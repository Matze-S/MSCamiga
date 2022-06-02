
_LVOSupervisor equ   -$1e
_LVODisable    equ   -$78
_LVOEnable     equ   -$7e
_LVOAllocMem   equ   -$c6
_AbsExecBase   equ   $4

   far      code
   far      data
   machine  mc68010
   cseg

init:
   movem.l  d2/a2-a3/a5,-(sp)
   moveq.l  #10,d2
   move.l   (_AbsExecBase).w,a6
   move.l   #(codeEnd-code+$400),d0
   moveq.l  #1,d1
   jsr      _LVOAllocMem(a6)
   tst.l    d0
   beq.s    8$
   move.l   d0,a2
   jsr      _LVODisable(a6)
   move.l   a2,a1
   moveq.l  #15,d0
   lea.l    $400(a2),a3
1$ move.l    a3,(a1)+
   dbf       d0,1$
   lea.l    ($40).w,a0
   moveq.l  #7,d0
2$ move.l    (a0)+,(a1)+
   dbf       d0,2$
   moveq.l  #23,d0
3$ move.l    a3,(a1)+
   dbf       d0,3$
   lea.l    ($c0).w,a0
   move.w    #$cf,d0
4$ move.l    (a0)+,(a1)+
   dbf       d0,4$
   move.w    #((codeEnd-code)/2-1),d0
   lea.l    code(pc),a0
5$ move.w    (a0)+,(a1)+
   dbf       d0,5$
   lea.l    6$,a5
   jsr      _LVOSupervisor(a6)
   bra.s    7$
6$ movec.l  a2,vbr
   rte
7$ jsr      _LVOEnable(a6)
   moveq.l  #0,d2
8$ move.l   d2,d0
   movem.l  (sp)+,d2/a2-a3/a5
   rts

code:
   subq.w   #4,sp
   move.w   sr,-(sp)
   movem.l  d0/a0,-(sp)
   move.w   #$f00,$dff180
   move.w   20(sp),d0
   and.w    #$fff,d0
   cmp.w    #$20,d0
   beq.s    1$
6$
   sub.l    a0,a0
   move.l   0(a0,d0.w),10(sp)
   movem.l  (sp)+,d0/a0
   move.w   (sp)+,sr
   rts
1$ bsr      blink
   move.l   16(sp),a0
   move.w   (a0),d0
   and.w    #$ffc0,d0
   cmp.w    #$40c0,d0
   beq.s    7$
   move.w   20(sp),d0
   and.w    #$fff,d0
   bra.s    6$
7$ move.w   (a0),d0
   lsr.w    #3,d0
   and.w    #7,d0
   cmp.w    #5,d0
   bcc.s    2$
   move.w   (a0)+,d0
   move.l   a0,16(sp)
   lea.l    5$(pc),a0
   move.w   d0,(a0)+
   move.l   #$4e714e71,(a0)
   bra.s    4$
2$ cmp.w    #15,d0
   bcc.s    3$
   move.l   (a0)+,d0
   move.l   a0,16(sp)
   lea.l    5$(pc),a0
   move.l   d0,(a0)+
   move.w   #$4e71,(a0)
   bra.s    4$
3$ move.w   (a0),-(sp)
   move.l   (a0)+,d0
   move.l   a0,18(sp)
   lea.l    5$(pc),a0
   move.w   (sp)+,a0
   move.l   d0,(a0)+
4$ movem.l  (sp)+,d0/a0
   move.w   (sp)+,sr
   addq.w   #4,sp
5$ nop
   nop
   nop
   rte

blink:
   move.w   ccr,-(sp)
   move.l   d0,-(sp)
   move.w   #$100,d0
1$ move.w   d0,$dff180
   dbf      d0,1$
   move.l   (sp)+,d0
   move.w   (sp)+,ccr
   rts

toEA:


toARl:               ; d0 := A reg #, d1 := value
   move.l   (sp)+,d2
   and.w    #7,d0
   lsl.w    #2,d0
   jmp      1$(pc,d0.w)
1$ move.l   d1,a0
   bra.s    2$
   move.l   d1,a1
   bra.s    2$
   move.l   d1,a2
   bra.s    2$
   move.l   d1,a3
   bra.s    2$
   move.l   d1,a4
   bra.s    2$
   move.l   d1,a5
   bra.s    2$
   move.l   d1,a6
   bra.s    2$
   move.l   d1,a7
2$ move.l   d2,-(sp)
   rts

codeEnd:
   end

