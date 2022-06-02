; Copyright (C) 1990 by Matthias Schmidt


;
; vertrks.asm -- Assembler sub routine for the HDFormat Utility
;
; version 1.52
;


;------------ included files ------------

	include "exec/types.i"
	include "exec/io.i"
	include	"libraries/dos.i"
	include "Harddisk.i"

;------------ external references and definitions ------------

	XDEF	_dp
	XDEF	_vertrks
	XREF	_sense
	XREF	_iob
	XREF	_SysBase
	XREF	_DOSBase
	XREF	_LVODoIO
	XREF	_LVOOutput
	XREF	_LVOSetSignal
	XREF	_LVOWrite

;------------ code ------------

;
; this is the fast verify routine of the HDFormat utility
;
;  4(sp).l = start track #
;  8(sp).l = end track #
;
;     d0.l = if no error, (-1) -- otherwise, the track # is returned
;

_vertrks:
	movem.l d2-d7/a2-a6,-(sp)
	movem.l 48(sp),d4-d5
	moveq.l	#0,d6
	move.b	(_dp+hddp_NumHeads)(pc),d6
	lea.l	-hdc_SIZEOF(sp),a5
	lea.l	-50(a5),sp
	move.l	_DOSBase,a6
	jsr	_LVOOutput(a6)
	move.l	d0,d7
	move.l	_iob,a2
	moveq.l	#0,d0
	move.b	(_dp+hddp_NumSecs)(pc),d0
	lsl.l	#8,d0
	move.b	(_dp+hddp_StepRate)(pc),d0
	move.w	d0,4(a5)
	move.b	#HDCMD_CHECK_TRACK,(a5)
	bra	_vertrks_loop1_entry
_vertrks_loop1:
	move.l	sp,a0
	lea.l	_vertrks_text1(pc),a1
_vertrks_loop2:
	move.b	(a1)+,(a0)+
	bne.s	_vertrks_loop2
	subq.w	#1,a0
	move.l	d4,d2
	divu.w	d6,d2
	moveq.l #0,d0
	move.w	d2,d0
	jsr	_utoa
	lea.l	_vertrks_text2(pc),a1
_vertrks_loop3:
	move.b	(a1)+,(a0)+
	bne.s	_vertrks_loop3
	subq.w	#1,a0
	moveq.l #0,d0
	swap	d2
	move.w	d2,d0
	jsr	_utoa
	move.b	#' ',(a0)+
	sub.l	sp,a0
	move.b	d2,1(a5)
	swap	d2
	move.b	d2,3(a5)
	lsr.w	#2,d2
	and.b	#$c0,d2
	move.b	d2,2(a5)
	lsr.w	#1,d2
	and.b	#$80,d2
	or.b	d2,1(a5)
	move.l	d7,d1
	move.l	sp,d2
	move.l	a0,d3
	move.l	_DOSBase,a6
	jsr	_LVOWrite(a6)
	move.l	a5,IO_DATA(a2)
	move.w	#HD_SENDCMD,IO_COMMAND(a2)
	move.l	a2,a1
	move.l	_SysBase,a6
	jsr	_LVODoIO(a6)
	move.w	#HD_GETSENSE,IO_COMMAND(a2)
	move.l	a2,a1
	jsr	_LVODoIO(a6)
	move.l	IO_ACTUAL(a2),_sense
	move.l	d4,d0
	tst.b	IO_ACTUAL(a2)
	bne.s	_vertrks_error
	moveq.l	#0,d0
	moveq.l	#0,d1
	jsr	_LVOSetSignal(a6)
	btst.l	#SIGBREAKB_CTRL_C,d0
	bne.s	_vertrks_error
	addq.l	#1,d4
_vertrks_loop1_entry:
	cmp.l	d5,d4
	bcs	_vertrks_loop1
	moveq.l #-1,d0
_vertrks_error:
	lea.l	(50+hdc_SIZEOF)(sp),sp
	movem.l (sp)+,d2-d7/a2-a6
	rts

_vertrks_text1:
	dc.b	13,'Verifying cylinder #',0
_vertrks_text2:
	dc.b	', head #',0
	ds.w	0

;-------------------------------------------------------------------------

	;------ this routine writes the contents of d0 as a
	;------ ascii-string in the area of memory a0 pointed to
_utoa:
	movem.l d2-d3,-(sp)
	moveq.l #4,d1
	moveq.l #0,d2
	move.w	#10000,d3
_utoa_loop:
	divu.w	d3,d0
	tst.w	d0
	bne.s	_utoa_ok1
	tst.w	d1
	beq.s	_utoa_ok1
	tst.w	d2
	beq.s	_utoa_ok2
_utoa_ok1:
	moveq.l #1,d2
	add.b	#'0',d0
	move.b	d0,(a0)+
_utoa_ok2:
	clr.w	d0
	swap	d0
	divu.w	#10,d3
	dbf	d1,_utoa_loop
	move.l	a0,d0
	movem.l (sp)+,d2-d3
_utoa_end:
	rts

	END

;------------ end of source ------------

