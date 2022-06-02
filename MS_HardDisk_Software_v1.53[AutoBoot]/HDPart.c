/* Copyright (C) 1990 by Matthias Schmidt */


/*
 *  HDPart.c
 *
 *  HardDisk Partition Utility v1.53 -- (03:30 11-Aug-90)
 */


#include "defs.h"


/*------------ prototypes ------------*/

int search_part(char *name);
int read_parts(void);
int write_parts(void);
void cleanup(void);
void startup(void);

/*------------ static data ------------*/

static struct parmpkt {
   struct HardDiskDriveParm dp;
   struct HardDiskPart p[HDDP_MAXNUMPARTS];
} pp[HD_NUMUNITS];
static int units[HD_NUMUNITS], num_parts = 0;
static struct IOStdReq *iob = 0;
static struct MsgPort *rp = 0;
static int dev_open = 0;

/*------------ sub routines ------------*/

/*------ search_part() -- search a specified partition ------*/

int search_part(char *name)
{
   int i, j;

   for (i = 0; i < HD_NUMUNITS; ++i)
      if (units[i])
         for (j = 0; j < pp[i].dp.hddp_NumParts; ++j)
            if (stricmp(pp[i].p[j].hdp_Name, name) == 0)
               return i * HDDP_MAXNUMPARTS + j;
   return -1;
}

/*------ write_parts() -- write the partition tables from all units ------*/

static int write_parts(void)
{
   int i, rc = 0, err;

   for (i = 0; i < HD_NUMUNITS; ++i)
      if (units[i]) {
         printf("\rWriting the partition table from unit %d...", i);
         fflush(stdout);
         if (!(err = OpenDevice(HD_NAME, (long)i, (struct IORequest *)iob,
               (long)HDF_ALLOW_EXT_CMDS))) {
            dev_open = 1;
            pp[i].dp.hddp_Flags = pp[i].dp.hddp_Flags & ~HDDPF_NOTWRITTEN |
                  HDDPF_WRITEPARTS;
            iob->io_Data = (APTR)&pp[i].dp;
            iob->io_Command = HD_SETDRIVEPARMS;
            err = DoIO((struct IORequest *)iob);
            CloseDevice((struct IORequest *)iob);
            dev_open = 0;
         }
         if (err) {
            printf("error code #%d returned!\n", err);
            rc = 10;
         } else
            printf("ok!");
      }
   printf("\r\x9b" "K1\r");
   if (!rc) printf("Writing the partition tables...ok!\n");
   return rc;
}

/*------ read_parts() -- read the partition tables from all units ------*/

static int read_parts(void)
{
   struct HardDiskUnit *hdu;
   int i, num_drives = 0;

   for (i = 0; i < HD_NUMUNITS; ++i) {
      units[i] = 0;
      if (OpenDevice(HD_NAME, (long)i, (struct IORequest *)iob,
            (long)HDF_ALLOW_EXT_CMDS)) continue;
      dev_open = 1;
      printf("Reading partition table from unit #%d...", i);
      fflush(stdout);
      hdu = (struct HardDiskUnit *)iob->io_Unit;
      pp[i].dp = hdu->hdu_DriveParms;
      iob->io_Data = (APTR)pp[i].p;
      iob->io_Command = HD_READPARTS;
      if (DoIO((struct IORequest *)iob))
         printf("error #%d returned!\n", (int)iob->io_Error);
      else {
         printf("ok!\r");
         ++num_drives;
         units[i] = 1;
         num_parts += pp[i].dp.hddp_NumParts;
      }
      CloseDevice((struct IORequest *)iob);
      dev_open = 0;
   }
   return num_drives;
}

/*------ cleanup() ------*/

static void cleanup(void)
{
   if (dev_open) CloseDevice((struct IORequest *)iob);
   if (iob) DeleteStdIO(iob);
   if (rp) DeletePort(rp);
}

/*------ startup() ------*/

static void startup(void)
{
   atexit(cleanup);
   if (rp = CreatePort(0L, 0L))
      if (iob = CreateStdIO(rp))
         return;
      else
         printf("Unable to create io block!\n");
   else
      printf("Unable to create reply port!\n");
   exit(20);
}

/*------------ main() ------------*/

void main(int argc, char **argv)
{
   static char startmsg[] = "\f\nHDPart -- HardDisk Partition Utility v1.53"
         "\nCopyright (C) 1990 by Matthias Schmidt\n\n";
   struct HardDiskDriveParm *dp;
   struct HardDiskPart *p;
   char buf[5], dhx, *cp;
   int i, j;

   startup();
   printf(&startmsg[1]);
   if (!read_parts()) {
      printf("Can't find any low level formatted drives!\n");
      exit(10);
   }

   do {
      printf(startmsg);
      dhx = '0';
      if (!num_parts)
         printf("There are no defined partitions.\n");
      else {
         printf("Name Unit Heads Secs LowCyl HighCyl Bufs BootPri "
               "FFS Size\n");
         for (i = 0; i < HD_NUMUNITS; ++i)
            for (j = 0; j < (dp = &pp[i].dp)->hddp_NumParts; ++j) {
               sprintf(buf, "%s:", cp = ((p = &pp[i].p[j])->hdp_Name));
               printf("%-4s%4d%6d%5d%7d%8d%5d%7d    %c  %3dM\n", buf, i,
                     (int)dp->hddp_NumHeads, (int)dp->hddp_NumSecs,
                     (int)p->hdp_LowCyl, (int)p->hdp_HighCyl,
                     (int)p->hdp_Buffers, (int)p->hdp_BootPri,
                     (char)(p->hdp_Flags & HDPF_USE_FFS ? 'Y' : 'N'),
                     (int)((((long)(p-> hdp_HighCyl - p->hdp_LowCyl + 1)) *
                     ((long)dp->hddp_NumHeads) *
                     ((long)dp->hddp_NumSecs) + 1024L) /
                     (1024L / HD_SECTOR * 1024L)));
               if (strlen(cp) == 3 && toupper(*cp) == 'D' &&
                     toupper(*++cp) == 'H' && *++cp >= '0' &&
                     *cp <= '9' && *cp == dhx) ++dhx;
            }
      }

      printf("\n (1) -- Add a new partition\n");
      printf(" (2) -- Delete a partition\n");
      printf(" (3) -- Show drive parameters\n");
      printf(" (4) -- Quit to AmigaDOS\n\n");

      i = rdrng("Please select", 1, 4, 1);
      printf("\n");

      switch (i) {
         case 1:
            while (!units[i = rdrng("Unit number", 0, HD_NUMUNITS - 1, 0)])
               printf("Unable to access unit #%d!\n", i);
            if ((j = (dp = &pp[i].dp)->hddp_NumParts) >= HDDP_MAXNUMPARTS) {
               printf("Too many partitions!\n");
               break;
            }
            p = &pp[i].p[dp->hddp_NumParts];
            buf[0] = 'D';
            buf[1] = 'H';
            buf[2] = dhx <= '9' ? dhx : dhx - ('0' + 'A');
            buf[3] = ':';
            buf[4] = 0;
            do {
               while ((j = strlen(cp = rdtxt("Name of the partition",
                     buf))) > 4 || (j == 4 && cp[3] != ':'));
               for (j = 0; j < 3 && *cp && *cp != ':'; ++j)
                  p->hdp_Name[j] = *cp++;
               p->hdp_Name[j] = 0;
               if ((j = search_part(p->hdp_Name)) != -1)
                  printf("Name already used by another partition!\n");
            } while (j != -1);
            do {
               j = rdrng("Starting cylinder #", 0,
                     (int)dp->hddp_LastCyl, 0);
            } while (0);
            p->hdp_LowCyl = j;
            do {
               j = rdrng("Ending cylinder #", 0,
                     (int)dp->hddp_LastCyl, (int)dp->hddp_LastCyl);
            } while (0);
            p->hdp_HighCyl = j;
            p->hdp_Buffers = rdrng("Number of AmigaDOS buffers", 0, 255, 30);
            p->hdp_BootPri = rdrng("Boot priority", -128, 127, 0);
            p->hdp_Flags = ask("Do you want to use the FastFileSystem",
                  (char)'Y') ? HDPF_USE_FFS : 0;
            ++dp->hddp_NumParts;
            ++num_parts;
            break;
         case 2:
            while ((j = strlen(cp = rdtxt("Name of the partition",
                  "Press RETURN for main menu"))) == 4 && cp[3] != ':');
            if (j > 4) break;
            for (j = 0; j < 3 && *cp && *cp != ':'; ++j) buf[j] = *cp++;
            buf[j] = 0;
            if ((i = search_part(buf)) == -1)
               printf("\nUnable to find this partition!\n");
            else {
               j = i % HDDP_MAXNUMPARTS;
               i /= HDDP_MAXNUMPARTS;
               printf("Partition '%s' deleted!\n", pp[i].p[j].hdp_Name);
               dp = &pp[i].dp;
               while (++j < dp->hddp_NumParts)
                  pp[i].p[j - 1] = pp[i].p[j];
               --dp->hddp_NumParts;
               --num_parts;
            }
            break;
         case 3:
            while (!units[i = rdrng("Unit number", 0, HD_NUMUNITS - 1, 0)])
               printf("Unable to access unit #%d!\n", i);
            dp = &pp[i].dp;
            printf("\nNumber of cylinders: %d\nReduced write current: %d\n"
                  "Write precompensation: %d\nPark cylinder: %d\n"
                  "Number of heads: %d\nNumber of sectors per track: %d\n"
                  "Step-rate: %d\nExtended cylinder correction ? %c\n"
                  "Retry verify ? %c\nWrite protected ? %c\n"
                  "Format protected ? %c\nRead mode: %s\nWrite mode: %s\n"
                  "Last useable cylinder: %d\nNumber of partitions: %d\n",
                  (int)dp->hddp_NumCyls, (int)dp->hddp_RedWriteCurrent,
                  (int)dp->hddp_WritePrecomp, (int)dp->hddp_ParkCyl,
                  (int)dp->hddp_NumHeads, (int)dp->hddp_NumSecs,
                  (int)dp->hddp_StepRate & 7, (char)(dp->hddp_StepRate &
                  HDCTRLF_ECC ? 'N' : 'Y'), (char)(dp->hddp_StepRate &
                  HDCTRLF_RETRY_VERIFY ? 'N' : 'Y'), (char)(dp->hddp_Flags &
                  HDDPF_WRITEPROTECTED ? 'Y' : 'N'), (char)(dp->hddp_Flags &
                  HDDPF_FORMATPROTECTED ? 'Y' : 'N'), dp->hddp_Flags &
                  HDDPF_READBLIND ? "512 bytes without handshake" :
                  (dp->hddp_Flags & HDDPF_READHALF ?
                  "16 bytes without handshake" : "Handshake after each "
                  "byte"), dp->hddp_Flags & HDDPF_WRITEHALF ? "16 bytes "
                  "without handshake" : "Handshake after each byte",
                  (int)dp->hddp_LastCyl, (int)dp->hddp_NumParts);
            rdtxt("\n\x08", "Press RETURN to continue");
            break;
      }
   } while (i != 4);
   exit(write_parts());
}

/*------------ end of source ------------*/

