
*
* LED - on/off
*
* Written 12-Dec-89 13:15 by Matthias Schmidt
*

main:
	lea.l	$bfe001,a1
	bclr.b	#1,(a1)
	btst.b	#0,(a0)
	beq.s	exit
	bset.b	#1,(a1)
exit:
	rts

