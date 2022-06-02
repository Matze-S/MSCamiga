
#include "bcpl.h"

/*
   A2PC.c - Convert AMIGA-ASCII (ANSI X3.64-1979) to IBM-PC-ASCII
   Copyright (C) 07-Mar-1988 by Ralph Babel, Falkenweg 3, D-6204 Taunusstein
   all rights reserved - alle Rechte vorbehalten
*/

#define return_ok       0L
#define return_hard     10L
#define ENDSTREAMCH     -1L

#define AMY_UC_A_UMLAUT 0xC4
#define AMY_UC_O_UMLAUT 0xD6
#define AMY_UC_U_UMLAUT 0xDC
#define AMY_LC_A_UMLAUT 0xE4
#define AMY_LC_O_UMLAUT 0xF6
#define AMY_LC_U_UMLAUT 0xFC
#define AMY_ESZET       0xDF

#define IBM_UC_A_UMLAUT 142
#define IBM_UC_O_UMLAUT 153
#define IBM_UC_U_UMLAUT 154
#define IBM_LC_A_UMLAUT 132
#define IBM_LC_O_UMLAUT 148
#define IBM_LC_U_UMLAUT 129
#define IBM_ESZET       225
#define IBM_EOF         26

#define ASC_LF  10
#define ASC_CR  13

#define arg_upb     64  /* argument upper bound */
#define argv_from   0
#define argv_to     1
#define argv_nojoin 2

/* code section */

LET convert(ch) VALOF
LET ch;
{
   SWITCHON (ch) INTO
   {
      CASE AMY_UC_A_UMLAUT:
       RESULTIS IBM_UC_A_UMLAUT;
      CASE AMY_UC_O_UMLAUT:
       RESULTIS IBM_UC_O_UMLAUT;
      CASE AMY_UC_U_UMLAUT:
       RESULTIS IBM_UC_U_UMLAUT;
      CASE AMY_LC_A_UMLAUT:
       RESULTIS IBM_LC_A_UMLAUT;
      CASE AMY_LC_O_UMLAUT:
       RESULTIS IBM_LC_O_UMLAUT;
      CASE AMY_LC_U_UMLAUT:
       RESULTIS IBM_LC_U_UMLAUT;
      CASE AMY_ESZET:
       RESULTIS IBM_ESZET;
      DEFAULT:
       RESULTIS ch;
   }
}

/* main entry point */

LET start() BE
{
   register LET rc = return_hard, flag = TRUE, rch, wch;
   LET termin, termout, filein, fileout, argv[arg_upb];

   TEST (rdargs("FROM/A,TO/A,NOJOIN/S", argv, (long)arg_upb)) THEN
   {
      filein = findinput(argv[argv_from]);
      TEST (filein) THEN
      {
         termin = input();
         selectinput(filein);

         fileout = findoutput(argv[argv_to]);
         TEST (fileout) THEN
         {
            termout = output();
            selectoutput(fileout);

            do
            {
               rch = rdch();
               SWITCHON (rch) INTO
               {
                  CASE '\n':
                     IF (!argv[argv_nojoin]) THEN
                     {
                        rch = rdch();
                        flag = flag || rch == '\n' ||
                              rch == ' ' || rch == ENDSTREAMCH;
                        TEST (flag) THEN
                        {
                           wrch((long)ASC_CR);
                           wrch((long)ASC_LF);
                        }
                        ELSE
                        {
                           wrch((long)' ');
                        }
                     }

                     IF (rch == '\n') THEN
                     {
                        wrch((long)ASC_CR);
                        wch = ASC_LF;
                        break;
                     }
                  DEFAULT:
                     flag = FALSE;
                     wch = convert(rch);
               }

               IF (wch != ENDSTREAMCH) THEN
               {
                  wrch(wch);
               }

            } REPEATUNTIL (wch == ENDSTREAMCH);

            wrch((long)IBM_EOF);

            rc = return_ok;

            endwrite();
            selectoutput(termout);
         }
         ELSE
         {
            writef("Can't open \"%S\" for output - ", argv[argv_to]);
            fault(result2(FALSE));
         }

         endread();
         selectinput(termin);
      }
      ELSE
      {
         writef("Can't open \"%S\" for input - ", argv[argv_from]);
         fault(result2(FALSE));
      }
   }
   ELSE
   {
      writes("Usage: A2PC [FROM] <amiga-ascii> [TO] <ibm-ascii> [NOJOIN]\n");
   }

   stop(rc);
}

