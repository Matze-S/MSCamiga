/* Copyright (C) 1990 by Matthias Schmidt */

/*
 *  rdval.c
 */

#include "defs.h"

int rdval(int sugg)
{
   int i = -1, s = 0, v;
   char buf[6];

   while (++i < 5 && ((v = getchar()) != -1 && (buf[i] = v) != '\n'));
   if (i == 5) {
      while (getchar() != '\n');
      printf("Input line is too long.  Please try again.\n");
      return RDVAL_TRYAGAIN;
   }
   if (!i) return sugg;
   buf[i] = 0;
   s = i = buf[0] == '-' ? 1 : 0;
   for (v = 0; buf[i]; ++i) {
      if (buf[i] < '0' || buf[i] > '9') return RDVAL_TRYAGAIN;
      v = v * 10 + buf[i] - '0';
   }
   return s ? -v : v;
}

/*------------ end of source ------------*/

