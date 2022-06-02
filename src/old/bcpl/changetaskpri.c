
/* A demo C code for using the bcpl.lib with Aztec C Compiler 3.6a */
/* Copyright (C) 1989 by Matthias Schmidt */

long atoi(cp)
register char *cp;
{
   long v = 0,s = 0;

   if (*cp == '+') ++cp;
   else if (*cp == '-') {
      s = 1;
      ++cp;
   }
   while (*cp) {
      if (*cp < '0' || *cp > '9')
         writef("Invalid char '%C' - ignored.\n",(long)*cp);
      else
         v = v * 10 + (*cp - '0');
      ++cp;
   }
   return s ? -v : v;
}

long start()
{
   long argv[16],*tt,*root(),rdargs(),taskid();

   if (rdargs("PRI/A,PROCESS/K",argv,16L)) {
      if ((argv[0] = atoi(argv[0])) < -128 || argv[0] > 127) {
         writes("Priority out of range (-128 to +127)\n");
         return 10;
      }
      tt = (long *)(root()->rn_TaskTable << 2);
      if (argv[1] && (argv[1] = atoi(argv[1])) < 1 ||
               argv[1] > tt[0]) {
         writef("Process %N does not exist\n",argv[1]);
         return 20;
      }
      doexec(_LVOSetTaskPri,argv[0],0L,0L,(argv[1] ? tt[argv[1]] :
            taskid()) - 0x5c);
      return 0;    }
   writes("Bad arguments\n");
   return 20;
}
