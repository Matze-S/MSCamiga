
*
* small.lib -- Copyright (C) 1989 by Matthias Schmidt
*

* --- useful macros --- *

XEQ	MACRO
\1	EQU	\2
	XDEF	\1
	ENDM

LIBINIT	MACRO
	IFC	'\1',''
CNT	SET	-30
	ENDC
	IFNC	'\1',''
CNT	SET	\1
	ENDC
	ENDM

LIBDEF	MACRO
	XEQ	_LVO\1,CNT
CNT	SET	CNT-6
	ENDM

* --- constants --- *

	XEQ	_AbsExecBase,4

* --- library references (lvos) --- *

	LIBINIT					* clist.library
	LIBDEF	InitCLPool
	LIBDEF	AllocCList
	LIBDEF	FreeCList
	LIBDEF	FlushCList
	LIBDEF	SizeCList
	LIBDEF	PutCLChar
	LIBDEF	GetCLChar
	LIBDEF	UnGetCLChar
	LIBDEF	UnPutCLChar
	LIBDEF	PutCLWord
	LIBDEF	GetCLWord
	LIBDEF	UnGetCLWord
	LIBDEF	UnPutCLWord
	LIBDEF	PutCLBuf
	LIBDEF	GetCLBuf
	LIBDEF	MarkCList
	LIBDEF	IncrCLMark
	LIBDEF	PeekCLMark
	LIBDEF	SplitCList
	LIBDEF	CopyCList
	LIBDEF	SubCList
	LIBDEF	ConcatCList

	LIBINIT	-42				* console.device
	LIBDEF	CDInputHandler
	LIBDEF	RawKeyConvert
	LIBDEF	AskDefaultKeyMap
	LIBDEF	SetDefaultKeyMap

	LIBINIT					* diskfont.library
	LIBDEF	OpenDiskFont
	LIBDEF	AvailFonts
	LIBDEF	NewFontContents
	LIBDEF	DisposeFontContents

	LIBINIT					* dos.library
	LIBDEF	Open
	LIBDEF	Close
	LIBDEF	Read
	LIBDEF	Write
	LIBDEF	Input
	LIBDEF	Output
	LIBDEF	Seek
	LIBDEF	DeleteFile
	LIBDEF	Rename
	LIBDEF	Lock
	LIBDEF	UnLock
	LIBDEF	DupLock
	LIBDEF	Examine
	LIBDEF	ExNext
	LIBDEF	Info
	LIBDEF	CreateDir
	LIBDEF	CurrentDir
	LIBDEF	IoErr
	LIBDEF	CreateProc
	LIBDEF	Exit
	LIBDEF	LoadSeg
	LIBDEF	UnLoadSeg
	LIBDEF	GetPacket
	LIBDEF	QueuePacket
	LIBDEF	DeviceProc
	LIBDEF	SetComment
	LIBDEF	SetProtection
	LIBDEF	DateStamp
	LIBDEF	Delay
	LIBDEF	WaitForChar
	LIBDEF	ParentDir
	LIBDEF	IsInteractive
	LIBDEF	Execute

	LIBINIT					* exec.library
	LIBDEF	Supervisor
	LIBDEF	ExitIntr
	LIBDEF	Schedule
	LIBDEF	Reschedule
	LIBDEF	Switch
	LIBDEF	Dispatch
	LIBDEF	Exception
	LIBDEF	InitCode
	LIBDEF	InitStruct
	LIBDEF	MakeLibrary
	LIBDEF	MakeFunctions
	LIBDEF	FindResident
	LIBDEF	InitResident
	LIBDEF	Alert
	LIBDEF	Debug
	LIBDEF	Disable
	LIBDEF	Enable
	LIBDEF	Forbid
	LIBDEF	Permit
	LIBDEF	SetSR
	LIBDEF	SuperState
     	LIBDEF	UserState
	LIBDEF	SetIntVector
	LIBDEF	AddIntServer
	LIBDEF	RemIntServer
	LIBDEF	Cause
	LIBDEF	Allocate
	LIBDEF	Deallocate
	LIBDEF	AllocMem
	LIBDEF	AllocAbs
	LIBDEF	FreeMem
	LIBDEF	AvailMem
	LIBDEF	AllocEntry
	LIBDEF	FreeEntry
	LIBDEF	Insert
	LIBDEF	AddHead
	LIBDEF	AddTail
	LIBDEF	Remove
	LIBDEF	RemHead
	LIBDEF	RemTail
	LIBDEF	Enqueue
	LIBDEF	FindName
	LIBDEF	AddTask
	LIBDEF	RemTask
	LIBDEF	FindTask
	LIBDEF	SetTaskPri
	LIBDEF	SetSignal
	LIBDEF	SetExcept
	LIBDEF	Wait
	LIBDEF	Signal
	LIBDEF	AllocSignal
	LIBDEF	FreeSignal
	LIBDEF	AllocTrap
	LIBDEF	FreeTrap
	LIBDEF	AddPort
	LIBDEF	RemPort
	LIBDEF	PutMsg
	LIBDEF	GetMsg
	LIBDEF	ReplyMsg
	LIBDEF	WaitPort
	LIBDEF	FindPort
	LIBDEF	AddLibrary
	LIBDEF	RemLibrary
	LIBDEF	OldOpenLibrary
	LIBDEF	CloseLibrary
	LIBDEF	SetFunction
	LIBDEF	SumLibrary
	LIBDEF	AddDevice
	LIBDEF	RemDevice
	LIBDEF	OpenDevice
	LIBDEF	CloseDevice
	LIBDEF	DoIO
	LIBDEF	SendIO
	LIBDEF	CheckIO
	LIBDEF	WaitIO
	LIBDEF	AbortIO
	LIBDEF	AddResource
	LIBDEF	RemResource
	LIBDEF	OpenResource
	LIBDEF	RawIOInit
	LIBDEF	RawMayGetChar
	LIBDEF	RawPutChar
	LIBDEF	RawDoFmt
	LIBDEF	GetCC
	LIBDEF	TypeOfMem
	LIBDEF	Procure
	LIBDEF	Vacate
	LIBDEF	OpenLibrary
	LIBDEF	InitSemaphore
	LIBDEF	ObtainSemaphore
	LIBDEF	ReleaseSemaphore
	LIBDEF	AttemptSemaphore
	LIBDEF	ObtSemaphoreList
	LIBDEF	RelSemaphoreList
	LIBDEF	FindSemaphore
	LIBDEF	AddSemaphore
	LIBDEF	RemSemaphore
	LIBDEF	SumKickData
	LIBDEF	AddMemList
	LIBDEF	CopyMem
	LIBDEF	CopyMemQuick

	LIBINIT					* expansion.library
	LIBDEF	AddConfigDev
	LIBDEF	expansionUnused
	LIBDEF	AllocBoardMem
	LIBDEF	AllocConfigDev
	LIBDEF	AllocExpansionMem
	LIBDEF	ConfigBoard
	LIBDEF	ConfigChain
	LIBDEF	FindConfigDev
	LIBDEF	FreeBoardMem
	LIBDEF	FreeConfigDev
	LIBDEF	FreeExpansionMem
	LIBDEF	ReadExpByte
	LIBDEF	ReadExpRom
	LIBDEF	RemConfigDev
	LIBDEF	WriteExpansionByte
	LIBDEF	ObtainConfigBinding
	LIBDEF	ReleaseConfigBinding
	LIBDEF	SetCurrentBinding
	LIBDEF	GetCurrentBinding
	LIBDEF	MakeDosNode
	LIBDEF	AddDosNode

	LIBINIT					* graphics.library
	LIBDEF	BltBitMap
	LIBDEF	BltTemplate
	LIBDEF	ClearEOL
	LIBDEF	ClearScreen
	LIBDEF	TextLength
	LIBDEF	Text
	LIBDEF	SetFont
	LIBDEF	OpenFont
	LIBDEF	CloseFont
	LIBDEF	AskSoftStyle
	LIBDEF	SetSoftStyle
	LIBDEF	AddBob
	LIBDEF	AddVSprite
	LIBDEF	DoCollision
	LIBDEF	DrawGList
	LIBDEF	InitGels
	LIBDEF	InitMasks
	LIBDEF	RemIBob
	LIBDEF	RemVSprite
	LIBDEF	SetCollision
	LIBDEF	SortGList
	LIBDEF	AddAnimObj
	LIBDEF	Animate
	LIBDEF	GetGBuffers
	LIBDEF	InitGMasks
	LIBDEF	DrawEllipse
	LIBDEF	AreaEllipse
	LIBDEF	LoadRGB4
	LIBDEF	InitRastPort
	LIBDEF	InitVPort
	LIBDEF	MrgCop
	LIBDEF	MakeVPort
	LIBDEF	LoadView
	LIBDEF	WaitBlit
	LIBDEF	SetRast
	LIBDEF	Move
	LIBDEF	Draw
	LIBDEF	AreaMove
	LIBDEF	AreaDraw
	LIBDEF	AreaEnd
	LIBDEF	WaitTOF
	LIBDEF	QBlit
	LIBDEF	InitArea
	LIBDEF	SetRGB4
	LIBDEF	QBSBlit
	LIBDEF	BltClear
	LIBDEF	RectFill
	LIBDEF	BltPattern
	LIBDEF	ReadPixel
	LIBDEF	WritePixel
	LIBDEF	Flood
	LIBDEF	PolyDraw
	LIBDEF	SetAPen
	LIBDEF	SetBPen
	LIBDEF	SetDrMd
	LIBDEF	InitView
	LIBDEF	CBump
	LIBDEF	CMove
	LIBDEF	CWait
	LIBDEF	VBeamPos
	LIBDEF	InitBitMap
	LIBDEF	ScrollRaster
	LIBDEF	WaitBOVP
	LIBDEF	GetSprite
	LIBDEF	FreeSprite
	LIBDEF	ChangeSprite
	LIBDEF	MoveSprite
	LIBDEF	LockLayerRom
	LIBDEF	UnlockLayerRom
	LIBDEF	SyncSBitMap
	LIBDEF	CopySBitMap
	LIBDEF	OwnBlitter
	LIBDEF	DisownBlitter
	LIBDEF	InitTmpRas
	LIBDEF	AskFont
	LIBDEF	AddFont
	LIBDEF	RemFont
	LIBDEF	AllocRaster
	LIBDEF	FreeRaster
	LIBDEF	AndRectRegion
	LIBDEF	OrRectRegion
	LIBDEF	NewRegion
	LIBDEF	NotRegion
	LIBDEF	ClearRegion
	LIBDEF	DisposeRegion
	LIBDEF	FreeVPortCopLists
	LIBDEF	FreeCopList
	LIBDEF	ClipBlit
	LIBDEF	XorRectRegion
	LIBDEF	FreeCprList
	LIBDEF	GetColorMap
	LIBDEF	FreeColorMap
	LIBDEF	GetRGB4
	LIBDEF	ScrollVPort
	LIBDEF	UCopperListInit
	LIBDEF	FreeGBuffers
	LIBDEF	BltBitMapRastPort
	LIBDEF	OrRegionRegion
	LIBDEF	XorRegionRegion
	LIBDEF	AndRegionRegion
	LIBDEF	SetRGB4CM
	LIBDEF	BltMaskBitMapRastPort
	LIBDEF	GraphicsReserved1
	LIBDEF	GraphicsResirved2
	LIBDEF	AttemptLockLayerRom

	LIBINIT					* icon.library
	LIBDEF	GetWBObject
	LIBDEF	PutWBObject
	LIBDEF	GetIcon
	LIBDEF	PutIcon
	LIBDEF	FreeFreeList
	LIBDEF	FreeWBObject
	LIBDEF	AllocWBObject
	LIBDEF	AddFreeList
	LIBDEF	GetDiskObject
	LIBDEF	PutDiskObject
	LIBDEF	FreeDiskObject
	LIBDEF	FindToolType
	LIBDEF	MatchToolValue
	LIBDEF	BumpRevision

	LIBINIT					* intuition.library
	LIBDEF	OpenIntuition
	LIBDEF	Intuition
	LIBDEF	AddGadget
	LIBDEF	ClearDMRequest
	LIBDEF	ClearMenuStrip
	LIBDEF	ClearPointer
	LIBDEF	CloseScreen
	LIBDEF	CloseWindow
	LIBDEF	CloseWorkBench
	LIBDEF	CurrentTime
	LIBDEF	DisplayAlert
	LIBDEF	DisplayBeep
	LIBDEF	DoubleClick
	LIBDEF	DrawBorder
	LIBDEF	DrawImage
	LIBDEF	EndRequest
	LIBDEF	GetLIBDEFPrefs
	LIBDEF	GetPrefs
	LIBDEF	InitRequester
	LIBDEF	ItemAddress
	LIBDEF	ModifyIDCMP
	LIBDEF	ModifyProp
	LIBDEF	MoveScreen
	LIBDEF	MoveWindow
	LIBDEF	OffGadget
	LIBDEF	OffMenu
	LIBDEF	OnGadget
	LIBDEF	OnMenu
	LIBDEF	OpenScreen
	LIBDEF	OpenWindow
	LIBDEF	OpenWorkBench
	LIBDEF	PrintIText
	LIBDEF	RefreshGadgets
	LIBDEF	RemoveGadget
	LIBDEF	ReportMouse
	LIBDEF	Request
	LIBDEF	ScreenToBack
	LIBDEF	ScreenToFront
	LIBDEF	SetDMRequest
	LIBDEF	SetMenuStrip
	LIBDEF	SetPointer
	LIBDEF	SetWindowTitles
	LIBDEF	ShowTitle
	LIBDEF	SizeWindow
	LIBDEF	ViewAddress
	LIBDEF	ViewPortAddress
	LIBDEF	WindowToBack
	LIBDEF	WindowToFront
	LIBDEF	WindowLimits
	LIBDEF	SetPrefs
	LIBDEF	IntuiTextLength
	LIBDEF	WBenchToBack
	LIBDEF	WBenchToFront
	LIBDEF	AutoRequest
	LIBDEF	BeginRefresh
	LIBDEF	BuildSysRequest
	LIBDEF	EndRefresh
	LIBDEF	FreeSysRequest
	LIBDEF	MakeScreen
	LIBDEF	RemakeDisplay
	LIBDEF	RethinkDisplay
	LIBDEF	AllocRemember
	LIBDEF	AlohaWorkbench
	LIBDEF	FreeRemember
	LIBDEF	LockIBase
	LIBDEF	UnlockIBase
	LIBDEF	GetScreenData
	LIBDEF	RefreshGList
	LIBDEF	AddGList
	LIBDEF	RemoveGList
	LIBDEF	ActivateWindow
	LIBDEF	RefreshWindowFrame
	LIBDEF	ActivateGadget
	LIBDEF	NewModifyProp

	LIBINIT					* layers.library
	LIBDEF	InitLayers
	LIBDEF	CreateUpfrontLayer
	LIBDEF	CreateBehindLayer
	LIBDEF	UpfrontLayer
	LIBDEF	BehindLayer
	LIBDEF	MoveLayer
	LIBDEF	SizeLayer
	LIBDEF	ScrollLayer
	LIBDEF	BeginUpdate
	LIBDEF	EndUpdate
	LIBDEF	DeleteLayer
	LIBDEF	LockLayer
	LIBDEF	UnlockLayer
	LIBDEF	LockLayers
	LIBDEF	UnlockLayers
	LIBDEF	LockLayerInfo
	LIBDEF	SwapBitsRastPortClipRect
	LIBDEF	WhichLayer
	LIBDEF	UnlockLayerInfo
	LIBDEF	NewLayerInfo
	LIBDEF	DisposeLayerInfo
	LIBDEF	FattenLayerInfo
	LIBDEF	ThinLayerInfo
	LIBDEF	MoveLayerInFrontOf
	LIBDEF	InstallClipRegion

	LIBINIT					* mathffp.library
	LIBDEF	SPFix
	LIBDEF	SPFlt
	LIBDEF	SPCmp
	LIBDEF	SPTst
	LIBDEF	SPAbs
	LIBDEF	SPNeg
	LIBDEF	SPAdd
	LIBDEF	SPSub
	LIBDEF	SPMul
	LIBDEF	SPDiv
	LIBDEF	SPFloor
	LIBDEF	SPCeil

	LIBINIT					* mathieeedoubbas.library
	LIBDEF	IEEEDPFix
	LIBDEF	IEEEDPFlt
	LIBDEF	IEEEDPCmp
	LIBDEF	IEEEDPTst
	LIBDEF	IEEEDPAbs
	LIBDEF	IEEEDPNeg
	LIBDEF	IEEEDPAdd
	LIBDEF	IEEEDPSub
	LIBDEF	IEEEDPMul
	LIBDEF	IEEEDPDiv
	LIBDEF	IEEEDPFloor
	LIBDEF	IEEEDPCeil

	LIBINIT					* mathieeedoubtrans.library
	LIBDEF	IEEEDPAtan
	LIBDEF	IEEEDPSin
	LIBDEF	IEEEDPCos
	LIBDEF	IEEEDPTan
	LIBDEF	IEEEDPSincos
	LIBDEF	IEEEDPSinh
	LIBDEF	IEEEDPCosh
	LIBDEF	IEEEDPTanh
	LIBDEF	IEEEDPExp
	LIBDEF	IEEEDPLog
	LIBDEF	IEEEDPPow
	LIBDEF	IEEEDPSqrt
	LIBDEF	IEEEDPTieee
	LIBDEF	IEEEDPFieee
	LIBDEF	IEEEDPAsin
	LIBDEF	IEEEDPAcos
	LIBDEF	IEEEDPLog10

	LIBINIT					* mathtrans.library
	LIBDEF	SPAtan
	LIBDEF	SPSin
	LIBDEF	SPCos
	LIBDEF	SPTan
	LIBDEF	SPSincos
	LIBDEF	SPSinh
	LIBDEF	SPCosh
	LIBDEF	SPTanh
	LIBDEF	SPExp
	LIBDEF	SPLog
	LIBDEF	SPPow
	LIBDEF	SPSqrt
	LIBDEF	SPTieee
	LIBDEF	SPFieee
	LIBDEF	SPAsin
	LIBDEF	SPAcos
	LIBDEF	SPLog10

	LIBINIT	-6				* potgo.library
	LIBDEF	AllocPotBits
	LIBDEF	FreePotBits
	LIBDEF	WritePotgo

	LIBINIT					* romboot.library
	LIBDEF	RomBoot

	LIBINIT	-42				* timer.device
	LIBDEF	AddTime
	LIBDEF	SubTime
	LIBDEF	CmpTime

	LIBINIT					* translator.library
	LIBDEF	Translate

* --- custom register structure --- *

	XEQ	_bltddat,	$DFF000
	XEQ	_dmaconr,	$DFF002
	XEQ	_vposr,		$DFF004
	XEQ	_vhposr,	$DFF006
	XEQ	_dskdatr,	$DFF008
	XEQ	_joy0dat,	$DFF00A
	XEQ	_joy1dat,	$DFF00C
	XEQ	_clxdat,	$DFF00E
	XEQ	_adkconr,	$DFF010
	XEQ	_pot0dat,	$DFF012
	XEQ	_pot1dat,	$DFF014
	XEQ	_potinp,	$DFF016
	XEQ	_serdatr,	$DFF018
	XEQ	_dskbytr,	$DFF01A
	XEQ	_intenar,	$DFF01C
	XEQ	_intreqr,	$DFF01E
	XEQ	_dskpt,		$DFF020
	XEQ	_dsklen,	$DFF024
	XEQ	_dskdat,	$DFF026
	XEQ	_refptr,	$DFF028
	XEQ	_vposw,		$DFF02A
	XEQ	_vhposw,	$DFF02C
	XEQ	_copcon,	$DFF02E
	XEQ	_serdat,	$DFF030
	XEQ	_serper,	$DFF032
	XEQ	_potgo,		$DFF034
	XEQ	_joytest,	$DFF036
	XEQ	_strequ,	$DFF038
	XEQ	_strvbl,	$DFF03A
	XEQ	_strhor,	$DFF03C
	XEQ	_strlong,	$DFF03E
	XEQ	_bltcon0,	$DFF040
	XEQ	_bltcon1,	$DFF042
	XEQ	_bltafwm,	$DFF044
	XEQ	_bltalwm,	$DFF046
	XEQ	_bltcpt,	$DFF048
	XEQ	_bltbpt,	$DFF04C
	XEQ	_bltapt,	$DFF050
	XEQ	_bltdpt,	$DFF054
	XEQ	_bltsize,	$DFF058
	XEQ	_bltcmod,	$DFF060
	XEQ	_bltbmod,	$DFF062
	XEQ	_bltamod,	$DFF064
	XEQ	_bltdmod,	$DFF066
	XEQ	_bltcdat,	$DFF070
	XEQ	_bltbdat,	$DFF072
	XEQ	_bltadat,	$DFF074
	XEQ	_dsksync,	$DFF07E
	XEQ	_cop1lc,	$DFF080
	XEQ	_cop2lc,	$DFF084
	XEQ	_copjmp1,	$DFF088
	XEQ	_copjmp2,	$DFF08A
	XEQ	_copins,	$DFF08C
	XEQ	_diwstrt,	$DFF08E
	XEQ	_diwstop,	$DFF090
	XEQ	_ddfstrt,	$DFF092
	XEQ	_ddfstop,	$DFF094
	XEQ	_dmacon,	$DFF096
	XEQ	_clxcon,	$DFF098
	XEQ	_intena,	$DFF09A
	XEQ	_intreq,	$DFF09C
	XEQ	_adkcon,	$DFF09E
	XEQ	_aud,		$DFF0A0
	XEQ	_bplpt,		$DFF0E0
	XEQ	_bplcon0,	$DFF100
	XEQ	_bplcon1,	$DFF102
	XEQ	_bplcon2,	$DFF104
	XEQ	_bpl1mod,	$DFF108
	XEQ	_bpl2mod,	$DFF10A
	XEQ	_bpldat,	$DFF110
	XEQ	_sprpt,		$DFF120
	XEQ	_spr,		$DFF140
	XEQ	_color,		$DFF180

