
*
* Reset.asm
*
* Written at 27-Nov-88 and Copyright © in 1988 by Matthias Schmidt
* System-Reset (Reboot)...
*

_SysBase       equ $4
_LVOSuperState equ -$96

Reset          move.l _SysBase,a6
               jsr _LVOSuperState(a6)
               reset
               move.l $fc0004,a0
               jmp (a0)

