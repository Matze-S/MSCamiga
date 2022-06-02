
	section	text,CODE_C

	move.l	4,a6
	jsr	-120(a6)
	jsr	-150(a6)
	move.l	sp,usp
	move.l	d0,sp

	dc.w	$f000,$4200
	move.l	d0,d2

	and.w	#$dfff,sr

	jsr	-126(a6)
	moveq.l	#0,d0
	rts

