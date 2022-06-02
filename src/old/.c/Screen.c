
#include <intuition/intuition.h>
#include <intuition/intuitionbase.h>

struct IntuitionBase *IntuitionBase;
extern struct Library *OpenLibrary();

main()
{
   REGISTER struct Window *wnd;
   REGISTER struct Screen *scr;

   if (IntuitionBase=(struct IntuitionBase *)
        OpenLibrary("intuition.library",0L)) {
      Forbid();
      if (wnd=IntuitionBase->ActiveWindow) {
         scr=wnd->WScreen;
         MoveWindow(wnd,(LONG)-wnd->LeftEdge,(LONG)-wnd->TopEdge);
         SizeWindow(wnd,(LONG)scr->Width-wnd->Width,
           (LONG)scr->Height-12-wnd->Height);
         MoveWindow(wnd,0L,12L);
      }
      Permit();
      CloseLibrary(IntuitionBase);
   }
}

