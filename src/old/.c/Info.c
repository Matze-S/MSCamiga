
#ifndef AZTEC_C

                                 Give up !

#else

/* Includes... */

#include <exec/types.h>
#include <libraries/dos.h>
#include <libraries/dosextens.h>
#include <libraries/filehandler.h>

/* External function declarations... */

extern char *malloc();
extern void free(),printf(),strncpy(),strcpy();
extern long dos_packet();                    /* Only for Aztec-Users */
extern int strcmp();

/* Global variables... */

GLOBAL struct DosLibrary *DOSBase;

/* Library-Support... */

stricmp(sa,sb)
register char *sa,*sb;
{
   register char ca,cb;

   while ((ca = toupper(*sa++)) == (cb = toupper(*sb++)))
      if (!ca) return 0;
   return ca < cb ? -1 : 1;
}

/* Main program... */

main(argc,argv)
char **argv;
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

   if (--argc && (i = strlen(argv[argc])) && argv[argc][--i] == '?') {
      printf("Usage: %s [DEVICE]\n",*argv);
      return RETURN_OK;
   }
   if (argc > 2 || (argc == 2 && stricmp(argv[1],"DEVICE"))) {
      printf("Bad arguments\n");
      return RETURN_FAIL;
   }
   if (sdp = (argc ? argv[argc] : NULL)) {
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
                  b[*(cp = (char *)BADDR(((struct DeviceList *)BADDR
                        (idp->id_VolumeNode))->dl_Name))] = '\0';
                  strncpy(b,cp + 1,(int)*cp);
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

#endif
