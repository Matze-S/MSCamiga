
clude <stdio.h> �x    �x4long tc;   �x< long crp[4] = { -1, -1, -1, -1};   �xL long srp[4] = { -1, -1, -
;   �xt long drp[4] = { -1, -1, -1, -1};   �x�    �x�void modify(void)  �x�{  �x�   long *lp;   �x�       �y  lp = 
)crp[1];        lp = (long *)(lp[7] & ~0xf

lp[0xf * 4 + 1] = lp[0xf * 4 + 1
fL | 0xd;       4   lp[0xf * 4 + 0] = lp[0xf * 4 + 0] & ~0xffL | 0xd;          lp = (long *)crp[1];  
lp = (long *)(lp[0] & ~0xfL);   

lp[0x0 * 4 + 0] = 0x00000000L | 

lp[0x0 * 4 + 1] = 0x00040000L | 

lp[0x0 * 4 + 2] = 0x00080000L | 

lp[0x0 * 4 + 3] = 0x000c0000L | 

lp[0x0 * 4 + 4] = 0x00000000L | 

lp[0x0 * 4 + 5] = 0x00040000L | 



lp[0xc * 4 + 0] = 0x00100000L | 

lp[0xc * 4 + 1] = 0x00140000L | 

lp[0xc * 4 + 2] = 0x00180000L | 

lp[0xc * 4 + 3] = 0x001c0000L | 


}


d get_regs(void)    {      #asm       
   mc68851     
   mc68881                move.l   a5,-(sp)    
move.l   _SysBase#,a6          
 _LVODisable#(a6)          lea.
a5         jsr      _LVOSupervisor#(a6)    
     _LVOEnable#(a6)       move
)+,a5          bra      2$             1$ lea.l    _tc,a0        pmove    tc,(a0)       lea.l    _crp,a0    
e    crp,(a0)          lea.l    _srp,a0       pmove    srp,(a0)               ;    pmove    (a0),srp     ;    pmov
a0),drp     ;    pmove    (a0),pcsr    
ove    (a0),psr     ;    pmove    (a0),crp     ;    pmove    (a0),ac      ;    pmove    (a0),scc     ;   
   (a0),val     ;    pmove    (

  pmove    (a0),tc      ;      
ove    srp,(a0)     ;    pmove    drp,(a0)     ;    pmove    pcsr,(a0)    ;    pmove    crp,(a0)     ;   
   ac,(a0)      ;    pmove    s

  pmove    val,(a0)     ;    pm
al,(a0)     ;    pmove    tc       ;      ;    prestore (a0)+    ;      ;    pflusha       ; 
lushr  (a0)     ;    pflushs  crp,#4       ;    psave    -(a0)    ;    pflush    d0,#5       ;    
    d0,(a0)     ;    ptestw    sfc,(a0),#4     ;    ploadr    d0,(a0)     ;    ptestr    sfc,(a0),#5               
u aus          clr.l    -(sp)         pmove    (sp),tc       addq.w   #4,sp                 jsr      _mod


u an       lea.l    _tc,a0        pmove    (a0),tc               rte             2$     #endasm    }   

d main(int argc, char **argv)       {         get_regs();                modify();          printf("t
8lx\n", tc);    2   printf("crp := %08lx %08lx\n
], crp[1]);     2   printf("srp := %08lx %08lx\n
], srp[1]);     2   printf("drp := %08lx %08lx\n
], drp[1]);        exit(0);    }              

