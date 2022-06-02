/* Copyright (C) 1990 by Matthias Schmidt */

/*
 *  rdrng.c
 */

#include "defs.h"

int rdrng(char *text, int min, int max, int sugg)
{
   int v;

   do {
      switch (sugg) {
         case RDRNG_NOSUGG:
            printf("%s (%d-%d): ", text, min, max);
            break;
         case RDRNG_NORANGE:
            printf("%s : ", text);
            break;
         default:
            printf("%s (%d-%d) [%d]: ", text, min, max, sugg);
      }
      if ((v = rdval(sugg == RDRNG_NORANGE ? RDRNG_NOSUGG : sugg)) !=
            RDRNG_NOSUGG && (v < min || v > max)) {
         printf("Value (=%d) is out of range (min=%d, max=%d).  "
               "Please try again.\n", v, min, max);
         v = RDRNG_NOSUGG;
      }
   } while (v == RDRNG_NOSUGG);
   return v;
}

/*------------ end of source ------------*/

