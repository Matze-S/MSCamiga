/* Copyright (C) 1990 by Matthias Schmidt */

/*
 *  test.c
 */


#include "defs.h"


struct {
   struct HardDiskDriveParm dp;
   struct HardDiskPart p;
} pp = {
   HDDP_DOSID, HDDP_CHECKSUM, 615, 615, 615, 614, 6, 26, HDCTRLF_ECC |
   HDCTRLF_RETRY_VERIFY | 1, HDDPF_FORMATPROTECTED | HDDPF_WRITEHALF |
   HDDPF_READBLIND | HDDPF_WRITEPARTS, 614, 1,
   0, 614, 30, 1, HDPF_USE_FFS, "DH0"
};
struct IOStdReq *iob;
struct MsgPort *rp;

void main(int argc, char **argv)
{
   rp = CreatePort(0L, 0L);
   iob = CreateStdIO(rp);
   if (OpenDevice(HD_NAME, 0L, (struct IORequest *)iob,
         (long)(HDF_IGNORE_OPEN_ERRORS | HDF_ALLOW_EXT_CMDS))) {
      printf("Can't open the %s!\n", HD_NAME);
      exit(20);
   }
   iob->io_Command = HD_SETDRIVEPARMS;
   iob->io_Data = (APTR)&pp.dp;
   DoIO((struct IORequest *)iob);
   iob->io_Command = CMD_RESET;
   DoIO((struct IORequest *)iob);
   CloseDevice((struct IORequest *)iob);
   DeleteStdIO(iob);
   DeletePort(rp);
   exit(0);
}

