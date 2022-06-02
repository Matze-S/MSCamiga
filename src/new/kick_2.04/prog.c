
#include <stdio.h>

void main(int argc, char **argv)
{
   FILE *fp;
   long l, *lp;

   if (fp = fopen("devs:kickstart", "rb")) {
      lp = (long *) 0xf80000;
      do {
         if (fread(&l, sizeof(l), 1, fp) != 1) {
            printf("read failure\n");
            break;
         }
         if (l != *lp)
            printf("%08lx: 0x%08lx in file, 0x%08lx in memory!\n",
                  lp, l, *lp);
      } while (++lp != (long *)0x01000000);
      fclose(fp);
   }
   exit(0);
}

