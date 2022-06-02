; Copyright (C) 1990 by Matthias Schmidt


;
; HardDisk.i
;
; OMTI harddisk driver -- main include file -- v1.53 (23:26 06-Aug-90)
;


	IFND	DEVICES_HARDDISK_I
DEVICES_HARDDISK_I	SET	1

	IFND	EXEC_TYPES_I
	INCLUDE	"exec/types.i"
	ENDC	!EXEC_TYPES_I

	IFND	EXEC_IO_I
	INCLUDE "exec/io.i"
	ENDC	!EXEC_IO_I

	IFND	EXEC_DEVICES_I
	INCLUDE "exec/devices.i"
	ENDC	!EXEC_DEVICES_I

	IFND	DEVICES_TIMER_I
	INCLUDE	"devices/timer.i"
	ENDC	!DEVICES_TIMER_I


*--------------------------------------------------------------------
*
* Max # of units in this device
*
*--------------------------------------------------------------------


HD_NUMUNITS	EQU	2


*--------------------------------------------------------------------
*
* Useful constants
*
*--------------------------------------------------------------------


*-- sizes before mfm/rll encoding
HD_SECTOR	EQU	512
HD_SECSHIFT	EQU	9			; log HD_SECTOR
*						;    2

HD_MFMNUMSEC	EQU	17			; # of sectors with mfm
HD_RLLNUMSEC	EQU	26			; # of sectors with rll


*--------------------------------------------------------------------
*
* Driver Specific Commands
*
*--------------------------------------------------------------------

*-- HD_NAME is a generic macro to get the name of the driver.  This
*-- way if the name is ever changed you will pick up the change
*-- automatically.
*--
*-- Normal usage would be:
*--
*-- internalName:	HD_NAME
*--

HD_NAME:	MACRO
		DC.B	'harddisk.device',0
		DS.W	0
		ENDM

*--
*-- the extended command flag of the trackdisk device is ignored
*--

	DEVINIT

; trackdisk compatible commands

	DEVCMD	HD_MOTOR		; control the disk's motor
	DEVCMD	HD_SEEK 		; explicit seek (for testing)
	DEVCMD	HD_FORMAT		; format disk
	DEVCMD	HD_REMOVE		; notify when disk changes
	DEVCMD	HD_CHANGENUM		; # of disk changes
	DEVCMD	HD_CHANGESTATE		; is there a disk in the drive?
	DEVCMD	HD_PROTSTATUS		; is the disk write protected?
	DEVCMD	HD_RAWREAD		; not implemented
	DEVCMD	HD_RAWWRITE		; not implemented
	DEVCMD	HD_GETDRIVETYPE 	; not implemented
	DEVCMD	HD_GETNUMTRACKS 	; get # of tracks on this disk
	DEVCMD	HD_ADDCHANGEINT 	; not implemented
	DEVCMD	HD_REMCHANGEINT 	; not implemented

; the 'not implemented' - commands, standing above, are included to
; void crazy things, doing the harddisk device, if a program, which
; calls trackdisk commands, accesses the harddisk device.

; special commands for the harddisk device

	DEVCMD	HD_CHANGEPROT		; change the disk protection
	DEVCMD	HD_PARK 		; park the heads of the drive
	DEVCMD	HD_SETDRIVEPARMS	; set new drive parameters
	DEVCMD	HD_READPARTS		; read the partition structures
	DEVCMD	HD_BUSY			; allocate the controller for own use
	DEVCMD	HD_SENDCMD		; send omti command
	DEVCMD	HD_SENDDATA		; send data to omti
	DEVCMD	HD_GETDATA		; receive data from omti
	DEVCMD	HD_GETSENSE		; fetch sense datas
	DEVCMD	HD_LASTCOMM		; dummy placeholder for end of list


*
* This is a bit in the FLAGS field of OpenDevice.  If it is set, then
* the driver will ignore a possible error at Recalibrate(),
* GetDriveParms() or SendDriveChars().
*
*

	BITDEF	HD,IGNORE_OPEN_ERRORS,1


*--------------------------------------------------------------------
*
* Driver error defines
*
*--------------------------------------------------------------------

; usable trackdisk like error codes
HDERR_WriteProt 	EQU	28	; can't write to a protected disk
HDERR_NoMem		EQU	31	; ran out of memory
HDERR_BadUnitNum	EQU	32	; asked for a unit > HD_NUMUNITS

; special harddisk device error codes
HDERR_NoDriveParms	EQU	40	; can't read drive parameters
HDERR_NoTrackBuffer	EQU	41	; there's no track buffer
HDERR_NoTimerDevice	EQU	42	; unable to open the timer.device

*--------------------------------------------------------------------
*
* Omti command structure
*
*--------------------------------------------------------------------

 STRUCTURE HardDiskCmd,0
	UBYTE	hdc_Command		; command to be done
	UBYTE	hdc_Head 		; head #
	UBYTE	hdc_Sector		; sector #
	UBYTE	hdc_Cylinder		; cylinder #
	UBYTE	hdc_Count		; counter
	UBYTE	hdc_Control		; control byte
	LABEL	hdc_SIZEOF

	BITDEF	HDCTRL,SEC_ADDR_CONV,4	; sector address conversion on
	BITDEF	HDCTRL,FORMAT_BUFFER,5	; format buffer on
	BITDEF	HDCTRL,ECC,6		; extended cylinder correction off
	BITDEF	HDCTRL,RETRY_VERIFY,7	; retry verify off

HDCMD_RECALIBRATE	EQU	1		; recalibrate the drive
HDCMD_SENSE		EQU	3		; get sense bytes
HDCMD_FORMAT_DRIVE	EQU	4		; format the drive
HDCMD_CHECK_TRACK	EQU	5		; check track
HDCMD_FORMAT_TRACK	EQU	6		; format track
HDCMD_FORMAT_BAD_TRACK 	EQU	7		; format bad track
HDCMD_READ		EQU	8		; read sectors
HDCMD_WRITE		EQU	10		; write sectors
HDCMD_SEEK		EQU	11		; seek
HDCMD_SET_DRIVE_CHARS	EQU	12		; set drive characteristics
HDCMD_ASSIGN_ALT_TRACK 	EQU	17		; assign alternate track
HDCMD_DIAG		EQU	228		; omti diagnostics

*--------------------------------------------------------------------
*
* Omti drive characteristics
*
*--------------------------------------------------------------------

 STRUCTURE HardDiskDriveChars,0
	UWORD	hddc_NumCyls		; # of cylinders
	UBYTE	hddc_NumHeads		; # of heads
; attention -- the following two words are not on a word boundary !
	UWORD	hddc_RedWriteCurrent	; reduced write current
	UWORD	hddc_WritePrecomp	; write precompensation
	UBYTE	hddc_NullByte		; byte which must be zero
	LABEL	hddc_SIZEOF

*--------------------------------------------------------------------
*
* Omti hardware registers
*
*--------------------------------------------------------------------

OMTI_BASE	EQU	$8f0641		; omti controller's base address

OMTI_DATA	EQU	0		; data register
OMTI_STATUS	EQU	2		; reset & status register
OMTI_RESET	EQU	OMTI_STATUS
OMTI_SELECT	EQU	4		; config & select register
OMTI_CONFIG	EQU	OMTI_SELECT
OMTI_MASK	EQU	6		; mask register

	BITDEF	OMTI,REQ,0		; controller is ready
	BITDEF	OMTI,IO,1
	BITDEF	OMTI,CD,2		; data can be send or received
	BITDEF	OMTI,BSY,3		; controller is busy
	BITDEF	OMTI,DREQ,4
	BITDEF	OMTI,IREQ,5

*--------------------------------------------------------------------
*
* Partition structure
*
*--------------------------------------------------------------------

 STRUCTURE HardDiskPart,0
	USHORT	hdp_LowCyl		; partition starting cylinder
	USHORT	hdp_HighCyl		; partition ending cylinder
	USHORT	hdp_Buffers		; # of AmigaDOS buffers
	BYTE	hdp_BootPri		; boot priority
	UBYTE	hdp_Flags		; see below
	STRUCT	hdp_Name,4		; name of the partition
	LABEL	hdp_SIZEOF

	BITDEF	HDP,USE_FFS,0		; use the FFS for this partition
	BITDEF	HDP,NO_AUTOMOUNT,1	; don't mount this partition

*--------------------------------------------------------------------
*
* Drive Parameters structure
*
*--------------------------------------------------------------------

 STRUCTURE HardDiskDriveParms,0
	ULONG	hddp_DOSID		; id for using this sector with dos
	UWORD	hddp_CheckSum
	UWORD	hddp_NumCyls		; # of cylinders
	UWORD	hddp_RedWriteCurrent	; reduced write current starting cyl
	UWORD	hddp_WritePrecomp	; write precompensation starting cyl
	UWORD	hddp_ParkCyl		; park cylinder
	UBYTE	hddp_NumHeads		; # of heads
	UBYTE	hddp_NumSecs		; # of sectors per track
	UBYTE	hddp_StepRate		; coded steprate
	UBYTE	hddp_Flags		; flags -- see below !
	UWORD	hddp_LastCyl		; # of the last useable cylinder
	UWORD	hddp_NumParts		; # of defined partition structures
	LABEL	hddp_SIZEOF

HDDP_DOSID	EQU	'NDOS'
HDDP_CHECKSUM	EQU	$4321
HDDP_MAXNUMPARTS EQU	8		; max # of partition structures

	BITDEF	HDDP,WRITEPROTECTED,0	; the harddisk is write protected
	BITDEF	HDDP,FORMATPROTECTED,1	; the harddisk is format protected
	BITDEF	HDDP,NOTWRITTEN,2	; this driveparms are not written
	BITDEF	HDDP,WRITEHALF,3	; write 16 bytes without handshake
	BITDEF	HDDP,WRITEBLIND,4	; reserved
	BITDEF	HDDP,READHALF,5		; read 512 bytes without handshake
	BITDEF	HDDP,READBLIND,6	; read 16 bytes without handshake
	BITDEF	HDDP,WRITEPARTS,7	; write the partition structures

*--------------------------------------------------------------------
*
* Unit structure
*
*--------------------------------------------------------------------

 STRUCTURE HardDiskUnit,UNIT_SIZE
	UBYTE	hdu_UnitNum		; # of this unit
	UBYTE	hdu_LUN			; LUN (logical unit number)
	APTR	hdu_Task		; pointer to the unit's task
	APTR	hdu_Device		; pointer to the device
	APTR	hdu_OmtiBase		; pointer to the omti controller
	UWORD	hdu_Cylinder		; actual cylinder
	UBYTE	hdu_Head		; actual head
	UBYTE	hdu_Sector		; actual sector
	STRUCT	hdu_OmtiCmd,hdc_SIZEOF	; omti command structure
	STRUCT	hdu_OmtiSense,4 	; sense datas after an error
	STRUCT	hdu_DriveParms,hddp_SIZEOF ; drive parameters
	APTR	hdu_IORequest		; saved pointer to the iob
	ULONG	hdu_OldSectorOffset	; sector of the last read sector
	APTR	hdu_TrackBuffer		; pointer to the track buffer
	ULONG	hdu_TrackBufferSize	; size of the track buffer
	UWORD	hdu_BufferCylNum	; cyl # of the track in the buffer
	UBYTE	hdu_BufferHeadNum	; head # of the track in the buffer
	UBYTE	hdu_pad			; pad byte for word alignment
	APTR	hdu_GetSector		; ptr to the Get_Sector() - routine
	ULONG	hdu_GetSectorSize	; size of the Get_Sector() - routine
	APTR	hdu_Parts		; possible ptr to part structures
	STRUCT	hdu_TimerReq,IOTV_SIZE	; timerequest for auto park, etc
	STRUCT	hdu_TimerPort,MP_SIZE	; replyport for timerequest
	LABEL	hdu_SIZEOF

	BITDEF	HDU,STOPPED,2		; this unit is stopped
	BITDEF	HDU,DRIVECHARSSET,3	; drive chars of the unit are set

*--------------------------------------------------------------------
*
* HardDisk device structure
*
*--------------------------------------------------------------------

 STRUCTURE HardDisk,DD_SIZE
	UWORD	hd_pad			; pad word for longword alignment
	STRUCT	hd_Units,HD_NUMUNITS*4	; pointer to the units in this device
	APTR	hd_SysBase		; pointer to SysBase
	APTR	hd_OmtiBase		; omti controller's base address
	LABEL	hd_SIZEOF

	BITDEF	HD,BUSY,7		; the controller/the device is in use

*--------------------------------------------------------------------

	ENDC	DEVICES_HARDDISK_I

;------------ end of source ------------

