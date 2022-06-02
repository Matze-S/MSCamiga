
#include <exec/resident.h>

struct res {
   struct Resident r;
   unsigned char *a;
   unsigned long s;
};

extern struct res *FindResident();

unsigned char *addr,byte;
unsigned long size;
void testmem();

#asm
_testmem:
   move.b _byte,d0
   move.l _addr,a0
   move.l _size,d1
testmemloop:
   addq.b #1,d0
   cmp.b (a0)+,d0
   bne.s testmemfalse:
   subq.l #1,d1
   bne.s testmemloop
testmemfalse:
   move.b d0,_byte
   move.l a0,_addr
   move.l d1,_size
   rts
#endasm

main()
{
   register struct res *res;

   if (res = FindResident("memalloc.resident")) {
      addr = res->a;
      byte = *addr++;
      size = res->s;
      printf(" ---- Address: %lx - Size: %ld ----\n",addr,size);
      for (;;) {
         --size;
         testmem();
         if (size == 0) {
            printf("All it's ok!\n");
            break;
         }
         printf("Error at $%lx, there is %d, and there should be %d\n",
            addr,(int)addr[-1],(int)byte);
      }
   } else
      printf("Cannot find 'memalloc.resident'!\n");
}

