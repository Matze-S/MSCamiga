
initresident:
   move.l 4,a6
   lea residentname(pc),a1
   jsr -$60(a6)
   moveq #5,d2
   tst.l d0
   bne initend
   move.l #residentend-resident+8,d0
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
   move.l a0,a2
   lea 336(a6),a0
   lea keymapresourcename(pc),a1
   jsr -$114(a6)
   tst.l d0
   beq.s initend
   move.l d0,a0
   add.w #14,a0
   lea keymapname(pc),a1
   jsr -$114(a6)
   tst.l d0
   beq.s initend
   move.l d0,a0
   subq.w #8,a0
   move.l (a0),d0
   movem.l d0/a0,34(a2)
   move.l a2,d0
   move.l $226(a6),-(a2)
   beq.s nooldresident
   bset.b #7,(a2)
nooldresident:
   move.l d0,-(a2)
   move.l a2,$226(a6)
   jsr -612(a6)
   move.l d0,$22a(a6)
initend:
   move.l d2,d0
   rts

resident:
   dc.w $4afc
   dc.l 0
   dc.l residentend-resident+232
   dc.b 1
   dc.b 1
   dc.b 0
   dc.b 3
   dc.l residentname-resident
   dc.l residentid-resident
   dc.l residentcode-resident

residentmem:
   dc.l 0,0

keymapsegment:
   dc.l 0,0

residentname:
   dc.b 'setmap '

keymapname:
   dc.b  'd',0

residentid:
   dc.b 'Resident German KeyMap 1.0 (10-Aug-89 00:19)',0
   even

residentcode:
   move.l a2,-(sp)
   lea resident-8(pc),a1
   move.l 14(a1),d0
   sub.l a1,d0
   move.l 4,a6
   jsr -$cc(a6)
   tst.l d0
   beq residenterror
   movem.l keymapsegment(pc),d0/a1
   jsr -$cc(a6)
   tst.l d0
   beq residenterror
   lea 336(a6),a0
   lea keymapresourcename(pc),a1
   jsr -$114(a6)
   tst.l d0
   beq residenterror
   move.l d0,a0
   add.w #14,a0
   move.l keymapsegment+4(pc),a1
   addq.w #8,a1
   jsr -$f0(a6)
   sub.w #$52,sp
   lea 8(sp),a2
   move.w #4<<8,(a2)+
   clr.l (a2)+
   clr.b (a2)+
   moveq #-1,d0
   jsr -$14a(a6)
   cmp.b #-1,d0
   beq.s residenterr
   move.b d0,(a2)+
   sub.l a1,a1
   jsr -$126(a6)
   move.l d0,(a2)+
   lea 4(a2),a1
   move.l a1,(a2)+
   clr.l (a2)+
   subq.w #4,a1
   move.l a1,(a2)+
   move.w #5<<8,(a2)+
   move.l a2,a1
   addq.w #8,a2
   move.w #5<<8,(a2)+
   clr.l (a2)+
   move.l sp,(a2)+
   move.w #$30,(a2)+
   moveq #6,d0
cleariobloop:
   clr.l (a2)+
   dbra d0,cleariobloop
   lea consoledevicename(pc),a0
   moveq #-1,d0
   moveq #0,d1
   jsr -$1bc(a6)
   tst.l d0
   bne.s residentnodev
   move.w #12,$1c+34(sp)
   move.l keymapsegment+4(pc),a0
   lea 22(a0),a0
   move.l a0,$28+34(sp)
   moveq #32,d0
   move.l d0,$24+34(sp)
   lea 34(sp),a1
   jsr -$1c8(a6)
   lea 34(sp),a1
   jsr -$1c2(a6)
residentnodev:
   moveq #0,d0
   move.b 15(sp),d0
   jsr -$150(a6)
residenterr:
   add.w #$52,sp
residenterror:
   move.l (sp)+,a2
   rts

keymapresourcename:
   dc.b 'keymap.resource',0
consoledevicename:
   dc.b 'console.device',0
   even

residentend:

