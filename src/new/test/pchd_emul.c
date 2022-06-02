
#include <exec/types.h>
#include <clib/dos_protos.h>
#include <clib/exec_protos.h>
#include <dos/dos.h>
#include <dos/dosextens.h>
#include <dos/filehandler.h>
#include <exec/memory.h>
#include <stdio.h>

extern struct DOSBase *DOSBase;

extern long unit, flags, start_offset, end_offset;
extern short surfaces, blkspertrk, numcyls;
extern char device_name[], partition_name[];
extern struct {
   long code_start;
   long code_end;
   short num_funcs;
   struct {
      short lib_offset;
      short code_offset;
   } func_table[1];
} code_table;

void main(int argc, char **argv)
{
   struct FileSysStartupMsg *fssmp;
   struct DosEnvec *dep;
   struct DosList *dolp;
   char *cp;
   long l;
   int rc = 10;

   printf("PC_HardDisk_Partition_Handler v1.1\n");
   printf("Copyright (C) 1991 by Matthias Schmidt\n");

   if (argc != 2 || strlen(argv[1]) > 15) {
      printf("\nUsage: %s <pc_partition_name>\n", *argv);
      exit(10);
   }

   if (dolp = LockDosList(LDF_DEVICES | LDF_READ)) {
      if (dolp = FindDosEntry(dolp, (UBYTE *)argv[1], LDF_DEVICES | LDF_READ)) {
         fssmp = (struct FileSysStartupMsg *)
               BADDR(dolp->dol_misc.dol_handler.dol_Startup);
         dep = (struct DosEnvec *)BADDR(fssmp->fssm_Environ);
         unit = fssmp->fssm_Unit;
         flags = fssmp->fssm_Flags;
         strcpy(device_name, ((char *)BADDR(fssmp->fssm_Device)) + 1);
         strcpy(partition_name, argv[1]);
         l = (dep->de_Surfaces * dep->de_BlocksPerTrack) << 9;
         start_offset = dep->de_LowCyl * l;
         end_offset = dep->de_HighCyl * l;
         surfaces = dep->de_Surfaces;
         blkspertrk = dep->de_BlocksPerTrack;
         numcyls = dep->HighCyl - dep->LowCyl;
         l = code_table.code_end - code_table.code_start;
         if (cp = (char *)AllocMem((ULONG)l, MEMF_PUBLIC)) {
            do {
               --l;
               cp[l] = ((char *)code_table.code_start)[l];
            } while (l >= 0);
            for (l = 0; l < code_table.num_funcs; ++l) {
               ((APTR *)cp)[l] = SetFunction((struct Library *)DOSBase,
                     (LONG)code_table.func_table[l].lib_offset,
                     (ULONG (*)()) ((LONG)cp + code_table.func_table[l].code_offset));
            }
            printf("PCHD_Handler's new DOS functions sucessfully installed.\n");
            rc = 0;
         } else {
            printf("Not enough memory for PCHD_Handler's DOS library code!\n");
         }
      } else {
         printf("Unable to find the partition/device '%s'!\n", argv[1]);
      }
      UnLockDosList(LDF_DEVICES | LDF_READ);
   } else {
      printf("Unable to acess the device list!\n");
   }
   exit(rc);
}

#asm
        include "exec/types.i"
        include "devices/scsidisk.i"
        include "dos/dos.i"
        include "exec/io.i"
        include "exec/lists.i"
        include "exec/nodes.i"
        include "exec/ports.i"

_AbsExecBase    equ     4

        dseg
_code_table:
        dc.l    code_start
        dc.l    code_end
        dc.w    5
        dc.w    (-_LVOOpen#),(open-code_start)
        dc.w    (-_LVOClose#),(close-code_start)
        dc.w    (-_LVORead#),(read-code_start)
        dc.w    (-_LVOWrite#),(write-code_start)
        dc.w    (-_LVOSeek#),(seek-code_start)

        cseg
code_start:
        ds.l    5
block:
        ds.b    512
_unit:
        dc.l    0
_flags:
        dc.l    0
_start_offset:
        dc.l    0
_end_offset:
        dc.l    0
_surfaces:
        dc.w    0
_blkspertrk:
        dc.w    0
_numcyls:
        dc.w    0
_device_name:
        ds.b    16
_partition_name:
        ds.b    16
msgport:
        dc.l    0,0
        dc.b    NT_MSGPORT,0
        dc.l    0
        dc.b    PA_SIGNAL,0
        dc.l    0
        dc.l    0,0,0
iob:
        dc.l    0,0
        dc.b    NT_MESSAGE,0
        dc.l    0,0
        dc.w    IOSTD_SIZE
        dc.l    0,0
        dc.w    0
        dc.b    0,0
        dc.l    0,0,0,0

toupper:
        cmp.b   #'a',d0
        bcs.s  toupper_ok
        cmp.b   #('z'+1),d0
        bcc.s  toupper_ok
        sub.b   #('a'-'A'),d0
toupper_ok:
        rts

stricmp:
        move.b  (a0)+,d0
        bsr.s   toupper
        move.b  d0,d1
        move.b  (a1)+,d1
        bsr.s   toupper
        cmp.b   d1,d0
        bne.s   stricmp_false
        tst.b   d0
        bne.s   stricmp
        moveq.l #0,d0
        rts
stricmp_false:
        moveq.l #-1,d0
        bcs.s   stricmp_ok
        moveq.l #1,d0
stricmp_ok:
        rts

open:
        move.l  d1,a0
        move.l  a0,-(sp)
        lea.l   _partition_name(pc),a1
        bsr.s   stricmp
        move.l  (sp)+,d1
        tst.b   d0
        beq.s   open_new
open_old:
        move.l  code_start(pc),a0
        jmp     (a0)
open_new:
        cmp.l   #MODE_OLDFILE,d2
        beq.s   open_ok
        cmp.l   #MODE_NEWFILE,d2
        beq.s   open_ok
        cmp.l   #MODE_READWRITE,d2
        bne.s   open_old
open_ok:
        movem.l d1/a6,-(sp)
        moveq.l #8,d0
        moveq.l #MEMF_PUBLIC,d1
        move.l  (_AbsExecBase).w,a6
        jsr     (_LVOAllocMem#).w(a6)
        tst.l   d0
        beq.s   open_end
        move.l  d0,a0
        lea.l   _partition_name(pc),a1
        move.l  a1,(a0)
        clr.l   4(a0)
        lsr.l   #2,d0
open_end:
        movem.l (sp)+,d1/a6
        rts

close:
        move.l  d1,a1
        add.l   a1,a1
        add.l   a1,a1
        lea.l   _partition_name(pc),a0
        cmp.l   a0,(a1)
        beq.s   close_new
        move.l  (code_start+4)(pc),a0
        jmp     (a0)
close_new:
        movem.l d1/a6,-(sp)
        moveq.l #8,d0
        move.l  (_AbsExecBase).w,a6
        jsr     (_LVOFreeMem#).w(a6)
        moveq.l #0,d0
        movem.l (sp)+,d1/a6
        rts

read:
        move.w  #CMD_READ,d0
        move.l  (code_start+8)(pc),-(sp)
        bra.s   readwrite_do

write:
        move.w  #CMD_WRITE,d0
        move.l  (code_start+12)(pc),-(sp)

readwrite_do:
        move.l  d1,a1
        add.l   a1,a1
        add.l   a1,a1
        lea.l   _partition_name(pc),a0
        cmp.l   a0,(a1)
        beq.s   readwrite_new
        move.l  (sp)+,a0
        jmp     (a0)
readwrite_new:
        addq.w  #4,sp
        movem.l d1-d5/a1-a3/a6,-(sp)
        move.l  4(a1),d4                ; d4 := offset
        move.w  d0,a3                   ; a3 := CMD_READ or CMD_WRITE
        move.w  #512,a2                 ; a2 := sector size (#512)
        moveq.l #0,d5                   ; d5 := actual
        cmp.l   a2,d4
        bcc.s   readwrite_hd            ; offset >= sector size ?

; ... offset < 512 -> block 0
        cmp.w   #CMD_READ,a3            ; only read accesses are allowed to block 0!
        bne.s   readwrite_end
readwrite_blk0:
        lea.l   block(pc),a0
        move.l  a0,a1
        moveq.l #127,d0
        move.l  #$f6f6f6f6,d1
readwrite_blk0_fill_loop:
        move.l  d1,(a1)+
        dbf     d0,readwrite_blk0_fill_loop
        move.l  #'AB00',(a0)+
        move.l  #('T<<24),(a0)+
        move.w  _surfaces(pc),(a0)+
        move.w  _blkspertrk(pc),(a0)+
        move.w  _numcyls(pc),(a0)
        move.l  a2,d0                   ; d0 (count) := sector/block size (#512)
        sub.w   d4,d0                   ; d0 (count) -= offset
        cmp.l   d0,d3
        bcc.s   readwrite_blk0_rest     ; length >= rest of block 0 ?
        move.w  d3,d0                   ; else: d0 (count) := rest of block 0
readwrite_blk0_rest:
        lea.l   -12(a0,d4.l),a0
        move.l  d2,a1                   ; a1 := d2 (data)
        sub.l   d0,d3                   ; d3 (length) -= rest of block 0
        add.l   d0,d5                   ; d5 (actual) += count
        add.l   d0,d4                   ; d4 (offset) += count
        bra.s   readwrite_blk0_copy_loopstart
readwrite_blk0_copy_loop:
        move.b  (a0)+,(a1)+
readwrite_blk0_copy_loopstart:
        dbf     d0,readwrite_blk0_copy_loop
        move.l  a1,d2                   ; d2 (data) := new data

; handle all other blocks than block 0
readwrite_hd:
        tst.l   d3                      ; d3 (length) >= 0 ?
        beq.s   readwrite_end
        bmi.s   readwrite_end
        move.l  d4,d0                   ; d0 (real offset) := offset
        sub.l   a2,d0                   ; d0 (real offset) -= sector size
        add.l   _startoffset(pc),d0     ; d0 (real offset) += start offset (on hd)
        move.l  d3,d1                   ; d1 (real length) := length
        add.l   d0,d3                   ; d3 (length) += start offset (on hd)
        cmp.l   _endoffset(pc),d3
        bcs.s   readwrite_length_ok     ; d3 (length) <= end offset (on hd) ?
        beq.s   readwrite_length_ok
        move.l  _endoffset(pc),d1       ; d1 (real length) := end offset (on hd)
        sub.l   d0,d1                   ; d1 (real length) -= real offset
        bpl.s   readwrite_length_ok
        moveq.l #0,d1                   ; d1 (real length) := 0
readwrite_length_ok:
        move.l  d2,a0                   ; a0 (new data) := data
        cmp.w   #CMD_READ,a3
        bne.s   readwrite_write
readwrite_read:
        bsr.s   read_hd
        bra.s   readwrite_continue
readwrite_write:
        bsr.s   write_hd
readwrite_continue:
        add.l   d0,d5                   ; d5 (actual) += result
readwrite_end:
        move.l  d5,d0                   ; d0 (result) := actual
        movem.l (sp)+,d1-d5/a1-a3/a6
        add.l   d0,4(a1)
        rts

