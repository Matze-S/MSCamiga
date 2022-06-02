
initresident:
   move.l 4,a6
   move.l #residentend-resident+8,d0
   moveq #3,d1
   jsr -$c6(a6)
   tst.l d0
   beq.s initend
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
   lea.l (residentmem-resident+8)(a0),a0
   move.l $226(a6),-(a0)
   beq.s nooldresident
   bset.b #7,(a0)
nooldresident:
   move.l d0,-(a0)
   move.l a0,$226(a6)
   jsr -612(a6)
   move.l d0,$22a(a6)
   moveq #0,d0
initend:
   rts

resident:
   dc.w $4afc
   dc.l 0
   dc.l residentend-resident
   dc.b 1
   dc.b 34
   dc.b 0
   dc.b -50
   dc.l residentname-resident
   dc.l residentid-resident
   dc.l residentcode-resident

residentmem:
   dc.l 0,0

residentname:
   dc.b 'fastboot.resident',0

residentid:
   dc.b 'Fast-Booter 1.0 by M.Schmidt (17-Jan-89)',0
   even

residentcode:
   move.l a2,-(sp)
   lea resident(pc),a1
   move.l a1,a2
   subq.l #8,a1
   move.l 6(a2),d0
   sub.l a1,d0
   move.l 4,a6
   jsr -$cc(a6)
   lea rombootname(pc),a1
   moveq #0,d0
   jsr -$228(a6)
   move.l d0,a6
   tst.l d0
   beq.s residenterror
   jsr -$1e(a6)
   move.l a6,a1
   move.l 4,a6
   jsr -$19e(a6)
residenterror:
   move.l (sp)+,a2
   rts

rombootname:
   dc.b 'romboot.library',0
   even

residentend:

