
	opt	a+,o+,p+,t+

_Reset:
	move.l	(4).w,a6		; AbsExecBase
	jsr	-$78(a6)		; Disable()
	jsr	-$96(a6)		; SuperState()
	sub.l	a0,a0
	move.l	_Reset_Code(pc),(a0)
	jmp	(a0)

_Reset_Code:
	reset
	dc.w	$4ef9

	END

