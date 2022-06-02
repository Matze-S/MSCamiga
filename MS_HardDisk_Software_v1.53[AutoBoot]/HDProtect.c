/* Copyright (C) 1990 by Matthias Schmidt */


/*
 *  HDProtect
 *
 *  HardDisk Protect Utility v1.53 -- (03:29 11-Aug-90)
 */


#include "defs.h"


/*------------ prototypes ------------*/

char *btoc(long);
void cleanup(void);

/*------------ external references ------------*/

extern struct DosLibrary *DOSBase;

/*------------ static data ------------*/

static struct IOStdReq *iob = 0;
static struct MsgPort *iob_rp = 0, *sp_rp = 0;
static struct StandardPacket *sp = 0;
static int dev_open = 0;

/*------------ sub routines ------------*/

/*------ btoc() -- convert bcpl string to c string ------*/

char *btoc(long bptr)
{
   static char buf[256];
   unsigned char *ucp;

   buf[*(ucp = (unsigned char *)BADDR(bptr))] = 0;
   strncpy(buf, (char *)(ucp + 1), (size_t)*ucp);
   return buf;
}

/*------ cleanup() -- delete msgports, iobs, close device, ... ------*/

void cleanup(void)
{
   if (sp) free((char *)sp);
   if (sp_rp) DeletePort(sp_rp);
   if (dev_open) CloseDevice((struct IORequest *)iob);
   if (iob) DeleteStdIO(iob);
   if (iob_rp) DeletePort(iob_rp);
}

/*------------ main() ------------*/

void main(int argc, char **argv)
{
   static int flg_tab[][3] = {
      HDDPF_FORMATPROTECTED, HDDPF_WRITEPROTECTED, 256,
      HDDPF_FORMATPROTECTED | 256, HDDPF_WRITEPROTECTED | 256,
      HDDPF_FORMATPROTECTED | HDDPF_WRITEPROTECTED | 256
   };
   static char *opt_tab[] = { "FORMAT", "WRITE", "NONE" };
   struct FileSysStartupMsg *fssmp;
   struct DeviceNode *sdnp, *dnp = (struct DeviceNode *)&((struct DosInfo *)
         BADDR(((struct RootNode *)DOSBase->dl_Root)->rn_Info))->di_DevInfo;
   char *dev_name, *cp;
   int flg = 0, i, j;
   long unit;

   atexit(cleanup);
   printf("\nHDProtect -- HardDisk Protect Utility v1.53\n"
         "Copyright (C) 1990 by Matthias Schmidt\n\n");

   if (argc < 2 || (argv[1][0] == '?' && !argv[1][1])) {
      printf("Usage: %s <device> [NONE] | [FORMAT][WRITE]\n", argv[0]);
      exit(10);
   }

   dev_name = argv[1];
   if (argc == 2)
      flg = HDDPF_WRITEPROTECTED | HDDPF_FORMATPROTECTED;
   else {
      for (i = 2; i < argc && flg != -1; ++i) {
         for (j = 0; j < 3; ++j)
            if (!stricmp(opt_tab[j], argv[i])) {
               if (flg & flg_tab[1][j]) {
                  j = 3;
                  break;
               }
               flg |= flg_tab[0][j];
               break;
            }
         if (j == 3) {
            printf("Invalid arguments!\n");
            exit(10);
         }
      }
   }

   /* protect the drive against format access, too, if the user
      only specified to protect it against write access */
   if (flg == HDDPF_WRITEPROTECTED) flg |= HDDPF_FORMATPROTECTED;

   for (cp = dev_name; *cp && *cp != ':'; ++cp);
   *cp = 0;
   sdnp = dnp;
   while (sdnp = (struct DeviceNode *)BADDR(sdnp->dn_Next)) {
      if (sdnp->dn_Type != DLT_DEVICE) continue;
      if (!stricmp(dev_name, btoc(sdnp->dn_Name))) break;
   }
   if (!sdnp) {
      printf("Device '%s:' not found!\n", dev_name);
      exit(10);
   }
   fssmp = (struct FileSysStartupMsg *)BADDR(sdnp->dn_Startup);
   if (stricmp(HD_NAME, btoc(fssmp->fssm_Device))) {
      printf("Device '%s:' doesn't use the '" HD_NAME "'!\n", dev_name);
      exit(10);
   }
   if (iob_rp = CreatePort(0L, 0L)) {
      if (iob = CreateStdIO(iob_rp)) {
         if (!OpenDevice(HD_NAME, unit = fssmp->fssm_Unit,
               (struct IORequest *)iob, fssmp->fssm_Flags)) {
            printf("%srotecting unit %d...", flg & 256 ? "Unp" : "P",
                  (int)unit);
            fflush(stdout);
            iob->io_Command = HD_CHANGEPROT;
            iob->io_Length = flg & 256 ? 0 : flg;
            DoIO((struct IORequest *)iob);
            if (iob->io_Error)
               printf("error code #%d returned!\n", (int)iob->io_Error);
            else
               printf("ok!\n");
            if (sp_rp = CreatePort(0L, 0L)) {
               if (sp = (struct StandardPacket *)malloc(sizeof(*sp))) {
                  sp->sp_Msg.mn_Node.ln_Name = (char *)&sp->sp_Pkt;
                  sp->sp_Pkt.dp_Link = &sp->sp_Msg;
                  while (dnp = (struct DeviceNode *)BADDR(dnp->dn_Next)) {
                     if (dnp->dn_Type != DLT_DEVICE || !dnp->dn_Startup ||
                           (fssmp = (struct FileSysStartupMsg *)
                           BADDR(dnp->dn_Startup))->fssm_Unit != unit ||
                           !dnp->dn_Task || stricmp(btoc(fssmp->fssm_Device),
                           HD_NAME))
                        continue;
                     printf("Initializing '%s:'...", btoc(dnp->dn_Name));
                     fflush(stdout);
                     sp->sp_Pkt.dp_Port = sp_rp;
                     sp->sp_Pkt.dp_Type = ACTION_INHIBIT;
                     sp->sp_Pkt.dp_Arg1 = DOSTRUE;
                     PutMsg(dnp->dn_Task, (struct Message *)sp);
                     WaitPort(sp_rp);
                     GetMsg(sp_rp);
                     if (sp->sp_Pkt.dp_Res1) {
                        sp->sp_Pkt.dp_Port = sp_rp;
                        sp->sp_Pkt.dp_Type = ACTION_INHIBIT;
                        sp->sp_Pkt.dp_Arg1 = DOSFALSE;
                        PutMsg(dnp->dn_Task, (struct Message *)sp);
                        WaitPort(sp_rp);
                        GetMsg(sp_rp);
                     }
                     printf(sp->sp_Pkt.dp_Res1 ? "ok!\n" : "failed!\n");
                  }
                  exit(0);
               } else
                  printf("Not enough memory!\n");
            } else
               printf("Can't create reply port!\n");
         } else
            printf("Error #%d occured at opening " HD_NAME "\n",
                  (int)iob->io_Error);
      } else
         printf("Unable to create io block!\n");
   } else
      printf("Unable to create io reply port!\n");
   exit(20);
}

/*------------ end of source ------------*/

