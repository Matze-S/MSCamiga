; Copyright (C) 1990 by Matthias Schmidt


;
; HDDevice.asm
;
; OMTI HardDisk Driver -- Disk Version -- v1.53 (03:21 11-Aug-90)
;


	incdir	devpac:include.new/
	opt	o+,t+


	include	"exec/execbase.i"
	include	"exec/memory.i"
	include	"exec/nodes.i"
	include	"exec/resident.i"
	include	"libraries/configvars.i"
	include	"libraries/dos.i"
	include	"libraries/expansion.i"
	include	"libraries/expansionbase.i"

_LVOWrite	equ	-$30			; dos.library
_LVOOutput	equ	-$3c
_LVOFindResident equ	-$60			; exec.library
_LVOForbid	equ	-$84
_LVOPermit	equ	-$8a
_LVOAllocAbs	equ	-$cc
_LVOCloseLibrary equ	-$19e
_LVOOpenLibrary	equ	-$228
_LVOSumKick	equ	-$264
_LVOSetCurrentBinding	equ	-$84		; expansion.library

_AbsExecBase	equ	$4

	XREF	_InitHD
	XREF	_BeginHD
	XREF	_EndHD

VERSION		equ	1
REVISION	equ	53
PRIORITY	equ	-10

	SECTION	Install,CODE

Install:
	lea.l	Install_AlreadyTxt(pc),a2
	moveq.l	#10,d5
	move.l	(_AbsExecBase).w,a6
	lea.l	name,a1
	jsr	_LVOFindResident(a6)
	tst.l	d0
	bne.s	Install_Exit
	lea.l	(Install-4)(pc),a0
	clr.l	(a0)
	jsr	_LVOForbid(a6)
	lea.l	nextTag,a0
	move.l	KickTagPtr(a6),4(a0)
	beq.s	Install_NoOldTag
	bset.b	#7,4(a0)
Install_NoOldTag:
	move.l	a0,KickTagPtr(a6)
	jsr	_LVOSumKick(a6)
	move.l	d0,KickCheckSum(a6)
	jsr	_LVOPermit(a6)
	lea.l	Install_OkTxt(pc),a2
	moveq.l	#0,d5
Install_Exit:
	lea.l	dosName,a1
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	beq.s	Install_Return
	move.l	d0,a6
	jsr	_LVOOutput(a6)
	move.l	d0,d1
	beq.s	Install_CloseDos
	moveq.l	#0,d3
	move.b	(a2)+,d3
	move.l	a2,d2
	jsr	_LVOWrite(a6)
Install_CloseDos:
	move.l	a6,a1
	move.l	(_AbsExecBase).w,a6
	jsr	_LVOCloseLibrary(a6)
Install_Return:
	move.l	d5,d0
	rts

Install_AlreadyTxt:
	dc.b	36,'harddisk.device already installed!',13,10
Install_OkTxt:
	dc.b	74,'HardDisk.Device v1.53 installed.',13,10
	dc.b	'Copyright (C) 1990 by Matthias Schmidt',13,10
	ds.w	0

;-------------------------------------------------------------------------

	SECTION	ResidentCode,CODE_C

Resident:
	dc.w	RTC_MATCHWORD
	dc.l	Resident
	dc.l	Resident_End
	dc.b	RTF_COLDSTART
	dc.b	VERSION
	dc.b	NT_DEVICE
	dc.b	PRIORITY
	dc.l	name
	dc.l	idString
	dc.l	Init

nextTag:
	dc.l	Resident,0

name:
	dc.b	'harddisk.device',0
idString:
	dc.b	'HardDisk.Device v1.53 (11-Aug-90)',13,10,0
expName:
	EXPANSIONNAME
dosName:
	DOSNAME
	ds.w	0

diagArea:
	dc.b	DAC_CONFIGTIME,0
	dc.w	0,0,(bootPoint-diagArea),(name-diagArea),0,0
expansionRom:
	dc.b	ERTF_DIAGVALID,0,0,0
	dc.l	0,0,diagArea
currentBinding:
	dc.l	(expansionRom-cd_Rom)

bootPoint:
	lea.l	dosName(pc),a1
	jsr	_LVOFindResident(a6)
	tst.l	d0
	beq.s	bootPoint_Error
	move.l	d0,a0
	move.l	RT_INIT(a0),a0
	jsr	(a0)
bootPoint_Error:
	rts

Init:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	lea.l	(Resident-8)(pc),a1
	move.l	(Resident+RT_ENDSKIP)(pc),d0
	sub.l	a1,d0
	move.l	(_AbsExecBase).w,a6
	jsr	_LVOAllocAbs(a6)
	tst.l	d0
	beq.s	Init_Return
	lea.l	_BeginHD,a1
	subq.w	#8,a1
	lea.l	_EndHD,a0
	move.l	a0,d0
	sub.l	a1,d0
	jsr	_LVOAllocAbs(a6)
	tst.l	d0
	beq.s	Init_Return
	lea.l	expName(pc),a1
	moveq.l	#34,d0
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	beq.s	Init_Return
	move.l	d0,a6
	lea.l	currentBinding(pc),a0
	moveq.l	#4,d0
	jsr	_LVOSetCurrentBinding(a6)
	move.l	a6,a1
	move.l	eb_ExecBase(a1),a6
	jsr	_LVOCloseLibrary(a6)
	jsr	_InitHD
Init_Return:
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

Resident_End:

;-------------------------------------------------------------------------

