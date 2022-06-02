
long _main()
{
   char *argv[16];
   long *rdargs(), *cli(), callgv();
   void writes();

   if (rdargs("PROMPT",argv,16L))
      callgv(-0x7cL,argv[0] ? argv[0] : "> ",cli()[6]);
   else
      writes("Parameters no good for PROMPT\n");
   return 0;
}

