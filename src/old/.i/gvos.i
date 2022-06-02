; Copyright (C) 1989 by Matthias Schmidt

_GVObstrtocstr		EQU	-$80		; -?-
_GVOcstrtobstr		EQU	-$7c		; -?-
_GVOExecute		EQU	-$6c
_GVOIsInteractive	EQU	-$68
_GVODateStamp		EQU	-$64
_GVOSetProtection	EQU	-$60
_GVOSetComment		EQU	-$5c
_GVODeviceProc		EQU	-$58
_GVOQueuePacket 	EQU	-$54
_GVOGetPacket		EQU	-$50
_GVOLoadSeg		EQU	-$4c
_GVOCreateProc		EQU	-$48
_GVOIoErr		EQU	-$44
_GVOCurrentDir		EQU	-$40
_GVOCreateDir		EQU	-$3c
_GVOInfo		EQU	-$38
_GVOExNext		EQU	-$34
_GVOExamine		EQU	-$30
_GVOLock		EQU	-$2c
_GVORename		EQU	-$28
_GVODeleteFile		EQU	-$24
_GVOSeek		EQU	-$20
_GVOWrite		EQU	-$18
_GVORead		EQU	-$c
_GVOOpen		EQU	-$4

_GVOstop		EQU	$8
_GVOresult2		EQU	$28
_GVOtaskid		EQU	$38
_GVOalloc		EQU	$4c		; -?-
_GVOallocpublic 	EQU	$74		; -?-
_GVOfree		EQU	$78		; -?-
_GVOparentdir		EQU	$8c		; -?-
_GVOtaskheld		EQU	$98		; -?-
_GVOroot		EQU	$9c		; -?-
_GVOtaskwait		EQU	$a4
_GVOsendpacket		EQU	$a8		; -?-
_GVOdelay		EQU	$bc		; -?-
_GVOrequest		EQU	$d0		; -?-
_GVOrdch		EQU	$d8
_GVOwrch		EQU	$e0
_GVOfindinput		EQU	$ec
_GVOfindoutput		EQU	$f0
_GVOselectinput 	EQU	$f4
_GVOselectoutput	EQU	$f8
_GVOendread		EQU	$fc
_GVOendwrite		EQU	$100
_GVOinput		EQU	$104
_GVOoutput		EQU	$108
_GVOwrites		EQU	$124
_GVOwritef		EQU	$128
_GVOtoupper		EQU	$12c		; -?-
_GVOchricmp		EQU	$130		; -?-
_GVOstricmp		EQU	$134		; -?-
_GVOrdargs		EQU	$138
_GVOloadseg		EQU	$144		; -?-
_GVOunloadseg		EQU	$148		; -?-
_GVOwaitforchar 	EQU	$15c		; -?-
_GVOdoexec		EQU	$160		; -?-
_GVOseglist		EQU	$164		; -?-
_GVOdeletefile		EQU	$168		; -?-
_GVOIntuitionBase	EQU	$170		; -?-
_GVOclose		EQU	$174		; -?-
_GVOtaskwait_ii 	EQU	$190		; -?-

