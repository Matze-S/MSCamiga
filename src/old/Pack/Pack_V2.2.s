
*
*  Pack.s - Version 2.2
*
*  Written at 26-Mar-89 by Matthias Schmidt
*  Last change at 05-Apr-89 17:04
*

FileName	equ	-108
ArgBuffer	equ	FileName-256
ReadFileHandle	equ	ArgBuffer-4
WriteFileHandle	equ	ReadFileHandle-4
BufferPointer	equ	WriteFileHandle-4
BufferReqs	equ	BufferPointer-4
BufferSize	equ	BufferReqs-4
BufferPosPtr	equ	BufferSize-4
BufferRemains	equ	BufferPosPtr-4
ErrorArg	equ	BufferRemains-4
ErrorMsg	equ	ErrorArg-4
ErrorCode	equ	ErrorMsg-4
IndentCount	equ	ErrorCode-4
Size		equ	IndentCount

main:
	move.l	sp,a1
	sub.l	4(sp),a1
	lea.l	(8-Size)(a1),a1
	sub.l	a0,a0
	move.l	#(65536/4),d0
	moveq.l	#1,d1
	movem.l	d1/a0,IndentCount(a1)
	movem.l	d0-d1/a0,BufferSize(a1)
	lea.l	ArgsTxt(pc),a3
	move.l	a3,d1
	lsr.l	#2,d1
	lea.l	ArgBuffer(a1),a3
	move.l	a3,d2
	lsr.l	#2,d2
	moveq.l	#$3f,d3
	move.l	$138(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	BadArgsTxt(pc),a3
	move.l	a3,ErrorMsg(a1)
	tst.l	d1
	beq.s	ErrorBEQ0
	movem.l	(ArgBuffer+8)(a1),d1-d2
	move.l	d1,d3
	or.l	d2,d1
ErrorBEQ0:
	beq.l	Error
	and.l	d3,d2
	bne.l	Error
	move.l	d3,BufferRemains(a1)
	move.l	(ArgBuffer+16)(a1),d0
	beq.l	AllocBuffer
	lsl.l	#2,d0
	move.l	d0,a4
	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	moveq.l	#1,d4
	lea.l	InvalidBufTxt(pc),a3
	move.l	a3,ErrorMsg(a1)
	move.b	(a4)+,d1
	beq.s	ErrorBEQ0
	bra.s	GetBufSizeEntry
GetBufSizeLoop:
	move.b	(a4)+,d2
	sub.b	#'0',d2
	cmp.b	#10,d2
	bcc.s	GetReqsEntry
	mulu	#10,d0
	add.w	d2,d0
	cmp.w	#1000,d0
	bcc.l	Error
GetBufSizeEntry:
	dbra	d1,GetBufSizeLoop
	bra.s	SetBuffer
GetReqsLoop:
	move.b	(a4)+,d2
	sub.b	#'0',d2
GetReqsEntry:
	cmp.b	#('c'-'0'),d2
	beq.s	SetChip
	cmp.b	#('C'-'0'),d2
	beq.s	SetChip
	cmp.b	#('l'-'0'),d2
	beq.s	SetLargest
	cmp.b	#('L'-'0'),d2
	bne.s	ErrorBNE1
SetLargest:
	btst.l	#17,d4
	bne.s	ErrorBNE1
	bset.l	#17,d4
	bra.s	GetReqsGoOn
SetChip:
	btst.l	#1,d4
ErrorBNE1:
	bne.l	Error
	bset.l	#1,d4
GetReqsGoOn:
	dbra	d1,GetReqsLoop
SetBuffer:
	move.l	d4,BufferReqs(a1)
	btst.l	#17,d4
	bne.s	GetAvailMem
	lsl.l	#8,d0
	beq.s	AllocBuffer
	move.l	d0,BufferSize(a1)
	bra.s	AllocBuffer
GetAvailMem:
	tst.l	d0
	bne.s	ErrorBNE1
	move.l	#-$d8,d1
	move.l	d4,d3
	move.l	$160(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	NotEnoughMemTxt(pc),a3
	move.l	a3,ErrorMsg(a1)
	moveq.l	#16,d0
	cmp.l	d0,d1
	bcs.l	Error
	lsr.l	#2,d1
	subq.l	#2,d1
	move.l	d1,BufferSize(a1)
AllocBuffer:
	movem.l	BufferSize(a1),d1-d2
	move.l	d1,d0
	beq.s	ErrorBEQ1
	lsl.l	#2,d0
	move.l	d0,BufferSize(a1)
	move.l	$4c(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	NotEnoughMemTxt(pc),a3
	move.l	a3,ErrorMsg(a1)
	lsl.l	#2,d1
	move.l	d1,BufferPointer(a1)
	beq.s	ErrorBEQ1
	move.l	d1,BufferPosPtr(a1)
	tst.l	BufferRemains(a1)
	beq.s	Extract

Create:
	move.l	ArgBuffer(a1),d1
	bsr	TestDir
	beq.s	ErrorBEQ1
	move.l	(ArgBuffer+4)(a1),d1
	move.l	d1,ErrorArg(a1)
	move.l	$f0(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	NoOutputTxt(pc),a3
	bsr.s	SetFault
ErrorBEQ1:
	beq.s	ErrorBEQ2
	move.l	d1,WriteFileHandle(a1)
	move.l	BufferSize(a1),BufferRemains(a1)
	move.l	ArgBuffer(a1),d1
	bsr	PackDir
	beq.s	CreateFailed
	move.l	(ArgBuffer+4)(a1),ErrorArg(a1)
	bsr	WriteBuffer
CreateFailed:
	move.l	d1,-(sp)
	move.l	WriteFileHandle(a1),d1
	bra.s	CloseAndExit

Extract:
	move.l	ArgBuffer(a1),d1
	move.l	d1,ErrorArg(a1)
	move.l	$ec(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	NoInputTxt(pc),a3
	bsr.s	SetFault
ErrorBEQ2:
	beq.s	Error
	move.l	d1,ReadFileHandle(a1)
	clr.l	BufferRemains(a1)
	move.l	(ArgBuffer+4)(a1),d1
	bsr	UnpackDir
	move.l	d1,-(sp)
	move.l	ReadFileHandle(a1),d1

CloseAndExit:
	move.l	$174(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	(sp)+,d1
	beq.s	Error
	bsr.s	FreeBuffer
	moveq.l	#0,d0
	rts

SetFault:
	movem.l	d1-d2,-(sp)
	move.l	a3,ErrorMsg(a1)
	move.l	-$44(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	d1,ErrorCode(a1)
	bne.s	SetFaultOk
	move.l	d1,ErrorMsg(a1)
SetFaultOk:
	movem.l	(sp)+,d1-d2
	tst.l	d1
	rts

Error:
	movem.l	ErrorMsg(a1),d1-d2
	lsr.l	#2,d1
	move.l	$128(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	ErrorCode(a1),d1
	beq.s	NoFault
	move.l	$1a0(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
NoFault:
	bsr.s	FreeBuffer
	moveq.l	#20,d0
NotFreeBuffer:
	rts

FreeBuffer:
	move.l	BufferPointer(a1),d1
	beq.s	NotFreeBuffer
	lsr.l	#2,d1
	move.l	$78(a2),a4
	moveq.l	#$c,d0
	jmp	(a5)

WriteBuffer:
	movem.l	BufferPointer(a1),d1-d2
	exg.l	d1,d2
	move.l	BufferSize(a1),d3
	move.l	d3,d0
	sub.l	BufferRemains(a1),d3
	beq.s	True
	move.l	d3,-(sp)
	movem.l	d0/d2,BufferRemains(a1)
	move.l	-$18(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	CantWriteTxt(pc),a3
	bsr.s	SetFault
	cmp.l	(sp)+,d1
	beq.s	True
False:
	moveq.l	#0,d1
Rts1:
	rts

WriteLoop:
	movem.l	d1/a3,-(sp)
	bsr.s	WriteBuffer
	movem.l	(sp)+,d1/a3
	beq.s	Rts1
Write:
	move.l	BufferRemains(a1),d0
	cmp.l	d0,d1
	bcc.s	WriteGoOn
	move.l	d1,d0
WriteGoOn:
	move.l	BufferPosPtr(a1),a4
	bsr.s	CopyMem
	move.l	a4,BufferPosPtr(a1)
	sub.l	d0,d1
	sub.l	d0,BufferRemains(a1)
	beq.s	WriteLoop
	bra.s	True

ReadLoop:
	movem.l	d1/a4,-(sp)
	bsr.s	ReadBuffer
	movem.l	(sp)+,d1/a4
	beq.s	False
	tst.l	d0
FalseBEQ1:
	beq.s	False
Read:
	move.l	BufferRemains(a1),d0
	cmp.l	d0,d1
	bcc.s	ReadGoOn
	move.l	d1,d0
ReadGoOn:
	move.l	BufferPosPtr(a1),a3
	bsr.s	CopyMem
	move.l	a3,BufferPosPtr(a1)
	sub.l	d0,d1
	sub.l	d0,BufferRemains(a1)
	beq.s	ReadLoop
	moveq.l	#-1,d0

True:
	moveq.l	#-1,d1
	rts

CopyMem:
	move.l	d0,d2
	bra.s	CopyMemEntry
CopyMemLoop:
	move.b	(a3)+,(a4)+
CopyMemEntry:
	dbra	d2,CopyMemLoop
	rts

ReadBuffer:
	move.l	ReadFileHandle(a1),d1
	move.l	BufferPointer(a1),d2
	move.l	BufferSize(a1),d3
	move.l	d2,BufferPosPtr(a1)
	move.l	-$c(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	CantReadTxt(pc),a3
	bsr	SetFault
	moveq.l	#-1,d0
	cmp.l	d0,d1
	beq.s	FalseBEQ1
	move.l	d1,BufferRemains(a1)
	exg.l	d0,d1
	tst.l	d1
	rts

TestDir:
	move.l	d1,ErrorArg(a1)
	move.l	$1b0(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	d1,-(sp)
	lea.l	-260(sp),sp
	lea.l	NoLockTxt(pc),a3
	movem.l	d1/a3,ErrorCode(a1)
	beq.s	TestDirError
	move.l	sp,d2
	move.l	-$30(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	d1,-(sp)
	lea.l	CantExamineTxt(pc),a3
	bsr	SetFault
	move.l	264(sp),d1
	move.l	$1b4(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	(sp)+,d1
	beq.s	TestDirError
	lea.l	IsFileNotDirTxt(pc),a3
	moveq.l	#0,d1
	movem.l	d1/a3,ErrorCode(a1)
	tst.l	4(sp)
	bmi.s	TestDirError
	moveq.l	#-1,d1
TestDirError:
	lea.l	264(sp),sp
	tst.l	d1
	rts

PrintIndent:
	move.l	IndentCount(a1),-(sp)
	bra.s	PrintIndentEntry
PrintIndentLoop:
	lea.l	IndentTxt(pc),a3
	move.l	a3,d1
	lsr.l	#2,d1
	move.l	$124(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
PrintIndentEntry:
	subq.l	#1,(sp)
	bne.s	PrintIndentLoop
	addq.l	#4,sp
	rts

PackDir:
	move.l	d1,ErrorArg(a1)
	move.l	$1b0(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	d1,-(sp)
	lea.l	-264(sp),sp
	lea.l	NoLockTxt(pc),a3
	movem.l	d1/a3,ErrorCode(a1)
	beq.l	PackDirErr
	move.l	sp,d2
	move.l	-$30(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	CantExamineTxt(pc),a3
	bsr	SetFault
	beq.l	PackDirErrNoCD
	move.l	(ArgBuffer+4)(a1),ErrorArg(a1)
	move.l	264(sp),d1
	move.l	-$40(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	d1,260(sp)
PackDirLoop:
	move.l	264(sp),d1
	move.l	sp,d2
	move.l	-$34(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	CantExNextTxt(pc),a3
	bsr	SetFault
	bne.s	PackDirExNextOk
	cmp.l	#232,ErrorCode(a1)
	bne.l	PackDirError
	clr.l	ErrorCode(a1)
	beq.s	PackDirErrorBEQ1
PackDirExNextOk:
	move.l	(ArgBuffer+4)(a1),ErrorArg(a1)
	moveq.l	#8,d1
	add.l	sp,d1
	moveq.l	#FileName,d2
	add.l	a1,d2
	lsr.l	#2,d2
	move.l	-$7c(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	FileName(a1),a3
	moveq.l	#1,d1
	add.b	(a3),d1
	tst.l	4(sp)
	bmi.s	PackFile
	bset.b	#7,(a3)
	bsr	Write
	beq.s	PackDirErrorBEQ1
	addq.l	#1,IndentCount(a1)
	bsr	PrintIndent
	lea.l	DirPackedTxt(pc),a3
	move.l	a3,d1
	lsr.l	#2,d1
	lea.l	FileName(a1),a3
	bclr.b	#7,(a3)
	move.l	a3,d2
	lsr.l	#2,d2
	move.l	d2,-(sp)
	move.l	$128(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	(sp)+,d1
	bsr	PackDir
	beq.s	PackDirErrorBEQ1
	subq.l	#1,IndentCount(a1)
	move.l	(ArgBuffer+4)(a1),ErrorArg(a1)
	lea.l	DirEndTxt(pc),a3
	moveq.l	#1,d1
	bsr	Write
	bne.l	PackDirLoop
	beq.s	PackDirErrorBEQ1
PackFile:
	bsr	Write
PackDirErrorBEQ1:
	beq.s	PackDirErrorBEQ2
	lea.l	124(sp),a3
	moveq.l	#4,d1
	bsr	Write
	beq.s	PackDirErrorBEQ2
	lea.l	119(sp),a3
	moveq.l	#1,d1
	bsr	Write
	beq.s	PackDirErrorBEQ2
	bsr	PrintIndent
	lea.l	PackingTxt(pc),a3
	move.l	a3,d1
	lsr.l	#2,d1
	moveq.l	#FileName,d2
	add.l	a1,d2
	lsr.l	#2,d2
	move.l	d2,-(sp)
	move.l	$128(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	(sp)+,d1
	move.l	d1,ErrorArg(a1)
	move.l	$ec(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	NoInputTxt(pc),a3
	bsr	SetFault
PackDirErrorBEQ2:
	beq.s	PackDirErrorBEQ3
	move.l	d1,ReadFileHandle(a1)
	move.l	124(sp),d2
	bra.s	PackFileEntry
PackFileLoop:
	move.l	d2,-(sp)
	bsr	WriteBuffer
	bne.s	PackFileWrBufOk
	clr.l	(sp)
	move.l	(ArgBuffer+4)(a1),ErrorArg(a1)
	bra.s	PackFileError2
PackFileWrBufOk:
	move.l	(sp)+,d2
PackFileEntry:
	move.l	BufferRemains(a1),d3
	cmp.l	d3,d2
	bcc.s	PackFileGoOn
	move.l	d2,d3
PackFileGoOn:
	movem.l	d2-d3,-(sp)
	move.l	ReadFileHandle(a1),d1
	move.l	BufferPosPtr(a1),d2
	move.l	-$c(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	CantReadTxt(pc),a3
	bsr	SetFault
	moveq.l	#0,d0
	movem.l	(sp)+,d2-d3
	cmp.l	d1,d3
	bne.s	PackFileError
	sub.l	d3,d2
	sub.l	d3,BufferRemains(a1)
	beq.s	PackFileLoop
	add.l	d3,BufferPosPtr(a1)
	moveq.l	#-1,d0
PackFileError:
	move.l	d0,-(sp)
PackFileError2:
	move.l	ReadFileHandle(a1),d1
	move.l	$174(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	(sp)+,d1
PackDirErrorBEQ3:
	beq.s	PackDirError
	lea.l	PackedTxt(pc),a3
	move.l	a3,d1
	lsr.l	#2,d1
	move.l	$124(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	bra	PackDirLoop
PackDirError:
	move.l	260(sp),d1
	move.l	-$40(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
PackDirErrNoCD:
	move.l	264(sp),d1
	move.l	$1b4(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
PackDirErr:
	lea.l	268(sp),sp
PackDirExit:
	moveq.l	#-1,d1
	tst.l	ErrorCode(a1)
	beq.s	PackDirOk
	moveq.l	#0,d1
PackDirOk:
	tst.l	d1
	rts

UnpackDir:
	bsr	TestDir
	beq.s	PackDirOk
	move.l	ErrorArg(a1),d1
	move.l	$1b0(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	movem.l	d0-d1,-(sp)
	lea.l	NoLockTxt(pc),a3
	movem.l	d1/a3,ErrorCode(a1)
	tst.l	d1
	beq.l	UnpackDirErrorNoCD
	move.l	-$40(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	d1,(sp)
	move.l	ArgBuffer(a1),ErrorArg(a1)
UnpackDirLoop:
	lea.l	FileName(a1),a4
	moveq.l	#1,d1
	bsr	Read
	beq.s	UnpackDirErrBEQ1
	clr.l	ErrorCode(a1)
	tst.l	d0
	beq.s	UnpackDirErrBEQ1
	lea.l	FileName(a1),a4
	cmp.b	#$80,(a4)
	beq.s	UnpackDirErrBEQ1
	moveq.l	#0,d1
	move.b	(a4)+,d1
	bclr.l	#7,d1
	bsr	Read
UnpackDirErrBEQ1:
	beq.s	UnpackDirErrBEQ2
	lea.l	FileIncompleteTxt(pc),a3
	movem.l	d0/a3,ErrorCode(a1)
	tst.l	d0
	beq.s	UnpackDirErrBEQ2
	lea.l	FileName(a1),a4
	move.l	a4,d1
	lsr.l	#2,d1
	move.l	d1,-(sp)
	move.l	d1,ErrorArg(a1)
	btst.b	#7,(a4)
	beq.l	UnpackFile
	bclr.b	#7,(a4)
	move.l	$1b0(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	tst.l	d1
	beq.s	UnpackDirMD
	move.l	d1,-(sp)
	lea.l	-260(sp),sp
	move.l	sp,d2
	move.l	-$30(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	d1,-(sp)
	move.l	264(sp),d1
	move.l	$1b4(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	movem.l	(sp)+,d1-d3
	lea.l	256(sp),sp
	tst.l	d1
	beq.s	UnpackDirMD
	lea.l	ExistsTxt(pc),a3
	tst.l	d3
	bpl.s	UnpackDirMDGoOn
UnpackDirMD:
	move.l	(sp),d1
	move.l	$1f4(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	CantCreateDirTxt(pc),a3
	bsr	SetFault
UnpackDirErrBEQ2:
	beq.s	UnpackDirErrBEQ3
	move.l	$1b4(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	CreatedTxt(pc),a3
UnpackDirMDGoOn:
	move.l	a3,-(sp)
	addq.l	#1,IndentCount(a1)
	bsr	PrintIndent
	lea.l	UnpackDirTxt(pc),a3
	move.l	a3,d1
	lsr.l	#2,d1
	move.l	(sp)+,d3
	lsr.l	#2,d3
	move.l	(sp),d2
	move.l	$128(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	(sp)+,d1
	bsr	UnpackDir
	beq.s	UnpackDirErrBEQ3
	subq.l	#1,IndentCount(a1)
	bra	UnpackDirLoop
UnpackFile:
	bsr	PrintIndent
	lea.l	PackingTxt(pc),a3
	move.l	a3,d1
	lsr.l	#2,d1
	move.l	(sp),d2
	move.l	$128(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	move.l	(sp)+,d1
	move.l	$f0(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	NoOutputTxt(pc),a3
	bsr	SetFault
UnpackDirErrBEQ3:
	beq.l	UnpackDirError
	move.l	d1,WriteFileHandle(a1)
	subq.l	#8,sp
	move.l	sp,a4
	moveq.l	#5,d1
	bsr	Read
	beq.s	UnpackFileRdError
	lea.l	FileIncompleteTxt(pc),a3
	movem.l	d0/a3,ErrorCode(a1)
	tst.l	d0
	beq.s	UnpackFileRdError
	movem.l	(sp)+,d2-d3
	rol.l	#8,d3
	moveq.l	#0,d1
	move.b	d3,d1
	move.l	d1,-(sp)
	bra.s	UnpackFileEntry
UnpackFileLoop:
	move.l	d2,-(sp)
	bsr	ReadBuffer
	bne.s	UnpackFileRdOk
UnpackFileRdError:
	clr.l	(sp)
	move.l	ArgBuffer(a1),ErrorArg(a1)
	bra.s	UnpackFileError2
UnpackFileRdOk:
	lea.l	FileIncompleteTxt(pc),a3
	movem.l	d0/a3,ErrorCode(a1)
	tst.l	d0
	beq.s	UnpackFileRdError
	move.l	(sp)+,d2
UnpackFileEntry:
	move.l	BufferRemains(a1),d3
	cmp.l	d3,d2
	bcc.s	UnpackFileGoOn
	move.l	d2,d3
UnpackFileGoOn:
	movem.l	d2-d3,-(sp)
	move.l	WriteFileHandle(a1),d1
	move.l	BufferPosPtr(a1),d2
	move.l	-$18(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	lea.l	CantWriteTxt(pc),a3
	bsr	SetFault
	moveq.l	#0,d0
	movem.l	(sp)+,d2-d3
	cmp.l	d1,d3
	bne.s	UnpackFileError
	sub.l	d3,BufferRemains(a1)
	add.l	d3,BufferPosPtr(a1)
	sub.l	d3,d2
	bne.s	UnpackFileLoop
	moveq.l	#-1,d0
UnpackFileError:
	move.l	d0,-(sp)
UnpackFileError2:
	move.l	WriteFileHandle(a1),d1
	move.l	$174(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	movem.l	(sp)+,d1/d2
	tst.l	d1
	beq.s	UnpackDirError
	tst.l	d2
	beq.s	NoProtectFlags
	lea.l	FileName(a1),a3
	moveq.l	#0,d0
	move.b	(a3)+,d0
	clr.b	0(a3,d0)
	move.l	a3,d1
	move.l	-$60(a2),a4
	moveq.l	#$10,d0
	jsr	(a5)
	lea.l	CantSetProtectTxt(pc),a3
	bsr	SetFault
	beq.s	UnpackDirError
NoProtectFlags:
	lea.l	UnpackedTxt(pc),a3
	move.l	a3,d1
	lsr.l	#2,d1
	move.l	$124(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	bra	UnpackDirLoop
UnpackDirError:
	move.l	(sp),d1
	move.l	-$40(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
UnpackDirErrorNoCD:
	movem.l	(sp)+,d0-d1
	move.l	$1b4(a2),a4
	moveq.l	#$c,d0
	jsr	(a5)
	bra	PackDirExit

	cnop	0,4
ArgsTxt:
	dc.b	43,'FROM/A,TO/A,CREATE/S,EXTRACT/S,BUF=BUFFER/K'

	cnop	0,4
BadArgsTxt:
	dc.b	14,'Bad arguments',10

	cnop	0,4
InvalidBufTxt:
	dc.b	26,'Invalid buffer argument !',10

	cnop	0,4
NotEnoughMemTxt:
	dc.b	31,'Not enough memory for buffer !',10

	cnop	0,4
NoOutputTxt:
	dc.b	27,'Can',39,'t open %S for output - '

	cnop	0,4
NoInputTxt:
	dc.b	26,'Can',39,'t open %S for input - '

	cnop	0,4
CantWriteTxt:
	dc.b	27,10,'Error while writing %S - '

	cnop	0,4
FileIncompleteTxt:
	dc.b	35,'Pack-File "%S" may be incomplete !',10

	cnop	0,4
NoLockTxt:
	dc.b	14,'Can',39,'t find %S',10

	cnop	0,4
CantExamineTxt:
	dc.b	20,'Can',39,'t examine "%S": '

	cnop	0,4
IsFileNotDirTxt:
	dc.b	34,'"%S" is a file, not a directory !',10

	cnop	0,4
CantExNextTxt:
	dc.b	40,'Can',39,'t examine the next directory entry: '

	cnop	0,4
DirPackedTxt:
	dc.b	19,'%S (dir)  [packed]',10

	cnop	0,4
PackingTxt:
	dc.b	8,'   %S..',0

	cnop	0,4
CantReadTxt:
	dc.b	26,10,'Error while reading %S - '

DirEndTxt:
	dc.b	$80

	cnop	0,4
PackedTxt:
	dc.b	7,'packed',10

	cnop	0,4
ExistsTxt:
	dc.b	6,'exists'

	cnop	0,4
CantCreateDirTxt:
	dc.b	29,'Can',39,'t create directory "%S": '

	cnop	0,4
CreatedTxt:
	dc.b	7,'created'

	cnop	0,4
UnpackDirTxt:
	dc.b	15,'%S (dir)  [%S]',10

	cnop	0,4
CantSetProtectTxt:
	dc.b	38,'Can',39,'t set protection flags for "%S" - '

	cnop	0,4
UnpackedTxt:
	dc.b	9,'unpacked',10

	cnop	0,4
IndentTxt:
	dc.b	5,'     '

	end

