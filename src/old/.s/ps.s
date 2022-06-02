
;
; CheckSummen-Prüfroutine für die Start-Meldung (System/Version) zum
; integrieren in mein geknacktes Superbase Professional 3.02
;
; by 'Top Secret!' of SHADOW 10-Mar-90
;

chksum:
	movem.l	d1-d2/a0-a1/a6,-(sp)
	move.l	(4).w,a6
	sub.l	a1,a1
	jsr	-$126(a6)
	move.l	d0,a0
	moveq.l	#0,d1
	move.l	$ac(a0),d0
	beq.s	wb_start
	lsl.l	#2,d0
	move.l	d0,a0
	lea.l	$3c(a0),a0
	bra.s	seg_loop
wb_start:
	move.l	$80(a0),d0
	lsl.l	#2,d0
	move.l	d0,a0
	lea.l	$c(a0),a0
seg_loop:
	move.l	(a0),d0
	beq.s	error
	lsl.l	#2,d0
	move.l	d0,a0
	addq.w	#1,d1
	cmp.w	#98,d1
	bne.s	seg_loop
	lea.l	$6cbf(a0),a0
	moveq.l	#0,d0
	move.w	#391,d1
	moveq.l	#0,d2
chksum_loop:
	move.b	(a0)+,d2
	eor.b	d1,d2
	add.l	d2,d0
	dbf	d1,chksum_loop
error:
	sub.l	#$a39e,d0		; Prüfsumme
	movem.l	(sp)+,d1-d2/a0-a1/a6
	rts

