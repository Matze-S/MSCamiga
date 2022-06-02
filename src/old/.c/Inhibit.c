
/****************************************************
 *                                                  *
 *  Inhibit.c - Version 1.0                         *
 *                                                  *
 *  Written at 06-May-89 19:30 by Matthias Schmidt  *
 *                                                  *
 ****************************************************/

#include <exec/types.h>
#include <libraries/dosextens.h>
#include <ctype.h>
#include <stdio.h>

stricmp(cp1,cp2)
register char *cp1,*cp2;
{
   register char c1,c2;

   do {
      if ((c1 = toupper(*cp1++)) < (c2 = toupper(*cp2++))) return -1;
      else if (c1 > c2) return 1;
   } while (c1);
   return 0;
}

main(argc,argv)
char **argv;
{
   int rc = 20;
   struct MsgPort *mpp,*DeviceProc();
   long dos_packet();

   if ((argc == 2 && stricmp(argv[1],"?")) || (argc == 3 &&
            stricmp(argv[1],"DEVICE") == 0)) {
      if (dos_packet(mpp = DeviceProc(argv[--argc]),ACTION_INHIBIT,TRUE))
         printf("Device '%s' successfull inhibited.\n",argv[argc]);
      else
         printf("Can't inhibit device '%s' !\n",argv[argc]);
      rc = 0;
   } else
      printf("Usage: %s [DEVICE] <device>\n",*argv);
   return rc;
}

