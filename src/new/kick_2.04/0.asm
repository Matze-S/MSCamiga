
oldstart    equ   $7fff000
realstart   equ   $7fff700

   far   code
   far   data
   cseg

   move.l   (oldstart+8),(realstart+8)
   jsr      (realstart+12)
   move.l   _8(pc),(realstart+8)
   move.l   _12(pc),(realstart+12)
   move.l   _16(pc),(realstart+16)
   rts

_8    dc.l  $61636365
_12   dc.l  $7373696e
_16   dc.l  $67202573

;
;

   jmp   $7ffffc0

