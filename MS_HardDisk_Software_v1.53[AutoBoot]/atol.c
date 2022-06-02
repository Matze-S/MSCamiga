/* Copyright (C) 1990 by Matthias Schmidt */

/*
 *  atol.c
 */

#include "defs.h"

long atol(const char *cp)
{
   long l = 0;
   int s = 0, h = 0;

   if (*cp == '-' || *cp == '+') s = (*cp++ == '+') ? 0 : 1;
   if (*cp == '0' && toupper((int)cp[1]) == 'X') {
      h = 1;
      cp += 2;
   } else if (*cp == '$') {
      h = 1;
      ++cp;
   }
   while (*cp) {
      if (!h) {
         if (*cp < '0' || *cp > '9')
            break;
         l = l * 10 + *cp - '0';
      } else {
         if (*cp >= '0' && *cp <= '9')
            l = (l << 4) + *cp - '0';
         else {
            if (toupper((int)*cp) < 'A' || toupper((int)*cp) > 'F')
               break;
            l = (l << 4) + toupper((int)*cp) - 'A' + 10;
         }
      }
      ++cp;
   }
   return s ? -l : l;
}

/*------------ end of source ------------*/

