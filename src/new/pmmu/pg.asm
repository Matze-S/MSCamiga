;:ts=8
;
;#include <stdio.h>
;
;long tc;
;long crp[4] = { -1, -1, -1, -1};
	dseg
	ds	0
	xdef	_crp
_crp:
	dc.l	$ffffffff
	dc.l	$ffffffff
	dc.l	$ffffffff
	dc.l	$ffffffff
	cseg
;long srp[4] = { -1, -1, -1, -1};
	dseg
	ds	0
	xdef	_srp
_srp:
	dc.l	$ffffffff
	dc.l	$ffffffff
	dc.l	$ffffffff
	dc.l	$ffffffff
	cseg
;long drp[4] = { -1, -1, -1, -1};
	dseg
	ds	0
	xdef	_drp
_drp:
	dc.l	$ffffffff
	dc.l	$ffffffff
	dc.l	$ffffffff
	dc.l	$ffffffff
	cseg
;
;void get_regs(void)
;{
# 9 'pg.c' 409544331
^| .2
	xdef	_get_regs
_get_regs:
	link	a5,#.3
	movem.l	.4,-(sp)
;   long *lp, l;
;
;#asm
;   mc68851
;   mc68881
;
;   move.l   a5,-(sp)
;   lea.l    1$,a5
;   move.l   _SysBase#,a6
;   jsr      _LVODisable#(a6)
;   jsr      _LVOSupervisor#(a6)
;   move.l   (sp)+,a5
;   bra      2$
;
;1$ lea.l    _tc,a0
;   pmove    tc,(a0)
;   lea.l    _crp,a0
;   pmove    crp,(a0)
;   lea.l    _srp,a0
;   pmove    srp,(a0)
;
;;    pmove    (a0),srp
;;    pmove    (a0),drp
;;    pmove    (a0),pcsr
;;    pmove    (a0),psr
;;    pmove    (a0),crp
;;    pmove    (a0),ac
;;    pmove    (a0),scc
;;    pmove    (a0),val
;;    pmove    (a0),cal
;;    pmove    (a0),tc
;;
;;    pmove    srp,(a0)
;;    pmove    drp,(a0)
;;    pmove    pcsr,(a0)
;;;   pmove     psr,(a0)
;;    pmove    crp,(a0)
;;    pmove    ac,(a0)
;;    pmove    scc,(a0)
;;    pmove    val,(a0)
;;    pmove    cal,(a0)
;;    pmove    tc
;;
;;    prestore (a0)+
;;
;;    pflusha
;;    pflushr  (a0)
;;    pflushs  crp,#4
;;    psave    -(a0)
;;    pflush    d0,#5
;;    ploadw    d0,(a0)
;;    ptestw    sfc,(a0),#4
;;    ploadr    d0,(a0)
;;    ptestr    sfc,(a0),#5
;
;   clr.l -(sp)
;   pmove (sp),tc
;   addq.w #4,sp
;
;   rte
;
;2$
;#endasm
   mc68851
   mc68881

   move.l   a5,-(sp)
   lea.l    1$,a5
   move.l   _SysBase#,a6
   jsr      _LVODisable#(a6)
   jsr      _LVOSupervisor#(a6)
   move.l   (sp)+,a5
   bra      2$

1$ lea.l    _tc,a0
   pmove    tc,(a0)
   lea.l    _crp,a0
   pmove    crp,(a0)
   lea.l    _srp,a0
   pmove    srp,(a0)

;    pmove    (a0),srp
;    pmove    (a0),drp
;    pmove    (a0),pcsr
;    pmove    (a0),psr
;    pmove    (a0),crp
;    pmove    (a0),ac
;    pmove    (a0),scc
;    pmove    (a0),val
;    pmove    (a0),cal
;    pmove    (a0),tc
;
;    pmove    srp,(a0)
;    pmove    drp,(a0)
;    pmove    pcsr,(a0)
;;   pmove     psr,(a0)
;    pmove    crp,(a0)
;    pmove    ac,(a0)
;    pmove    scc,(a0)
;    pmove    val,(a0)
;    pmove    cal,(a0)
;    pmove    tc
;
;    prestore (a0)+
;
;    pflusha
;    pflushr  (a0)
;    pflushs  crp,#4
;    psave    -(a0)
;    pflush    d0,#5
;    ploadw    d0,(a0)
;    ptestw    sfc,(a0),#4
;    ploadr    d0,(a0)
;    ptestr    sfc,(a0),#5

   clr.l -(sp)
   pmove (sp),tc
   addq.w #4,sp

   rte

2$
;
;   lp = (long *)crp[1];
~ lp -4 "*l"
~ l -8 "l"
^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^
^^^	move.l	_crp+4,-4(a5)
;   lp = (long *)(lp[7] & ~0xffL);
^	move.l	-4(a5),a0
	move.l	28(a0),d0
	and.l	#-256,d0
	move.l	d0,-4(a5)
;   lp[0xf * 4 + 1] = lp[0xf * 4 + 1] & ~0xffL | 0xd;
^	move.l	-4(a5),a0
	move.l	244(a0),d0
	and.l	#-256,d0
	or.l	#13,d0
	move.l	-4(a5),a0
	move.l	d0,244(a0)
;   lp[0xf * 4] = lp[0xf * 4] & ~0xffL | 0xd;
^	move.l	-4(a5),a0
	move.l	240(a0),d0
	and.l	#-256,d0
	or.l	#13,d0
	move.l	-4(a5),a0
	move.l	d0,240(a0)
;   lp = (long *)crp[1];
^	move.l	_crp+4,-4(a5)
;   lp = (long *)(lp[0] & ~0xffL);
^	move.l	-4(a5),a0
	move.l	(a0),d0
	and.l	#-256,d0
	move.l	d0,-4(a5)
;   lp[0xc * 4] = 0x7f00000L | 0x19;
^	move.l	-4(a5),a0
	move.l	#133169177,192(a0)
;   lp[0xc * 4 + 1] = 0x7f40000L | 0x19;
^	move.l	-4(a5),a0
	move.l	#133431321,196(a0)
;
;#asm
;   move.l   a5,-(sp)
;   lea.l    3$,a5
;   move.l   _SysBase#,a6
;   jsr      _LVOSupervisor#(a6)
;   jsr      _LVOEnable#(a6)
;   move.l   (sp)+,a5
;   bra      4$
;
;3$ lea.l    _crp,a0
;   pmove    (a0),crp
;   rte
;
;4$
;#endasm
   move.l   a5,-(sp)
   lea.l    3$,a5
   move.l   _SysBase#,a6
   jsr      _LVOSupervisor#(a6)
   jsr      _LVOEnable#(a6)
   move.l   (sp)+,a5
   bra      4$

3$ lea.l    _crp,a0
   pmove    (a0),crp
   rte

4$
;}
^^^^^^^^^^^^^^^^^.5
	movem.l	(sp)+,.4
	unlk	a5
	rts
.2
.3	equ	-8
.4	reg	
;
;void main(int argc, char **argv)
;{
# 101
^| .6
	xdef	_main
_main:
	link	a5,#.7
	movem.l	.8,-(sp)
;   get_regs();
~~ argc 8 "l"
~~ argv 12 "**c"
^	jsr	_get_regs
;
;   printf("tc := %08lx\n", tc);
^^	move.l	_tc,-(sp)
	pea	.1+0
	jsr	_printf
	add.w	#8,sp
;   printf("crp := %08lx %08lx\n", crp[0], crp[1]);
^	move.l	_crp+4,-(sp)
	move.l	_crp,-(sp)
	pea	.1+13
	jsr	_printf
	lea	12(sp),sp
;   printf("srp := %08lx %08lx\n", srp[0], srp[1]);
^	move.l	_srp+4,-(sp)
	move.l	_srp,-(sp)
	pea	.1+33
	jsr	_printf
	lea	12(sp),sp
;   printf("drp := %08lx %08lx\n", drp[0], drp[1]);
^	move.l	_drp+4,-(sp)
	move.l	_drp,-(sp)
	pea	.1+53
	jsr	_printf
	lea	12(sp),sp
;   exit(0);
^	clr.l	-(sp)
	jsr	_exit
	add.w	#4,sp
;}
^.9
	movem.l	(sp)+,.8
	unlk	a5
	rts
.6
.7	equ	0
.8	reg	
.1
	dc.b	116,99,32,58,61,32,37,48,56,108,120,10,0,99,114
	dc.b	112,32,58,61,32,37,48,56,108,120,32,37,48,56,108
	dc.b	120,10,0,115,114,112,32,58,61,32,37,48,56,108,120
	dc.b	32,37,48,56,108,120,10,0,100,114,112,32,58,61,32
	dc.b	37,48,56,108,120,32,37,48,56,108,120,10,0
	ds	0
;
;
# 111
|
~ _exit * "(l"
~ _main * "(v"
~ _get_regs * "(v"
~ _drp * "[4l"
~ _srp * "[4l"
~ _crp * "[4l"
~ _tc * "l"
~ '__stdio'
~ 1 8 22
~ _bp 0 "*C"
~ _bend 4 "*C"
~ _buff 8 "*C"
~ _flags 12 "I"
~ _unit 14 "c"
~ _bytbuf 15 "C"
~ _buflen 16 "L"
~ _tmpnum 20 "I"
~ _printf * "(l"
~ FILE ":" 1
~ fpos_t "l"
~ size_t "L"
~ va_list "*c"
	xref	_exit
	xref	_printf
	xref	.begin
	dseg
	global	_tc,4
	end
