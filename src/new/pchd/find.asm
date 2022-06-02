;:ts=8
	far	code
	far	data
# 18 'find.c' 425530436
^| .2
	xdef	_main
_main:
	link	a5,#.3
	movem.l	.4,-(sp)
~ 'DosEnvec'
~ 1 20 80
~ de_TableSize 0 "L"
~ de_SizeBlock 4 "L"
~ de_SecOrg 8 "L"
~ de_Surfaces 12 "L"
~ de_SectorPerBlock 16 "L"
~ de_BlocksPerTrack 20 "L"
~ de_Reserved 24 "L"
~ de_PreAlloc 28 "L"
~ de_Interleave 32 "L"
~ de_LowCyl 36 "L"
~ de_HighCyl 40 "L"
~ de_NumBuffers 44 "L"
~ de_BufMemType 48 "L"
~ de_MaxTransfer 52 "L"
~ de_Mask 56 "L"
~ de_BootPri 60 "l"
~ de_DosType 64 "L"
~ de_Baud 68 "L"
~ de_Control 72 "L"
~ de_BootBlocks 76 "L"
~ dep -4 "#:" 1
~ 'FileSysStartupMsg'
~ 2 4 16
~ fssm_Unit 0 "L"
~ fssm_Device 4 "l"
~ fssm_Environ 8 "l"
~ fssm_Flags 12 "L"
~ fssmp -8 "#:" 2
~ 'DosList'
~ 'MsgPort'
~ 'Node'
~ 5 5 14
~ ln_Succ 0 "#:" 5
~ ln_Pred 4 "#:" 5
~ ln_Type 8 "C"
~ ln_Pri 9 "c"
~ ln_Name 10 "#c"
~ 'List'
~ 6 5 14
~ lh_Head 0 "#:" 5
~ lh_Tail 4 "#:" 5
~ lh_TailPred 8 "#:" 5
~ lh_Type 12 "C"
~ l_pad 13 "C"
~ 4 5 34
~ mp_Node 0 ":" 5
~ mp_Flags 14 "C"
~ mp_SigBit 15 "C"
~ mp_SigTask 16 "#v"
~ mp_MsgList 20 ":" 6
~ ''
~ ''
~ 8 6 24
~ dol_Handler 0 "l"
~ dol_StackSize 4 "l"
~ dol_Priority 8 "l"
~ dol_Startup 12 "L"
~ dol_SegList 16 "l"
~ dol_GlobVec 20 "l"
~ ''
~ 'DateStamp'
~ 10 3 12
~ ds_Days 0 "l"
~ ds_Minute 4 "l"
~ ds_Tick 8 "l"
~ 9 3 20
~ dol_VolumeDate 0 ":" 10
~ dol_LockList 12 "l"
~ dol_DiskType 16 "l"
~ ''
~ 'AssignList'
~ 12 2 8
~ al_Next 0 "#:" 12
~ al_Lock 4 "l"
~ 11 2 8
~ dol_AssignName 0 "#C"
~ dol_List 4 "#:" 12
~ 7 3 24
~ dol_handler 0 ":" 8
~ dol_volume 0 ":" 9
~ dol_assign 0 ":" 11
~ 3 6 44
~ dol_Next 0 "l"
~ dol_Type 4 "l"
~ dol_Task 8 "#:" 4
~ dol_Lock 12 "l"
~ dol_misc 16 ":" 7
~ dol_Name 40 "l"
~ dolp -12 "#:" 3
~~ argc 8 "l"
~~ argv 12 "##c"
^^^^^	pea	.1+0
	jsr	_printf
	add.w	#4,sp
^^	pea	5
	jsr	_LockDosList
	add.w	#4,sp
	move.l	d0,-12(a5)
	beq	.10001
^	pea	4
	pea	.1+62
	move.l	-12(a5),-(sp)
	jsr	_FindDosEntry
	lea	12(sp),sp
	move.l	d0,-12(a5)
	beq	.10002
^	move.l	-12(a5),-(sp)
	pea	.1+67
	jsr	_printf
	add.w	#8,sp
^	move.l	-12(a5),a0
	move.l	4(a0),-(sp)
	pea	.1+84
	jsr	_printf
	add.w	#8,sp
^	move.l	-12(a5),a0
	move.l	28(a0),d0
	asl.l	#2,d0
	move.l	d0,-8(a5)
	move.l	d0,-(sp)
	pea	.1+97
	jsr	_printf
	add.w	#8,sp
^^^	move.l	-12(a5),a0
	move.l	36(a0),-(sp)
	pea	.1+115
	jsr	_printf
	add.w	#8,sp
^^	move.l	-8(a5),a0
	move.l	(a0),-(sp)
	pea	.1+126
	jsr	_printf
	add.w	#8,sp
^	move.l	-8(a5),a0
	move.l	4(a0),d0
	asl.l	#2,d0
	add.l	#1,d0
	move.l	d0,-(sp)
	pea	.1+139
	jsr	_printf
	add.w	#8,sp
^	move.l	-8(a5),a0
	move.l	8(a0),d0
	asl.l	#2,d0
	move.l	d0,-4(a5)
	move.l	d0,-(sp)
	pea	.1+153
	jsr	_printf
	add.w	#8,sp
^^	move.l	-8(a5),a0
	move.l	12(a0),-(sp)
	pea	.1+173
	jsr	_printf
	add.w	#8,sp
^	move.l	-4(a5),a0
	move.l	36(a0),-(sp)
	pea	.1+187
	jsr	_printf
	add.w	#8,sp
^	move.l	-4(a5),a0
	move.l	40(a0),-(sp)
	pea	.1+202
	jsr	_printf
	add.w	#8,sp
^	move.l	-4(a5),a0
	move.l	12(a0),-(sp)
	pea	.1+218
	jsr	_printf
	add.w	#8,sp
^	move.l	-4(a5),a0
	move.l	20(a0),-(sp)
	pea	.1+235
	jsr	_printf
	add.w	#8,sp
^^	move.l	-8(a5),a0
	move.l	(a0),_unit
^	move.l	-8(a5),a0
	move.l	12(a0),_flags
^^	move.l	-4(a5),a0
	move.w	38(a0),_lowcyl
^	move.l	-4(a5),a0
	move.w	42(a0),_highcyl
^	move.l	-4(a5),a0
	move.w	14(a0),_surfaces
^	move.l	-4(a5),a0
	move.w	22(a0),_blkspertrk
^^	move.l	-8(a5),a0
	move.l	4(a0),d0
	asl.l	#2,d0
	add.l	#1,d0
	move.l	d0,-(sp)
	pea	_devname
	jsr	_strcpy
	add.w	#8,sp
^^	move.w	_blkspertrk,a0
	move.l	a0,d1
	move.w	_lowcyl,d0
	muls.w	_surfaces,d0
	jsr	.mulu#
	move.l	#9,d1
	asl.l	d1,d0
	move.l	d0,_startoffset
^^	move.w	_blkspertrk,a0
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
^^^^^^^^^^^^^^^^^^^^
^	jsr	_install_funcs
^	pea	.1+258
	jsr	_printf
	add.w	#4,sp
^^	move.l	-12(a5),-(sp)
	jsr	_FreeDosEntry
	add.w	#4,sp
^	bra	.10003
.10002
^	pea	.1+310
	pea	__iob+44
	jsr	_fprintf
	add.w	#8,sp
^	pea	10
	jsr	_exit
	add.w	#4,sp
^.10003
^	pea	4
	jsr	_UnLockDosList
	add.w	#4,sp
^	pea	.1+340
	jsr	_printf
	add.w	#4,sp
^	bra	.10004
.10001
^	pea	.1+353
	pea	__iob+44
	jsr	_fprintf
	add.w	#8,sp
^	pea	20
	jsr	_exit
	add.w	#4,sp
^.10004
^	clr.l	-(sp)
	jsr	_exit
	add.w	#4,sp
^.5
	movem.l	(sp)+,.4
	unlk	a5
	rts
.2
.3	equ	-12
.4	reg	
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
	dc.b	117,10,0,80,67,72,68,58,45,72,97,110,100,108,101
	dc.b	114,32,100,111,115,32,102,117,110,99,116,105,111,110,115
	dc.b	32,105,110,115,116,97,108,108,101,100,32,115,117,99,99
	dc.b	101,115,102,117,108,108,121,46,10,0,67,97,110,39,116
	dc.b	32,102,105,110,100,32,116,104,101,32,80,67,72,68,58
	dc.b	45,68,101,118,105,99,101,33,10,0,85,110,108,111,99
	dc.b	107,101,100,46,46,46,10,0,67,97,110,39,116,32,108
	dc.b	111,99,107,32,116,104,101,32,100,101,118,105,99,101,32
	dc.b	108,105,115,116,33,10,0
	ds	0

   include  "exec/types.i"
   include  "devices/scsidisk.i"
   include  "dos/dos.i"
   include  "exec/io.i"
   include  "exec/lists.i"
   include  "exec/memory.i"
   include  "exec/nodes.i"
   include  "exec/ports.i"

   far code
   far data
   cseg

_AbsExecBase equ 4

_install_funcs:
   movem.l  d2-d3/a2-a3,-(sp)
   move.l   #codeSize,d0
   moveq.l  #MEMF_PUBLIC,d1
   move.l   _SysBase#,a6
   jsr      _LVOAllocMem(a6)
   tst.l    d0
   beq      _install_error
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
   moveq.l  #0,d0
   move.w   (a3)+,d0
   move.w   (a3)+,a0
   add.l    d3,d0
   move.l   _DOSBase#,a1
   jsr      _LVOSetFunction#(a6)
   move.l   d0,(a2)+
   dbf      d2,_set_loop
_install_error:
   movem.l  (sp)+,d2-d3/a2-a3
   rts

_set_table:
   dc.w  (open-code),-_LVOOpen#
   dc.w  (close-code),-_LVOClose#
   dc.w  (read-code),-_LVORead#
   dc.w  (write-code),-_LVOWrite#
   dc.w  (seek-code),-_LVOSeek#

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
_mp:
   dc.l  0,0
   dc.b  NT_MSGPORT,0
   dc.l  0
   dc.b  PA_SIGNAL,0
   dc.l  0
   dc.l  0,0,0
_iob:
   dc.l  0,0
   dc.b  NT_MESSAGE,0
   dc.l  0,0
   dc.w  IOSTD_SIZE
   dc.l  0,0
   dc.w  0
   dc.b  0,0
   dc.l  0,0,0,0
_devname:
   ds.b  16

open:
   move.l   d1,a0
   cmp.l    #'PCHD',(a0)
   bne      old_open
   cmp.w    #(':'<<8),4(a0)
   beq      new_open
old_open:
   move.l   code(pc),a0
   jmp      (a0)
new_open:
   cmp.l    #MODE_OLDFILE,d2
   beq      1$
   cmp.l    #MODE_READWRITE,d2
   bne      old_open
1$ movem.l  d1/a6,-(sp)
   moveq.l  #8,d0
   moveq.l  #MEMF_PUBLIC,d1
   move.l   (_AbsExecBase#).w,a6
   jsr      _LVOAllocMem#(a6)
   tst.l    d0
   beq      end_open
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
   beq      new_close
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
   bra      rdwr

write:
   move.w   #CMD_WRITE,d0
   move.l   (code+12)(pc),a0

rdwr:
   move.l   d1,a1
   add.l    a1,a1
   add.l    a1,a1
   cmp.l    #'PCHD',(a1)
   beq      new_rdwr
   jmp      (a0)
new_rdwr:
   movem.l  d1-d5/a1-a3/a6,-(sp)    ; d2 := data, d3 := length, d5 := actual
   move.l   4(a1),d4                ; d4 := offset, a2 := sector-size, a3 := cmd
   move.w   d0,a3
   move.w   #512,a2
   moveq.l  #0,d5
   cmp.l    a2,d4
   bcc      hd_rdwr

; block 0 ...
   cmp.w    #CMD_READ,a3            ; can't write to block 0 ...
   bne      new_rdwr_end
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
   bcc      1$                      ; ... length (d3) >= rest of block
   move.w   d3,d0                   ; length < rest of block --> count := length
1$ lea.l    block(pc),a0
   add.l    d4,a0                   ; source += count
   move.l   d2,a1
   sub.l    d0,d3                   ; length -= count
   add.l    d0,d5                   ; actual += count
   add.l    d0,d4                   ; offset += count
   bra      3$
2$ move.b   (a0)+,(a1)+
3$ dbf      d0,2$
   move.l   a1,d2                   ; d2 := data

; other blocks
hd_rdwr:
   tst.l    d3
   beq      new_rdwr_end
   bmi      new_rdwr_end
   move.l   d4,d0
   sub.l    a2,d0
   add.l    _startoffset(pc),d0
   move.l   d3,d1
   add.l    d0,d3
   cmp.l    _endoffset(pc),d3
   bcs      1$
   beq      1$
   move.l   _endoffset(pc),d1
   sub.l    d0,d1
   bpl.s    1$
   moveq.l  #0,d1
1$ move.l   d2,a0
   cmp.w    #CMD_READ,a3
   bne      hd_wr
hd_rd:
   bsr      rd
   bra      hd_cont
hd_wr:
   bsr      wr
hd_cont:
   add.l    d0,d5
new_rdwr_end:
   move.l   d5,d0
   movem.l  (sp)+,d1-d5/a1-a3/a6
   add.l    d0,4(a1)
   rts

rd:                        ; (d0 := offset, d1 := length, a0 := data)
   movem.l  d2-d4/a2-a4,-(sp)
   bsr      _initio
   move.l   d0,d2          ; d2 := offset
   move.l   d1,d3          ; d3 := length
   move.l   a0,a2          ; a2 := data
   moveq.l  #0,d4          ; d4 := actual
   move.w   #512,a3        ; a3 := sector size - constant 512
   tst.l    d3
   beq      rd_end
   and.w    #511,d0
   beq      rd_2
rd_1:
   move.w   d2,d0
   and.w    #-512,d0
   move.l   a3,d1
   lea.l    block(pc),a0
   bsr      _readsecs
   cmp.l    a3,d0
   bne      rd_error
   move.w   d2,d0
   and.w    #511,d0        ; d0 := offset in sector (0-511)
   move.l   a3,d1
   sub.w    d0,d1          ; d1 := # of rest bytes in sector (1-512)
   cmp.l    d1,d3
   bcc      1$             ; ... length (d3) is >= rest of bytes
   move.w   d3,d1
1$ sub.l    d1,d3          ; length -= count
   move.w   d1,d4          ; actual := count
   lea.l    block(pc),a0
   add.w    d0,a0
   bra      3$
2$ move.b   (a0)+,(a2)+
3$ dbf      d1,2$
   tst.l    d3
   beq      rd_end
   and.w    #-512,d2       ; offset = (offset + 511) & ~511
   add.l    a3,d2
rd_2:
   cmp.l    a3,d3
   bcs      rd_3           ; ... length < size of sector (512)
   move.l   d2,d0
   move.l   d3,d1
   and.w    #-512,d1       ; d1 := length & ~511
   move.l   d1,a4          ; a4 := d1
   move.l   a2,a0
   bsr      _readsecs
   add.l    d0,d4          ; actual(file) += actual(iob)
   cmp.l    a4,d0
   bne      rd_error       ; actual <> length & ~511
   sub.l    a4,d3
   beq      rd_end         ; ... length = 0
   add.l    a4,d2          ; offset += length & ~511
   add.l    a4,a2          ; data += length & ~511
rd_3:
   move.l   d2,d0
   move.l   a3,d1
   lea.l    block(pc),a0
   bsr      _readsecs
   cmp.l    a3,d0
   bne      rd_error
   add.l    d3,d4          ; actual += length
   lea.l    block(pc),a0
   bra      5$
4$ move.b   (a0)+,(a2)+
5$ dbf      d3,4$
rd_error:
rd_end:
   move.l   d4,d0
   movem.l  (sp)+,d2-d4/a2-a4
   bra      _endio

wr:                        ; (d0 := offset, d1 := length, a0 := data)
   movem.l  d2-d4/a2-a4,-(sp)
   bsr      _initio
   move.l   d0,d2          ; d2 := offset
   move.l   d1,d3          ; d3 := length
   move.l   a0,a2          ; a2 := data
   moveq.l  #0,d4          ; d4 := actual
   move.w   #512,a3        ; a3 := sector size - constant 512
   tst.l    d3
   beq      wr_end
   and.w    #511,d0
   beq      wr_2
wr_1:
   move.w   d2,d0
   and.w    #-512,d0
   move.l   a3,d1
   lea.l    block(pc),a0
   bsr      _readsecs
   cmp.l    a3,d0
   bne      wr_error
   move.w   d2,d0
   and.w    #511,d0        ; d0 := offset in sector (0-511)
   move.l   a3,d1
   sub.w    d0,d1          ; d1 := # of rest bytes in sector (1-512)
   cmp.l    d1,d3
   bcc      1$             ; ... length (d3) is >= rest of bytes
   move.w   d3,d1
1$ sub.l    d1,d3          ; length -= count
   move.w   d1,d4          ; actual := count
   lea.l    block(pc),a0
   add.w    d0,a0
   bra      3$
2$ move.b   (a2)+,(a0)+
3$ dbf      d1,2$
   tst.l    d3
   beq      wr_end
   and.w    #-512,d2       ; offset = (offset + 511) & ~511
   move.l   d2,d0
   move.l   a3,d1
   lea.l    block(pc),a0
   bsr      _writesecs
   cmp.l    a3,d0
   bne      wr_error
   add.l    a3,d2
wr_2:
   cmp.l    a3,d3
   bcs      wr_3           ; ... length < size of sector (512)
   move.l   d2,d0
   move.l   d3,d1
   and.w    #-512,d1       ; d1 := length & ~511
   move.l   d1,a4          ; a4 := d1
   move.l   a2,a0
   bsr      _writesecs
   add.l    d0,d4          ; actual(file) += actual(iob)
   cmp.l    a4,d0
   bne      wr_error       ; actual <> length & ~511
   sub.l    a4,d3
   beq      wr_end         ; ... length = 0
   add.l    a4,d2          ; offset += length & ~511
   add.l    a4,a2          ; data += length & ~511
wr_3:
   move.l   d2,d0
   move.l   a3,d1
   lea.l    block(pc),a0
   bsr      _readsecs
   cmp.l    a3,d0
   bne      wr_error
   add.l    d3,d4          ; actual += length
   lea.l    block(pc),a0
   bra      5$
4$ move.b   (a2)+,(a0)+
5$ dbf      d3,4$
   move.l   d2,d0
   move.l   a3,d1
   lea.l    block(pc),a0
   bsr      _writesecs
wr_error:
wr_end:
   move.l   d4,d0
   movem.l  (sp)+,d2-d4/a2-a4
   bra      _endio

_writesecs:
   move.w   #CMD_WRITE,-(sp)
   bra.s    _rdwrsecs

_readsecs:
   move.w   #CMD_READ,-(sp)

_rdwrsecs:
   lea.l    _iob(pc),a1
   move.l   d0,IO_OFFSET(a1)
   move.l   d1,IO_LENGTH(a1)
   move.l   a0,IO_DATA(a1)
   move.w   (sp)+,IO_COMMAND(a1)
   move.l   (_AbsExecBase#).w,a6
   jsr      _LVODoIO#(a6)
   lea.l    _iob(pc),a1
   move.l   IO_ACTUAL(a1),d0
   rts

seek:
   move.l   d1,a1
   add.l    a1,a1
   add.l    a1,a1
   cmp.l    #'PCHD',(a1)
   beq      new_seek
   move.l   (code+16)(pc),a0
   jmp      (a0)
new_seek:
   cmp.l    #OFFSET_END,d3
   bne.s    1$
   move.l   _endoffset(pc),d0
   sub.l    _startoffset(pc),d0
   add.l    #512,d0
   bra.s    2$
1$ move.l   d2,d0
   cmp.l    #OFFSET_BEGINNING,d3
   beq.s    3$
   move.l   4(a1),d0
   cmp.l    #OFFSET_CURRENT,d3
   bne.s    3$
2$ add.l    d2,d0
3$ move.l   d0,4(a1)
   rts

_initio:
   movem.l  d0-d1/a0-a2/a6,-(sp)
   lea.l    _mp(pc),a2
   sub.l    a1,a1
   move.l   (_AbsExecBase#).w,a6
   jsr      _LVOFindTask#(a6)
   move.l   d0,MP_SIGTASK(a2)
   moveq.l  #-1,d0
   jsr      _LVOAllocSignal#(a6)
   tst.l    d0
   bpl.s    1$
   moveq.l  #0,d0
   bra.s    _initio_end
1$ move.b   d0,MP_SIGBIT(a2)
   lea.l    (MP_MSGLIST+4)(a2),a0
   move.l   a0,-(a0)
   move.l   a0,8(a0)
   lea.l    _iob(pc),a1
   move.l   a2,MN_REPLYPORT(a1)
   lea.l    _devname(pc),a0
   move.l   _unit(pc),d0
   move.l   _flags(pc),d1
   jsr      _LVOOpenDevice#(a6)
   not.l    d0
   tst.l    d0
   bne.s    _initio_end
   moveq.l  #0,d0
   move.b   MP_SIGBIT(a2),d0
;   jsr      _LVOFreeSignal#(a6)
   moveq.l  #0,d0
_initio_end:
   movem.l  (sp)+,d0-d1/a0-a2/a6
   rts

_endio:
   movem.l  d0-d1/a0-a1/a6,-(sp)
   lea.l    _iob(pc),a1
   move.l   (_AbsExecBase#).w,a6
   jsr      _LVOCloseDevice#(a6)
   moveq.l  #0,d0
   lea.l    _mp(pc),a0
   move.b   MP_SIGBIT(a0),d0
   jsr      _LVOFreeSignal#(a6)
   movem.l  (sp)+,d0-d1/a0-a1/a6
   rts

codeSize equ (*-code)

# 575
|
~ _exit * "(l"
~ _strcpy * "(l"
~ _main * "(v"
~ _install_funcs * "(v"
~ _devname * "[0c"
~ _endoffset * "l"
~ _startoffset * "l"
~ _flags * "l"
~ _unit * "l"
~ _blkspertrk * "i"
~ _surfaces * "i"
~ _highcyl * "i"
~ _lowcyl * "i"
~ '__stdio'
~ 13 8 22
~ _bp 0 "#C"
~ _bend 4 "#C"
~ _buff 8 "#C"
~ _flags 12 "I"
~ _unit 14 "c"
~ _bytbuf 15 "C"
~ _buflen 16 "L"
~ _tmpnum 20 "I"
~ _printf * "(l"
~ _fprintf * "(l"
~ __iob * "[0:" 13
~ FILE ":" 13
~ fpos_t "l"
~ size_t "L"
~ va_list "#c"
~ 'SignalSemaphore'
~ 'MinList'
~ 'MinNode'
~ 16 2 8
~ mln_Succ 0 "#:" 16
~ mln_Pred 4 "#:" 16
~ 15 3 12
~ mlh_Head 0 "#:" 16
~ mlh_Tail 4 "#:" 16
~ mlh_TailPred 8 "#:" 16
~ 'SemaphoreRequest'
~ 'Task'
~ 18 22 92
~ tc_Node 0 ":" 5
~ tc_Flags 14 "C"
~ tc_State 15 "C"
~ tc_IDNestCnt 16 "c"
~ tc_TDNestCnt 17 "c"
~ tc_SigAlloc 18 "L"
~ tc_SigWait 22 "L"
~ tc_SigRecvd 26 "L"
~ tc_SigExcept 30 "L"
~ tc_TrapAlloc 34 "I"
~ tc_TrapAble 36 "I"
~ tc_ExceptData 38 "#v"
~ tc_ExceptCode 42 "#v"
~ tc_TrapData 46 "#v"
~ tc_TrapCode 50 "#v"
~ tc_SPReg 54 "#v"
~ tc_SPLower 58 "#v"
~ tc_SPUpper 62 "#v"
~ tc_Switch 66 "#(v"
~ tc_Launch 70 "#(v"
~ tc_MemEntry 74 ":" 6
~ tc_UserData 88 "#v"
~ 17 2 12
~ sr_Link 0 ":" 16
~ sr_Waiter 8 "#:" 18
~ 14 6 46
~ ss_Link 0 ":" 5
~ ss_NestCount 14 "i"
~ ss_WaitQueue 16 ":" 15
~ ss_MultipleLink 28 ":" 17
~ ss_Owner 40 "#:" 18
~ ss_QueueCount 44 "i"
~ 'Library'
~ 19 10 34
~ lib_Node 0 ":" 5
~ lib_Flags 14 "C"
~ lib_pad 15 "C"
~ lib_NegSize 16 "I"
~ lib_PosSize 18 "I"
~ lib_Version 20 "I"
~ lib_Revision 22 "I"
~ lib_IdString 24 "#v"
~ lib_Sum 28 "L"
~ lib_OpenCnt 32 "I"
~ 'Message'
~ 20 3 20
~ mn_Node 0 ":" 5
~ mn_ReplyPort 14 "#:" 4
~ mn_Length 18 "I"
~ 'MemList'
~ 'MemEntry'
~ ''
~ 23 2 4
~ meu_Reqs 0 "L"
~ meu_Addr 0 "#v"
~ 22 2 8
~ me_Un 0 ":" 23
~ me_Length 4 "L"
~ 21 3 24
~ ml_Node 0 ":" 5
~ ml_NumEntries 14 "I"
~ ml_ME 16 "[1:" 22
~ 'Interrupt'
~ 'Resident'
~ 'LocalVar'
~ 26 4 24
~ lv_Node 0 ":" 5
~ lv_Flags 14 "I"
~ lv_Value 16 "#C"
~ lv_Len 20 "L"
~ 'RDArgs'
~ 'CSource'
~ 28 3 12
~ CS_Buffer 0 "#C"
~ CS_Length 4 "l"
~ CS_CurChr 8 "l"
~ 27 6 32
~ RDA_Source 0 ":" 28
~ RDA_DAList 12 "l"
~ RDA_Buffer 16 "#C"
~ RDA_BufSiz 20 "l"
~ RDA_ExtHelp 24 "#C"
~ RDA_Flags 28 "l"
~ 'Segment'
~ _FreeDosEntry * "(v"
~ _FindDosEntry * "(#:" 3
~ _UnLockDosList * "(v"
~ _LockDosList * "(#:" 3
~ 'DevProc'
~ 30 4 16
~ dvp_Port 0 "#:" 4
~ dvp_Lock 4 "l"
~ dvp_Flags 8 "L"
~ dvp_DevNode 12 "#:" 3
~ 'Process'
~ 31 26 228
~ pr_Task 0 ":" 18
~ pr_MsgPort 92 ":" 4
~ pr_Pad 126 "i"
~ pr_SegList 128 "l"
~ pr_StackSize 132 "l"
~ pr_GlobVec 136 "#v"
~ pr_TaskNum 140 "l"
~ pr_StackBase 144 "l"
~ pr_Result2 148 "l"
~ pr_CurrentDir 152 "l"
~ pr_CIS 156 "l"
~ pr_COS 160 "l"
~ pr_ConsoleTask 164 "#v"
~ pr_FileSystemTask 168 "#v"
~ pr_CLI 172 "l"
~ pr_ReturnAddr 176 "#v"
~ pr_PktWait 180 "#v"
~ pr_WindowPtr 184 "#v"
~ pr_HomeDir 188 "l"
~ pr_Flags 192 "l"
~ pr_ExitCode 196 "#(v"
~ pr_ExitData 200 "l"
~ pr_Arguments 204 "#C"
~ pr_LocalVars 208 ":" 15
~ pr_ShellPrivate 220 "L"
~ pr_CES 224 "l"
~ 'CommandLineInterface'
~ 32 16 64
~ cli_Result2 0 "l"
~ cli_SetName 4 "l"
~ cli_CommandDir 8 "l"
~ cli_ReturnCode 12 "l"
~ cli_CommandName 16 "l"
~ cli_FailLevel 20 "l"
~ cli_Prompt 24 "l"
~ cli_StandardInput 28 "l"
~ cli_CurrentInput 32 "l"
~ cli_CommandFile 36 "l"
~ cli_Interactive 40 "l"
~ cli_Background 44 "l"
~ cli_CurrentOutput 48 "l"
~ cli_DefaultStack 52 "l"
~ cli_StandardOutput 56 "l"
~ cli_Module 60 "l"
~ 'DosPacket'
~ 33 12 48
~ dp_Link 0 "#:" 20
~ dp_Port 4 "#:" 4
~ dp_Type 8 "l"
~ dp_Res1 12 "l"
~ dp_Res2 16 "l"
~ dp_Arg1 20 "l"
~ dp_Arg2 24 "l"
~ dp_Arg3 28 "l"
~ dp_Arg4 32 "l"
~ dp_Arg5 36 "l"
~ dp_Arg6 40 "l"
~ dp_Arg7 44 "l"
~ BSTR "l"
~ BPTR "l"
~ TEXT "C"
~ BOOL "i"
~ DOUBLE "d"
~ FLOAT "f"
~ CPTR "L"
~ UCOUNT "I"
~ COUNT "i"
~ USHORT "I"
~ SHORT "i"
~ STRPTR "#C"
~ RPTR "i"
~ BYTEBITS "C"
~ UBYTE "C"
~ BYTE "c"
~ WORDBITS "I"
~ UWORD "I"
~ WORD "i"
~ LONGBITS "L"
~ ULONG "L"
~ LONG "l"
~ APTR "#v"
	xref	_exit
	xref	_strcpy
	xref	_install_funcs
	xref	_printf
	xref	_fprintf
	xref	_FreeDosEntry
	xref	_FindDosEntry
	xref	_UnLockDosList
	xref	_LockDosList
	xref	.begin
	dseg
	xref	_devname
	xref	_endoffset
	xref	_startoffset
	xref	_flags
	xref	_unit
	xref	_blkspertrk
	xref	_surfaces
	xref	_highcyl
	xref	_lowcyl
	xref	__iob
	end
