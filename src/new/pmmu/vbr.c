
#include <exec/memory.h>
#include <functions.h>
#include <stdio.h>

extern long size;
extern void rout(void);

#asm
   cseg
   xdef  _rout
_rout:
   movem.l  d0/a0,-(sp)
   moveq.l  #-1,d0
1$ move.w   d0,$dff180
   dbf      d0,1$
   move.l   10(sp),a0
   move.w   (a0),d0
   and.w    #$ffc0,d0
   cmp.w    #$40c0,d0
   beq.s    2$
   movem.l  (sp)+,d0/a0
   move.l   (_rout-4)(pc),-(sp)
   rts
2$ move.w   (a0)+,3$
   move.l   a0,10(sp)
   movem.l  (sp)+,d0/a0
3$ dc.w     0
   rte
_rout_end:
   dseg
_size:
   dc.l     (_rout_end-_rout)
   cseg
#endasm

void (**_vbr_)();

void set_vbr(void (**vbr)())
{
   _vbr_ = vbr;
#asm
   move.l   _SysBase#,a6
   jsr      _LVODisable#(a6)
   jsr      _LVOSuperState#(a6)

   machine  mc68020
   mc68851

   subq.w   #4,sp
   pmove.l  tc,(sp)

   clr.l    -(sp)
   pmove.l  (sp),tc
   addq.w   #4,sp

   move.l   __vbr_,d0
   movec.l  d0,vbr

   pmove.l  (sp),tc
   addq.w   #4,sp

   jsr      _LVOUserState#(a6)
   jsr      _LVOEnable#(a6)
#endasm
}

void main(int argc, char **argv)
{
   long *vbr, *lp;
   char *cp;
   int i;

   if (vbr = AllocMem(1028L + size, MEMF_CHIP)) {
      vbr = (long *)0x07fd0000;
      for (i = 0; i < 256; ++i) vbr[i] = ((long *)0L)[i];
      lp = &vbr[256];
      *lp++ = ((long *)0L)[8];
      cp = (char *)lp;
      for (i = 0; i < size; ++i) cp[i] = ((char *)rout)[i];
/*      ((long *)0L)[8] = (long)cp;
*/
      set_vbr((void (**)())vbr);
      printf("vbr := $%08lx\n", _vbr_);
   }
   exit(0);
}
