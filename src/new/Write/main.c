
#include <exec/types.h>
#include <clib/exec_protos.h>
#include <clib/graphics_protos.h>
#include <clib/intuition_protos.h>
#include <graphics/displayinfo.h>
#include <intuition/screens.h>
#include <stdio.h>

struct GfxBase *GfxBase;
struct IntuitionBase *IntuitionBase;
struct Screen *Screen;
struct Window *Window;

char screen_title[] = "Write v1.0";
UWORD pens = -1;
struct TagItem screen_tis[] = {
   SA_Pens, NULL,
   SA_Title, NULL,
   SA_Left, 0,
   SA_Top, 1,
   SA_Depth, 4,
   SA_Type, CUSTOMSCREEN,
   SA_DisplayID, HIRESLACE_KEY,
   SA_FullPalette, TRUE,
   SA_SysFont, 1,
   TAG_DONE, NULL
};
char window_tile[] = "Unbenannt";
struct TagItem window_tis[] = {
   WA_CustomScreen, NULL,
   WA_Title, NULL,
   WA_Left, 0,
   WA_Top, 20,
   WA_Height, -20,
   WA_IDCMP, CLOSEWINDOW,
   WA_Flags, WINDOWCLOSE,
   TAG_DONE, NULL
};

void main(int argc, char **argv)
{
   printf("Write v1.0 -- Copyright (C) 1991 by Matthias Schmidt\n");

   if (!(IntuitionBase = (struct IntuitionBase *)
         OpenLibrary((UBYTE *)"intuition.library", 37L))) {
      printf("No intuition.library, ver.2.0, rev.37.x\n");
      exit(20);
   }
   if (!(GfxBase = (struct GfxBase *)
         OpenLibrary((UBYTE *)"graphics.library", 37L))) {
      printf("No graphics.library, ver.2.0, rev.37.x\n");
      CloseLibrary((struct Library *)IntuitionBase);
      exit(20);
   }

   screen_tis[0].ti_Data = (ULONG)&pens;
   screen_tis[1].ti_Data = (ULONG)screen_title;
   if (!(Screen = OpenScreenTagList(NULL, screen_tis))) {
      printf("No screen\n");
      CloseLibrary((struct Library *)GfxBase);
      CloseLibrary((struct Library *)IntuitionBase);
      exit(20);
   }
   window_tis[0].ti_Data = (ULONG)Screen;
   window_tis[1].ti_Data = (ULONG)window_tile;

   Window = OpenWindowTagList(NULL, window_tis);

   WaitPort((struct MsgPort *)Window->UserPort);

   CloseWindow(Window);
   CloseScreen(Screen);
   CloseLibrary((struct Library *)GfxBase);
   CloseLibrary((struct Library *)IntuitionBase);
   exit(20);
}

