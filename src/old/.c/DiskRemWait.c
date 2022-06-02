
/* 
**  DiskRemWait.c - waits for removing the disk in a given unit
**
**  Written at 02-Mar-89 19:30 by Matthias Schmidt
*/

#include <exec/types.h>
#include <exec/nodes.h>
#include <exec/interrupts.h>
#include <devices/trackdisk.h>
#include <stdio.h>

IMPORT struct Task *FindTask();
IMPORT struct MsgPort *CreatePort();
IMPORT UBYTE AllocSignal();
IMPORT APTR CreateExtIO();
IMPORT BOOL OpenDevice();
IMPORT ULONG Wait(),DoIO();
IMPORT VOID CloseDevice(),FreeSignal(),Forbid(),Permit();
IMPORT VOID DeleteExtIO(),DeletePort();

STATIC struct MsgPort *MsgPort;
STATIC struct IOExtTD *IOExtTD;
STATIC struct Interrupt Interrupt;
STATIC struct Task *Task;
STATIC ULONG SignalMask;

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
   UBYTE Unit,Signal;
   int rc = 20;

   if (argc != 2 || argv[1][1] || (Unit = (UBYTE)argv[1][0]-'0') > 3) {
      fwrite("Usage: ",sizeof(char),7,stdout);
      fwrite(argv[0],sizeof(char),strlen(argv[0]),stdout);
      puts(" <Unit>");
   } else {
      if (!(MsgPort = CreatePort(NULL,0L)))
         puts("Cannot create Device-Port !");
      else {
         if (!(IOExtTD = (struct IOExtTD *)
               CreateExtIO(MsgPort,(ULONG)sizeof(*IOExtTD))))
            puts("Cannot create IORequest !");
         else {
            if ((Signal = AllocSignal(-1L)) == -1)
               puts("Cannot allocate Signal !");
            else {
               if (OpenDevice(TD_NAME,(ULONG)Unit,IOExtTD,0L))
                  puts("Cannot open 'trackdisk.device' with given unit !");
               else {
                  Task = FindTask(NULL);
                  SignalMask = 1L<<Signal;
                  Interrupt.is_Node.ln_Name = NULL;
                  Interrupt.is_Node.ln_Type = NT_INTERRUPT;
                  Interrupt.is_Node.ln_Pri = 0;
                  Interrupt.is_Code = RemoveInterrupt;
                  IOExtTD->iotd_Req.io_Data = (APTR)&Interrupt;
                  IOExtTD->iotd_Req.io_Command = TD_REMOVE;
                  DoIO(IOExtTD);
                  Wait(SignalMask);
                  Forbid();
                  IOExtTD->iotd_Req.io_Data = NULL;
                  IOExtTD->iotd_Req.io_Command = TD_REMOVE;
                  DoIO(IOExtTD);
                  Permit();
                  rc = 0;
                  CloseDevice(IOExtTD);
               }
               FreeSignal((ULONG)Signal);
            }
            DeleteExtIO(IOExtTD);
         }
         DeletePort(MsgPort);
      }
   }
   return rc;
}
