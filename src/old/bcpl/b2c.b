
//
// BCPL-Compiler 1.0a for Aztec C68K 3.6a
// (C) 1989 by Matthias Schmidt
//

#include "bcpl.h"

LET change_ext(s,t) VALOF
register char *s, *t;
$(
   LET rc := (LET) t;

   while (*s && *s != '.') *t++ := *s++;
   *t++ := '.';
   *t++ := 'c';
   *t := 0;
   RESULTIS rc;
$)

LET start() BE
$(
   LET rfh, wfh, ti, to;
   LET argv[40], wfn[40];
   register unsigned char lch;
   register LET ch := 0, rc := 20;

   TEST rdargs("FROM/A,TO",argv,40L) THEN
   $(
      IF !argv[1] THEN
      $(
         argv[1] := change_ext(argv[0],wfn);
      $)
      TEST rfh := findinput(argv[0]) THEN
      $(
         TEST wfh := findoutput(argv[1]) THEN
         $(
            $(
               ti := input();
               to := output();
               writef("BCPL - Aztec C68K - Compiler 0.12a  06-03-89  %S\n",
                     "(C) 1989 by Matthias Schmidt");
               selectinput(rfh);
               selectoutput(wfh);
               rc := 0;
               do
               $(
                  TEST testbreak(1L) THEN
                  $(
                     selectoutput(to);
                     writes("*** BREAK\n");
                     rc := 10;
                     break;
                  $)
                  lch := ch;
                  SWITCHON ch := rdch() INTO
                  $(
                     CASE '$':
                        SWITCHON ch := rdch() INTO
                        $(
                           CASE '(':
                              ch := '{';
                              break;
                           CASE ')':
                              ch := '}';
                              break;
                           DEFAULT:
                              wrch('$');
                              break;
                        $)
                        break;
                     CASE ':':
                        IF (ch := rdch()) != '=' THEN
                        $(
                           wrch(':');
                        $)
                        break;
                     CASE '=':
                        IF (lch >= 'A' && lch <= 'Z') || (lch >= 'a' &&
                              lch <= 'z') || (lch >= '0' && lch <= '9') ||
                              lch = ' ' || lch = '_' THEN
                        $(
                           wrch(ch);
                        $)
                        break;
                     CASE '/':
                        IF (ch := rdch()) != '/' THEN
                        $(
                           wrch('/');
                           break;
                        $)
                        while ((ch := rdch()) != 10);
                        break;
                  $)
                  IF (ch != -1) THEN
                  $(
                     wrch(ch);
                  $)
               $) REPEATUNTIL (ch = -1);
               selectinput(ti);
               selectoutput(to);
            $)
            close(wfh);
         $)
         ELSE
         $(
            writef("Unable to open %S for writing - ",argv[1]);
            fault(result2(FALSE));
         $)
         close(rfh);
      $)
      ELSE
      $(
         writef("Unable to open %S for reading - ",argv[0]);
         fault(result2(FALSE));
      $)
   $)
   ELSE
   $(
      writes("Bad arguments\n");
   $)
   stop(rc);
$)

