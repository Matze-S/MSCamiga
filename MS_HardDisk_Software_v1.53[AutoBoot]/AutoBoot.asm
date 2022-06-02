; Copyright (C) 1990 by Matthias Schmidt

;
; AutoBoot.asm
;
; M&T RAM/ROM-Board AutoBoot Software -- v1.0 (03:25 11-Aug-90)
;


; devpac environment settings
	incdir	devpac:include.new/		; include directory
	opt	a+,o+,p+,t+


	XREF	_FFS
	XREF	_InitHD


;------------ included files ------------

	include	"exec/execbase.i"
	include	"exec/libraries.i"
	include	"exec/memory.i"
	include	"exec/nodes.i"
	include	"exec/resident.i"
	include	"exec/types.i"
	include	"graphics/rastport.i"
	include	"graphics/text.i"
	include	"graphics/view.i"
	include	"hardware/cia.i"
	include	"hardware/custom.i"
	include	"intuition/intuition.i"
	include	"intuition/screens.i"
	include	"libraries/configregs.i"
	include	"libraries/dos.i"
	include	"libraries/romboot_base.i"


;------------ constants ------------

; LVOs
_LVOFindResident equ	-$60			; exec.library
_LVOSuperState	equ	-$96
_LVOAllocMem	equ	-$c6
_LVOAvailMem	equ	-$d8
_LVOGetMsg	equ	-$174
_LVOReplyMsg	equ	-$17a
_LVOWaitPort	equ	-$180
_LVOCloseLibrary equ	-$19e
_LVOOpenLibrary	equ	-$228
_LVOText	equ	-$3c			; graphics.library
_LVOMove	equ	-$f0
_LVODraw	equ	-$f6
_LVORectFill	equ	-$132
_LVOSetAPen	equ	-$156
_LVOSetDrMd	equ	-$162
_LVOOpenScreen	equ	-$c6			; intuition.library
_LVOOpenWindow	equ	-$cc
_LVOSetPointer	equ	-$10e
_LVORomBoot	equ	-$1e			; romboot.library

_AbsExecBase	equ	$4			; the location to get SysBase
_ciaa		equ	$bfe001			; base of cia A
_custom		equ	$dff000			; base of custom regs

; private constants

	BITDEF	C,HARDDISK,0			; configuration flag
	BITDEF	C,CMOSDISK,1
	BITDEF	C,IGNORE_DF0,2
	BITDEF	C,SETMAP,3
	BITDEF	C,NOFASTMEM,4
	BITDEF	C,REMOVE_BOARD,5

CONFIG_RAM_OFFSET equ	$e4000

VERSION		equ	1
REVISION	equ	0
PRODUCTNUMBER	equ	1
MFGNUMBER	equ	19796		; manufacturer number
SERIALNUMBER	equ	1


;------------ code ------------

	SECTION AutoBoot,CODE

romBase:
	dc.b	%11011111,$ff,%01011111,$ff
	dc.b	$ff-(PRODUCTNUMBER&$f0),$ff
	dc.b	$ff-((PRODUCTNUMBER<<4)&$f0),$ff
	dc.b	%01111111,$ff,$ff,$ff
	dc.b	$ff,$ff,$ff,$ff
	dc.b	$ff-((MFGNUMBER>>8)&$f0),$ff
	dc.b	$ff-((MFGNUMBER>>4)&$f0),$ff
	dc.b	$ff-(MFGNUMBER&$f0),$ff
	dc.b	$ff-((MFGNUMBER<<4)&$f0),$ff
	dc.b	$ff-((SERIALNUMBER>>24)&$f0),$ff
	dc.b	$ff-((SERIALNUMBER>>20)&$f0),$ff
	dc.b	$ff-((SERIALNUMBER>>16)&$f0),$ff
	dc.b	$ff-((SERIALNUMBER>>12)&$f0),$ff
	dc.b	$ff-((SERIALNUMBER>>8)&$f0),$ff
	dc.b	$ff-((SERIALNUMBER>>4)&$f0),$ff
	dc.b	$ff-(SERIALNUMBER&$f0),$ff
	dc.b	$ff-((SERIALNUMBER<<4)&$f0),$ff
	dc.b	$ff-(((diagArea-romBase)>>8)&$f0),$ff
	dc.b	$ff-(((diagArea-romBase)>>4)&$f0),$ff
	dc.b	$ff-((diagArea-romBase)&$f0),$ff
	dc.b	$ff-(((diagArea-romBase)<<4)&$f0),$ff
	dcb.b	$10,$ff
	dc.b	%00000000,$ff,%00010000,$ff
	dcb.b	$3c,$ff

diagArea:
	dc.b	DAC_WORDWIDE!DAC_CONFIGTIME,0
	dc.w	(diagEnd-diagArea)
	dc.w	(diagPoint-diagArea)
	dc.w	(bootPoint-diagArea)
	dc.w	(name-diagArea)
	dc.w	0,0

	;------ resident structure
resident:
	dc.w	RTC_MATCHWORD
	dc.l	(resident-diagArea)
	dc.l	(diagEnd-diagArea)
	dc.b	0
	dc.b	VERSION
	dc.b	NT_DEVICE		; (NT_UNKNOWN)
	dc.b	20
	dc.l	(name-romBase)
	dc.l	(idString-romBase)
	dc.l	(_Init-romBase)

name:
	dc.b	'ram/rom-board',0

idString:
	dc.b	'M&T RAM/ROM-Board AutoBoot Software v1.0',13,10
	dc.b	'Copyright (C) 1990 by Matthias Schmidt',13,10,0

	;------	'dos.library' for the bootPoint() routine
dosName:
	DOSNAME
	ds.w	0

	;------	rom diagnostics
diagPoint:
	lea.l	resident(pc),a1
	move.l	a2,d0
	add.l	d0,RT_MATCHTAG(a1)
	add.l	d0,RT_ENDSKIP(a1)
	add.l	d0,RT_NAME(a1)
	add.l	d0,RT_IDSTRING(a1)
	move.l	a0,d0
	add.l	d0,RT_INIT(a1)
	moveq.l	#1,d0
bootPoint_Error:
	rts

	;------	boot point
bootPoint:
	lea.l	dosName(pc),a1
	jsr	_LVOFindResident(a6)
	tst.l	d0
	beq.s	bootPoint_Error
	move.l	d0,a0
	move.l	RT_INIT(a0),a0
	jmp	(a0)

	;------	end of the diagnostics area
diagEnd:

	;------	the Init() routine (a0 := SysBase)
_Init:
	movem.l	d0-d7/a0-a6,-(sp)
	bsr	_Menu
	lea.l	romBase(pc),a5
	add.l	#CONFIG_RAM_OFFSET,a5
	btst.b	#CB_REMOVE_BOARD,(a5)
	beq.s	Init_NoRemove
	movem.l	Init_RemoveCode(pc),d0-d2
	movem.l	d0-d2,-(sp)
	lea.l	(romBase+$4c)(pc),a0
	jmp	(sp)
Init_NoRemove:
	btst.b	#CB_IGNORE_DF0,(a5)
	beq.s	Init_NoIgnore
	move.l	ResModules(a6),a2
	bra.s	Init_ScanModules_Entry
Init_ScanModules_Loop:
	move.l	(a2),a0
	move.l	RT_NAME(a0),a0
	lea.l	Init_StrapName(pc),a1
Init_ScanModules_Cmp:
	move.b	(a0)+,d0
	cmp.b	(a1)+,d0
	bne.s	Init_ScanModules_Next
	tst.b	d0
	bne.s	Init_ScanModules_Cmp
	moveq.l	#RT_SIZE,d0
	moveq.l	#MEMF_PUBLIC,d1
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	beq.s	Init_NoIgnore
	move.l	d0,a0
	moveq.l	#((RT_SIZE/2)-1),d2
	lea.l	Init_IgnoreResident(pc),a1
	move.l	a1,d1
Init_CopyResLoop:
	move.w	(a1)+,(a0)+
	dbf	d2,Init_CopyResLoop
	move.l	d0,a0
	move.l	d0,RT_MATCHTAG(a0)
	add.l	d0,RT_ENDSKIP(a0)
	add.l	d1,RT_NAME(a0)
	add.l	d1,RT_IDSTRING(a0)
	add.l	d1,RT_INIT(a0)
	move.l	a0,(a2)
	bra.s	Init_NoIgnore
Init_ScanModules_Next:
	addq.w	#4,a2
Init_ScanModules_Entry:
	tst.l	(a2)
	bne.s	Init_ScanModules_Loop
Init_NoIgnore:
	btst.b	#CB_NOFASTMEM,(a5)
	beq.s	Init_NoNoFastMem
	move.l	#(MEMF_FAST!MEMF_LARGEST),d2
	bra.s	Init_AllocFast_Entry
Init_AllocFast_Loop:
	move.l	d2,d1
	jsr	_LVOAllocMem(a6)
Init_AllocFast_Entry:
	move.l	d2,d1
	jsr	_LVOAvailMem(a6)
	tst.l	d0
	bne.s	Init_AllocFast_Loop
Init_NoNoFastMem:
	btst.b	#CB_HARDDISK,(a5)
	beq.s	Init_NoHardDisk
	jsr	_InitHD(pc)
Init_NoHardDisk:
	bra.s	Init_Rts

Init_RemoveCode:
	clr.b	(a0)				; remove ram/rom-board
	lea.l	(Init_RemoveCodeEnd-Init_RemoveCode)(sp),sp ; skip this code
Init_Rts:
	movem.l	(sp)+,d0-d7/a0-a6		; get back saved regs
	rts					; return
Init_RemoveCodeEnd:

Init_IgnoreResident:
	dc.w	RTC_MATCHWORD
	dc.l	0
	dc.l	RT_SIZE
	dc.b	RTF_COLDSTART
	dc.b	3				; version := 3
	dc.b	0				; type := NT_UNKNOWN
	dc.b	-60
	dc.l	(Init_IgnoreName-Init_IgnoreResident)
	dc.l	(Init_IgnoreId-Init_IgnoreResident)
	dc.l	(Init_RomBoot-Init_IgnoreResident)

	;------	my own boot.strap
Init_RomBoot:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	lea.l	Init_RomBootName(pc),a1
	moveq.l	#34,d0				; version := 34
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	beq.s	Init_NoRomBoot
	move.l	d0,a6
	jsr	_LVORomBoot(a6)
	move.l	a6,a1
	move.l	16(sp),a6
	jsr	_LVOCloseLibrary(a6)
Init_NoRomBoot:
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

Init_IgnoreId:
	dc.b	'Ignore DF0: Boot Disk v3.0 (02:02 01-Aug-90)',13,10,0
Init_IgnoreName:
	dc.b	'ignore.strap',0
Init_StrapName:
	dc.b	'strap',0
Init_RomBootName:
	ROMBOOT_NAME
	ds.w	0

 STRUCTURE LocalData,4			; 0(ld_ptr) := SysBase
	APTR	ld_IntuitionBase
	APTR	ld_GfxBase
	APTR	ld_Screen
	APTR	ld_Window
	APTR	ld_RastPort
	SHORT	ld_LeftEdge
	SHORT	ld_TopEdge
	APTR	ld_RomBase
	APTR	ld_ConfigPtr
	UBYTE	ld_Config
	UBYTE	ld_pad
	STRUCT	ld_TextAttr,ta_SIZEOF
	LABEL	ld_SIZEOF

	;------	the AutoBoot menu ... (a6 := SysBase)
_Menu:
	movem.l	d0-d3/a0-a2/a5-a6,-(sp)
	lea.l	(-ld_SIZEOF)(sp),sp
	move.l	sp,a5
	move.l	a6,(a5)
	btst.b	#6,(_ciaa+ciapra).l
	bne	Menu_Return
	lea.l	romBase(pc),a0
	move.l	a0,ld_RomBase(a5)
	add.l	#CONFIG_RAM_OFFSET,a0
	move.l	a0,ld_ConfigPtr(a5)
	move.b	(a0),d0
	and.b	#%00011111,d0
	move.b	d0,ld_Config(a5)
	lea.l	Menu_GfxName(pc),a1
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,ld_GfxBase(a5)
	beq	Menu_Reset
	lea.l	Menu_IntName(pc),a1
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,ld_IntuitionBase(a5)
	beq	Menu_Reset
	move.l	d0,a6
	lea.l	(Menu_NewScreen+ns_SIZEOF)(pc),a0
	moveq.l	#((ns_SIZEOF/2)-1),d0
Menu_Loop1:
	move.w	-(a0),-(sp)
	dbf	d0,Menu_Loop1
	lea.l	ld_TextAttr(a5),a0
	lea.l	Menu_FontName(pc),a1
	move.l	#((8<<16)!(FS_NORMAL<<8)!FPF_ROMFONT),a2
	movem.l	a1-a2,(a0)
	move.l	a0,ns_Font(sp)
	move.l	sp,a0
	jsr	_LVOOpenScreen(a6)
	move.l	a5,sp
	move.l	d0,ld_Screen(a5)
	beq	Menu_Reset
	lea.l	(Menu_NewWindow+nw_SIZE)(pc),a0
	moveq.l	#((nw_SIZE/2)-1),d1
Menu_Loop2:
	move.w	-(a0),-(sp)
	dbf	d1,Menu_Loop2
	move.l	d0,nw_Screen(sp)
	move.l	d0,a1
	move.w	sc_Height(a1),nw_Height(sp)
	move.l	sp,a0
	jsr	_LVOOpenWindow(a6)
	move.l	a5,sp
	move.l	d0,ld_Window(a5)
	beq	Menu_Reset
	move.l	d0,a0
	moveq.l	#0,d0
	moveq.l	#16,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	move.l	d1,a1
	jsr	_LVOSetPointer(a6)
	move.l	ld_Window(a5),a0
	move.l	wd_RPort(a0),a1
	move.l	a1,ld_RastPort(a5)
	move.w	wd_Height(a0),d1
	sub.w	#132,d1
	lsr.w	#1,d1
	move.w	#142,d0
	move.w	#356,d2
	move.w	#132,d3
	bsr	Menu_ShadowBox
	addq.w	#3,d0
	addq.w	#2,d1
	subq.w	#6,d2
	subq.w	#4,d3
	bsr	Menu_ShadowBox
	add.w	#15,d0
	addq.w	#8,d1
	movem.w	d0-d1,ld_LeftEdge(a5)
Menu_Loop3:
	move.l	ld_RastPort(a5),a1
	moveq.l	#0,d0
	move.l	ld_GfxBase(a5),a6
	jsr	_LVOSetAPen(a6)
	move.l	ld_RastPort(a5),a1
	moveq.l	#0,d0
	moveq.l	#0,d1
	movem.w	ld_LeftEdge(a5),d0-d1
	move.l	d0,d2
	move.l	d1,d3
	add.w	#321,d2
	add.w	#111,d3
	subq.w	#1,d1
	jsr	_LVORectFill(a6)
	lea.l	Menu_Text(pc),a0
	moveq.l	#0,d0
	moveq.l	#13,d1
	moveq.l	#CB_NOFASTMEM,d2
Menu_Loop4:
	move.b	(a0)+,d0
	bsr	Menu_Print
	cmp.w	#8,d1
	bcc.s	Menu_Continue1
	tst.w	d2
	bmi.s	Menu_Continue1
	move.b	(a0)+,d0
	move.l	a0,-(sp)
	lea.l	Menu_OnText(pc),a0
	btst.b	d2,ld_Config(a5)
	bne.s	Menu_Ok1
	lea.l	Menu_OffText(pc),a0
Menu_Ok1:
	bsr	Menu_Print
	move.l	(sp)+,a0
	subq.w	#1,d2
Menu_Continue1:
	subq.w	#1,d1
	tst.b	(a0)
	bpl.s	Menu_Loop4
	moveq.l	#2,d0
	move.l	ld_RastPort(a5),a1
	jsr	_LVOSetAPen(a6)
	moveq.l	#96,d0
	add.w	d0,d0
	add.w	ld_LeftEdge(a5),d0
	moveq.l	#104,d1
	add.w	ld_TopEdge(a5),d1
	move.l	d0,d2
	move.l	d1,d3
	addq.w	#8,d2
	addq.w	#7,d3
	move.l	ld_RastPort(a5),a1
	movem.l	d0-d3/a1,-(sp)
	addq.w	#2,d0
	subq.w	#1,d1
	addq.w	#2,d2
	subq.w	#1,d3
	jsr	_LVORectFill(a6)
	move.l	ld_RastPort(a5),a1
	moveq.l	#3,d0
	jsr	_LVOSetAPen(a6)
	movem.l	(sp)+,d0-d3/a1
	jsr	_LVORectFill(a6)
Menu_Loop5:
	move.l	ld_Window(a5),a0
	move.l	wd_UserPort(a0),a2
	move.l	a2,a0
	move.l	(a5),a6
	jsr	_LVOWaitPort(a6)
	move.l	a2,a0
	jsr	_LVOGetMsg(a6)
	move.l	d0,a1
	move.w	im_Code(a1),d2
	jsr	_LVOReplyMsg(a6)
	cmp.b	#$44,d2				; $44 := RETURN
	beq.s	Menu_Quit
	cmp.b	#$45,d2				; $45 := ESC
	beq.s	Menu_Reset
	cmp.b	#$50,d2				; $50 := F1
	bcs.s	Menu_Loop5
	cmp.b	#$58,d2				; $58 := F9
	beq.s	Menu_Quit
	bcc.s	Menu_Loop5
	cmp.b	#$55,d2
	bcc.s	Menu_Ok2
	sub.w	#$50,d2
	bchg.b	d2,ld_Config(a5)
	bra	Menu_Loop3
Menu_Ok2:
	cmp.b	#$56,d2
	beq.s	Menu_Remove
	cmp.b	#$57,d2
	bne	Menu_Loop3
	move.w	#$4000,(_custom+intena).l
	not.l	LIB_SUM(a6)
	not.l	LowMemChkSum(a6)
	not.l	ChkBase(a6)
	not.l	ColdCapture(a6)
	not.l	CoolCapture(a6)
	not.l	WarmCapture(a6)
	not.l	KickCheckSum(a6)
	not.l	ChkSum(a6)
	clr.l	(_AbsExecBase).w
	bra.s	Menu_Quit
Menu_Remove:
	bset.b	#CB_REMOVE_BOARD,ld_Config(a5)
Menu_Quit:
	move.l	ld_ConfigPtr(a5),a0
	move.b	ld_Config(a5),(a0)
Menu_Reset:
	movem.l	Menu_ResetCode(pc),d0-d1
	movem.l	d0-d1,-(sp)
	move.l	(a5),a6
	jsr	_LVOSuperState(a6)
	jmp	(sp)
Menu_Return:
	lea.l	ld_SIZEOF(a5),sp
	movem.l	(sp)+,d0-d3/a0-a2/a5-a6
	rts

Menu_ResetCode:
	reset
	jmp	($fc0002).l

;------------ TOOLS ------------ (a0 := ConfigPtr, a5 := ld, a6 := SysBase)

	;------	print a text (a0 := text, d0 := x, d1 := y)
Menu_Print:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	moveq.l	#2,d0
	move.l	ld_RastPort(a5),a1
	move.l	ld_GfxBase(a5),a6
	jsr	_LVOSetAPen(a6)
	moveq.l	#RP_JAM1,d0
	move.l	ld_RastPort(a5),a1
	jsr	_LVOSetDrMd(a6)
	moveq.l	#0,d0
	move.w	2(sp),d0
	lsl.w	#3,d0
	add.w	ld_LeftEdge(a5),d0
	moveq.l	#0,d1
	move.w	6(sp),d1
	lsl.w	#3,d1
	add.w	ld_TopEdge(a5),d1
	move.l	ld_RastPort(a5),a1
	add.w	rp_TxBaseline(a1),d1
	move.l	ld_GfxBase(a5),a6
	movem.l	d0-d1/a1,-(sp)
	addq.w	#2,d0
	subq.w	#1,d1
	jsr	_LVOMove(a6)
	move.l	20(sp),a0
	moveq.l	#-1,d0
	move.l	a0,a1
Menu_PrintLoop:
	addq.l	#1,d0
	tst.b	(a1)+
	bne.s	Menu_PrintLoop
	move.l	a1,20(sp)
	move.l	ld_RastPort(a5),a1
	movem.l	d0/a0-a1,-(sp)
	jsr	_LVOText(a6)
	moveq.l	#1,d0
	move.l	ld_RastPort(a5),a1
	jsr	_LVOSetAPen(a6)
	movem.l	12(sp),d0-d1/a1
	jsr	_LVOMove(a6)
	movem.l	(sp),d0/a0-a1
	jsr	_LVOText(a6)
	lea.l	24(sp),sp
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

	;------	draw a box with a shadow
Menu_ShadowBox:
	movem.l	d0-d3/a0-a1/a6,-(sp)
	moveq.l	#2,d0
	move.l	ld_RastPort(a5),a1
	move.l	ld_GfxBase(a5),a6
	jsr	_LVOSetAPen(a6)
	movem.l	(sp),d0-d1
	addq.w	#2,d0
	subq.w	#1,d1
	bsr.s	Menu_DrawBox
	moveq.l	#1,d0
	move.l	ld_RastPort(a5),a1
	jsr	_LVOSetAPen(a6)
	movem.l	(sp),d0-d1
	bsr.s	Menu_DrawBox
	movem.l	(sp)+,d0-d3/a0-a1/a6
	rts

	;------	draw a box
	;------	(d0.w := left, d1.w := top, d2.w := width, d3.w := height)
Menu_DrawBox:
	movem.l	d0-d3/a0-a1/a6,-(sp)
	subq.w	#1,d2
	subq.w	#1,d3
	moveq.l	#0,d0
	moveq.l	#0,d1
	move.w	2(sp),d0
	move.w	6(sp),d1
	movem.l	d0-d1,(sp)
	move.l	ld_RastPort(a5),a1
	move.l	ld_GfxBase(a5),a6
	jsr	_LVOMove(a6)
	movem.l	(sp),d0-d1
	add.w	d2,d0
	move.l	ld_RastPort(a5),a1
	jsr	_LVODraw(a6)
	movem.l	(sp),d0-d1
	add.w	d2,d0
	add.w	d3,d1
	move.l	ld_RastPort(a5),a1
	jsr	_LVODraw(a6)
	movem.l	(sp),d0-d1
	add.w	d3,d1
	move.l	ld_RastPort(a5),a1
	jsr	_LVODraw(a6)
	movem.l	(sp),d0-d1
	move.l	ld_RastPort(a5),a1
	jsr	_LVODraw(a6)
	movem.l	(sp)+,d0-d3/a0-a1/a6
	rts

Menu_OnText:
	dc.b	'(on)',0
Menu_OffText:
	dc.b	'(off)',0
Menu_Text:
	dc.b	0,'Please select (F1-F9) :',0
	dc.b	0,0
	dc.b	2,'F9 -- Quit',0
	dc.b	2,'F8 -- Total Reset',0
	dc.b	2,'F7 -- Remove RAM/ROM-Board',0
	dc.b	2,'F6 -- Small Copy',0
	dc.b	2,'F5 -- NoFastMem',0,18
	dc.b	2,'F4 -- SetMap/Sys-Config/SetClock',0,35
	dc.b	2,'F3 -- Ignore DF0:',0,20
	dc.b	2,'F2 -- CMOS-RamDisk',0,21
	dc.b	2,'F1 -- HardDisk',0,17
	dc.b	0,0
	dc.b	1,'Copyright (C) 1990 by Matthias Schmidt',0
	dc.b	0,'M&T RAM/ROM-Board AutoBoot Software v1.0',0,-1
Menu_GfxName:
	dc.b	'graphics.library',0
Menu_IntName:
	dc.b	'intuition.library',0
Menu_FontName:
	dc.b	'topaz.font',0
	ds.w	0
Menu_NewScreen:
	dc.w	0,0,640,STDSCREENHEIGHT,2
	dc.b	0,0
	dc.w	V_HIRES,CUSTOMSCREEN!SCREENQUIET
	dc.l	0,0,0,0
Menu_NewWindow:
	dc.w	0,0,640,200
	dc.b	0,0
	dc.l	RAWKEY
	dc.l	SIMPLE_REFRESH!BORDERLESS!ACTIVATE!RMBTRAP!NOCAREREFRESH
	dc.l	0,0,0,0,0
	dc.w	-1,-1,-1,-1,CUSTOMSCREEN

;-------------------------------------------------------------------------

	cnop	0,4
	END

;------------ end of source ------------

