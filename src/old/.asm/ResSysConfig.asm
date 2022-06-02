; Copyright (C) 1989 by Matthias Schmidt

;
; resident system-configuration
; (it was written for getting more free blocks in the
; recoverable and bootable ram disk RAD:!)
;
; MS - 09-Aug-89 23:38
;

initresident:
   move.l 4,a6
   lea residentname(pc),a1
   jsr -$60(a6)
   moveq #5,d2
   tst.l d0
   bne.s initend
   move.l #residentend-resident+8+256,d0
   moveq #3,d1
   jsr -$c6(a6)
   moveq #20,d2
   tst.l d0
   beq.s initend
   moveq #0,d2
   addq.l #8,d0
   lea resident(pc),a0
   move.l d0,a1
   move.w #(residentend-resident)/2-1,d1
copyresident:
   move.w (a0)+,(a1)+
   dbra d1,copyresident
   move.l d0,a0
   move.l d0,2(a0)
   add.l d0,6(a0)
   add.l d0,14(a0)
   add.l d0,18(a0)
   add.l d0,22(a0)
   movem.l d0/a0,-(sp)
   lea intname(pc),a1
   moveq #0,d0
   jsr -$228(a6)
   move.l d0,a6
   move.l (sp),a0
   lea.l (residentend-resident)(a0),a0
   move.l #232,d0
   jsr -$84(a6)
   move.l a6,a1
   move.l 4,a6
   jsr -$19e(a6)
   movem.l (sp)+,d0/a0
   lea.l (residentmem-resident+4)(a0),a0
   move.l $226(a6),(a0)
   beq.s nooldresident
   bset.b #7,(a0)
nooldresident:
   move.l d0,-(a0)
   move.l a0,$226(a6)
   jsr -612(a6)
   move.l d0,$22a(a6)
initend:
   move.l d2,d0
   rts

resident:
   dc.w $4afc
   dc.l 0
   dc.l residentend-resident+256
   dc.b 1
   dc.b 1
   dc.b 0
   dc.b 3
   dc.l residentname-resident
   dc.l residentid-resident
   dc.l residentcode-resident

residentmem:
   dc.l 0,0

residentname:
   dc.b 'system-configuration',0

residentid:
   dc.b 'Resident System-Configuration (09-Aug-89 23:37)',0
   even

residentcode:
   lea.l    (resident-8)(pc),a1
   move.l   (resident+6)(pc),d0
   sub.l    a1,d0
   move.l   (4).w,a6
   jsr      -$cc(a6)
   tst.l    d0
   beq.s    residenterror
   lea.l    intname(pc),a1
   moveq.l  #0,d0
   jsr      -$228(a6)
   tst.l    d0
   beq.s    residenterror
   move.l   d0,a6
   lea.l    residentend(pc),a0
   move.l   #232,d0
   moveq.l  #1,d1
   jsr      -$144(a6)
   move.l   a6,a1
   move.l   (4).w,a6
   jsr      -$19e(a6)
residenterror:
   rts

intname:
   dc.b 'intuition.library',0
   even

residentend:

