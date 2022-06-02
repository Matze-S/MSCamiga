arclist
arclist
cli.c
comm1.c
comm2.c
dir.c
execom.c
fexec.c
globals.c
info.c
main.c
makeami
makefile
RawConsole.c
readme.205m
run.c
set.c
shell.doc
shell.h
sort.c
sub.c
tags

cli.c

#include "shell.h"

static struct CommandLineInterface *cli = NULL;

init_cli()
{
   register struct CommandLineInterface *clip;
   register long *lp, l, *slp, *olp;
   register struct Process *pp,*wbpp;
   char *cp;

   if ((pp = (struct Process *)FindTask(NULL))->pr_CLI) return 1;
   if (cli = clip = (struct CommandLineInterface *)
            malloc(sizeof *clip + (78 * 4))) {
      lp = (long *)(clip + 1);
      for (l = 0; l < 78; ++l) lp[l] = 0L;
      lp[0] = (long)&lp[1] >> 2;
      lp[11] = (long)&lp[12] >> 2;
      lp[44] = (long)&lp[45] >> 2;
      lp[56] = (long)&lp[57] >> 2;
      clip->cli_Result2 = clip->cli_ReturnCode = clip->cli_Background = 0L;
      clip->cli_SetName = lp[56];
      *(cp = (char *)&lp[57]) = 4;
      clip->cli_CommandName = lp[11];
      clip->cli_FailLevel = 10L;
      clip->cli_Prompt = lp[0];
      *(cp = (char *)&lp[1]) = 4;
      strncpy(cp + 1,"%N> ",4);
      clip->cli_Interactive = IsInteractive(clip->cli_StandardInput =
            clip->cli_CurrentInput = (long)Input());
      clip->cli_CommandFile = lp[44];
      clip->cli_CurrentOutput = clip->cli_StandardOutput = (long)Output();
      clip->cli_DefaultStack = pp->pr_StackSize;
      clip->cli_Module = clip->cli_CommandDir = NULL;
      if ((wbpp = (struct Process *)FindTask("Workbench")) &&
               wbpp->pr_CLI && (lp = (long *)BADDR
               (((struct CommandLineInterface *)
               BADDR(wbpp->pr_CLI))->cli_CommandDir))) {
         olp = (long *)&clip->cli_CommandDir;
         do {
            if ((slp = (long *)AllocMem(12L,1L)) == NULL ||
                     (slp[2] = (long)DupLock(lp[1])) == NULL) {
               cleanup_cli();
               return 0;
            }
            slp[0] = 12L;
            slp[1] = 0L;
            *olp = (long)++slp >> 2;
            olp = slp;
         } while (lp = (long *)BADDR(lp[0]));
      }
      pp->pr_CLI = (BPTR)clip >> 2;
      return 1;
   } else
      return 0;
}

cleanup_cli()
{
   if (cli) {
      free_path();
      ((struct Process *)FindTask(NULL))->pr_CLI = NULL;
      free(cli);
      cli = NULL;
   }
}

free_path()
{
   register struct CommandLineInterface *clip =
         (struct CommandLineInterface *)BADDR(((struct Process *)
         FindTask(NULL))->pr_CLI);
   register long *slp, *lp = (long *)BADDR(clip->cli_CommandDir);

   while (slp = lp) {
      lp = (long *)BADDR(*slp);
      UnLock(slp[1]);
      FreeMem(--slp,12L);
   }
   clip->cli_CommandDir = NULL;
}
comm1.c
/*
 * COMM1.C
 *
 * Matthew Dillon, August 1986
 *
 * version 2.05M (Manx Version and Additions) by Steve Drew 20-Jan-87
 *
 */

#include "shell.h"
typedef struct FileInfoBlock FIB;
 
#define DIR_SHORT 0x01
#define DIR_FILES 0x02
#define DIR_DIRS  0x04
#define DIR_EXCLUDE 0x08

#define BPTR_TO_C(strtag, var)  ((struct strtag *)(BADDR( (ULONG) var)))
#define C_TO_BPTR(strtag, var)  ((struct strtag *)(((ULONG)var)>>2))

extern char *btocstr();
extern int has_wild;
char cwd[256];
struct FileLock *Clock;
  
do_sleep()
{
   register int i;
 
   if (ac == 2) {
      i = atoi(av[1]);
      while (i > 0) {
         Delay ((long)50*2);
         i -= 2;
         if (CHECKBREAK())
            break;
      }
   }
   return (0);
}
 
 
do_number()
{
   return (0);
}
 
do_cat()
{
   FILE *fopen(), *fi;
   int i;
   char buf[256];

   if (ac == 1) {
      while (gets(buf)) {
      	 if (CHECKBREAK()) break;
         puts(buf);
         }
      clearerr(stdin);
      return (0);
   }

   for (i = 1; i < ac; ++i) {
      if ((fi = fopen (av[i], "r")) != 0) {
           while (fgets(buf,256,fi)) {
            fputs(buf,stdout);
            fflush(stdout); 
            if (CHECKBREAK()) {
               breakreset();
               break;
            }
         }
         fclose (fi);
      } else {
         fprintf (stderr, "could not open %s\n", av[i]);
      }
   }
   return (0);
}

/* things shared with disp_entry */

int   filecount, col; 
long  bytes, blocks;

do_dir(garbage, com)
char *garbage;
{
   void   		disp_entry();
   struct DPTR          *dp;
   struct InfoData      *info;
   char                 *name;
   int                  i = 0, stat, clen, more;
   char                 options = 0;
   char                 *c;
   char			exclude[40];
   char                 lspec[256];
   char                 volume[40];
   char                 *volname();
   char			*dates();
  
   col = filecount = 0;
   bytes = blocks = 0L;
   
   while((++i < ac) && (av[i][0] == '-')) {
   	for (c = av[i]+1; *c ; c++) {
   		switch(*c) {
   			case 's':
   				options |= DIR_SHORT;
   				break;
   			case 'f':
   				options |= DIR_FILES;
   				break;
   			case 'd':
   				options |= DIR_DIRS;
   				break;
   			case 'e':
   				options |= DIR_EXCLUDE;
   				strcpy(exclude,"*");
   				strcat(exclude,av[++i]);
   				strcat(exclude,"*");
   				break;
   			default:
   				break;
   		}
   	}
   }
   
   if (ac == i) {
      ++ac;
      av[i] = "";
   if (has_wild)
      return(0);
   }
   if (!(options & (DIR_FILES | DIR_DIRS)))  options |= (DIR_FILES | DIR_DIRS);
   
   for (; i < ac; ++i) {
      if (!(dp = dopen (av[i], &stat)))
         continue;
      if (com < 0) {
         info = (struct InfoData *)AllocMem((long)sizeof(struct InfoData), MEMF_PUBLIC);
         if (Info (dp->lock, info)) {
            printf ("Unit:%2ld  Errs:%3ld  Used: %-4ld %3ld%% Free: %-4ld  Volume: %s\n",
                  info->id_UnitNumber,
                  info->id_NumSoftErrors,
                  info->id_NumBlocksUsed,
                  (info->id_NumBlocksUsed * 100)/ info->id_NumBlocks,
                  (info->id_NumBlocks - info->id_NumBlocksUsed),
                  volname(dp->lock,volume));

         } else {
            pError (av[i]);
         }
         FreeMem (info,(long) sizeof(*info));
         dclose(dp);
         continue;
         return(0);
      } 
 
     /* start of directory routine */
      
            c = av[i];
            clen = strlen(c);
            if (!stat || has_wild) {    /* if not wild and is a dir don't */
                                         /* extract dir from file name     */
               while (clen && c[clen] != '/' && c[clen] != ':') clen--;
               if (c[clen] == ':' || c[clen] == '/') clen++;
               c[clen] = '\0';
            }
            if (!clen)  c = cwd;
            if (strcmp (c, &lspec) != 0)  {
               strcpy(lspec, c);
               if (col)    printf("\n");
               printf ("Directory of %s\n", lspec);
               fflush(stdout);
               col = 0;
            } 
            more = stat;
            do {
            	if (more && !has_wild) {
            	    *lspec = '\0';
            	    if (!(more = dnext(dp, &name, &stat)))
            	    break;
            	}
                if (CHECKBREAK()) {
              	   i = ac;
              	   break;
                }
                disp_entry (dp->fib, options,exclude);
      } while(more && !has_wild);     
      dclose(dp); 
    }                /* end for */
   if (col)  printf("\n");    
   if (filecount > 1) {
       blocks += filecount;     /* account for dir blocks */
       printf (" %ld Blocks, %ld Bytes used in %d files\n", blocks, bytes, filecount);
   }
   return (0);
}

char *
volname(lock,buf)
struct FileLock *lock;
char *buf;
{

        struct    DeviceList    *dl;
        char                    *p;

     Forbid();
                /* Only way I know to get Volume label since InfoData  */
                /* seems to always have NULL for this string           */

        lock = BPTR_TO_C(FileLock, lock);
        dl = BPTR_TO_C(DeviceList, lock->fl_Volume);
        p = btocstr(dl->dl_Name,buf);

     Permit();
     return p;
}

void
disp_entry(fib, options, exclude)
char options;
char *exclude;
register struct FileInfoBlock *fib;
{

   char str[5];
   int italics;
   char s;   
   
   if (!(((options & DIR_FILES) && (fib->fib_DirEntryType < 0)) || 
         ((options & DIR_DIRS)  && (fib->fib_DirEntryType > 0))))
                return;

   if ((options & DIR_EXCLUDE) && (compare_ok(exclude,fib->fib_FileName)))
           return;
                
 if (!(options & DIR_SHORT)) { 
   str[4] = '\0';
   str[0] = (fib->fib_Protection & FIBF_READ) ? '-' : 'r';
   str[1] = (fib->fib_Protection & FIBF_WRITE) ? '-' : 'w';
   str[2] = (fib->fib_Protection & FIBF_EXECUTE) ? '-' : 'e';
   str[3] = (fib->fib_Protection & FIBF_DELETE) ? '-' : 'd';

   printf ("   %-24s  %s  ", fib->fib_FileName, str);
   if (fib->fib_DirEntryType < 0) printf("%6ld %4ld", (long)fib->fib_Size, (long)fib->fib_NumBlocks);
    else printf("   Dir     ");
   printf("  %s", dates(&fib->fib_Date));
   fflush(stdout);
   } 
   else {
   
        if ((col == 3) && strlen(fib->fib_FileName)>18) {
            printf("\n");
            col = 0;
        } 
        if (fib->fib_DirEntryType > 0)  {
            printf ("\033[3m");
            italics = 1;
        }
        if (strlen(fib->fib_FileName)>18) {
            printf(" %-37s",fib->fib_FileName);
            col += 2;
        } 
        else { 
            printf(" %-18s",fib->fib_FileName);
            col++;
        } 
        if (col > 3) {
            printf("\n");
            col = 0;
        }
        if (italics) printf("\033[0m");
   }
   fflush(stdout);
   blocks += fib->fib_NumBlocks;
   bytes  += fib->fib_Size;
   filecount++;
   return;
}

/* converts dos date stamp to a time string of form dd-mmm-yy  */

char *
dates(dss)
struct DateStamp *dss;
{
   register struct tm tm;
   register long time, t;
   register int i;
   static char timestr[20];
   static char months[12][4] = {
   	"Jan","Feb","Mar","Apr","May","Jun",
   	"Jul","Aug","Sep","Oct","Nov","Dec"
   };
   static char days[12] = {
   	31,28,31,30,31,30,31,31,30,31,30,31
   };
   time = dss->ds_Days * 24 * 60 * 60 + dss->ds_Minute * 60 +
   				       dss->ds_Tick/TICKS_PER_SECOND;
   tm.tm_sec = time % 60; time /= 60;
   tm.tm_min = time % 60; time /= 60;
   tm.tm_hour= time % 24; time /= 24;
   tm.tm_wday= time %  7;
   tm.tm_year= 78 + (time/(4*365+1)) * 4; time %= 4 * 365 + 1;
   while (time) {
   	t = 365;
   	if ((tm.tm_year&3) == 0) t++;
   	if (time < t) break;
   	time -= t;
   	tm.tm_year++;
   }
   tm.tm_yday = ++time;
   for (i=0;i<12;i++) {
   	t = days[i];
   	if (i == 1 && (tm.tm_year&3) == 0) t++;
   	if (time <= t) break;
   	time -= t;
   }  
   tm.tm_mon = i;
   tm.tm_mday = time;
   
   sprintf(timestr,"%02d-%s-%2d %02d:%02d:%02d\n",tm.tm_mday,
   		months[tm.tm_mon],tm.tm_year,
   		tm.tm_hour,tm.tm_min,tm.tm_sec);
   return(timestr);
   
}
 
date()
{
   struct   DateStamp   dss;
   char *s, *dates();

   DateStamp(&dss);
   s = dates(&dss);
   printf("%s",s);
   return(0);
}
 
do_quit()
{
   if (Src_stack) {
      Quit = 1;
      return(do_return());
   }
   main_exit (0);
}
 
 
do_echo(str)
char *str;
{
   register char *ptr;
   char nl = 1;
 
   for (ptr = str; *ptr && *ptr != ' '; ++ptr);
   if (*ptr == ' ')
      ++ptr;
   if (av[1] && strcmp (av[1], "-n") == 0) {
      nl = 0;
      ptr += 2;
      if (*ptr == ' ')
         ++ptr;
   }
   printf("%s",ptr);
   fflush(stdout);
   if (nl)
      printf("\n");
   return (0);
}

do_source(str)
char *str;
{
   register FILE *fi;
   char buf[256];

   if (Src_stack == MAXSRC) {
      printf (stderr,"Too many source levels\n");
      return(-1);
   }
   if ((fi = fopen (av[1], "r")) == 0) {
      fprintf (stderr,"Cannot open %s\n", av[1]);
      return(-1);
   }   
   set_var(LEVEL_SET, V_PASSED, next_word(next_word(str)));
   ++H_stack;
   Src_pos[Src_stack] = 0;
   Src_base[Src_stack] = (long)fi;
   ++Src_stack;
   while (fgets (buf, 256, fi)) {
      buf[strlen(buf)-1] = '\0';
      Src_pos[Src_stack - 1] += 1+strlen(buf);
      if (Verbose)
         fprintf(stderr,"%s\n",buf);
      exec_command (buf);
      if (CHECKBREAK())
         break;
   }
   --H_stack;
   --Src_stack;
   unset_level(LEVEL_LABEL + Src_stack);
   unset_var(LEVEL_SET, V_PASSED);
   fclose (fi);
   return (0);
}

/*
 * CD
 *
 * CD(str, -1)      -do pwd and display current cd. if str = NULL don't disp.
 * CD(str, 0)       -do CD operation.
 *
 *    standard operation: breakup path by '/'s and process independantly
 *    x:    -reset cwd base
 *    ..    -remove last cwd element
 *    N     -add N or /N to cwd
 */

do_cd(str, com)
char *str;
{
   char sc, *ptr;
   char *name;

   if (com < 0) {
      struct FileLock *lock, *newlock;
      FIB *fib;
      int i, len;

      fib = (FIB *)AllocMem((long)sizeof(FIB), MEMF_PUBLIC);
      if ((Clock = (struct FileLock *)Myprocess->pr_CurrentDir) == 0) 
          attempt_cd(":"); /* if we just booted 0 = root lock */
      lock = (struct FileLock *)DupLock(Clock);
      cwd[i = 255] = '\0';
      
      while (lock) {
         newlock = (struct FileLock *)ParentDir(lock);
         Examine(lock, fib);
         name = fib->fib_FileName;
         if (*name == '\0')            /* HACK TO FIX RAM: DISK BUG */
            name = "ram";
         len = strlen(name);
         if (newlock) {
            if (i == 255) {
               i -= len;
               bmov(name, cwd + i, len);
            } else {
               i -= len + 1;
               bmov(name, cwd + i, len);
               cwd[i+len] = '/';
            }
         } else {
            i -= len + 1;
            bmov(name, cwd + i, len);
            cwd[i+len] = ':';
         }
         UnLock(lock);
         lock = newlock;
      }
      FreeMem(fib, (long)sizeof(FIB));
      bmov(cwd + i, cwd, 256 - i);
      if (str)
         puts(cwd);
      set_var(LEVEL_SET, V_CWD, cwd);
 
     /* put the current dir name in our CLI task structure */

      ptr = (char *)((ULONG)((struct CommandLineInterface *)
          BADDR(Myprocess->pr_CLI))->cli_SetName << 2);
      ptr[0] = strlen(cwd);
      movmem(cwd,ptr+1,(int)ptr[0]);
      return (0);
   }
   str = next_word(str);
   if (*str == '\0')
      puts(cwd);
   str[strlen(str)+1] = '\0';          /* add second \0 on end */
   while (*str) {
      for (ptr = str; *ptr && *ptr != '/' && *ptr != ':'; ++ptr);
      switch (*ptr) {
      case ':':
         sc = ptr[1];
         ptr[1] = '\0';
         if (attempt_cd(str))
            strcpy(cwd, str);
         ptr[1] = sc;
         break;
      case '\0':
      case '/':
         *ptr = '\0';
         if (strcmp(str, "..") == 0 || str == ptr)
            str = "/";
         if (*str && attempt_cd(str)) {
            if (*str == '/') {
               rmlast(cwd);
            } else {
               if (cwd[0] == 0 || cwd[strlen(cwd)-1] != ':')
                  strcat(cwd, "/");
               strcat(cwd, str);
            }
         }
         break;
      }
      str = ptr + 1;
   }
   do_cd(NULL,-1);
}

attempt_cd(str)
char *str;
{
   struct FileLock *oldlock, *filelock;

   if (filelock = (struct FileLock *)Lock(str, ACCESS_READ)) {
      if (isdir(str)) {
         if (oldlock = (struct FileLock *)CurrentDir(filelock))
            UnLock(oldlock);
         Clock = filelock;
         return (1);
      }
      UnLock(filelock);
      ierror(str, 212);
   } else {
      ierror(str, 205);
   }
   return (0);
}


/*
 * remove last component. Start at end and work backwards until reach
 * a '/'
 */

rmlast(str)
char *str;
{
   char *ptr = str + strlen(str) - 1;
   while (ptr != str && *ptr != '/' && *ptr != ':')
      --ptr;
   if (*ptr != ':')
      ptr[0] = '\0';
   else
      ptr[1] = '\0';
}


do_mkdir()
{
   register int i;
   register struct FileLock *lock;

   for (i = 1; i < ac; ++i) {
      if (lock = (struct FileLock *)CreateDir (av[i])) {
         UnLock (lock);
         continue;
      }
      pError (av[i]);
   }
   return (0);
}


do_mv()
{
   char dest[256];
   register int i;
   char *str;

   --ac;
   if (isdir(av[ac])) {
      for (i = 1; i < ac; ++i) {
         str = av[i] + strlen(av[i]) - 1;
         while (str != av[i] && *str != '/' && *str != ':')
            --str;
         if (str != av[i])
            ++str;
         if (*str == 0) {
            ierror(av[i], 508);
            return (-1);
         }
         strcpy(dest, av[ac]);
         if (dest[strlen(dest)-1] != ':')
            strcat(dest, "/");
         strcat(dest, str);
         if (Rename(av[i], dest) == 0)
            break;
      }
      if (i == ac)
         return (1);
   } else {
      i = 1;
      if (ac != 2) {
         ierror("", 507);
         return (-1);
      }
      if (Rename (av[1], av[2]))
         return (0);
   }
   pError (av[i]);
   return (-1);
}

rm_file(file)
char *file;
{
      if (has_wild) printf("  %s...",file);
      fflush(stdout);
      if (!DeleteFile(file))
         pError (file);
      else 
         if (has_wild) printf("Deleted\n");
}

do_rm()
{
   register short i, recur;
 
   recur = (strncmp(av[1], "-r", 2)) ? 0 : 1;
 
   for (i = 1 + recur; i < ac; ++i) {
      if (CHECKBREAK()) break;
      if (isdir(av[i]) && recur)
         rmdir(av[i]);
      if (!(recur && av[i][strlen(av[i])-1] == ':')) 
         rm_file(av[i]);
   }
   return (0);
}
 
rmdir(name)
char *name;
{
   register struct FileLock *lock, *cwd;
   register FIB *fib;
   register char *buf;
 
   buf = (char *)AllocMem(256L, MEMF_PUBLIC);
   fib = (FIB *)AllocMem((long)sizeof(FIB), MEMF_PUBLIC);
 
   if (lock = (struct FileLock *)Lock(name, ACCESS_READ)) {
      cwd = (struct FileLock *) CurrentDir(lock);
      if (Examine(lock, fib)) {
         buf[0] = 0;
         while (ExNext(lock, fib)) {
            if (CHECKBREAK()) break;
            if (isdir(fib->fib_FileName))
               rmdir(fib->fib_FileName);
            if (buf[0]) {
               rm_file(buf);
            }
            strcpy(buf, fib->fib_FileName);
         }
         if (buf[0] && !CHECKBREAK()) {
            rm_file(buf);
         }
      }
      UnLock(CurrentDir(cwd));
   } else {
      pError(name);
   }
   FreeMem(fib, (long)sizeof(FIB));
   FreeMem(buf, 256L);
}
 
 
 
do_history()
{
   register struct HIST *hist;
   register int i = H_tail_base;
   register int len = (av[1]) ? strlen(av[1]) : 0;
 
   for (hist = H_tail; hist; hist = hist->prev) {
      if (len == 0 || strncmp(av[1], hist->line, len) == 0) {
         printf ("%3d ", i);
         puts (hist->line);
      }
      ++i;
      if (CHECKBREAK())
         break;
   }
   return (0);
}
 
do_mem()
{
   long cfree, ffree;
   extern long AvailMem();

   Forbid();
   cfree = AvailMem (MEMF_CHIP);
   ffree = AvailMem (MEMF_FAST);
   Permit();

   if (ffree)       {
   printf ("FAST memory: %ld\n", ffree);  
   printf ("CHIP memory: %ld\n", cfree);   
   }
   printf ("Total  Free: %ld\n", cfree + ffree);
   return(0);
}

/*
 * foreach var_name  ( str str str str... str ) commands
 * spacing is important (unfortunetly)
 *
 * ac=0    1 2 3 4 5 6 7
 * foreach i ( a b c ) echo $i
 * foreach i ( *.c )   "echo -n "file ->";echo $i"
 */
 
do_foreach()
{
   register int i, cstart, cend, old;
   register char *cstr, *vname, *ptr, *scr, *args;
 
   cstart = i = (*av[2] == '(') ? 3 : 2;
   while (i < ac) {
      if (*av[i] == ')')
         break;
      ++i;
   }
   if (i == ac) {
      fprintf (stderr,"')' expected\n");
      return (-1);
   }
   ++H_stack;
   cend = i;
   vname = strcpy(malloc(strlen(av[1])+1), av[1]);
   cstr = compile_av (av, cend + 1, ac);
   ptr = args = compile_av (av, cstart, cend);
   while (*ptr) {
      while (*ptr == ' ' || *ptr == 9)
         ++ptr;
      scr = ptr;
      if (*scr == '\0')
         break;
      while (*ptr && *ptr != ' ' && *ptr != 9)
         ++ptr;
      old = *ptr;
      *ptr = '\0';
      set_var (LEVEL_SET, vname, scr);
      if (CHECKBREAK())
         break;
      exec_command (cstr);
      *ptr = old;
   }
   --H_stack;
   free (args);
   free (cstr);
   unset_var (LEVEL_SET, vname);
   free (vname);
   return (0);
}
 

do_forever(str)
char *str;
{
   int rcode = 0;
   char *ptr = next_word(str);

   ++H_stack;
   for (;;) {
      if (CHECKBREAK()) {
         rcode = 20;
         break;
      }
      if (exec_command (ptr) < 0) {
         str = get_var(LEVEL_SET, V_LASTERR);
         rcode = (str) ? atoi(str) : 20;
         break;
      }
   }
   --H_stack;
   return (rcode);
}


/*
 * CP file file
 * CP file file file... destdir
 * CP [-r] dir dir dir... destdir
 */

char *errstr;          /* let's be alittle more informative */
 
do_copy()
{
   register short recur, i, ierr;
   register char *destname;
   register char destisdir;
   register FIB *fib;
   
   errstr = "";
   ierr = 0;
   fib = (FIB *)AllocMem((long)sizeof(FIB), MEMF_PUBLIC);	/* 0 => PUBLIC jgII */
   recur = (strncmp(av[1], "-r", 2)) ? 0 : 1;
   destname = av[ac - 1];
 
   if (ac < recur + 3) {
      ierr = 500;
      goto done;
   }
 
   destisdir = isdir(destname);
   if (ac > recur + 3 && !destisdir) {
      ierr = 507;
      goto done;
   }
 
   /*
    * copy set:                        reduce to:
    *    file to file                     file to file
    *    dir  to file (NOT ALLOWED)
    *    file to dir                      dir to dir
    *    dir  to dir                      dir to dir
    *
    */
 
   fflush(stdout);
   stdout->_buflen = 1;
   for (i = recur + 1; i < ac - 1; ++i) {
      short srcisdir = isdir(av[i]);
      if (srcisdir && has_wild && (ac >2)) /* hack to stop dir's from */
          continue;			   /* getting copied if specified */
          			           /* from wild expansion */
      if (CHECKBREAK())
         break;
      if (srcisdir) {
         struct FileLock *srcdir, *destdir;
         if (!destisdir) {        /* disallow dir to file */
            ierr = 507;
            goto done;
         }
         if (!(destdir = (struct FileLock *)Lock(destname, ACCESS_READ))) {
            ierr = 205;
            errstr = destname;
            goto done;
         }
         if (!(srcdir = (struct FileLock *)Lock(av[i], ACCESS_READ))) {
            ierr = 205;
            errstr = av[i];
            UnLock(destdir);
            goto done;
         }
         ierr = copydir(srcdir, destdir, recur);
         UnLock(srcdir);
         UnLock(destdir);
         if (ierr)
            break;
      } else {                      /* FILE to DIR,   FILE to FILE   */
         struct FileLock *destdir, *srcdir, *tmp;
         char *destfilename;
                                                        /* jgII   ! */
         srcdir = (struct FileLock *)((struct Process *)FindTask(0L))->pr_CurrentDir;
         if (destisdir) {
            if ((tmp = (struct FileLock *)Lock(av[i], ACCESS_READ)) == NULL || !Examine(tmp,fib)){
               if (tmp) UnLock(tmp);
               ierr = 205;
               errstr = av[i];
               goto done;
            }
            UnLock(tmp);
            destdir = (struct FileLock *)Lock(destname, ACCESS_READ);
            destfilename = fib->fib_FileName;
         } else {
            destdir = srcdir;
            destfilename = destname;
         }
         printf(" %s..",av[i]);
         ierr = copyfile(av[i], srcdir, destfilename, destdir);
         if (destisdir)
            UnLock(destdir);
         if (ierr)
            break;
      }
   }
done:
   stdout->_buflen = STDBUF;            /* set back to buffr'd */
   FreeMem(fib, (long)sizeof(*fib));
   if (ierr) {
      ierror(errstr, ierr);
      return(20);
   }
   return(0);
}
 
 
copydir(srcdir, destdir, recur)
register struct FileLock *srcdir, *destdir;
{
   struct FileLock *cwd;
   register FIB *srcfib;
   register struct FileLock *destlock, *srclock;
   int ierr;
   static int level; 

   level++;
   ierr = 0;
   srcfib = (FIB *)AllocMem((long)sizeof(FIB), MEMF_PUBLIC);
   if (Examine(srcdir, srcfib)) {
      while (ExNext(srcdir, srcfib)) {
         if (CHECKBREAK())
	    break;
         if (srcfib->fib_DirEntryType < 0) {
	    printf("%*s%s..",(level-1) * 6," ",srcfib->fib_FileName);
            ierr = copyfile(srcfib->fib_FileName,srcdir,srcfib->fib_FileName,destdir);
            if (ierr)
               break;
         } else {
            if (recur) {
               cwd = (struct FileLock *)CurrentDir(srcdir);
               if (srclock = (struct FileLock *)Lock(srcfib->fib_FileName, ACCESS_READ)) {
                  CurrentDir(destdir);
                  if (!(destlock = (struct FileLock *)
				Lock(srcfib->fib_FileName))) {
                     destlock = (struct FileLock *)CreateDir(srcfib->fib_FileName);
  		     printf("%*s%s (Dir)....[Created]\n",(level-1) * 6,
  				" ",srcfib->fib_FileName); 
		  }
  		  else 
		     printf("%*s%s (Dir)\n",(level-1) * 6," ",srcfib->fib_FileName); 
                  if (destlock) {
                     ierr = copydir(srclock, destlock, recur);
                     UnLock(destlock);
                  } else {
                     ierr = (int)((long)IoErr());
                  }
                  UnLock(srclock);
               } else {
                  ierr = (int)((long)IoErr());
               }
               CurrentDir(cwd);
               if (ierr)
                  break;
            }
         }
      }
   } else {
      ierr = (int)((long)IoErr());
   }      
   --level;
   FreeMem(srcfib, (long)sizeof(FIB));
   return(ierr);
}
 
 
copyfile(srcname, srcdir, destname, destdir)
char *srcname, *destname;
struct FileLock *srcdir, *destdir;
{
   struct FileLock *cwd;
   struct FileHandle *f1, *f2;
   long i; 
   int ierr;
   char *buf;
 
   buf = (char *)AllocMem(8192L, MEMF_PUBLIC|MEMF_CLEAR);   
   if (buf == NULL) {
      ierr = 103;
      goto fail;
   }

   ierr = 0;
   cwd = (struct FileLock *)CurrentDir(srcdir);
   f1 = Open(srcname, MODE_OLDFILE);
   if (f1 == NULL) {
      errstr = srcname;
      ierr = 205;
      goto fail;
   }
   CurrentDir(destdir);
   f2 = Open(destname, MODE_NEWFILE);
   if (f2 == NULL) {
      Close(f1);
      ierr = (int)((long)IoErr());
      errstr = destname;
      goto fail;
   }
   while (i = Read(f1, buf, 8192L))
      if (Write(f2, buf, i) != i) {
         ierr = (int)((long)IoErr());
	 break;
      }
   Close(f2);
   Close(f1);
   if (!ierr)  {
      printf("..copied\n"); 
   }
   else {
      DeleteFile(destname);
      printf("..Not copied..");
   }
fail:
   if (buf) 
      FreeMem(buf, 8192L);
   CurrentDir(cwd);
   return(ierr);
}
comm2.c

/*
 * COMM2.C
 *
 * (c)1986 Matthew Dillon     9 October 1986
 *
 * version 2.05M (Manx Version and Additions) by Steve Drew 20-Jan-87
 *
 */

#include "shell.h"

#define BPTR_TO_C(strtag, var)  ((struct strtag *)(BADDR( (ULONG) var)))

#define TO_ASC(n)       ((n) + '0')             /* make it printable! */

/* Casting conveniences */
#define PROC(task)              ((struct Process *)task)
#define ROOTNODE                ((struct RootNode *)DOSBase->dl_Root)
#define CLI(proc)               (BPTR_TO_C(CommandLineInterface, proc->pr_CLI))

/* Externs */
extern struct DosLibrary *DOSBase;      /* dos library base pointer */

do_abortline()
{
   Exec_abortline = 1;
   return (0);
}

do_return()
{
   Exec_abortline = 1;
   if (Src_stack) {
      fseek (Src_base[Src_stack - 1], 0, 2); 
      return ((ac < 2) ? 0 : atoi(av[1]));
   } else {
      main_exit ((ac < 2) ? 0 : atoi(av[1]));
   }
}

/*
 * STRHEAD
 *
 * place a string into a variable removing everything after and including
 * the 'break' character or until a space is found in the string.
 *
 * strhead varname breakchar string
 *
 */

do_strhead()
{
   register char *str = av[3];
   char bc = *av[2];

   while (*str && *str != bc)
      ++str;
   *str = '\0';
   set_var (LEVEL_SET, av[1], av[3]);
   return (0);
}

do_strtail()
{
   register char *str = av[3];
   char bc = *av[2];

   while (*str && *str != bc)
      ++str;
   if (*str)
      ++str;
   set_var (LEVEL_SET, av[1], str);
   return (0);
}



/*
 * if A < B   <, >, =, <=, >=, !=, where A and B are either:
 * nothing
 * a string
 * a value (begins w/ number)
 */

do_if(garbage, com)
char *garbage;
{
   char *v1, *v2, *v3, result, num;
   int n1, n2;

   switch (com) {
   case 0:
      if (If_stack && If_base[If_stack - 1]) {
         If_base[If_stack++] = 1;
         break;
      }
      result = num = 0;
      if (ac <= 2) {       /* if $var; */
         if (ac == 1 || strlen(av[1]) == 0 || (strlen(av[1]) == 1 && *av[1] == ' '))
            goto do_result;
         result = 1;
         goto do_result;
      }
      if (ac != 4) {
         ierror(NULL, 500);
         break;
      }
      v1 = av[1]; v2 = av[2]; v3 = av[3];
      while (*v1 == ' ')
         ++v1;
      while (*v2 == ' ')
         ++v2;
      while (*v3 == ' ')
         ++v3;
      if (*v1 >= '0' && *v1 <= '9') {
         num = 1;
         n1 = atoi(v1);
         n2 = atoi(v3);
      }
      while (*v2) {
         switch (*v2++) {
         case '>':
            result |= (num) ? (n1 >  n2) : (strcmp(v1, v3) > 0);
            break;
         case '<':
            result |= (num) ? (n1 <  n2) : (strcmp(v1, v3) < 0);
            break;
         case '=':
            result |= (num) ? (n1 == n2) : (strcmp(v1, v3) ==0);
            break;
         default:
            ierror (NULL, 503);
            break;
         }
      }
do_result:
      If_base[If_stack++] = !result;
      break;
   case 1:
      if (If_stack > 1 && If_base[If_stack - 2])
         break;
      if (If_stack)
         If_base[If_stack - 1] ^= 1;
      break;
   case 2:
      if (If_stack)
         --If_stack;
      break;
   }
   disable = (If_stack) ? If_base[If_stack - 1] : 0;
   return (0);
}

do_label()
{
   char aseek[32];

   if (Src_stack == 0) {
      ierror (NULL, 502);
      return (-1);
   }
   sprintf (aseek, "%ld %d", Src_pos[Src_stack-1], If_stack);
   set_var (LEVEL_LABEL + Src_stack - 1, av[1], aseek);
   return (0);
}

do_goto()
{
   int new;
   long pos;
   char *lab;

   if (Src_stack == 0) {
      ierror (NULL, 502);
   } else {
      lab = get_var (LEVEL_LABEL + Src_stack - 1, av[1]);
      if (lab == NULL) {
         ierror (NULL, 501);
      } else {
         pos = atoi(lab);
         fseek (Src_base[Src_stack - 1], pos, 0);
         Src_pos[Src_stack - 1] = pos;
         new = atoi(next_word(lab));
         for (; If_stack < new; ++If_stack)
            If_base[If_stack] = 0;
         If_stack = new;
      }
   }
   Exec_abortline = 1;
   return (0);      /* Don't execute rest of this line */
}


do_inc(garbage, com)
char *garbage;
{
   char *var;
   char num[32];

   if (ac == 3)
      com = atoi(av[2]);
   var = get_var (LEVEL_SET, av[1]);
   if (var) {
      sprintf (num, "%d", atoi(var)+com);
      set_var (LEVEL_SET, av[1], num);
   }
   return (0);
}

do_input()
{
   char in[256];

   if ((gets(in)) != 0)
      set_var (LEVEL_SET, av[1], in);
   return (0);
}

do_ver()
{
   puts (VERSION);
   return (0);
}


do_ps()
{
	/* this code fragment based on ps.c command by Dewi Williams */

        register ULONG   *tt;           /* References TaskArray         */
        register int     count;         /* loop variable                */
        register UBYTE   *port;         /* msgport & ptr arith          */
        register struct Task *task;     /* EXEC descriptor              */
        char             strbuf[64];   /* scratch for btocstr()        */
        char             *btocstr();    /* BCPL BSTR to ASCIIZ          */

        tt = (unsigned long *)(BADDR(ROOTNODE->rn_TaskArray));

        printf("Proc Command Name         CLI Type    Pri.  Address  Directory\n");
        Forbid();               /* need linked list consistency */
        
        for (count = 1; count <= (int)tt[0] ; count++) {/* or just assume 20?*/
                if (tt[count] == 0) continue;           /* nobody home */

                /* Start by pulling out MsgPort addresses from the TaskArray
                 * area. By making unwarranted assumptions about the layout
                 * of Process and Task structures, we can derive these
                 * descriptors. Every task has an associated process, since
                 * this loop drives off a CLI data area.
                 */

                port = (UBYTE *)tt[count];
                task = (struct Task *)(port - sizeof(struct Task));

                /* Sanity check just in case */
                if (PROC(task)->pr_TaskNum == 0 || PROC(task)->pr_CLI == 0)
                        continue;               /* or complain? */

                        btocstr(CLI(PROC(task))->cli_CommandName, strbuf);
			printf("%2d   %-21s",count,strbuf);
			strcpy(strbuf,task->tc_Node.ln_Name);
                        strbuf[11] = '\0';
                        printf("%-11s",strbuf);
                        printf(" %3d  %8lx  %s\n",
                           task->tc_Node.ln_Pri,task,
                           btocstr(CLI(PROC(task))->cli_SetName, strbuf));
        }
        Permit();               /* outside critical region */
        return(0);
}


char *
btocstr(b, buf)
ULONG   b;
char    *buf;
{
        register char   *s;

        s = (char *)BADDR(b);   /* Shift & get length-prefixed str */
        bmov(s +1, buf, s[0]);
        buf[s[0]] = '\0';
        return buf;
}


dir.c

#include "shell.h"

struct FileNode
{
struct FileNode *fn_Next;
char fn_Name[108];
};

#define OPTF_ALL 1
#define OPTF_DIRS 2
#define OPTF_FILES 4

char *malloc(),*calloc();

stricmp(s1,s2)
register char *s1,*s2;
{
   register char c1,c2;

   while ((c1 = toupper(*s1++)) == (c2 = toupper(*s2++)))
      if (!c1) return 0;
   return c1 < c2 ? -1 : 1;
}

static short DirSpaces,Modes;

do__dir()
{
   int rc;
   register char argcnt,mode=0,cnt,*charptr,*s = NULL;
   static char *Options[]={"DIR","OPT","ALL","FILES","DIRS"},
      OptDo[][2]={0,-1,0,-1,OPTF_ALL,-1,0,~OPTF_DIRS,0,~OPTF_FILES};

   if (--ac && (cnt = strlen(av[ac])) && av[ac][--cnt] == '?') {
      printf("Usage: %s [[DIR] directory] [OPT options] [ALL] [FILES] [DIRS]\n",*av);
      return 20;
   }
   ++ac;
   Modes = OPTF_FILES | OPTF_DIRS;
   DirSpaces = 0;
   for (argcnt=1;argcnt<ac;argcnt++) {
      if (mode) {
         for (charptr=av[argcnt];charptr<(strlen(av[argcnt])+
               av[argcnt]);charptr++) {
            *charptr = toupper(*charptr);
            switch (*charptr) {
               case 'A':
                  Modes|=OPTF_ALL;
                  break;
               case 'D':
                  Modes&=~OPTF_FILES;
                  break;
               case 'F':
                  Modes&=~OPTF_DIRS;
                  break;
               default:
                  printf("Option '%c' ignored.\n",*charptr);
            }
         }
         mode = 0;
      } else {
         for (cnt=0;cnt<(sizeof(Options)/(sizeof(char *)));cnt++)
            if (!stricmp(av[argcnt],Options[cnt])) break;
         if (!cnt) continue;
         if (cnt == 1) mode=1;
         else if (cnt && cnt<sizeof(Options)/sizeof(char *))
                    Modes=(Modes|OptDo[cnt][0])&OptDo[cnt][1];
              else if (s) {
                      printf("Bad arguments\n");
                      return 20;
                   } else s=av[argcnt];
      }
   }
   rc = dir(s ? s : "");
   CHECKBREAK();
   return rc;
}

static prtspcs()
{
   register int cnt;
   for (cnt=0;cnt<DirSpaces;cnt++) printf("     ");
}

static qsortstrcmp(a,b)
char **a,**b;
{
   return (stricmp(*a,*b));
}

static dir(s)
register char *s;
{
   register short filecnt,usecnt;
   register struct FileInfoBlock *fib;
   register long lock,savelock;
   register struct FileNode *files_act,*files_strt;
   char **ptrs;
   int rc = 0;

   if (fib=(struct FileInfoBlock *)malloc(sizeof(*fib))) {
      if (lock=(long)Lock(s,ACCESS_READ)) {
         if (Examine(lock,fib)) {
            files_act=(struct FileNode *)&files_act;
            files_strt=0;
            filecnt = 0;
            while (ExNext(lock,fib) && !breakcheck())
               if (fib->fib_DirEntryType<0) {
                  if (Modes & OPTF_FILES) {
                     if (files_act->fn_Next=(struct FileNode *)
                           calloc(sizeof(struct FileNode),1)) {
                        if (files_strt) files_act=files_act->fn_Next;
                        else files_strt=files_act;
                        strcpy(&files_act->fn_Name,&fib->fib_FileName);
                        ++filecnt;
                     } else {
                        printf("Not enough heap-space!\n");
                        break;
                     }
                  }
               } else {
                  if (Modes & OPTF_DIRS) {
                     prtspcs();
                     printf("     %s (dir)\n",&fib->fib_FileName);
                  }
                  if (Modes & OPTF_ALL) {
                     ++DirSpaces;
                     savelock=(long)CurrentDir(lock);
                     rc = dir(&fib->fib_FileName);
                     CurrentDir(savelock);
                     if (rc) break;
                  }
               }
            if (!rc && (rc = IoErr()) == ERROR_NO_MORE_ENTRIES) rc = 0;
            if (Modes & OPTF_FILES) {
               usecnt=0;
               if (ptrs=(char **)malloc(filecnt*sizeof(char *))) {
                  files_act=files_strt;
                  while (files_act) {
                     ptrs[usecnt++]=(char *)(&files_act->fn_Name);
                     files_act=files_act->fn_Next;
                  }
                  qsort(ptrs,filecnt,4,qsortstrcmp);
                  usecnt=-1;
                  filecnt=0;
                  while (files_strt) {
                     if (breakcheck()) {
                        while (files_strt) {
                           files_act = files_strt;
                           files_strt = files_strt->fn_Next;
                           free(files_act);
                        }
                        break;
                     }
                     if (usecnt=~usecnt)
                        printf("  %s\n",ptrs[filecnt]);
                     else {
                        prtspcs();
                        printf("  %-31s",ptrs[filecnt]);
                     }
                     ++filecnt;
                     files_act=files_strt;
                     files_strt=files_strt->fn_Next;
                     free(files_act);
                  }
                  free(ptrs);
                  if (!usecnt) printf("\n");
               }
            }
         } else {
            printf("Couldn't get information for %s\n",s);
            rc = IoErr();
         }
         UnLock(lock);
      } else {
         printf("Can't find %s\n",s);
         rc = IoErr();
      }
      free(fib);
   }
   --DirSpaces;
   return rc;
}
execom.c
/*
 * EXECOM.C
 *
 * Matthew Dillon, 10 August 1986
 *    Finally re-written.
 *
 * version 2.05M (Manx Version and Additions) by Steve Drew 20-Jan-87
 *
 *
 */
 
#include "shell.h"
#include <fcntl.h>
 
#define F_EXACT 0
#define F_ABBR  1
 
#define ST_COND   0x03
#define ST_NAME   0x02
 
int has_wild = 0;                 /* set if any arg has wild card */

struct COMMAND {
   int (*func)();
   short minargs;
   short stat;
   int   val;
   char *name;
};
 
extern char *format_insert_string();
extern char *mpush(), *exarg();
 
extern int do_run(), do_number();
extern int do_quit(), do_set_var(), do_unset_var();
extern int do_echo(), do_source(), do_mv();
extern int do_cd(), do_rm(), do_mkdir(), do_history();
extern int do_mem(), do_cat(), do_dir(), do_inc();
extern int do_foreach(), do_return(), do_if(), do_label(), do_goto();
extern int do_input(), do_ver(), do_sleep(), do_help();
extern int do_strhead(), do_strtail();
extern int do_copy(), date(),  do_ps();
extern int do_forever(), do_abortline();
extern int do__info(),do__dir();
 
static struct COMMAND Command[] = {
   do_run      , 0,  0,       0 ,   "\001",
   do_number   , 0,  0,          0 ,   "\001",
   do_set_var  , 0,  0, LEVEL_ALIAS,   "alias",
   do_abortline, 0,  0,          0,    "abortline",   
   do_cd       , 0,  0,          0 ,   "cd",
   do_cat      , 0,  0,          0 ,   "cat",
   do_copy     , 1,  0,          0 ,   "copy",
   date        , 0,  0,          0 ,   "date",
   do__dir     , 0,  0,          0 ,   "dir",
   do_inc      , 1,  0,         -1 ,   "dec",
   do_dir      , 0,  0,         -1 ,   "devinfo",
   do_echo     , 0,  0,          0 ,   "echo",
   do_if       , 0,  ST_COND,    1 ,   "else",
   do_if       , 0,  ST_COND,    2 ,   "endif",
   do_foreach  , 3,  0,          0 ,   "foreach",
   do_forever  , 1,  0,          0 ,   "forever",   
   do_goto     , 1,  0,          0 ,   "goto",
   do_help     , 0,  0,          0 ,   "help",
   do_history  , 0,  0,          0 ,   "history",
   do__info    , 0,  0,          0 ,   "info",
   do_if       , 1,  ST_COND,    0 ,   "if",
   do_inc      , 1,  0,          1 ,   "inc",
   do_input    , 1,  0,          0 ,   "input",
   do_dir      , 0,  0,          0 ,   "list",
   do_label    , 1,  ST_COND,    0 ,   "label",
   do_mem      , 0,  0,          0 ,   "mem",
   do_mkdir    , 0,  0,          0 ,   "mkdir",
   do_mv       , 2,  0,          0 ,   "mv",   
   do_ps       , 0,  0,          0,    "ps",
   do_cd       , 0,  0,         -1 ,   "pwd",
   do_quit     , 0,  0,          0 ,   "quit",
   do_return   , 0,  0,          0 ,   "return",
   do_rm       , 0,  0,          0 ,   "rm",
   do_run      , 1,  ST_NAME,    0 ,   "run",
   do_set_var  , 0,  0, LEVEL_SET  ,   "set",
   do_sleep    , 0,  0,          0,    "sleep",
   do_source   , 0,  0,          0 ,   "source",
   do_strhead  , 3,  0,          0 ,   "strhead",
   do_strtail  , 3,  0,          0 ,   "strtail",
   do_unset_var, 0,  0, LEVEL_ALIAS,   "unalias",
   do_unset_var, 0,  0, LEVEL_SET  ,   "unset",
   do_ver      , 0,  0,          0 ,   "version",
   '\0'        , 0,  0,          0 ,   NULL
};

  
static unsigned char elast;          /* last end delimeter */
static char Cin_ispipe, Cout_ispipe;
 
exec_command(base)
char *base;
{
   register char *scr;
   register int i;
   char buf[32];
 
   if (!H_stack) {
      add_history(base);
      sprintf(buf, "%d", H_tail_base + H_len);
      set_var(LEVEL_SET, V_HISTNUM, buf);
   }
   scr = malloc((strlen(base) << 2) + 2);    /* 4X */
   preformat(base, scr);
   i = fcomm(scr, 1);
   return ((i) ? -1 : 1);
}
 
isalphanum(c)
char c;
{
   if (c >= '0' && c <= '9')
      return (1);
   if (c >= 'a' && c <= 'z')
      return (1);
   if (c >= 'A' && c <= 'Z')
      return (1);
   if (c == '_')
      return (1);
   return (0);
}
 
preformat(s, d)
register char *s, *d;
{
   register int si, di, qm;
 
   si = di = qm = 0;
   while (s[si] == ' ' || s[si] == 9)
      ++si;
   while (s[si]) {
      if (qm && s[si] != '\"' && s[si] != '\\') {
         d[di++] = s[si++] | 0x80;
         continue;
      }
      switch (s[si]) {
      case ' ':
      case 9:
         d[di++] = ' ';
         while (s[si] == ' ' || s[si] == 9)
            ++si;
         if (s[si] == 0 || s[si] == '|' || s[si] == ';')
            --di;
         break;
      case '*':
      case '?':
         d[di++] = 0x80;
      case '!':
         d[di++] = s[si++];
         break;
      case '#':
         d[di++] = '\0';
         while (s[si])
            ++si;
         break;
      case ';':
      case '|':
         d[di++] = s[si++];
         while (s[si] == ' ' || s[si] == 9)
            ++si;
         break;
      case '\\':
         d[di++] = s[++si] | 0x80;
         if (s[si]) ++si;
         break;
      case '\"':
         qm = 1 - qm;
         ++si;
         break;
      case '^':
         d[di++] = s[++si] & 0x1F;
         if (s[si]) ++si;
         break;
      case '$':         /* search end of var name and place false space */
         d[di++] = 0x80;
         d[di++] = s[si++];
         while (isalphanum(s[si]))
            d[di++] = s[si++];
         d[di++] = 0x80;
         break;
      default:
         d[di++] = s[si++];
         break;
      }
   }
   d[di++] = 0;
   d[di]   = 0;
   if (debug & 0x01) {
      fprintf (stderr,"PREFORMAT: %d :%s:\n", strlen(d), d);
   }
}
 
/*
 * process formatted string.  ' ' is the delimeter.
 *
 *    0: check '\0': no more, stop, done.
 *    1: check $.     if so, extract, format, insert
 *    2: check alias. if so, extract, format, insert. goto 1
 *    3: check history or substitution, extract, format, insert. goto 1
 *
 *    4: assume first element now internal or disk based command.
 *
 *    5: extract each ' ' or 0x80 delimited argument and process, placing
 *       in av[] list (except 0x80 args appended).  check in order:
 *
 *             '$'         insert string straight
 *             '>'         setup stdout
 *             '>>'        setup stdout flag for append
 *             '<'         setup stdin
 *             '*' or '?'  do directory search and insert as separate args.
 *
 *             ';' 0 '|'   end of command.  if '|' setup stdout
 *                          -execute command, fix stdin and out (|) sets
 *                           up stdin for next guy.
 */
 
 
fcomm(str, freeok)
register char *str;
{
   static int alias_count;
   int p_alias_count = 0;
   char *istr;
   char *nextstr;
   char *command;
   char *pend_alias = NULL;
   char err = 0;
   has_wild = 0;
   ++alias_count;
   
   mpush_base();
   if (*str == 0)
      goto done1;
step1:
   if (alias_count == MAXALIAS || ++p_alias_count == MAXALIAS) {
      fprintf(stderr,"Alias Loop\n");
      err = 20;
      goto done1;
   }
   if (*str == '$') {
      if (istr = get_var (LEVEL_SET, str + 1))
         str = format_insert_string(str, istr, &freeok);
   }
   istr = NULL;
   if (*(unsigned char *)str < 0x80)
      istr = get_var (LEVEL_ALIAS, str);  /* only if not \command */
   *str &= 0x7F;                          /* remove \ teltail     */
   if (istr) {
      if (*istr == '%') {
         pend_alias = istr;
      } else {
         str = format_insert_string(str, istr, &freeok);
         goto step1;
      }
   }
   if (*str == '!') {
      char *p, c;            /* fix to allow !cmd1;!cmd2 */
      for(p = str; *p && *p != ';' ; ++p);
      c = *p;
      *p = '\0';      
      istr = get_history(str);
      *p = c;
      replace_head(istr);      
      str = format_insert_string(str, istr, &freeok);
      goto step1;
   }
   nextstr = str;
   command = exarg(&nextstr);
   if (*command == 0)
      goto done0;
   if (pend_alias == 0) {
      register int ccno;
      ccno = find_command(command);
      if (Command[ccno].stat & ST_COND)
         goto skipgood;
   }
   if (disable) {
      while (elast && elast != ';' && elast != '|')
         exarg(&nextstr);
      goto done0;
   }
skipgood:
   {
      register char *arg, *ptr, *scr;
      short redir;
      short doexpand;
      short cont;
      short inc;
 
      ac = 1;
      av[0] = command;
step5:                                          /* ac = nextac */
      if (!elast || elast == ';' || elast == '|')
         goto stepdone;
 
      av[ac] = '\0';
      cont = 1;
      doexpand = redir = inc = 0;
 
      while (cont && elast) {
         ptr = exarg(&nextstr);
         inc = 1;
         arg = "";
         cont = (elast == 0x80);
         switch (*ptr) {
         case '<':
            redir = -2;
         case '>':
            if ((Command[find_command(command)].stat & ST_NAME) != 0) { 
                              /* don't extract   */
               redir = 0;            /* <> stuff if its */
               arg = ptr;            /* external cmd.   */
               break;   
            }
            ++redir;
            arg = ptr + 1;
            if (*arg == '>') {
               redir = 2;        /* append >> (not impl yet) */
               ++arg;
            }            
            cont = 1;
            break;
         case '$':
            if ((arg = get_var(LEVEL_SET, ptr + 1)) == NULL)
               arg = ptr;
            break;
         case '*':
         case '?':
            doexpand = 1;
            arg = ptr;
            break;
         default:
            arg = ptr;
            break;
         }
 
         /* Append arg to av[ac] */
 
         for (scr = arg; *scr; ++scr)
            *scr &= 0x7F;
         if (av[ac]) {
            register char *old = av[ac];
            av[ac] = mpush(strlen(arg)+1+strlen(av[ac]));
            strcpy(av[ac], old);
            strcat(av[ac], arg);
         } else {
            av[ac] = mpush(strlen(arg)+1);
            strcpy(av[ac], arg);
         }
         if (elast != 0x80)
            break;
      }
 
      /* process expansion */
 
      if (doexpand) {
         char **eav, **ebase;
         int eac;
     has_wild = 1;
         eav = ebase = expand(av[ac], &eac);
         inc = 0;
         if (eav) {
            if (ac + eac + 2 > MAXAV) {
               ierror (NULL, 506);
               err = 1;
            } else {               
               QuickSort(eav, eac);
               for (; eac; --eac, ++eav)
                  av[ac++] = strcpy(mpush(strlen(*eav)+1), *eav);
            }
            free_expand (ebase);
         }
      }
 
      /* process redirection  */
 
      if (redir && !err) {
         register char *file = (doexpand) ? av[--ac] : av[ac];
 
         if (redir < 0)
            Cin_name = file;
         else {            
            Cout_name = file;
            Cout_append = (redir == 2);
         }            
         inc = 0;
      }
 
      /* check elast for space */
 
      if (inc) {
         ++ac;
         if (ac + 2 > MAXAV) {
            ierror (NULL, 506);
            err = 1;                /* error condition */
            elast = 0;              /* don't process any more arguemnts */
         }
      }
      if (elast == ' ')
         goto step5;
   }
stepdone:
   av[ac] = '\0';
 
   /* process pipes via files */
 
   if (elast == '|' && !err) {
      static int which;             /* 0 or 1 in case of multiple pipes */
      which = 1 - which;
      Cout_name = (which) ? Pipe1 : Pipe2;
      Cout_ispipe = 1;
   }
 
 
   if (err)
      goto done0;
 
   {
      register int i, len;
      char save_elast;
      register char *avline;
 
      save_elast = elast;
      for (i = len = 0; i < ac; ++i)
         len += strlen(av[i]) + 1;
      avline = malloc(len+1);
      for (len = 0, i = ((pend_alias) ? 1 : 0); i < ac; ++i) {
         if (debug & 0x02) { 
             fprintf (stderr, "AV[%2d] %d :%s:\n", i, strlen(av[i]), av[i]);
         }
         strcpy(avline + len, av[i]);
         len += strlen(av[i]);
         if (i + 1 < ac)
            avline[len++] = ' ';
      }
      avline[len] = 0;
      if (pend_alias) {                               /* special % alias */
         register char *ptr, *scr;
         for (ptr = pend_alias; *ptr && *ptr != ' '; ++ptr);
         set_var (LEVEL_SET, pend_alias + 1, avline);
         free (avline);
 
         scr = malloc((strlen(ptr) << 2) + 2);
         preformat (ptr, scr);
         fcomm (scr, 1);
         unset_var (LEVEL_SET, pend_alias + 1);
      } else {                                        /* normal command  */
         register int ccno;
         long  oldcin = (long)Input();
     long  oldcout = (long)Output();
    struct _dev *stdfp;
    
    fflush(stdout);
         ccno = find_command (command);
         if ((Command[ccno].stat & ST_NAME) == 0) {
            if (Cin_name) {
               if ((Cin = (long)Open(Cin_name,1005L)) == 0L) {
                  ierror (NULL, 504);
                  err = 1;
                  Cin_name = '\0';
               } else {
                  Myprocess->pr_CIS = Cin;
              _devtab[stdin->_unit].fd = Cin;
               }
            }
            if (Cout_name) {               
               if (Cout_append) {
                  if ((Cout = (long)Open(Cout_name, 1005L)) != 0L)
                     Seek(Cout, 0L, 1L);
               } else {
                  Cout = (long)Open(Cout_name,1006L);
          }
               if (Cout == NULL) {
                  err = 1;
                  ierror (NULL, 504);
                  Cout_name = '\0';
                  Cout_append = 0;
               } else {
                  Myprocess->pr_COS = Cout;
                  _devtab[stdout->_unit].fd = Cout;
               }
            }
         }
         if (ac < Command[ccno].minargs + 1) {
            ierror (NULL, 500);
            err = -1;
         } else if (!err) {
            i = (*Command[ccno].func)(avline, Command[ccno].val);
            if (i < 0)
               i = 20;
            err = i;
         }
         free (avline);
         if (Exec_ignoreresult == 0 && Lastresult != err) {
            Lastresult = err;
            seterr();
         }
         if ((Command[ccno].stat & ST_NAME) == 0) {
            if (Cin_name) {
               fflush(stdin); 
          clearerr(stdin);
          Close(Cin);
            }
            if (Cout_name) {
               fflush(stdout);
               clearerr(stdout);
               stdout->_flags &= ~_DIRTY;    /* because of nil: device */
               Close(Cout);
               Cout_append = 0;
            }
         }

       /* the next few lines solve a bug with fexecv and bcpl programs */
       /* that muck up the input/output streams  which causes GURUs   */

         Myprocess->pr_CIS =  _devtab[stdin->_unit].fd = oldcin;
         Myprocess->pr_COS =  _devtab[stdout->_unit].fd = oldcout;      
      }
      if (Cin_ispipe && Cin_name)
         DeleteFile(Cin_name);
      if (Cout_ispipe) {
         Cin_name = Cout_name;         /* ok to assign.. static name */
         Cin_ispipe = 1;
      } else {
         Cin_name = '\0';
      }
      Cout_name = '\0';
      Cout_ispipe = 0;
      elast = save_elast;
   }
   mpop_tobase();                      /* free arguments   */
   mpush_base();                       /* push dummy base  */
 
done0:
   {
      char *str;
      if (err && E_stack == 0) {
         str = get_var(LEVEL_SET, V_EXCEPT);
         if (err >= ((str)?atoi(str):1)) {
            if (str) {
               ++H_stack;
               ++E_stack;
               exec_command(str);
               --E_stack;
               --H_stack;
            } else {
               Exec_abortline = 1;
            }
         }
      }
      if (elast != 0 && Exec_abortline == 0)
         err = fcomm(nextstr, 0);
      Exec_abortline = 0;
      if (Cin_name)
         DeleteFile(Cin_name);
      Cin_name = NULL;
      Cin_ispipe = 0;
   } 
done1:
   mpop_tobase();
   if (freeok)
      free(str);
   --alias_count;
   return ((int)err);                  /* TRUE = error occured    */
}
 
 
char *
exarg(ptr)
unsigned char **ptr;
{
   register unsigned char *end;
   register unsigned char *start;
 
   start = end = *ptr;
   while (*end && *end != 0x80 && *end != ';' && *end != '|' && *end != ' ')
      ++end;
   elast = *end;
   *end = '\0';
   *ptr = end + 1;
   return ((char *)start);
}
 
static char **Mlist;
 
mpush_base()
{
   char *str;
 
   str = malloc(5);
   *(char ***)str = Mlist;
   str[4] = 0;
   Mlist = (char **)str;
}
 
char *
mpush(bytes)
{
   char *str;
 
   str = malloc(5 + bytes);
   *(char ***)str = Mlist;
   str[4] = 1;
   Mlist = (char **)str;
   return (str + 5);
}
 
mpop_tobase()
{
   register char *next;
   while (Mlist) {
      next = *Mlist;
      if (((char *)Mlist)[4] == 0) {
         free (Mlist);
         Mlist = (char **)next;
         break;
      }
      free (Mlist);
      Mlist = (char **)next;
   }
}
 

/*
 * Insert 'from' string in front of 'str' while deleting the
 * first entry in 'str'.  if freeok is set, then 'str' will be
 * free'd
 */



char *
format_insert_string(str, from, freeok)
char *str;
char *from;
int *freeok;
{
   register char *new1, *new2;
   register unsigned char *strskip;
   int len;

   for (strskip = (unsigned char *)str; *strskip && *strskip != ' ' && *strskip != ';' && *strskip != '|' && *strskip != 0x80; ++strskip);
   len = strlen(from);
   new1 = malloc((len << 2) + 2);
   preformat(from, new1);
   len = strlen(new1) + strlen(strskip);
   new2 = malloc(len+2);
   strcpy(new2, new1);
   strcat(new2, strskip);
   new2[len+1] = 0;
   free (new1);
   if (*freeok)
      free (str);
   *freeok = 1;
   return (new2);
}

find_command(str)
char *str;
{
   int i;
   int len = strlen(str);

   if (*str >= '0'  &&  *str <= '9')
      return (1);
   for (i = 0; Command[i].func; ++i) {
      if (strncmp (str, Command[i].name, len) == 0)
         return (i);
   }
   return (0);
}
 
do_help()
{
   register struct COMMAND *com;
   int i= 0;

    
   for (com = &Command[2]; com->func; ++com) {
      printf ("%-12s", com->name);
      if (++i  % 6 == 0) printf("\n");
   }
   printf("\n");
   return(0);
}

fexec.c
/* Copyright (C) 1986,1987 by Manx Software Systems, Inc. */

#include   <exec/types.h>
#include   <exec/tasks.h>
#include   <libraries/dosextens.h>

static long ret_val;

wait()
{
   return(ret_val);
}

fexecl(file, arg0)
char *file, *arg0;
{
   return(fexecv(file, &arg0));
}

fexecv(cmd, argv)
char *cmd, **argv;
{
   register struct CommandLineInterface *cli;
   struct Process *pp;
   struct Process *FindTask();
   struct FileHandle *fhp;
   APTR sav_ret;
   register char **ap, *cp, *arg;
   int i;
   long len, seg, sav, stksiz;
   long sav_Buf,sav_Pos,sav_End;
   char buf[40];
   long *bcpl;
   union {
      long *lp;
      long ll;
   } l, stk;
   long oldcin, oldcout;
   long doexec(), LoadSeg(), CurrentDir(), OpenLibrary();
   void *AllocMem();
   extern long _savsp;
   extern struct DosLibrary *DOSBase;

   pp = FindTask(0L);
   if ((cli = (struct CommandLineInterface *)((long)pp->pr_CLI << 2)) == 0) {
      return(-1);
   }
   if ((sav = OpenLibrary("dos.library", 33L)) == 0) {

      bcpl = (long *)*((long *)*((long *)*((long *)*((long *)
                              _savsp+2)+1)-3)-3)+107;
      if (*bcpl != cli->cli_Module)
         return(-1);
   }
   else {
      CloseLibrary(sav);
      bcpl = 0;
   }
   if (seg = LoadSeg(cmd))
      goto found;
   l.lp = (long *) cli->cli_CommandDir;
   while (l.ll) {
      l.ll <<= 2;
      sav = CurrentDir(l.lp[1]);
      seg = LoadSeg(cmd);
      CurrentDir(sav);
      if (seg)
         goto found;
      l.ll = *l.lp;
   }
   strcpy(buf, "c:");
   strcat(buf, cmd);
   if (seg = LoadSeg(buf))
      goto found;
   return(-1);
found:
   stksiz = 4 * cli->cli_DefaultStack;
   if ((stk.lp = AllocMem(stksiz+8, 0L)) == 0) {
      UnLoadSeg(seg);
      return(-1);
   }
   for (len=1,ap=argv+1;*ap;ap++)
      len += strlen(*ap) + 1;
   if ((cp = arg = AllocMem(len, 0L)) == 0) {
      UnLoadSeg(seg);
      FreeMem(stk.lp, stksiz+8);
      return(-1);
   }
   *stk.lp = stksiz + 8;
   stk.ll += stksiz;
   stk.lp[0] = stksiz;
   sav_ret = pp->pr_ReturnAddr;
   pp->pr_ReturnAddr = (APTR) stk.lp;

   sav = cli->cli_Module;
   cli->cli_Module = seg;
   if (bcpl)
      *bcpl = seg;

   for (ap=argv+1;*ap;ap++) {
      strcpy(cp, *ap);
      strcat(cp, " ");
      cp += strlen(cp);
   }
   arg[len-1] = '\n';

   cp = (char *)((long)cli->cli_CommandName << 2);
   movmem(cp, buf, 40);
   strcpy(cp+1, cmd);
   cp[0] = strlen(cmd);

   fhp = (struct FileHandle *) ((oldcin = pp->pr_CIS) << 2);
   sav_Buf = fhp->fh_Buf;
   sav_Pos = fhp->fh_Pos;
   sav_End = fhp->fh_End;
   fhp->fh_Buf = (BPTR)arg >> 2;
   fhp->fh_Pos = 0L;
   fhp->fh_End = len;

   oldcout = pp->pr_COS;      

   ret_val = doexec(len, stksiz, stksiz+8, len, arg, DOSBase->dl_A2,
         pp, (seg+1)<<2, DOSBase->dl_A5, DOSBase->dl_A6, stk.ll);
   pp->pr_CIS =  oldcin;
   pp->pr_COS =  oldcout;
   fhp->fh_Buf = sav_Buf;
   fhp->fh_Pos = sav_Pos;
   fhp->fh_End = sav_End;
   UnLoadSeg(cli->cli_Module);
   pp->pr_ReturnAddr = sav_ret;
   cli->cli_Module = sav;
   if (bcpl)
      *bcpl = sav;
   FreeMem(arg, len);
   movmem(buf, cp, 40);
   return(0);
}

static long
doexec()
{
#asm
   movem.l  d3-d7/a2-a5,-(sp)   ;save registers
   lea      savsp(pc),a0
   move.l   sp,(a0)             ;save our sp
   move.l   48(a5),d1
   move.l   __stkbase#,a1
   movem.l  8(a5),d0/d2/d3/d4/a0/a2/a3/a4/a5/a6  ;load params
   add.l    #4,a1
   movem.l  a1-a2/a5-a6,-(sp)
   move.l   $54(a3),-(sp)
   exg.l    d1,sp
   move.l   d1,a3
   move.l   d1,4(sp)
   move.l   a0,d1               ;copy to d1 as well
   jsr      (a4)                ;call new program
   movem.l  (sp)+,d2/d3         ;get stk siz and old sp
   move.l   sp,a1               ;save current sp
   move.l   savsp(pc),sp        ;get back our sp
   movem.l  (sp)+,d3-d7/a2-a5   ;get back registers
   move.l   d0,-(sp)            ;save return code
   sub.l    d2,a1               ;back up a bit
   sub.l    #8,a1               ;back up over header
   move.l   (a1),d0             ;get size to free
   move.l   4,a6                ;get ExecBase
   jsr      -210(a6)            ;free the memory
   move.l   (sp)+,d0            ;get the return code
#endasm
}

#asm
savsp:
   dc.l   0
#endasm
globals.c

/*
 * GLOBALS.C
 *
 * (c)1986 Matthew Dillon     9 October 1986
 *
 * version 2.05M (Manx Version and Additions) by Steve Drew 20-Jan-87
 *
 *    Most global variables.
 *
 */


#include "shell.h"

struct HIST *H_head, *H_tail;                   /* HISTORY lists      */

struct PERROR Perror[] = {                      /* error code->string */
   103,  "insufficient free storage",
   105,  "task table full",
   120,  "argument line invalid or too long",
   121,  "file is not an object module",
   122,  "invalid resident library during load",
   201,  "no default directory",
   202,  "object in use",
   203,  "object already exists",
   204,  "directory not found",
   205,  "object not found",
   206,  "bad stream name",
   207,  "object too large",
   209,  "action not known",
   210,  "invalid stream component name",
   211,  "invalid object lock",
   212,  "object not of required type",
   213,  "disk not validated",
   214,  "disk write protected",
   215,  "rename across devices",
   216,  "directory not empty",
   217,  "too many levels",
   218,  "device not mounted",
   219,  "seek error",
   220,  "comment too long",
   221,  "disk full",
   222,  "file delete protected",
   223,  "file write protected",
   224,  "file read protected",
   225,  "not a DOS disk",
   226,  "no disk",
   232,  "no more entries in directory",

   /* custom error messages */

   500,  "bad arguments",
   501,  "label not found",
   502,  "must be within source file",
   503,  "Syntax Error",
   504,  "redirection error",
   505,  "pipe error",
   506,  "too many arguments",
   507,  "destination not a directory",
   508,  "cannot mv a filesystem",
     0,  NULL
};


char  *av[MAXAV];             /* Internal argument list                 */
long  Src_base[MAXSRC];       /* file pointers for source files         */
long  Src_pos[MAXSRC];        /* seek position storage for same         */
char  If_base[MAXIF];         /* If/Else stack for conditionals         */
int   H_len, H_tail_base;     /* History associated stuff               */
int   H_stack;                /* AddHistory disable stack               */
int   E_stack;                /* Exception disable stack                */
int   Src_stack, If_stack;    /* Stack Indexes                          */
int   ac;                     /* Internal argc                          */
int   debug;                  /* Debug mode                             */
int   disable;                /* Disable com. execution (conditionals)  */
int   Verbose;                /* Verbose mode for source files          */
int   Lastresult;             /* Last return code                       */
int   Exec_abortline;         /* flag to abort rest of line             */
int   Exec_ignoreresult;      /* flag to ignore result                  */
int   Quit;                   /* Quit flag                              */
long  Cout, Cin;              /* Current input and output file handles  */
long  Cout_append;            /* append flag for Cout                   */
long  Uniq;                   /* unique value                           */
char  *Cin_name, *Cout_name;  /* redirection input/output name or NULL  */
char  *Pipe1, *Pipe2;         /* the two pipe temp. files               */
struct Process *Myprocess;
int   S_histlen = 20;         /* Max # history entries                  */



info.c

#include "shell.h"
#include <libraries/filehandler.h>

extern long dos_packet();

GLOBAL struct DosLibrary *DOSBase;

do__info()
{
   struct DevInfo *dip;
   struct DeviceList *dlp;
   register struct InfoData *idp;
   register char b[256],*cp,*sdp,c;
   register LONG s,*lp;
   int i;
   static char *DiskStates[] = {
      "Read Only","Validating","Read/Write"
   };

   if (--ac && (i = strlen(av[ac])) && av[ac][--i] == '?') {
      printf("Usage: %s [[DEVICE] device]\n",*av);
      return RETURN_OK;
   }
   if (ac > 2 || (ac == 2 && stricmp(av[1],"DEVICE"))) {
      printf("Bad arguments\n");
      return RETURN_FAIL;
   }
   if (sdp = (ac ? av[ac] : NULL)) {
      while ((i = strlen(sdp)) && ((c = sdp[--i]) == ':' || c == '-' ||
               c == ';' || c == '_' || c == ',' || c == '.' || c == '*'))
         sdp[i] = '\0';
      while ((c = *sdp) == ':' || c == ';') ++sdp;
      if (*sdp == 0) sdp = NULL;
   }
   if (!(idp = (struct InfoData *)malloc(sizeof *idp))) {
      printf("Not enough memory !\n");
      return RETURN_FAIL;
   }
   dlp = (struct DeviceList *)(dip = (struct DevInfo *)&((struct DosInfo *)
         BADDR(((struct RootNode *)DOSBase->dl_Root)->rn_Info))->di_DevInfo);
   printf("\nMounted disks:\n");
   printf("Unit      Size    Used    Free Full Errs   Status   Name\n");
   Forbid();
   while (dip = (struct DevInfo *)BADDR(dip->dvi_Next)) 
      if (dip->dvi_Type == DLT_DEVICE && dip->dvi_Task) {
         b[*(cp = ((char *)BADDR(dip->dvi_Name)))] = '\0';
         strncpy(b,cp + 1,(int)*cp);
         if (sdp && stricmp(b,sdp)) continue;
         if (dos_packet(dip->dvi_Task,ACTION_DISK_INFO,(BPTR)idp>>2)) {
            strcat(b,":");
            printf("%-10s",b);
            switch (idp->id_DiskType) {
               case ID_NO_DISK_PRESENT:
                  printf("No disk present\n");
                  break;
               case ID_UNREADABLE_DISK:
                  printf("Unreadable disk\n");
                  break;
               case ID_NOT_REALLY_DOS:
                  printf("Not a DOS disk\n");
                  break;
               case ID_KICKSTART_DISK:
                  printf("Kickstart disk\n");
                  break;
               case ID_DOS_DISK:
                  if (dip->dvi_Startup && (lp = (LONG *)BADDR
                           (((struct FileSysStartupMsg *)BADDR
                           (dip->dvi_Startup))->fssm_Environ)))
                     s = (lp[DE_UPPERCYL] - lp[DE_LOWCYL] + 1) *
                              lp[DE_NUMHEADS] * lp[DE_BLKSPERTRACK] *
                              lp[DE_SIZEBLOCK] << 2;
                  else
                     s = idp->id_NumBlocks * idp->id_BytesPerBlock;
                  if ((s >>= 10) < 1000) printf("%3dK",(int)s);
                  else if (s / 1024 < 10)
                     printf("%d.%dM",(int)s / 1024,(int)(s % 1024) / 100);
                  else
                     printf("%3dM",(int)s / 1024);
                  b[0] = 0;
                  if (idp->id_VolumeNode) {
                     b[*(cp = (char *)BADDR(((struct DeviceList *)BADDR
                           (idp->id_VolumeNode))->dl_Name))] = '\0';
                     strncpy(b,cp + 1,(int)*cp);
                  }
                  printf("%8ld%8ld%4d%%%4ld  %-10s %s\n",
                        idp->id_NumBlocksUsed,idp->id_NumBlocks -
                        idp->id_NumBlocksUsed,(int)(idp->id_NumBlocksUsed *
                        100 / idp->id_NumBlocks),idp->id_NumSoftErrors,
                        DiskStates[idp->id_DiskState - ID_WRITE_PROTECTED],
                        b);
            }
         }
      }
   s = TRUE;
   while (dlp = (struct DeviceList *)BADDR(dlp->dl_Next))
      if (dlp->dl_Type == DLT_VOLUME) {
         b[*(cp = (char *)BADDR(dlp->dl_Name))] = '\0';
         strncpy(b,cp + 1,(int)*cp);
         if (sdp && stricmp(sdp,b)) continue;
         if (s) {
            printf("\nVolumes available:\n");
            s = FALSE;
         }
         printf("%s%s\n",b,dlp->dl_Task ? " [Mounted]" : "");
      }
   Permit();
   free(idp);
   return RETURN_OK;
}
main.c

/*
 * MAIN.C
 *
 * Matthew Dillon, 24 Feb 1986
 * (c)1986 Matthew Dillon     9 October 1986
 *
 * version 2.05M (Manx Version and Additions) by Steve Drew 20-Jan-87
 *
 */
 
#include "shell.h"

void cleanupconsole(), initconsole();
extern char *btocstr();
extern struct FileLock *Clock; 

char Inline[256];
char stdout_buff[STDBUF]; 
main(argc, argv)
register char *argv[];
{
   char *rawgets();
   char *prompt;
   register int i;
   extern int Enable_Abort;
   Enable_Abort = 0;

   if (!argc && !init_cli()) {
      printf("\n\nCouldn't create a CLI structure !\n");
      printf("Press RETURN for quitting...\n");
      getchar();
      return 20;
   }

   init_vars();
   init();
   seterr();
   do_cd(NULL, -1);
   
   for (i = 1; i < argc; ++i) {
      if (argv[i][0] == '-' && argv[i][1] == 'c') {
       Inline[0] = ' ';
       Inline[1] = '\000';
       while (++i < argc) {
      strcat(Inline,argv[i]);
      strcat(Inline," ");
      }
       exec_command(Inline);
       main_exit(0);
       }
      strcpy (Inline, "source ");
      strcat (Inline, argv[i]);
      av[1] = argv[i];
      do_source (Inline);
   }
#ifdef JGII
   strcpy(Inline, "source ");
   strcat(Inline, "s:.login");
   av[1] = "s:.login";
   do_source (Inline);
#endif
   
   for (;;) {
      if ((prompt = get_var (LEVEL_SET, V_PROMPT)) == NULL)
         prompt = "$ ";
      if (breakcheck()) {
         while (WaitForChar(Input(), 100L))
            gets(Inline);
      }
      if (Quit || !rawgets(Inline, prompt))
         main_exit(0);
      breakreset();
      if (*Inline)
         exec_command(Inline);
   }
}
 
init_vars()
{
   if (IsInteractive(Input()))
      set_var (LEVEL_SET, V_PROMPT, "$ ");
   else
      set_var (LEVEL_SET, V_PROMPT, "");
   set_var (LEVEL_SET, V_HIST,   "20");
   set_var (LEVEL_SET, V_LASTERR, "0");
   set_var (LEVEL_SET, V_PATH, "ram:,ram:c/,c:,df1:c/,df0:c/");
}
 
init()
{


   static char pipe1[32], pipe2[32];

   initconsole();

   fflush(stdout);                  /* added by jgII 1-23-87 */
   stdout->_buff = stdout_buff;
   stdout->_buflen = STDBUF;  

   Myprocess = (struct Process *)FindTask(0L);
   Uniq  = (long)Myprocess;
   Pipe1 = pipe1;
   Pipe2 = pipe2;
   sprintf (pipe1, "ram:pipe1_%ld", Uniq);
   sprintf (pipe2, "ram:pipe2_%ld", Uniq);
}
 
 
main_exit(n)
{
   cleanupconsole(0);
   cleanup_cli();
   exit (n);
}
 
breakcheck()
{
   if (SetSignal(0L,0L) & SIGBREAKF_CTRL_C)
      return (1);
   else
      return (0);
}
 
breakreset()
{
   SetSignal(0L, SIGBREAKF_CTRL_C);
}


/* this routine causes manx to use this Chk_Abort() rather than it's own */
/* otherwise it resets our ^C when doing any I/O (even when Enable_Abort */
/* is zero).  Since we want to check for our own ^C's           */

Chk_Abort()
{
return(0);
}


makeami
######################################################################
#
# Makefile to build Shell 2.05M
# by Steve Drew 20-Jan-87
#
######################################################################

OBJS	= run.o main.o comm1.o comm2.o execom.o set.o sub.o \
	globals.o RawConsole.o sort.o


INCL	= shell.h


Shell	: $(OBJS)
	ln   +ss -wo Shell $(OBJS) -lc

RawConsole.o : RawConsole.c $(INCL)
	cc    +IShell.syms RawConsole.c

run.o   : run.c $(INCL)
	cc    +HShell.syms run.c

main.o  : main.c $(INCL)
	cc    -DJGII +IShell.syms main.c

comm1.o	: comm1.c $(INCL)
	cc    +IShell.syms comm1.c

comm2.o	: comm2.c $(INCL)
	cc    +IShell.syms comm2.c

set.o	: set.c $(INCL)
	cc    +IShell.syms set.c

sub.o	: sub.c $(INCL)
	cc    +IShell.syms sub.c

globals.o : globals.c $(INCL)
	cc    +IShell.syms globals.c

execom.o : execom.c $(INCL)
	cc    +IShell.syms execom.c


makefile
######################################################################
#
# Makefile to build Shell 2.05M
# by Steve Drew 20-Jan-87
#
######################################################################

OBJS   = run.o main.o comm1.o comm2.o execom.o set.o sub.o \
   globals.o RawConsole.o sort.o dir.o info.o cli.o fexec.o

INCL   = shell.h

COPT   =


Shell   : $(OBJS)
   ln   +ss -o Shell $(OBJS) -lc

RawConsole.o : RawConsole.c $(INCL)
   cc    $(COPT) +X5 +IShell.syms RawConsole.c

run.o   : run.c $(INCL)
   cc    $(COPT) +X5 +HShell.syms run.c

main.o  : main.c $(INCL)
   cc    $(COPT) +X5 -DJGII +IShell.syms main.c

comm1.o   : comm1.c $(INCL)
   cc    $(COPT) +IShell.syms comm1.c

comm2.o   : comm2.c $(INCL)
   cc    $(COPT) +X5 +IShell.syms comm2.c

set.o   : set.c $(INCL)
   cc    $(COPT) +X5 +IShell.syms set.c

sub.o   : sub.c $(INCL)
   cc    $(COPT) +X5 +IShell.syms sub.c

globals.o : globals.c $(INCL)
   cc    $(COPT) +X5 +IShell.syms globals.c

sort.o : sort.c
   cc    $(COPT) +X5 sort.c

execom.o : execom.c $(INCL)
   cc    $(COPT) +X5 +IShell.syms execom.c

dir.o : dir.c $(INCL)
   cc    $(COPT) +X5 +IShell.syms dir.c

info.o : info.c $(INCL)
   cc    $(COPT) +X5 +IShell.syms info.c

cli.o : cli.c $(INCL)
   cc    $(COPT) +X5 +IShell.syms cli.c

fexec.o : fexec.c
   cc    $(COPT) +X5 fexec.c

RawConsole.c
/*
 * RawConsole.c
 *
 * Shell 2.05M  20-Jan-87
 * console handling, command line editing support for Shell
 * using new console packets from 1.2.
 * Written by Steve Drew. (c) 14-Oct-86.
 * 16-Dec-86 Slight mods to rawgets() for Disktrashing.
 *
 */
#include "shell.h" 

#define ACTION_SCREEN_MODE 994L

struct MsgPort        *replyport, *conid;
struct StandardPacket *packet;

initconsole()
{
    struct Process *myprocess;
  
    if (IsInteractive(Input())) {
        myprocess = (struct Process *) FindTask(NULL);      
        replyport = (struct MsgPort *) CreatePort(NULL,NULL);
        if(!replyport) exit(10);
        packet = (struct StandardPacket *) 
            AllocMem((long)sizeof(*packet),MEMF_PUBLIC | MEMF_CLEAR);
        conid = (struct MsgPort *) myprocess->pr_ConsoleTask; /* get console handler */
        printf("\23312{");
        set_var (LEVEL_SET, "_insert", "1");
    }
}

void
cleanupconsole()
{

    if (IsInteractive(Input())) {
       FreeMem(packet,(long)sizeof(*packet)); 
       DeletePort(replyport); 
    }
}

void 
setraw(onoff)
int onoff; 
{
 
 packet->sp_Msg.mn_Node.ln_Name = (char *) &(packet->sp_Pkt); /* link packet- */
 packet->sp_Pkt.dp_Link         = &(packet->sp_Msg);        /* to message    */
 packet->sp_Pkt.dp_Port         = replyport;         /* set-up reply port   */
 packet->sp_Pkt.dp_Type = ACTION_SCREEN_MODE;        /* function */

 if (onoff) { 
     packet->sp_Pkt.dp_Arg1 = DOSTRUE; 
     fflush(stdout);             /* I had previously set stdout to buf'rd */
     stdout->_buflen = 1;        /* but for raw mode we need single char */
     }
 else {
     packet->sp_Pkt.dp_Arg1 = FALSE;
     stdout->_buflen = STDBUF;            /* set back to buffr'd */
 }
 PutMsg(conid,packet);  /* send packet */
 WaitPort(replyport); /* wait for packet to come back */
 GetMsg(replyport);   /* pull message */
 
}
 

char *
rawgets(line,prompt)
char *line, *prompt;
{
    char *get_var();
    char *gets();
    register int n, pl;
    register int max, i;
    unsigned char c1,c2,c3;
    char fkeys[5];
    char *s;
    int fkey;
    int insert = 1;
    char rep[14];
    static int width;
    int recall = -1;
    struct HIST *hist;

    if (!IsInteractive(Input())) return(gets(line));
    if (WaitForChar((long)Input(), 100L)) {   /* don't switch to 1L ...*/
    /*  printf("%s",prompt); */               /* else causes read err's  */
   gets(line);
   return(line);
    } 
    setraw(1);
    printf("%s",prompt);
    max = pl = i = strlen(prompt);
    strcpy(line,prompt);
    if (!width) width = 77;
    if (s = get_var (LEVEL_SET, "_insert"))
        insert = atoi(s) ? 1 : 0;

    while((c1 = getchar()) != 255) {
   if (c1 < 156) switch(c1) {   
       case 155:
       c2 = getchar();
       switch(c2) {
           case 'A':         /* up arrow   */
         n = ++recall;
           case 'B':         /* down arrow */
         line[pl] = '\0';
         if (recall >= 0 || c2 == 'A') {
             if (c2 == 'B') n = --recall;
             if (recall >= 0) {
                 for(hist = H_head; hist && n--; 
                     hist = hist->next);
                 if (hist) strcpy(&line[pl],hist->line);
                 else recall = H_len;
             }
         }
         if (i != pl) 
             printf("\233%dD",i);
         printf("\015\233J");
         Write(Output(),line,(long)(i = max = strlen(line)));
         break;
           case 'C':         /* right arrow*/
         if (i < max) {
             i++;
             printf("\233C");
         }
         break;
           case 'D':         /* left arrow */
         if (i > pl) {
             i--;
             printf("\233D");
         }
         break;
          case 'T':         /* shift up   */
          case 'S':         /* shift down */
         break;
          case ' ':         /* shift -> <-*/
         c3 = getchar();
         break;
          default:
         c3 = getchar();
         if (c3 == '~') {
             fkey = c2;
                            fkeys[0] = 'f';
             if (c2 == 63) {
            strcpy(&line[pl],"help");
            goto done;
             }
         }
         else if (getchar() != '~') { /* window was resized */
                  while(getchar() != '|');
                              printf("\2330 q"); /* get window bounds */
                      n = 0;
                  while((rep[n] = getchar()) != 'r' && n++ < 14 );
                  width = (rep[n-3] - 48) * 10 + rep[n-2] - 48;
                  rep[n-1] = '\0';
                  set_var (LEVEL_SET, "_width", &rep[n-3]);
                            break;
             }
             else {
                            fkey = c3;
                            fkeys[0] = 'F';
                        }
         sprintf(fkeys+1,"%d",fkey - 47);
         if (!(s = get_var(LEVEL_SET, fkeys))) break;
         strcpy(&line[pl], s);
         printf("%s",&line[pl]);
         goto done;
         break;
          } 
      break;
       case 8:
      if (i > pl) {
          i--;
          printf("\010");
      }
      else break;
       case 127:
      if (i < max) {
          int j,t,l = 0;
          movmem(&line[i+1],&line[i],max-i);
          --max;
          printf("\233P");
          j = width - i % width - 1;    /* amount to end     */
          t = max/width - i/width;    /* no of lines       */
          for(n = 0; n < t; n++) {
         l += j;          /* no. of char moved */
         if (j) printf("\233%dC",j); /* goto eol       */
         printf("%c\233P",line[width*(i/width+n+1)-1]);
         j = width-1;
          }
          if (t)
          printf("\233%dD",l+t);   /* get back */
      }
      break;
       case 18:
      n = i/width;
      if (n) printf("\233%dF",n);
      printf("\015\233J%s",line);
      i = max;
      break;
       case 27:
       case 10:
      break;
       case 1:
      insert ^= 1;
      break;
       case 21:
       case 24:
       case 26:
      if (i > pl)
          printf("\233%dD",i-pl);
      i = pl;
      if (c1 == 26) break;
      printf("\233J");
      max = i;
      line[i] = '\0';
      break;
       case 11:        /* ^K */
           printf("\233J");
           max = i;
           line[i] = '\0';
           break; 
            case 28:        /* ^\ */
                setraw(0);
                return(NULL);
       case 5:
      printf("\233%dC",max - i);
      i = max;
      break;
       case 13:
      line[max] = '\0';
done:      printf("\233%dC\n",max - i);

      setraw(0);
      strcpy(line, &line[pl]);
      return(line);
       default:
      if (c1 == 9) c1 = 32;
      if (c1 > 31 & i < 256) {
          if (i < max && insert) {
         int j,t,l = 0;
         movmem(&line[i], &line[i+1], max - i);
         printf("\233@%c",c1);
         t = max/width - i/width;
         j = width - i % width - 1;
         for(n = 0; n < t; n++) {
             l += j;
             if (j) printf("\233%dC",j);
             printf("\233@%c",line[width*(i/width+n+1)]);
             j = width-1;
         }
         if (t) printf("\233%dD",l + t);
         ++max;            
          }
          else {
         if (i == pl && max == i) printf("\015%s",line);
         putchar(c1);
          }
          line[i++] = c1;
          if (max < i) max = i;
          line[max] = '\0';
      }
   }
    }
    setraw(0);
    return(NULL);
}

readme.205m


	VERSION RELEASES:  (Manx Versions)
	----------------

	2.05M   10-Jan-87 Steve Drew  :Few bugs fixed, Matt's new 2.04
				      :features implemented.
	2.04M	09-Dec-86 Steve Drew  :Few bugs fixed, Commandline Editing
				      :& Function key support added.
				      :Changed my version to (M)anx.
	2.02A	20-oct-86 Steve Drew  :Implemented Matt's new features also
				      :now 16 bit compilable.
				      :(Same functionality as Matt's 2.03)
	2.01A	27-sep-86 Steve Drew  :Major conversion from Lattice > MANX
				      :and added more commands/features.

    	Steve Drew at	ENET:    CGFSV1::DREW
    			ARPA:    drew%cfgsv1.dec.com@decwrl.dec.com
    			USENET:  {decvax|decwrl}!cgfsv1.dec.com!drew    

Version 2.05M notes: (new features)
-----------------------------------

	- Shell search path now used on 'run' command as well.
	- New -e, exclude files option on dir command. see shell.doc.
	- Command line editing new key:  ^K - delete to end of line.
        - New variable _insert set to 0 makes default of no insert mode
	  for commandline editing default is 1. (insert mode on).
	- New 'copy' command from Matt's 2.04 'cp' logs files and directorys
	  as they are created and ^C detection. See doc for -r option.
	- Few bugs fixed.

   NEW FEATURES IN 2.04: (from Matt implemented in 2.05M)

        - RM command now has '-r' option.
        - \command forces the command parser NOT to look at aliases.  Thus,
          you can alias something like 'cd' and have the alias contain a 'cd'
          which references the internal cd:
           alias cd "stuff...;\\cd $x"
        - _histnum variable .. current history #
        - expanded filenames are sorted.
	   eg. Dir *    will output sorted directory.
 
Version 2.04M notes: (new features)
-----------------------------------
	
	- This version runs UNDER WORKBENCH 1.2 ONLY.
	- COMMAND LINE EDITING
	- Using Function keys.
	- New variable _width shows the number of collums in the window.
	  and will change automatically if the user resizes the window.
	- option -c when starting will invoke the rest of command line
	  and exit. (Thanks Dave.) Usefull to do stuff in the background.
	  e.g. run shell -c copy c:foo ram:;echo done.
	- pwd gets run as part of cd so as to set _cwd to full path name.

 
Version 2.02A notes: 
--------------------
	- For new features of 2.03 see Matt's instruction.txt appended below.
	- All Matt's new feature for 2.03 converted to manx. And uses c.lib.
	- Redirection appears to work fine. Even on bcpl programs.
	  Let me know if you find otherwise.
	- new varible	_path	for setting search path for external
	  cmds. Shell does not use the 1.2 PATH feature but you may
	  specify a search path by setting this symbol.
		e.g.
			$ set _path "ram:,c:,df0:c/,df1:c/"

	- Auto requesters are turned off during searching for cmds
	  except when an explicit path is specified eg. df0:c/sort.
	- Command list is sorted so that help displays readable output.
	- A few bugs fixed
	- Changed all i/o routines that used MY.LIB written by Matt to
	  use standard i/o or Amiga routines, since Manx is so efficeint
	  with standard i/o routines compiling all those library functions
	  did'nt gain anything as it does with Lattice.
	- Dir command rewritten to allow options:
		-s short mutil(4) collum display of files
		-d directorys only
		-f files only
	- Wildcarding now matches upper or lower case.	
	- Command will no longer abort if one of the arguments which
	  has wild card does not expand.
	- run program >redir will work properly as
	  long as you run command is called 'run'. With the lattice 
	  version the command got parsed like run >redir program, so
   	  all you got in you redir file was [CLI n].
	- On startup you current directory is determined and set.
	- Added %full and volume name to devinfo.
	- ps command added
	  

   NEW FEATURES IN 2.03.  Thanks to Steve Drew who suggested a '_path'
   variable.  The other difference with this version is that BCPL
   output redirection works properly.  Additionaly, alias loops are
   detected (this is what is known as a hack).
 
   NEW FEATURES IN 2.02.  I would like to thank Dave Wecker and Steve Drew
   for their numerous comments on the previous version of my shell.
 
   -Return code and error handling
      (A) retrieve return code
      (B) Manual or Automatic error handling.
   -Control C-F now passed to external commands.
   -can execute shell scripts as if they were normal commands (w/ arguments)
    (see down below)
   -BCPL programs which change the CLI state (CD/PATH...) now work with
    the shell.  However, the CLI PATH is not used currently.
   -MV command embellished... can now specify multiple files with a
    directory as the destination.
   -CD re-written, new variable $_cwd. startup directory figured out.
   -Comment character '#'
   -EXIT as an alternate to QUIT
 
   Additional Commands:
      abortline
      forever
 
   Additional SET variables (see documentation below)
      _cwd           current directory (see CD below)
      _maxerr        worst return value to date
      _lasterr       return value from last command (internal or external)
      _except        contains error level AND exception code. "nnn;command"
                     (see ABORTLINE, and start of section E)
 
      _passed        contains passed command line to source files
      _path          contains search path (example:  "c:,df1:c/,df0:c/"
 

run.c

/*
 * RUN.C
 *
 * (c)1986 Matthew Dillon     9 October 1986
 *
 *    RUN   handles running of external commands.
 *
 * version 2.05M (Manx Version and Additions) by Steve Drew 20-Jan-87
 *
 */

#include "shell.h"

char *FindIt();

do_run(str)
char *str;
{
   int i, try = -1;
   int run = 0;
   char buf[128];
   char runcmd[128];
   char *save, *path;


   if (path = FindIt(av[0],"",buf)) {   
      if (!strcmp(av[0],"run")) {
         if (FindIt(av[1],"",runcmd)) {
            run = 1;
            save = av[1];
            av[1] = runcmd;
         }
      }
      if ((try = fexecv(path, av)) == 0)
         i = wait();
      if (run) av[1] = save;      
   } 
   else if ((try = fexecv(av[0], av)) == 0)     /* added by jgII  1-23-87 */
      i = wait();
   if (try) {
      long lock;
      char *copy;

      if ((path = FindIt(av[0],".sh",buf)) == NULL) {
         fprintf(stderr,"Unknown command %s\n",av[0]);
         return (-1);
      }
      av[1] = buf;               /* particular to do_source() */
      copy = malloc(strlen(str)+3);
      strcpy(copy+2,str);
      copy[0] = 'x';
      copy[1] = ' ';
      i = do_source(copy);
      free(copy);
   }
   return (i);
}


char *
FindIt(cmd, ext, buf)
char *cmd;
char *ext;
char *buf;
{
   long lock = 0;
   char hasprefix = 0;
   APTR original;
   char *ptr, *s = NULL;

   original = Myprocess->pr_WindowPtr;

   for (ptr = cmd; *ptr; ++ptr) {
      if (*ptr == '/' || *ptr == ':')
         hasprefix = 1;
   }
   
   if (!hasprefix) {
      Myprocess->pr_WindowPtr = (APTR)(-1);
      s = get_var(LEVEL_SET, V_PATH);
   }

   strcpy(buf, cmd);
   strcat(buf, ext);
   while ((lock = (long)Lock(buf, ACCESS_READ)) == 0) {
      if (*s == NULL || hasprefix) break;
      for(ptr = s; *s && *s != ','; s++) ;
      strcpy(buf, ptr);
      buf[s-ptr] = '\0';
      strcat(buf, cmd);
      strcat(buf, ext);
      if (*s) s++;
   }
   Myprocess->pr_WindowPtr = original;
   if (lock) {
      UnLock(lock);
      return(buf);
   }
   return(NULL);
}


set.c

/*
 * SET.C
 *
 * (c)1986 Matthew Dillon     9 October 1986
 *
 * version 2.05M (Manx Version and Additions) by Steve Drew 20-Jan-87
 *
 */

#include "shell.h"
#define MAXLEVELS (3 + MAXSRC)

struct MASTER {
   struct MASTER *next;
   struct MASTER *last;
   char *name;
   char *text;
};

static struct MASTER *Mbase[MAXLEVELS];

char *
set_var(level, name, str)
register char *name, *str;
{
   register struct MASTER *base = Mbase[level];
   register struct MASTER *last;
   register int len;

   for (len = 0; isalphanum(name[len]); ++len);
   while (base != NULL) {
      if (strlen(base->name) == len && strncmp (name, base->name, len) == 0) {
         Free (base->text);
         goto gotit;
      }
      last = base;
      base = base->next;
   }
   if (base == Mbase[level]) {
      base = Mbase[level] = (struct MASTER *)malloc (sizeof(struct MASTER));
      base->last = NULL;
   } else {
      base = (struct MASTER *)malloc (sizeof(struct MASTER));
      base->last = last;
      last->next = base;
   }
   base->name = malloc (len + 1);
   bmov (name, base->name, len);
   base->name[len] = 0;
   base->next = NULL;
gotit:
   base->text = malloc (strlen(str) + 1);
   strcpy (base->text, str);
   return (base->text);
}

char *
get_var (level, name)
register char *name;
{
   register struct MASTER *base = Mbase[level];
   register unsigned char *scr;
   register int len;

   for (scr = (unsigned char *)name; *scr && *scr != 0x80 && *scr != ' ' && *scr != ';' && *scr != '|'; ++scr);
   len = scr - name;

   while (base != NULL) {
      if (strlen(base->name) == len && strncmp (name, base->name, len) == 0)
         return (base->text);
      base = base->next;
   }
   return (NULL);
}

unset_level(level)
{
   register struct MASTER *base = Mbase[level];

   while (base) {
      Free (base->name);
      Free (base->text);
      Free (base);
      base = base->next;
   }
   Mbase[level] = NULL;
}

unset_var(level, name)
char *name;
{
   register struct MASTER *base = Mbase[level];
   register struct MASTER *last = NULL;
   register int len;

   for (len = 0; isalphanum(name[len]); ++len);
   while (base) {
      if (strlen(base->name) == len && strncmp (name, base->name, len) == 0) {
         if (base != Mbase[level])
            last->next = base->next;
         else
            Mbase[level] = base->next;
         if (base->next != NULL)
            base->next->last = last;
         if (base == Mbase[level])
            Mbase[level] = base->next;
         Free (base->name);
         Free (base->text);
         Free (base);
         return (1);
      }
      last = base;
      base = base->next;
   }
   return (-1);
}


do_unset_var(str, level)
char *str;
{
   register int i;

   for (i = 1; i < ac; ++i)
      unset_var (level, av[i]);
   return (0);
}

do_set_var(command, level)
char *command;
{
   register struct MASTER *base = Mbase[level];
   register char *str;

   if (ac == 1) {
      while (base) {
	 if (CHECKBREAK())
	     return(0);
         printf ("%-10s ", base->name);
         puts (base->text);
         base = base->next;
      }
      return (0);
   }
   if (ac == 2) {
      str = get_var (level, av[1]);
      if (str) {
         printf ("%-10s ", av[1]);
         puts(str);
      } else if (level == LEVEL_SET) { /* only create var if set command */
         set_var (level, av[1], "");
      }
   }
   if (ac > 2)
      set_var (level, av[1], next_word (next_word (command)));
   if (*av[1] == '_') {
      S_histlen = (str = get_var(LEVEL_SET, V_HIST))   ? atoi(str) : 0;
      debug     = (str = get_var(LEVEL_SET, V_DEBUG))  ? atoi(str) : 0;
      Verbose   = (get_var(LEVEL_SET, V_VERBOSE)) ? 1 : 0;
      if (S_histlen < 2)   S_histlen = 2;
   }
   return (0);
}
shell.doc
		INSTRUCTIONS FOR SHELL V2.05M    20-Jan-87
		-----------------------------

SHELL V2.04. (C)Copyright 1986, Matthew Dillon, All Rights Reserved.
You may distribute this program for non-profit only.

		Shell V2.05M by Steve Drew.
		--------------------------
--------------------------------------------------------------------------
Note:
    These Instructions are my specific 2.05M Instructions and Matt's 2.04
    merged together. 
    A preceding | indicates that funtionality has been changed/enhanced,
    a preceding * indicates that this is functionality or a command
    that has been added in my manx version.

    for version releases see readme file. 
---------------------------------------------------------------------------

      (A)   Compiling
      (B)   Overview
      (C)   Quicky tech notes on implimentation.
 
      (D)   Command pre-processor
      (E)   Command Line Editing
      (F)   Function Keys
      (G)   Command-list
      (H)   special SET variables
 
      (I)   example .login file.
 

 
(A) COMPILING:
 
|   makefile supplied.
|
|   Your manx should be patched for 1.2 (c.lib) otherwise fexec wont work
|   and you'll just get "command not found" for all external commands.


(B) OVERVIEW:
 
   OVERVIEW of the major features:
 
   -simple history
   -redirection
   -piping
   -command search path 
   -aliases
   -variables & variable handling (embedded variables)
   -file name expansion via '?' and '*'
   -conditionals
   -source files  (w/ gotos and labels)
   -many built in commands to speed things up

   PROBLEMS
 
   -Not really a bug  but, if you want to pass a quote to an
    external command dont forget to use the overide '\' character
	eg.   Relabel df0: \"Blank disk\"
 
   -Append '>>' does NOT work with BCPL programs.  It does work with all
    internal and non-bcpl programs.
 
   -This version runs UNDER WORKBENCH 1.2 ONLY.
    
 
(C) QUICK TECH NOTES:
 
   PIPES have been implimented using temporary RAM: files.  Thus, you
   should be careful when specifying a 'ram:*' expansion as it might
   include the temp. files.  These files are deleted on completion of
   the pipe segment.
 
   The file names used are completely unique, even with multiple shell
   running simultaniously.
 
   My favorite new feature is the fact that you can now redirect to and
   from, and pipe internal commands.  'echo charlie >ram:x', for
   instance.  Another favorite:
 
      echo "echo mem | shell" | shell
 
   To accomplish these new features, I completely re-wrote the command
   parser in execom.c
 
   The BCPL 'RUN' command should not be redirected.. .strange things
   happen.
 
   NO BCPL program should be output-append redirected (>>).
 
 
(D)   Command pre-processor
 
   preprocessing is done on the command line before it is passed on to
   an internal or external routine:
 
   ^c       where c is a character is converted to that control character.
            Thus, say '^l' for control-l.
 
   $name    where name is a variable name.  Variable names can consist of
            0-9, a-z, A-Z, and underscore (_).  The contents of the
            specified variable is used.  If the variable doesn't exist,
            the specifier is used.  That is, if the variable 'i' contains
            'charlie', then '$i' -> 'charlie'.  If the variable 'i' doesn't
            exist, then '$i'->'$i' .
 
   ;        delimits commands.   echo charlie ; echo ben.
 
   ' '      (a space). Spaces delimit arguments.
 
   "string" a quoted string.  For instance, if you want to echo five spaces
            and an 'a':
 
            echo      a       -> a
            echo "    a"      ->      a
 
   \c       overide the meaning of special characters.  '\^a' is a
            circumflex and an a rather than control-a.  To get a backslash,
            you must say '\\'.
 
            also used to overide alias searching for commands.
 
   >file    specify output redirection.  All output from the command is
            placed in the specified file.
 
   >>file   specify append redirection (Does not work with BCPL programs).
 
   <file    specify input redirection.  The command takes input from the
            file rather than the keyboard (note: not all commands require
            input).  It makes no sense to say  'echo <charlie' since
            the 'echo' command only outputs its arguments.
 
   |        PIPE specifier.  The output from the command on the left becomes
            the input to the command on the right.  The current SHELL
            implimentation uses temporary files to store the data.
 
   !!       execute the previously executed command.
   !nn      (nn is a number).  Insert the history command numbered n (see
            the HISTORY command)
   !partial search backwards through the history list for a command which
            looks the same as 'partial', and execute it.
 
   #        Enter comment.  The rest of the line is discarded (note: \#
            will, of course, overide the comment character's special
            meaning)
 

(E) Command Line Editing

*  - Command line can be upto 255 chars.
*  - Inserts and deletes are handled correctly over
*    multiple screen lines. The program will keep track of
*    the line width should the window get resized.
*
*	KEY DEFINITIONS:
*   	  	Up Arrow    Recal previous commands
*	  	Down Arrow  Recal commands
*		Left Arrow  Move cursor about command line.
*		Right Arrow  "     "      "      "      "
*		^A	    Toggle insert/overtype mode.
*		^D	    EOF
*		^E	    Put cursor at end of text.
*		^K	    Delete to end of line.
*		^R	    Retype current line.
*		^U	    Erase entire line.
*		^X	    Erase entire line.
*		^Z	    Put cursor at start of text.
*		f1 - f10    Execute command if variable exists.
*		F1 - F10    More commands (Shifted f keys).
*		Help 	    invokes help command

(F) Function keys.
		
*  - Just set the variable f1-f10 or F1-F10 (shifted) to
*    the desired string.
*
*	  eg. 
*  	     $ set f1 "dir -s df0:"			

 
(G)  COMMAND LIST:
 
   The first argument is the command-name... if it doesn't exist in the
   list below and isn't an alias, it is assumed to be an external (disk)
   command.
 
   AUTOMATIC SOURCING may be accomplished by naming shell scripts with a
   .sh suffix.  Thus, if you say 'stuff' and the file 'stuff.sh' exists in
   your current or C: directory, it will be SOURCED with any arguments you
   have placed in the $_passed variable.
 
   EXCEPTION_PROCESSING:
 
      if no _except variable exists, any command which fails causes the
      rest of the line to abort as if an ABORTLINE had been executed.  If
      the _except variable exists, it is of the form:
 
      "nnn;commands..."
 
      where nnn is some value representing the minimum return code required
      to cause an error.  Whenever a command returns a code which is
      larger or equal to nnn, the commands in _except are executed before
      anything.  WHEN _except EXISTS, THE COMMAND LINE DOES NOT ABORT
      AUTOMATICALLY.  Thus, if you want the current line being executed
      to be aborted, the last command in _except should be an "abortline".
 
      exception handling is disabled while in the exception handling routine
      (thus you can't get into any infinite loops this way).
 
      Thus if _except = ";", return codes are completely ignored.
 
      example:
 
      set _except "20;abortline"
 
 
   ABORTLINE
 
      or just 'abort'.  Causes the rest of the line to be aborted. Used in
      conjunction with exception handling.
 
      % echo a;abort;echo b
      a
 
 
   HELP
 
|     simply displays all the available commands.  The commands are
|     displayed in search-order.  That is, if you give a partial name
|     the first command that matches that name in this list is the one
|     executed.  Generally, you should specify enough of a command so that
|     it is completely unique.
 
   QUIT
   EXIT
   RETURN [n]
 
      quit my SHELL (awww!).  End, El-Zappo, Kapow. Done, Finis.  If you
      use RETURN and are on the top source level, the shell exits with the
      optional return code.  (see RETURN below)
 
 
   SET
   SET name
   SET name string
 
      The first method lists all current variable settings.
      The second method lists the setting for that particular variable,
      or creates the variable if it doesn't exist (to "")
      The last method sets a variable to a string.
 
      see the section on special _ variables down below
 
 
   UNSET name name name....
 
      unset one or more variables.  Deletes them entirely.
 
 
   ALIAS
   ALIAS name
   ALIAS name string
 
      same as SET, but applies to the alias list.  You can alias a single
      name to a set of commands.  For instance:
 
      alias hi "echo a; echo b"
 
      then you can simply say 'hi'.  Aliases come in two forms the second
      form allows you to place the arguments after an alias in a variable
      for retrieval:
 
      alias xxx "%i echo this $i is a test"
 
      % xxx charlie
      this charlie is a test
 
      The rest of the command line is placed in the specified variable
      for the duration of the alias.  This is especially useful when used
      in conjunction with the 'FOREACH' command.
 
 
   UNALIAS name name name...
 
      delete aliases..
 
 
   ECHO string
   ECHO -n string
 
      echo the string to the screen.  If '-n' is specified, no newline is
      output.
 
 
   STRHEAD  varname breakchar string
 
      remove everything after and including the breakchar in 'string' and
      place in variable 'varname':
 
         % strhead j . aaa.bbb
         % echo $j
         aaa
         %
 
 
   STRTAIL  varname breakchar string
 
      remove everything before and including the breakchar in 'string' and
      place in variable 'varname':
 
         % strtail j . aaa.bbb
         % echo $j
         bbb
         %
 
 
   SOURCE file [arguments]
 
      execute commands from a file.  You can create SHELL programs in
      a file and then execute them with this command.  Source'd files
      have the added advantage that you can have loops in your command
      files (see GOTO and LABEL).  You can pass SOURCE files arguments
      by specifying arguments after the file name.  Arguments are passed
      via the _passed variable (as a single string).
 
      Automatic 'sourcing' is accomplished by placing a .sh extension on
      the file and executing it as you would a C program:
 
      --------- file hello.sh ---------
      foreach i ( $_passed ) "echo yo $i"
      ---------------------------------
      % hello a b c
      yo a
      yo b
      yo c
 
 
   MV from to
   MV from from from ... from todir
 
      Allows you to rename a file or move it around within a disk.  Allows
      you to move 1 or more files into a single directory.
 
 
   CD
   CD ..
   CD path
 
|     Change your current working directory.  You may specify '..' to go
|     back one directory (this is a CD specific feature, and does not
|     work with normal path specifications).
 
      CD without any arguments displays the path of the directory you
      are currently in.
 
 
   PWD
      rebuild _cwd by backtracing from your current directory.
 
 
   RM [-r] file file file...
 
      DeleteFile().  Remove the specified files.  Remove always returns
      errorcode 0.  You can remove empty directories.  The '-r' option
      will remove non-empty directories by recursively removing all sub
      directories.
*     If  you specify any wildcard deletes the files will be listed as
*     they are deleted. This can be suppressed by redirecting to nil: 

 
|  COPY file file
|  COPY file1 file2...fileN dir
|  COPY [-r] dir1 dir2...dirN dir
 
      copy files or directories.  when copying directories, the "-r" option
      must be specified to copy subdirectories as well.  Otherwise, only
      top level files in the source directory are copied.

*     All files will be displayed as they are copied and directory's displayed
*     as they are created. This output can be suppessed by redirecting to nil:
*	eg. copy -r >nil: df0: df1:
*     copy will abort after current file on Control-C.
 
   MKDIR name name name...
 
      create the following directories.
 
 
   HISTORY [partial_string]
 
      Displays the enumerated history list.  The size of the list is
      controlled by the _history variable.  If you specify a partial-
      string, only those entries matching that string are displayed.
 
 
   MEM
 
      Display current memory statistics for CHIP and FAST.
 
 
   CAT [file file....]
 
      Type the specified files onto the screen.  If no file is specified,
      STDIN in used.  CAT is meant to output text files only.
 
 
|  DIR [-sdf] [path path ... ]
 
|	- default output show's date, protection, block size, byte size.
*	- Dir command rewritten to allow options:
*		-s short mutil(4) collum display of files
*			(directory files are in italics).
*		-d directorys only
*		-f files only
*		-e exclude files. Specify as the next argument a pattern
*		   for the files to be excluded. Do not use * or ? chars
*		   as the '*' is already appended to either side of the 
*		   pattern and this prevents the preprosesor from expanding
*	    	   them. eg. -e .c is merge to *.c* so any file spec 
*		   containing a ".c" string is skipped.	           
*
*	  eg. dir -se .info       (short directory exclude all .info files.)
				
|	  the directory command will also not expand files that are
|	  directories if as result of a wildcard expansion. eg:
|	  'dir df0:*'  and 'dir df0:' will give same results
|	  expect previously if df0:* was specified all subdirectories
|	  of df0: were expanded also.
|	  (to list the subdirectories: 'dir df0:*/*')
				
 
   DEVINFO [device: device:... ]
 
      Display Device statistics for the current device (CD base), or
      specified devices.
|     Gives block used/free, % used, errs and volume name.

 
   FOREACH varname ( strings ) command
 
      'strings' is broken up into arguments.  Each argument is placed in
      the variable 'varname' in turn and 'command' executed.  To execute
      multiple commands, place them in quotes:
 
      % foreach i ( a b c d ) "echo -n $i;echo \" ha\""
      a ha
      b ha
      c ha
      d ha
 
      Foreach is especially useful when interpreting passed arguments in
      an alias or source file.
 
      NOTE: a GOTO inside will have indeterminate results.
 
 
   FOREVER command
   FOREVER "command;command;command..."
 
      The specified commands are executed over and over again forever.
 
      -Execution stops if you hit ^C
      -If the commands return with an error code.
 
      NOTE: a GOTO inside will have indeterminate results.
 
 
   RETURN [value]
 
      return from a source file.  The rest of the source file is
      discarded.  If given, the value becomes the return value for the
      SOURCE command.  If you are on the top level, this value is returned
      as the exit code for the shell.
 
 
   IF argument conditional argument ;
   IF argument
 
      If a single argument is something to another argument.  Conditional
      clauses allowed:
 
      <, >, =, and combinations (wire or).  Thus <> is not-equal, >=
      larger or equal, etc...
 
      If the left argument is numeric, both arguments are treated as
      numeric.
 
      usually the argument is either a constant or a variable ($varname).
 
      The second form if IF is conditional on the existance of the argument.
      If the argument is a "" string, then false , else TRUE.
 
 
   ELSE ;
 
      else clause.
 
 
   ENDIF ;
 
      the end of an if statement.
 
 
   LABEL name
 
      create a program label right here.
 
 
   GOTO label
 
      goto the specified label name.  You can only use this command from a
      source file.
 
 
   DEC var
   INC var
 
      decrement or increment the numerical equivalent of the variable and
      place the ascii-string result back into that variable.
 
 
   INPUT varname
 
      input from STDIN (or a redirection, or a pipe) to a variable.  The
      next input line is placed in the variable.
 
 
   VER
 
      display my name and the version number.
 
 
   SLEEP timeout
 
      Sleep for 'timeout' seconds.
 
*  PS
 
*    Gives the following info:
*	  
*	  Proc Command Name         CLI Type    Pri.  Address  Directory
*	   1   SHELL                Initial CLI   0      97b0  Stuff:shell
*	   2   sys:c/clockmem       Background  -10    2101a8  Workdisk:
*	   3   c:emacs              Background    0    212f58  Stuff:shell
*	   4   sys:c/VT100          Background    0    227328  Workdisk:
*	
*	   Address is the addres of the task, directory is the process
*	   currently set directory.
 
 
(H) SPECIAL SET VARIABLES
 
|   _prompt
|        This variable is set to the command you wish executed that will
|        create your prompt. Under manx version set this to the string
|	 for your prompt not a command to create the prompt. (Restriction
|	 due to commandline editing support.
 
   _history
         This variable is set to a numerical value, and specifies how far
         back your history should extend.
 
   _debug
         Debug mode... use it if you dare.  must be set to some value
 
   _verbose
         Verbose mode (for source files).  display commands as they are
         executed.
 
   _maxerr
         The worst (highest) return value to date.  To use this, you usually
         set it to '0', then do some set of commands, then check it.  
 
   _lasterr
         Return code of last command executed.  This includes internal
         commands as well as external comands, so to use this variables
         you must check it IMMEDIATELY after the command in question.
 
   _cwd
         Holds a string representing the current directory we are in from
         root.  The SHELL can get confused as to its current directory if
         some external program changes the directory.  Use PWD to rebuild
         the _cwd variable in these cases.
 
   _passed
         This variable contains the passed arguments when you SOURCE a file
         or execute a .sh file.  For instance:
 
         test a b c d
 
         -------- file test.sh ----------
         echo $_passed
         foreach i ( $_passed ) "echo YO $i"
         --------------------------------
 
 
   _path
         This variable contains the search path when the shell is looking
         for external commands.  The format is:  DIR,DIR,DIR  Each DIR must
         have a trailing ':' or '/'.  The current directory is always
         searched first.  The entire path will be searched first for the
         <command>, then for <command>.sh (automatic shell script sourcing).
 
         The default _path is set to  "c:,df1:c/,df0:c/,ram:,ram:c/"
*	 When using 'run' command Shell will now use it's own search
*	 path first to find the command to run. If it fails to find
*	 the command (but the Run command was found) it executes the
*	 command line anyway to let amigaDos search path take over.

*  _insert
*        Set's the default for insert/overtype mode for command line
*	 editing. ^A toggles between, but after <RET> the default is 
*         set back as indicated by this variable. By default _insert is 1
*        indicating insert mode on setting to zero will make overtype
*	 the default.

*  _width
*	 Indicates the console window width, 77 if unset. 
* 	 Will change automatically if the user resizes the window.
	
 
(I) EXAMPLE .login file.
 
   from a CLI or the startup-script say 'SHELL filename'.  That file
   is sourced first.  thus, 'SHELL .login' will set up your favorite
   aliases:
 
------------------------------------------------------------------------
.LOGIN
------------------------------------------------------------------------

# -Steve's .login file- #

echo -n    "Enter Date [DD-MMM-YY HH:MM] ";input new; DATE $new

# ------My search path ------- #

set   _path  ram:c/,ram:,c:,df0:c/,df1:c/,sys:system/,sys:utilities

# -------Function keys-------- #

set   f1     dir df0:
set   f2     dir df1:
set   F1     dir -s df0:
set   F2     dir -s df1:
set   f3     info
set   f4     ps

# ---------Quickies---------- #

# -query delete- #
#another favorite eg    qd *.c
alias qd "%q foreach i ( $q ) \"echo -n Delete [n] ;input a;if $a = y;del $i;endif\""

alias delete rm
alias rename mv
alias makedir mkdir
alias print "%q copy $q prt:"
alias info  "devinfo df0: df1: ram:"
alias tosys "assign c: SYS:c"
alias toram "assign c: RAM:c;"
alias tomanx "assign c: MANX:c; manxinit"
alias d     "dir -se .info"
alias clr   "echo -n ^l"
alias wb    "loadwb"
alias pref  "sys:preferences"
alias cal   "run sys:utilities/calculator"

# ------Applications---------- #

alias em    "run emacs"
alias vt    "run sys:c/VT100"

# --------Finish Up----------- #

ver ;echo -n "Shell loaded on ";date


------------------------------------------------------------------------
MANXINIT.SH
------------------------------------------------------------------------
SET INCLUDE=AC:include CCTEMP=ram:
makedir ram:lib;Set CLIB=RAM:lib/;copy AC:lib/$libfile ram:lib"
alias	cleanup	"del >NIL: ram:lib/* ram:lib"

#run make in background at lower priority:
alias	make	"%q run ChangeTaskPri -5 +^J^J MAKE $q"


------------------------------------------------------------------------
RAM.SH
------------------------------------------------------------------------
cp c:run ram:; cp c:assign ram:; cp c:cp ram:; assign c: ram:

shell.h

/*
 * SHELL.H
 *
 * (c)1986 Matthew Dillon     9 October 1986
 *
 *
 * SHELL include file.. contains shell parameters and extern's
 *
 *
 */

#include <stdio.h>
#include <time.h> 
#include <exec/types.h>
#include <exec/exec.h>
#include <libraries/dos.h>
#include <libraries/dosextens.h>
#include <exec/memory.h>
#include <exec/tasks.h>
#include <exec/ports.h>
#include <exec/io.h>
#include <functions.h>

#define bmov   movmem
#define STDBUF 256

#define MAXAV        256            /* Max. # arguments             */
#define MAXSRC       5              /* Max. # of source file levels */
#define MAXIF        10             /* Max. # of if levels          */
#define MAXALIAS     20             /* Max. # of alias levels       */

#define LEVEL_SET    0              /* which variable list to use   */
#define LEVEL_ALIAS  1
#define LEVEL_LABEL  2

#define V_PROMPT     "_prompt"      /* your prompt (ascii command)   */
#define V_HIST       "_history"     /* set history depth (value)     */
#define V_HISTNUM    "_histnum"     /* set history numbering var     */
#define V_DEBUG      "_debug"       /* set debug mode                */
#define V_VERBOSE    "_verbose"     /* set verbose for source files  */
#define V_STAT       "_maxerr"      /* worst return value to date    */
#define V_LASTERR    "_lasterr"     /* return value from last comm.  */
#define V_CWD        "_cwd"         /* current directory             */
#define V_EXCEPT     "_except"      /* "nnn;command"                 */
#define V_PASSED     "_passed"      /* passed arguments to source fle*/
#define V_PATH       "_path"        /* search path for external cmds */

            /* EXECOM.C defines */

#define FL_DOLLAR    0x01  /* One of the following */
#define FL_BANG      0x02
#define FL_PERCENT   0x04
#define FL_QUOTE     0x08
#define FL_IDOLLAR   0x10  /* Any or all of the following may be set */
#define FL_EOC       0x20
#define FL_EOL       0x40
#define FL_OVERIDE   0x80
#define FL_WILD      0x100
#define FL_MASK      (FL_DOLLAR|FL_BANG|FL_PERCENT|FL_QUOTE)


#define VERSION   "V2.05M  (c)1986 Matthew Dillon.  Manx version by Steve Drew"

#ifndef NULL
#define NULL 0L
#endif

#define CHECKBREAK() ( breakcheck() ? (printf("^C\n"),1) : 0)


struct HIST {
   struct HIST *next, *prev;     /* doubly linked list */
   char *line;                   /* line in history    */
};

struct PERROR {
   int errnum;                   /* Format of global error lookup */
   char *errstr;
};

struct DPTR {                    /* Format of directory fetch pointer */
   struct FileLock *lock;        /* lock on directory   */
   struct FileInfoBlock *fib;    /* mod'd fib for entry */
};

extern struct HIST *H_head, *H_tail;
extern struct PERROR Perror[];
extern struct DPTR *dopen();
extern char *set_var(), *get_var(), *next_word();
extern char *get_history(), *compile_av();
extern char *malloc(), *strcpy(), *strcat();
extern char **expand();
extern char *av[];
extern char *Current;
extern int  H_len, H_tail_base, H_stack;
extern int  E_stack;
extern int  Src_stack, If_stack;
extern int  ac;
extern int  debug, Rval, Verbose, disable, Quit;
extern int  Lastresult;
extern int  Exec_abortline, Exec_ignoreresult;
extern int   S_histlen;
extern long  Uniq;
extern long  Cin, Cout, Cout_append;
extern char *Cin_name, *Cout_name;
extern char  Cin_type,  Cout_type;  /* these variables are in transition */
extern char *Pipe1, *Pipe2;

extern long Src_base[MAXSRC];
extern long Src_pos[MAXSRC];
extern char If_base[MAXIF];
extern struct Process *Myprocess;

sort.c

/*
 * SORT.C
 *
 * a QuickSort is used for speed, simplicity, and small code size.
 *
 */


QuickSort(av, n)
char *av[];
short n;
{
   short b;

   if (n > 0) {
      b = QSplit(av, n);
      QuickSort(av, b);
      QuickSort(av+b+1, n - b - 1);
   }
}


/*
 * QSplit called as a second routine so I don't waste stack on QuickSort's
 * recursivness.
 */

QSplit(av, n)
register char *av[];
short n;
{
   register short i, b;
   register char *element, *scr;

   element = av[0];
   for (b = 0, i = 1; i < n; ++i) {
      if (strcmp(av[i], element) < 0) {
         ++b;
         scr = av[i]; av[i] = av[b]; av[b] = scr;
      }
   }
   scr = av[0]; av[0] = av[b]; av[b] = scr;
   return (b);
}
sub.c

/*
 * SUB.C
 *
 * (c)1986 Matthew Dillon     9 October 1986
 *
 * version 2.05M (Manx Version and Additions) by Steve Drew 20-Jan-87
 *
 */

#include "shell.h"

#define HM_STR 0              /* various HISTORY retrieval modes */
#define HM_REL 1
#define HM_ABS 2

extern struct FileLock *Clock;
seterr()
{
   char buf[32];
   int stat;

   sprintf(buf, "%d", Lastresult);
   set_var(LEVEL_SET, V_LASTERR, buf);
   stat = atoi(get_var(LEVEL_SET, V_STAT));
   if (stat < Lastresult)
      stat = Lastresult;
   sprintf(buf, "%d", stat);
   set_var(LEVEL_SET, V_STAT, buf);
}


char *
next_word(str)
register char *str;
{
   while (*str  &&  *str != ' '  &&  *str != 9)
      ++str;
   while (*str  && (*str == ' ' || *str == 9))
      ++str;
   return (str);
}


char *
compile_av(av, start, end)
char **av;
{
   char *cstr;
   int i, len;

   len = 0;
   for (i = start; i < end; ++i)
      len += strlen(av[i]) + 1;
   cstr = malloc(len + 1);
   *cstr = '\0';
   for (i = start; i < end; ++i) {
      strcat (cstr, av[i]);
      strcat (cstr, " ");
   }
   return (cstr);
}

/*
 * FREE(ptr)   --frees without actually freeing, so the data is still good
 *               immediately after the free.
 */


Free(ptr)
char *ptr;
{
   static char *old_ptr;

   if (old_ptr)
      free (old_ptr);
   old_ptr = ptr;
}

/*
 * Add new string to history (H_head, H_tail, H_len,
 *  S_histlen
 */

add_history(str)
char *str;
{
   register struct HIST *hist;

   if (H_head != NULL && strcmp(H_head->line, str) == 0)
       return(0);
   while (H_len > S_histlen)
      del_history();
   hist = (struct HIST *)malloc (sizeof(struct HIST));
   if (H_head == NULL) {
      H_head = H_tail = hist;
      hist->next = NULL;
   } else {
      hist->next = H_head;
      H_head->prev = hist;
      H_head = hist;
   }
   hist->prev = NULL;
   hist->line = malloc (strlen(str) + 1);
   strcpy (hist->line, str);
   ++H_len;
}

del_history()
{
   if (H_tail) {
      --H_len;
      ++H_tail_base;
      free (H_tail->line);
      if (H_tail->prev) {
         H_tail = H_tail->prev;
         free (H_tail->next);
         H_tail->next = NULL;
      } else {
         free (H_tail);
         H_tail = H_head = NULL;
      }
   }
}

char *
get_history(ptr)
char *ptr;
{
   register struct HIST *hist;
   register int len;
   int mode = HM_REL;
   int num  = 1;
   char *str;
   char *result = NULL;

   if (ptr[1] >= '0' && ptr[1] <= '9') {
      mode = HM_ABS;
      num  = atoi(&ptr[1]);
      goto skip;
   }
   switch (ptr[1]) {
   case '!':
      break;
   case '-':
      num += atoi(&ptr[2]);
      break;
   default:
      mode = HM_STR;
      str  = ptr + 1;
      break;
   }
skip:
   switch (mode) {
   case HM_STR:
      len = strlen(str);
      for (hist = H_head; hist; hist = hist->next) {
         if (strncmp(hist->line, str, len) == 0 && *hist->line != '!') {
            result = hist->line;
            break;
         }
      }
      break;
   case HM_REL:
      for (hist = H_head; hist && num--; hist = hist->next);
      if (hist)
         result = hist->line;
      break;
   case HM_ABS:
      len = H_tail_base;
      for (hist = H_tail; hist && len != num; hist = hist->prev, ++len);
      if (hist)
         result = hist->line;
      break;
   }
   if (result) {
      fprintf(stderr,"%s\n",result);
      return(result);
   }
   printf("History failed\n");
   return ("");
}

replace_head(str)
char *str;
{
   if (str == NULL)
      str = "";
   if (H_head) {
      free (H_head->line);
      H_head->line = malloc (strlen(str)+1);
      strcpy (H_head->line, str);
   }
}


pError(str)
char *str;
{
   int ierr = (long)IoErr();
   ierror(str, ierr);
}

ierror(str, err)
register char *str;
{
   register struct PERROR *per = Perror;

   if (err) {
      for (; per->errstr; ++per) {
         if (per->errnum == err) {
            fprintf (stderr, "%s%s%s\n",
                  per->errstr,
                  (str) ? ": " : "",
                  (str) ? str : "");
            return ((short)err);
         }
      }
      fprintf (stderr, "Unknown DOS error %ld %s\n", err, (str) ? str : "");
   }
   return ((short)err);
}

/*
 * Disk directory routines
 *
 * dptr = dopen(name, stat)
 *    struct DPTR *dptr;
 *    char *name;
 *    int *stat;
 *
 * dnext(dptr, name, stat)
 *    struct DPTR *dptr;
 *    char **name;
 *    int  *stat;
 *
 * dclose(dptr)                  -may be called with NULL without harm
 *
 * dopen() returns a struct DPTR, or NULL if the given file does not
 * exist.  stat will be set to 1 if the file is a directory.  If the
 * name is "", then the current directory is openned.
 *
 * dnext() returns 1 until there are no more entries.  The **name and
 * *stat are set.  *stat = 1 if the file is a directory.
 *
 * dclose() closes a directory channel.
 *
 */

struct DPTR *
dopen(name, stat)
char *name;
int *stat;
{
   struct DPTR *dp;

   *stat = 0;
   dp = (struct DPTR *)malloc(sizeof(struct DPTR));
   if (*name == '\0')
      dp->lock = (struct FileLock *)DupLock (Clock);
   else
      dp->lock = (struct FileLock *)Lock (name, ACCESS_READ);
   if (dp->lock == NULL) {
      free (dp);
      return (NULL);
   }
   dp->fib = (struct FileInfoBlock *)
         AllocMem((long)sizeof(struct FileInfoBlock), MEMF_PUBLIC);
   if (!Examine (dp->lock, dp->fib)) {
      pError (name);
      dclose (dp);
      return (NULL);
   }
   if (dp->fib->fib_DirEntryType >= 0)
      *stat = 1;
   return (dp);
}

dnext(dp, pname, stat)
struct DPTR *dp;
char **pname;
int *stat;
{
   if (dp == NULL)
      return (0);
   if (ExNext (dp->lock, dp->fib)) {
      *stat = (dp->fib->fib_DirEntryType < 0) ? 0 : 1;
      *pname = dp->fib->fib_FileName;
      return (1);
   }
   return (0);
}


dclose(dp)
struct DPTR *dp;
{
   if (dp == NULL)
      return (1);
   if (dp->fib)
      FreeMem (dp->fib,(long)sizeof(*dp->fib));
   if (dp->lock)
      UnLock (dp->lock);
   free (dp);
   return (1);
}


isdir(file)
char *file;
{
   register struct DPTR *dp;
   int stat;

   stat = 0;
   if (dp = dopen (file, &stat))
      dclose(dp);
   return (stat == 1);
}


free_expand(av)
register char **av;
{
   char **base = av;

   if (av) {
      while (*av) {
         free (*av);
         ++av;
      }
      free (base);
   }
}

/*
 * EXPAND(wild_name, pac)
 *    wild_name      - char * (example: "df0:*.c")
 *    pac            - int  *  will be set to # of arguments.
 *
 * Standalone, except in requires Clock to point to the Current-Directory
 * lock.
 */


char **
expand(base, pac)
char *base;
int *pac;
{
   register char *ptr;
   char **eav = (char **)malloc (sizeof(char *));
   short eleft, eac;
   char *name;
   char *bname, *ename, *tail;
   int stat, scr;
   register struct DPTR *dp;

   *pac = eleft = eac = 0;

   base = strcpy(malloc(strlen(base)+1), base);
   for (ptr = base; *ptr && *ptr != '?' && *ptr != '*'; ++ptr);
   for (; ptr >= base && !(*ptr == '/' || *ptr == ':'); --ptr);
   if (ptr < base) {
      bname = strcpy (malloc(1), "");
   } else {
      scr = ptr[1];
      ptr[1] = '\0';
      bname = strcpy (malloc(strlen(base)+1), base);
      ptr[1] = scr;
   }
   ename = ptr + 1;
   for (ptr = ename; *ptr && *ptr != '/'; ++ptr);
   scr = *ptr;
   *ptr = '\0';
   tail = (scr) ? ptr + 1 : NULL;

   if ((dp = dopen (bname, &stat)) == NULL  ||  stat == 0) {
      free (bname);
      free (base);
      free (eav);
      fprintf(stderr,"Could not open directory\n");
      return (NULL);
   }
   while (dnext (dp, &name, &stat)) {
      if (compare_ok(ename, name)) {
         if (tail) {
            int alt_ac;
            char *search, **alt_av, **scrav;
            struct FileLock *lock;

            if (!stat)           /* expect more dirs, but this not a dir */
               continue;
            lock = (struct FileLock *)CurrentDir (Clock = dp->lock);
            search = malloc(strlen(name)+strlen(tail)+2);
            strcpy (search, name);
            strcat (search, "/");
            strcat (search, tail);
            scrav = alt_av = expand (search, &alt_ac);
            CurrentDir (Clock = lock);
            if (scrav) {
               while (*scrav) {
                  if (eleft < 2) {
                     char **scrav = (char **)malloc(sizeof(char *) * (eac + 10));
                     bmov (eav, scrav, (eac + 1) << 2);
                     free (eav);
                     eav = scrav;
                     eleft = 10;
                  }
                  eav[eac] = malloc(strlen(bname)+strlen(*scrav)+1);
                  strcpy(eav[eac], bname);
                  strcat(eav[eac], *scrav);
                  free (*scrav);
                  ++scrav;
                  --eleft, ++eac;
               }
               free (alt_av);
            }
         } else {
            if (eleft < 2) {
               char **scrav = (char **)malloc(sizeof(char *) * (eac + 10));
               bmov (eav, scrav, (eac + 1) << 2);
               free (eav);
               eav = scrav;
               eleft = 10;
            }
            eav[eac] = malloc (strlen(bname)+strlen(name)+1);
            eav[eac] = strcpy(eav[eac], bname);
            strcat(eav[eac], name);
            --eleft, ++eac;
         }
      }
   }
   dclose (dp);
   *pac = eac;
   eav[eac] = NULL;
   free (bname);
   free (base);
   if (eac) {
      return (eav);
   }
   free (eav);
   return (NULL);
}

/*
 * Compare a wild card name with a normal name
 */

#define MAXB   8

compare_ok(wild, name)
char *wild, *name;
{
   register char *w = wild;
   register char *n = name;
   char *back[MAXB][2];
   register char s1, s2;
   int  bi = 0;

   while (*n || *w) {
      switch (*w) {
      case '*':
         if (bi == MAXB) {
            printf(stderr,"Too many levels of '*'\n");
            return (0);
         }
         back[bi][0] = w;
         back[bi][1] = n;
         ++bi;
         ++w;
         continue;
goback:
         --bi;
         while (bi >= 0 && *back[bi][1] == '\0')
            --bi;
         if (bi < 0)
            return (0);
         w = back[bi][0] + 1;
         n = ++back[bi][1];
         ++bi;
         continue;
      case '?':
         if (!*n) {
            if (bi)
               goto goback;
            return (0);
         }
         break;
      default:
         s1 = (*n >= 'A' && *n <= 'Z') ? *n - 'A' + 'a' : *n;
         s2 = (*w >= 'A' && *w <= 'Z') ? *w - 'A' + 'a' : *w;
         if (s1 != s2) {
            if (bi)
               goto goback;
            return (0);
         }
         break;
      }
      if (*n)  ++n;
      if (*w)  ++w;
   }
   return (1);
}
tags
do_abortline comm2.c /^do_abortline(
do_return comm2.c /^do_return(
do_strhead comm2.c /^do_strhead(
do_strtail comm2.c /^do_strtail(
do_if comm2.c /^do_if(
do_label comm2.c /^do_label(
do_goto comm2.c /^do_goto(
do_inc comm2.c /^do_inc(
do_input comm2.c /^do_input(
do_ver comm2.c /^do_ver(
do_ps comm2.c /^do_ps(
btocstr comm2.c /^btocstr(
set_var set.c /^set_var(
get_var set.c /^get_var (
unset_level set.c /^unset_level(
unset_var set.c /^unset_var(
do_unset_var set.c /^do_unset_var(
do_set_var set.c /^do_set_var(
QuickSort sort.c /^QuickSort(
QSplit sort.c /^QSplit(
seterr sub.c /^seterr(
next_word sub.c /^next_word(
compile_av sub.c /^compile_av(
Free sub.c /^Free(
add_history sub.c /^add_history(
del_history sub.c /^del_history(
get_history sub.c /^get_history(
replace_head sub.c /^replace_head(
pError sub.c /^pError(
ierror sub.c /^ierror(
dopen sub.c /^dopen(
dnext sub.c /^dnext(
dclose sub.c /^dclose(
isdir sub.c /^isdir(
free_expand sub.c /^free_expand(
expand sub.c /^expand(
compare_ok sub.c /^compare_ok(
main main.c /^main(
init_vars main.c /^init_vars(
init main.c /^init(
main_exit main.c /^main_exit(
breakcheck main.c /^breakcheck(
breakreset main.c /^breakreset(
Chk_Abort main.c /^Chk_Abort(
do_sleep comm1.c /^do_sleep(
do_number comm1.c /^do_number(
do_cat comm1.c /^do_cat(
do_dir comm1.c /^do_dir(
volname comm1.c /^volname(
disp_entry comm1.c /^disp_entry(
dates comm1.c /^dates(
date comm1.c /^date(
do_quit comm1.c /^do_quit(
do_echo comm1.c /^do_echo(
do_source comm1.c /^do_source(
do_cd comm1.c /^do_cd(
attempt_cd comm1.c /^attempt_cd(
rmlast comm1.c /^rmlast(
do_mkdir comm1.c /^do_mkdir(
do_mv comm1.c /^do_mv(
rm_file comm1.c /^rm_file(
do_rm comm1.c /^do_rm(
rmdir comm1.c /^rmdir(
do_history comm1.c /^do_history(
do_mem comm1.c /^do_mem(
do_foreach comm1.c /^do_foreach(
do_forever comm1.c /^do_forever(
do_copy comm1.c /^do_copy(
copydir comm1.c /^copydir(
copyfile comm1.c /^copyfile(
do_run run.c /^do_run(
FindIt run.c /^FindIt(
exec_command execom.c /^exec_command(
isalphanum execom.c /^isalphanum(
preformat execom.c /^preformat(
fcomm execom.c /^fcomm(
exarg execom.c /^exarg(
mpush_base execom.c /^mpush_base(
mpush execom.c /^mpush(
mpop_tobase execom.c /^mpop_tobase(
format_insert_string execom.c /^format_insert_string(
find_command execom.c /^find_command(
do_help execom.c /^do_help(
initconsole rawconsole.c /^initconsole(
