
;
; initkick.asm
;

        mc68851
        far data
        cseg

_AbsExecBase    equ     4
_LVOSupervisor  equ     -$1e
_LVOAllocMem    equ     -$c6
_LVOAllocAbs    equ     -$cc
_LVOCloseLibrary equ    -$19e
_LVOOpenLibrary equ     -$228
_LVOOpen        equ     -$1e
_LVOClose       equ     -$24
_LVORead        equ     -$2a
_LVOSeek        equ     -$42

        include "exec/types.i"
        include "exec/memory.i"
        include "dos/dos.i"

bonusSize       equ     $5000

initKick:
        dc.l    $0000feed               ; ?
        dc.l    $c0edbabe               ; ?
        dc.l    $00000000               ; ?

        bra.s   loadBonus
        nop
bonusSize:
        dc.l    0

loadBonus:
        movem.l d2-d5/a5,-(sp)
        move.l  (_AbsExecBase).w,a6
        move.l  #$7f40000,a1
        move.l  a1,a5                   ; a5 := ptr to bonus 2.0
        moveq.l #4,d0
        swap    d0
        jsr     (_LVOAllocAbs).w(a6)
        tst.l   d0
        beq.s   noBonusMem
        lea.l   dosName(pc),a1
        moveq.l #0,d0
        jsr     (_LVOOpenLibrary).w(a6)
        move.l  d0,d5                   ; d5 := DOSBase
        beq.s   noDosLib
        lea.l   kickName(pc),a0
        move.l  a0,d1
        move.l  #MODE_OLDFILE,d2
        move.l  d5,a6
        jsr     (_LVOOpen).w(a6)
        move.l  d0,d4                   ; d4 := filehandle
        beq.s   noKick
        move.l  d4,d1
        move.l  #(512*1024+initKickSize),d2
        moveq.l #OFFSET_BEGINNING,d3
        jsr     (_LVOSeek).w(a6)
        moveq.l #1,d0
        swap    d0
        move.l  a5,a0
clearLoop:
        clr.l   (a0)+
        dbf     d0,clearLoop
        move.l  d4,d1
        move.l  a5,d2
        move.l  bonusSize(pc),d3
        jsr     (_LVORead).w(a6)
        cmp.l   d3,d0
        bne.s   readError
        lea.l   initCode(pc),a0
        move.l  a5,a1
        move.l  #((initCodeSize/2)-1),d0
copyLoop:
        move.w  (a0)+,(a1)+
        dbf     d0,copyLoop
        jmp     (loadKick-initCode).w(a5)
readError:
        move.l  d4,d1
        jsr     (_LVOClose).w(a6)
noKick:
        move.l  (_AbsExecBase).w,a6
        move.l  d5,a1
        jsr     (_LVOCloseLibrary).w(a6)
noDosLib:
        move.l  a5,a1
        moveq.l #4,d0
        swap    d0
        jsr     (_LVOFreeMem).w(a6)
noBonusMem:
        movem.l (sp)+,d2-d5/a5
        moveq.l #0,d0
        rts

        cnop    0,16
initCode:
        dc.l    $0000feed               ; ?
        dc.l    $c0edbabe               ; ?
        dc.l    $00000002               ; ?

        move.l  (_AbsExecBase).w,a6
        move.w  #$4000,($dff09a).l
        addq.b  #1,$126(a6)
        lea.l   (initSCode-initCode+$7f40000).l,a5
        jmp     (_LVOSupervisor).w(a6)
initSCode:
        lea.l   ($100000).l,a0
        move.l  (a0),d1
        not.l   d1
        not.l   (a0)
        move.l  ($10).w,a1
        cmp.l   (a0),d1
        bne.s   no2MBchip
        not.l   d1
        not.l   (a0)
        move.l  ($10).w,a1
        cmp.l   (a0),d1
        beq.s   is2MBchip
no2MBchip:
        lea.l   (mmuTable2-initCode+$7f40000).l,a0
        movem.l (a0)+,d0-d3
        movem.l d0-d3,(a0)
is2MBchip:
        lea.l   (mmuRegs-initCode+$7f40000).l,a0
        pmove.l (a0),crp
        addq.w  #8,a0
        pmove.l (a0),srp
        addq.w  #8,a0
        pmove.l (a0),tc
        move.l  #$4ef9,(0).w
        lea.l   ($f80002).l,a0
        move.l  a0,(4).w
        reset
        jmp     (a0)

loadKick:
        move.l  d4,d1
        move.l  #(512*1024-$1000),d2
        moveq.l #OFFSET_BEGINNING,d3
        jsr     (_LVOSeek).w(a6)
        move.l  d4,d1
        move.l  #$7fff000,d2
        move.l  #$1000,d3
        jsr     (_LVORead).w(a6)
        move.l  d0,-(sp)
        move.l  d4,d1
        jsr     (_LVOClose).w(a6)
        move.l  d5,a1
        move.l  (_AbsExecBase).w(a6)
        jsr     (_LVOCloseLibrary).w(a6)
        move.l  d3,d1
        movem.l (sp)+,d0/d2-d5/a5
        cmp.l   d0,d1
        beq.s   (initCode+$c)
        moveq.l #0,d0
        rts

mmuRegs:
        dc.l    $000f0002,(mmuTable1-initCode+$7f40000) ; crp
        dc.l    $80000001,0                             ; srp
        dc.l    $80f08630

        cnop    0,16
mmuTable1:
        dc.l    (mmuTable2-mmuInit+$7f40002),$01000001
        dc.l    $02000001,$03000001
        dc.l    $04000001,$05000001
        dc.l    $06000001,(mmuTable3-mmuInit+$7f40002)
        dc.l    $08000001,$09000001
        dc.l    $0a000001,$0b000001
        dc.l    $0c000001,$0d000001
        dc.l    $0e000001,$0f000001

        cnop    0,16
mmuTable2:
        dc.l    $00000041,$00040041,$00080041,$000c0041
        dc.l    $00100041,$00140041,$00180041,$001c0041
        dc.l    $00200001,$00240001,$00280001,$002c0001
        dc.l    $00300001,$00340001,$00380001,$003c0001
        dc.l    $00400001,$00440001,$00480001,$004c0001
        dc.l    $00500001,$00540001,$00580001,$005c0001
        dc.l    $00600001,$00640001,$00680001,$006c0001
        dc.l    $00700001,$00740001,$00780001,$007c0001

        dc.l    $00800001,$00840001,$00880001,$008c0001
        dc.l    $00900001,$00940001,$00980001,$009c0001
        dc.l    $00a00001,$00a40001,$00a80001,$00ac0001
        dc.l    $00b00001,$00b40001,$00b80001,$00bc0041
        dc.l    $00c00001,$00c40001,$00c80001,$00cc0001
        dc.l    $00d00001,$00d40001,$00d80001,$00dc0041
        dc.l    $00e00001,$00e40001,$00e80041,$00ec0041
        dc.l    $07f40005,$00f40001,$07f80005,$07fc0005

        cnop    0,16
mmuTable3:
        dc.l    $07000001,$07040001,$07080001,$070c0001
        dc.l    $07100001,$07140001,$07180001,$071c0001
        dc.l    $07200001,$07240001,$07280001,$072c0001
        dc.l    $07300001,$07340001,$07380001,$073c0001
        dc.l    $07400001,$07440001,$07480001,$074c0001
        dc.l    $07500001,$07540001,$07580001,$075c0001
        dc.l    $07600001,$07640001,$07680001,$076c0001
        dc.l    $07700001,$07740001,$07780001,$077c0001

        dc.l    $07800001,$07840001,$07880001,$078c0001
        dc.l    $07900001,$07940001,$07980001,$079c0001
        dc.l    $07a00001,$07a40001,$07a80001,$07ac0001
        dc.l    $07b00001,$07b40001,$07b80001,$07bc0001
        dc.l    $07c00001,$07c40001,$07c80001,$07cc0001
        dc.l    $07d00001,$07d40001,$07d80001,$07dc0001
        dc.l    $07e00001,$07e40001,$07e80001,$07ec0001
        dc.l    $07f00001,$07f40001,$07f80001,$07fc0001

        cnop    0,16
initKickSize    equ     (*-initKick)

        end

