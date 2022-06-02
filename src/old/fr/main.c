
/*
**  main.c
**
**  is the main-control-program for the filerequester.
*/

extern char *FileRequest();
extern struct Menu menu;

UBYTE topaz[]="topaz.font";
struct TextAttr Topaz_80 = {
   topaz,TOPAZ_EIGHTY,FS_NORMAL,FPF_ROMFONT
};
struct TextAttr ITopaz_80 = {
   topaz,TOPAZ_EIGHTY,FSF_ITALIC,FPF_ROMFONT
};
struct NewWindow newwindow = {
   80,20,296,176,-1,-1,CLOSEWINDOW|MENUPICK,
   WINDOWCLOSE|WINDOWDEPTH|WINDOWDRAG|ACTIVATE|
   SIMPLE_REFRESH|NOCAREREFRESH,
   NULL,NULL,(STRPTR)"Window",NULL,NULL,100,28,-1,-1,WBENCHSCREEN
};
#ifdef OWNSCREEN
struct NewScreen newscreen = {
   0,0,320,256,2,0,1,0,CUSTOMSCREEN,&Topaz_80,(STRPTR)"Screen",NULL,NULL
};
struct Screen *scr;
#endif

struct IntuitionBase *IntuitionBase;
struct Window *wnd;
struct IntuiMessage msg;

main()
{
   if (IntuitionBase=(struct IntuitionBase *)
         OpenLibrary("intuition.library",0L)) {
#ifdef OWNSCREEN
      if ((scr=OpenScreen(&newscreen))==NULL) {
         CloseLibrary(IntuitionBase);
         exit(FALSE);
      }
      newwindow.Screen=scr;
      newwindow.Type=CUSTOMSCREEN;
      newwindow.LeftEdge=0;
      newwindow.TopEdge=12;
#endif
      if (wnd=OpenWindow(&newwindow)) {
         SetMenuStrip(wnd,&menu);
         FileRequest(wnd,10L,13L,"Start-Requester","Cancel");
         do {
            msg=*(struct IntuiMessage *)WaitPort(wnd->UserPort);
            ReplyMsg(GetMsg(wnd->UserPort));
            switch (msg.Class) {
               case MENUPICK:
                  switch (MENUNUM(msg.Code)) {
                     case 0:
                        switch (ITEMNUM(msg.Code)) {
                           case 0:
                              FileRequest(wnd,10L,13L,"Load File"," Load ");
                              continue;
                           case 1:
                              FileRequest(wnd,10L,13L,"Save File"," Save ");
                              continue;
                           case 2:
                              msg.Class=CLOSEWINDOW;
                        }
                  }
            }
         } while (msg.Class!=CLOSEWINDOW);
         CloseWindow(wnd);
      }
#ifdef OWNSCREEN
      CloseScreen(scr);
#endif
      CloseLibrary(IntuitionBase);
   }
}
