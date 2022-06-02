
/*
 *  setntsc.c v1.1 -- Copyright (C) 1991 by Matthias Schmidt
 */


/* Includes 2.0 required! */


#include <exec/types.h>
#include <graphics/gfxbase.h>
#include <graphics/gfxnodes.h>
#include <graphics/monitor.h>
#include <functions.h>
#include <stdio.h>


struct GfxBase *GfxBase;

void main(int argc, char **argv)
{
   struct MonitorSpec *msp;
   int i;

   printf("setntsc v1.1 -- Copyright (C) 1990 by Matthias Schmidt\n");

   if ((GfxBase = (struct GfxBase *)OpenLibrary((UBYTE *)
         GRAPHICSNAME, 36L)) == NULL) {
      printf("Unable to open '%s' version 36!\n", GRAPHICSNAME);
      exit(20);
   }

   if (GfxBase->DisplayFlags & NTSC) {
      printf("NTSC is alread set.\n");
      i = 0;
   } else {

      Forbid();
      msp = (struct MonitorSpec *)&GfxBase->MonitorList;

      while ((msp = (struct MonitorSpec*)msp->ms_Node.xln_Succ)->
            ms_Node.xln_Succ) {
         if (strcmp(msp->ms_Node.xln_Name, NTSC_MONITOR_NAME) == 0) {
            GfxBase->default_monitor = msp;
            GfxBase->monitor_id = REQUEST_NTSC;
            GfxBase->DisplayFlags = GfxBase->DisplayFlags & ~PAL | NTSC;
            GfxBase->NormalDisplayRows = 200;
            printf("NTSC mode installed.\n");
            i = 0;
            break;
         }
      }

      if (!msp->ms_Node.xln_Succ) {
         printf("No '%s' found!\n", NTSC_MONITOR_NAME);
         i = 5;
      }
      Permit();

   }

   CloseLibrary((struct Library *)GfxBase);
   exit(i);
}

