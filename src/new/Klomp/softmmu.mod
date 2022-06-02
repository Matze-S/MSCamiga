#include <exec/types.h>
#include <exec/nodes.h>
#include <exec/lists.h>
#include <exec/memory.h>
#include <exec/interrupts.h>
#include <exec/ports.h>
#include <exec/libraries.h>
#include <exec/io.h>
#include <exec/tasks.h>
#include <exec/execbase.h>
#include <intuition/intuitionbase.h>

#include <functions.h>

#define SUCCESS 0
#define NO_EXEC 1
#define NO_INTUITION 2
#define HOW_TO 3
#define NOT_ENOUGH_MEM 4

#define MEGACHIP 0x01
#define INITFAST 0x02
#define PALCHECK 0x04

#define NUMLIBS 7
#define NUMDEVS 7
#define NUMRESOURCES 5

#define OS_ADDR 0xfc0000L
#define OS_SIZE 0x40000L

#define INSTALLED  ((*(ULONG*)((ULONG*)ExecBase-1) < OS_ADDR) \
               || (*(ULONG*)((ULONG*)ExecBase-1) > (OS_ADDR + OS_SIZE)))

struct ExecBase *ExecBase;
struct IntuitionBase *IntuitionBase;

struct command {
       UWORD jmp;
       ULONG loc;
       };

UBYTE *LibNames[NUMLIBS]=
      {(UBYTE*)"expansion.library",
       (UBYTE*)"graphics.library",
       (UBYTE*)"layers.library",
       (UBYTE*)"intuition.library",
       (UBYTE*)"mathffp.library",
       (UBYTE*)"romboot.library",
       (UBYTE*)"ramlib.library"};

UBYTE *DevNames[NUMDEVS]=
      {(UBYTE*)"keyboard.device",
       (UBYTE*)"gameport.device",
       (UBYTE*)"timer.device",
       (UBYTE*)"audio.device",
       (UBYTE*)"input.device",
       (UBYTE*)"console.device",
       (UBYTE*)"trackdisk.device"};

UBYTE *ResNames[NUMRESOURCES]=
      {(UBYTE*)"potgo.resource",
       (UBYTE*)"ciaa.resource",
       (UBYTE*)"ciab.resource",
       (UBYTE*)"misc.resource",
       (UBYTE*)"disk.resource"};

UBYTE *RomKickSB;
UBYTE *RomKickEB;

UBYTE *RamKickSB;
UBYTE *RamKickEB;

ULONG *RomKickSL;
ULONG *RomKickEL;

ULONG *RamKickSL;
ULONG *RamKickEL;

ULONG *RamStart;
ULONG *RamEnd;
ULONG *CSumPos;

LONG DiffAddr;

APTR axtol(str)
UBYTE *str;
{
  ULONG i,n;

  for(i=0; *(str+i) != '\0' ; i++)
     *(str+i) = toupper(*(str+i));

  i=0;
  for(n = 0; *(str+i) >= '0'  && *(str+i) <= 'F' ; i++)
  {
     (*(str+i) >= 'A' ) ? (*(str+i) -= 7) : *(str+i);
     n = (n << 4) + *(str+i) - '0' ;
  }
  return((APTR)n);
}

getout(reason)
USHORT reason;
{
   switch(reason)
   {
      case SUCCESS:      break;

      case NO_EXEC:      printf("\nKeine exec.library\n");
                         break;
      case NO_INTUITION: printf("\nKeine intuition.library\n");
                         break;
      case HOW_TO:       printf("\n Aufruf: ");
                         printf("SoftMMU [-c][-f][-p] ");
                         printf("FastRAM-Anfang FastRAM-Ende\n\n");
                         break;
      case NOT_ENOUGH_MEM:
              printf("\nMindestens 256KB FastRAM sind erforderlich !\n");
              break;
   }
   if(IntuitionBase) CloseLibrary(IntuitionBase);
   if(ExecBase) CloseLibrary(ExecBase);
   exit(0L);
}

patchOS(flags,start)
USHORT flags;
ULONG start;
{
   if(flags & MEGACHIP)
     *(RamKickSB + 0x19d) = 0x10;

   if(flags & INITFAST)
   {
      *(ULONG*)(RamKickSB + 0x1b6) = (ULONG)RamKickSB;
      *(ULONG*)(RamKickSB + 0x1be) = (ULONG)RamKickSB;

      *(ULONG*)(RamKickSB + 0x1d8) = start;
      *(ULONG*)(RamKickSB + 0x1de) = (ULONG)RamKickSB;

      *(ULONG*)(RamKickSB + 0x1f0) = start;

      *(ULONG*)(RamKickSB + 0x1fc) = start;
    }
}

ULONG calcCS()
{
   ULONG csum;

#asm
      movem.l d2/a2,-(sp)
      move.l  _RamKickSB,a0
      move.l  _RamKickEB,a1
      addq.l  #1,a1
      move.l  8(a5),a2
      move.l  (a2),d2
      move.l  #0,(a2)
      moveq   #0,d0
loop:
      move.l  (a0),d1
      add.l   d0,d1
      cmp.l   d0,d1
      bge     skip
      addq.l  #1,d0
skip:
      add.l   (a0)+,d0
      cmp.l   a1,a0
      bcs     loop
      moveq   #0,d1
      sub.l   d0,d1
      move.l  d1,-4(a5)
      move.l  d2,(a2)
      movem.l (sp)+,d2/a2
#endasm

   *CSumPos = csum;
}

SetCold(RamKickStart)
APTR RamKickStart;
{
   UWORD *ChkStart,*ChkEnd,*ChkPtr,ExecSum = 0;

   ExecBase->ColdCapture = RamKickStart;

   ChkStart = (UWORD *)&(ExecBase->SoftVer);
   ChkEnd = (UWORD *)&(ExecBase->MaxExtMem);

   for(ChkPtr = ChkStart;ChkPtr <= ChkEnd;ChkPtr++)
   {
      ExecSum = ExecSum + *ChkPtr;
   }
   ExecBase->ChkSum = (0xFFFF - ExecSum);
}

boot()
{
   SuperState();
#asm
      lea.l   2,a0
      reset
      jmp     (a0)
#endasm
}

void pROMJumps(RamLocS,RamLocE)
UBYTE *RamLocS,*RamLocE;
{  
   struct command *RJmp;
   UWORD *sAdr;
   SHORT i=0;

   Disable();
   for(sAdr = (UWORD*)RamLocS; sAdr < (UWORD*)RamLocE; sAdr++)
   {
      if(*sAdr == 0x4ef9 || *sAdr == 0x4eb9)
      { 
         RJmp = (struct command *)sAdr;
         if(RJmp->loc >= 0xfc0000 && RJmp->loc <= 0xffffff)
              RJmp->loc = RJmp->loc - DiffAddr;
      }
    }
    Enable();
}

void patchDOS(base)
UWORD *base;
{
   ULONG *offs;
   (UBYTE*)offs = (UBYTE*)base + 0x2e;

   *offs = *offs - DiffAddr;
   *(++offs) = *offs - DiffAddr;

   for(offs = (ULONG*)base + 0x31; offs <= (ULONG*)base + 0xd2; offs++)
   {
      if(*offs > 0xff0000 && *offs < 0xffffff)
        *offs = *offs - DiffAddr;
   }
}

struct Library *findlib(node)
UBYTE *node;
{
  #ifdef DEBUG
    printf("\n%s\n",node);
  #endif
  return((struct Library*)FindName(ExecBase->LibList.lh_Head,node));
}

struct Library *finddev(node)
UBYTE *node;
{
  #ifdef DEBUG
    printf("\n%s\n",node);
  #endif
  return((struct Library*)FindName(ExecBase->DeviceList.lh_Head,node));
}

struct Library *findres(node)
UBYTE *node;
{
  #ifdef DEBUG
    printf("\n%s\n",node);
  #endif
  return((struct Library*)FindName(ExecBase->ResourceList.lh_Head,node));
}

void SpeedFuncs(base,neg_Off)
UWORD *base;
ULONG *neg_Off;
{
   struct command *cmd;
   struct command *start;

   start = (struct command *)((ULONG)base-(ULONG)neg_Off);

   for(cmd = start;cmd < (struct cmd *)base;cmd++)
   {
     if((cmd->loc > 0xf00000)
        && (cmd->loc < 0xffffff))
       cmd->loc = cmd->loc - DiffAddr;
   }
}

void main(argc,argv)
SHORT argc;
UBYTE *argv[];
{
   UBYTE *c;
   SHORT i;
   ULONG param;
   USHORT flags = 0;

   APTR RamKickStart;
   struct Library *myNode = NULL;

   RomKickSB = OS_ADDR;
   RomKickSL = OS_ADDR;

   printf("\nSoftMMU - FastRAM-Einbindung und Kopie des OS ins RAM");
   printf("\n        **>> Winfried Krüger Mai 1990 <<**\n");

   while(--argc > 0 && (*++argv)[0] == '-')
   {
      for(c = (UBYTE *)(argv[0]+1); *c != '\0'; c++)
      {
        switch(tolower(*c))
         {
           case 'c': flags = flags|MEGACHIP;
                     break;
           case 'f': flags = flags|INITFAST;
                     break;
           case 'p': flags = flags|PALCHECK;
                     break;

           default: argc = 0;
                    break;
         }
      }
   }
   if(argc <=1) getout(HOW_TO);
   else
   {
      (APTR)RamStart = axtol(*argv);
      (APTR)RamEnd = axtol(*++argv);
   }

   if(RamEnd <= RamStart) getout(HOW_TO);
   if(((UBYTE*)RamEnd - (UBYTE*)RamStart) < OS_SIZE) getout(NOT_ENOUGH_MEM);

   (ULONG*)RamKickEB = RamKickEL = RamEnd;
   RamKickSB = (UBYTE*)RamKickSL = (UBYTE*)RamKickEL - OS_SIZE;

   (UBYTE*)CSumPos = RamKickSB + 0x3ffe8;
   DiffAddr = (LONG)RomKickSL - (LONG)RamKickSL;

   ExecBase = (struct ExecBase*)OpenLibrary("exec.library",NULL);
   if(ExecBase == NULL) getout(NO_EXEC);

   if((*(UWORD*)RamKickSB == 0x1111)
     /*  && (*CSumPos == calcCS(CSumPos))*/
       && INSTALLED)
   {
     printf("\n2.Runde\n");
     if (flags&PALCHECK)
     {
        IntuitionBase = (struct IntuitionBase*)
                  OpenLibrary("intuition.library",0L);
        if (! IntuitionBase) getout(NO_INTUITION);

        if(((IntuitionBase->ViewLord.ViewPort->Modes & LACE) &&
              (IntuitionBase->FirstScreen->Height <= 500)) ||
              ((!(IntuitionBase->ViewLord.ViewPort->Modes & LACE)) &&
              (IntuitionBase->FirstScreen->Height <= 250)))
        {
           Disable();
           boot();
        }
     }
     RamKickStart = (APTR)(RamKickSB + 0x0184);
     printf("\nOS befindet sich bereits im FastRAM\n");
     SetCold(RamKickStart);
     for (i = 0; i <= NUMLIBS-1;i++)
     {
        myNode = findlib(LibNames[i]);
        Forbid();
        SpeedFuncs((ULONG *)myNode,(UWORD *)myNode->lib_NegSize);
        myNode->lib_Flags = LIBF_CHANGED;
        SumLibrary(myNode);
        Permit();
     }
     for (i = 0; i <= NUMDEVS-1;i++)
     {
        myNode = finddev(DevNames[i]);
        Forbid();
        SpeedFuncs((ULONG *)myNode,(UWORD *)myNode->lib_NegSize);
        myNode->lib_Flags = LIBF_CHANGED;
        SumLibrary(myNode);
        Permit();
     }
     for (i = 0; i <= NUMRESOURCES-1;i++)
     {
        myNode = findres(ResNames[i]);
        Forbid();
        SpeedFuncs((ULONG *)myNode,(UWORD *)myNode->lib_NegSize);
        myNode->lib_Flags = LIBF_CHANGED;
        SumLibrary(myNode);
        Permit();
     }

     myNode = findlib("dos.library");
     Forbid();
     patchDOS(myNode);
     myNode->lib_Flags = LIBF_CHANGED;
     SumLibrary(myNode);
     Permit();
   }
   else
   {
     printf("\n1.Runde\n");
     RamKickStart = (APTR)(RamKickSB + 0x01ce);
     CopyMemQuick(RomKickSL,RamKickSL,(ULONG)OS_SIZE);
     printf("\nOS ins FastRAM kopiert\n");
     pROMJumps(RamKickSB,RamKickEB);
     patchOS(flags,RamStart);
     printf("\nOS-Patch durchgeführt\n");
     *CSumPos = calcCS();
     printf("\nOS-Checksumme angepaßt\n");
     SetCold(RamKickStart);
     printf("\nColdCapture verbogen\n");
     Disable();
     boot();
   }
   getout(SUCCESS);
}
