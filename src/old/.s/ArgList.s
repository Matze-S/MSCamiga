
_LVOAllocMem	equ -$c6
_LVOFreeMem	equ -$d2
_LVOAddTail	equ -$f6
_SysBase	equ $4
MEMF_PUBLIC	equ $1
MLH_HEAD	equ $0
MLH_TAIL	equ $4
MLH_TAILPRED	equ $8
MLH_SIZE	equ $c

ALN_SUCC	equ $0
ALN_PRED	equ $4
ALN_SIZE	equ $8
ALN_LENGTH	equ $c
ALN_TYPE	equ $e
ALN_TEXT	equ $f

_LVOOpenLibrary	equ	-$228
_LVOCloseLibrary	equ	-$19e
_LVOOutput	equ	-$3c
_LVOWrite	equ	-$30

Test:
	jsr	GetArgList(pc)
	movem.l	d0/a0,-(sp)
	move.l	a0,a2
	lea	dosName(pc),a1
	moveq	#0,d0
	move.l	_SysBase,a6
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,a6
	jsr	_LVOOutput(a6)
	move.l	d0,d6
	move.l	(sp)+,d0
	beq.s	TestLoopStart
	lea	BadArgs(pc),a0
	moveq	#BadArgsLength,d3
	cmp.b	#2,d0
	beq.s	TestError
	lea	NoMem(pc),a0
	moveq	#NoMemLength,d3
TestError:
	move.l	d6,d1
	move.l	a0,d2
	jsr	_LVOWrite(a6)
	bra.s	CloseDOS
TestLoop:
	lea	text1(pc),a0
	moveq	#text1length,d3
	cmp.b	#'"',ALN_TYPE(a2)
	beq.s	TestLoopOk
	lea	text2(pc),a0
	moveq	#text2length,d3
TestLoopOk:
	move.l	a0,d2
	move.l	d6,d1
	jsr	_LVOWrite(a6)
	move.l	d6,d1
	move.l	a2,d2
	add.l	#ALN_TEXT,d2
	moveq	#0,d3
	move.w	ALN_LENGTH(a2),d3
	jsr	_LVOWrite(a6)
	move.l	d6,d1
	lea	cr(pc),a0
	move.l	a0,d2
	moveq	#crlength,d3
	jsr	_LVOWrite(a6)
TestLoopStart:
	move.l	(a2),a2
	tst.l	(a2)
	bne.s	TestLoop
	move.l	(sp),a0
	jsr	FreeArgList(pc)
CloseDOS:
	addq.w	#4,sp
	move.l	a6,a1
	move.l	_SysBase,a6
	jsr	_LVOCloseLibrary(a6)
	rts
	
dosName	dc.b	'dos.library',0
text1	dc.b	39,34,39,': ',39
text1length	equ	*-text1
text2	dc.b	39,32,39,': ',39
text2length	equ	*-text2
cr	dc.b	39,10
crlength	equ	*-cr
BadArgs	dc.b	'Bad arguments!',10
BadArgsLength	equ	*-BadArgs
NoMem	dc.b	'Not enough heap-space',10
NoMemLength	equ	*-NoMem
	even

*
* Create Argument-List
*

GetArgList:
	movem.l	d2-d3/a2-a3/a6,-(sp)
	move.l	a0,a2
	move.l	_SysBase,a6
	moveq	#MLH_SIZE,d0
	moveq	#MEMF_PUBLIC,d1
	jsr	_LVOAllocMem(a6)
	move.l	d0,-(sp)
	beq.l	NoMemory
	move.l	d0,a0
	addq.l	#MLH_TAIL,d0
	move.l	d0,MLH_HEAD(a0)
	clr.l	MLH_TAIL(a0)
	move.l	a0,MLH_TAILPRED(a0)
NextArg:
	subq.l	#1,a2
SkipBlanks:
	addq.l	#1,a2
	cmp.b	#' ',(a2)
	beq.s	SkipBlanks
	cmp.b	#9,(a2)
	beq.s	SkipBlanks
	moveq	#0,d3
	cmp.b	#10,(a2)
	beq.s	ParseEnd
	moveq	#'"',d2
	cmp.b	(a2),d2
	beq.s	IsNotBlank
	moveq	#' ',d2
	subq.l	#1,a2
IsNotBlank:
	lea	1(a2),a3
ParseLoop:
	addq.l	#1,a2
	cmp.b	#10,(a2)
	beq.s	LoopEnd
	cmp.b	#'"',d2
	beq.s	CompareD2
	cmp.b	#9,(a2)
	beq.s	LoopEnd
CompareD2:
	cmp.b	(a2),d2
	bne.s	ParseLoop
LoopEnd:
	move.l	a2,d3
	sub.l	a3,d3
	cmp.b	#' ',d2
	beq.s	EndOk
	cmp.b	#10,(a2)+
	bne.s	EndOk
	moveq	#2,d3
	bra.s	Error
EndOk:	moveq	#ALN_TEXT+1,d0
	add.l	d3,d0
	move.l	d0,-(sp)
	moveq	#MEMF_PUBLIC,d1
	jsr	_LVOAllocMem(a6)
	move.l	(sp)+,d1
	tst.l	d0
	beq.s	NoMemory
	move.l	d0,a1
	move.l	d1,ALN_SIZE(a1)
	move.b	d2,ALN_TYPE(a1)
	move.w	d3,ALN_LENGTH(a1)
	lea	ALN_TEXT(a1),a0
	bra.s	StartCopy
CopyLoop:
	move.b	(a3)+,(a0)+
StartCopy:
	dbf	d3,CopyLoop
	clr.b	(a0)
	move.l	(sp),a0
	jsr	_LVOAddTail(a6)
	bra	NextArg
NoMemory:
	moveq	#1,d3
Error:
	move.l	(sp),a1
	bsr.s	FreeArgList
	clr.l	(sp)
ParseEnd:
	move.l	d3,a0
	movem.l	(sp)+,d0/d2-d3/a2-a3/a6
	exg.l	d0,a0
	rts

FreeArgList:
	move.l	a0,d0
	beq.s	NoArgList
	movem.l	a2/a6,-(sp)
	move.l	_SysBase,a6
	move.l	ALN_SUCC(a0),a1
	bra.s	StartFreeing
FreeLoop:
	move.l	ALN_SUCC(a1),a2
	move.l	ALN_SIZE(a1),d0
	jsr	_LVOFreeMem(a6)
	move.l	a2,a1
StartFreeing:	tst.l	(a1)
	bne.s	FreeLoop
FreeArgHead:
	subq.l	#MLH_TAIL,a1
	moveq	#MLH_SIZE,d0
	jsr	_LVOFreeMem(a6)
NoArgList:
	movem.l	(sp)+,a2/a6
	rts

	end

