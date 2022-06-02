
         far code
         far data
         machine mc68020
         mc68881
         mc68851
         cseg

         move.l   ($4).w,a6
         lea.l    do_mmu,a5
         jsr      -$1e(a6)
         rts

do_mmu:
         subq.w   #4,sp
         pmove.l  tc,(sp)
         move.l   (sp)+,d0
         rte

         end

