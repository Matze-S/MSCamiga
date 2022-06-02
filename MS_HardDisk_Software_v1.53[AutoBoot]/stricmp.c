/* Copyright (C) 1990 by Matthias Schmidt */

/*
 *  stricmp.c
 */

#include "defs.h"

int stricmp(char *sa, char *sb)
{
   char ca, cb;

   do {
      if ((ca = toupper((int)*sa++)) < (cb = toupper((int)*sb++)))
         return -1;
      else if (ca > cb) return 1;
   } while (ca);
   return 0;
}

/*------------ end of source ------------*/

