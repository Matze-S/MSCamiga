/* Copyright (C) 1990 by Matthias Schmidt */


/*
 *  HardDisk.h
 *
 *  OMTI harddisk driver -- main include file -- v1.53 (23:27 06-Aug-90)
 */


#ifndef HARDDISK_H
#define HARDDISK_H

#ifndef EXEC_TYPES_H
#include "exec/types.h"
#endif /* EXEC_TYPES_H */

#ifndef EXEC_IO_H
#include "exec/io.h"
#endif /* EXEC_IO_H */

#ifndef EXEC_DEVICES_H
#include "exec/devices.h"
#endif /* EXEC_DEVICES_H */

#ifndef DEVICES_TIMER_H
#include "devices/timer.h"
#endif /* DEVICES_TIMER_H */

/*
 *--------------------------------------------------------------------
 *
 * Max # of units in this device
 *
 *--------------------------------------------------------------------
 */

#define HD_NUMUNITS 2

/*
 *--------------------------------------------------------------------
 *
 * Useful constants
 *
 *--------------------------------------------------------------------
 */

/*-- sizes before mfm/rll encoding */
#define HD_SECTOR 512
#define HD_SECSHIFT 9           /* log HD_SECTOR */
                                /*    2          */

#define HD_MFMNUMSEC 17         /* # of sectors with mfm encoding */
#define HD_RLLNUMSEC 26         /* # of sectors with rll encoding */

/*
 *--------------------------------------------------------------------
 *
 * Driver Specific Commands
 *
 *--------------------------------------------------------------------
 */

/*
 *-- HD_NAME is a generic macro to get the name of the driver.  This
 *-- way if the name is ever changed you will pick up the change
 *-- automatically.
 *--
 *-- Normal usage would be:
 *--
 *-- char internalName[] = HD_NAME;
 *--
 */

#define HD_NAME "harddisk.device"

/* trackdisk compatible commands */

#define HD_MOTOR        (CMD_NONSTD+0)  /* control the disk's motor */
#define HD_SEEK         (CMD_NONSTD+1)  /* explicit seek (for testing) */
#define HD_FORMAT       (CMD_NONSTD+2)  /* format disk */
#define HD_REMOVE       (CMD_NONSTD+3)  /* notify when disk changes */
#define HD_CHANGENUM    (CMD_NONSTD+4)  /* number of disk changes */
#define HD_CHANGESTATE  (CMD_NONSTD+5)  /* is there a disk in the drive? */
#define HD_PROTSTATUS   (CMD_NONSTD+6)  /* is the disk write protected? */
#define HD_GETNUMTRACKS (CMD_NONSTD+10) /* get # of tracks on this disk */

/* special commands for the harddisk device */

#define HD_CHANGEPROT   (CMD_NONSTD+13) /* change the disk protection */
#define HD_PARK         (CMD_NONSTD+14) /* park the heads of the drive */
#define HD_SETDRIVEPARMS (CMD_NONSTD+15) /* set new drive parameters */
#define HD_READPARTS    (CMD_NONSTD+16) /* read the partition structures */
#define HD_BUSY         (CMD_NONSTD+17) /* allocate the omti for own use */
#define HD_SENDCMD      (CMD_NONSTD+18) /* send omti command */
#define HD_SENDDATA     (CMD_NONSTD+19) /* send data to the omti */
#define HD_GETDATA      (CMD_NONSTD+20) /* receive data from the omti */
#define HD_GETSENSE     (CMD_NONSTD+21) /* get sense datas */
#define HD_LASTCOMM     (CMD_NONSTD+22)

/*
**  This is a bit in the FLAGS field of OpenDevice(). If it is set, then
**  the driver will ignore a possible error at omti hardware functions
**  at initializing (opening) a unit.
*/

#define HDB_IGNORE_OPEN_ERRORS  1
#define HDF_IGNORE_OPEN_ERRORS  (1<<1)

/*
**  If you want to use the special harddisk device commands, you should
**  set the following bit in the FLAGS field of OpenDevice().
*/

#define HDB_ALLOW_EXT_CMDS  2
#define HDF_ALLOW_EXT_CMDS  (1<<2)

/*
/*
 *--------------------------------------------------------------------
 *
 * Driver error defines
 *
 *--------------------------------------------------------------------
 */

/* usable trackdisk like error codes */
#define HDERR_WriteProt         28      /* can't write to a protected disk */
#define HDERR_NoMem             31      /* ran out of memory */
#define HDERR_BadUnitNum        32      /* asked for a unit > HD_NUMUNITS */

/* special harddisk device error codes */
#define HDERR_NoDriveParms      40      /* can't read drive parameters */
#define HDERR_NoTrackBuffer     41      /* there's no track buffer */
#define HDERR_NoTimerDevice     42      /* unable to open the timer.device */

/*
 *--------------------------------------------------------------------
 *
 * Omti Command structure
 *
 *--------------------------------------------------------------------
 */

struct HardDiskCmd {
    UBYTE   hdc_Command;                /* command to be done */
    UBYTE   hdc_Head;                   /* head # */
    UBYTE   hdc_Sector;                 /* sector # */
    UBYTE   hdc_Cylinder;               /* cylinder # */
    UBYTE   hdc_Count;                  /* counter */
    UBYTE   hdc_Control;                /* control byte */
};

#define HDCTRLB_SECADDRCONV    4        /* sector address conversion on */
#define HDCTRLB_FORMATBUFFER   5        /* format buffer on */
#define HDCTRLB_ECC            6        /* extended cylinder correction off*/
#define HDCTRLB_RETRY_VERIFY   7        /* retry verify off */
#define HDCTRLF_SECADDRCONV    (1<<4)
#define HDCTRLF_FORMATBUFFER   (1<<5)
#define HDCTRLF_ECC            (1<<6)
#define HDCTRLF_RETRY_VERIFY   (1<<7)

#define HDCMD_RECALIBRATE     1         /* recalibrate the drive */
#define HDCMD_SENSE           3         /* get sense bytes */
#define HDCMD_FORMAT_DRIVE    4         /* format the drive */
#define HDCMD_CHECK_TRACK     5         /* check track */
#define HDCMD_FORMAT_TRACK    6         /* format track */
#define HDCMD_FORMAT_BAD_TRK  7         /* format bad track */
#define HDCMD_READ            8         /* read sector(s) */
#define HDCMD_WRITE           10        /* write sector(s) */
#define HDCMD_SEEK            11        /* seek */
#define HDCMD_SET_DRIVE_CHARS 12        /* set drive characteristics */
#define HDCMD_ASSIGN_ALT_TRK  17        /* assign alternate track */
#define HDCMD_DIAG            228       /* omti diagnostics */

/*
 *--------------------------------------------------------------------
 *
 * Omti drive characteristics
 *
 *--------------------------------------------------------------------
 */

struct HardDiskDriveChars {
    UWORD   hddc_NumCyls;               /* # of cylinders */
    UBYTE   hddc_NumHeads;              /* # of heads */
    UBYTE   hddc_RedWrtCurrent_hi;     /* reduced write current - high byte */
    UBYTE   hddc_RedWrtCurrent_lo;     /*         - '' -        -  low byte */
    UBYTE   hddc_WritePrecomp_hi;      /* write precompensation - high byte */
    UBYTE   hddc_WritePrecomp_lo;      /*         - '' -        -  low byte */
    UBYTE   hddc_NullByte;              /* byte which should be zero */
};

/*
 *--------------------------------------------------------------------
 *
 * Omti hardware registers
 *
 *--------------------------------------------------------------------
 */

/* the base address of the omti controller should be fetched out of the
 * HardDiskUnit structure ! */
#define OMTI_BASE ((struct Omti *)0x8f0641) /* omti's base address */

struct Omti {
    UBYTE   omti_Data;                  /* data register */
    UBYTE   pad_0;
    UBYTE   omti_Status;                /* reset & status register */
#define omti_Reset omti_Status
    UBYTE   pad_1;
    UBYTE   omti_Select;                /* config & select register */
#define omti_Config omti_Select
    UBYTE   pad_2;
    UBYTE   omti_Mask;                  /* mask register */
};

#define OMTIB_REQ   0                   /* controller is ready */
#define OMTIB_IO    1
#define OMTIB_CD    2                   /* data can be send or received */
#define OMTIB_BSY   3                   /* controller is busy */
#define OMTIB_DREQ  4
#define OMTIB_IREQ  5
#define OMTIF_REQ   (1<<0)
#define OMTIF_IO    (1<<1)
#define OMTIF_CD    (1<<2)
#define OMTIF_BSY   (1<<3)
#define OMTIF_DREQ  (1<<4)
#define OMTIF_IREQ  (1<<5)

/*
 *--------------------------------------------------------------------
 *
 * Partition structure
 *
 *--------------------------------------------------------------------
 */

struct HardDiskPart {
    USHORT   hdp_LowCyl;                /* partition starting cylinder */
    USHORT   hdp_HighCyl;               /* partition ending cylinder */
    USHORT   hdp_Buffers;               /* # of AmigaDOS buffers */
    BYTE     hdp_BootPri;               /* boot priority */
    UBYTE    hdp_Flags;                 /* see below */
    BYTE     hdp_Name[4];               /* AmigaDOS name of the partition */
};

#define HDPB_USE_FFS        0           /* use the FFS for this partition */
#define HDPB_NO_AUTOMOUNT   1           /* don't mount this partition */
#define HDPF_USE_FFS        (1<<0)
#define HDPF_NO_AUTOMOUNT   (1<<1)

/*
 *--------------------------------------------------------------------
 *
 * Drive Parameter structure
 *
 *--------------------------------------------------------------------
 */

struct HardDiskDriveParm {
    ULONG   hddp_DOSID;                 /* id for using sector 0 with dos */
    UWORD   hddp_CheckSum;
    UWORD   hddp_NumCyls;               /* # of cylinders */
    UWORD   hddp_RedWriteCurrent;       /* reduced write current cyl */
    UWORD   hddp_WritePrecomp;          /* write precompensation cyl */
    UWORD   hddp_ParkCyl;               /* park cylinder */
    UBYTE   hddp_NumHeads;              /* # of heads */
    UBYTE   hddp_NumSecs;               /* # of sectors per track */
    UBYTE   hddp_StepRate;              /* coded step rate */
    UBYTE   hddp_Flags;                 /* flags -- see below ! */
    UWORD   hddp_LastCyl;               /* # of the last useable cylinder */
    UWORD   hddp_NumParts;              /* # of defined partition structs */
};

#define HDDP_DOSID (('N' << 24) | ('D' << 16) | ('O' << 8) | 'S')
#define HDDP_CHECKSUM 0x4321
#define HDDP_MAXNUMPARTS 8              /* max # of partition structures */

#define HDDPB_WRITEPROTECTED      0     /* the disk is write protected */
#define HDDPB_FORMATPROTECTED     1     /* the disk is format protected */
#define HDDPB_NOTWRITTEN          2     /* the driveparms aren't written */
#define HDDPB_WRITEHALF           3     /* write 16 bytes without handshk. */
#define HDDPB_WRITEBLIND          4     /* reserved */
#define HDDPB_READHALF            5     /* read 16 bytes without handshake */
#define HDDPB_READBLIND           6     /* read 512 bytes without handshk. */
#define HDDPB_WRITEPARTS          7     /* write the partition structs */
#define HDDPF_WRITEPROTECTED      (1<<0)
#define HDDPF_FORMATPROTECTED     (1<<1)
#define HDDPF_NOTWRITTEN          (1<<2)
#define HDDPF_WRITEHALF           (1<<3)
#define HDDPF_WRITEBLIND          (1<<4)
#define HDDPF_READHALF            (1<<5)
#define HDDPF_READBLIND           (1<<6)
#define HDDPF_WRITEPARTS          (1<<7)

/*
 *--------------------------------------------------------------------
 *
 * Unit structure
 *
 *--------------------------------------------------------------------
 */

struct HardDiskUnit {
    struct  Unit        hdu_Unit;       /* normal unit structure */
    UBYTE   hdu_UnitNum;                /* # of this unit */
    UBYTE   hdu_LUN;                    /* LUN (logical unit number) */
    struct  Task        *hdu_Task;      /* pointer to the unit task */
    struct  HardDiskDevice *hdu_Device; /* pointer to the device */
    struct  Omti        *hdu_OmtiBase;  /* pointer to the omti */
    UWORD   hdu_Cylinder;               /* actual cylinder # */
    UBYTE   hdu_Head;                   /* actual head # */
    UBYTE   hdu_Sector;                 /* actual sector # */
    struct  HardDiskCmd hdu_OmtiCmd;    /* omti's command structure */
    UBYTE   hdu_OmtiSense[4];           /* sense datas */
    struct  HardDiskDriveParm hdu_DriveParms; /* drive parameters */
    struct  IOStdReq    *hdu_IORequest; /* saved pointer to the iob */
    ULONG   hdu_OldSectorOffset;        /* offset of the last read sector */
    APTR    hdu_TrackBuffer;            /* pointer to the track buffer */
    ULONG   hdu_TrackBufferSize;        /* size of the track buffer */
    UWORD   hdu_BufferCylNum;           /* cyl # of the track in the buffer */
    UBYTE   hdu_BufferHeadNum;          /* head # of the trk in the buffer */
    UBYTE   hdu_pad;
    VOID    (*hdu_GetSector)();         /* ptr to the Get_Sector() routine */
    ULONG   hdu_GetSectorSize;          /* size of it, if it is created */
    APTR    hdu_Parts;                  /* possible ptr to part structs */
    struct  timerequest hdu_TimerReq;   /* timerequest for auto park, etc */
    struct  MsgPort     hdu_TimerPort;  /* replyport for timerequest */
};

#define HDUB_STOPPED            2       /* this unit is stopped */
#define HDUB_DRIVECHARSSET      3       /* drive chars of the unit are set */
#define HDUF_STOPPED            (1<<2)
#define HDUF_DRIVECHARSSET      (1<<3)

/*
 *--------------------------------------------------------------------
 *
 * HardDisk device structure
 *
 *--------------------------------------------------------------------
 */

struct HardDiskDevice {
    struct  Device      hd_Device;      /* normal device structure */
    UWORD   hd_pad;                     /* ... for longword alignment */
    struct  HardDiskUnit *hd_Units[HD_NUMUNITS]; /* pointer to the units */
    struct  ExecBase    *hd_SysBase;    /* SysBase */
    struct  Omti        *hd_OmtiBase;   /* omti's base address */
};

#define HDB_BUSY    7                   /* the device is in use */
#define HDF_BUSY    (1<<7)

#endif /* HARDDISK_H */

/*------------ end of source ------------*/

