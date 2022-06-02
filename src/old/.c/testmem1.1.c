
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

/*------ atol() - convert ascii string to long value ------*/

/* (note: supports decimal and hexadecimal ascii string!) */

long atol(const char *cp)
{
   long l = 0;
   int s = 0, h = 0;

   if (*cp == '-' || *cp == '+') {
      s = (*cp == '+') ? 0 : 1;
      ++cp;
   }
   if (*cp == '0' && toupper((int)cp[1]) == 'X') {
      h = 1;
      cp += 2;
   } else if (*cp == '$') {
      h = 1;
      ++cp;
   }
   while (*cp) {
      if (!h) {
         if (*cp < '0' && *cp > '9')
            break;
         l = l * 10 + *cp - '0';
      } else {
         if (*cp >= '0' && *cp <= '9')
            l = (l << 4) + *cp - '0';
         else {
            if (toupper((int)*cp) < 'A' && toupper((int)*cp) > 'F')
               break;
            l = (l << 4) + toupper((int)*cp) - 'A' + 10;
         }
      }
      ++cp;
   }
   return (s ? -l : l);
}

void main(int argc, char **argv)
{
   unsigned char c, f, *cp, *la, *ua;

   printf("TestMem v1.1 -- Copyright (C) 1990 by Matthias Schmidt\n");
   if (argc != 3) {
      printf("Usage: %s <lower address> <upper address>\n", *argv);
      exit(EXIT_SUCCESS);
   }
   cp = la = (unsigned char *)atol(argv[1]);
   ua = ((unsigned char *)atol(argv[2])) + 1;
   c = 0;
   printf("Filling...");
   fflush(stdout);
   while (cp < ua) *cp++ = c++;
   printf("ok!\nChecking...");
   fflush(stdout);
   for (f = c = 0, cp = la; cp < ua; ++cp, ++c)
      if (*cp != c) {
         if (!f) printf("\n");
         printf("Wrong value at $%lx -- there is: %u, and there "
               "should be %u!\n", cp, (unsigned)*cp, (unsigned)c);
         f = 1;
      }
   if (f) {
      printf("\nBad memory!\n");
      exit(EXIT_FAILURE);
   }
   printf("ok!\n");
   exit(EXIT_SUCCESS);
}
