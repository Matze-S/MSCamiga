
;
; RegMon 
; 1988 by M.Schmidt & G.Auwärter 
;

RegMon	movem.l d0-d7/a0-a7,-(sp)
	move.w sr,-(sp)
	lea RegMonBuffTab,a0
	lea RegMonDivTab,a1
	moveq #0,d0
RegMonLoop1	moveq #0,d1
	move.l (a0,d0.w),a2
	move.l 2(a7,d0.w),d3
RegMonLoop2	moveq #'0'-1,d2
	move.l d1,d4
	lsl.l #2,d4
RegMonLoop3	addq.b #1,d2
	move.l d3,d5
	sub.l (a1,d4.w),d3
	bcc RegMonLoop3
	move.l d5,d3
	move.b d2,(a2,d1.w)
	addq.b #1,d1
	cmp.b #10,d1
	bne RegMonLoop2
	moveq #0,d1
	move.l 2(a7,d0.w),d3
RegMonLoop4	rol.l #4,d3
	move.b d3,d2
	and.b #15,d2
	cmp.b #9,d2
	ble RegMonOk1
	addq.b #7,d2
RegMonOk1	add.b #48,d2
	move.b d2,12(a2,d1.w)
	addq.b #1,d1
	cmp.b #8,d1
	bne RegMonLoop4
	moveq #0,d1
RegMonLoop5	rol.l #1,d3
	move.b d3,d2
	and.b #1,d2
	add.b #'0',d2
	move.b d2,22(a2,d1.w)
	addq.b #1,d1
	cmp.b #32,d1
	bne RegMonLoop5
	addq.l #4,d0
	cmp.l #68,d0
	bne RegMonLoop1
	moveq #0,d2
	move.w (sp)+,d0
	lea RegMonStatReg,a0
RegMonLoop6	rol.w #1,d0
	move.b d0,d1
	and.b #1,d1
	beq RegMonOk2
	move.b #'*',(a0,d2)
	bra RegMonOk3
RegMonOk2	move.b #'.',(a0,d2)
RegMonOk3	addq.b #1,d2
	cmp.b #16,d2
	bne RegMonLoop6
	moveq #0,d0
	lea RegMonDosName,a1
	move.l $04,a6
	jsr -552(a6)
	move.l d0,a6
	jsr -60(a6)
	move.l d0,d1
	move.l #RegMonBuffer,d2
	move.l #RegMonBuffLen,d3
	jsr -48(a6)
	move.l a6,a1
	move.l $04,a6
	jsr -414(a6)
	movem.l (sp)+,d0-d7/a0-a7
	rts

RegMonBuffer	dc.b $0a,"Register:",$0a
	dc.b "---------",$0a
	dc.b "     T S  MSK   XNZVC",$0a," SR: "
RegMonStatReg	dc.b "0123456789012345",$0a
	dc.b " D0: "
RegMonD0	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," D1: "
RegMonD1	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," D2: "
RegMonD2	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," D3: "
RegMonD3	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," D4: "
RegMonD4	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," D5: "
RegMonD5	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," D6: "
RegMonD6	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," D7: "
RegMonD7	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," A0: "
RegMonA0	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," A1: "
RegMonA1	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," A2: "
RegMonA2	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," A3: "
RegMonA3	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," A4: "
RegMonA4	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," A5: "
RegMonA5	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," A6: "
RegMonA6	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," A7: "
RegMonA7	dc.b "0123456789 $01234567 %01234567890123456789012345678901"
	dc.b $0a," PC: "
RegMonPC	dc.b "0123456789 $01234567 %01234567890123456789012345678901",$0a,$0a
RegMonBuffLen	equ *-RegMonBuffer
	even

RegMonBuffTab	dc.l RegMonD0,RegMonD1,RegMonD2,RegMonD3
	dc.l RegMonD4,RegMonD5,RegMonD6,RegMonD7
	dc.l RegMonA0,RegMonA1,RegMonA2,RegMonA3
	dc.l RegMonA4,RegMonA5,RegMonA6,RegMonA7
	dc.l RegMonPC

RegMonDivTab	dc.l 1000000000
	dc.l 100000000
	dc.l 10000000
	dc.l 1000000
	dc.l 100000
	dc.l 10000
	dc.l 1000
	dc.l 100
	dc.l 10
	dc.l 1

RegMonDosName	dc.b "dos.library",0
	even

