
/*
**  fr_structs.c
**
**  structures for the filerequester
*/

#include "filerequest.h"

extern struct TextAttr Topaz_80,ITopaz_80;

USHORT fr_UpImageData[] = {
   0x0180,0x03c0,0x07e0,0x0ff0,0x0180,0x0180,0x0180,0x0180
};
USHORT fr_DownImageData[] = {
   0x0180,0x0180,0x0180,0x0180,0x0ff0,0x07e0,0x03c0,0x0180
};
struct Image fr_G6_Image;
struct Image fr_G5_Image = {
   7,5-PG_HEIGHT-UDG_HEIGHT-12,16,8,1,fr_UpImageData,1,0,NULL
};
struct Image fr_G4_Image = {
   7,5,16,8,1,fr_DownImageData,1,0,&fr_G5_Image
};
UBYTE fr_Path[1100] = "";
UBYTE fr_File[108] = "";
UBYTE fr_EntryNames[EY][EX+1];
struct IntuiText fr_G7_ITexts[EY];
struct IntuiText fr_G3_IText = {
   C_TEXT,0,JAM1,-56,0,&Topaz_80,(STRPTR)"Path:",NULL
};
struct IntuiText fr_G2_IText = {
   C_TEXT,0,JAM1,-56,0,&Topaz_80,(STRPTR)"File:",NULL
};
struct IntuiText fr_G1_IText = {
   C_TEXT,0,JAM1,16,6,&Topaz_80,(STRPTR)"Cancel",NULL
};
struct IntuiText fr_G0_IText = {
   C_TEXT,0,JAM1,16,6,&Topaz_80,NULL,NULL
};
struct IntuiText fr_IText = {
   C_TEXT,0,JAM2,0,5,&Topaz_80,NULL,NULL
};
short fr_G7_XY[] = {
   1,FG_HEIGHT+5,1,1,0,FG_HEIGHT+5,0,0,FG_WIDTH+11,0,FG_WIDTH+11,FG_HEIGHT+5,
   FG_WIDTH+10,1,FG_WIDTH+10,FG_HEIGHT+5,2,FG_HEIGHT+5
};
short fr_G6_XY[] = {
   1,PG_HEIGHT+5,1,1,0,PG_HEIGHT+5,0,0,PG_WIDTH+11,0,PG_WIDTH+11,PG_HEIGHT+5,
   PG_WIDTH+10,1,PG_WIDTH+10,PG_HEIGHT+5,2,PG_HEIGHT+5
};
short fr_G4_XY[] = {
   1,UDG_HEIGHT-5,1,1,0,UDG_HEIGHT-5,0,0,UDG_WIDTH-9,0,UDG_WIDTH-9,
   UDG_HEIGHT-5,UDG_WIDTH-10,1,UDG_WIDTH-10,UDG_HEIGHT-5,2,UDG_HEIGHT-5
};
short fr_G2_XY[] = {
   1,SG_HEIGHT+4,1,1,0,SG_HEIGHT+4,0,0,SG_WIDTH+7,0,SG_WIDTH+7,SG_HEIGHT+4,
   SG_WIDTH+6,1,SG_WIDTH+6,SG_HEIGHT+4,2,SG_HEIGHT+4
};
short fr_G0_XY[] = {
   1,EG_HEIGHT-5,1,1,0,EG_HEIGHT-5,0,0,EG_WIDTH-9,0,EG_WIDTH-9,EG_HEIGHT-5,
   EG_WIDTH-10,1,EG_WIDTH-10,EG_HEIGHT-5,2,EG_HEIGHT-5
};
short fr_XY_0[] = {
   1,1,1,TITLEHEIGHT+3,0,TITLEHEIGHT+3,0,0,REQWIDTH-6,0,
   REQWIDTH-6,TITLEHEIGHT+3,0,TITLEHEIGHT+3,0,REQHEIGHT-3,
   1,TITLEHEIGHT+3,1,REQHEIGHT-3,REQWIDTH-6,REQHEIGHT-3,
   REQWIDTH-6,TITLEHEIGHT+3,REQWIDTH-5,REQHEIGHT-3,REQWIDTH-5,0
};
struct Border fr_G7_Border2 = {
   12,TITLEHEIGHT+11,C_FRONT,0,JAM1,9,fr_G7_XY,NULL
};
struct Border fr_G7_Border = {
   16,TITLEHEIGHT+9,C_BACK,0,JAM1,9,fr_G7_XY,&fr_G7_Border2
};
struct Border fr_G6_Border6 = {
   2,PG_TOPEDGE-(UG_TOPEDGE)-2,C_FRONT,0,JAM1,9,fr_G6_XY,NULL
};
struct Border fr_G6_Border5 = {
   6,PG_TOPEDGE-(UG_TOPEDGE)-4,C_BACK,0,JAM1,9,fr_G6_XY,&fr_G6_Border6
};
struct Border fr_G5_Border4 = {
   2,DG_TOPEDGE-(UG_TOPEDGE)+3,C_FRONT,0,JAM1,9,fr_G4_XY,&fr_G6_Border5
};
struct Border fr_G5_Border3 = {
   6,DG_TOPEDGE-(UG_TOPEDGE)+1,C_BACK,0,JAM1,9,fr_G4_XY,&fr_G5_Border4
};
struct Border fr_G4_Border2 = {
   2,3,C_FRONT,0,JAM1,9,fr_G4_XY,&fr_G5_Border3
};
struct Border fr_G4_Border = {
   6,1,C_BACK,0,JAM1,9,fr_G4_XY,&fr_G4_Border2
};
struct Border fr_G2_Border2 = {
   -8,-2,C_FRONT,0,JAM1,9,fr_G2_XY,NULL
};
struct Border fr_G2_Border = {
   -4,-4,C_BACK,0,JAM1,9,fr_G2_XY,&fr_G2_Border2
};
struct Border fr_G0_Border2 = {
   2,3,C_FRONT,0,JAM1,9,fr_G0_XY,NULL
};
struct Border fr_G0_Border = {
   6,1,C_BACK,0,JAM1,9,fr_G0_XY,&fr_G0_Border2
};
struct Border fr_Border_1 = {
   0,2,C_FRONT,0,JAM1,14,fr_XY_0,&fr_G7_Border
};
struct Border fr_Border = {
   4,0,C_BACK,0,JAM1,14,fr_XY_0,&fr_Border_1
};
struct PropInfo fr_G6_Info = {
   AUTOKNOB|FREEVERT|PROPBORDERLESS,0,0,0,MAXBODY,0,0,0,0,0,0
};
struct StringInfo fr_G3_Info = {
   fr_Path,NULL,0,sizeof(fr_Path),0
};
struct StringInfo fr_G2_Info = {
   fr_File,NULL,0,sizeof(fr_File),0
};
struct Gadget fr_Gadget_7 = {
   NULL,20,TITLEHEIGHT+13,FG_WIDTH,FG_HEIGHT,GADGHNONE,
   GADGIMMEDIATE,REQGADGET|BOOLGADGET,NULL,NULL,
   fr_G7_ITexts,0,NULL,GID_SELECT,NULL
};
struct Gadget fr_Gadget_6 = {
   &fr_Gadget_7,-19-PG_WIDTH,PG_TOPEDGE,PG_WIDTH,PG_HEIGHT,
   GADGHBOX|GRELRIGHT,GADGIMMEDIATE|RELVERIFY|FOLLOWMOUSE,REQGADGET|PROPGADGET,
   (APTR)&fr_G6_Image,NULL,NULL,0,(APTR)&fr_G6_Info,GID_PROP,NULL
};
struct Gadget fr_Gadget_5 = {
   &fr_Gadget_6,-9-UDG_WIDTH,DG_TOPEDGE,UDG_WIDTH,UDG_HEIGHT,GADGIMAGE|
   GADGHCOMP|GRELRIGHT,GADGIMMEDIATE|RELVERIFY,REQGADGET|BOOLGADGET,
   (APTR)&fr_G4_Image,NULL,NULL,0,NULL,GID_DOWN,NULL
};
struct Gadget fr_Gadget_4 = {
   &fr_Gadget_5,-9-UDG_WIDTH,UG_TOPEDGE,UDG_WIDTH,UDG_HEIGHT,
   GADGHCOMP|GRELRIGHT,GADGIMMEDIATE|RELVERIFY,REQGADGET|BOOLGADGET,
   (APTR)&fr_G4_Border,NULL,NULL,0,NULL,GID_UP,NULL
};
struct Gadget fr_Gadget_3 = {
   &fr_Gadget_4,-15-SG_WIDTH,-19-EG_HEIGHT-2*SG_HEIGHT,SG_WIDTH,SG_HEIGHT,
   GADGHCOMP|GRELBOTTOM|GRELRIGHT,RELVERIFY|GADGIMMEDIATE,REQGADGET|
   STRGADGET,(APTR)&fr_G2_Border,NULL,&fr_G3_IText,0,(APTR)&fr_G3_Info,
   GID_PATH,NULL
};
struct Gadget fr_Gadget_2 = {
   &fr_Gadget_3,-15-SG_WIDTH,-9-EG_HEIGHT-SG_HEIGHT,SG_WIDTH,SG_HEIGHT,
   GADGHCOMP|GRELBOTTOM|GRELRIGHT,RELVERIFY|GADGIMMEDIATE,REQGADGET|
   STRGADGET,(APTR)&fr_G2_Border,NULL,&fr_G2_IText,0,(APTR)&fr_G2_Info,
   GID_FILE,NULL
};
struct Gadget fr_Gadget_1 = {
   &fr_Gadget_2,-9-EG_WIDTH,-4-EG_HEIGHT,EG_WIDTH,EG_HEIGHT,GADGHCOMP|
   GRELBOTTOM|GRELRIGHT,RELVERIFY|GADGIMMEDIATE|ENDGADGET,REQGADGET|
   BOOLGADGET,(APTR)&fr_G0_Border,NULL,&fr_G1_IText,0,NULL,GID_CANCEL,NULL
};
struct Gadget fr_Gadget = {
   &fr_Gadget_1,10,-4-EG_HEIGHT,EG_WIDTH,EG_HEIGHT,GADGHCOMP|GRELBOTTOM,
   RELVERIFY|GADGIMMEDIATE|ENDGADGET,REQGADGET|BOOLGADGET,
   (APTR)&fr_G0_Border,NULL,&fr_G0_IText,0,NULL,GID_ENDGADGET,NULL
};
struct Requester fr_Requester = {
   NULL,10,4,REQWIDTH,REQHEIGHT,0,0,&fr_Gadget,
   &fr_Border,&fr_IText,0,C_GROUND
};
