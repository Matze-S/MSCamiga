
*
*  RemFFSBoot.s
*
*  Written by Matthias Schmidt
*  Last change at 17-Feb-89 15:06
*

Init:
	move.l	a0,a2
	move.l	d0,d2
	moveq.l	#20,d5
	move.l	(4).w,a6
	lea.l	DosName(pc),a1
	moveq.l	#0,d0
	jsr	-$228(a6)
	move.l	d0,d6
	beq.l	Exit
	move.l	d0,a6
	jsr	-$3c(a6)
	move.l	d0,d7
	moveq.l	#0,d5
	lea.l	HelpTxt(pc),a0
	cmp.b	#'?',(a2)
	beq.s	BeqEndMsg1
	moveq.l	#20,d5
	subq.l	#2,d2
	bmi.s	EndMsg
BeqEndMsg1:
	beq.s	EndMsg
	cmp.b	#':',0(a2,d2.l)
	bne.s	EndMsg
	moveq.l	#10,d5
	move.l	(4).w,a6
	jsr	-$84(a6)
	lea.l	$226(a6),a1
	bset.b	#7,(a1)
	lea.l	NotExistsTxt(pc),a0
SearchResLoop:
	move.l	a1,a3
	move.l	(a1)+,d0
	beq.s	CorrectKickTag
	bpl.s	SearchResLoop
	bclr.l	#31,d0
	move.l	d0,a1
	move.l	(a1),a5
	move.l	14(a5),a5
	move.l	a2,a4
	move.l	d2,d1
	bra.s	CmpResNameEntry1
CmpResNameLoop1:
	move.b	(a4)+,d0
	bsr.s	toupper
	move.b	d0,d3
	move.b	(a5)+,d0
	bsr.s	toupper
	cmp.b	d0,d3
	bne.s	SearchResLoop
CmpResNameEntry1:
	dbra	d1,CmpResNameLoop1
	lea.l	FFSBootTxt(pc),a4
CmpResNameLoop2:
	move.b	(a5)+,d0
	cmp.b	(a4)+,d0
	bne.s	SearchResLoop
	tst.b	d0
	bne.s	CmpResNameLoop2
	move.l	4(a1),(a3)
	bset.b	#7,(a3)
	moveq.l	#0,d5
	lea.l	RemovedTxt(pc),a0
CorrectKickTag:
	move.l	a0,-(sp)
	bclr.b	#7,$226(a6)
	jsr	-$264(a6)
	move.l	d0,$22a(a6)
	jsr	-$8a(a6)
	move.l	(sp)+,a0
EndMsg:
	moveq.l	#0,d3
	move.b	(a0)+,d3
	move.l	d7,d1
	move.l	d6,a6
	move.l	a0,d2
	jsr	-$30(a6)
	move.l	a6,a1
	move.l	(4).w,a6
	jsr	-$19e(a6)
Exit:
	move.l	d5,d0
	rts

toupper:
	cmp.b	#'a',d0
	bcs.s	toupperok
	cmp.b	#'z',d0
	bcc.s	toupperok
	sub.b	#'a'-'A',d0
toupperok:
	rts

DosName:
	dc.b	'dos.library',0
HelpTxt:
	dc.b	27,'Usage: RemFFSBoot <DEVICE>',10
NotExistsTxt:
	dc.b	20,'FFS not installed !',10
RemovedTxt:
	dc.b	13,'FFS removed.',10
FFSBootTxt:
	dc.b	'.ffsboot',0
	even

