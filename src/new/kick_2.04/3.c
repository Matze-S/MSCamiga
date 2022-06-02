
extern unsigned long tc, psr, crp1, crp2, srp1, srp2;
long *POINTER;

#asm
         far code
         far data
         machine mc68020
         mc68881
         mc68851
         dseg


         cnop  0,4
   public _tc
   public _psr
   public _crp1
   public _crp2
   public _srp1
   public _srp2
_tc:  dc.l  0
_psr: dc.l  0
_crp1:   dc.l  0
_crp2:   dc.l  0
_srp1:   dc.l  0
_srp2:   dc.l  0

         cseg

         public   _xyz
_xyz:
         move.l   a5,-(sp)
         move.l   ($4).w,a6
         lea.l    do_mmu,a5
         jsr      -$1e(a6)
         move.l   (sp)+,a5
         rts

do_mmu:
         subq.w   #8,sp
         lea.l    _tc,a0
         pmove.l  tc,(sp)
         move.l   (sp),(a0)
;         pmove.l  psr,(sp)
         move.l   (sp),4(a0)
         pmove.l  crp,(sp)
         move.l   (sp),8(a0)
         move.l   4(sp),12(a0)
         pmove.l  srp,(sp)
         move.l   (sp)+,16(a0)
         move.l   (sp)+,20(a0)
         rte

         public   _abc
_abc:
         move.l   a5,-(sp)
         move.l   ($4).w,a6
         lea.l    _ABC,a5
         jsr      -$1e(a6)
         move.l   (sp)+,a5
         rts

_ABC:
         clr.l    -(sp)
         pmove.l  (sp),tc
         move.l   _crp2,d0
         and.l    #$ffffffe0,d0
         move.l   d0,a0
         move.l   (a0),d0
         and.l    #$ffffffe0,d0
         move.l   d0,a0
         move.l   248(a0),d0
         and.l    #$ffffffe0,d0
         or.l     #$00000059,d0
         move.l   d0,248(a0)
         move.l   252(a0),d0
         and.l    #$ffffffe0,d0
         or.l     #$00000059,d0
         move.l   d0,252(a0)

         move.l   #$0008005d,248(a0)
         move.l   #$000c005d,252(a0)

         clr.l    (4).w
         reset

         move.l   _tc,(sp)
         pmove.l  (sp),tc
         addq.w   #4,sp
         jmp      $f80002

         rte

copy:
         move.l   _POINTER,a0
         move.l   #$f80000,a1
         move.l   #(256*1024),d0
l1:      move.l   (a0)+,(a1)+
         subq.l   #1,d0
         bne.s    l1
         move.l   #(256*1024),d0
         move.l   #$07e000,a1
l2:      move.l   (a0)+,(a1)+
         subq.l   #1,d0
         bne.s    l1
         reset
         move.l   _tc,-(sp)
         pmove.l  (sp),tc
         addq.w   #4,sp
         jmp      $f80002


         public   _myReset
_myReset:
         move.l   (4).w,a6
         lea.l    _dasIstMeinReset,a5
         jsr      -$1e(a6)
_dasIstMeinReset:
         jmp      $f80002
#endasm

#include <stdio.h>

extern void xyz(void);
extern long *AllocMem(long, long);
extern void myReset(void);

void main(int argc, char **argv)
{
   FILE *fp;
   long l, *lp, *l2p;

   xyz();
   printf("tc:  %08lx\n", tc);
   printf("psr: %08lx\n", psr);
   printf("crp: %08lx %08lx\n", crp1, crp2);
   printf("srp: %08lx %08lx\n", srp1, srp2);

   fp = fopen("kick2.04", "rb");
   lp = AllocMem((long)(512L * 1024L), 1L);
   fread((long *)0x80000, 1024L, 512L, fp);
   fclose(fp);

   Disable();
   abc();
   POINTER=lp;
   l2p = (long *)0xf80000;
   for (l = 256L * 1024L / 4L; l; --l) *l2p++ = *lp++;
   l2p = (long *)0x07e000;
   for (l = 256L * 1024L / 4L; l; --l) *l2p++ = *lp++;
   myReset();
   Enable();

   exit(0);
}

