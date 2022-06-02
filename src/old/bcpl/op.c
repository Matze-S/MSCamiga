
/*

       Aztec 68000 Assembler Optimizer 3.6a

      Copyright (C) 1989 by Matthias Schmidt


      Note: This program needs the 'bcpl.lib'
         Compile with 'cc optimizer.c' and
         link with 'ln optimizer.o -lbcpl'

*/

#include "bcpl.h"

long start(g)
struct globals g;
{
   long argv[40],wfn[40],*buf,rfh,wfh,ifh,ofh,rc = 20,len,flt = FALSE;

   writef("\015Aztec 68000 Assembler Optimizer 3.6a  06-05-89  %S\n",
         "(C) 1989 by Matthias Schmidt");
   if (rdargs("FROM/A,TO/K",argv,40L)) {
      if (!argv[1]) {
         register char *s = (char *)argv[0],
               *t = (char *)(argv[1] = (long)wfn);

         while (*s && *s != '.') *t++ = *s++;
         t[0] = '.';
         t[1] = 'o';
         t[2] = 'p';
         t[3] = 't';
         t[4] = 0;
      }
      ifh = input();
      ofh = output();
      flt = TRUE;
      if (rfh = findinput(argv[0])) {
         selectinput(rfh);
         if (wfh = findoutput(argv[1])) {
            selectoutput(wfh);
            flt = FALSE;
            if (buf = palloc(2048L)) {
               flt = TRUE;
               rc = 0;
               while ((len = read(buf,8192L)) && len != -1)
                  if (write(buf,len) != len) {
                     selectoutput(ofh);
                     writef("\nError while writing %S - ",argv[1]);
                     rc = 20;
                     len = 0;
                     break;
                  }
               if (len) {
                  selectoutput(ofh);
                  writef("\nError while reading %S - ",argv[0]);
                  rc = 20;
               }
               free(buf);
            } else {
               selectoutput(ofh);
               writes("Not enough memory !\n");
            }
            selectoutput(ofh);
            close(wfh);
         } else
            writef("Unable to open %S for writing - ",argv[1]);
         endread();
         selectinput(ifh);
      } else
         writef("Unable to open %S for reading - ",argv[0]);
      if (flt) fault(result2(FALSE));
   } else
      writes("Bad arguments\n");
   return rc;
}

