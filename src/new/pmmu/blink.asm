
   far code
   far data
   cseg

   moveq.l  #-1,d0
loop:
   move.w   d0,$dff180
   subq.l   #1,d0
   beq.s    quit
   move.l   #loop,pc
quit:
   rts
