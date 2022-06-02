
#include <exec/types.h>
#include <clib/dos_protos.h>
#include <dos/dos.h>
#include <stdio.h>

void main(int argc, char **argv)
{
   static char buf[512];
   BPTR fh;
   int i, j;

   for (i = 0; i < 512; ++i)
      buf[i] = 0xf6;

   if (fh = Open("PCHD:", MODE_READWRITE)) {
      Seek(fh, OFFSET_BEGINNING, 0x200L);
      for (i = 0; i < 50; ++i)
         Write(fh, buf, 0x200L);
      Close(fh);
   }
   exit(0);
}

