; BCPL <> C - Interface - Copyright (C) 1989 by Matthias Schmidt

   public   _bcpl
_bcpl:
   movem.l  d2-d7/a2-a6,-(sp)       ; save registers
   move.l   a7,d0                   ; build BCPL stack
   sub.l    #$600,d0
   bclr.l   #1,d0                   ; force it to be longword-aligned
   move.l   d0,a1
   movem.l  48(sp),d0-d4            ; get arguments
   move.l   _DOSBase,a6             ; set BCPL environment
   movem.l  42(a6),a2/a5-a6
   sub.l    a0,a0
   move.l   (a2,d0.l),a4            ; set BCPL function address
   move.l   #$c,d0                  ; set stack-offset
   jsr      (a5)                    ; call BCPL function
   move.l   d1,d0                   ; move result to d0
   movem.l  (sp)+,d2-d7/a2-a6       ; get back registers
   rts                              ; return to caller

   public   _DOSBase

