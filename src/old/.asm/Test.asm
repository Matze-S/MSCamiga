; Copyright (C) 1989 by Matthias Schmidt

;
; Test.asm - a test program for the harddisk.device
;

_main:
	;------	replyPort.mp_SigTask = FindTask(0L)
	move.l	(4).w,a6
	jsr	-$126(a6)
	lea.l	replyPort(pc),a2
	move.l	d0,16(a2)

	;------	replyPort.mp_SigBit = AllocSignal(-1L)
	moveq.l	#-1,d0
	jsr	-$14a(a6)
	move.b	d0,15(a2)

	;------	OpenDevice("harddisk.device",0L,&ioRequest,0L)
	lea.l	devName(pc),a0
	moveq.l #0,d0
	lea.l	ioRequest(pc),a1
	moveq.l #0,d1
	jsr	-$1bc(a6)

	;------	CloseDevice(&ioRequest)
	lea.l	ioRequest(pc),a1
	jsr	-$1c2(a6)

	;------	FreeSignal((ULONG)replyPort.mp_SigBit)
	moveq.l	#0,d0
	move.b	(replyPort+15)(pc),d0
	jmp	-$150(a6)

devName:
	dc.b	'harddisk.device',0
	ds.w	0

replyPort:
	dc.l	0,0
	dc.b	4,0
	dc.l	devName
	dc.b	0,0
	dc.l	0,(replyPort+24),0,(replyPort+20)

ioRequest:
	dc.l	0,0
	dc.b	5,0
	dc.l	devName,replyPort
	dc.w	48
	ds.b	48

