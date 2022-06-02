
/* Select_II.c - a selector for using with my Hard Disk */

char entries[20][80],script_files[20][80];

int num_entries;
#define NUMENTRIES num_entries
#define PRINTENTRY(nr,c) {\
   char *cp = entries[nr];\
   int l = strlen(cp);\
\
   SetAPen(rp,(long)c);\
   Move(rp,(long)160-(l<<2),(long)(y+((nr)<<4)+((int)rp->TxBaseline)));\
   Text(rp,cp,(long)l);\
}

#include <exec/types.h>
#include <intuition/intuition.h>
#include <graphics/gfxmacros.h>
#include <libraries/dosextens.h>    /* for Process structure */
#include <hardware/cia.h>           /* for CIAF_GAMEPORT0 */
#include <stdio.h>

extern struct Library *OpenLibrary();
extern struct Message *WaitPort(),*GetMsg();
extern struct Screen *OpenScreen();
extern struct Window *OpenWindow();
extern VOID CloseLibrary(),ReplyMsg(),LoadRGB4(),WaitBOVP(),CloseScreen(),CloseWindow();
long Open();
struct Process *FindTask();

unsigned short color_table[20] = {
   0x000,0x000,0x001,0x002,0x003,0x004,0x005,0x006,
   0x007,0x008,0x009,0x00a,0x00b,0x00c,0x00d,0x00e,
   0x00f,0xff0,0x080,0x0f0
};

struct GfxBase *GfxBase;
struct IntuitionBase *IntuitionBase;
static struct Window *Window;
FILE *fp;

static struct TextAttr Topaz_80 = {
   (UBYTE *)"topaz.font",8,FS_NORMAL,FPF_ROMFONT
};
static struct NewScreen NewScreen = {
   0,0,320,256,5,0,0,0,CUSTOMSCREEN,&Topaz_80,NULL,NULL,NULL
};
static struct NewWindow NewWindow = {
   0,0,320,256,0,0,MOUSEBUTTONS,WINDOWCLOSE|ACTIVATE|NOCAREREFRESH|REPORTMOUSE|
   SIMPLE_REFRESH|BORDERLESS|RMBTRAP,NULL,NULL,NULL,NULL,NULL,
   0,0,0,0,CUSTOMSCREEN
};

close_all(ec)
{
   static char *ErrorMsgs[] = {
      "Can't open 'graphics.library' !",
      "Can't open 'intuition.library' !",
      "Unable to open Screen !",
      "Unable to open Window !",
      "Can't open script file !",
      "Unable to open text file !",
      "Unable to read text file !"
   };

   switch (ec) {
      case 7:
      case 6:
         fclose(fp);
         break;
      case 0:
      case 5:
         CloseWindow(Window);
      case 4:
         CloseScreen(NewWindow.Screen);
      case 3:
         CloseLibrary(IntuitionBase);
      case 2:
         CloseLibrary(GfxBase);
      case 1:;
   }
   if (ec) puts(ErrorMsgs[ec-1]);
   exit(ec ? 20:0);
}

main(argc,argv)
char **argv;
{
   register int i,j,d,x,y;
   struct IntuiMessage *imp;
   register struct RastPort *rp;
   struct CommandLineInterface *clip =
         (struct CommandLineInterface *)BADDR(FindTask(0L)->pr_CLI);
   long fh;

   if (*(char *)0xbfe001 & 0x40) exit(0);

   if (fp = fopen(argv[1],"r")) {
      i = 0;
      while (fgets(entries[i],80,fp)) {
         if (!fgets(script_files[i],80,fp)) close_all(7);
         entries[i][strlen(entries[i]) - 1] = 0;
         script_files[i][strlen(script_files[i]) - 1] = 0;
         ++i;
      }
      num_entries = i;
      fclose(fp);
   } else close_all(6);

   if (!(GfxBase = (struct GfxBase *)OpenLibrary("graphics.library",0L)))
            close_all(1);
   if (!(IntuitionBase = (struct IntuitionBase *)
            OpenLibrary("intuition.library",0L))) close_all(2);
   if (!(NewWindow.Screen = OpenScreen(&NewScreen))) close_all(3);
   if (!(Window = OpenWindow(&NewWindow))) close_all(4);

   LoadRGB4(&NewWindow.Screen->ViewPort,color_table,20L);
   SetDrMd(rp = Window->RPort,JAM1);
   for (i = 0, j = 2, d = 1; i<320; ++i, j += d) {
      SetAPen(rp,(long)j);
      Move(rp,(long)i,0L);
      Draw(rp,(long)i,255L);
      if (j == 1 || j == 16) d = -d;
   }
   for (i = d = 0; i < NUMENTRIES; ++i)
      if ((j = strlen(entries[i])) > d) d = j;

   SetAPen(rp,0L);
   SetOPen(rp,17L);
   x = (i = (260-(d<<3))>>1) + 30;
   j = (216-(NUMENTRIES<<4))>>1;
   RectFill(rp,(long)i,(long)j,319L-i,255L-j);
   SetAPen(rp,18L);
   for (i = 0, y = (j += 24), j += (int)rp->TxBaseline; i < NUMENTRIES;
            ++i,j += 16) {
      Move(rp,(long)(320-((d = strlen(entries[i]))<<3))>>1,(long)j);
      Text(rp,entries[i],(long)d);
   }
   i = -1;

   while (!(*(char *)0xbfe001 & 0x40));

main_loop:

   for (;;) {
      if (imp = (struct IntuiMessage *)GetMsg(Window->UserPort)) {
         if (imp->Class == MOUSEBUTTONS && imp->Code == SELECTUP)
            ReplyMsg(imp);
         else
            break;
      }
      j = (d = ((int)NewWindow.Screen->MouseY) - y) >> 4;
      if (j >= 0 && j < NUMENTRIES && !(d&8) && NewWindow.Screen->MouseX >=
               x && NewWindow.Screen->MouseX <= (319 - x)) {
         if (i != j) {
            if (i != -1) PRINTENTRY(i,18);
            i = j;
            PRINTENTRY(i,19);
         }
      } else if (i != -1) {
         PRINTENTRY(i,18);
         i = -1;
      }
      Delay(1L);
   }
   ReplyMsg(imp);

   if (i == -1) goto main_loop;

   if (i != -1 && script_files[i][0]) {
      /* close a possible script file (e.g. SYS:S/Startup-Sequence) */
      if (clip->cli_CurrentInput != clip->cli_StandardInput) {
         Close(clip->cli_CurrentInput);
         clip->cli_CurrentInput = clip->cli_StandardInput;
         clip->cli_Interactive = DOSTRUE;
      }

      if (!(fh = Open(script_files[i],MODE_OLDFILE))) close_all(5);
      clip->cli_CurrentInput = fh;
      clip->cli_Interactive = DOSFALSE;
   }

   close_all(0);
}

