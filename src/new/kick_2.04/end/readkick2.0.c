
/* this program writes the kickstart 2.x out of the rom into a file */

#include <stdio.h>

void main(int argc, char **argv)
{
   FILE *fp;

   if (fp = fopen("kick2.0", "wb")) {
      if (fwrite((char *)0xf80000, (size_t)1024, (size_t)512, fp) != 512) {
         printf("write error.");
         fclose(fp);
         exit(10);
      }
      printf("ok.\n");
      fclose(fp);
      exit(0);
   }
   printf("open error.");
   exit(0);
}

