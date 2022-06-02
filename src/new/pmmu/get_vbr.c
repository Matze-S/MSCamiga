
#include <stdio.h>

long *get_vbr(void)
{
#asm
   movem.l  d2/a5,-(sp)
   move.l   (_AbsExecBase#).w,a6
   jsr      _LVODisable#(a6)
   lea.l    1$,a5
   jsr      _LVOSupervisor#(a6)
   bra.s    2$
   machine  mc68010
1$ movec.l  vbr,d0
   move.l   d0,d2
   rte
2$ jsr      _LVOEnable#(a6)
   move.l   d2,d0
   movem.l  (sp)+,d2/a5
#endasm
}

void main(int argc, char **argv)
{
   printf("VectorBaseRegister VBR := $%08lx\n", (unsigned long)get_vbr());
   exit(0);
}

