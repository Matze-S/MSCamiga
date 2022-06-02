
/* save the kick 1.3 bonus */

#include <stdio.h>

void main(int argc, char **argv)
{
   FILE *fp;

   fp = fopen("kick1.3_bonus", "wb");
   fwrite((char *)0xf00000, (size_t)1024, (size_t)64, fp);
   fclose(fp);
   exit(0);
}

