
*
*  PALCLI.s - V2.0
*
*  Written at 23-Apr-89 18:19 by Matthias Schmidt
*

main:
	sub.w	#$8a,sp
	move.l	(4).w,a6
	moveq.l	#-1,d0
	jsr	-$14a(a6)
	moveq.l	#-1,d1
	moveq.l	#20,d5
	cmp.l	d0,d1
	beq.l	exit
	clr.b	14(sp)
	move.b	d0,15(sp)
	sub.l	a1,a1
	jsr	-$126(a6)
	move.l	d0,16(sp)
	lea.l	24(sp),a0
	clr.l	(a0)
	move.l	a0,-(a0)
	move.l	a0,8(a0)
	move.l	d0,a0
	move.l	164(a0),a0
	lea.l	42(sp),a2
	move.w	#(5<<8),(a2)+
	lea.l	54(sp),a1
	move.l	a1,(a2)+
	move.l	sp,(a2)+
	move.w	#$44,(a2)+
	lea.l	34(sp),a1
	move.l	a1,(a2)+
	move.l	sp,(a2)+
	moveq.l	#25,d0
	moveq.l	#-1,d1
	lea.l	102(sp),a3
	move.l	a3,d3
	lsr.l	#2,d3
	movem.l	d0-d3,(a2)
	jsr	-$16e(a6)
	move.l	sp,a0
	jsr	-$180(a6)
	lea.l	IntuitionName(pc),a1
	moveq.l	#0,d0
	jsr	-$228(a6)
	tst.l	d0
	beq.s	noIntuition
	move.l	d0,a6
	move.l	130(sp),a2
	move.l	46(a2),a3
	move.l	a2,a0
	movem.w	4(a0),d0/d1
	neg.w	d0
	neg.w	d1
	ext.l	d0
	ext.l	d1
	jsr	-$a8(a6)
	move.l	a2,a0
	movem.w	12(a3),d0/d1
	sub.w	8(a0),d0
	ext.l	d0
	sub.w	10(a0),d1
	sub.w	#12,d1
	ext.l	d1
	jsr	-$120(a6)
	move.l	a2,a0
	moveq.l	#0,d0
	moveq.l	#12,d1
	jsr	-$a8(a6)
	moveq.l	#0,d5
noIntuition:
	move.l	a6,a1
	move.l	(4).w,a6
	jsr	-$19e(a6)
exit:
	add.w	#$8a,sp
	move.l	d5,d0
	rts

IntuitionName:
	dc.b	'intuition.library',0
	even

