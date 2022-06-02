
long _main()
{
   char *argv[80];
   long *rdargs();
   void writes();

   if (rdargs("",argv,80L)) {
      writes(argv[0]);
      writes("\n");
   } else
      writes("Invalid argument to ECHO\n");
}

