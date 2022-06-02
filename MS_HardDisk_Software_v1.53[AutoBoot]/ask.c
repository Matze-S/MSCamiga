/* Copyright (C) 1990 by Matthias Schmidt */

/*
 *  ask.c
 */

#include "defs.h"

int ask(char *text, char sugg)
{
   int i;

   for (;;) {
      printf("%s [Y/N] : %c\010", text, sugg);
      if ((i = getchar()) == '\n') break;
      if (i == -1) continue;
      if ((i = toupper(i)) == 'Y' || i == 'N') {
         sugg = i;
         if ((i = getchar()) == '\n') break;
      }
      while (i != -1 && (i = getchar()) != '\n');
   }
   return sugg == 'Y' ? 1 : 0;
}

/*------------ end of source ------------*/

