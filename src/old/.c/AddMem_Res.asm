
   include  "exec/types.i"
   include  "exec/nodes.i"
   include  "exec/memory.i"
   include  "exec/execbase.i"

   section  code

MEMPRI   EQU   5

   XREF _LVOAllocAbs
   XREF _LVOAllocMem
   XREF _LVOEnqueue
   XREF _LVOSumKick

_res:
   dc.w     $4afc
   dc.l     0
   dc.l     _resSize
   dc.b     1
   dc.b     1
   dc.b     0
   dc.b     115
   dc.l     _resName-_res
   dc.l     _resId-_res
   dc.l     _resCode-_res

_resLink:
   dc.l     0,0

_resName:
   dc.b     'addmem.resident',0

_resId:
   dc.b     13,'AddMem II -- 20:56 11-Apr-90',13,10
   dc.b     'Copyright (C) 1990 by Matthias Schmidt',13,10,0
   ds.w     0

_resCode:
   movem.l  d0-d1/a0-a1,-(sp)
   lea.l    (_res-8)(pc),a1
   move.l   #(_resSize+8),d0
   move.l   (4).w,a6
   jsr      _LVOAllocAbs(a6)
   tst.l    d0
   beq.s    _resCode_End
   bsr.s    _AddMem
_resCode_End:
   movem.l  (sp)+,d0-d1/a0-a1
   rts

   xdef     _MemAddress
_MemAddress:
   dc.l     0

   xdef     _MemSize
_MemSize:
   dc.l     0

   xdef     _Attributes
_Attributes:
   dc.w     0

   xdef     _AddMem
_AddMem:
   move.l   a6,-(sp)
   moveq.l  #MH_SIZE,d0
   moveq.l  #MEMF_PUBLIC,d1
   move.l   (4).w,a6
   jsr      _LVOAllocMem(a6)
   tst.l    d0
   beq.s    _AddMem_End
   move.l   d0,a1
   addq.w   #LN_TYPE,a1
   move.b   #NT_MEMORY,(a1)+
   move.b   #MEMPRI,(a1)+
   clr.l    (a1)+             ; no name
   move.w   _Attributes(pc),(a1)+
   move.l   _MemAddress(pc),a0
   clr.l    (a0)
   move.l   _MemSize(pc),d1
   move.l   d1,MC_BYTES(a0)
   move.l   a0,(a1)+
   move.l   a0,(a1)+
   add.l    d1,a0
   move.l   a0,(a1)+
   move.l   d1,(a1)+
   lea.l    MemList(a6),a0
   move.l   d0,a1
   jsr      _LVOEnqueue(a6)
_AddMem_End:
   move.l   (sp)+,a6
   rts

   cnop     0,4
_resSize    EQU (*-_res)

   xdef     _InitRes
_InitRes:
   move.l   a6,-(sp)
   move.l   (4).w,a6
   move.l   #(_resSize+8),d0
   moveq.l  #(MEMF_PUBLIC!MEMF_CHIP),d1
   jsr      _LVOAllocMem(a6)
   tst.l    d0
   beq.s    _InitRes_End
   addq.l   #8,d0
   lea.l    _res(pc),a0
   move.l   d0,a1
   move.w   #((_resSize/2)-1),d1
_InitRes_CopyLoop:
   move.w   (a0)+,(a1)+
   dbf      d1,_InitRes_CopyLoop
   move.l   d0,a0
   move.l   d0,2(a0)
   add.l    d0,6(a0)
   add.l    d0,14(a0)
   add.l    d0,18(a0)
   add.l    d0,22(a0)
   lea.l    (_resLink-_res+4)(a0),a0
   move.l   $226(a6),(a0)
   beq.s    _InitRes_NoOldRes
   bset.b   #7,(a0)
_InitRes_NoOldRes:
   move.l   d0,-(a0)
   move.l   a0,$226(a6)
   jsr      _LVOSumKick#(a6)
   move.l   d0,$22a(a6)
   moveq.l  #1,d0
_InitRes_End:
   move.l   (sp)+,a6
   rts

   end

