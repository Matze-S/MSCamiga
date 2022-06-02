/* Copyright (C) 1990 by Matthias Schmidt */


/*
 *  HDFormat.c
 *
 *  HardDisk Low Level Format Utility v1.53 -- (03:28 11-Aug-90)
 */


#include "defs.h"


/*------------ prototypes ------------*/

long vertrks(long start, long end);          /* vertrks.asm */

void add_bad_tracks(long track);
void busy(int flag);
int chk_err(void);
void cleanup(void);
int mark_bad_track(long track);
int omtistatus(void);
void readdata(char *buf, int cnt);
void rem_bad_tracks(void);
void rw_data(int cmd, char *buf, int cnt);
void sendcmd(int cmd, int head, int sec, int cyl, int count, int ctrl);
void sort_bad_tracks(void);
void startup(int unit);
void writedata(char *buf, int cnt);

/*------------ global data ------------*/

struct IOStdReq *iob = 0;
struct HardDiskDriveParm dp;
unsigned char sense[4];

/*------------ static data ------------*/

static int dev_open = 0, dev_busy = 0;
static struct MsgPort *rp = 0;
static struct Omti *omti;
static long *bad_tracks = 0;
static int interleave, bad_track_count = 0;
static int Num_BadTracks = 0, bad_tracks_flag = 0;
static long last_track;

#define NUM_BADTRACKS 50

/*------------ sub routines ------------*/

/*------ busy() - allocate the drive for own use ------*/

static void busy(int flag)
{
   if ((flag && dev_busy) || (!flag && !dev_busy)) return;
   iob->io_Command = HD_BUSY;
   dev_busy = iob->io_Length = flag;
   DoIO((struct IORequest *)iob);
}

/*------ sendcmd() - send a command to the omti ------*/

static void sendcmd(int cmd, int hd, int sec, int cyl, int cnt, int ctrl)
{
   struct HardDiskCmd hdc;

   hdc.hdc_Command = cmd;
   hdc.hdc_Head = hd;
   hdc.hdc_Sector = sec;
   hdc.hdc_Cylinder = cyl;
   hdc.hdc_Count = cnt;
   hdc.hdc_Control = ctrl;
   busy(1);
   iob->io_Data = (APTR)&hdc;
   iob->io_Command = HD_SENDCMD;
   DoIO((struct IORequest *)iob);
}

/*------ writedata()/readdata() - send/receive data to/from the omti ------*/

static void rw_data(int cmd, char *buf, int cnt)
{
   iob->io_Command = cmd;
   iob->io_Data = (APTR)buf;
   iob->io_Length = cnt;
   DoIO((struct IORequest *)iob);
}

#define writedata(buf, cnt) rw_data((int)HD_SENDDATA, buf, cnt)
#define readdata(buf, cnt) rw_data((int)HD_GETDATA, buf, cnt)

/*------ waitomti() - wait for the omti ------*/

#define waitomti() while (!(omti->omti_Status & OMTIF_REQ))

/*------ omtistatus() - read omti status ------*/

static int omtistatus(void)
{
   iob->io_Command = HD_GETSENSE;
   DoIO((struct IORequest *)iob);
   *(long *)sense = *(long *)&iob->io_Actual;
   return iob->io_Error;
}

/*------ chk_err() - print a possible error message ------*/

static int chk_err(void)
{
   if (sense[0]) {
      printf("error codes %02x %02x %02x %02x returned!\n",
         (int)sense[0], (int)sense[1], (int)sense[2], (int)sense[3]);
      return 1;
   } else {
      if (iob->io_Error) {
         printf("error code #%u returned!\n",
               (unsigned)((unsigned char)iob->io_Error));
         return 1;
      }
      printf("ok!\n");
      return 0;
   }
}

/*------ add_bad_track() - add one track to the bad track table ------*/

static void add_bad_track(long t)
{
   int i;
   long *lp;

   if (bad_track_count == Num_BadTracks) {
      if (!(lp = (long *)malloc((size_t)(Num_BadTracks +
            (NUM_BADTRACKS * sizeof(*bad_tracks)))))) {
         printf("Not enough memory for the bad track table!\n");
         exit(20);
      }
      Num_BadTracks += NUM_BADTRACKS;
      if (bad_tracks) {
         for (i = 0; i < bad_track_count; ++i)
            lp[i] = bad_tracks[i];
         free((void *)bad_tracks);
      }
      bad_tracks = lp;
   }
   bad_tracks[bad_track_count++] = t;
}

/*------ rem_bad_tracks() - remove the bad track table ------*/

static void rem_bad_tracks(void)
{
   bad_tracks = 0;
   bad_track_count = Num_BadTracks = 0;
   free((void *)bad_tracks);
}

/*------ sort_bad_tracks() - sort the bad track table ------*/

static int _sort_bad_tracks(const long *a, const long *b)
{
   return (*a < *b ? -1 : (*a > *b ? 1 : 0));
}

#define sort_bad_tracks() qsort(bad_tracks,\
      (size_t)bad_track_count, (size_t)sizeof(*bad_tracks),\
      (int (*)(const void *, const void *))_sort_bad_tracks)

/*------ mark_bad_track() - assigning a track to a alternate one ------*/

static int mark_bad_track(long t)
{
   char buf[4];
   unsigned head, cyl, alt_head, alt_cyl;

   ++bad_tracks_flag;
   if (--last_track != t) {
      printf("Assigning the bad track cyl #%d, head #%d to cyl #%d, "
            "head #%d...", cyl = t / dp.hddp_NumHeads, head = t %
            dp.hddp_NumHeads, alt_cyl = last_track / dp.hddp_NumHeads,
            alt_head = last_track % dp.hddp_NumHeads);
      fflush(stdout);
      buf[0] = (alt_cyl >> 3) & 0x80 | alt_head;
      buf[1] = (alt_cyl >> 2) & 0xc0;
      buf[2] = alt_cyl;
      buf[3] = 0;
      sendcmd(HDCMD_ASSIGN_ALT_TRK, (cyl >> 3) & 0x80 | head,
            (cyl >> 2) & 0xc0, cyl, interleave, (int)dp.hddp_StepRate);
      waitomti();
      if (!(omti->omti_Status & OMTIF_CD)) writedata(buf, 4);
      omtistatus();
      return (chk_err());
   } else
      return 0;
}

/*------ cleanup() ------*/

static void cleanup(void)
{
   Write(Output(), "\x9b" "1 p", 4L);
   if (bad_tracks) rem_bad_tracks();
   if (dev_open) {
      busy(0);
      iob->io_Command = CMD_RESET;
      DoIO((struct IORequest *)iob);
      CloseDevice((struct IORequest *)iob);
   }
   if (iob) DeleteStdIO(iob);
   if (rp) DeletePort(rp);
}

/*------ startup() ------*/

static void startup(int unit)
{
   atexit(cleanup);
   if (rp = CreatePort(0L, 0L))
      if (iob = CreateStdIO(rp))
         if (!OpenDevice(HD_NAME, (long)unit, (struct IORequest *)iob,
               (long)(HDF_IGNORE_OPEN_ERRORS | HDF_ALLOW_EXT_CMDS))) {
            dev_open = 1;
            omti = ((struct HardDiskUnit *)iob->io_Unit)->hdu_OmtiBase;
            return;
         } else
            printf("\nUnable to open the %s -- error #%d returned!\n",
                  HD_NAME, (int)iob->io_Error);
      else
         printf("\nCan't create io block!\n");
   else
      printf("\nCan't create reply port!\n");
   exit(20);
}

/*------------ main() ------------*/

void main(int argc, char **argv)
{
   static int rd_modes[] = { 0, HDDPF_READHALF, HDDPF_READBLIND };
   char buffer[256];
   long l;
   int i;

   printf("\nHDFormat -- HardDisk Low Level Format Utility v1.53\n"
         "Copyright (C) 1990 by Matthias Schmidt\n\n");

   startup(rdrng("Unit number", 0, (int)HD_NUMUNITS - 1, 0));
   printf("\n");

   dp.hddp_NumCyls = rdrng("Number of cylinders", 1, 2048, RDRNG_NOSUGG);
   dp.hddp_NumHeads = rdrng("Number of heads", 1, 16, RDRNG_NOSUGG);
   dp.hddp_NumSecs = rdrng("Number of sectors per track", 1, 36, 17);
   dp.hddp_RedWriteCurrent = rdrng("Reduced write current cylinder", 0,
         (int)dp.hddp_NumCyls, (int)dp.hddp_NumCyls);
   dp.hddp_WritePrecomp = rdrng("Write precompensation cylinder", 0,
         (int)dp.hddp_NumCyls, (int)dp.hddp_NumCyls);
   interleave = rdrng("Sector interleave factor", 1,
         (int)dp.hddp_NumSecs - 1, 2);
   dp.hddp_StepRate = rdrng("Coded step-rate", 0, 7, 1);
   dp.hddp_ParkCyl = rdrng("Park cylinder", 0, 2048, (int)dp.hddp_NumCyls);

   if (!ask("Extended cylinder correction (ECC) ?", (char)'N'))
      dp.hddp_StepRate |= HDCTRLF_ECC;
   if (!ask("Retry verify ?", (char)'N'))
      dp.hddp_StepRate |= HDCTRLF_RETRY_VERIFY;
   dp.hddp_Flags = HDDPF_NOTWRITTEN;
   printf(" (1) -- Handshake before each read byte\n"
         " (2) -- Handshake before 16 read bytes\n"
         " (3) -- Handshake before each read sector (512 bytes)\n");
   dp.hddp_Flags |= rd_modes[rdrng("Please select read mode", 1, 3, 3) - 1];
   printf(" (1) -- Handshake before each written byte\n"
         " (2) -- Handshake before 16 written bytes\n");
   if (rdrng("Please select write mode", 1, 2, 2) == 2)
      dp.hddp_Flags |= HDDPF_WRITEHALF;

   if (ask("\nWould you like to mark any tracks on the disk as bad ?",
         (char)'N')) {
      printf("Enter '-1' and press the RETURN key when done.\n");
      do {
         while ((i = rdrng("Cylinder", -1, (int)dp.hddp_NumCyls - 1,
               RDRNG_NORANGE)) != -1) {
            l = i * dp.hddp_NumHeads + rdrng("Head", 0,
                  (int)dp.hddp_NumHeads - 1, RDRNG_NORANGE);
            sprintf(buffer, "Cylinder [%d] Head [%d] ... Is this correct ?",
                  i, (int)(l % dp.hddp_NumHeads));
            if (ask(buffer, (char)'Y')) add_bad_track(l);
         }
      } while (ask("Any more bad tracks to add ?", (char)'N'));
   }

   printf("\nContinuing will destroy any information on the entire "
         "physical drive.\n");
   if (!ask("Do you wish to proceed ?", (char)'N')) {
      printf("\nDrive not formatted!\n");
      exit(10);
   }

   printf("\nSetting drive characteristics...");
   fflush(stdout);
   iob->io_Command = HD_SETDRIVEPARMS;
   iob->io_Data = (APTR)&dp;
   DoIO((struct IORequest *)iob);
   if (chk_err()) {
      printf("Can't set drive characteristics!\n");
      exit(20);
   }

   printf("Recalibrating drive...");
   fflush(stdout);
   sendcmd(HDCMD_RECALIBRATE, 0, 0, 0, 0, (unsigned)dp.hddp_StepRate);
   omtistatus();
   if (chk_err()) {
      printf("\nCan't recalibrate the drive!\n");
      exit(10);
   }

   printf("Formatting drive...");
   fflush(stdout);
   sendcmd(HDCMD_FORMAT_DRIVE, 0, 0, 0, interleave,
         (unsigned)dp.hddp_StepRate);
   omtistatus();
   if (chk_err()) {
      printf("Can't format the drive!\n");
      exit(10);
   }

   last_track = dp.hddp_NumCyls * dp.hddp_NumHeads;
   sort_bad_tracks();
   if (bad_track_count) {
      for (i = bad_track_count - 1; i >= 0; --i)
         while (mark_bad_track(bad_tracks[i]));
      rem_bad_tracks();
   }

   l = 0;
   while (l < last_track) {
      printf("\x9b" "0 p");
      fflush(stdout);
      l = vertrks(l, last_track);
      printf("\r\x9b" "1 p");
      if (l == -1L) break;
      while (l < (last_track - 1) && mark_bad_track(l));
      if (l == (last_track - 1)) break;
   }
   busy(0);

   dp.hddp_LastCyl = (bad_tracks_flag ? last_track / dp.hddp_NumHeads :
         dp.hddp_NumCyls) - 1;
   dp.hddp_NumParts = 0;

   printf("\nWriting drive parameters...");
   fflush(stdout);
   dp.hddp_Flags &= ~HDDPF_NOTWRITTEN;
   iob->io_Command = HD_SETDRIVEPARMS;
   iob->io_Data = (APTR)&dp;
   DoIO((struct IORequest *)iob);
   if (chk_err()) {
      printf("\nCan't write drive parameters!\n");
      exit(10);
   }

   if (bad_tracks_flag)
      printf("\nAttention! The last useable cylinder is #%d.\n",
            (int)dp.hddp_LastCyl);

   printf("\nHDFormat complete.\n");
   exit(0);
}

/*------------ end of source ------------*/

