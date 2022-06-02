
   mc68851

   move.l   (4).w,a6
   jsr      -120(a6)
   lea.l    1$,a5
   jsr      -30(a6)
   jsr      -126(a6)
   moveq.l  #20,d0
   rts

1$ clr.l    -(sp)
   pmove    (sp),tc
   addq.w   #4,sp
   move.l   #$4ef9,(0).w
   lea.l    ($f80002).l,a0
   move.l   a0,(4).w
   bra      2$
2$ reset
   jmp      (a0)

   end

