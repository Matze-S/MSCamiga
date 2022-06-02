
   mc68851
   mc68881
   machine mc68020
   cseg

   public _get_tc
_get_tc:
   movem.l  a5-a6,-(sp)
   lea.l    1$,a5
   move.l   (4).w,a6
   jsr      -30(a6)
   bra      2$
1$
   clr.l    -(sp)
   frestore (sp)+
   subq.w   #4,sp
   pmove    tc,(sp)
   move.l   (sp)+,d0
   clr.l    -(sp)
   pmove    (sp),tc
   rte
2$
   movem.l  (sp)+,a5-a6
   rts

