/* Copyright (C) 1990 by Matthias Schmidt */


/*
 *  SetConfig.c -- M&T AutoBoot Software Configuration Utility
 *
 *  version 1.0
 */


#include "defs.h"


/*------------ main() ------------*/

void main(int argc, char **argv)
{
   printf("\nSetConfig -- M&T AutoBoot Software Configuration Utility v1.0\n"
         "Copyright (C) 1990 by Matthias Schmidt\n\n");

   printf("Usage: %s [SYSCONFIG [KEYMAP [CMOS-BOOTPRI [WAIT-TIME]]]]\n",
         *argv);
   exit(0);
}

