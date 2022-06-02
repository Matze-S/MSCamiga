# Copyright (C) 1990 by Matthias Schmidt

CFLAGS=-ms0cdem -ps0ct -sbo -wadepru
AFLAGS=
LIB=c16

#
# makefile to build the HardDisk (Utilities) v1.53 (03:31 11-Aug-90)
#

all:    HDFormat HDPart HDProtect SetConfig WF AB HD

LIBOBJS=ask.lo atol.lo rdrng.lo rdtxt.lo rdval.lo stricmp.lo

.c.lo:
        cc $(CFLAGS) -mb0 -hi defs.pre -o $@ $*.c

defs.pre: defs.h HardDisk.h
        cc $(CFLAGS) -ho defs.pre defs.h

$(LIBOBJS): defs.pre

hd.lib: $(LIBOBJS)
        ls >hd.inp $(LIBOBJS)
        ord hd.inp hd.out
        lb hd.lib -f hd.out

.c.o:
        cc $(CFLAGS) -hi defs.pre $*.c

HDFormat.o HDPart.o HDProtect.o SetConfig.o WF.o: defs.pre

HDFormat: HDFormat.o vertrks.o abort.lo hd.lib
        ln HDFormat.o vertrks.o abort.lo -lhd -l$(LIB)

vertrks.o: vertrks.asm
        as $(AFLAGS) vertrks.asm

HDPart: HDPart.o abort.lo hd.lib
        ln HDPart.o abort.lo -lhd -l$(LIB)

HDProtect: HDProtect.o abort.lo hd.lib
        ln HDProtect.o abort.lo -lhd -l$(LIB)

SetConfig: SetConfig.o abort.lo hd.lib
        ln SetConfig.o abort.lo -lhd -l$(LIB)

HardDisk.o: HardDisk.asm HardDisk.i
        genim2 HardDisk.asm -oHardDisk.o -lidevpac:include.new/

HDDevice.o: HDDevice.asm
        genim2 HDDevice.asm -oHDDevice.o -lidevpac:include.new/

AutoBoot.o: AutoBoot.asm
        genim2 AutoBoot.asm -oAutoBoot.o -lidevpac:include.new/

HD:     HDDevice.o HardDisk.o
        blink from HDDevice.o+HardDisk.o TO HD nd chip verbose faster
AB:     AutoBoot.o HardDisk.o
        blink from AutoBoot.o+HardDisk.o TO AB sc sd nd chip verbose faster

WF:     WF.o abort.lo
        ln WF.o abort.lo -l$(LIB)

cleanup:
        delete #?.(o|lo|lib|inp|out|pre)

test:   defs.pre test.o abort.lo
        ln test.o abort.lo -l$(LIB)

