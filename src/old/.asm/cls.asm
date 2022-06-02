
*
*  cls.asm
*
*  Written at 19-May-89 01:19 by Matthias Schmidt
*

        lea.l   8(sp),a1        ; build BCPL environment
        sub.l   4(sp),a1
        sub.l   a0,a0

        moveq.l #12,d1
        move.l  $e0(a2),a4
        moveq.l #$c,d0
        jsr     (a5)            ; wrch(12)

        moveq.l #0,d0
        rts

