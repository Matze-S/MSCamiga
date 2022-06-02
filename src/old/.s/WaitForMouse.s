WaitForMouse:
	btst.b	#6,$bfe001
	bne.s	WaitForMouse
	rts

