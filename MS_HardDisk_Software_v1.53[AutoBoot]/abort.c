/* Copyright (C) 1990 by Matthias Schmidt */

/*
 *  abort.c
 */

#include "defs.h"

void _abort(void)
{
   stdout->_flags &= ~_IODIRTY;
   write(1, "\n*** BREAK\n", 11L);
   exit(10);
}

/*------------ end of source ------------*/

