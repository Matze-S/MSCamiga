
#include <stdlib.h>
#include <stdio.h>

void Forbid(void), Permit(void);

void main(int argc, char **argv)
{
   FILE *fp;
   long i, len, l = 0x12345678, *mp, *lp;
   register unsigned short *ssp, *tsp = (unsigned short *)0x300000;

   *(lp = (long *)tsp) = l;
   if (*lp != l) {
      *(char *)0xe80048 = 0x30;
      printf("RAM/ROM-Board moved to $%06lx\n", tsp);
   }
   if (fp = fopen("ab", "rb")) {
      do {
         (void)fread((void *)&l, (size_t)4, (size_t)1, fp);
      } while ((l & 0x3fffffff) != 0x3e9);
      (void)fread((void *)&len, (size_t)4, (size_t)1, fp);
      if (mp = malloc((size_t)len << 2)) {
         (void)fread((void *)mp, (size_t)4, (size_t)len, fp);
         ssp = (unsigned short *)mp;
         i = len << 1;
         printf("Writing %ld bytes as words to $%lx...\n",
            i << 1, (long)tsp);
         Forbid();
         while (i--) *tsp++ = *ssp++;
         Permit();
         free((void *)mp);
         printf("ok.\n");
      } else {
         printf("Not enough memory!\n");
         exit(20);
      }
      fclose(fp);
   } else {
      printf("Unable to open 'ab' for reading!\n");
      exit(20);
   }
}
