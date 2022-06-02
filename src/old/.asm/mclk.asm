; Copyright (C) 1989 by Matthias Schmidt

   section laber,CODE

STACK_SIZE  equ   2000
WAIT_TIME   equ   250000

_main:
   ;------ allocate memory for task struct, name, stack and code
   move.l   (4).w,a6    ; SysBase
   lea.l (MemList-14)(pc),a0  ; entry
   jsr   -$de(a6)    ; AllocEntry()
   moveq.l #20,d2
   tst.l d0
   bmi.s exit

   ;------ initialize the stack pointers in the task structure
   move.l   d0,a1
   move.l   24(a1),a3
   move.l   16(a1),a0
   lea.l STACK_SIZE(a0),a2
   move.l   a2,d0
   movem.l  d0/a0/a2,54(a3)      ; tc_SPReg,tc_SPLower & tc_SPUpper

   ;------ set a ptr to the task's name and copy it and its code

   move.l   #((__CodeEnd-CodeStart)/2-1),d0
   move.l   32(a1),a2
   move.l   a2,a4
   lea.l (TaskName-CodeStart)(a2),a0
   move.l   a0,10(a3)      ; tc_Node.ln_Name
   lea.l CodeStart(pc),a0
Copy_Code_Loop:
   move.w   (a0)+,(a4)+
   dbf   d0,Copy_Code_Loop

   ;------ initialize the tc_MemList structure
   lea.l 78(a3),a0      ; tc_MemEntry.lh_Tail
   clr.l (a0)
   move.l   a0,-(a0)    ; tc_MemEntry.lh_Head
   move.l   a0,8(a0)    ; tc_MemEntry.lh_TailPred
   jsr   -$f0(a6)    ; AddHead()

   ;------ set the task's priority
   move.b   #1,8(a3)    ; tc_Node.ln_Type

   ;------ correct address references in task code
   lea.l RelocTable(pc),a0
   move.l   a2,d1
   bra.s Reloc_Entry
Reloc_Loop:
   add.l d1,0(a2,d0.w)
Reloc_Entry:
   move.w   (a0)+,d0
   bne.s Reloc_Loop

   ;------ start task
   move.l   a3,a1       ; task
   sub.l a3,a3       ; finalPC
   jsr   -$11a(a6)      ; AddTask()

   ;------ exit(0)
   moveq.l #0,d2

   ;------  exit(d2)
exit:
   move.l   d2,d0
   rts

MemList:
   dc.w  3
   dc.l  $10001,STACK_SIZE
   dc.l  $10001,92
   dc.l  1,(__CodeEnd-CodeStart)

;
; task code -- main code !
;

CodeStart:

   ;------ save a pointer to my own task structure
   move.l   (4).w,a6    ; SysBase
   sub.l a1,a1       ; name
   jsr   -$126(a6)      ; FindTask()
   move.l   d0,a2

   ;------ allocate a signal
   moveq.l #-1,d0       ; signalNum
   jsr   -$14a(a6)      ; AllocSignal()
   tst.b d0
   bmi   noSignal

   ;------ set mp_SigBit and mp_SigTask
   lea.l Timer_Port(pc),a0
   move.b   d0,15(a0)      ; Timer_Port.mp_SigBit
   move.l   a2,16(a0)      ; Timer_Port.mp_SigTask

   ;------ open the timer device
   lea.l Timer_Name(pc),a0 ; devName
   moveq.l #1,d0        ; unit
   lea.l Time_Req(pc),a1   ; ioRequest
   moveq.l #0,d1        ; flags
   jsr   -$1bc(a6)      ; OpenDevice()
   tst.l d0
   bne   freeSignal

   ;------ open the intuition library
   lea.l Intuition_Name(pc),a1   ; libName
   moveq.l #0,d0        ; version
   jsr   -$228(a6)      ; OpenLibrary()
   move.l   d0,d6
   beq   closeTimerDev

   ;------ open a new window
   move.l   d6,a6       ; IntuitionBase
   lea.l New_Window(pc),a0 ; OWArgs
   jsr   -$cc(a6)    ; OpenWindow()
   tst.l d0
   beq   closeIntLib
   move.l   d0,a5

   ;------------ main loop ------------

main_loop:

   ;------ get free chip memory in kb
   move.l   (4).w,a6    ; SysBase
   moveq.l #2,d1        ; requirements
   jsr   -$d8(a6)    ; AvailMem()
   moveq.l #10,d1
   lsr.l d1,d0       ; free_chip_mem /= 1024

   ;------ write the value in the Date_Buffer
   lea.l (Date_Buffer+9)(pc),a0  ; end of buffer to write in
   moveq.l #3,d1        ; number of digits
   moveq.l  #' ',d5        ; fill-character
   bsr   Write_Value

   ;------ get free fast memory in kb
   moveq.l #4,d1        ; requirements
   jsr   -$d8(a6)    ; AvailMem()
   moveq.l #10,d1
   lsr.l d1,d0       ; free_fast_mem /= 1024

   ;------ write the value in the Date_Buffer
   lea.l (Date_Buffer+20)(pc),a0 ; end of buffer to write in
   moveq.l #4,d1        ; number of digits
   bsr   Write_Value

   ;------ get system time
   lea.l Time_Req(pc),a1      ; ioRequest
   move.w   #10,28(a1)     ; Time_Req.tr_node.io_Command
   jsr   -$1c8(a6)      ; DoIO()

   ;------ write the time in the Date_Buffer
   lea.l (Date_Buffer+35)(pc),a0 ; end of buffer to write in
   lea.l (Div_Table+6)(pc),a1 ; ptr to Div_Table
   lea.l (Fill_Table+3)(pc),a2   ; ptr to Fill_Table
   moveq.l #0,d0
   moveq.l #2,d3        ; counter
   move.l   (Time_Req+32)(pc),d4 ; d4 %= Time_Req.tr_time.tv_secs /
   lsr.l #1,d4       ; (24 * 60 * 60)
   divu.w   #43200,d4
   clr.w d4
   swap  d4
   roxl.l   #1,d4
Write_Time_Loop:
   divu.w   -(a1),d4    ; d0 := secs % Div_Table[counter]
   swap  d4       ; d4 /= Div_Table[counter]
   move.w   d4,d0
   clr.w d4
   swap  d4
   moveq.l #2,d1        ; number of digits
   move.b   -(a2),d5    ; get fill-character
   bsr   Write_Value
   subq.w   #1,a0       ; skip ':' backwards in Date_Buffer
   dbf   d3,Write_Time_Loop

   ;------ print the Date_Buffer in the window
   move.l   d6,a6       ; IntuitionBase
   move.l   50(a5),a0      ; rp
   lea.l Date_Text(pc),a1  ; itext
   moveq.l #20,d0       ; left
   moveq.l #3,d1        ; top
   jsr   -$d8(a6)    ; PrintIText()

   ;------ wait for WAIT_TIME microsecs and break
   ;------ if the CLOSEWINDOW gadget is selected
   move.l   (4).w,a6    ; SysBase
   lea.l Time_Req(pc),a1   ; ioRequest
   move.w   #9,28(a1)      ; Time_Req.tr_node.io_Command
   clr.l 32(a1)         ; Time_Req.tr_time.tv_secs
   move.l   #WAIT_TIME,36(a1) ; Time_Req.tr_time.tv_micro
   jsr   -$1ce(a6)      ; SendIO()

   ;------ build signal mask for Wait() and wait ...
   moveq.l #0,d0        ; signalSet
   move.l   86(a5),a3
   move.b   15(a3),d1      ; Window->UserPort->mp_SigBit
   bset.l   d1,d0
   move.b   (Timer_Port+15)(pc),d1  ; Timer_port.mp_SigBit
   bset.l   d1,d0
   jsr   -$13e(a6)      ; Wait()

   ;------ get the replied msg off the Timer_Port
   lea.l Timer_Port(pc),a0 ; port
   jsr   -$174(a6)      ; GetMsg()

   ;------ test for CLOSEWINDOW
   move.l   a3,a0       ; port
   jsr   -$174(a6)      ; GetMsg()
   tst.l d0
   beq   main_loop

   ;------ reply the IntuiMessage
   move.l   d0,a1       ; message
   jsr   -$17a(a6)      ; ReplyMsg()

   ;------ abort the SendIO() to the timer device
   lea.l Time_Req(pc),a1      ; ioRequest
   jsr   -$1e0(a6)      ; AbortIO()

   ;------ close window
   move.l   d6,a6       ; IntuitionBase
   move.l   a5,a0       ; Window
   jsr   -$48(a6)    ; CloseWindow()

   ;------ close intuition library
closeIntLib:
   move.l   (4).w,a6    ; SysBase
   move.l   d6,a1       ; library
   jsr   -$19e(a6)      ; CloseLibrary()

   ;------ close timer device
closeTimerDev:
   lea.l Time_Req(pc),a1   ; ioRequest
   jsr   -$1c2(a6)      ; CloseDevice()

freeSignal:
   ;------ free the signal for the replyport
   moveq.l #0,d0        ; signalNum
   move.b   (Timer_Port+15)(pc),d0  ; Timer_Port.mp_SigBit
   jsr   -$150(a6)      ; FreeSignal()

noSignal:
   rts

   ;------  convert a value to ascii code
   ;------     d0 := value
   ;------     d1 := length
   ;------     d5 := fill character
   ;------     a0 := end of buffer to write in + 1
Write_Value_Loop:
   divu.w   #10,d0         ; write (d0 % 10 + '0')
   swap  d0       ; d0 /= 10
   add.b #'0',d0
   move.b   d0,-(a0)
   clr.w d0
   swap  d0
   beq.s Write_Spaces
Write_Value:
   dbf   d1,Write_Value_Loop
   rts
Write_Spaces_Loop:
   move.b   d5,-(a0)    ; write (fill-char)
Write_Spaces:
   dbf   d1,Write_Spaces_Loop
   rts

   ;------  table to calculate hours, mins and secs
Div_Table:
   dc.w  24,60,60

   ;------  a NewWindow type of structure
New_Window:
   dc.w  221,0,361-28,16
   dc.b  -1,-1
   dc.l  $200,$2000e,0,0,(New_Window_Title-CodeStart),0,0
   dc.w  0,0,0,0,1

   ;------  replyport for timer.device io
Timer_Port:
   dc.l  0,0
   dc.b  4,0
   dc.l  (TaskName-CodeStart)
   dc.b  0,0
   dc.l  0,(Timer_Port-CodeStart+24),0,(Timer_Port-CodeStart+20)
   dc.b  5,0

   ;------  timerequest structure for doing some io
Time_Req:
   dc.l  0,0
   dc.b  5,0
   dc.l  (TaskName-CodeStart),(Timer_Port-CodeStart)
   dc.w  20
   dc.l  0,0
   dc.w  0
   dc.b  0,0
   dc.l  0,0

   ;------  TextAttr structure for TOPAZ_EIGHTY
Date_Font:
   dc.l  (Date_Font_Name-CodeStart)
   dc.w  11
   dc.b  0,1

   ;------  IntuiText structure for printing the output
Date_Text:
   dc.b  1,0,1,0
   dc.w  0,0
   dc.l  (Date_Font-CodeStart),(Date_Buffer-CodeStart),0

   ;------  text to be printed
Date_Buffer:
   dc.b  ' Chip:$$$  Fast:$$$$  Time:$$:$$:$$ ',0

   ;------  table with which the Write_Value routine knows
   ;------  with which character it got to fill the value up
   ;------  to the passed number of digits when writing
   ;------  the hours, mins and secs
Fill_Table:
   dc.b  ' 00'
   
   ;------  names for opening different things
Date_Font_Name:
   dc.b  'topaz.font',0

Intuition_Name:
   dc.b  'intuition.library',0

Timer_Name:
   dc.b  'timer.device',0

New_Window_Title  equ   (*-1)

   ;------ the task's name
TaskName:
   dc.b  'mclk',0

   ;------ force word alignment
   ds.w  0

__CodeEnd:

   ;------  table to correct all direct address references
   ;------  in the task code when it was copied in another area
RelocTable:
   dc.w  (Date_Text-CodeStart+8),(Date_Text-CodeStart+12)
   dc.w  (Date_Font-CodeStart),(Timer_Port-CodeStart+10)
   dc.w  (Timer_Port-CodeStart+20),(Timer_Port-CodeStart+28)
   dc.w  (Time_Req-CodeStart+10),(Time_Req-CodeStart+14)
   dc.w  (New_Window-CodeStart+26),0

   end

