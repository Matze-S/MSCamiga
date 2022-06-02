
/***************************************************************************
 *                                                                         *
 *                           3D-Netz-Grafik-Demo                           *
 *                                                                         *
 ***************************************************************************/

#include <intuition/intuition.h>
#include <graphics/gfxmacros.h>
#include <exec/memory.h>

#define PI ((FLOAT)3.141592653589793)
#define ROUND(x) ((FLOAT)((LONG)((x)+((FLOAT)0.5))))

#define f(x,y)    -exp(-x*x-y*y)
#define Links     -3.0
#define Rechts    3.0
#define Unten     -3.0
#define Oben      3.0
#define Anzahl    35
#define Winkel    45.0
#define FaktorX   1.0
#define FaktorY   1.0
#define FaktorZ   5.0

IMPORT APTR AllocMem();
IMPORT struct Message *WaitPort(),*GetMsg();
IMPORT struct Library *OpenLibrary();
IMPORT struct Screen *OpenScreen();
IMPORT struct Window *OpenWindow();
IMPORT VOID ReplyMsg(),FreeMem(),Move(),Text(),SetAPen(),SetBPen();
IMPORT VOID SetDrMd();
IMPORT VOID CloseLibrary(),CloseScreen(),CloseWindow(),LoadRGB4();
IMPORT FLOAT sin(),cos(),exp();

STATIC struct TextAttr Topaz_80 = {
   (STRPTR)"topaz.font",TOPAZ_EIGHTY,FS_NORMAL,FPF_ROMFONT
};
STATIC struct NewScreen NewScreen = {
   0,0,640,256,2,2,1,HIRES,CUSTOMSCREEN,&Topaz_80,
   (STRPTR)"3D-Netz-Grafik-Demo",NULL,NULL
};
USHORT ColorTable[] = {
   0x000,0x00f,0xf00,0x0f0
};
STATIC struct NewWindow NewWindow = {
   0,10,640,246,0,0,MOUSEBUTTONS|RAWKEY,REPORTMOUSE|SIMPLE_REFRESH|
   NOCAREREFRESH|RMBTRAP|BORDERLESS|BACKDROP|ACTIVATE,NULL,NULL,NULL,
   NULL,NULL,0,0,0,0,CUSTOMSCREEN
};

struct IntuitionBase *IntuitionBase;
struct GfxBase *GfxBase;
STATIC struct Screen *Screen;
STATIC struct Window *Window;
STATIC struct Punkt_3D { FLOAT x,y,z; } Knoten[Anzahl][Anzahl];
STATIC struct Punkt_2D { SHORT x,y; } Koords[Anzahl][Anzahl];
STATIC FLOAT MinX,MinY,MaxX,MaxY;

VOID Funktionsberechnung()
{
   REGISTER int xcnt,ycnt;
   REGISTER FLOAT x,y,xinc,yinc;

   xinc = (Rechts-Links)/Anzahl;
   yinc = (Oben-Unten)/Anzahl;
   for (ycnt = 0,y = Unten;ycnt<Anzahl;ycnt++,y += xinc)
      for (xcnt = 0,x = Links;xcnt<Anzahl;xcnt++,x += yinc) {
         Knoten[xcnt][ycnt].x = x*FaktorX;
         Knoten[xcnt][ycnt].y = y*FaktorY;
         Knoten[xcnt][ycnt].z = (f(x,y))*FaktorZ;
      }
}

VOID ParallelProjektion()
{
   REGISTER int xcnt,ycnt;
   REGISTER FLOAT c,s,w;

   c = cos(w = PI/180.0*Winkel);
   s = sin(w);
   for (xcnt = 0;xcnt<Anzahl;xcnt++)
      for (ycnt = 0;ycnt<Anzahl;ycnt++) {
         Knoten[xcnt][ycnt].x = Knoten[xcnt][ycnt].x+c*Knoten[xcnt][ycnt].y;
         Knoten[xcnt][ycnt].y = -Knoten[xcnt][ycnt].z-s*Knoten[xcnt][ycnt].y;
      }
}

VOID MinMaxSuch()
{
   REGISTER int xcnt,ycnt;
   REGISTER FLOAT flt;

   MinX = MinY = MaxX = MaxY = 0.0;
   for (xcnt = 0;xcnt<Anzahl;xcnt++)
      for (ycnt = 0;ycnt<Anzahl;ycnt++) {
         if ((flt = Knoten[xcnt][ycnt].x)<MinX) MinX=flt;
         if (flt>MaxX) MaxX=flt;
         if ((flt = Knoten[xcnt][ycnt].y)<MinY) MinY=flt;
         if (flt>MaxY) MaxY=flt;
      }
}

VOID Bildschirmanpassung()
{
   REGISTER struct Punkt_3D *pt1;
   REGISTER struct Punkt_2D *pt2;
   REGISTER int xcnt,ycnt;
   REGISTER FLOAT xf,yf,yd;
   SHORT xa,ya;

   if ((xf = 250.0/(MaxX-MinX))>(yf = 200.0/(yd = MaxY-MinY))) xf = yf;
   xf = (yf = ROUND(xf))*2.0;
   xa = 320-(SHORT)(yf*(MaxX+MinX));
   ya = 123-(SHORT)(yf*(yd/2+MinY));
   for (xcnt = 0;xcnt<Anzahl;xcnt++)
      for (ycnt = 0;ycnt<Anzahl;ycnt++) {
         Koords[xcnt][ycnt].x = xa+(SHORT)(0.5+xf*Knoten[xcnt][ycnt].x);
         Koords[xcnt][ycnt].y = ya+(SHORT)(0.5+yf*Knoten[xcnt][ycnt].y);
      }
}

VOID Zeichnen()
{
   REGISTER struct RastPort *rp;
   REGISTER struct Punkt_2D *pt;
   REGISTER int xcnt,ycnt;

   SetAPen(rp = Window->RPort,0L);
   SetOPen(rp,3L);
   for (ycnt = Anzahl-2;ycnt>=0;ycnt--)
      for (xcnt = Anzahl-2;xcnt>=0;xcnt--) {
         AreaMove(rp,(LONG)pt->x,(LONG)(pt = &Koords[xcnt][ycnt])->y);
         AreaDraw(rp,(LONG)pt->x,(LONG)(pt = &Koords[xcnt+1][ycnt])->y);
         AreaDraw(rp,(LONG)pt->x,(LONG)(pt = &Koords[xcnt+1][ycnt+1])->y);
         AreaDraw(rp,(LONG)pt->x,(LONG)(pt = &Koords[xcnt][ycnt+1])->y);
         AreaDraw(rp,(LONG)pt->x,(LONG)(pt = &Koords[xcnt][ycnt])->y);
         AreaEnd(rp);
      }
}

VOID main()
{
   REGISTER struct RastPort *rp;
   REGISTER APTR ptr;
   struct TmpRas TmpRas;
   struct AreaInfo AreaInfo;
   BYTE AreaBuffer[26];

   if (IntuitionBase = (struct IntuitionBase *)
        OpenLibrary("intuition.library",0L)) {
      if (GfxBase = (struct GfxBase *)OpenLibrary("graphics.library",0L)) {
         if (Screen = OpenScreen(&NewScreen)) {
            LoadRGB4(&(Screen->ViewPort),ColorTable,4L);
            NewWindow.Screen = Screen;
            if (Window = OpenWindow(&NewWindow)) {
               if (ptr = AllocMem(50000L,MEMF_CHIP|MEMF_PUBLIC)) {
                  InitTmpRas(Window->RPort->TmpRas = &TmpRas,ptr,50000L);
                  InitArea(Window->RPort->AreaInfo = &AreaInfo,AreaBuffer,5L);
                  SetAPen(rp = &(Screen->RastPort),2L);
                  SetBPen(rp,0L);
                  SetDrMd(rp,JAM2);
                  Move(rp,0L,254L);
                  Text(rp,"Funktionsberechnung...",22L);
                  Funktionsberechnung();
                  Move(rp,0L,254L);
                  Text(rp,"Parallel-Projektion...",22L);
                  ParallelProjektion();
                  Move(rp,0L,254L);
                  Text(rp,"Suchen der Minima- und Maxima- Werte...",39L);
                  MinMaxSuch();
                  Move(rp,0L,254L);
                  Text(rp,"Bildschirmanpassung...                 ",39L);
                  Bildschirmanpassung();
                  Move(rp,0L,254L);
                  Text(rp,"Zeichnen...           ",22L);
                  Zeichnen();
                  Move(rp,0L,254L);
                  Text(rp,"           ",11L);
                  WaitPort(Window->UserPort);
                  ReplyMsg(GetMsg(Window->UserPort));
                  FreeMem(TmpRas.RasPtr,TmpRas.Size);
               }
               CloseWindow(Window);
            }
            CloseScreen(Screen);
         }
         CloseLibrary(GfxBase);
      }
      CloseLibrary(IntuitionBase);
   }
}

