
*
*  PALCLI.s
*
*  Written at 08-Mar-89 14:25 by Matthias Schmidt
*

main:
	move.l	(4).w,a6
	jsr	-$84(a6)
	lea.l	IntuitionName(pc),a1
	moveq.l	#0,d0
	jsr	-$228(a6)
	moveq.l	#20,d5
	tst.l	d0
	beq.s	exit
	move.l	d0,a6
	movem.l	52(a6),a2/a3
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
	move.l	a6,a1
	move.l	(4).w,a6
	jsr	-$19e(a6)
	moveq.l	#0,d5
exit:
	jsr	-$84(a6)
	move.l	d5,d0
	rts

IntuitionName:
	dc.b	'intuition.library',0
	even

