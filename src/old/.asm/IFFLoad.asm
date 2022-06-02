
;
; IFF/ILBM-Loader
;

	incdir "DEVPAC:include/"
	include "libraries/dos_lib.i"
	include "libraries/dos.i"
	include "graphics/view.i"
	include "graphics/gfx.i"
	include "graphics/gfxbase.i"
	include "graphics/graphics_lib.i"
	include "exec/memory.i"
	include "exec/exec_lib.i"

	opt	o+

	lea NAME(pc),a0

_IFFLoad	move.l a0,-(sp)
	lea _IL_DOSName(pc),a1
	moveq #0,d0
	move.l _SysBase,a6
	jsr _LVOOpenLibrary(a6)
	move.l d0,_IL_DOSBase
	move.l (sp)+,d1
	move.l #MODE_OLDFILE,d2
	move.l d0,a6
	jsr _LVOOpen(a6)
	moveq #1,d6
	move.l d0,_IL_FileHandle
	beq _IFFLoad_Error
	move.l d0,d1
	move.l #_IL_FORM,d2
	moveq #8,d3
	jsr _LVORead(a6)
	moveq #2,d6
	cmp.l #8,d0
	bne _IFFLoad_Error
	cmp.l #'FORM',_IL_FORM
	bne _IFFLoad_Error
	move.l _IL_Size(pc),d0
	move.l #MEMF_PUBLIC,d1
	move.l _SysBase,a6
	jsr _LVOAllocMem(a6)
	moveq #3,d6
	move.l d0,_IL_FileAddr
	beq _IFFLoad_Error
	move.l _IL_FileHandle(pc),d1
	move.l d0,d2
	move.l _IL_Size(pc),d3
	move.l _IL_DOSBase(pc),a6
	jsr _LVORead(a6)
	moveq #4,d6
	cmp.l _IL_Size(pc),d0
	bne _IFFLoad_Error
	move.l _IL_FileHandle(pc),d1
	jsr _LVOClose(a6)
	clr.l _IL_FileHandle

;auf ILBM- (Grafik-) File testen
	moveq #8,d6
	move.l _IL_FileAddr,a0
	cmp.l #'ILBM',(a0)
	bne _IFFLoad_Error

; BMHD analysieren und Grafik-Daten holen
	moveq #5,d6
	move.l #'BMHD',d0
	bsr IL_SearchChunk
	beq _IFFLoad_Error
	move.b 8(a0),bm_Depth+_IL_BitMap
	move.b 10(a0),_IL_PackFlag
	move.w (a0),d0
	move.w d0,_IL_Width
	move.w d0,d1
	and.w #7,d0
	beq.s _IFFLoadOk1
	or.w #8,d1
_IFFLoadOk1	lsr.w #3,d1
	move.w d1,bm_BytesPerRow+_IL_BitMap
	move.w 2(a0),bm_Rows+_IL_BitMap
	moveq #0,d0
	cmp.w #40,d1
	bls.s _IFFLoadOk2
	or.w #V_HIRES,d0
_IFFLoadOk2	cmp.w #256,2(a0)
	bls.s _IFFLoadOk3
	or.w #V_LACE,d0
_IFFLoadOk3	move.w d0,_IL_ViewMode

; CMAP analysieren und Farbtabelle holen
	moveq #6,d6
	move.l #'CMAP',d0
	bsr IL_SearchChunk
	beq _IFFLoad_Error
	moveq #0,d0
	move.b bm_Depth+_IL_BitMap,d1
	bset.l d1,d0
	move.w d0,_IL_ColorCount
	lea _IL_ColorTable(pc),a1
_IFFLoadLoop1	clr.w d1
	move.b (a0)+,d1
	and.b #$f0,d1
	lsl.w #4,d1
	move.b (a0)+,d1
	and.w #$0ff0,d1
	clr.w d2
	move.b (a0)+,d2
	lsr.b #4,d2
	and.b #$0f,d2
	or.b d2,d1
	move.w d1,(a1)+
	subq.b #1,d0
	bne.s _IFFLoadLoop1

; Bitplanes für Grafik allocieren
	moveq #9,d6
	move.b bm_Depth+_IL_BitMap(pc),d5
	move.l _SysBase,a6
	moveq #0,d4
	move.w bm_Rows+_IL_BitMap(pc),d4
	mulu bm_BytesPerRow+_IL_BitMap(pc),d4
	move.w d4,_IL_PlaneSize
	lea bm_Planes+_IL_BitMap(pc),a4
	move.w #(4*8)-1,d0
_IFFLoadLoop2	clr.b (a4,d0.w)
	dbf d0,_IFFLoadLoop2
_IFFLoadLoop3	move.l d4,d0
	move.l #MEMF_PUBLIC!MEMF_CHIP!MEMF_CLEAR,d1
	jsr _LVOAllocMem(a6)
	move.l d0,(a4)+
	tst.l d0
	beq.s _IFFLoad_Error
	subq.b #1,d5
	bne.s _IFFLoadLoop3

; BODY analysieren und Grafik holen
	moveq #7,d6
	move.l #'BODY',d0
	bsr IL_SearchChunk
	beq.s _IFFLoad_Error
	lea bm_Planes+_IL_BitMap(pc),a1
	lea _IL_PtrBuffer(pc),a2
	moveq #7,d0
_IFFLoadLoop4	move.l (a1)+,(a2)+
	dbf d0,_IFFLoadLoop4
	lea _IL_PtrBuffer(pc),a2
	move.w bm_Rows+_IL_BitMap(pc),d2
_IFFLoadLoop5	moveq #0,d4
	move.b bm_Depth+_IL_BitMap(pc),d3
_IFFLoadLoop6	move.l (a2,d4.w),a1
	bsr IL_UnPackRow
	move.l a1,(a2,d4.w)
	addq.w #4,d4
	subq.b #1,d3
	bne.s _IFFLoadLoop6
	subq.w #1,d2
	bne.s _IFFLoadLoop5

; IFF-File-Speicher freigeben und ILBM-Grafik darstellen
	move.l _SysBase,a6
	move.l _IL_FileAddr(pc),a1
	move.l _IL_Size(pc),d0
	jsr _LVOFreeMem(a6)
	clr.l _IL_FileAddr

	jsr show_it

; Routinenende
	moveq #0,d6
_IFFLoad_Error	tst.l _IL_FileHandle
	beq.s _IFFLoad_EOk1
	move.l _IL_FileHandle(pc),d1
	move.l _IL_DOSBase,a6
	jsr _LVOClose(a6)
_IFFLoad_EOk1	move.l _SysBase,a6
	tst.l _IL_FileAddr
	beq.s _IFFLoad_EOk2
	move.l _IL_FileAddr(pc),a1
	move.l _IL_Size(pc),d0
	jsr _LVOFreeMem(a6)
_IFFLoad_EOk2	lea bm_Planes+_IL_BitMap(pc),a5
	moveq #7,d5
_IFFLoad_ELp1	tst.l (a5)+
	beq.s _IFFLoad_EOk3
	move.l -4(a5),a1
	moveq #0,d0
	move.w _IL_PlaneSize(pc),d0
	jsr _LVOFreeMem(a6)
_IFFLoad_EOk3	dbf d5,_IFFLoad_ELp1
	move.l _IL_DOSBase,a6
	jsr _LVOOutput(a6)
	move.l d0,d1
	move.l #Buffer,d2
	moveq #2,d3
	move.b d6,Buffer
	add.b #'0',Buffer
	jsr _LVOWrite(a6)
	move.l a6,a1
	move.l _SysBase,a6
	jsr _LVOCloseLibrary(a6)
	rts

Buffer	dc.b '0',$0a

* Chunk suchen

IL_SearchChunk	move.l _IL_FileAddr(pc),a0
	add.l #12,a0
IL_SearchChkLp	cmp.l -8(a0),d0
	beq.s IL_SearchCkOk2
	add.l -4(a0),a0
	move.l a0,d1
	and.b #1,d1
	beq.s IL_SearchCkOk1
	tst.b (a0)+
IL_SearchCkOk1	addq.l #8,a0
	move.l a0,a1
	sub.l _IL_FileAddr(pc),a1
	sub.l _IL_Size(pc),a1
	bpl.s IL_SearchChkLp
	moveq #0,d0
	rts
IL_SearchCkOk2	moveq #1,d1
	rts

* Eine Zeile dekodieren bzw. unpacken

IL_UnPackRow	move.w bm_BytesPerRow+_IL_BitMap(pc),d0
IL_UnPckRowLp1	tst.w d0
	beq.s IL_UnPckRowOk2
	bmi.s IL_UnPckRowOk2
	tst.b _IL_PackFlag
	bne.s IL_UnPckRowOk1
	move.w d0,d1
	subq.w #1,d1
IL_UnPckRowLp2	move.b (a0)+,(a1)+
	subq.w #1,d0
	dbf d1,IL_UnPckRowLp2
	bra.s IL_UnPckRowLp1
IL_UnPckRowOk1	clr.w d1
	move.b (a0)+,d1
	bpl.s IL_UnPckRowLp2
	neg.b d1
IL_UnPckRowLp3	move.b (a0),(a1)+
	subq.w #1,d0
	dbf d1,IL_UnPckRowLp3
	tst.b (a0)+
	bra.s IL_UnPckRowLp1
IL_UnPckRowOk2	rts

* Darstellung der Grafik mit Hilfe der Graphics-Primitives

show_it	moveq #0,d0
	lea GfxName(pc),a1
	move.l _SysBase,a6
	jsr _LVOOpenLibrary(a6)
	move.l d0,_GfxBase
	move.l d0,a6
	move.l gb_ActiView(a6),_OldView
	lea View(pc),a1
	jsr _LVOInitView(a6)
	lea ViewPort(pc),a1
	jsr _LVOInitVPort(a6)
	move.l #ViewPort,v_ViewPort+View
	move.w _IL_ViewMode(pc),v_Modes+View
	move.l #RasInfo,vp_RasInfo+ViewPort
	move.w _IL_Width(pc),vp_DWidth+ViewPort
	move.w bm_Rows+_IL_BitMap(pc),vp_DHeight+ViewPort
	move.w _IL_ViewMode(pc),vp_Modes+ViewPort
	moveq #0,d0
	move.w _IL_ColorCount(pc),d0
	jsr _LVOGetColorMap(a6)
	move.l d0,vp_ColorMap+ViewPort
	lea ViewPort(pc),a0
	moveq #0,d0
	move.w _IL_ColorCount(pc),d0
	lea _IL_ColorTable(pc),a1
	jsr _LVOLoadRGB4(a6)
	lea View(pc),a0
	lea ViewPort(pc),a1
	jsr _LVOMakeVPort(a6)
	lea View(pc),a1
	jsr _LVOMrgCop(a6)
	lea View(pc),a1
	jsr _LVOLoadView(a6)
	moveq #0,d0
	jsr _LVOFreeSprite(a6)
WaitMouse	btst.b #6,$bfe001
	bne.s WaitMouse
	move.l _OldView(pc),a1
	jsr _LVOLoadView(a6)
	move.l vp_ColorMap+ViewPort(pc),a0
	jsr _LVOFreeColorMap(a6)
	lea ViewPort(pc),a0
	jsr _LVOFreeVPortCopLists(a6)
	move.l v_LOFCprList+View(pc),a0
	jsr _LVOFreeCprList(a6)
	move.l v_SHFCprList+View(pc),a0
	jsr _LVOFreeCprList(a6)
	move.l a6,a1
	move.l _SysBase,a6
	jsr _LVOCloseLibrary(a6)
	rts

* Variablen, Zeiger & Strukturen

GfxName	dc.b "graphics.library",0
	even
_GfxBase	dc.l 0
_OldView	dc.l 0
RasInfo	dc.l 0,_IL_BitMap,0
View	ds.b v_SIZEOF
ViewPort	ds.b vp_SIZEOF

_IL_DOSName	dc.b "dos.library",0
_IL_PackFlag	dc.b 0
	even
_IL_DOSBase	dc.l 0
_IL_FileAddr	dc.l 0
_IL_FileHandle	dc.l 0
_IL_FORM	dc.l 0
_IL_Size	dc.l 0
_IL_PtrBuffer	ds.l 8

_IL_Width	dc.w 0
_IL_PlaneSize	dc.w 0
_IL_BitMap	ds.b bm_SIZEOF
_IL_ViewMode	dc.w 0
_IL_ColorCount	dc.w 0
_IL_ColorTable	ds.w 32

* Name der Grafik

NAME	dc.b "DATA-DISK II:pic2",0
	even
*

