/* Copyright (C) 1990 by Matthias Schmidt */

/*
 *  rdtxt.c
 */

#include "defs.h"

char *rdtxt(char *text, char *sugg)
{
   static char buf[256];

   printf("%s [%s] : ", text, sugg);
   gets(buf);
   if (!buf[0]) strcpy(buf, sugg);
   return buf;
}

/*------------ end of source ------------*/

