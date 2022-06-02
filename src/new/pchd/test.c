
#include <exec/types.h>
#include <clib/dos_protos.h>
#include <dos/dos.h>
#include <stdio.h>

static ULONG buf[4][128];

void fill(int x)
{
   ULONG ul;
   UBYTE ub;
   int i, j;

   ub = (UBYTE)x;
   ul = (x << 24) | (x << 16) | (x << 8) | x;
   for (i = 0; i < 4; ++i)
      for (j = 0; j < 128; ++j)
         buf[i][j] = ul;
}

void print(void)
{
   int i, j, k;

   for (i = 0; i < 4; ++i)
      for (j = 0; j < 128; j += 4) {
         printf("%d%03x:", i, j << 2);
         for (k = 0; k < 4; ++k)
            printf(" %08X", buf[i][j + k]);
         printf("\n");
      }
}

void main(int argc, char **argv)
{
   BPTR fh;

   if (fh = Open((UBYTE *)"PCHD:", MODE_READWRITE)) {
      fill(0x33);
      Seek(fh, OFFSET_CURRENT, 512L + 50L);
/*      Write(fh, buf, 1024 + 20L);
*/      fill(0xaa);
      print();
      Seek(fh, OFFSET_BEGINNING, 0L);
      Read(fh, buf, 4L * 512L);
      print();
      Close(fh);
   }
   exit(0);
}

