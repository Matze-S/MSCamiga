
*
* MaxFast.s - force all existing fast ram to be unused after reset
*
* Written at 27-May-89 by Matthias Schmidt
*

main:
	move.l	(4).w,a6
	jsr	-$78(a6)
	move.l	46(a6),d0
	bne.s	Remove
	moveq.l	#(CodeSize+8),d0
	moveq.l	#3,d1
	jsr	-$c6(a6)
	tst.l	d0
	beq.s	NoMemory
	lea.l	CodeStart(pc),a0
	move.l	d0,a1
	addq.w	#8,a1
	move.l	a1,46(a6)
	move.w	#(CodeSize/2-1),d0
CopyCodeLoop:
	move.w	(a0)+,(a1)+
	dbra	d0,CopyCodeLoop
	bsr.s	CalcNewChkSum
	jsr	-$96(a6)
	reset
	jmp	$fc0002
Remove:
	move.l	d0,a1
	subq.w	#8,a1
	moveq.l	#(CodeSize+8),d0
	jsr	-$d2(a6)
	clr.l	46(a6)
	bra.s	NoMemory

CodeStart:
	jsr	-$78(a6)
	lea.l	(CodeStart-8)(pc),a1
	moveq.l	#(CodeSize+8),d0
	jsr	-$cc(a6)
	tst.l	d0
	beq.s	NoMemory
	addq.l	#8,d0
	move.l	d0,46(a6)
	move.l	322(a6),a1
	bra.s	SearchFastEntry
SearchFastLoop:
	move.l	d0,-(sp)
	btst.b	#2,15(a1)
	beq.s	SearchFastNext
	move.l	a1,-(sp)
	jsr	-$fc(a6)
	move.l	(sp)+,a1
	move.b	#-15,9(a1)
	lea	322(a6),a0
	jsr	-$10e(a6)
SearchFastNext:
	move.l	(sp)+,a1
SearchFastEntry:
	move.l	(a1),d0
	bne.s	SearchFastLoop
NoMemory:
	bsr.s	CalcNewChkSum
	jsr	-$7e(a6)
	moveq.l	#0,d0
	rts

CalcNewChkSum:
	lea.l	34(a6),a0
	moveq.l	#23,d1
	clr.w	d0
CalcNewChkSumLoop:
	add.w	(a0)+,d0
	dbra	d1,CalcNewChkSumLoop
	not.w	d0
	move.w	d0,82(a6)
	rts

CodeSize	EQU	*-CodeStart

