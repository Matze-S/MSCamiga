
Start:
   move.l   (4).w,a6
   lea.l DosName(pc),a1
   moveq.l  #0,d0
   jsr   -$228(a6)
   move.l   d0,d6
   beq.w NoDos
   move.l   d6,dosbase
   move.l   d0,a6
   jsr   -$3c(a6)
   move.l   d0,d5
   beq.s NoOutput
   move.l   d5,outputhandle
   move.l   d5,d1
   lea.l StartTxt(pc),a0
   move.l   a0,d2
   moveq.l  #StartTxtLen,d3
   jsr   -$30(a6)
   move.l   (4).w,a6
   move.l   $12c(a6),d0
   beq.s NoResModules
IsPtr:
   bclr.l   #31,d0
   move.l   d0,a0
Loop:
   move.l   (a0)+,d0
   bmi.s IsPtr
   beq.s NoRes
   move.l   d0,a1
   movem.l  d0-d7/a0-a6,-(sp)
   move.l   22(a1),-(sp)
   moveq.l  #0,d1
   move.b   11(a1),d1
   move.w   d1,-(sp)
   move.b   10(a1),d1
   move.w   d1,-(sp)
   move.b   12(a1),d1
   move.w   d1,-(sp)
   move.b   13(a1),d1
   ext.w d1
   move.w   d1,-(sp)
   move.l   14(a1),-(sp)
   lea.l OutString(pc),a0
   move.l   sp,a1
   lea.l OutProc(pc),a2
   lea.l Buffer(pc),a3
   jsr   -522(a6)
   lea.l 16(sp),sp
   lea.l Buffer(pc),a0
   bsr   Print
   movem.l  (sp)+,d0-d7/a0-a6
   bra.s Loop
NoResModules:
NoRes:
NoOutput:
   move.l   d6,a1
   move.l   (4).w,a6
   jsr   -$19e(a6)
NoDos:
   moveq.l  #0,d0
   rts

OutProc:
   movem.l  d0-d7/a0-a2/a4-a6,-(sp)
   move.b   d0,(a3)+
   addq.b   #1,Buffer
   cmp.b #255,Buffer
   bcs.s NoPrint
   lea.l Buffer(pc),a3
   move.l   a3,a0
   bsr.s Print
   clr.b (a3)
NoPrint:
   movem.l  (sp)+,d0-d7/a0-a2/a4-a6
   rts

Print:
   move.l   outputhandle,d1
   move.l   dosbase,a6
   moveq.l  #0,d3
   move.b   (a0)+,d3
   beq.s PrintEnd
   move.l   a0,d2
   jsr   -$30(a6)
PrintEnd:
   rts

zwsp:
   dc.b  0
   even

dosbase:
   dc.l  0
outputhandle:
   dc.l  0

DosName:
   dc.b  'dos.library',0
   even

Buffer:
   ds.b  256

StartTxt:
   dc.b  ' Name:                Pri: Type: Flags: Version: Init:',10
   dc.b  ' -------------------- ---- ----- ------ -------- -----',10
StartTxtLen equ   *-StartTxt

OutString:
   dc.b  ' %-20s %4d  %3d   %3d     %3d   $%06lx',10,0
   even

