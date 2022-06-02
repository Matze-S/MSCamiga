
   far   code
   far   data
   cseg

   move.l   (4).w,a6
   lea.l    1$(pc),a5
   jsr      -$1e(a6)
   rts

1$ jmp      $f80002

