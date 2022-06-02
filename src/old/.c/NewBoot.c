/* Copyright (C) 1989/90 by Matthias Schmidt */

/*#INIT=mc
*/

/*

            ------ NewBoot -- version 1.3 -- 17-May-90 13:19 ------


      Description:
         This program removes a possible device, mounts a new one with
         the same name, assignes all system directories, loads a new
         system-configuration and execute a possible startup script file.

      Usage:
         NewBoot <devname> <drivername> <unit> <flags> <surfaces>
                 <blkspertrk> <lowcyl> <highcyl> <buffers> <bufmemtype>
                 <dostype> <filesystem> <globvec> <sysdir> <startupfile>

      Arguments:
         <devname>      name of the AmigaDOS device
         <drivername>   name of the exec device driver
         <unit>         unit number passed to the driver
         <flags>        flags passed to the driver
         <surfaces>     number of surfaces of the disk
         <blkspertrk>   number of blocks per one track
         <lowcyl>       lowest cylinder of this partition
         <highcyl>      highest cylinder of this partition
         <buffers>      number of buffers used by the filesystem
         <bufmemtype>   memory type of the buffers
         <dostype>      0x444F5300 for the old filesystem or
                        0x444F5301 for the fast filesystem
         <filesystem>   "" for using the old filesystem or
                        the name of the filesystem or handler
                        to be loaded
         <globvec>      0 for the old filesystem or
                        -1 for the fast filesystem or other
                        filesystems written in c or assembler
         <sysdir>       the path for the SYS: directory which will
                        be set after the device is mounted
         <startupfile>  a script file which will be executed when
                        all SYS: directories (C:,L:,S:,FONTS:,...)
                        are assigned.

      Example:
         NewBoot DH0: hddisk.device 1 0 4 17 3 611 30 1 0x444F5301
                 FastFileSystem -1 DH0:Workbench Startup-Sequence

*/

/* ------ included files ------ */

#include <exec/types.h>
#include <exec/ports.h>
#include <exec/memory.h>
#include <exec/tasks.h>
#include <libraries/dosextens.h>
#include <libraries/filehandler.h>
#include <libraries/expansion.h>
#include <stdio.h>

/* ------ include file support ------ */

/* additional information in the disk environment vector */
#define DE_MAXTRANSFER 13L
#define DE_MASK 14L
#define DE_BOOTPRI 15L
#define DE_DOSTYPE 16L

/* ------ external declarations for library functions ------ */

/* amiga.lib */
struct DeviceNode *MakeDosNode();
struct Library *OpenLibrary();
struct Task *FindTask();
APTR AllocMem();
BOOL AddDosNode();
BPTR CurrentDir(),LoadSeg(),Lock(),Open();
LONG DeleteFile(),Examine(),Read();
VOID Close(),CloseLibrary(),Forbid();
VOID FreeMem(),Permit(),RemTask(),SetPrefs(),UnLock();

/* aztec c library */
char toupper();
long dos_packet();
void exit(),printf(),sprintf(),strncpy();

/* ------ external symbols ------ */

extern struct DosLibrary *DOSBase;
extern int Enable_Abort;

/* ------ global symbols ------ */

/* library bases */
struct ExpansionBase *ExpansionBase = NULL;
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

/* convert ascii string to long value */
long atol(cp)
char *cp;
{
   long l = 0;
   int s = 0,h = 0;

   if (*cp == '-' || *cp == '+') {
      s = (*cp == '+') ? 0 : 1;
      ++cp;
   }
   if (cp[0] == '0' && toupper(cp[1]) == 'X') {
      h = 1;
      cp += 2;
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
   return s ? -l : l;
}

/* exit with a last message to the user and an error code */
error(rc,cp,a1,a2,a3,a4)
char *cp,*a1,*a2,*a3,*a4;
{
   if (ExpansionBase) CloseLibrary(ExpansionBase);
   if (IntuitionBase) CloseLibrary(IntuitionBase);
   if (fibp) FreeMem(fibp,(long)sizeof(*fibp));
   Permit();
   printf(cp,a1,a2,a3,a4);
   exit(rc);
}

/* ------ main code ------ */

main(argc,argv)
char **argv;
{
   static long parmPkt[21] = {
      -1,-1,-1,-1,16,128,0,2,1,11,2,0,0,0,79,30,3,
      0x7fffffff,-2,0,0x444F5300
   };
   static int indexTable[] = {
      2,3,7,9,13,14,15,16,20
   };
   static char *sys_dirs[] = {
      "S","L","C","FONTS","DEVS","LIBS","SYS"
   };
   static char expansionName[] = EXPANSIONNAME;
   static char intuitionName[] = "intuition.library";
   static char sysConfigName[] = "DEVS:system-configuration";
   struct DeviceNode *pdnp,*dnp = (struct DeviceNode *)
         &((struct DosInfo *)BADDR(((struct RootNode *)
         DOSBase->dl_Root)->rn_Info))->di_DevInfo,*mydnp = dnp;
   struct MsgPort *mpp = NULL;
   struct CommandLineInterface *clip = (struct CommandLineInterface *)
         BADDR(((struct Process *)FindTask(0L))->pr_CLI);
   struct FileInfoBlock *fibp;
   BPTR seglist = 0,lk,fh;
   LONG size;
   char *cp;
   int i;

   /* disable the CTRL-C break */
   Enable_Abort = 0;

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

   /* disable task switching */
   Forbid();

   /* try to open the expansion.library */
   if (!(ExpansionBase = (struct ExpansionBase *)
         OpenLibrary(expansionName,33L)))
      error(20,"Can't open the %s!\n",expansionName);

   /* check for the correct number of arguments */
   if (argc != 16) {
      printf("NewBoot 1.3 -- Copyright (C) 1990 by Matthias Schmidt\n");
      error(10,"Usage: %s <devname> <drivername> <unit> %s %s %s\n",
            *argv,"<flags> <surfaces> <blockspertrack> <lowcyl>",
            "<highcyl> <buffers> <bufmemtype> <dostype> <filesystem>",
            "<globvec> <sysdir> <startupfile>");
   }

   /* load filesystem */
   if (*argv[12] && !(seglist = LoadSeg(argv[12])))
      error(10,"Can't load '%s'\n",argv[12]);

   /* set parameters in the parameter packet */
   for (cp = argv[1]; *cp && *cp != ':'; ++cp);
   *cp = 0;
   for (i = 0; i < sizeof(indexTable) / sizeof(int); ++i)
      parmPkt[indexTable[i]] = atol(argv[i + 3]);
   parmPkt[0] = (long)argv[1];
   parmPkt[1] = (long)argv[2];

   /* unlock the current directory if one is current'ed */
   if (lk = CurrentDir(0L))
      UnLock(lk);

   /* search device node and remove it if it exists */
   while (dnp = (struct DeviceNode *)BADDR((pdnp = dnp)->dn_Next)) {
      if (dnp->dn_Type == DLT_DEVICE &&
            stricmp(btoc(dnp->dn_Name),argv[1]) == 0) {
         mpp = dnp->dn_Task;
         pdnp->dn_Next = dnp->dn_Next;
         break;
      }
   }

   /* free all locks in directories using this device */
   dnp = mydnp;
   while (dnp = (struct DeviceNode *)BADDR(dnp->dn_Next))
      if (dnp->dn_Type == DLT_DIRECTORY)
         for (i = 0; i < sizeof(sys_dirs) / sizeof(char *); ++i)
            if (stricmp(sys_dirs[i],btoc(dnp->dn_Name)) == 0 &&
                  dnp->dn_Lock) {
               UnLock(dnp->dn_Lock);
               dnp->dn_Lock = 0L;
               break;
            }

   /* try to inhibit the device and hope that the
    * disk is no more in use, so the volume node is
    * removed after inhibiting the device */
   if (mpp && !dos_packet(mpp,ACTION_INHIBIT,DOSTRUE))
      error(10,"Can't inhibit the device!\n");

   /* get back the device node pointer */
   pdnp = dnp = mydnp;

   /* initialize the new device process */
   if (!(mydnp = MakeDosNode(parmPkt)))
      error(20,"Can't create dos node!\n");
   mydnp->dn_SegList = seglist;
   mydnp->dn_GlobalVec = atol(argv[13]);
   if (!AddDosNode(0L,ADNF_STARTPROC,mydnp))
      error(20,"Unable to add dos node!\n");

   /* set current directory */
   if (!*argv[14] || !(lk = Lock(argv[14],ACCESS_READ))) {
      sprintf(strbuf,"%s:",argv[1]);
      if (!(lk = Lock(strbuf,ACCESS_READ)))
         error(10,"Unable to get lock for '%s'!\n",strbuf);
   }
   CurrentDir(lk);

   /* set all locks of the directories to the new device */
   while (dnp = (struct DeviceNode *)BADDR(dnp->dn_Next))
      if (dnp->dn_Type == DLT_DIRECTORY && !dnp->dn_Lock)
         dnp->dn_Lock = Lock(stricmp(btoc(dnp->dn_Name),"SYS") ?
               strbuf : "",ACCESS_READ);

   /* execute a possible startup script file */
   if (*argv[15]) {
      if (!(fh = Open(argv[15],MODE_OLDFILE))) {
         for (cp = argv[15]; *cp; ++cp)
            if (*cp == ':' || *cp == '/') break;
         sprintf(strbuf,"S:%s",argv[15]);
         if (*cp || !(fh = Open(strbuf,MODE_OLDFILE)))
            error(10,"Can't open script file '%s'!\n",argv[15]);
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

