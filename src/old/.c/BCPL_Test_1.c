
#define rdargs(s,b,c) bcpl(0x138L,get_bstr(s),(long)b>>2,(long)c)
#define writes(s) bcpl(0x124L,get_bstr(s))
#define writef(s,a,b,c) bcpl(0x128L,get_bstr(s),a,b,c)

#define BUFLONGS 64

void *malloc();
long bcpl();

long get_bstr(s)
char *s;
{
   long bp;
   int l = strlen(s);

   if (bp = (long)malloc(l+1)) {
      strncpy((char *)bp+1,s,l);
      *(char *)bp = (char)l;
      return bp>>2;
   } else {
      puts("Not enough memory for a BCPL-String !");
      exit(1);
   }
}

main()
{
   long buffer[BUFLONGS+1];
   long *buf = (long *)(((long)&buffer[1])&-4L);

   writes("C<>BCPL-Interface-Test-Program - © 1989 by M.Schmidt\n");
   if (rdargs("FROM/A,TO/A,NOJOIN/S",buf,BUFLONGS))
      writef("FROM: %S - TO: %S - NOJOIN: %S\n",
         buf[0],buf[1],buf[2] ? get_bstr("YES"):get_bstr("NO"));
}
