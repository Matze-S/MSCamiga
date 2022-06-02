# Retro Amiga Misc

Works that were created during the school days

* an OMTI 5520/5527 hard disk controller driver

  - Hardware must be based on the famous OMTI adapter published in Amiga Magazine in 1989: http://amiga.resource.cx/expde/omtiadapter
  - also works with some WD controllers, but they were very slow
  - supports various handshake modes, including the high-performance "A.L.F." mode, selectable
  - supports write protection for the entire drive or just the partition table
  - supports soft reboot with persistent FFS, and some other features that were uncommon in competing products but I can't remember right now
  
* a file packer "pack" similar to tar (without compression)

  - written in assembler, based as far as possible and reasonable on the undocumented AmigaDOS, BCPL functions
  - accordingly also supports wildcard matching/usage/etc. as the standard AmigaDOS commands
  - quite compact size due to internal AmigaDOS function usage
  - some sources could be found on the subject of BCPL and/or interfaces to C/ASM
  - the undocumented functions and their usage were reverse engineered in the debugger

* One or two of the tools have been published in Amiga magazines, 2-3 commissioned works are included, the rest have never been published or distributed

* The .asm/.s/.c sources should compile with the MANX Aztec C 3.6/5.0 assembler/compiler

* The .asm/.s source(s) should also be able to be assembled with the Kick-AS from the Kickstart magazine

* It is not known whether the sources work with Lattice-C or Gnu-ASM/C - others like the above were not available to me at the time

* only intended for browsing and/or use by yourself

* Function/compile was not checked, unfortunately I currently have no access to my A3000 (too small apartment)
