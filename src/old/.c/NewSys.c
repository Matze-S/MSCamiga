/* Copyright (C) 1989/90 by Matthias Schmidt */

/*#INIT=mc
*/

/*

         ------ NewSys -- version 1.4 -- 14-May-90 15:10 ------


      Description:
         This program assignes all system directories to a new path,
         loads a new system-configuration and executes a script file.

      Usage:
         NewSys <sysdir> <startupfile>

      Arguments:
         <sysdir>       the path for the SYS: directory
         <startupfile>  a script file which will be executed

      Example:
         NewSys dh0:workbench startup-sequence

*/

/* ------ included files ------ */

#include <exec/types.h>
#include <exec/ports.h>
#include <exec/memory.h>
#include <exec/tasks.h>
#include <libraries/dosextens.h>
#include <libraries/filehandler.h>
#include <stdio.h>

/* ------ external declarations for library functions ------ */

/* amiga.lib */
struct Library *OpenLibrary();
struct Task *FindTask();
APTR AllocMem();
BPTR CurrentDir(),Lock(),Open();
LONG DeleteFile(),Examine(),Read();
VOID Close(),CloseLibrary(),Forbid();
VOID FreeMem(),Permit(),RemTask(),SetPrefs(),UnLock();

/* aztec c library */
char toupper();
void exit(),printf(),sprintf(),strncpy();

/* ------ external symbols ------ */

extern struct DosLibrary *DOSBase;
extern int Enable_Abort;

/* ------ global symbols ------ */

/* library bases */
struct IntuitionBase *IntuitionBase = NULL;

/* ------ static data ------ */

static char strbuf[256];
static struct FileInfoBlock *fibp = NULL;

/* ------ library support ------ */

/* compare two strings, case insensitive */
stricmp(s1,s2)
register char *s1,*s2;
{
   register char c1,c2;

   do {
      if ((c1 = toupper(*s1++)) < (c2 = toupper(*s2++))) return -1;
      else if (c1 > c2) return 1;
   } while (c1);
   return 0;
}

/* ------ sub-routines ------ */

/* convert bstr to cstr */
char *btoc(bp)
long bp;
{
   register char *cp;

   strbuf[*(cp = (char *)BADDR(bp))] = 0;
   strncpy(strbuf,cp,(int)*cp++);
   return strbuf;
}

/* exit with a last error message */
error(rc,cp,a)
char *cp,*a;
{
   if (IntuitionBase) CloseLibrary(IntuitionBase);
   if (fibp) FreeMem(fibp,(long)sizeof(*fibp));
   Permit();
   printf(cp,a);
   exit(rc);
}

/* ------ main code ------ */

main(argc,argv)
char **argv;
{
   static char *sys_dirs[] = {
      "S","L","C","FONTS","DEVS","LIBS","SYS"
   };
   static char intuitionName[] = "intuition.library";
   static char sysConfigName[] = "DEVS:system-configuration";
   struct DeviceNode *dnp = (struct DeviceNode *)
         &((struct DosInfo *)BADDR(((struct RootNode *)
         DOSBase->dl_Root)->rn_Info))->di_DevInfo;
   struct CommandLineInterface *clip = (struct CommandLineInterface *)
         BADDR(((struct Process *)FindTask(0L))->pr_CLI);
   struct FileInfoBlock *fibp;
   BPTR lk,fh;
   LONG size;
   char *cp;
   int i;

   /* disable the CTRL-C break */
   Enable_Abort = 0;

   /* disable task switching */
   Forbid();

   /* close a possible script file (e.g. SYS:S/Startup-Sequence) */
   if (clip->cli_CurrentInput != clip->cli_StandardInput) {
      Close(clip->cli_CurrentInput);
      clip->cli_CurrentInput = clip->cli_StandardInput;
      if (*(cp = (char *)BADDR(clip->cli_CommandFile))) {
         DeleteFile(btoc(clip->cli_CommandFile));
         *cp = 0;
      }
      clip->cli_Interactive = DOSTRUE;
   }

   /* check for the correct number of arguments */
   if (argc != 3) {
      printf("NewSys 1.4 -- Copyright (C) 1990 by Matthias Schmidt\n");
      error(10,"Usage: %s <sysdir> <startupfile>\n",*argv);
   }

   /* unlock the current directory if one is current'ed */
   if (lk = CurrentDir(0L)) UnLock(lk);

   /* set current directory */
   if (!*argv[1] || !(lk = Lock(argv[1],ACCESS_READ)))
      error(10,"Unable to get lock for '%s'!\n",argv[1]);
   CurrentDir(lk);

   /* set the locks in the system directories */
   while (dnp = (struct DeviceNode *)BADDR(dnp->dn_Next))
      if (dnp->dn_Type == DLT_DIRECTORY)
         for (i = 0; i < sizeof(sys_dirs) / sizeof(char *); ++i)
            if (!stricmp(sys_dirs[i],btoc(dnp->dn_Name))) {
               UnLock(dnp->dn_Lock);
               dnp->dn_Lock = Lock(stricmp(strbuf,"SYS") ?
                     strbuf : argv[1],ACCESS_READ);
               break;
            }

   /* execute a possible startup script file */
   if (*argv[2]) {
      if (!(fh = Open(argv[2],MODE_OLDFILE))) {
         for (cp = argv[2]; *cp; ++cp)
            if (*cp == ':' || *cp == '/') break;
         sprintf(strbuf,"S:%s",argv[2]);
         if (*cp || !(fh = Open(strbuf,MODE_OLDFILE)))
            error(10,"Can't open script file '%s'!\n",argv[2]);
      }
      clip->cli_CurrentInput = fh;
      clip->cli_Interactive = DOSFALSE;
   }

   /* attempt to open the intuition.library */
   if (!(IntuitionBase = (struct IntuitionBase *)
         OpenLibrary(intuitionName,0L)))
      error(20,"Can't open the %s!\n",intuitionName);

   /* allocate memory for the FileInfoBlock */
   if (!(fibp = (struct FileInfoBlock *)
         AllocMem((long)sizeof(*fibp),MEMF_PUBLIC)))
      error(20,"Not enough memory (less than %d bytes) !\n",
            sizeof(*fibp));

   /* lock in devs: for the system-configuration, get the size
    * of the file, load it and set the preferences */
   if (lk = Lock(sysConfigName,ACCESS_READ)) {
      i = Examine(lk,fibp);
      UnLock(lk);
      if (i) {
         if (!(cp = (char *)AllocMem(size = fibp->fib_Size,MEMF_PUBLIC)))
               error(20,"Not enough heap-space!\n");
         if (fh = Open(sysConfigName,MODE_OLDFILE)) {
            i = Read(fh,cp,size) - size;
            Close(fh);
            if (!i) SetPrefs(cp,size,TRUE);
         }
         FreeMem(cp,size);
      }
   }

   /* exit with no error */
   error(0,"");
}

