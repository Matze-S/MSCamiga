
FastWarn:
	move.l	#$20005,d1
	move.l	(4).w,a6
	jsr	-$d8(a6)
	tst.l	d0
	beq.s	Exit
	moveq.l	#5,d0
Exit:
	rts

