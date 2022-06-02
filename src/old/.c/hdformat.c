/* Copyright (C) 1989 by Matthias Schmidt */

/*
 *    OMTI HardDisk Formatter 1.00
 */

/* max # of bad tracks on the disk */
#define MAX_BAD_TRACKS 256

#include <stdio.h>

fetchvalue(vorgabe)
{
   int i = -1, v, s = 0;
   char buf[6];

   while (++i < 5 && ((v = getchar()) != -1 && (buf[i] = v) != '\n'));
   if (i == 5) {
      while (getchar() != '\n');
      printf("Input line is too long.  Please try again.\n");
      return -32768;
   }
   if (!i) return vorgabe;
   buf[i] = 0;
   s = i = buf[0] == '-' ? 1 : 0;
   for (v = 0; buf[i]; ++i) {
      if (buf[i] < '0' || buf[i] > '9') return -32768;
      v = v * 10 + buf[i] - '0';
   }
   return s ? -v : v;
}

getvalue(v, min, max)
{
   int dummy;

   if ((dummy = fetchvalue(v)) != -32768 && (dummy < min || dummy > max)) {
      printf("Value (=%d) is out of range (min=%d, max=%d).  %s",
            dummy, min, max, "Please try again.\n");
      return -32768;
   }
   return dummy;
}

entervalue(s,v,min,max)
char *s;
{
   int ret_val;

   do {
      printf("%s (%d-%d) [%d]: ", s, min, max, v);
   } while ((ret_val = getvalue(v, min, max)) == -32768);
   return ret_val;
}

ask(s,v)
char *s,v;
{
   int dummy;

   for (;;) {
      printf("%s [Y/N] : %c\010", s, v);
      if ((dummy = getchar()) == '\n' || dummy == -1) break;
      if ((dummy = toupper(dummy)) == 'Y' || dummy == 'N') {
         v = dummy;
         if ((dummy = getchar()) == '\n' || dummy == -1) break;
      }
      while ((dummy = getchar()) != '\n' && dummy != -1);
   }
   return v == 'Y' ? 1 : 0;
}

struct drive_def {
   char *name;
   int numcyls, wrprecomp, redwrcur, parkcyl;
   char numheads, numsecs;
   unsigned char steprate;
   char interleave;
} defs[] = {
   "Seagate ST-412", 306, 128, 306, 320, 4, 17, 1, 1
};

struct bad_track {
   int cyl, head;
} badtrks[MAX_BAD_TRACKS];

main(argc,argv)
char **argv;
{
   char buf[256];
   int i, autopark_time;
   static struct drive_def drive = {
      0, -32768, -32767, -32768, -32768, 4, 17, 1, 1
   };

   printf("\nOMTI HardDisk Formatter Version 1.00\n");
   printf("Copyright (C) 1989 by Matthias Schmidt\n");

   do {
      printf("\n  0) User defined\n");
      for (i = 0; i < sizeof(defs) / sizeof(struct drive_def); ++i) {
         printf("  %d) %-20s (%d cylinders, %d heads, %d sectors - %s)\n",
               i + 1, defs[i].name, defs[i].numcyls, defs[i].numheads,
               defs[i].numsecs, defs[i].numsecs == 17 ? "MFM" : "RLL");
      }
      printf("Select drive type [0]: ");
   } while ((i = getvalue(0, 0, i)) < 0);
   if (i) {
      drive = defs[--i];
   } else {
      printf("\n");
      drive.numheads = entervalue("Number of heads", 4, 1, 32);
      do {
         printf("Number of cylinders (1-2048) : ");
      } while ((drive.numcyls = getvalue(drive.numcyls, 1, 2048)) == -32768);
      do {
         printf("Number of sectors per track (17/26) [17]: ");
      } while ((drive.numsecs = fetchvalue(drive.numsecs)) &&
            drive.numsecs != 17 && drive.numsecs != 26);
      drive.wrprecomp = entervalue("Write pre-comp cylinder",
            drive.numcyls - 1, 0, drive.numcyls - 1);
      drive.redwrcur = entervalue("Reduced write current cylinder",
            drive.numcyls - 1, 0, drive.numcyls - 1);
      drive.interleave = entervalue("Interleave factor", 1, 0, 7);
      drive.steprate = entervalue("Coded step-rate", 1, 0, 7);
   }
   do {
      printf("\nAfter how many seconds of inactivity do you want to ");
      printf("park the heads\nautomatically ? (Enter '-1 for no ");
      printf("auto parking) (-1-1000) [-1] : ");
   } while ((autopark_time = getvalue(-1, -1, 1000)) < -1);
   if (ask("\nWould you like to mark any blocks on the disk as bad ?", 'N')) {
      printf("Press the RETURN key when done.\n");
      i = 0;
      do {
         for (; i < MAX_BAD_TRACKS - 1; ++i) {
            do {
               printf("Cylinder : ");
            } while ((badtrks[i].cyl =
                  getvalue(-32767, 0, drive.numcyls - 1)) < 0);
            do {
               printf("Head : ");
            } while ((badtrks[i].head =
                  getvalue(-32768, 0, drive.numheads - 1)) == -32768);
            sprintf(buf,"Cylinder [%d] Head [%d] ... Is this correct ?",
                  badtrks[i].cyl, badtrks[i].head);
            if (!ask(buf, 'Y')) --i;
         }
         if (i == MAX_BAD_TRACKS - 1) {
            printf("\nThe bad track table is full!\n");
            break;
         }
      } while (ask("Any more bad blocks to add ?", 'N'));
      badtrks[i].cyl = badtrks[i].head = -1;
   }
   printf("\nContinuing will destroy any information on %s\n",
         "the entire physical device.");
   if (!ask("Do you wish to proceed ?", 'N')) return 0;
}

