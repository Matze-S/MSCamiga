_callgv.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_callgv
_callgv:
	lea	4(sp),a0
	move.l	(a0)+,d0
	move.l	(a6),a1
	jmp	.gvcall#

writes.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_writes
_writes:
	move.l	#$124/4,d0
	jmp	.stdconv#

writef.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_writef
_writef:
	lea	-$34(sp),sp
	movem.l a2-a4,-(sp)
	move.l	(a6),a1
	lea	68(sp),a2
	lea	12(sp),a3
	move.l	(a2)+,a0
	move.l	a0,a4
	bra	3$
1$	move.b	(a4)+,d0
	beq	6$
	cmp.b	#'%',d0
	bne	1$
	move.b	(a4)+,d1
	beq	6$
	cmp.b	#'%',d1
	beq	1$
	move.l	(a2)+,d0
	beq	4$
	cmp.b	#'S',d1
	beq	2$
	cmp.b	#'s',d1
	beq	2$
	cmp.b	#'T',d1
	beq	2$
	cmp.b	#'t',d1
	bne	4$
2$	move.l	d0,a0
3$	jsr	.conv#
4$	move.l	d0,(a3)+
5$	lea	64(sp),a0
	cmp.l	a0,a3
	bcs	1$
6$	movem.l (sp)+,a2-a4
	move.l	sp,a0
	move.l	#$128/4,d0
	jsr	.callgv#
	lea	$34(sp),sp
	rts

write.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_write
_write:
	move.l	#$ac/4,d0
	jmp	.stdcall#

wrch.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_wrch
_wrch:
	move.l	#$e0/4,d0
	jmp	.stdcall#

unrdch.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_unrdch
_unrdch:
	move.l	#$dc/4,d0
	jmp	.stdcall#

testbrea.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_testbreak
_testbreak:
	move.l	#$94/4,d0
	jmp	.stdcall#

taskwait.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_taskwait
_taskwait:
	move.l	#$a4/4,d0
	jsr	.stdcall#
	lsl.l	#2,d0
	rts

taskid.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_taskid
_taskid:
	move.l	#$38/4,d0
	jmp	.stdcall#

taskheld.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_taskheld
_taskheld:
	move.l	#$98/4,d0
	jmp	.stdcall#

stricmp.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_stricmp
_stricmp:
	move.l	(a6),a1
	move.l	8(sp),a0
	jsr	.conv#
	move.l	d0,8(sp)
	move.l	4(sp),a0
	jsr	.conv#
	lea	4(sp),a0
	move.l	d0,(a0)
	move.l	#$134/4,d0
	jmp	.callgv#

stop.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_stop
_stop:
	move.l	#$8/4,d0
	jmp	.stdcall#

stdconv.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	.stdconvjsr
.stdconvjsr:
	lea	8(sp),a0
	bra	call_it

	public	.stdconv
.stdconv:
	lea	4(sp),a0
call_it:
	movem.l d0/a0,-(sp)
	move.l	(a0),a0
	move.l	(a6),a1
	jsr	.conv#
	movem.l (sp)+,d1/a0
	move.l	d0,(a0)
	move.l	d1,d0
	jmp	.callgv#

stdcall.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	.stdcalljsr
.stdcalljsr:
	lea	8(sp),a0
	bra	call_it

	public	.stdcall
.stdcall:
	lea	4(sp),a0
call_it:
	move.l	(a6),a1
	jmp	.callgv#

selectou.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_selectoutput
_selectoutput:
	move.l	#$f8/4,d0
	jmp	.stdcall#

selectin.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_selectinput
_selectinput:
	move.l	#$f4/4,d0
	jmp	.stdcall#

root.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_root
_root:
	move.l	#$9c/4,d0
	jsr	.stdcall#
	lsl.l	#2,d0
	rts

result2.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_result2
_result2:
	move.l	#$28/4,d0
	jmp	.stdcall#

request.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_request
_request:
	move.l	(a6),a1
	move.l	d2,-(sp)
	move.l	#2,d2
1$	move.l	16(sp),a0
	jsr	.conv#
	move.l	d0,-(sp)
	lsl.l	#2,d0
	move.l	d0,a0
	add.b	#1,(a0)
	clr.w	d0
	move.b	(a0),d0
	clr.b	(a0,d0.w)
	add.w	#4,a1
	dbra	d2,1$
	move.l	sp,a0
	move.l	#$d0/4,d0
	jsr	.callgv#
	movem.l (sp)+,d1-d2/a0-a1
	move.l	a1,d2
	rts

read.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_read
_read:
	move.l	#$a0/4,d0
	jmp	.stdcall#

rdch.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_rdch
_rdch:
	move.l	#$d8/4,d0
	jmp	.stdcall#

rdargs.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_rdargs
_rdargs:
	movem.l d2-d4/a2-a3,-(sp)
	move.l	(a6),a1
	movem.l 24(sp),a0/a3
	jsr	.conv#
	move.l	32(sp),d2
	move.l	a1,a2
	move.l	a1,d1
	lsr.l	#2,d1
	movem.l d0-d2,-(sp)
	move.l	d2,d1
	lsl.l	#2,d1
	add.l	d1,a1
	sub.l	#1,8(sp)
	move.l	sp,a0
	move.l	#$138/4,d0
	jsr	.callgv#
	tst.l	d0
	beq	1$
	sub.l	4(sp),d0
	lsl.l	#2,d0
1$	move.l	d0,8(sp)
	move.l	#-1,d3
	bra	4$
2$	move.l	(a2)+,d4
	beq	3$
	move.l	#-1,d0
	cmp.l	d0,d4
	beq	3$
	cmp.l	d3,a3
	bcc	3$
	move.l	d4,(sp)
	move.l	sp,a0
	move.l	#-$80,d0
	jsr	.gvcall#
	sub.l	4(sp),d4
	lsl.l	#2,d4
	add.l	40(sp),d4
	cmp.l	d3,d4
	bcc	3$
	move.l	d4,d3
3$	move.l	d4,(a3)+
4$	dbra	d2,2$
	add.w	#8,sp
	movem.l (sp)+,d0/d2-d4/a2-a3
	rts

palloc.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_palloc
_palloc:
	sub.l	#1,4(sp)
	move.l	#$74/4,d0
	jsr	.stdcalljsr#
	lsl.l	#2,d0
	rts

output.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_output
_output:
	move.l	#$108/4,d0
	jmp	.stdcall#

mulu.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	.mulu
.mulu:
	pea	$c
	jmp	.lcalc#

mods.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	.mods
.mods:
	pea	$14
	jmp	.lcalc#

lcalc.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	.lcalc
.lcalc:
	movem.l d0-d1/a0-a1,-(sp)
	move.l	16(sp),d0
	move.l	sp,a0
	move.l	(a6),a1
	jsr	.gvcall#
	add.w	#4,sp
	movem.l (sp)+,d1/a0-a1
	add.w	#4,sp
	tst.l	d0
	rts

input.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_input
_input:
	move.l	#$104/4,d0
	jmp	.stdcall#

gv.list

  GVO    description
--------------------------------------------------------------------------

 - $84   build system request with own flags (t1,t2,t3,reqflags) - see below
 - $80   convert bcpl string to c string (string_BSTR)
 - $7c   convert c string to bcpl string (cstr_APTR,bstr_BSTR)
 - $6c                                                [ Execute(); ]
 - $68                                                [ IsInteractive(); ]
 - $64                                                [ DateStamp(); ]
 - $60                                                [ SetProtection(); ]
 - $5c                                                [ SetComment(); ]
 - $58                                                [ DeviceProc(); ]
 - $54                                                [ QueuePacket(); ]
 - $50                                                [ GetPacket(); ]
 - $4c                                                [ LoadSeg(); ]
 - $48                                                [ CreateProc(); ]
 - $44                                                [ IoErr(); ]
 - $40                                                [ CurrentDir(); ]
 - $3c                                                [ CreateDir(); ]
 - $38                                                [ Info(); ]
 - $34                                                [ ExNext(); ]
 - $30                                                [ Examine(); ]
 - $2c                                                [ Lock(); ]
 - $28                                                [ Rename(); ]
 - $24                                                [ DeleteFile(); ]
 - $20                                                [ Seek(); ]
 - $18                                                [ Write(); ]
 -  $c                                                [ Read(); ]
 -  $4                                                [ Open(); ]

    $0   size of Global Vector
    $4                                                [ start() ]
    $8                                                [ Exit(); | stop() ]
    $c   x mul y (x,y)
   $10   x div y (x,y)
   $14   x mod y (x,y)
   $18   set parms of io request (iob_BPTR,command,data_BPTR,length,offset)
                                                      [ SetIO() ]
   $20   read a value bytewise from memory (APTR,length)
   $24   write a value bytewise in memory (APTR,length,value)
   $28                                                [ result2() ]
   $38                                                [ taskid() ]
   $3c   get byte (BPTR,number)
   $40   set byte (BPTR,number)
   $44   get previous stack pointer
   $48   - ? -
   $4c   allocate dos memory segment (size - 1,reqs)
   $54   doio (iob_BPTR)                              [ DoIO() ]
   $58   sendio (iob_BPTR,iob.node.ln_Name := pointer to
         a packet you can wait for with taskwait())   [ SendIO() ]
   $74   allocate a public dos memory segment (size - 1)
   $78   free dos memory segment (BPTR)
   $7c   open device (iob_BPTR,devname_BSTR + '\0'-terminator,unit,flags)
                                                      [ OpenDevice() ]
   $80   close device (iob_BPTR)                      [ CloseDevice() ]
   $84   create a process (SegArray,StackSize,Priority,Name,GlobVec)
   $88   free a process' SegArray, GlobVec & remove himself
   $8c                                                [ ParentDir(); ]
   $90   set break signals (-?-,MASK - bit 0=C,bit 1=D,bit 2=E,bit 3=F)
   $94   test own break signals & clear them after testing (MASK)
   $98   task held - GURU! (GURU_CODE)
   $9c   get bptr to root node
   $a0   Read (Input(),APTR,length);
   $a4                                                [ taskwait() ]
   $a8   send packet (packet_BPTR)
   $ac   Write (Output(),APTR,length);
   $b0   convert long array to bstr (BPTR,BSTR)
   $b4   convert bstr to long array (BSTR,BPTR)
   $bc                                                [ Delay(); ]
   $c0   create a packet, send it and wait for replying (-?-,MsgPort,Type,
         Res1,Res2,Arg1,...) / rc := Res1 / result2 := Res2
   $c4   send back a packet (packet_BPTR,Res1,Res2)   [ returnpkt() ]
   $cc   get (flag = FALSE) or set (flag = TRUE) current dir (flag[,lock])
   $d0   build system request (text1_BSTR,text2_BSTR,text3_BSTR)
         all 3 BSTRs must be '\0'-terminated
   $d4   write limited length string (BPTR,length)
   $d8                                                [ rdch() ]
   $dc   decrement input buffer pointer ((rc := FALSE) = EOF)
   $e0                                                [ wrch() ]
   $e4   Read (Input(),BPTR,size);
   $e8   Write (Output(),BPTR,size);
   $ec                                                [ findinput() ]
   $f0                                                [ findoutput() ]
   $f4                                                [ selectinput() ]
   $f8                                                [ selectoutput() ]
   $fc                                                [ endread() ]
  $100                                                [ endwrite() ]
  $104                                                [ Input(); input() ]
  $108                                                [ Output(); output() ]
  $10c   read integer
  $110   write LF
  $114   write limited length integer (integer,length)
  $118   write integer (integer)
  $11c   write limited length hex (integer,length)
  $120   write limited length octal (integer,length)
  $124                                                [ writes() ]
  $128                                                [ writef() ]
  $12c   make char upper case                         [ toupper(); ]
  $130   make 2 chars upper case and compare them
  $134   compare two strings case insensitive         [ stricmp(); ]
  $138                                                [ rdargs() ]
  $144   LoadSeg (segname_BSTR)
  $148                                                [ UnLoadSeg(); ]
  $158   DateStamp (BPTR)
  $15c                                                [ WaitForChar(); ]
  $160   do 'exec.library'-function (offset,[d0],[d1],[a0],[a1],[a2])
  $164   get bptr to own process' SegArray
  $168   DeleteFile (name_BSTR)
  $170                                                [ IntuitionBase ]
  $174                                                [ Close(); ]
  $178   get word (BPTR,number)
  $17c   set word (BPTR,number,value)
  $190   - (-> $a4 ?) taskwait(...)
  $194   Execute (name_BSTR,ofh,ifh)
  $19c   do library-function (LibraryBase,offset,[d0],[d1],[a0],[a1])
  $1a0                                                [ fault() ]
  $1a4   get own process' ConsoleTask
  $1a8   get own process' FileSystemTask
  $1b0   Lock (name_BPTR,ACCESS_READ)
  $1b4                                                [ UnLock(); ]
  $1b8   get long (number,APTR)
  $1bc   set long (number,APTR,value)
  $1c0   initialize File-Handler/-System (devnode_BPTR)
  $1c4                                                [ DupLock(); ]
  $1e4   execute SegList (SegList,StackSize,Arg_BPTR,Arg_length)
  $1f4   CreateDir (name_BSTR)
  $1f8   compare 3 longs in memory (f_BPTR,s_BPTR)
         rc := f < s ? -1 | f = s ? 0 | f > s ? 1
  $218   get bptr to own process' cli structure

globals.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_globals
_globals:
	move.l	a6,d0
	rts

geta6.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_geta6
_geta6:
	move.l	4,a6
	move.l	$114(a6),a6
	move.l	$b0(a6),a6
	lea	-36(a6),a6
	rts

free.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_free
_free:
	move.l	4(sp),d0
	lsr.l	#2,d0
	move.l	d0,4(sp)
	move.l	#$78/4,d0
	jmp	.stdcall#

findoutp.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_findoutput
_findoutput:
	move.l	#$f0/4,d0
	jmp	.stdconv#

findinpu.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_findinput
_findinput:
	move.l	#$ec/4,d0
	jmp	.stdconv#

fault.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_fault
_fault:
	move.l	#$1a0/4,d0
	jmp	.stdcall#

endwrite.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_endwrite
_endwrite:
	move.l	#$100/4,d0
	jmp	.stdcall#

endread.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_endread
_endread:
	move.l	#$fc/4,d0
	jmp	.stdcall#

dospkt.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_dospkt
_dospkt:
	move.l	#$c0/4,d0
	jmp	.stdcall#

dolib.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_dolib
_dolib:
	move.l	#$19c/4,d0
	jmp	.stdcall#

doexec.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_doexec
_doexec:
	move.l	#$160/4,d0
	jmp	.stdcall#

divs.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	.divs
.divs:
	pea	$10
	jmp	.lcalc#

currentd.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_currentdir
_currentdir:
	move.l	#$cc/4,d0
	jmp	.stdcall#

crt0.a68
; Copyright (C) 1989 by Matthias Schmidt

	entry	.begin
	public	.begin
.begin:
	bsr	_geta4
	move.l	4,a1
	movem.l d0/a0-a1,-(sp)
	sub.l	a1,a1
	lea	16(sp),a0
	sub.l	(a0)+,a0
	movem.l a0-a2/a5-a6,-(sp)
	move.l	sp,a6
	jsr	_start#
	lea	32(sp),sp
	rts

	public	_geta4
_geta4:
	far	data
	lea	__H1_org+32766,a4
	rts

	dseg
	public	__H1_org

conv.a68
; Copyright (C) 1989 by Matthias Schmidt

; a0 := string pointer
; a1 := stack pointer

	public	.conv
.conv:
	move.l	a0,d0
	bchg.l	#31,d0
	bne	1$
	move.l	a1,d1
	lsr.l	#2,d1
	move.l	a0,d0
	movem.l d0-d1/a1,-(sp)
	move.l	#-$7c/4,d0
	move.l	sp,a0
	lea	$100(a1),a1
	jsr	.callgv#
	movem.l (sp)+,d1/a0-a1
	move.l	#0,d1
	move.b	(a1),d1
	add.w	#4,d1
	and.b	#$fc,d1
	add.w	d1,a1
1$	rts

close.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_close
	public	_Close
_close:
_Close:
	move.l	#$174/4,d0
	jmp	.stdcall#

cli.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_cli
_cli:
	move.l	#$218/4,d0
	jsr	.stdcall#
	lsl.l	#2,d0
	rts

callgv.a68
; Copyright (C) 1989 by Matthias Schmidt

; d0 := gv offset / 4
; a0 := pointer to args
; a1 := stack base

	public	.callgv
.callgv:
	asl.l	#2,d0

; d0 := gv offset

	public	.gvcall
.gvcall:
	movem.l d2-d7/a2-a6,-(sp)	; save regs
	movem.l (a0),d1-d7/a0/a2-a5	; copy args onto BCPL stack
	movem.l d5-d7/a0/a2-a5,28(a1)
	movem.l 4(a6),a0/a2/a5-a6	; build BCPL environment
	move.l	(a2,d0.l),a4		; set BCPL function address
	move.l	#$c,d0			; set stack offset
	jsr	(a5)			; call BCPL function
	move.l	d1,d0			; move result to d0
	movem.l (sp)+,d2-d7/a2-a6	; pop regs
	rts				; return to caller

bstr.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_bstr
_bstr:
	move.l	#-$7c/4,d0
	jmp	.stdcall#

bcpl.h
/* Copyright (C) 1989 by Matthias Schmidt */

/* BCPL.H - Header for Aztec C programs using the 'bcpl.lib' */

#ifndef BCPL_H
#define BCPL_H

/* global variables passed to the start() - routine */

struct globals {
	long *stkbase;			/* a1 */
	long null,*a2,a5,a6;		/* a0/a2/a5-a6 */
	long arglen;			/* argline... */
	char *argptr;
	struct ExecBase *SysBase;	/* library bases... */
};

/* defines */

#define IS_BSTR (1L<<31)		/* is already bcpl string */
#define TRUE -1L			/* booleans... */
#define FALSE 0L

/* macros */

#define lptr(bp) ((long *)((long)(bp) << 2))	/* convert bptr to lptr */
#define bptr(ap) ((long)(ap) >> 2))		/* convert aptr to bptr */

/* function declarations */

struct globals *globals();
long *alloc(),bstr(),callgv(),*cli(),currentdir(),doexec(),dolib();
long dospkt(),findinput(),findoutput(),input(),output(),*palloc(),*rdargs();
long rdch(),read(),request(),result2(),*root(),stricmp(),*taskid();
long *taskwait(),testbreak(),unrdch(),write();
void close(),endread(),endwrite(),fault(),free(),geta4(),geta6();
void selectinput(),selectoutput(),stop(),taskheld(),wrch(),writef();
void writes();

#endif

alloc.a68
; Copyright (C) 1989 by Matthias Schmidt

	public	_alloc
_alloc:
	sub.l	#1,4(sp)
	move.l	#$4c/4,d0
	jsr	.stdcalljsr#
	lsl.l	#2,d0
	rts

makefile

#
# makefile to build bcpl.lib & bcpll.lib
# Copyright (C) 1989 by Matthias Schmidt
#

O=alloc.o bstr.o callgv.o cli.o close.o conv.o crt0.o currentd.o divs.o\
	doexec.o dolib.o dospkt.o endread.o endwrite.o fault.o findinpu.o\
	findoutp.o free.o geta6.o globals.o input.o lcalc.o mods.o\
	mulu.o output.o palloc.o rdargs.o rdch.o read.o request.o\
	result2.o root.o selectin.o selectou.o stdcall.o stdconv.o\
	stop.o stricmp.o taskid.o taskheld.o taskwait.o testbrea.o\
	unrdch.o wrch.o write.o writef.o writes.o _callgv.o
L=alloc.l bstr.l callgv.l cli.l close.l conv.l crt0.l currentd.l divs.l\
	doexec.l dolib.l dospkt.l endread.l endwrite.l fault.l findinpu.l\
	findoutp.l free.l geta6.l globals.o input.l lcalc.l mods.l\
	mulu.l output.l palloc.l rdargs.l rdch.l read.l request.l\
	result2.l root.l selectin.l selectou.l stdcall.l stdconv.l\
	stop.l stricmp.l taskid.l taskheld.l taskwait.l testbrea.l\
	unrdch.l wrch.l write.l writef.l writes.l _callgv.l

.a68.o:
	as -o $@ $*.a68
.a68.l:
	as -cdo $@ $*.a68
.inp.out:
	ord $*.inp $*.out

all:	bcpl bcpll

bcpl:	bcpl.inp bcpl.out
	lb bcpl.lib -f bcpl.out
bcpll:	bcpll.inp bcpll.out
	lb bcpll.lib -f bcpll.out

bcpl.inp: $(O)
	list #?.o to bcpl.inp quick nohead
bcpll.inp: $(L)
	list #?.l to bcpll.inp quick nohead

cleanup:
	delete (#?.(o|l|out|inpt))|arclist quiet

arc:
	list (#?.(c|h|a68))|makefile|gv.list to arclist quick nohead

