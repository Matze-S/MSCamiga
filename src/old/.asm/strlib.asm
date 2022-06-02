
*
* String-Functions for MANX Aztec C68K/Amiga
* using small code and small data
*
* Created on 04-Jan-89 01:21 and
* Copyright © 1989 by Matthias Schmidt
*

   public   _strlen
_strlen:
   move.l   4(sp),a0
   moveq.l  #-1,d0
1$ addq.w   #1,d0
   tst.b    (a0)+
   bne.s    1$
   rts

   public   _strcpy
_strcpy:
   movem.l  4(sp),a0/a1
   move.l   a0,d0
1$ move.b   (a1)+,(a0)+
   bne.s    1$
   rts

   public   _strncpy
_strncpy:
   movem.l  4(sp),a0/a1
   move.w   12(sp),d1
   move.l   a0,d0
   bra.s    2$
1$ move.b   (a1)+,(a0)+
2$ dbeq     d1,1$
   beq.s    4$
3$ clr.b    (a0)+
4$ dbf      d1,3$
   rts

   public   _strcat
_strcat:
   movem.l  4(sp),a0/a1
   move.l   a0,d0
1$ tst.b    (a0)+
   bne.s    1$
   subq.l   #1,a0
2$ move.b   (a1)+,(a0)+
   bne.s    2$
   rts

   public   _strncat
_strncat:
   movem.l  4(sp),a0/a1
   move.w   12(sp),d1
   move.l   a0,d0
1$ tst.b    (a0)+
   bne.s    1$
   subq.l   #1,a0
   subq.w   #1,d1
2$ move.b   (a1)+,(a0)+
   dbeq     d1,2$
   rts

   public   _strcmp
_strcmp:
   movem.l  4(sp),a0/a1
   moveq.l  #-1,d0
1$ cmp.b    (a1)+,(a0)+
   bne.s    2$
   tst.b    -1(a0)
   bne.s    1$
   moveq.l  #0,d0
   rts
2$ bls.s    3$
   moveq    #1,d0
3$ rts

   public   _strncmp
_strncmp:
   movem.l  4(sp),a0/a1
   move.w   12(sp),d0
1$ subq.w   #1,d0
   bmi.s    2$
   cmp.b    (a1)+,(a0)+
   bne.s    3$
   tst.b    -1(a0)
   bne.s    1$
2$ moveq.l  #0,d0
   rts
3$ bls.s    4$
   moveq.l  #1,d0
   rts
4$ moveq.l  #-1,d0
   rts

   public   _stricmp
_stricmp:
   movem.l  4(sp),a0/a1
1$ move.b   (a0)+,d0
   and.b    #$5f,d0
   move.b   (a1)+,d1
   and.b    #$5f,d1
   cmp.b    d1,d0
   bne.s    2$
   tst.b    -1(a0)
   bne.s    1$
   moveq.l  #0,d0
2$ bls.s    3$
   moveq.l  #1,d0
   rts
3$ moveq.l  #-1,d0
   rts

   public   _strnicmp
_strnicmp:
   move.l   d2,-(sp)
   movem.l  8(sp),a0/a1
   move.w   16(sp),d2
1$ subq.w   #1,d2
   bmi.s    2$
   move.b   (a0)+,d0
   and.b    #$5f,d0
   move.b   (a1)+,d1
   and.b    #$5f,d1
   cmp.b    d1,d0
   bne.s    4$
   tst.b    -1(a0)
   bne.s    1$
2$ moveq.l  #0,d0
3$ move.l   (sp)+,d2
   rts
4$ bls.s    5$
   moveq.l  #1,d0
   bra.s    3$
5$ moveq.l  #-1,d0
   bra.s    3$

   end

