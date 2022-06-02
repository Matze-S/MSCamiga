;:ts=8
;
;#include <functions.h>
;#include <stdio.h>
;
;extern long size;
;extern void rout(void);
;
;#asm
;   cseg
;   xdef  _rout
;_rout:
;   rte
;_rout_end:
;   dseg
;_size:
;   dc.l  (_rout_end-_rout)
;   cseg
;#endasm
   cseg
   xdef  _rout
_rout:
   rte
_rout_end:
   dseg
_size:
   dc.l  (_rout_end-_rout)
   cseg
;
;void (**_vbr_)();
;
;void set_vbr(void (**vbr)())
;{
	xdef	_set_vbr
_set_vbr:
	link	a5,#.2
	movem.l	.3,-(sp)
;   _vbr_ = vbr;
	move.l	8(a5),__vbr_
;#asm
;   move.l   _SysBase#,a6
;   jsr      _LVODisable#(a6)
;   move.l   a5,-(sp)
;   lea.l    1$,a5
;   jsr      _LVOSupervisor#(a6)
;   move.l   (sp)+,a5
;   jsr      _LVOEnable#(a6)
;   bra      2$
;   machine  mc68010
;1$ move.l   __vbr_,a0
;   movec.l  a0,vbr
;   rte
;2$
;#endasm
   move.l   _SysBase#,a6
   jsr      _LVODisable#(a6)
   move.l   a5,-(sp)
   lea.l    1$,a5
   jsr      _LVOSupervisor#(a6)
   move.l   (sp)+,a5
   jsr      _LVOEnable#(a6)
   bra      2$
   machine  mc68010
1$ move.l   __vbr_,a0
   movec.l  a0,vbr
   rte
2$
;}
.4
	movem.l	(sp)+,.3
	unlk	a5
	rts
.2	equ	0
.3	reg	
;
;void main(int argc, char **argv)
;{
	xdef	_main
_main:
	link	a5,#.5
	movem.l	.6,-(sp)
;   long *vbr;
;   char *cp;
;   int i;
;
;   if (vbr = AllocMem(1024L + size, 0L)) {
	move.l	a6,-16(a5)
	move.l	#0,d1
	move.l	_size,d0
	add.l	#1024,d0
	move.l	_SysBase#,a6
	jsr	-198(a6)
	move.l	-16(a5),a6
	move.l	d0,-4(a5)
	beq	.10001
;      for (i = 0; i < 255; ++i) vbr[i] = ((long *)0L)[i];
	clr.l	-12(a5)
	bra	.10003
.10002
	add.l	#1,-12(a5)
.10003
	cmp.l	#255,-12(a5)
	bge	.10004
	move.l	-12(a5),d0
	asl.l	#2,d0
	sub.l	a0,a0
	move.l	-12(a5),d1
	asl.l	#2,d1
	move.l	-4(a5),a1
	move.l	(a0,d0.l),(a1,d1.l)
	bra	.10002
.10004
;      cp = (char *)&vbr[256];
	move.l	-4(a5),-8(a5)
	add.l	#1024,-8(a5)
;      for (i = 0; i < size; ++i) cp[i] = ((char *)rout)[i];
	clr.l	-12(a5)
	bra	.10006
.10005
	add.l	#1,-12(a5)
.10006
	move.l	-12(a5),d0
	cmp.l	_size,d0
	bge	.10007
	move.l	-12(a5),d0
	lea	_rout,a0
	move.l	-12(a5),d1
	move.l	-8(a5),a1
	move.b	(a0,d0.l),(a1,d1.l)
	bra	.10005
.10007
;      vbr[8] = (long)cp;
	move.l	-4(a5),a0
	move.l	-8(a5),32(a0)
;      set_vbr((void (**)())vbr);
	move.l	-4(a5),-(sp)
	jsr	_set_vbr
	add.w	#4,sp
;   }
;   exit(0);
.10001
	clr.l	-(sp)
	jsr	_exit
	add.w	#4,sp
;}
.7
	movem.l	(sp)+,.6
	unlk	a5
	rts
.5	equ	-16
.6	reg	
;
;
	xref	_rout
	xref	_exit
	xref	.begin
	dseg
	global	__vbr_,4
	xref	_size
	end
