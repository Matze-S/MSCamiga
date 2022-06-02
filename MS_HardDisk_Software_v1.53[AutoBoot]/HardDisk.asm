; Copyright (C) 1990 by Matthias Schmidt


;
; HardDisk.asm
;
; OMTI harddisk driver -- v1.53 (03:24 11-Aug-90)
;


; devpac environment settings
	incdir	devpac:include.new/
	opt	a+,o+,p+,t+


	XDEF	_BeginHD			; start of code
	XDEF	_EndHD				; end of code (inclusive FFS)
	XDEF	_InitHD				; _InitHD() routine
	XDEF	_FFS				; FFS segment


;------------ included files ------------

	include	"devices/timer.i"
	include	"devices/trackdisk.i"
	include	"exec/devices.i"
	include	"exec/errors.i"
	include	"exec/initializers.i"
	include	"exec/io.i"
	include	"exec/libraries.i"
	include	"exec/lists.i"
	include	"exec/memory.i"
	include	"exec/nodes.i"
	include	"exec/ports.i"
	include	"exec/tasks.i"
	include	"hardware/custom.i"
	include	"libraries/configvars.i"
	include	"libraries/expansion.i"
	include	"libraries/expansionbase.i"
	include	"libraries/filehandler.i"
	include	"libraries/romboot_base.i"

	include "Harddisk.i"


;------------ constants ------------

; LVOs
_LVOMakeLibrary equ	-$54			; exec.library
_LVOAllocMem	equ	-$c6
_LVOFreeMem	equ	-$d2
_LVOAllocEntry	equ	-$de
_LVOFreeEntry	equ	-$e4
_LVOAddHead	equ	-$f0
_LVOEnqueue	equ	-$10e
_LVOAddTask	equ	-$11a
_LVORemTask	equ	-$120
_LVOFindTask	equ	-$126
_LVOWait	equ	-$13e
_LVOSignal	equ	-$144
_LVOAllocSignal equ	-$14a
_LVOFreeSignal	equ	-$150
_LVOPutMsg	equ	-$16e
_LVOGetMsg	equ	-$174
_LVOReplyMsg	equ	-$17a
_LVOCloseLibrary equ	-$19e
_LVOAddDevice	equ	-$1b0
_LVOOpenDevice	equ	-$1bc
_LVOCloseDevice	equ	-$1c2
_LVOSendIO	equ	-$1ce
_LVOAbortIO	equ	-$1e0
_LVOOpenLibrary equ	-$228
_LVOGetCurrentBinding equ -$8a			; expansion.library
_LVOMakeDosNode equ	-$90

_AbsExecBase	equ	$4			; the location to get SysBase
_custom		equ	$dff000			; base of the custom regs

; private constants
UNIT_TASK_PRI	equ	5
UNIT_STACK_SIZE equ	4096
WAIT_READY_TIME	equ	15	; wait time, if unit 0 is not ready at init

VERSION 	equ	1
REVISION	equ	53


;------------ code ------------

_BeginHD:

	;------	id string
idString:
	dc.b	13,'HardDisk v1.53 (11 Aug 1990)',13,10
	dc.b	'Copyright (C) 1990 by Matthias Schmidt',13,10,0

	;------	name of this device
name:
	HD_NAME

	;------	'expansion.library' for creating device node structures
expName:
	EXPANSIONNAME

	;------	'timer.device' for auto park and waiting for unit 0
timerName:
	TIMERNAME
	ds.w	0

	;------ data table for initializing HardDisk structure
dataTable:
	INITBYTE	LN_TYPE,NT_DEVICE
	INITBYTE	LIB_FLAGS,LIBF_SUMUSED!LIBF_CHANGED
	INITWORD	LIB_VERSION,VERSION
	INITWORD	LIB_REVISION,REVISION
	dc.l	0

;-------------------------------------------------------------------------
; a0 := segment list
; a6 := exec pointer

_InitHD:
	movem.l d0-d7/a0-a6,-(sp)

	moveq.l	#-1,d1
	move.l	d1,-(sp)
	lea.l	Open(pc),a0
	lea.l	Close(pc),a1
	lea.l	Expunge(pc),a2
	lea.l	Null(pc),a3
	lea.l	BeginIO(pc),a4
	lea.l	AbortIO(pc),a5
	movem.l	a0-a5,-(sp)
	move.l	sp,a0
	lea.l	dataTable(pc),a1
	sub.l	a2,a2
	moveq.l	#hd_SIZEOF,d0
	jsr	_LVOMakeLibrary(a6)
	lea.l	28(sp),sp
	tst.l	d0
	beq	Init_Error
	exg.l	d0,a6				; a6 := ptr to device
	lea.l	name(pc),a0
	lea.l	idString(pc),a1
	move.l	a0,LN_NAME(a6)
	move.l	a1,LIB_IDSTRING(a6)

	move.l	d0,hd_SysBase(a6)		; save SysBase

	lea.l	(OMTI_BASE).l,a4		; get omti's base address
	move.l	a4,hd_OmtiBase(a6)

	;------	get a local unit structure -- only for omti diagnostics...
	lea.l	(-hdu_SIZEOF)(sp),sp
	move.l	sp,a5

	bsr	Init_StRegs

	;------ initialize omti controller
	bsr	InitOmti

	;------	internal omti diagnostics (RAM and ROM test)...
	lea.l	Init_TestCmd(pc),a0
	bsr	SendOmtiCmd
	bsr	OmtiStatus
	lea.l	hdu_SIZEOF(sp),sp		; remove local unit structure
	tst.b	d0
	bne	Init_Error

	;------	add the device to the system
	move.l	a6,a5
	move.l	a5,a1
	move.l	hd_SysBase(a6),a6
	jsr	_LVOAddDevice(a6)

	;------	open the 'expansion.library'
	lea.l	expName(pc),a1
	moveq.l	#34,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,d4
	beq	Init_Error

	;------	get ptr to ConfigDev structure
	move.l	d4,a6
	moveq.l	#CurrentBinding_SIZEOF,d0
	sub.w	d0,sp
	move.l	sp,a0
	jsr	_LVOGetCurrentBinding(a6)
	move.l	a5,a6				; a6 := device ptr
	move.l	(sp),a2				; a2 := ptr to ConfigDev
	lea.l	CurrentBinding_SIZEOF(sp),sp
	move.l	a2,d0
	beq	Init_CloseExpLib

	moveq.l	#(HD_NUMUNITS-1),d2
	move.l	sp,d5				; d5 := saved sp

Init_Loop1:
	;------	initialize unit
	lea.l	-84(sp),sp			; local parmpkt/iob
	move.l	sp,a1				; a1 := iob
	moveq.l	#0,d1				; flags
	bsr	InitUnit
	tst.l	d0
	beq	Init_Continue1
	move.l	d0,a5				; a5 := unit ptr
	bsr	InitRegs
	move.l	sp,a1				; a1 := parmpkt
	moveq.l	#hdp_SIZEOF,d0
	mulu.w	(hdu_DriveParms+hddp_NumParts)(a5),d0
	sub.w	d0,sp
	move.l	sp,hdu_Parts(a5)
	bsr	ReadParts
	clr.l	hdu_Parts(a5)
	tst.b	d0
	bne	Init_ExpUnit
	move.l	a1,a3				; a3 := parmpkt
	move.w	(hdu_DriveParms+hddp_NumParts)(a5),d3
	bra	Init_Entry2

Init_Loop2:
	move.l	sp,a0
	addq.w	#hdp_Name,a0
	lea.l	name(pc),a1
	movem.l	a0-a1,(a3)
	moveq.l	#0,d6
	moveq.l	#16,d7
	move.w	#128,a0
	move.l	d6,a1
	movem.l	d2/d6-d7/a0-a1,8(a3)
	moveq.l	#0,d0
	move.b	(hdu_DriveParms+hddp_NumHeads)(a5),d0
	moveq.l	#1,d1
	move.b	(hdu_DriveParms+hddp_NumSecs)(a5),d7
	move.l	d1,a0
	move.l	a1,a4
	movem.l	d0-d1/d7/a0-a1/a4,28(a3)
	movem.w	(sp)+,d0/d6-d7
	move.l	#$7fffffff,a1
	movem.l	d0/d6-d7/a0-a1,52(a3)
	moveq.l	#-2,d0
	move.b	(sp),d1
	ext.w	d1
	ext.l	d1
	move.l	#$444f5300,d6
	btst.b	#HDPB_USE_FFS,1(sp)
	beq.s	Init_NoFFS1
	addq.w	#1,d6
Init_NoFFS1:
	movem.l	d0-d1/d6,72(a3)
	move.l	a3,a0
	exg.l	d4,a6
	jsr	_LVOMakeDosNode(a6)
	exg.l	d4,a6
	tst.l	d0
	beq.s	Init_Continue2
	move.l	d0,a4
	moveq.l	#BootNode_SIZEOF,d0
	moveq.l	#MEMF_PUBLIC,d1
	move.l	hd_SysBase(a6),a6
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	beq.s	Init_Continue2
	move.l	d0,a1
	move.l	a1,a0
	addq.w	#LN_TYPE,a0
	move.b	#NT_BOOTNODE,(a0)+
	move.b	(sp),(a0)+
	move.l	a2,(a0)+
	clr.w	(a0)+
	move.l	a4,(a0)
	btst.b	#HDPB_USE_FFS,1(sp)
	beq.s	Init_NoFFS2
	lea.l	_FFS(pc),a0
	move.l	a0,d0
	lsr.l	#2,d0
	move.l	d0,dn_SegList(a4)
	subq.l	#1,dn_GlobalVec(a4)		; GlobVec != 1 (:= -1)
Init_NoFFS2:
	move.l	d4,a0
	lea.l	eb_MountList(a0),a0
	jsr	_LVOEnqueue(a6)
Init_Continue2:
	move.l	hdu_Device(a5),a6
	addq.w	#(hdp_SIZEOF-hdp_BootPri),sp
Init_Entry2:
	dbf	d3,Init_Loop2

Init_ExpUnit:
	bsr	ExpungeUnit

Init_Continue1:
	move.l	d5,sp
	dbf	d2,Init_Loop1

Init_CloseExpLib:
	move.l	hd_SysBase(a6),a6
	move.l	d4,a1
	jsr	_LVOCloseLibrary(a6)

Init_Error:
	movem.l (sp)+,d0-d7/a0-a6
	rts

Init_TestCmd:
	dc.b	HDCMD_DIAG,0,0,0,0,0

;-------------------------------------------------------------------------
; d0 := unit
; d1 := flags
; a1 := iob
; a6 := device

Open:
	movem.l d2/a2,-(sp)

	;------ see if the unit number is in range
	move.b	#HDERR_BadUnitNum,IO_ERROR(a1)
	moveq.l #(HD_NUMUNITS-1),d2
	cmp.l	d0,d2
	bcs.s	Open_Return

	;------ see if the unit is already initialized
	move.l	d0,d2
	lsl.w	#2,d0
	lea.l	hd_Units(a6,d0.w),a2
	move.l	(a2),d0
	bne.s	Open_Ok

	;------ initialize the unit
	bsr.s	InitUnit
	move.l	d0,(a2)
	beq.s	Open_Return

Open_Ok:
	clr.b	IO_ERROR(a1)		; no error

	move.l	d0,a2			; a2 := pointer to unit
	move.l	a2,IO_UNIT(a1)		; iob.io_Unit := a2

	;------ mark the device and the unit that we're having
	;------ another opener
	addq.w	#1,LIB_OPENCNT(a6)
	addq.w	#1,UNIT_OPENCNT(a2)

Open_Return:
	movem.l (sp)+,d2/a2
	rts

;-------------------------------------------------------------------------
; a1 := iob
; a6 := device

Close:
	movem.l d1/a0/a5,-(sp)

	move.l	IO_UNIT(a1),a5

	;------ make sure the iob isn't used again
	moveq.l #-1,d0
	move.l	d0,IO_UNIT(a1)
	move.l	d0,IO_DEVICE(a1)

	;------ see if the unit is still in use
	subq.w	#1,UNIT_OPENCNT(a5)
	bne.s	Close_Device

	bsr	ExpungeUnit

Close_Device:
	moveq.l #0,d0			; set return code

	;------ see if the device is still in use
	subq.w	#1,LIB_OPENCNT(a6)

Close_Return:
	movem.l (sp)+,d1/a0/a5
	rts

;-------------------------------------------------------------------------
; a6 := device

Expunge:
Null:
	moveq.l	#0,d0
	rts

;-------------------------------------------------------------------------
; d1 := flags
; d2 := unit
; a1 := iob
; a6 := device

InitUnit:
	movem.l d1-d2/d6-d7/a0-a6,-(sp)

	;------ allocate memory for unit structure, task structure,
	;------	stack and the track buffer
	move.b	#HDERR_NoMem,IO_ERROR(a1)
	move.l	hd_SysBase(a6),a6
	lea.l	(initUnit_MemList-ML_NUMENTRIES)(pc),a0
	jsr	_LVOAllocEntry(a6)
	tst.l	d0
	bmi	InitUnit_Return	 	; error -- return 0

	move.l	40(sp),a6		; get back saved device pointer
	move.l	d0,a1			; a1 := pointer to MemList
	movem.l	ML_ME(a1),a0/a2-a5	; a0 := stack ptr, a2 := stack size,
					; a3 := task ptr, a5 := unit ptr

	;------	initialize unit structure
	move.b	#NT_MSGPORT,LN_TYPE(a5)	; unit.hdu_MsgPort.mp_Node.ln_Type
	move.b	#PA_IGNORE,MP_FLAGS(a5)	; unit.hdu_MsgPort.mp_Flags
	move.l	a3,MP_SIGTASK(a5)	; unit.hdu_MsgPort.mp_SigTask

	lea.l	(MP_MSGLIST+LH_TAIL)(a5),a4 ; unit.hdu_MsgPort.mp_MsgList
	clr.l	(a4)
	move.l	a4,-(a4)
	move.l	a4,LH_TAILPRED(a4)
	move.b	#NT_MESSAGE,LH_TYPE(a4)

	move.b	d2,hdu_UnitNum(a5)	; unit.hdu_UnitNum
	and.b	#1,d2
	lsl.b	#5,d2
	move.b	d2,hdu_LUN(a5)		; unit.hdu_LUN

	movem.l	a3/a6,hdu_Task(a5)	; hdu_Task & hdu_Device
	move.l	hd_OmtiBase(a6),hdu_OmtiBase(a5) ; unit.hdu_OmtiBase
	moveq.l	#-1,d0
	move.l	d0,hdu_OldSectorOffset(a5) ; set old sector offset
	move.b	d0,hdu_BufferHeadNum(a5) ; no valid data in the track buffer
	lea.l	Get_Sector(pc),a4	; set ptr to the Get_Sector() routine
	move.l	a4,hdu_GetSector(a5)

	;------	initialize task structure
	move.b	#NT_TASK,LN_TYPE(a3)	; task.tc_Node.ln_Type
	move.b	#UNIT_TASK_PRI,LN_PRI(a3) ; task.tc_Node.ln_Pri

	lea.l	0(a0,a2.w),a2		; task.tc_SPReg,task.tc_SPLower &
	move.l	a2,d0			; task.tc_SPUpper
	movem.l	d0/a0/a2,TC_SPREG(a3)

	lea.l	name(pc),a2		; task.tc_Node.ln_Name
	move.l	a2,LN_NAME(a3)

	lea.l	(TC_MEMENTRY+LH_TAIL)(a3),a0 ; task.tc_MemEntry
	clr.l	(a0)
	move.l	a0,-(a0)
	move.l	a0,LH_TAILPRED(a0)

	move.l	hd_SysBase(a6),a6
	jsr	_LVOAddHead(a6)

	;------	pass a pointer to the unit structure in the
	;------	TC_Userdata field of the task structure to the new task
	move.l	a5,TC_Userdata(a3)

	;------	set needed regs for using the harddisk functions
	bsr	InitRegs

	;------ initialize the unit
InitUnit_Wait:
	bset.b	#HDB_BUSY,LIB_FLAGS(a6)
	bne.s	InitUnit_Wait

	;------	recalibrate this unit
	bsr	Recalibrate
	tst.b	hdu_UnitNum(a5)			; don't try again, if
	bne.s	InitUnit_RecalibrateOk		; the unit # is > 0, or
	cmp.b	#4,d0				; if the return code is
	bne.s	InitUnit_RecalibrateOk		; not = 0 !

	movem.l	d0-d1/a0-a1/a6,-(sp)
	move.l	hd_SysBase(a6),a6
	bsr	Init_TimerIO
	moveq.l	#HDERR_NoTimerDevice,d2
	tst.b	d0
	bne.s	InitUnit_WaitReadyError
	moveq.l	#WAIT_READY_TIME,d0
	lea.l	hdu_TimerReq(a5),a1
	move.l	d0,(IOTV_TIME+TV_SECS)(a1)
	clr.l	(IOTV_TIME+TV_MICRO)(a1)
	move.w	#TR_ADDREQUEST,IO_COMMAND(a1)
	jsr	_LVOSendIO(a6)
InitUnit_WaitReadyLoop:
	lea.l	hdu_TimerPort(a5),a0
	jsr	_LVOGetMsg(a6)
	tst.l	d0
	bne.s	InitUnit_NoDrive
	move.l	hdu_Device(a5),a6
	bsr	Recalibrate
	move.l	hd_SysBase(a6),a6
	cmp.b	#4,d0
	beq.s	InitUnit_WaitReadyLoop
	move.b	d0,d2
	lea.l	hdu_TimerReq(a5),a1
	jsr	_LVOAbortIO(a6)
InitUnit_NoDrive:
	lea.l	hdu_TimerReq(a5),a1
	jsr	_LVOCloseDevice(a6)
	moveq.l	#0,d0
	move.b	(hdu_TimerPort+MP_SIGBIT)(a5),d0
	jsr	_LVOFreeSignal(a6)
InitUnit_WaitReadyError:
	movem.l	(sp)+,d0-d1/a0-a1/a6
	move.b	d2,d0

InitUnit_RecalibrateOk:
	tst.b	d0
	bne.s	InitUnit_Error

	;------ get the physical drive parameters
	bsr	GetDriveParms
	tst.b	d0
	bne.s	InitUnit_Error

	;------	set drive characteristics
	bsr	SendDriveChars
InitUnit_Error:
	bsr	UnbusyDevice
	move.l	hd_SysBase(a6),a6	; get SysBase
	move.l	20(sp),a1		; get back saved iob
	move.b	d0,IO_ERROR(a1)		; set io error
	beq.s	InitUnit_NoError

	btst.b	#HDB_IGNORE_OPEN_ERRORS,3(sp)
	bne.s	InitUnit_Ok

InitUnit_Exit:
	;------ if an error occurs, free the allocated
	;------ memory and leave with zero in d0
	move.l	hdu_Task(a5),a0		; get task pointer
	move.l	TC_MEMENTRY(a0),a0	; get MemEntry pointer
	jsr	_LVOFreeEntry(a6)	; free memory

InitUnit_Return:
	moveq.l #0,d0			; error occured -- return with zero
	bra.s	InitUnit_End

InitUnit_NoError:
	bset.b	#HDUB_DRIVECHARSSET,UNIT_FLAGS(a5)

	;------	allocate memory for the track buffer
	bsr	AllocTrackBuffer
	move.b	d0,IO_ERROR(a1)
	bne.s	InitUnit_Exit

InitUnit_Ok:
	move.l	hdu_Task(a5),a1
	lea.l	UnitTask(pc),a2
	move.l	d7,a3
	jsr	_LVOAddTask(a6)

	move.l	a5,d0			; ok. (return unit)

InitUnit_End:
	;------ return to caller
	movem.l (sp)+,d1-d2/d6-d7/a0-a6
	rts

initUnit_MemList:
	dc.w	3
	dc.l	MEMF_PUBLIC!MEMF_CLEAR,UNIT_STACK_SIZE
	dc.l	MEMF_PUBLIC!MEMF_CLEAR,TC_SIZE
	dc.l	MEMF_PUBLIC!MEMF_CLEAR,hdu_SIZEOF

;-------------------------------------------------------------------------
; a5 := unit
; a6 := device

ExpungeUnit:
	movem.l d0-d1/a0-a1/a6,-(sp)

	;------ clear out the unit pointer in the unit vector in the device
	clr.w	d0
	move.b	hdu_UnitNum(a5),d0
	lsl.w	#2,d0
	clr.l	hd_Units(a6,d0.w)

	;------	free the allocated memory for the track buffer
	move.l	hd_SysBase(a6),a6
	bsr	FreeTrackBuffer

	;------	free the possible memory for the Get_Sector() routine
	move.l	hdu_GetSectorSize(a5),d0
	beq.s	ExpungeUnit_Ok
	move.l	hdu_GetSector(a5),a1
	jsr	_LVOFreeMem(a6)

ExpungeUnit_Ok:
	;------ remove unit task
	move.l	hdu_Task(a5),a1
	jsr	_LVORemTask(a6)

	movem.l (sp)+,d0-d1/a0-a1/a6
	rts

;-------------------------------------------------------------------------

UnitTask:
	move.l	(_AbsExecBase).w,a6	; a6 := SysBase

	;------ get unit and device pointer
	sub.l	a1,a1
	jsr	_LVOFindTask(a6)
	move.l	d0,a2			; a2 := task
	move.l	TC_Userdata(a2),a5	; a5 := unit
	move.l	hdu_Device(a5),a3	; a3 := device

	;------ allocate a signal for the msgport
	moveq.l #-1,d0
	jsr	_LVOAllocSignal(a6)
	move.b	d0,MP_SIGBIT(a5)
	clr.b	MP_FLAGS(a5)		; mp_Flags := PA_SIGNAL

	moveq.l #0,d2			; make a signal mask
	bset.l	d0,d2

	;------------ main loop ------------

UnitTask_loop:
	btst.b	#HDUB_STOPPED,UNIT_FLAGS(a5)
	bne.s	UnitTask_wait		; unit is stopped

UnitTask_testMsg:
	;------ see if there's a msg (iob) to do
	lea.l	MP_MSGLIST(a5),a0
	cmp.l	LH_TAILPRED(a0),a0
	bne.s	UnitTask_doMsg

	;------ no msg -- wait !
UnitTask_wait:
	move.l	d2,d0
	jsr	_LVOWait(a6)
	bra.s	UnitTask_loop

	;------ a message was queued -- do it if possible
UnitTask_doMsg:
	;------ lock the device
	bset.b	#HDB_BUSY,LIB_FLAGS(a3)
	bne.s	UnitTask_wait		; device is already in use

	;------	see if the unit is already active (> it's not possible!)
	bset.b	#UNITB_ACTIVE,UNIT_FLAGS(a5)
	beq.s	UnitTask_ok
	bclr.b	#HDB_BUSY,LIB_FLAGS(a3)
	bra.s	UnitTask_loop

UnitTask_ok:
	move.l	a5,a0
	jsr	_LVOGetMsg(a6)
	move.l	d0,a1
	move.l	a3,a6
	bsr	PerformIO
	move.l	hd_SysBase(a6),a6

	bclr.b	#UNITB_ACTIVE,UNIT_FLAGS(a5)
	bclr.b	#UNITB_INTASK,UNIT_FLAGS(a5)
	bra.s	UnitTask_loop

;-------------------------------------------------------------------------

cmdTable:
	dc.w	(Invalid-cmdTable)		; $00000001
	dc.w	(_Reset-cmdTable)		; $00000002
	dc.w	(Read-cmdTable)			; $00000004
	dc.w	(Write-cmdTable)		; $00000008
	dc.w	(Update-cmdTable)		; $00000010
	dc.w	(Clear-cmdTable)		; $00000020
	dc.w	(_Stop-cmdTable)		; $00000040
	dc.w	(Start-cmdTable)		; $00000080
	dc.w	(Flush-cmdTable)		; $00000100
	dc.w	(Motor-cmdTable)		; $00000200
	dc.w	(Seek-cmdTable)			; $00000400
	dc.w	(Format-cmdTable)		; $00000800
	dc.w	(Remove-cmdTable)		; $00001000
	dc.w	(ChangeNum-cmdTable)		; $00002000
	dc.w	(ChangeState-cmdTable)		; $00004000
	dc.w	(ProtStatus-cmdTable)		; $00008000
	dc.w	(RawRead-cmdTable)		; $00010000
	dc.w	(RawWrite-cmdTable)		; $00020000
	dc.w	(GetDriveType-cmdTable)		; $00040000
	dc.w	(GetNumTracks-cmdTable)		; $00080000
	dc.w	(AddChangeInt-cmdTable)		; $00100000
	dc.w	(RemChangeInt-cmdTable)		; $00200000
	dc.w	(ChangeProt-cmdTable)		; $00400000
	dc.w	(Park-cmdTable)			; $00800000
	dc.w	(SetDriveParms-cmdTable)	; $01000000
	dc.w	(_ReadParts-cmdTable)		; $02000000
	dc.w	(Busy-cmdTable)			; $04000000
	dc.w	(SendCmd-cmdTable)		; $08000000
	dc.w	(SendData-cmdTable)		; $10000000
	dc.w	(GetData-cmdTable)		; $20000000
	dc.w	(GetSense-cmdTable)		; $40000000
cmdTable_End:

; the immediate commands are:
; CMD_INVALID,,CMD_STOP,CMD_START,HD_REMOVE,HD_CHANGENUM,
; HD_CHANGESTATE,HD_GETDRIVETYPE,HD_ADDCHANGEINT,HD_REMCHANGEINT,
; HD_BUSY,HD_SENDCMD,HD_SENDDATA,HD_GETDATA,HD_GETSENSE

IMMEDIATES	equ	$7c3470c1

;-------------------------------------------------------------------------
; a1 := iob
; a6 := device

BeginIO:
	movem.l d1/a0-a2/a5-a6,-(sp)

	move.l	IO_UNIT(a1),a5		; a5 := unit

	;------ see if the io command is within range
	move.b	#IOERR_NOCMD,IO_ERROR(a1)
	move.w	IO_COMMAND(a1),d0
	bclr.l	#TDB_EXTCOM,d0
	cmp.w	#HD_LASTCOMM,d0
	bcc.s	BeginIO_Return

	;------ disable interrupts
	move.l	hd_SysBase(a6),a2
	lea.l	(_custom+intena).l,a0
	move.w	#$4000,(a0)
	addq.b	#1,IDNestCnt(a2)

	;------ process immediate commands
	move.l	#IMMEDIATES,d1
	btst.l	d0,d1
	bne.s	BeginIO_Immediate

	;------ queue the msg (iob) to do it later, when the unit
	;------ and the device aren't still in use
BeginIO_Queue:
	bset.b	#UNITB_INTASK,UNIT_FLAGS(a5)
	bclr.b	#IOB_QUICK,IO_FLAGS(a1)

	;------ enable interrupts
	subq.b	#1,IDNestCnt(a2)
	bge.s	Begin_IO_Ok1
	move.w	#$c000,(a0)
Begin_IO_Ok1:

	move.b	#NT_MESSAGE,LN_TYPE(a1)
	move.l	a5,a0
	move.l	a2,a6
	jsr	_LVOPutMsg(a6)
	bra.s	BeginIO_Return

BeginIO_Immediate:
	;------ enable interrupts
	subq.b	#1,IDNestCnt(a2)
	bge.s	Begin_IO_Ok2
	move.w	#$c000,(a0)
Begin_IO_Ok2:

	;------ do the io request
	bsr.s	PerformIO

BeginIO_Return:
	movem.l (sp)+,d1/a0-a2/a5-a6
	moveq.l #0,d0
	rts

;-------------------------------------------------------------------------
; a1 := iob
; a5 := unit
; a6 := device

PerformIO:
	movem.l d0-d7/a0-a6,-(sp)

	;------	clear the result fields of the iob (error and actual)
	clr.b	IO_ERROR(a1)
	clr.l	IO_ACTUAL(a1)

	;------	save a pointer to the iob
	move.l	a1,hdu_IORequest(a5)

	;------	get io function address
	move.w	IO_COMMAND(a1),d0
	lsl.w	#1,d0
	lea.l	cmdTable(pc),a0
	add.w	0(a0,d0.w),a0

	;------	set registers needed for calling harddisk functions
	bsr	InitRegs

	;------	call io function
	jsr	(a0)

	movem.l (sp)+,d0-d7/a0-a6
	rts

;-------------------------------------------------------------------------
; a5 := unit
; a6 := device

TermIO:
	;------ the device isn't still busy
	move.l	hdu_IORequest(a5),a1
	btst.b	#IOB_QUICK,IO_FLAGS(a1)
	bne.s	TermIO_NoUnBusy
	bsr.s	UnbusyDevice

TermIO_NoUnBusy:
	move.l	hdu_IORequest(a5),a1

	;------ if the quick bit is still set then we don't need to
	;------ reply the msg -- just to return to the user
	btst.b	#IOB_QUICK,IO_FLAGS(a1)
	bne.s	TermIO_Return

	move.l	hd_SysBase(a6),a6
	jsr	_LVOReplyMsg(a6)

TermIO_Return:
	rts

;-------------------------------------------------------------------------
; a1 := iob
; a6 := device

AbortIO:
	;------	function is not implemented yet ( -- and not needed !)
	move.b	#IOERR_NOCMD,IO_ERROR(a1)
	moveq.l	#0,d0
	rts

;-------------------------------------------------------------------------

	;------ kick the unit task to stop Wait()ing...
	;------	(a1 := unit pointer, a6 := device pointer)
KickUnitTask:
	move.l	a6,-(sp)
	moveq.l #0,d0
	move.b	MP_SIGBIT(a1),d1
	bset.l	d1,d0
	move.l	hdu_Task(a1),a1
	move.l	hd_SysBase(a6),a6
	jsr	_LVOSignal(a6)
	move.l	(sp)+,a6
	rts

	;------ clear the busy flag in the device and
	;------	signal the unit tasks, which msg list contains
	;------	some msgs, that the device isn't still busy
	;------	and they can attempt to perform the msgs.
	;------	(a6 := device pointer)
UnbusyDevice:
	movem.l	d0-d2/a0-a2,-(sp)
	bclr.b	#HDB_BUSY,LIB_FLAGS(a6)
	lea.l	hd_Units(a6),a2
	moveq.l #(HD_NUMUNITS-1),d2
UnbusyDevice_Loop:
	move.l	(a2)+,d0
	beq.s	UnbusyDevice_Ok
	move.l	d0,a1
	lea.l	MP_MSGLIST(a1),a0
	cmp.l	LH_TAILPRED(a0),a0
	beq.s	UnbusyDevice_Ok
	bsr.s	KickUnitTask
UnbusyDevice_Ok:
	dbf	d2,UnbusyDevice_Loop
	movem.l	(sp)+,d0-d2/a0-a2
	rts

	;------	allocate memory for the track buffer
AllocTrackBuffer:
	movem.l	d1/a0-a1,-(sp)
	bsr.s	FreeTrackBuffer
	moveq.l	#0,d0
	move.b	(hdu_DriveParms+hddp_NumSecs)(a5),d0
	lsl.w	d6,d0
	move.l	d0,hdu_TrackBufferSize(a5)
	moveq.l	#MEMF_PUBLIC,d1
	jsr	_LVOAllocMem(a6)
	moveq.l	#HDERR_NoMem,d1
	move.l	d0,hdu_TrackBuffer(a5)
	beq.s	AllocTrackBuffer_Return
	moveq.l	#0,d1
AllocTrackBuffer_Return:
	move.l	d1,d0
	movem.l	(sp)+,d1/a0-a1
	rts

	;------	free the memory for the allocated track buffer
FreeTrackBuffer:
	movem.l	d0-d1/a0-a1,-(sp)
	move.l	hdu_TrackBuffer(a5),d0
	beq.s	FreeTrackBuffer_Ok
	move.l	d0,a1
	move.l	hdu_TrackBufferSize(a5),d0
	jsr	_LVOFreeMem(a6)
FreeTrackBuffer_Ok:
	moveq.l	#-1,d0
	move.b	d0,hdu_BufferHeadNum(a5)
	clr.l	hdu_TrackBuffer(a5)
	clr.l	hdu_TrackBufferSize(a5)
	movem.l	(sp)+,d0-d1/a0-a1
	rts

;-------------------------------------------------------------------------
;
; sub-routines
;
;-------------------------------------------------------------------------

	;------	init registers for using the harddisk functions
	;------	(a5 := unit pointer)
InitRegs:
	move.l	hdu_OmtiBase(a5),a4
	move.l	hdu_Device(a5),a6
	moveq.l	#HD_SECSHIFT,d6
Init_StRegs:
	moveq.l	#OMTIB_REQ,d7
	lea.l	OMTI_STATUS(a4),a3
	rts

	;------	fill the OmtiCmd structure with standard contents
FillCmd:
	lea.l	(hdu_OmtiCmd+hdc_Count)(a5),a0
	move.w	#$0101,(a0)
	move.w	d7,-(a0)
	move.b	hdu_LUN(a5),-(a0)
	rts

	;------	initialize omti controller
InitOmti:
	clr.b	(a3)			; a3 := OMTI_STATUS = OMTI_RESET
	clr.b	OMTI_MASK(a4)
	moveq.l	#-1,d0
InitOmti_WaitLoop:
	dbf	d0,InitOmti_WaitLoop
	rts

	;------	recalibrate the drive
Recalibrate:
	bsr.s	FillCmd
	move.b	#HDCMD_RECALIBRATE,-(a0)
	bsr	SendOmtiCmd
	bra	OmtiStatus

	;------	read drive parameters
GetDriveParms:
	lea.l	(-HDDP_MAXNUMPARTS*hdp_SIZEOF)(sp),sp
	bsr.s	FillCmd
	move.b	#HDCMD_READ,-(a0)
	bsr	SendOmtiCmd

GetDriveParms_Loop1:
	btst.b	d7,(a3)
	beq.s	GetDriveParms_Loop1
	btst.b	#OMTIB_CD,(a3)
	bne.s	GetDriveParms_CD
	lea.l	hdu_DriveParms(a5),a0	; read drive parameters
	moveq.l	#hddp_SIZEOF,d0
	bsr	ReadData
	move.l	sp,a0
	move.w	#(HDDP_MAXNUMPARTS*hdp_SIZEOF),d0
	bsr	ReadData
	move.w	#(HD_SECTOR-hddp_SIZEOF-HDDP_MAXNUMPARTS*hdp_SIZEOF-1),d0
GetDriveParms_Loop2:			; skip the rest of the sector
	btst.b	d7,(a3)
	beq.s	GetDriveParms_Loop2
	move.b	(a4),d1
	dbf	d0,GetDriveParms_Loop2
GetDriveParms_CD:
	bsr	OmtiStatus
	tst.b	d0
	bne.s	GetDriveParms_Error

	moveq.l	#0,d1
	moveq.l	#hdp_SIZEOF,d0
	mulu.w	(hdu_DriveParms+hddp_NumParts)(a5),d0
	lsr.w	#1,d0
	move.l	sp,a0
	bra.s	GetDriveParms_Entry3
GetDriveParms_Loop3:
	add.w	(a0)+,d1
GetDriveParms_Entry3:
	dbf	d0,GetDriveParms_Loop3
	lea.l	(hdu_DriveParms+hddp_CheckSum)(a5),a0
	moveq.l	#(hddp_SIZEOF/2-3),d0
GetDriveParms_Loop4:
	add.w	(a0)+,d1
	dbf	d0,GetDriveParms_Loop4
	moveq.l	#HDERR_NoDriveParms,d0
	cmp.w	#HDDP_CHECKSUM,d1
	bne.s	GetDriveParms_Error

	moveq.l	#0,d0
GetDriveParms_Error:
	lea.l	(HDDP_MAXNUMPARTS*hdp_SIZEOF)(sp),sp
SendDriveChars_Error:
	rts

	;------	send drive characteristics
SendDriveChars:
	bsr	Set_GetSector
	tst.b	d0
	bne.s	SendDriveChars_Error
	move.l	sp,a0
	lea.l	(-hddc_SIZEOF)(sp),sp
	move.b	d7,-(a0)
	moveq.l	#3,d0
SendDriveChars_Loop:
	move.b	(hdu_DriveParms+hddp_RedWriteCurrent)(a5,d0.w),-(a0)
	dbf	d0,SendDriveChars_Loop
	move.b	(hdu_DriveParms+hddp_NumHeads)(a5),-(a0)
	move.w	(hdu_DriveParms+hddp_NumCyls)(a5),(sp)
	bsr	FillCmd
	move.b	#HDCMD_SET_DRIVE_CHARS,-(a0)
	bsr.s	SendOmtiCmd
	move.l	sp,a0
	moveq.l	#hddc_SIZEOF,d0
	bsr.s	WriteData
	lea.l	hddc_SIZEOF(sp),sp
	bra.s	OmtiStatus

	;------ calculate something in the unit structure
	;------ (d0 := sector offset)
CalcCHS:
	moveq.l #0,d1
	move.b	(hdu_DriveParms+hddp_NumSecs)(a5),d1
	divu.w	d1,d0
	swap	d0
	and.b	#%00111111,d0
	move.b	d0,hdu_Sector(a5)
	clr.w	d0
	swap	d0
	move.b	(hdu_DriveParms+hddp_NumHeads)(a5),d1
	divu.w	d1,d0
	move.w	d0,d1
	swap	d0
	move.w	d1,hdu_Cylinder(a5)
	and.b	#%00011111,d0
	move.b	d0,hdu_Head(a5)
	lea.l	(hdu_OmtiCmd+hdc_Control)(a5),a0
	move.b	(hdu_DriveParms+hddp_StepRate)(a5),(a0)
	move.b	#1,-(a0)
	move.b	d1,-(a0)
	clr.b	d1
	lsr.w	#2,d1
	or.b	hdu_Sector(a5),d1
	move.b	d1,-(a0)
	clr.b	d1
	lsr.w	#1,d1
	or.b	d0,d1
	or.b	hdu_LUN(a5),d1
	move.b	d1,-(a0)
	rts

	;------ send command to the omti
	;------	(a0 := pointer to a OmtiCmd structure)
SendOmtiCmd:
	moveq.l #OMTIB_BSY,d1
SendOmtiCmd_WaitBusy:
	btst.b	d1,(a3)
	bne.s	SendOmtiCmd_WaitBusy

	clr.b	OMTI_SELECT(a4)
SendOmtiCmd_WaitSelect:
	btst.b	d1,(a3)
	beq.s	SendOmtiCmd_WaitSelect

	moveq.l #(hdc_SIZEOF-1),d0

	;------ send data to the omti (WriteData())
	;------	(d0 := number of bytes, a0 := ptr to data)
WriteData_Loop:
	btst.b	d7,(a3)
	beq.s	WriteData_Loop
	move.b	(a0)+,(a4)
WriteData:
	dbf	d0,WriteData_Loop
	rts

	;------ receive data from the omti (ReadData())
	;------	(d0 := number of bytes, a0 := ptr to memory)
ReadData_Loop:
	btst.b	d7,(a3)
	beq.s	ReadData_Loop
	move.b	(a4),(a0)+
ReadData:
	dbf	d0,ReadData_Loop
	rts

	;------ get omti status
OmtiStatus:
	btst.b	d7,(a3)
	beq.s	OmtiStatus
	moveq.l	#0,d0
	move.b	(a4),d0
	and.b	#2,d0
	beq.s	OmtiStatus_Ok

	lea.l	(hdu_OmtiCmd+hdc_Count)(a5),a0
	and.w	#%00100000,(a0)		; hdc_Control &= 0x20
	move.w	d7,-(a0)
	move.b	hdu_LUN(a5),-(a0)
	move.b	#HDCMD_SENSE,-(a0)
	bsr.s	SendOmtiCmd

	lea.l	hdu_OmtiSense(a5),a0
	moveq.l #4,d0
	bsr.s	ReadData

OmtiStatus_WaitLoop:
	btst.b	d7,(a3)
	beq.s	OmtiStatus_WaitLoop
	move.b	(a4),d0

	moveq.l	#0,d0
	move.b	hdu_OmtiSense(a5),d0
OmtiStatus_Ok:
	rts

	;------ test IO_OFFSET and IO_LENGTH for correct offset and length
	;------	(a1 := iob)
TestSize:
	move.w	(IO_OFFSET+2)(a1),d0
	or.w	(IO_LENGTH+2)(a1),d0
	and.w	#(HD_SECTOR-1),d0
	beq.s	TestSize_Ok
	move.b	#IOERR_BADLENGTH,IO_ERROR(a1)
TestSize_Ok:
	rts

	;------	copy a sector from one place to another
	;------	(a0 := source, a2 := target)
CopySector:
	movem.l	d0-d7/a0-a6,-(sp)
	movem.l (a0)+,d0-d7/a1/a3-a6
	movem.l d0-d7/a1/a3-a6,(a2)
	movem.l (a0)+,d0-d7/a1/a3-a6
	movem.l d0-d7/a1/a3-a6,52(a2)
	movem.l (a0)+,d0-d7/a1/a3-a6
	movem.l d0-d7/a1/a3-a6,104(a2)
	movem.l (a0)+,d0-d7/a1/a3-a6
	movem.l d0-d7/a1/a3-a6,156(a2)
	movem.l (a0)+,d0-d7/a1/a3-a6
	movem.l d0-d7/a1/a3-a6,208(a2)
	movem.l (a0)+,d0-d7/a1/a3-a6
	movem.l d0-d7/a1/a3-a6,260(a2)
	movem.l (a0)+,d0-d7/a1/a3-a6
	movem.l d0-d7/a1/a3-a6,312(a2)
	movem.l (a0)+,d0-d7/a1/a3-a6
	movem.l d0-d7/a1/a3-a6,364(a2)
	movem.l (a0)+,d0-d7/a1/a3-a6
	movem.l d0-d7/a1/a3-a6,416(a2)
	movem.l (a0)+,d0-d7/a1/a3-a4
	movem.l d0-d7/a1/a3-a4,468(a2)
	movem.l	(sp)+,d0-d7/a0-a6
	rts

	;------	look for the specified sector in the track buffer
IfSecInBuf:
	moveq.l	#0,d0
	move.b	hdu_Head(a5),d1
	cmp.b	hdu_BufferHeadNum(a5),d1
	bne.s	IfSecInBuf_Return
	move.w	hdu_Cylinder(a5),d1
	cmp.w	hdu_BufferCylNum(a5),d1
	bne.s	IfSecInBuf_Return
	moveq.l	#-1,d0
IfSecInBuf_Return:
WriteDriveParms_Error:
	rts

	;------	write the drive parameters to the harddisk
WriteDriveParms:
	moveq.l	#HDERR_NoTrackBuffer,d0
	tst.l	hdu_TrackBuffer(a5)
	beq.s	WriteDriveParms_Error
	moveq.l	#-1,d0
	move.b	d0,hdu_BufferHeadNum(a5)
	bsr	FillCmd
	move.b	#HDCMD_READ,-(a0)
	bsr	SendOmtiCmd
WriteDriveParms_Loop1:
	btst.b	d7,(a3)
	beq.s	WriteDriveParms_Loop1
	btst.b	#OMTIB_CD,(a3)
	bne.s	WriteDriveParms_CD1
	move.l	hdu_TrackBuffer(a5),a0
	move.w	#HD_SECTOR,d0
	bsr	ReadData
WriteDriveParms_CD1:
	bsr	OmtiStatus
	tst.b	d0
	bne.s	WriteDriveParms_Error
	move.l	hdu_TrackBuffer(a5),a1
	addq.w	#hddp_NumCyls,a1
	lea.l	(hdu_DriveParms+hddp_NumCyls)(a5),a0
	moveq.l	#(hddp_SIZEOF/2-4),d0
WriteDriveParms_Loop2:
	move.w	(a0)+,(a1)+
	dbf	d0,WriteDriveParms_Loop2
	moveq.l	#hdp_SIZEOF,d1
	mulu.w	(hdu_DriveParms+hddp_NumParts)(a5),d1
	move.l	hdu_Parts(a5),d0
	beq.s	WriteDriveParms_NoParts
	move.l	d0,a0
	move.w	d1,d0
	bra.s	WriteDriveParms_Entry3
WriteDriveParms_Loop3:
	move.b	(a0)+,(a1)+
WriteDriveParms_Entry3:
	dbf	d0,WriteDriveParms_Loop3
	bra.s	WriteDriveParms_PartsCopied
WriteDriveParms_NoParts:
	add.w	d1,a1
WriteDriveParms_PartsCopied:
	lsr.w	#1,d1
	addq.w	#(hddp_SIZEOF/2-4),d1
	moveq.l	#0,d0
WriteDriveParms_Loop5:
	add.w	-(a1),d0
	dbf	d1,WriteDriveParms_Loop5
	neg.w	d0
	add.w	#HDDP_CHECKSUM,d0
	move.w	d0,-(a1)
	bsr	FillCmd
	move.b	#HDCMD_WRITE,-(a0)
	bsr	SendOmtiCmd
WriteDriveParms_Loop6:
	btst.b	d7,(a3)
	beq.s	WriteDriveParms_Loop6
	btst.b	#OMTIB_CD,(a3)
	bne.s	WriteDriveParms_CD2
	move.l	hdu_TrackBuffer(a5),a0
	move.w	#HD_SECTOR,d0
	bsr	WriteData
WriteDriveParms_CD2:
	bra	OmtiStatus

	;------	read the partition structures (hdu_Parts := ptr to mem)
ReadParts:
	bsr	FillCmd
	move.b	#HDCMD_READ,-(a0)
	bsr	SendOmtiCmd
ReadParts_Loop1:
	btst.b	d7,(a3)
	beq.s	ReadParts_Loop1
	btst.b	#OMTIB_CD,(a3)
	bne.s	ReadParts_CD
	moveq.l	#(hddp_SIZEOF-1),d0	; skip drive parameters
ReadParts_Loop2:
	btst.b	d7,(a3)
	beq.s	ReadParts_Loop2
	move.b	(a4),d1
	dbf	d0,ReadParts_Loop2
	move.l	hdu_Parts(a5),a0
	moveq.l	#hdp_SIZEOF,d0
	mulu.w	(hdu_DriveParms+hddp_NumParts)(a5),d0
	move.w	#(HD_SECTOR-hddp_SIZEOF-1),d1
	sub.w	d0,d1
	bsr	ReadData
ReadParts_Loop3:			; skip rest of the sector
	btst.b	d7,(a3)
	beq.s	ReadParts_Loop3
	move.b	(a4),d0
	dbf	d1,ReadParts_Loop3
ReadParts_CD:
	bra	OmtiStatus

Get_Sector:
	move.l	a2,a0
	move.w	#HD_SECTOR,d0
	bsr	ReadData
	move.l	a0,a2
	rts

Get_SectorHalf:
	moveq.l	#31,d0
Get_SectorHalf_Loop:
	btst.b	d7,(a3)
	beq.s	Get_SectorHalf_Loop
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
	move.b	(a4),(a2)+
Get_Sector_move:
	move.b	(a4),(a2)+
	dbf	d0,Get_SectorHalf_Loop
Get_Sector_rts:
	rts

Set_GetSector:
	movem.l	d1/a0-a2/a6,-(sp)
	move.l	hd_SysBase(a6),a6
	move.l	hdu_GetSectorSize(a5),d0
	beq.s	Set_GetSector_Ok1
	move.l	hdu_GetSector(a5),a1
	jsr	_LVOFreeMem(a6)
	clr.l	hdu_GetSectorSize(a5)
Set_GetSector_Ok1:
	lea.l	Get_SectorHalf(pc),a0
	btst.b	#HDDPB_READHALF,(hdu_DriveParms+hddp_Flags)(a5)
	bne.s	Set_GetSector_Ok2
	lea.l	Get_Sector(pc),a0
	btst.b	#HDDPB_READBLIND,(hdu_DriveParms+hddp_Flags)(a5)
	beq.s	Set_GetSector_Ok2
	move.w	#1026,a2
	move.l	a2,d0
	moveq.l	#MEMF_PUBLIC,d1
	jsr	_LVOAllocMem(a6)
	move.l	d0,a0
	moveq.l	#HDERR_NoMem,d0
	move.l	a0,d1
	beq.s	Set_GetSector_Return
	move.l	a2,hdu_GetSectorSize(a5)
	move.w	#511,d0
Set_GetSector_Loop:
	move.w	Get_Sector_move(pc),(a0)+
	dbf	d0,Set_GetSector_Loop
	move.w	Get_Sector_rts(pc),(a0)
	move.l	d1,a0
Set_GetSector_Ok2:
	move.l	a0,hdu_GetSector(a5)
	moveq.l	#0,d0
Set_GetSector_Return:
	movem.l	(sp)+,d1/a0-a2/a6
	rts

;-------------------------------------------------------------------------

	;------	initialize the timerequest and open the timer.device
	;------	(a5 := ptr to unit, a6 := SysBase)
Init_TimerIO:
	move.b	#NT_MSGPORT,(hdu_TimerPort+LN_TYPE)(a5)
	clr.b	(hdu_TimerPort+MP_FLAGS)(a5)		; PA_SIGNAL
	moveq.l	#-1,d0
	jsr	_LVOAllocSignal(a6)
	move.b	d0,(hdu_TimerPort+MP_SIGBIT)(a5)
	sub.l	a1,a1
	jsr	_LVOFindTask(a6)
	move.l	d0,(hdu_TimerPort+MP_SIGTASK)(a5)
	lea.l	(hdu_TimerPort+MP_MSGLIST+LH_TAIL)(a5),a0
	clr.l	(a0)
	move.l	a0,-(a0)
	move.l	a0,LH_TAILPRED(a0)
	move.b	#NT_REPLYMSG,LH_TYPE(a0)
	move.b	#NT_MESSAGE,(hdu_TimerReq+LN_TYPE)(a5)
	lea.l	name(pc),a1
	move.l	a1,(hdu_TimerReq+LN_NAME)(a5)
	lea.l	hdu_TimerPort(a5),a0
	move.l	a1,LN_NAME(a0)
	lea.l	hdu_TimerReq(a5),a1
	move.l	a0,MN_REPLYPORT(a1)
	move.w	#IOTV_SIZE,MN_LENGTH(a5)
	lea.l	timerName(pc),a0
	moveq.l	#UNIT_VBLANK,d0
	moveq.l	#0,d1
	jmp	_LVOOpenDevice(a6)

;=========================================================================
;
; here begin the device functions that implement the device commands
;
;	d7 := OMTIB_REQ
;	a0 := pointer to function
;	a1 := io request block
;	a3 := pointer to OMTI_STATUS
;	a4 := omti base address
;	a5 := pointer to the unit
;	a6 := pointer to the device
;
;-------------------------------------------------------------------------

Invalid:
Remove:
RawRead:
RawWrite:
GetDriveType:
AddChangeInt:
RemChangeInt:
	move.b	#IOERR_NOCMD,IO_ERROR(a1)
	bra	TermIO

;-------------------------------------------------------------------------

_Reset:
	bsr	InitOmti
	move.l	a5,d2
	lea.l	hd_Units(a6),a2
	moveq.l	#(HD_NUMUNITS-1),d3
	
_Reset_Loop:
	move.l	(a2)+,d0
	beq.s	_Reset_Continue
	move.l	d0,a5

	bsr	Recalibrate
	tst.b	d0
	bne.s	_Reset_Continue
	bsr	GetDriveParms
	tst.b	d0
	bne.s	_Reset_Continue
	bsr	SendDriveChars

_Reset_Continue:
	dbf	d3,_Reset_Loop
	move.l	d2,a5
	bra	TermIO

;-------------------------------------------------------------------------

Read:
	bsr	TestSize
	bne	TermIO

	movem.l IO_LENGTH(a1),d3-d5
	lsr.l	d6,d5
	lsr.l	d6,d3
	move.l	d4,a2
	moveq.l #0,d4
	not.b	d4
	moveq.l	#1,d2
	cmp.l	d2,d3
	beq.s	Read_Buffer

Read_Loop:
	move.l	d5,d0
	bsr	CalcCHS

Read_BufferEntry:
	move.b	#HDCMD_READ,-(a0)
	clr.b	d0
	move.l	d3,d2
	beq.s	Read_Return
	cmp.l	d2,d4
	bcc.s	Read_LengthOk
	move.l	d4,d2
Read_LengthOk:
	sub.l	d2,d3
	move.b	d2,hdc_Count(a0)
	bsr	SendOmtiCmd
	bra.s	Read_Entry

Read_WaitOmti:
	btst.b	d7,(a3)
	beq.s	Read_WaitOmti
	btst.b	#OMTIB_CD,(a3)
	bne.s	Read_Continue
	move.l	hdu_GetSector(a5),a0
	jsr	(a0)
	addq.l	#1,d5
Read_Entry:
	dbf	d2,Read_WaitOmti

Read_Continue:
	bsr	OmtiStatus
	tst.b	d0
	bne.s	Read_Return
	tst.l	d3
	bne.s	Read_Loop

Read_Return:
	move.b	d0,IO_ERROR(a1)
	lsl.l	d6,d5
	sub.l	IO_OFFSET(a1),d5
	move.l	d5,IO_ACTUAL(a1)
	bra	TermIO

Read_Buffer:
	move.l	d5,d0
	bsr	CalcCHS
	bsr	IfSecInBuf
	move.l	hdu_OldSectorOffset(a5),d1
	move.l	d5,hdu_OldSectorOffset(a5)
	tst.b	d0
	bne.s	Read_CopySector
	sub.l	d5,d1
	bpl.s	Read_BufferIsPos
	neg.l	d1
Read_BufferIsPos:
	cmp.l	d1,d2
	bne.s	Read_BufferEntry

Read_FillBuffer:
	move.b	#HDCMD_READ,-(a0)
	and.b	#%11000000,hdc_Sector(a0)
	move.b	(hdu_DriveParms+hddp_NumSecs)(a5),d4
	move.b	d4,hdc_Count(a0)
	bsr	SendOmtiCmd
	move.l	hdu_TrackBuffer(a5),a2
	bra.s	Read_FillBufferEntry

Read_FillBufferWait:
	btst.b	d7,(a3)
	beq.s	Read_FillBufferWait
	btst.b	#OMTIB_CD,(a3)
	bne.s	Read_FillBufferCont
	move.l	hdu_GetSector(a5),a0
	jsr	(a0)
Read_FillBufferEntry:
	dbf	d4,Read_FillBufferWait

Read_FillBufferCont:
	bsr	OmtiStatus
	tst.b	d0
	bne.s	Read_Return

	move.w	hdu_Cylinder(a5),hdu_BufferCylNum(a5)
	move.b	hdu_Head(a5),hdu_BufferHeadNum(a5)

	move.l	IO_DATA(a1),a2

Read_CopySector:
	move.b	hdu_Sector(a5),d4
	lsl.w	d6,d4
	move.l	hdu_TrackBuffer(a5),a0
	add.w	d4,a0
	bsr	CopySector
	moveq.l	#0,d0			; no error -- d0 := 0
	addq.l	#1,d5
	bra	Read_Return

;-------------------------------------------------------------------------

Format:
	move.b	#HDERR_WriteProt,IO_ERROR(a1)
	btst.b	#HDDPB_FORMATPROTECTED,(hdu_DriveParms+hddp_Flags)(a5)
	bne	TermIO

	movem.l IO_LENGTH(a1),d3-d5

	;------	check for correct length and offset
	move.b	#IOERR_BADLENGTH,IO_ERROR(a1)
	move.b	(hdu_DriveParms+hddp_NumSecs)(a5),d0
	lsl.w	d6,d0
	move.l	d3,d1
	divu.w	d0,d1
	swap	d1
	tst.w	d1
	bne	TermIO
	move.l	d5,d1
	divu.w	d0,d1
	swap	d1
	tst.w	d1
	bne	TermIO
	bra.s	Write_FormatEntry

;-------------------------------------------------------------------------

Write:
	move.b	#HDERR_WriteProt,IO_ERROR(a1)
	btst.b	#HDDPB_WRITEPROTECTED,(hdu_DriveParms+hddp_Flags)(a5)
	bne	TermIO

	bsr	TestSize
	bne	TermIO
	movem.l IO_LENGTH(a1),d3-d5

Write_FormatEntry:
	lsr.l	d6,d5
	lsr.l	d6,d3
	move.l	d4,a2
	moveq.l #0,d4
	not.b	d4
	tst.l	d5
	beq	Write_BootBlock
	moveq.l	#1,d1
	cmp.l	d3,d1
	beq	Write_Buffer
	move.b	d4,hdu_BufferHeadNum(a5)

Write_Loop:
	move.l	d5,d0
	bsr	CalcCHS
Write_BufferEntry:
	move.b	#HDCMD_WRITE,-(a0)
	clr.b	d0
	move.l	d3,d2
	beq	Read_Return
	cmp.l	d2,d4
	bcc.s	Write_LengthOk
	move.l	d4,d2
Write_LengthOk:
	sub.l	d2,d3
	move.b	d2,hdc_Count(a0)
	bsr	SendOmtiCmd
	bra.s	Write_Entry

Write_WaitOmti:
	btst.b	d7,(a3)
	beq.s	Write_WaitOmti
	btst.b	#OMTIB_CD,(a3)
	bne.s	Write_Continue

	btst.b	#HDDPB_WRITEHALF,(hdu_DriveParms+hddp_Flags)(a5)
	beq.s	Write_NoHalf

	moveq.l	#31,d0
Write_WaitLoop:
	btst.b	d7,(a3)
	beq.s	Write_WaitLoop
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	move.b	(a2)+,(a4)
	dbf	d0,Write_WaitLoop
	bra.s	Write_Ok

Write_NoHalf:
	move.l	a2,a0
	move.w	#HD_SECTOR,d0
	bsr	WriteData
	move.l	a0,a2

Write_Ok:
	addq.l	#1,d5
Write_Entry:
	dbf	d2,Write_WaitOmti

Write_Continue:
	bsr	OmtiStatus
	tst.b	d0
	bne.s	Write_Return
	tst.l	d3
	bne.s	Write_Loop
Write_Return:
	bra	Read_Return

Write_Buffer:
	move.l	d5,d0
	bsr	CalcCHS
	bsr	IfSecInBuf
	tst.b	d0
	beq	Write_BufferEntry
	movem.l	a0/a2/d4,-(sp)
	move.b	hdu_Sector(a5),d4
	lsl.w	d6,d4
	move.l	a2,a0
	move.l	hdu_TrackBuffer(a5),a2
	add.w	d4,a2
	bsr	CopySector
	movem.l	(sp)+,a0/a2/d4
	bra	Write_BufferEntry

Write_BootBlock:
	moveq.l	#0,d0
	bsr	CalcCHS
	move.b	#HDCMD_READ,-(a0)
	bsr	SendOmtiCmd
	move.b	d4,hdu_BufferHeadNum(a5)
Write_BootBlock_Loop1:
	btst.b	d7,(a3)
	beq.s	Write_BootBlock_Loop1
	btst.b	#OMTIB_CD,(a3)
	bne.s	Write_BootBlock_CD1
	move.l	hdu_TrackBuffer(a5),a0
	move.w	#HD_SECTOR,d0
	bsr	ReadData
Write_BootBlock_CD1:
	bsr	OmtiStatus
	tst.b	d0
	bne.s	Write_Return
	move.l	hdu_TrackBuffer(a5),a0
	move.l	(a2),(a0)
	bne.s	Write_BootBlock_IDOk
	move.l	#HDDP_DOSID,(a0)
Write_BootBlock_IDOk:
	moveq.l	#hdp_SIZEOF,d1
	mulu.w	(hdu_DriveParms+hddp_NumParts)(a5),d1
	add.w	#hddp_SIZEOF,d1
	add.w	d1,a0
	add.w	d1,a2
	move.w	#HD_SECTOR,d0
	sub.w	d1,d0
	bra.s	Write_BootBlock_Entry2
Write_BootBlock_Loop2:
	move.b	(a2)+,(a0)+
Write_BootBlock_Entry2:
	dbf	d0,Write_BootBlock_Loop2
	moveq.l	#0,d0
	bsr	CalcCHS
	move.b	#HDCMD_WRITE,-(a0)
	bsr	SendOmtiCmd
Write_BootBlock_Loop3:
	btst.b	d7,(a3)
	beq.s	Write_BootBlock_Loop3
	btst.b	#OMTIB_CD,(a3)
	bne.s	Write_BootBlock_CD3
	move.l	hdu_TrackBuffer(a5),a0
	move.w	#HD_SECTOR,d0
	bsr	WriteData
Write_BootBlock_CD3:
	bsr	OmtiStatus
	tst.b	d0
	bne	Write_Return
	subq.l	#1,d3
	addq.l	#1,d5
	bra	Write_Loop

;-------------------------------------------------------------------------

Clear:
	moveq.l	#-1,d0
	move.b	d0,hdu_BufferHeadNum(a5)
Update:
ChangeState:
	move.l	d7,IO_ACTUAL(a1)
	bra	TermIO

;-------------------------------------------------------------------------

_Stop:
	bset.b	#HDUB_STOPPED,UNIT_FLAGS(a5)
	bra	TermIO

;-------------------------------------------------------------------------

Start:
	bclr.b	#HDUB_STOPPED,UNIT_FLAGS(a5)
	move.l	a5,a1
	bsr	KickUnitTask
Flush_Return:
	bra	TermIO

;-------------------------------------------------------------------------

Flush:
	move.l	hd_SysBase(a6),a6
	bset.b	#HDUB_STOPPED,UNIT_FLAGS(a5)
	sne.b	d2
	bra.s	Flush_Entry

Flush_Loop:
	move.l	d0,a1
	move.b	#IOERR_ABORTED,IO_ERROR(a1)
	jsr	_LVOReplyMsg(a6)

Flush_Entry:
	move.l	a5,a0
	jsr	_LVOGetMsg(a6)
	tst.l	d0
	bne.s	Flush_Loop

	move.l	hdu_Device(a5),a6
	tst.b	d2
	beq.s	Flush_Return
	bra.s	Start

;-------------------------------------------------------------------------

ChangeNum:
Motor:
	moveq.l #1,d0
	move.l	d0,IO_ACTUAL(a1)
	bra	TermIO

;-------------------------------------------------------------------------

Seek:
	move.l	IO_OFFSET(a1),d0
	lsr.l	d6,d0
	bsr.s	Seek_Do
	move.b	d0,IO_ERROR(a1)
	bra	TermIO

Seek_Do:
	bsr	CalcCHS
	move.b	#HDCMD_SEEK,-(a0)
	move.b	d7,hdc_Count(a0)
	and.b	#%11000000,hdc_Sector(a0)
	bsr	SendOmtiCmd
	bra	OmtiStatus

;-------------------------------------------------------------------------

ProtStatus:
	moveq.l #0,d0
	btst.b	#HDDPB_WRITEPROTECTED,(hdu_DriveParms+hddp_Flags)(a5)
	beq.s	ProtStatus_Return
	moveq.l	#-1,d0
ProtStatus_Return:
	move.l	d0,IO_ACTUAL(a1)
	bra	TermIO

;-------------------------------------------------------------------------

GetNumTracks:
	moveq.l	#0,d0
	move.b	(hdu_DriveParms+hddp_NumHeads)(a5),d0
	mulu.w	(hdu_DriveParms+hddp_NumCyls)(a5),d0
	move.l	d0,IO_ACTUAL(a1)
	bra	TermIO

;-------------------------------------------------------------------------

ChangeProt:
	moveq.l	#HDDPF_WRITEPROTECTED!HDDPF_FORMATPROTECTED,d1
	move.b	(IO_LENGTH+3)(a1),d0
	and.b	d1,d0
	not.b	d1
	and.b	d1,(hdu_DriveParms+hddp_Flags)(a5)
	or.b	d0,(hdu_DriveParms+hddp_Flags)(a5)
	bsr	WriteDriveParms
	move.b	d0,IO_ERROR(a1)
	bra	TermIO

;-------------------------------------------------------------------------

Park:
	move.w	(hdu_DriveParms+hddp_NumCyls)(a5),d2
	move.w	(hdu_DriveParms+hddp_ParkCyl)(a5),d0
	addq.w	#1,d0
	move.w	d0,(hdu_DriveParms+hddp_NumCyls)(a5)
	bsr	SendDriveChars
	move.w	d2,(hdu_DriveParms+hddp_NumCyls)(a5)
	tst.b	d0
	bne.s	Park_Error
	moveq.l	#0,d0
	moveq.l	#0,d1
	move.b	(hdu_DriveParms+hddp_NumSecs)(a5),d0
	move.b	(hdu_DriveParms+hddp_NumHeads)(a5),d1
	mulu.w	d1,d0
	mulu.w	(hdu_DriveParms+hddp_ParkCyl)(a5),d0
	bsr	Seek_Do
	move.b	d0,d2
	bsr	SendDriveChars
	tst.b	d2
	bne.s	Park_Error
	move.b	d2,d0
Park_Error:
	move.b	d0,IO_ERROR(a1)
	bra	TermIO

;-------------------------------------------------------------------------

SetDriveParms:
	move.l	IO_DATA(a1),d0
	beq.s	SetDriveParms_Ok
	move.l	d0,a0
	lea.l	hdu_DriveParms(a5),a2
	moveq.l	#(hddp_SIZEOF/2-1),d0
SetDriveParms_Loop:
	move.w	(a0)+,(a2)+
	dbf	d0,SetDriveParms_Loop
SetDriveParms_Ok:
	bsr	SendDriveChars
	tst.b	d0
	bne.s	SetDriveParms_Error
	btst.b	#HDDPB_NOTWRITTEN,(hdu_DriveParms+hddp_Flags)(a5)
	bne.s	SetDriveParms_Error
	move.l	hd_SysBase(a6),a6
	bsr	AllocTrackBuffer
	move.l	hdu_Device(a5),a6
	tst.b	d0
	bne.s	SetDriveParms_Error
	moveq.l	#0,d0
	btst.b	#HDDPB_WRITEPARTS,(hdu_DriveParms+hddp_Flags)(a5)
	beq.s	SetDriveParms_NoParts
	bclr.b	#HDDPB_WRITEPARTS,(hdu_DriveParms+hddp_Flags)(a5)
	move.l	IO_DATA(a1),d0
	beq.s	SetDriveParms_NoParts
	moveq.l	#hddp_SIZEOF,d1
	add.l	d1,d0
SetDriveParms_NoParts:
	move.l	d0,hdu_Parts(a5)
	bsr	WriteDriveParms
	clr.l	hdu_Parts(a5)
SetDriveParms_Error:
	move.b	d0,IO_ERROR(a1)
	bra	TermIO

;-------------------------------------------------------------------------

_ReadParts:
	move.l	IO_DATA(a1),hdu_Parts(a5)
	bsr	ReadParts
	move.b	d0,IO_ERROR(a1)
	clr.l	hdu_Parts(a5)
	bra	TermIO

;-------------------------------------------------------------------------

Busy:
	tst.l	IO_LENGTH(a1)
	bne.s	Busy_Wait
	bclr.b	#HDB_BUSY,LIB_FLAGS(a6)
	rts
Busy_Wait:
	bset.b	#HDB_BUSY,LIB_FLAGS(a6)
	bne.s	Busy_Wait
	bra	TermIO_NoUnBusy

;-------------------------------------------------------------------------

SendCmd:
	lea.l	hdu_OmtiCmd(a5),a0
	move.l	IO_DATA(a1),d0
	beq.s	SendCmd_Ok
	move.l	d0,a1
	move.l	(a1)+,(a0)+
	move.w	(a1),(a0)
	subq.w	#4,a0
SendCmd_Ok:
	bclr.b	#5,hdc_Head(a0)
	move.b	hdu_LUN(a5),d0
	or.b	d0,hdc_Head(a0)
	bsr	SendOmtiCmd
	bra	TermIO_NoUnBusy

;-------------------------------------------------------------------------

SendData:
	movem.l	IO_LENGTH(a1),d0/a0
	bsr	WriteData
	bra	TermIO_NoUnBusy

;-------------------------------------------------------------------------

GetData:
	movem.l	IO_LENGTH(a1),d0/a0
	bsr	ReadData
	bra	TermIO_NoUnBusy

;-------------------------------------------------------------------------

GetSense:
	bsr	OmtiStatus
	move.l	d7,IO_ACTUAL(a1)
	move.b	d0,IO_ERROR(a1)
	beq.s	GetSense_Ok
	move.l	hdu_OmtiSense(a5),IO_ACTUAL(a1)
GetSense_Ok:
	bra	TermIO_NoUnBusy

;-------------------------------------------------------------------------

	cnop	0,4

	;------	FFS segment
	dc.l	(_FFS_End-_FFS+4)	; segment size
_FFS:
	dc.l	0			; no following segment
	incbin	"FFS.code"		; FFS code
_FFS_End:

;-------------------------------------------------------------------------

	cnop	0,4
_EndHD:
	END

;------------ end of source ------------

