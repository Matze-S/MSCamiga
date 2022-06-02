/* Copyright (C) 1990 by Matthias Schmidt */

/*
 *  defs.h
 */

#include <exec/types.h>
#include <exec/io.h>
#include <exec/ports.h>
#include <libraries/dosextens.h>
#include <libraries/filehandler.h>
#include <ctype.h>
#include <fcntl.h>
#include <functions.h>
#include <pragmas.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "Harddisk.h"

#define RDVAL_TRYAGAIN -32767       /* try this call again */
#define RDRNG_NORANGE -32766        /* don't print range and suggestion */
#define RDRNG_NOSUGG -32767         /* don't print a suggestion */

char *rdtxt(char *text, char *sugg);
int ask(char *text, char sugg);
int rdrng(char *text, int min, int max, int sugg);
int rdval(int sugg);
int stricmp(char *string1, char *string2);

/*------------ end of source ------------*/

