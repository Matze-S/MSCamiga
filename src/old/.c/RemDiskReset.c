
/* 
**  RemDiskReset.c - waits for removing the disk in DF0: and do a reset !
**
**  Written at 02-Mar-89 21:00 by Matthias Schmidt
**   15:31 16-Aug-90  --  corrected the RESET routine
*/

#include <exec/types.h>
#include <exec/interrupts.h>
#include <exec/nodes.h>
#include <devices/trackdisk.h>
#include <exec/io.h>
#include <stdio.h>

IMPORT struct Task *FindTask();
IMPORT struct MsgPort *CreatePort();
IMPORT UBYTE AllocSignal();
IMPORT APTR CreateExtIO();
IMPORT BOOL OpenDevice();
IMPORT ULONG Wait(),DoIO();
IMPORT VOID CloseDevice(),FreeSignal();
IMPORT VOID DeleteExtIO(),DeletePort();

STATIC struct MsgPort *MsgPort;
STATIC struct IOExtTD *IOExtTD;
STATIC struct Interrupt Interrupt;
STATIC struct Task *Task;
STATIC ULONG SignalMask;

VOID Reset()
{
#asm
   xref     _AbsExecBase
   xref     _LVODisable
   xref     _LVOSuperState

   move.l   (_AbsExecBase).w,a6
   jsr      _LVODisable(a6)
   jsr      _LVOSuperState(a6)
   sub.l    a0,a0
   move.l   _Reset_Code(pc),(a0)
   jmp      (a0)

_Reset_Code:
   reset
   dc.w     $4ef9
#endasm
}

VOID RemoveInterrupt()
{
#ifdef AZTEC_C
#ifndef _LARGE_CODE
   geta4();
#endif
#endif
   Signal(Task,SignalMask);
}

main(argc,argv)
char **argv;
{
   REGISTER UBYTE Signal;

   if (!(MsgPort = CreatePort(NULL,0L)))
      puts("Can't create Reply-Port !");
   else {
      if (!(IOExtTD = (struct IOExtTD *)
            CreateExtIO(MsgPort,(ULONG)sizeof(*IOExtTD))))
         puts("Can't create IORequest !");
      else {
         if ((Signal = AllocSignal(-1L)) == -1)
            puts("Can't allocate Signal !");
         else {
            if (OpenDevice(TD_NAME,0L,IOExtTD,0L))
               puts("Can't open 'trackdisk.device' for DF0: !");
            else {
               IOExtTD->iotd_Req.io_Command = TD_CHANGESTATE;
               DoIO(IOExtTD);
               if (!IOExtTD->iotd_Req.io_Actual) {
                  puts("\nPlease remove disk in DF0: !");
                  Task = FindTask(NULL);
                  SignalMask = 1L << Signal;
                  Interrupt.is_Node.ln_Name = NULL;
                  Interrupt.is_Node.ln_Type = NT_INTERRUPT;
                  Interrupt.is_Node.ln_Pri = 0;
                  Interrupt.is_Code = RemoveInterrupt;
                  IOExtTD->iotd_Req.io_Data = (APTR)&Interrupt;
                  IOExtTD->iotd_Req.io_Command = TD_REMOVE;
                  DoIO(IOExtTD);
                  Wait(SignalMask);
               }
               Reset();
            }
            FreeSignal((ULONG)Signal);
         }
         DeleteExtIO(IOExtTD);
      }
      DeletePort(MsgPort);
   }
   return 20;
}
