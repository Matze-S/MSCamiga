
   far code
   far data
   cseg

x:
   move.w   #size,d0
   moveq.l  #0,d0
   cnop  0,4
size  equ *-x

   end

