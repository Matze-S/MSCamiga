
*
* Parser
*

* Offsets and Flags from Exec ...

_SysBase	equ $4
_LVOAllocMem	equ -$c6
_LVOFreeMem	equ -$d2
_LVOOpenLibrary equ -$228
_LVOCloseLibrary equ -$19e

MEMF_PUBLIC	equ $1

* ... from DOS ...

_LVOOutput	equ -$3c
_LVOWrite	equ -$30

* and Register-Equals for the main-program ...

REG_Handle	equr d6
REG_Address	equr a5
REG_Length	equr d5

* ... and for _Search ...

REG_SearchAddr	equr a2


* MAIN-PROGRAM

main	move.l d0,REG_Length
	move.l a0,a4
	moveq #MEMF_PUBLIC,d1
	move.l _SysBase,a6
	jsr _LVOAllocMem(a6)
	move.l d0,REG_Address
	beq.s error
	move.l d0,a0
	move.l REG_Length,d0
copy_loop	move.b (a4)+,(a0)+
	subq.l #1,d0
	bne.s copy_loop
	lea DosName(pc),a1
	jsr _LVOOpenLibrary(a6)
	move.l d0,a6
	jsr _LVOOutput(a6)
	move.l d0,REG_Handle
	move.l REG_Address,REG_SearchAddr
main_loop	bsr _Search
	tst.l d0
	beq.s break
	movem.l d0/a1,-(sp)
	lea Text1(pc),a0
	move.l a0,d2
	moveq #Text1Length,d3
	btst.b #1,d1
	beq.s continue
	add.l d3,d2
	moveq #Text2Length,d3
continue	move.l REG_Handle,d1
	jsr _LVOWrite(a6)
	movem.l (sp)+,d0/a1
	move.l d0,d3
	move.l a1,d2
	move.l REG_Handle,d1
	jsr _LVOWrite(a6)
	lea CR(pc),a0
	move.l a0,d2
	moveq #CRLength,d3
	move.l REG_Handle,d1
	jsr _LVOWrite(a6)
	bra.s main_loop
break	move.l a6,a1
	move.l _SysBase,a6
	jsr _LVOCloseLibrary(a6)
	move.l REG_Address,a1
	move.l REG_Length,d0
	jsr _LVOFreeMem(a6)
error	rts

DosName	dc.b 'dos.library',0
Text1	dc.b 'OHNE ANFÜHRUNGSZEICHEN: "'
Text1Length	equ *-Text1
Text2	dc.b 'MIT ANFÜHRUNGSZEICHEN: "'
Text2Length	equ *-Text2
CR	dc.b 34,10
CRLength	equ *-CR
	even


* _Search

_Search	move.l REG_SearchAddr,a1
	cmp.b #32,(REG_SearchAddr)+
	beq.s _Search
	moveq #0,d0
	cmp.b #10,(a1)
	beq.s _SearchEnd
	moveq #32,d1
	cmp.b #34,(a1)
	bne.s _Search1
	move.l REG_SearchAddr,a1
	addq.b #2,d1
_Search1	move.l a1,REG_SearchAddr
_Search2	addq.l #1,REG_SearchAddr
	cmp.b #10,(REG_SearchAddr)
	beq.s _Search3
	cmp.b (REG_SearchAddr),d1
	bne.s _Search2
_Search3	move.l REG_SearchAddr,d0
	sub.l a1,d0
	cmp.b #10,(REG_SearchAddr)
	beq.s _SearchEnd
	addq.l #1,REG_SearchAddr
_SearchEnd	rts

	end

