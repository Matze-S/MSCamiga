
/*------------------------------*
 * filerequest.c - main-program *
 * (W) by M.Schmidt             *
 *------------------------------*/

#include "filerequest.h"

extern struct PropInfo fr_G6_Info;
extern struct TextAttr Topaz_80,ITopaz_80;
extern struct Gadget fr_Gadget_6,fr_Gadget_7;
extern struct IntuiText fr_IText,fr_G0_IText,fr_G7_ITexts[];
extern struct Requester fr_Requester;
extern UBYTE fr_Path[],fr_File[],fr_EntryNames[EY][EX+1];

struct fr_entry {
   struct fr_entry *next;
   char typ;
   char name[108];
};
#define ET_FILE 2L
#define ET_DIR 1L
#define ET_ITALIC 0L

ULONG fr_numentries;
char fr_buffer1[108];
char fr_buffer2[108];

int fr_InsertEntry(el,e)
register struct fr_entry *el,*e;
{
   register struct fr_entry *ne;
   register char *ptr;
   register int pos = 0;

   while (ne=el->next) {
      ++pos;
      if (((e->typ!=ET_DIR)&&(e->typ!=ET_FILE))||
       ((e->typ==ET_DIR)&&(ne->typ==ET_FILE))) break;
      if (!((e->typ==ET_FILE)&&(ne->typ==ET_DIR))) {
         strcpy(fr_buffer1,e->name);
         strcpy(fr_buffer2,ne->name);
         for (ptr=fr_buffer1;*ptr;ptr++) *ptr=_toupper(*ptr);
         for (ptr=fr_buffer2;*ptr;ptr++) *ptr=_toupper(*ptr);
         if (strcmp(fr_buffer1,fr_buffer2)<0) break;
      }
      el=ne;
   }
   el->next=e;
   e->next=ne;
   return (pos);
}

void fr_Init_G7_ITexts()
{
   register short cnt;
   register struct IntuiText *it;
   register STRPTR ptr;

   for (cnt=0;cnt<EY;cnt++) {
      it=&fr_G7_ITexts[cnt];
      it->FrontPen=C_TEXT;
      it->BackPen=C_GROUND;
      it->DrawMode=JAM2;
      it->LeftEdge=0;
      it->TopEdge=cnt<<3;
      it->ITextFont=NULL;
      ptr=(it->IText=&fr_EntryNames[cnt][0])+EX;
      for (*ptr=0;ptr>it->IText;*--ptr=' ');
      it->NextText=&fr_G7_ITexts[cnt+1];
   }
   fr_G7_ITexts[EY-1].NextText=NULL;
}

void fr_DisplayEntries(w,el,p)
struct Window *w;
register struct fr_entry *el;
long p;
{
   register short cnt;
   register STRPTR ptr,ptr2,ptr3;
   struct IntuiText *it;

   for (cnt=p;cnt;cnt--) el=el->next;
   for (cnt=0,it=fr_G7_ITexts;cnt<EY;cnt++) {
      ptr2=ptr=it->IText;
      ptr3=ptr+EX;
      do {
         *ptr2++=' ';
      } while (*ptr2);
      ptr2=(STRPTR)el->name;
      do {
         *ptr++=*ptr2++;
      } while ((*ptr2)&&(ptr<ptr3));
      if (el->typ==ET_DIR) strncpy((ptr>ptr3-6)?ptr3-6:ptr," (dir)",6);
      it->ITextFont=(el->typ==ET_ITALIC)?&ITopaz_80:&Topaz_80;
      if ((el=el->next)==NULL) break;
      it=it->NextText;
   }
   RefreshGList(&fr_Gadget_7,w,&fr_Requester,1L);
}

unsigned short fr_CalcPos()
{
   return ((((ULONG)fr_numentries-EY+1)*fr_G6_Info.VertPot+0x8000L)>>16);
}

LONG fr_RecalcProp(w,numinc,posinc)
struct Window *w;
long numinc,posinc;
{
   REGISTER LONG pot,pos;

   pos=(LONG)fr_CalcPos();
   fr_numentries+=numinc;
   pos+=posinc;
   if (pos<0) {
pos=0;
puts("POS <0!");
}
   if (pos>fr_numentries-EY) {
pos=fr_numentries-EY;
puts("POS >xx!");
}
   pot=(fr_numentries<=EY)?0L:(((ULONG)pos<<16)/(fr_numentries-EY));
   NewModifyProp(&fr_Gadget_6,w,&fr_Requester,
    AUTOKNOB|FREEVERT|PROPBORDERLESS,0L,pot,0L,
    (fr_numentries<=EY)?MAXBODY:(((ULONG)EY<<16)/fr_numentries),1L);
   return (pos);
}

void fr_RedisplayProp(w,el,numinc,posinc)
struct Window *w;
struct fr_entry *el;
long numinc,posinc;
{
   fr_DisplayEntries(w,el,fr_RecalcProp(w,numinc,posinc));
}

SHORT fr_DoIDCMP(w,el,wf)
struct Window *w;
struct fr_entry *el;
LONG wf;
{
   struct IntuiMessage msg,*msgptr;
   register USHORT id,loopflag=FALSE,oldpos=0,udgpressed=0;

   do {
      if (wf||loopflag) WaitPort(w->UserPort);
      if (msgptr=(struct IntuiMessage *)GetMsg(w->UserPort)) {
         msg=*msgptr;
         ReplyMsg(msgptr);
         if (msg.Class==MOUSEMOVE) {
            register USHORT newpos;
            if ((newpos=fr_CalcPos())!=oldpos)
             fr_DisplayEntries(w,el,(ULONG)(oldpos=newpos));
            continue;
         }
         if (udgpressed) {
            if (udgpressed=GID_UP) {
               fr_RedisplayProp(w,el,0L,-1L);
            } else {
               fr_RedisplayProp(w,el,0L,1L);
            }
            continue;
         }
         switch (msg.Class) {
            case GADGETDOWN:
               id=((struct Gadget *)msg.IAddress)->GadgetID;
               printf("GADGETDOWN! ID: %d\n",(int)id);
               switch (id) {
                  case GID_UP:
                  case GID_DOWN:
                     udgpressed=id;
                     loopflag=TRUE;
                     continue;
                  case GID_PROP:
                     oldpos=fr_CalcPos();
                     loopflag=TRUE;
                     continue;
                  default:
                     continue;
               }
               continue;
            case GADGETUP:
               id=((struct Gadget *)msg.IAddress)->GadgetID;
               printf("GADGETUP! ID: %d\n",(int)id);
               switch (id) {
                  case GID_UP:
                  case GID_DOWN:
                     udgpressed=0;
                     loopflag=FALSE;
                     continue;
                  case GID_PROP:
                     oldpos=0;
                     loopflag=FALSE;
                     continue;
                  case GID_CANCEL:
                  case GID_ENDGADGET:
                  case GID_FILE:
                     return (0);
                  case GID_PATH:
                     return (1);
               }
               continue;
         }
      }
   } while (loopflag);
   return (0);
}

struct fr_entry fr_Parent = {
   NULL,ET_ITALIC," - / (parent Directory) -"
};
struct fr_entry fr_Devices = {
   NULL,ET_ITALIC," - Devices: -"
};

char *FileRequest(w,x,y,t,g)
struct Window *w;
LONG x,y;
STRPTR t,g;
{
   struct FileInfoBlock *fib;
   struct FileLock *lk;
   struct Remember *entrykey;
   LONG oldidcmps;
   short error=0,brk;
   struct fr_entry *entrylist;

   if (!(fib=(struct FileInfoBlock *)
     AllocMem((LONG)sizeof(*fib),MEMF_PUBLIC))) return (-1L);
   fr_Requester.LeftEdge=x;
   fr_Requester.TopEdge=y;
   fr_IText.IText=t;
   fr_IText.LeftEdge=(REQWIDTH-IntuiTextLength(&fr_IText))>>1;
   fr_G0_IText.IText=g;
   oldidcmps=w->IDCMPFlags;
   ModifyIDCMP(w,MOUSEMOVE|GADGETDOWN|GADGETUP);
   Request(&fr_Requester,w);
   do {
      entrykey=entrylist=NULL;
      printf("-------- AND NOW: DO IT AGAIN: PATH := %s --------\n",fr_Path);
      fr_G6_Info.VertPot=0;
      error=1;
      fr_Init_G7_ITexts();
      error=2;
      if (lk=Lock(fr_Path,ACCESS_READ)) {
         fr_numentries=1;
         {
            register struct FileLock *flk;
            if (flk=ParentDir(lk)) {
               fr_InsertEntry(&entrylist,&fr_Parent);
               ++fr_numentries;
               UnLock(flk);
            }
         }
         brk=-1;
         fr_InsertEntry(&entrylist,&fr_Devices);
         if (Examine(lk,fib)) {
            register struct fr_entry *entry;
            error=0;
            while (ExNext(lk,fib)) {
               if ((entry=(struct fr_entry *)AllocRemember(&entrykey,
                (ULONG)sizeof(*entry),MEMF_PUBLIC))==NULL) {
                  error=1;
                  break;
               }
               entry->typ=(fib->fib_DirEntryType<0)?ET_FILE:ET_DIR;
               strcpy(entry->name,fib->fib_FileName);
               fr_InsertEntry(&entrylist,entry);
               fr_RedisplayProp(w,entrylist,1L,0L);
               if ((brk=fr_DoIDCMP(w,entrylist,FALSE))!=0) {
                  puts("BRK != 0 / IF IS!");
                  break;
               }
               puts("BRK = 0 / NIX IF!");
            }
         }
         UnLock(lk);
      }
      if (!brk) {
         puts("WAIT FOR IDCMP!");
         if (brk=fr_DoIDCMP(w,entrylist,TRUE)) puts ("NIX NULL");
         else puts("IS NULL!");
      }
      FreeRemember(entrykey,TRUE);
   } while (brk==1);
   puts("BRK == 0");
   FreeMem(fib,(LONG)sizeof(*fib));
   ModifyIDCMP(w,oldidcmps);
}
