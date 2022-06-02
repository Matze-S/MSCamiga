
*
* Flush.asm
*
* Written at 27-Nov-88 and Copyright © in 1988 by Matthias Schmidt
* Force the system to close all unused libraries,devices, ...
*

_SysBase       equ $4
_LVOAllocMem   equ -$c6
_LVOFreeMem    equ -$d2

_Flush         moveq #1,d2
               move.l _SysBase,a6
_Flush_Loop    move.l d2,d0
               moveq #0,d1
               jsr _LVOAllocMem(a6)
               tst.l d0
               beq.s _Flush_End
               move.l d0,a1
               move.l d2,d0
               jsr _LVOFreeMem(a6)
               add.l #$400,d2
               bne.s _Flush_Loop
_Flush_End     moveq #0,d0
               rts

