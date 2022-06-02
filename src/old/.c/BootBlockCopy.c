/* Copyright (C) 1989 by Matthias Schmidt */

/* #INIT=mc; ;-> EDwork: turn on C-Source-Mode */

#include <devices/bootblock.h>
#include <devices/trackdisk.h>
#include <exec/io.h>
#include <exec/memory.h>
#include <exec/ports.h>
#include <exec/types.h>
#include <libraries/dosextens.h>
#include <stdio.h>

extern BOOL OpenDevice();
extern APTR AllocMem();
extern struct MsgPort *CreatePort(),*DeviceProc();
extern struct IOStdReq *CreateStdIO();
extern VOID CloseDevice(),DeletePort(),DeleteStdIO(),DoIO(),FreeMem();

main(argc,argv)
char **argv;
{
   int rc = 20;
   struct MsgPort *mpp,*rpp;
   struct IOStdReq *iob;
   struct BootBlock *bbp;

   printf("BootBlockCopy V1.0 -- Copyright (C) 1989 by Matthias Schmidt\n");
   if (mpp = DeviceProc("DF0:"))
      dos_packet(mpp,ACTION_INHIBIT,DOSTRUE);
   if (rpp = CreatePort(NULL,NULL)) {
      if (iob = CreateStdIO(rpp)) {
         if (!OpenDevice(TD_NAME,0L,iob,0L)) {
            if (bbp = (struct BootBlock *)
                     AllocMem(BOOTSECTS * TD_SECTOR,MEMF_CHIP)) {
               printf("\nInsert source disk in DF0: and press RETURN.");
               getchar();
               printf("Reading boot block ...\n");
               iob->io_Command = CMD_READ;
               iob->io_Length = BOOTSECTS * TD_SECTOR;
               iob->io_Data = (APTR)bbp;
               iob->io_Offset = 0L;
               DoIO(iob);
               if (!iob->io_Error) {
                  printf("\nInsert target disk in DF0: and press RETURN.");
                  getchar();
                  printf("Writing boot block ...\n");
                  iob->io_Command = CMD_WRITE;
                  iob->io_Length = BOOTSECTS * TD_SECTOR;
                  iob->io_Data = (APTR)bbp;
                  iob->io_Offset = 0L;
                  DoIO(iob);
                  if (!iob->io_Error) {
                     iob->io_Command = CMD_UPDATE;
                     DoIO(iob);
                     if (!iob->io_Error) {
                        printf("\nAll done!\n");
                        rc = 0;
                     }
                  }
               }
               if (iob->io_Error)
                  printf("Error #%d returned!\n",(int)iob->io_Error);
               FreeMem(bbp,BOOTSECTS * TD_SECTOR);
            } else
               printf("Not enough memory for boot block!\n");
            CloseDevice(iob);
         } else
            printf("Can't open '%S' for unit 0!\n",TD_NAME);
         DeleteStdIO(iob);
      } else
         printf("Can't create io request!\n");
      DeletePort(rpp);
   } else
      printf("Unable to create reply port!\n");
   if (mpp)
      dos_packet(mpp,ACTION_INHIBIT,DOSFALSE);
   return rc;
}

