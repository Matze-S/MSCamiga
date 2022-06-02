
#include <graphics/gfx.h>
#include <graphics/gfxbase.h>
#include <graphics/rastport.h>
#include <graphics/view.h>

IMPORT struct Library *OpenLibrary();
IMPORT struct ColorMap *GetColorMap();
IMPORT PLANEPTR AllocRaster();
IMPORT VOID CloseLibrary(),InitView(),InitVPort(),InitBitMap();
IMPORT VOID InitRastPort(),FreeRaster(),FreeColorMap();
IMPORT VOID FregVPortCopLists(),FreeCprList(),WaitBOVP(),LoadRGB4();

STATIC struct cprlist *Old_LOFCprList,*Old_SHFCprList;
STATIC struct View v,*Old_View;
STATIC struct ViewPort vp;
STATIC struct RasInfo ri;
STATIC struct BitMap bm[2];
STATIC struct RastPort rp;

struct GfxBase *GfxBase;

#define LMB_UP (*(char *)0xbfe001 & 0x40)

#define WIDTH 320L
#define HEIGHT 256L
#define DEPTH 2L
#define MODES 0L

USHORT ColorTable[2<<DEPTH] = {
   0x000,0xf00,0x0f0,0x00f
};

STATIC VOID Switch()
{
   REGISTER struct cprlist *TEMP;

   WaitBOVP(&vp);
   LoadView(&v);
   TEMP = v.LOFCprList;
   v.LOFCprList = Old_LOFCprList;
   Old_LOFCprList = TEMP;
   TEMP = v.SHFCprList;
   v.SHFCprList = Old_SHFCprList;
   Old_SHFCprList = TEMP;
   rp.BitMap = ri.BitMap = &bm[(ri.BitMap == &bm[0]) ? 1:0];
}

VOID main()
{
   REGISTER COUNT cnt;

   GfxBase = (struct GfxBase *)OpenLibrary("graphics.library",NULL);
   Old_View = GfxBase->ActiView;
   Old_LOFCprList = Old_SHFCprList = NULL;
   InitView(&v);
   InitVPort(v.ViewPort = &vp);
   if ((vp.ColorMap = GetColorMap(1L<<DEPTH)) == NULL) goto CloseGfx;
   vp.DWidth = WIDTH;
   vp.DHeight = HEIGHT;
   vp.RasInfo = &ri;
   ri.RxOffset = ri.RyOffset = 0;
   ri.Next = ri.BitMap = NULL;
   InitRastPort(&rp);
   InitBitMap(&bm[0],DEPTH,WIDTH,HEIGHT);
   InitBitMap(&bm[1],DEPTH,WIDTH,HEIGHT);
   LoadRGB4(&vp,ColorTable,1L<<DEPTH);
   for (cnt = 0; cnt<DEPTH; cnt++) {
      if ((bm[0].Planes[cnt] = AllocRaster(WIDTH,HEIGHT)) == NULL ||
         (bm[1].Planes[cnt] = AllocRaster(WIDTH,HEIGHT)) == NULL)
         goto FreePlanes;
   }
   rp.BitMap = ri.BitMap = &bm[0];
   MakeVPort(&v,&vp);
   MrgCop(&v);
   SetRast(&rp,0L);
   Old_LOFCprList = v.LOFCprList;
   Old_SHFCprList = v.SHFCprList;
   v.LOFCprList = v.SHFCprList = NULL;
   rp.BitMap = ri.BitMap = &bm[1];
   MakeVPort(&v,&vp);
   MrgCop(&v);
   SetRast(&rp,0L);
   {
      register long c = 1;
      struct { SHORT x,y; } rec[4];

      rec[0].x = 200; rec[0].y = 120;
      rec[1].x = 200; rec[1].y = 150;
      rec[2].x = 120; rec[2].y = 150;
      rec[3].x = 120; rec[3].y = 120;

      SetDrMd(&rp,JAM1);
do {
      for (cnt = 500; cnt && LMB_UP; --cnt) {
         Switch();
         SetAPen(&rp,c);
         rec[0].x--; rec[0].y++;
         rec[1].x--; rec[1].y--;
         rec[2].x++; rec[2].y--;
         rec[3].x++; rec[3].y++;
         SetRast(&rp,0L);
         Move(&rp,(long)rec[3].x,(long)rec[3].y);
         PolyDraw(&rp,4L,rec);
         c==3 ? c=1:c++;
      }
      for (cnt = 50; cnt && LMB_UP; --cnt) {
         Switch();
         SetAPen(&rp,c);
         rec[0].x++; rec[0].y--;
         rec[1].x++; rec[1].y++;
         rec[2].x--; rec[2].y++;
         rec[3].x--; rec[3].y--;
         SetRast(&rp,0L);
         Move(&rp,(long)rec[3].x,(long)rec[3].y);
         PolyDraw(&rp,4L,rec);
         c==3 ? c=1:c++;
      }
} while (LMB_UP);
   }
   while (LMB_UP);
FreePlanes:
   for (cnt = 0; cnt<DEPTH; cnt++) {
      if (bm[0].Planes[cnt]) FreeRaster(bm[0].Planes[cnt],WIDTH,HEIGHT);
      if (bm[1].Planes[cnt]) FreeRaster(bm[1].Planes[cnt],WIDTH,HEIGHT);
   }
   FreeColorMap(vp.ColorMap);
   FreeVPortCopLists(&vp);
   FreeCprList(v.LOFCprList);
   FreeCprList(v.SHFCprList);
   FreeCprList(Old_LOFCprList);
   FreeCprList(Old_SHFCprList);
CloseGfx:
   LoadView(Old_View);
   CloseLibrary(GfxBase);
}

