
#include <exec/memory.h>
#include <exec/resident.h>
#include <exec/execbase.h>

extern char *MemAddress, *MemSize;
extern short Attributes;
extern void AddMem();
extern int InitRes();

/*------ atol() - convert ascii string to long value ------*/

/* (note: supports decimal and hexadecimal ascii string!) */

long atol(cp)
char *cp;
{
   long l = 0;
   int s = 0, h = 0;

   if (*cp == '-' || *cp == '+') {
      s = (*cp == '+') ? 0 : 1;
      ++cp;
   }
   if (*cp == '0' && toupper(cp[1]) == 'X') {
      h = 1;
      cp += 2;
   } else if (*cp == '$') {
      h = 1;
      ++cp;
   }
   while (*cp) {
      if (!h) {
         if (*cp < '0' && *cp > '9')
            break;
         l = l * 10 + *cp - '0';
      } else {
         if (*cp >= '0' && *cp <= '9')
            l = (l << 4) + *cp - '0';
         else {
            if (toupper(*cp) < 'A' && toupper(*cp) > 'F')
               break;
            l = (l << 4) + toupper(*cp) - 'A' + 10;
         }
      }
      ++cp;
   }
   return (s ? -l : l);
}

usage()
{
   printf("AddMem II -- Copyright (C) 1990 by Matthias Schmidt\n");
   printf("Usage: AddMem [-rtca] <lower address> <upper address>\n");
   printf(" where -rtc are:\n");
   printf("    -r    Make the addmem command resident\n");
   printf("    -t    Test the memory area\n");
   printf("    -c    Clear the memory area\n");
   printf("    -ax   Specifies if chip (x=c) or fast memory (x=f)\n");
   printf("Example:\n");
   printf("1> AddMem 0x80000 0xfffff -r -af\n");
   exit(10);
}

#define F_LOSET 1
#define F_HISET 2
#define F_TEST  4
#define F_CLEAR 8
#define F_RES   16
#define F_CHIP  32
#define F_FAST  64

main(argc,argv)
char **argv;
{
   unsigned int i, j, f = 0;
   register unsigned char c, *cp, *la, *ua, *AllocMem();
   struct Resident *rp;

   if (argc < 3) {
      printf("AddMem II -- Copyright (C) 1990 by Matthias Schmidt\n");
      printf("Usage: AddMem [-rtca] <lower address> <upper address>\n");
      printf(" where -rtc are:\n");
      printf("    -r    Make 'AddMem' resident\n");
      printf("    -t    Test the memory\n");
      printf("    -c    Clear the memory\n");
      printf("    -ax   Specifies if chip (x=c) or fast memory (x=f)\n");
      printf("Example:\n");
      printf("1> AddMem 0x80000 0xfffff -raf\n");
      exit(10);
   }
   for (i = 1; i < argc; ++i) {
      if (!*argv[i]) continue;
      if (*argv[i] != '-') {
         if (!(f & (F_LOSET | F_HISET))) {
            la = (unsigned char *)atol(argv[i]);
            f |= 1;
            continue;
         }
         if (!(f & F_HISET)) {
            ua = (unsigned char *)atol(argv[i]);
            f |= 2;
            continue;
         }
         if ((f & (F_LOSET | F_HISET)) == 3) {
            printf("Too many arguments!\n");
            exit(10);
         }
      } else {
         for (j = 1; argv[i][j]; ++j) {
            switch (argv[i][j]) {
               case 'r':
               case 'R':
                  if (f & F_RES) goto bad_opt;
                  f |= F_RES;
                  break;
               case 't':
               case 'T':
                  if (f & F_TEST) goto bad_opt;
                  f |= F_TEST;
                  break;
               case 'c':
               case 'C':
                  if (f & F_CLEAR) goto bad_opt;
                  f |= F_CLEAR;
                  break;
               case 'a':
               case 'A':
                  if (f & F_CHIP || f & F_FAST) goto bad_opt;
                  switch (argv[i][++j]) {
                     case 'c':
                     case 'C':
                        f |= F_CHIP;
                        break;
                     case 'f':
                     case 'F':
                        f |= F_FAST;
                        break;
                     default:
                        printf("Bad attribute parameter!\n");
                        exit(10);
                  }
                  --j;
                  break;
               default:
bad_opt:
                  printf("Bad options!\n");
                  exit(10);
            }
         }
      }
   }
   if (!(f & (F_LOSET | F_HISET))) {
      printf("Missing arguments!\n");
      exit(10);
   }
   if (f & F_TEST) {
      c = 0;
      cp = la;
      while (cp < ua) *cp++ = c++;
      for (c = 0, cp = la; cp < ua; ++cp, ++c)
         if (*cp != c) {
            printf("Error at address 0x%lx -- there is: %u, \
and there should be %u!\n", cp, (unsigned)*cp, (unsigned)c);
            f = -1;
         }
      if (f == -1) {
         printf("Your memory is damaged!\n");
         exit(20);
      }
      printf("Memory tested.\n");
   }
   if (f & F_CLEAR) {
      for (cp = la; cp < ua; *cp++ = 0);
      printf("Memory cleared.\n");
   }
   MemAddress = (char *)((((unsigned long)la) + 7) & ~(7L));
   MemSize = ((unsigned long)(ua - la) + 1L) & ~(7L);
   Attributes = (f & F_CHIP ? MEMF_CHIP : 0) | ((f & F_FAST ||
         !(f & F_CHIP)) ? MEMF_FAST : 0) | MEMF_PUBLIC;
   if (f & F_RES) {
      if (!InitRes()) {
         printf("Not enough chip memory for resident code!\n");
         exit(20);
      }
   }
   AddMem();
   exit(0);
}
