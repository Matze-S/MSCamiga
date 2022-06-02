Reset:
	move.l	(4).w,a6
	jsr	-$96(a6)
	jsr	-$78(a6)
	not.l	34(a6)
	not.l	38(a6)
	clr.l	(4).w
	move.l	$fc0004,a0
	reset
	jmp	(a0)

