
*
*  FFSBoot.s - V3.1
*
*  Written by Matthias Schmidt
*

Init:
	move.l	sp,a5
	move.l	a0,a2
	move.l	d0,d2
	moveq.l	#20,d5
	move.l	(4).w,a6
	lea.l	DosName(pc),a1
	moveq.l	#$22,d0
	jsr	-$228(a6)
	move.l	d0,d6
	beq.l	Exit
	move.l	d0,a6
	jsr	-$3c(a6)
	move.l	d0,d7
	lea.l	HelpTxt(pc),a0
	cmp.b	#'?',(a2)
	beq.l	IsOk
	move.l	d2,d0
	subq.l	#2,d2
	bmi.l	EndMsg
	beq.s	BeqEnd1
	cmp.b	#':',0(a2,d2.l)
	bne.l	EndMsg
	moveq.l	#5,d5
	bclr.l	#0,d0
	sub.l	d0,sp
	move.l	sp,a0
	move.b	d2,(a0)+
	bra.s	CopyArgEntry
CopyArgLoop:
	move.b	(a2)+,(a0)+
CopyArgEntry:
	dbra	d2,CopyArgLoop
	move.l	(4).w,a6
	move.l	$226(a6),d0
	beq.s	NotExists
SearchResIsPtr:
	bclr.l	#31,d0
	move.l	d0,a2
SearchResLoop:
	move.l	(a2)+,d0
	beq.s	NotExists
	bmi.s	SearchResIsPtr
	move.l	d0,a0
	move.l	14(a0),a0
	subq.l	#1,a0
	move.l	sp,a1
	bsr	bstrcmp
	bne.s	SearchResLoop
	lea.l	ffsbootTxt(pc),a1
CmpResNameLoop:
	move.b	(a0)+,d0
	cmp.b	(a1)+,d0
	bne.s	SearchResLoop
	tst.b	d0
	bne.s	CmpResNameLoop
	lea.l	AlreadyTxt(pc),a0
BeqEnd1:
	beq.s	BeqEnd2
NotExists:
	moveq.l	#20,d5
	move.l	d6,a6
	move.l	$22(a6),a0
	move.l	$18(a0),d0
	lsl.l	#2,d0
	move.l	d0,a4
	addq.l	#4,a4
SearchDevLoop:
	lea.l	NotFoundTxt(pc),a0
	move.l	(a4),d0
BeqEnd2:
	beq.s	BeqEnd3
	lsl.l	#2,d0
	move.l	d0,a4
	tst.l	4(a4)
	bne.s	SearchDevLoop
	move.l	$28(a4),d0
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	sp,a1
	bsr	bstrcmp
	bne.s	SearchDevLoop
	lea.l	NotLoadedTxt(pc),a0
	move.l	$20(a4),d2
BeqEnd3:
	beq.s	BeqEnd4
	lea.l	NotNeededTxt(pc),a0
	cmp.l	#$f00000>>2,d2
	bcc.l	EndMsg
	move.l	d2,d1
	moveq.l	#4,d0
CountLoop:
	addq.l	#8,d0
	lsl.l	#2,d1
	move.l	d1,a0
	move.l	(a0),d1
	bne.s	CountLoop
	add.l	#ResidentSize+8,d0
	move.l	d0,d3
	moveq.l	#11,d1
	add.b	(sp),d1
	add.l	d1,d0
	and.w	#-2,d0
	move.l	d0,d4
	moveq.l	#3,d1
	move.l	(4).w,a6
	jsr	-$c6(a6)
	lea.l	NoMemTxt(pc),a0
	tst.l	d0
BeqEnd4:
	beq.l	EndMsg
	move.l	d0,a2
	lea.l	8(a2),a3
	lea.l	ResidentSize(a3),a1
SaveLoop:
	lsl.l	#2,d2
	move.l	d2,(a1)+
	beq.s	SaveEnd
	move.l	d2,a0
	move.l	(a0),d2
	move.l	-(a0),(a1)+
	bra.s	SaveLoop
SaveEnd:
	move.l	a3,a1
	lea.l	Resident(pc),a0
	move.w	#ResidentSize/2-1,d1
CopyResLoop:
	move.w	(a0)+,(a1)+
	dbra	d1,CopyResLoop
	add.l	a2,d3
	move.l	a3,d0
	move.l	d0,2(a3)
	move.l	d4,6(a3)
	add.l	d0,6(a3)
	add.l	d3,14(a3)
	add.l	d0,18(a3)
	add.l	d0,22(a3)
	move.l	$24(a4),d2
	movem.l	d2/d4/a2,(ResidentData-Resident)(a3)
	move.l	d3,a1
	move.l	sp,a0
	clr.w	d1
	move.l	$28(a4),d0
	lsl.l	#2,d0
	move.l	d0,a0
	move.b	(a0),d1
CopyNameLoop:
	move.b	(a0)+,(a1)+
	dbra	d1,CopyNameLoop
	moveq.l	#8,d1
	lea.l	ffsbootTxt(pc),a0
CopyNameLoop2:
	move.b	(a0)+,(a1)+
	dbra	d1,CopyNameLoop2
	jsr	-$84(a6)
	lea.l	(ResidentArray-Resident+4)(a3),a1
	move.l	$226(a6),(a1)
	beq.s	NoOldResident
	bset.b	#7,(a1)
NoOldResident:
	move.l	a3,-(a1)
	move.l	a1,$226(a6)
	jsr	-$264(a6)
	move.l	d0,$22a(a6)
	jsr	-$8a(a6)
	lea.l	IsOkTxt(pc),a0
IsOk:
	moveq.l	#0,d5
EndMsg:
	moveq.l	#0,d3
	move.b	(a0)+,d3
	move.l	a0,d2
	move.l	d7,d1
	move.l	d6,a6
	jsr	-$30(a6)
	move.l	(4).w,a6
	move.l	d6,a1
	jsr	-$19e(a6)
Exit:
	move.l	d5,d0
	move.l	a5,sp
	rts

DosName:
	dc.b	'dos.library',0
HelpTxt:
	dc.b	24,'Usage: FFSBoot <DEVICE>',10
NotFoundTxt:
	dc.b	19,'Device not found !',10
NotLoadedTxt:
	dc.b	17,'FFS not loaded !',10
NotNeededTxt:
	dc.b	42,'FileSystem already exists in the KickStart !',10
NoMemTxt:
	dc.b	48,'Not enough memory for resident-code and -data !',10
IsOkTxt:
	dc.b	15,'FFS installed.',10
AlreadyTxt:
	dc.b	23,'FFS already installed.',10
ffsbootTxt:
	dc.b	'.ffsboot',0
	even

Resident:
	dc.w	$4afc
	dc.l	0
	dc.l	0
	dc.b	1
	dc.b	3
	dc.b	0
	dc.b	-30
	dc.l	1
	dc.l	ResidentId-Resident
	dc.l	ResidentCode-Resident
ResidentArray:
	dc.l	0,0
ResidentData:
	dc.l	0,0,0
ResidentId:
	dc.b	'FFSBoot Version 3.0 (12-Feb-89 18:00)',0
ExpansionName:
	dc.b	'expansion.library',0
	even

ResidentCode:
	movem.l	a2/d2/a6,-(sp)
	move.l	(4).w,a6
	movem.l	(ResidentData+4)(pc),d0/a1
	jsr	-$cc(a6)
	tst.l	d0
	beq.l	ResidentCodeEnd
	lea.l	(Resident+ResidentSize)(pc),a2
	moveq.l	#1,d2
AllocLoop:
	movem.l	(a2)+,d0/a1
	exg.l	a1,d0
	subq.l	#4,a1
	jsr	-$cc(a6)
	tst.l	d0
	beq.s	SearchBootNode
	move.l	d0,a0
	movem.l	-4(a2),d0/d1
	lsr.l	#2,d1
	movem.l	d0/d1,(a0)
	bne.s	AllocLoop
	moveq.l	#0,d2
SearchBootNode:
	lea.l	ExpansionName(pc),a1
	moveq.l	#$22,d0
	jsr	-$228(a6)
	tst.l	d0
	beq.s	ResidentCodeEnd
	move.l	d0,a1
	lea.l	$4a(a1),a2
	jsr	-$19e(a6)
SearchBootDevLoop:
	move.l	(a2),a2
	tst.l	(a2)
	beq.s	ResidentCodeEnd
	cmp.b	#16,8(a2)
	bne.s	ResidentCodeEnd
	move.l	$10(a2),a0
	move.l	$28(a0),d0
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	(Resident+14)(pc),a1
	subq.l	#1,a1
	bsr.s	bstrcmp
	bne.s	SearchBootDevLoop
	tst.w	d2
	beq.s	NotRemBootNode
	move.l	a2,a1
	jsr	-$fc(a6)
	bra.s	ResidentCodeEnd
NotRemBootNode:
	move.l	$10(a2),a0
	move.l	(Resident+ResidentSize)(pc),d0
	lsr.l	#2,d0
	move.l	ResidentData(pc),d1
	movem.l	d0/d1,$20(a0)
ResidentCodeEnd:
	movem.l	(sp)+,a2/d2/a6
	rts

bstrcmp:
	clr.w	d0
	moveq.l	#0,d1
	move.b	(a0)+,d1
	cmp.b	(a1)+,d1
	bra.s	bstrcmpentry
bstrcmploop:
	move.b	(a0)+,d0
	bsr.s	toupper
	move.w	d0,-(sp)
	move.b	(a1)+,d0
	bsr.s	toupper
	cmp.w	(sp)+,d0
bstrcmpentry:
	dbne	d1,bstrcmploop
	rts
toupper:
	cmp.b	#'a',d0
	bcs.s	toupperok
	cmp.b	#'z',d0
	bcc.s	toupperok
	sub.b	#'a'-'A',d0
toupperok:
	rts

ResidentSize	equ	*-Resident

	end

