
*
AllocSegList:			* Pointer to SegListTable -> a1
	movem.l	a2/a3,-(sp)
	move.l	a1,a2
	move.l	a1,a3
allocloop:
	movem.l	(a2)+,d0/a1
	exg.l	d0,a1
	subq.l	#4,a1
	jsr	-$cc(a6)
	tst.l	d0
	beq.s	error
	move.l	d0,a0
	movem.l	-4(a2),d0/d1
	lsr.l	#2,d1
	movem.l	d0/d1,(a0)
	bne.s	allocloop
	move.l	(a3),d0
	lsr.l	#2,d0
end:
	movem.l	(sp)+,a2/a3
	rts
error:
	subq.l	#8,a2
freeloop:
	move.l	-(a2),d0
	move.l	-(a2),a1
	subq.l	#4,a1
	jsr	-$d2(a6)
	cmp.l	a2,a3
	bne.s	freeloop
	moveq	#0,d0
	bra.s	end
*

