;:ts=8
	far	code
	far	data
	xdef	_main
_main:
	link	a5,#.2
	movem.l	.3,-(sp)
	move.l	#5,-4(a5)
	pea	.1+0
	jsr	_printf
	add.w	#4,sp
	move.l	-4(a5),-(sp)
	jsr	_LockDosList
	add.w	#4,sp
	move.l	d0,-16(a5)
	beq	.10001
	move.l	-4(a5),-(sp)
	pea	.1+62
	move.l	-16(a5),-(sp)
	jsr	_FindDosEntry
	lea	12(sp),sp
	move.l	d0,-16(a5)
	beq	.10002
	move.l	-16(a5),-(sp)
	pea	.1+67
	jsr	_printf
	add.w	#8,sp
	move.l	-16(a5),a0
	move.l	4(a0),-(sp)
	pea	.1+84
	jsr	_printf
	add.w	#8,sp
	move.l	-16(a5),a0
	move.l	28(a0),d0
	asl.l	#2,d0
	move.l	d0,-12(a5)
	move.l	d0,-(sp)
	pea	.1+97
	jsr	_printf
	add.w	#8,sp
	move.l	-16(a5),a0
	move.l	36(a0),-(sp)
	pea	.1+115
	jsr	_printf
	add.w	#8,sp
	move.l	-12(a5),a0
	move.l	(a0),-(sp)
	pea	.1+126
	jsr	_printf
	add.w	#8,sp
	move.l	-12(a5),a0
	move.l	4(a0),d0
	asl.l	#2,d0
	add.l	#1,d0
	move.l	d0,-(sp)
	pea	.1+139
	jsr	_printf
	add.w	#8,sp
	move.l	-12(a5),a0
	move.l	8(a0),d0
	asl.l	#2,d0
	move.l	d0,-8(a5)
	move.l	d0,-(sp)
	pea	.1+153
	jsr	_printf
	add.w	#8,sp
	move.l	-12(a5),a0
	move.l	12(a0),-(sp)
	pea	.1+173
	jsr	_printf
	add.w	#8,sp
	move.l	-8(a5),a0
	move.l	36(a0),-(sp)
	pea	.1+187
	jsr	_printf
	add.w	#8,sp
	move.l	-8(a5),a0
	move.l	40(a0),-(sp)
	pea	.1+202
	jsr	_printf
	add.w	#8,sp
	move.l	-8(a5),a0
	move.l	12(a0),-(sp)
	pea	.1+218
	jsr	_printf
	add.w	#8,sp
	move.l	-8(a5),a0
	move.l	20(a0),-(sp)
	pea	.1+235
	jsr	_printf
	add.w	#8,sp
	move.l	-12(a5),a0
	move.l	(a0),_unit
	move.l	-12(a5),a0
	move.l	12(a0),-4(a5)
	move.l	-8(a5),a0
	move.w	38(a0),_lowcyl
	move.l	-8(a5),a0
	move.w	42(a0),_highcyl
	move.l	-8(a5),a0
	move.w	14(a0),_surfaces
	move.l	-8(a5),a0
	move.w	22(a0),_blkspertrk
	move.w	_blkspertrk,a0
	move.l	a0,d1
	move.w	_lowcyl,d0
	muls.w	_surfaces,d0
	jsr	.mulu#
	move.l	#9,d1
	asl.l	d1,d0
	move.l	d0,_startoffset
	move.w	_blkspertrk,a0
	move.l	a0,d1
	move.w	_highcyl,a0
	move.l	a0,d0
	add.l	#1,d0
	move.w	_surfaces,a0
	move.l	d1,-(sp)
	move.l	a0,d1
	jsr	.mulu#
	move.l	(sp)+,d1
	jsr	.mulu#
	move.l	#9,d1
	asl.l	d1,d0
	move.l	d0,_endoffset
	jsr	_CreateMsgPort
	move.l	d0,_mp
	beq	.10003
	pea	48
	move.l	_mp,-(sp)
	jsr	_CreateIORequest
	add.w	#8,sp
	move.l	d0,_iob
	beq	.10004
	move.l	-4(a5),-(sp)
	move.l	_iob,-(sp)
	move.l	_unit,-(sp)
	move.l	-12(a5),a0
	move.l	4(a0),d0
	asl.l	#2,d0
	add.l	#1,d0
	move.l	d0,-(sp)
	jsr	_OpenDevice
	lea	16(sp),sp
	tst.b	d0
	beq	.10005
	pea	.1+258
	pea	__iob+44
	jsr	_fprintf
	add.w	#8,sp
	pea	10
	jsr	_exit
	add.w	#4,sp
	bra	.10006
.10005
	jsr	_install_funcs
	pea	.1+278
	jsr	_printf
	add.w	#4,sp
.10006
	bra	.10007
.10004
	pea	.1+330
	pea	__iob+44
	jsr	_fprintf
	add.w	#8,sp
	pea	20
	jsr	_exit
	add.w	#4,sp
.10007
	bra	.10008
.10003
	pea	.1+369
	pea	__iob+44
	jsr	_fprintf
	add.w	#8,sp
	pea	20
	jsr	_exit
	add.w	#4,sp
.10008
	bra	.10009
.10002
	pea	.1+396
	pea	__iob+44
	jsr	_fprintf
	add.w	#8,sp
	pea	10
	jsr	_exit
	add.w	#4,sp
.10009
	move.l	-4(a5),-(sp)
	jsr	_UnLockDosList
	add.w	#4,sp
	bra	.10010
.10001
	pea	.1+426
	pea	__iob+44
	jsr	_fprintf
	add.w	#8,sp
	pea	20
	jsr	_exit
	add.w	#4,sp
.10010
	clr.l	-(sp)
	jsr	_exit
	add.w	#4,sp
.4
	movem.l	(sp)+,.3
	unlk	a5
	rts
.2	equ	-16
.3	reg	
.1
	dc.b	80,67,72,68,58,45,72,97,110,100,108,101,114,32,118
	dc.b	49,46,48,32,45,45,32,67,111,112,121,114,105,103,104
	dc.b	116,32,40,67,41,32,49,57,57,49,32,98,121,32,77
	dc.b	97,116,116,104,105,97,115,32,83,99,104,109,105,100,116
	dc.b	10,0,80,67,72,68,0,100,111,108,112,32,58,61,32
	dc.b	48,120,37,48,56,108,120,10,0,116,121,112,101,32,58
	dc.b	61,32,37,108,100,10,0,102,115,115,109,112,32,58,61
	dc.b	32,48,120,37,48,56,108,120,10,0,103,118,32,58,61
	dc.b	32,37,108,100,10,0,85,110,105,116,32,58,61,32,37
	dc.b	108,117,10,0,68,101,118,105,99,101,32,58,61,32,37
	dc.b	115,10,0,69,110,118,105,114,111,110,32,58,61,32,48
	dc.b	120,37,48,56,108,120,10,0,70,108,97,103,115,32,58
	dc.b	61,32,37,108,117,10,0,76,111,119,67,121,108,32,58
	dc.b	61,32,37,108,117,10,0,72,105,103,104,67,121,108,32
	dc.b	58,61,32,37,108,117,10,0,83,117,114,102,97,99,101
	dc.b	115,32,58,61,32,37,108,117,10,0,66,108,111,99,107
	dc.b	115,80,101,114,84,114,97,99,107,32,58,61,32,37,108
	dc.b	117,10,0,79,112,101,110,68,101,118,105,99,101,32,102
	dc.b	97,105,108,101,100,33,10,0,80,67,72,68,58,45,72
	dc.b	97,110,100,108,101,114,32,100,111,115,32,102,117,110,99
	dc.b	116,105,111,110,115,32,105,110,115,116,97,108,108,101,100
	dc.b	32,115,117,99,99,101,115,102,117,108,108,121,46,10,0
	dc.b	78,111,116,32,101,110,111,117,103,104,32,109,101,109,111
	dc.b	114,121,32,102,111,114,32,97,32,116,104,101,32,105,111
	dc.b	32,98,108,111,99,107,33,10,0,85,110,97,98,108,101
	dc.b	32,116,111,32,99,114,101,97,116,101,32,109,115,103,112
	dc.b	111,114,116,33,10,0,67,97,110,39,116,32,102,105,110
	dc.b	100,32,116,104,101,32,80,67,72,68,58,45,68,101,118
	dc.b	105,99,101,33,10,0,67,97,110,39,116,32,108,111,99
	dc.b	107,32,116,104,101,32,100,101,118,105,99,101,32,108,105
	dc.b	115,116,33,10,0
	ds	0

   include  "exec/types.i"
   include  "devices/scsidisk.i"
   include  "dos/dos.i"
   include  "exec/io.i"
   include  "exec/memory.i"

   far code
   far data
   cseg

_install_funcs:
   movem.l  d2-d3/a2-a3,-(sp)
   move.l   #codeSize,d0
   moveq.l  #MEMF_PUBLIC,d1
   move.l   _SysBase#,a6
   jsr      _LVOAllocMem(a6)
   tst.l    d0
   beq.s    _install_error
   move.l   d0,a2                   ; a2 := code
   move.l   d0,a1
   lea.l    code(pc),a0
   move.l   #((codeSize/2)-1),d1
_copy_loop:
   move.w   (a0)+,(a1)+
   dbf      d1,_copy_loop
   moveq.l  #4,d2
   lea.l    _set_table(pc),a3
   move.l   a2,d3
_set_loop:
   move.w   (a3)+,d0
   move.w   (a3)+,a0
   exg.l    d0
   add.l    d3,d0
   move.l   _DOSBase#,a1
   jsr      _LVOSetFunction#(a6)
   move.l   d0,(a2)+
   dbf      d2,_set_loop
_install_error:
   movem.l  (sp)+,d2-d3/a2-a3
   rts

_set_table:
   dc.w  (open-code),_LVOOpen#
   dc.w  (close-code),_LVOClose#
   dc.w  (read-code),_LVORead#
   dc.w  (write-code),_LVOWrite#
   dc.w  (seek-code),_LVOSeek#

code:
   ds.l  5

block:
   ds.b  512

_lowcyl:
   dc.w  0
_highcyl:
   dc.w  0
_surfaces:
   dc.w  0
_blkspertrk:
   dc.w  0
_startoffset:
   dc.l  0
_endoffset:
   dc.l  0
_unit:
   dc.l  0
_flags:
   dc.l  0
_iob:
   dc.l  0
_mp:
   dc.l  0

open:
   move.l   d1,a0
   cmp.l    #'PCHD',(a0)
   bne.s    old_open
   cmp.w    #(':'<<8),4(a0)
   beq.s    new_open
old_open:
   move.l   code(pc),a0
   jmp      (a0)
new_open:
   cmp.l    #MODE_OLDFILE,d2
   bne.s    old_open
   cmp.l    #MODE_READWRITE,d2
   bne.s    old_open
   movem.l  d1/a6,-(sp)
   moveq.l  #8,d0
   moveq.l  #MEMF_PUBLIC,d1
   move.l   (_AbsExecBase#).w,a6
   jsr      _LVOAllocMem#(a6)
   tst.l    d0
   beq.s    end_open
   move.l   d0,a0
   move.l   #'PCHD',(a0)
   clr.l    4(a0)
   lsr.l    #2,d0
end_open:
   movem.l  (sp)+,d1/a6
   rts

close:
   move.l   d1,a1
   add.l    a1,a1
   add.l    a1,a1
   cmp.l    #'PCHD',(a1)
   beq.s    new_close
   move.l   (code+4)(pc),a0
   jmp      (a0)
new_close:
   movem.l  d1/a6,-(sp)
   moveq.l  #8,d0
   move.l   (_AbsExecBase#).w,a6
   jsr      _LVOFreeMem#(a6)
   movem.l  (sp)+,d1/a6
   rts

read:
   move.w   #CMD_READ,d0
   move.l   (code+8)(pc),a0
   bra.s    rdwr

write:
   move.w   #CMD_WRITE,d0
   move.l   (code+12)(pc),a0

rdwr:
   move.l   d1,a1
   add.l    a1,a1
   add.l    a1,a1
   cmp.l    #'PCHD',(a1)
   beq.s    new_rdwr
   jmp      (a0)
new_rdwr:
   movem.l  d1-d5/a2-a3/a6,-(sp)    ; d2 := data, d3 := length, d5 := actual
   move.l   4(a1),d4                ; d4 := offset, a2 := sector-size, a3 := cmd
   move.w   d0,a3
   move.w   #512,a2
   moveq.l  #0,d5
   cmp.l    a2,d4
   bcc.s    hd_rdwr

; block 0 ...
   cmp.w    #CMD_READ,a3            ; can't write to block 0 ...
   bne.s    new_rdwr_end
blk0_read:
   lea.l    block(pc),a0
   move.l   a0,a1
   moveq.l  #127,d0
   move.l   #$f6f6f6f6,d1
del_blk0_loop:
   move.l   d1,(a1)+
   dbf      d0,del_blk0_loop
   move.l   #'ABOO',(a0)+
   move.l   #('T'<<24),(a0)+
   move.w   _surfaces(pc),(a0)+
   move.w   _blkspertrk(pc),(a0)+
   move.w   _highcyl(pc),d0
   sub.w    _lowcyl(pc),d0
   move.w   d0,(a0)+
   move.l   a2,d0
   sub.w    d4,d0                   ; count := d0 := rest of block
   cmp.l    d0,d3
   bcc.s    1$                      ; ... length (d3) >= rest of block
   move.w   d3,d0                   ; length < rest of block --> count := length
1$ lea.l    block(pc),a0
   move.l   d2,a1
   sub.l    d0,d3                   ; length -= count
   add.l    d0,d5                   ; actual += count
   add.l    d0,d4                   ; offset += count
   bra.s    3$
2$ move.b   (a0)+,(a1)+
3$ dbf      d0,2$
   move.l   a1,d2                   ; d2 := data

; other blocks
hd_rdwr:
   tst.l    d3
   beq.s    new_rdwr_end
   move.l   d4,d0
   sub.l    a2,d0
   add.l    _startoffset(pc),d0
   move.l   d3,d1
   add.l    d0,d3
   cmp.l    _endoffset(pc),d3
   bcc.s    1$
   move.l   _endoffset(pc),d1
   sub.l    d0,d1
1$ move.l   d2,a0
   cmp.w    #CMD_READ,a3
   bne.s    hd_wr
hd_rd:
   bsr.s    rd
   bra.s    hd_cont
hd_wr:
;   bsr.s    wr
hd_cont:
   add.l    d0,d5
new_rdwr_end:
   move.l   d5,d0
   movem.l  (sp)+,d1-d5/a2-a3/a6
   rts

rd:                        ; (d0 := offset, d1 := length, a0 := data)
   movem.l  d2-d4/a2-a4,-(sp)
   move.l   d0,d2          ; d2 := offset
   move.l   d1,d3          ; d3 := length
   move.l   a0,a2          ; a2 := data
   moveq.l  #0,d4          ; d4 := actual
   move.w   #512,a3        ; a3 := sector size - constant 512
   tst.l    d3
   beq.s    rd_end
   and.w    #511,d0
   beq.s    rd_2
rd_1:
   move.w   d2,d0
   and.w    #-512,d0
   move.l   a3,d1
   lea.l    block(pc),a0
   bsr.s    _readsecs
   cmp.l    a3,d0
   bne.s    rd_error
   move.w   d2,d0
   and.w    #511,d0        ; d0 := offset in sector (0-511)
   move.l   a3,d1
   sub.w    d0,d1          ; d1 := # of rest bytes in sector (1-512)
   cmp.l    d1,d3
   bcc.s    1$             ; ... length (d3) is >= rest of bytes
   move.w   d3,d1
1$ sub.l    d1,d3          ; length -= count
   move.w   d1,d4          ; actual := count
   lea.l    block(pc),a0
   add.w    d0,a0
   bra.s    3$
2$ move.b   (a0)+,(a2)+
3$ dbf      d1,2$
   tst.l    d3
   beq.s    rd_end
   and.w    #-512,d2       ; offset = (offset + 511) & ~511
   add.l    a3,d2
rd_2:
   cmp.l    a3,d3
   bcs.s    rd_3           ; ... length < size of sector (512)
   move.l   d2,d0
   move.l   d3,d1
   and.w    #-512,d1       ; d1 := length & ~511
   move.l   d1,a4          ; a4 := d1
   move.l   a2,a0
   bsr.s    _readsecs
   add.l    d0,d4          ; actual(file) += actual(iob)
   cmp.l    a4,d0
   bne.s    rd_error       ; actual <> length & ~511
   sub.l    a4,d3
   beq.s    rd_end         ; ... length = 0
   add.l    a4,d2          ; offset += length & ~511
   add.l    a4,a2          ; data += length & ~511
rd_3:
   move.l   d2,d0
   move.l   a3,d1
   lea.l    block(pc),a0
   bsr.s    _readsecs
   cmp.l    a3,d0
   bne.s    rd_error
   add.l    d3,d4          ; actual += length
   lea.l    block(pc),a0
   bra.s    5$
4$ move.b   (a0)+,(a2)+
5$ dbf      d3,4$
rd_error:
rd_end:
   move.l   d4,d0
   movem.l  (sp)+,d2-d4/a2-a4
   rts

_readsecs:
   move.l   _iob(pc),a1
   move.l   d0,IO_OFFSET(a1)
   move.l   d1,IO_LENGTH(a1)
   move.l   a0,IO_DATA(a1)
   move.w   #CMD_READ,IO_COMMAND(a1)
   move.l   (_AbsExecBase#).w,a6
   jsr      _LVODoIO#(a6)
   move.l   _iob(pc),a1
   move.l   IO_ACTUAL(a1),d0
   rts

seek:
   move.l   d1,a1
   add.l    a1,a1
   add.l    a1,a1
   cmp.l    #'PCHD',(a1)
   beq.s    new_seek
   move.l   (code+16)(pc),a0
   jmp      (a0)
new_seek:
   cmp.l    #OFFSET_END,d2
   bne.s    1$
   move.l   _endoffset(pc),d0
   sub.l    d3,d0
   bra.s    3$
1$ cmp.l    #OFFSET_BEGINNING,d2
   bne.s    2$
   move.l   _startoffset(pc),d0
   add.l    d3,d0
   bra.s    3$
2$ move.l   4(a1),d0
   cmp.l    #OFFSET_CURRENT,d2
   bne.s    3$
   add.l    d3,d0
3$ move.l   d0,4(a1)
   rts

codeSize equ (*-code)

	xref	_exit
	xref	_install_funcs
	xref	_printf
	xref	_fprintf
	xref	_CreateMsgPort
	xref	_CreateIORequest
	xref	_OpenDevice
	xref	_FindDosEntry
	xref	_UnLockDosList
	xref	_LockDosList
	xref	.begin
	dseg
	xref	_mp
	xref	_iob
	xref	_endoffset
	xref	_startoffset
	xref	_unit
	xref	_blkspertrk
	xref	_surfaces
	xref	_highcyl
	xref	_lowcyl
	xref	__iob
	end
