
#include <stdio.h>

void main(int argc, char **argv)
{
   FILE *rfp, *wfp;

   rfp = fopen("devs:kick2", "rb");
   wfp = fopen(".", "wb");
   fseek(rfp, (long)(512 * 1024), 1);
   while (!feof(rfp)) putc(getc(rfp), wfp);
   fclose(wfp);
   fclose(rfp);
   exit(0);
}

