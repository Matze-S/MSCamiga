struct View View ;
struct ViewPort ViewPort ;
struct RasInfo RasInfo ;
struct ColorMap *ColorMap ;
struct BitMap BitMap ;
struct RastPort RastPort ;

SHORT i, j, Length ;

struct GfxBase *GfxBase ;
struct View *OldView ;

USHORT ColorTable[] = {0x000,0xf00,0x00f,0x0f0} ;

main()
{
   if (!(GfxBase = (struct GfxBase *)
      OpenLibrary("graphics.library",0L)))
      Exit(FALSE) ;

   OldView = GfxBase->ActiView ;

   InitView(&View) ;
   InitVPort(&ViewPort) ;
   View.ViewPort = &ViewPort ;

   InitBitMap(&BitMap,2L,320L,200L) ;

   InitRastPort(&RastPort) ;
   RastPort.BitMap = &BitMap ;

   RasInfo.BitMap = &BitMap ;
   RasInfo.RxOffset = 0 ;
   RasInfo.RyOffset = 0 ;
   RasInfo.Next = NULL ;

   ViewPort.RasInfo = &RasInfo ;
   ViewPort.DWidth = 320 ;
   ViewPort.DHeight = 200 ;
   ViewPort.ColorMap = (struct ColorMap *)GetColorMap(4L) ;

   LoadRGB4(&ViewPort,&ColorTable[0],4L) ;

   for (i=0;i<2;i++)
      {
         if ((BitMap.Planes[i] = (PLANEPTR)
               AllocRaster(320L,200L)) == NULL)
               Exit(-1000) ;

         BltClear((UBYTE *)BitMap.Planes[i],RASSIZE(320,200L),0L) ;
      }

   MakeVPort(&View,&ViewPort) ;
   MrgCop(&View) ;

   LoadView(&View) ;

   SetDrMd(&RastPort,JAM1) ;
   SetAPen(&RastPort,3) ;

   for (i=0;i<320;i+=10)
      {
         Move(&RastPort,160L,200L) ;
         Draw(&RastPort,i,0L) ;
      }

   for(i=0;i<1000;i++)
      {
         for(j=0;j<1000;j++) ;
      }
   LoadView(OldView) ;

   for(i=0;i<2;i++)
      FreeRaster(BitMap.Planes[i],320L,200L) ;

   FreeColorMap(ViewPort.ColorMap) ;
   FreeVPortCopLists(&ViewPort) ;

   FreeCprList(View.LOFCprList) ;
   FreeCprList(View.SHFCprList) ;

   CloseLibrary(GfxBase) ;
}
