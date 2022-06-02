
#include <stdio.h>

void main(int argc, char **argv)
{
   FILE *rfp1, *rfp2, *wfp;
   long l;

   rfp1 = fopen("kick2.04", "rb");
   rfp2 = fopen(".", "rb");
   wfp = fopen("kick", "wb");
   l = 0x7f700;
   while (l--) putc(getc(rfp1), wfp);
   l = 0x8e0;
   fseek(rfp1, l, 1);
   while (l--) putc(getc(rfp2), wfp);
   l = 0x20;
   while (l--) putc(getc(rfp1), wfp);
   fclose(wfp);
   fclose(rfp2);
   fclose(rfp1);
   exit(0);
}

