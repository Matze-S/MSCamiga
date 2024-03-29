
/*
#include <devices/printer.h>
#include <exec/io.h>
#include <exec/memory.h>
#include <graphics/gfxbase.h>
#include <graphics/rastport.h>
#include <graphics/text.h>
#include <graphics/view.h>
#include <intuition/intuition.h>
#include <intuition/intuitionbase.h>
#include <libraries/dos.h>
*/

#include <stdio.h>

#define WIDTH 800
#define HEIGHT 30
#define BUFFER_SIZE 80000
#define FONT_NAME "Times.font"
#define FONT_HEIGHT 24
#define TITEL_XS 3
#define TITEL_YS 7
#define KOMPONENTE_XS 3
#define KOMPONENTE_YS 5
#define GG_Y 38

/*#FOLD: Externe Deklarationen */

char *AllocMem();
long ReadPixel(),TextLength(),Wait();
struct ColorMap *GetColorMap();
struct IOStdReq *CreateStdIO();
struct Library *OpenLibrary();
struct Message *GetMsg(),*WaitPort();
struct MsgPort *CreatePort();
struct TextFont *OpenDiskFont();
struct Window *OpenWindow();

extern int (*cls_)();

/*#ENDFD*/

char produkt[31];
char komponente[] = "Komponente \x00";
char farbton[16];
char charge[8];
char mischung[21];
char enthaelt[4][51];
char gefahren[4][91];
char hinweise[4][91];
char inhalt[6];
char anzahl[6];
int groesse = 1;

long delay = 600;
int papier_laengen/* in 1/360 Zoll */[] = {
   960,2880,2879
};

char *pbp,*pbb = 0;
struct GfxBase *GfxBase = 0;
struct IntuitionBase *IntuitionBase = 0;
struct Library *DiskfontBase = 0;
struct TextFont *TextFont = 0;
struct Window *wnd = 0;
struct IOStdReq *iob = 0;
struct MsgPort *mpp = 0;
int open_flag = 0;

/*#FOLD: Drucker-Routinen */

struct RastPort rp;
struct BitMap bm;
struct RasInfo ri;
struct ViewPort vp;
struct View v,*old_view;
unsigned char plane[WIDTH / 8 * HEIGHT];
char inhalt_buffer[20000],*inhalt_pointer[12];
int inhalt_length[11];

/*#FOLD: init_gfx() */

init_gfx()
{
   old_view = GfxBase->ActiView;
   InitView(&v);
   InitVPort(v.ViewPort = &vp);
   if (!(vp.ColorMap = GetColorMap(2L))) {
      puts("Not enough memory !");
      exit(20);
   }
   v.Modes = vp.Modes = HIRES;
   vp.DWidth = WIDTH;
   vp.DHeight = HEIGHT;
   vp.RasInfo = &ri;
   ri.RxOffset = ri.RyOffset = 0;
   ri.Next = 0L;
   InitRastPort(&rp);
   InitBitMap(rp.BitMap = ri.BitMap = &bm,1L,(long)WIDTH,(long)HEIGHT);
   SetRGB4(&vp,0L,15L,15L,15L);
   SetRGB4(&vp,1L,0L,0L,0L);
   bm.Planes[0] = plane;
   MakeVPort(&v,&vp);
   MrgCop(&v);
   SetRast(&rp,0L);
   SetAPen(&rp,1L);
   SetDrMd(&rp,JAM1);
   SetFont(&rp,TextFont);
}

/*#ENDFD*/
/*#FOLD: gfx_print() */

gfx_print(s,xs,ys)
char *s;
{
   register int ca,cb,cc,cd;
   int w,hh = rp.TxHeight * ys,pc,sc,nc;
   char b[4];

   SetRast(&rp,0L);
   w = TextLength(&rp,s,(long)strlen(s));
   nc = (2124 - (pc = w * xs)) >> 1;
   nc -= (sc = nc / 36) * 36;
   pc += nc;
   nc *= 3;
   Move(&rp,0L,(long)rp.TxBaseline);
   Text(&rp,s,(long)strlen(s));
   *pbp++ = 27;   /* ESC '0' = LF 1/8 */
   *pbp++ = '0';
   *pbp++ = 27;   /* ESC 'P' = PICA */
   *pbp++ = 'P';
   *pbp++ = 27;   /* ESC 'w'�0 = Doppelthohe Zeichen aus */
   *pbp++ = 'w';
   *pbp++ = 0;

   for (ca = 0; ca < hh; ca += 24) {
      for (cb = sc; cb; --cb) {
         *pbp++ = 32;
      }
      pbp[0] = 27;
      pbp[1] = '*';
      pbp[2] = 39;
      pbp[3] = pc;
      pbp[4] = pc >> 8;
      pbp += 5;
      for (cb = nc; cb; --cb) {
         *pbp++ = 0;
      }
      for (cb = 0; cb < w; ++cb) {
         for (cc = 0; cc < 3; ++cc) {
            for (cd = 0; cd < 8; ++cd) {
               b[cc] = ReadPixel(&rp,(long)cb,(long)((ca + (cc << 3) + cd) /
                     ys)) | (b[cc] << 1);
            }
         }
         for (cc = xs; cc; --cc) {
            pbp[0] = b[0];
            pbp[1] = b[1];
            pbp[2] = b[2];
            pbp += 3;
         }
      }
      *pbp++ = '\n';
   }
}

/*#ENDFD*/
/*#FOLD: create_inhalt() */

create_inhalt(s)
char *s;
{
   register char *ihb,b[4];
   register int i,j,k,l,w,nc;

   inhalt_pointer[0] = ihb = inhalt_buffer;

   switch (groesse) {

      /*#FOLD: Gr��e 3 = Gro� */

      case 3:
         SetRast(&rp,0L);
         Move(&rp,0L,(long)rp.TxBaseline);
         Text(&rp,s,(long)strlen(s));
         nc = ((60 - (w = TextLength(&rp,s,(long)strlen(s)))) * 3 + 33) * 3;

         /* 1. Zeile */
         /* oberes +-----+ */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 104;
         *ihb++ = 1;
         for (i = 0; i < 6 * 3; ++i) *ihb++ = 0;
         for (i = 0; i < 6; ++i) {
            ihb[0] = 0;
            ihb[1] = 127;
            ihb[2] = 255;
            ihb += 3;
         }
         for (i = 336 /* (3 * 60 + 4 * 2 * 18 + 2 * 6) */; i; --i) {
            ihb[0] = 0;
            ihb[1] = 126;
            ihb[2] = 0;
            ihb += 3;
         }
         for (i = 0; i < 6; ++i) {
            ihb[0] = 0;
            ihb[1] = 127;
            ihb[2] = 255;
            ihb += 3;
         }
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 2. Zeile */
         inhalt_pointer[1] = ihb;

         /* |     | */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 104;
         *ihb++ = 1;
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 255;
         for (i = 336 * 3; i; --i) *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 255;
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 3. Zeile */
         inhalt_pointer[2] = ihb;

         /* |     | */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 104;
         *ihb++ = 1;
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 255;
         for (i = 336 * 3; i; --i) *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 255;
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 4. Zeile */
         inhalt_pointer[3] = ihb;

         /* | Inhalt: | */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 75;
         *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 255;
         for (i = 63 * 3; i; --i) *ihb++ = 0;
         *ihb++ = 'I';
         *ihb++ = 'n';
         *ihb++ = 'h';
         *ihb++ = 'a';
         *ihb++ = 'l';
         *ihb++ = 't';
         *ihb++ = ':';
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 75;
         *ihb++ = 0;
         for (i = 63 * 3; i; --i) *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 255;
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 5. Zeile */
         inhalt_pointer[4] = ihb;

         /* |     | */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 104;
         *ihb++ = 1;
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 255;
         for (i = 336 * 3; i; --i) *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 255;
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 6. - 9. Zeile */

         /* | xxxxx kg | */
         for (j = 0; j < 4; ++j) {
            inhalt_pointer[5 + j] = ihb;
            *ihb++ = 27;
            *ihb++ = '*';
            *ihb++ = 39;
            if (j != 3) {
               *ihb++ = 104;
               *ihb++ = 1;
            } else {
               *ihb++ = 225;
               *ihb++ = 0;
            }
            for (i = 6 * 3; i; --i) *ihb++ = 0;
            for (i = 6 * 3; i; --i) *ihb++ = 255;
            for (i = nc; i; --i) *ihb++ = 0;
            for (i = 0; i < w; ++i) {
               for (k = 0; k < 3; ++k) {
                  for (l = 0; l < 8; ++l) {
                     b[k] = ReadPixel(&rp,(long)i,(long)((j * 24 + (k << 3) +
                           l) / 5)) | (b[k] << 1);
                  }
               }
               for (k = 3; k; --k) {
                  ihb[0] = b[0];
                  ihb[1] = b[1];
                  ihb[2] = b[2];
                  ihb += 3;
               }
            }

            if (j != 3) {
               for (i = 3 * 30 * 3; i; --i) *ihb++ = 0;
            } else {
               *ihb++ = ' ';
               *ihb++ = 'k';
               *ihb++ = 'g';
               *ihb++ = 27;
               *ihb++ = '*';
               *ihb++ = 39;
               *ihb++ = 45;
               *ihb++ = 0;

            }
            for (i = 33 * 3; i; --i) *ihb++ = 0;
            for (i = 6 * 3; i; --i) *ihb++ = 255;
            for (i = 6 * 3; i; --i) *ihb++ = 0;
            *ihb++ = '\n';
         }

         /* 10. Zeile */
         inhalt_pointer[9] = ihb;

         /* |     | */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 104;
         *ihb++ = 1;
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 255;
         for (i = 336 * 3; i; --i) *ihb++ = 0;
         for (i = 6 * 3; i; --i) *ihb++ = 255;
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 11. Zeile */
         inhalt_pointer[10] = ihb;

         /* unteres +-----+ */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 104;
         *ihb++ = 1;
         for (i = 0; i < 6 * 3; ++i) *ihb++ = 0;
         for (i = 0; i < 6; ++i) {
            ihb[0] = 255;
            ihb[1] = 254;
            ihb[2] = 0;
            ihb += 3;
         }
         for (i = 336 /* (3 * 60 + 4 * 2 * 18 + 2 * 6) */; i; --i) {
            ihb[0] = 0;
            ihb[1] = 126;
            ihb[2] = 0;
            ihb += 3;
         }
         for (i = 0; i < 6; ++i) {
            ihb[0] = 255;
            ihb[1] = 254;
            ihb[2] = 0;
            ihb += 3;
         }
         for (i = 6 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* (12. Zeile) */
         inhalt_pointer[11] = ihb;

         /* Zeilenl�ngen berechnen */
         for (i = 0; i < 11; ++i) {
            inhalt_length[i] = (int)(inhalt_pointer[i + 1] -
                  inhalt_pointer[i]);
         }
         break;

/*#ENDFD*/
      /*#FOLD: Gr��e 2 = Mittel */

      case 2:
         /* 1. Zeile */
         /* oberes +-----+ */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 20;
         *ihb++ = 1;
         for (i = 0; i < 7 * 3; ++i) *ihb++ = 0;
         for (i = 0; i < 4; ++i) {
            ihb[0] = 0;
            ihb[1] = 63;
            ihb[2] = 255;
            ihb += 3;
         }
         for (i = 254 /* (5 * 30 + 3 * 18 + 2 * 7 + 2 * 18) */; i; --i) {
            ihb[0] = 0;
            ihb[1] = 60;
            ihb[2] = 0;
            ihb += 3;
         }
         for (i = 0; i < 4; ++i) {
            ihb[0] = 0;
            ihb[1] = 63;
            ihb[2] = 255;
            ihb += 3;
         }
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 2. Zeile */
         inhalt_pointer[1] = ihb;

         /* |     | */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 20;
         *ihb++ = 1;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 254 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 3. Zeile */
         inhalt_pointer[2] = ihb;

         /* | Inhalt: | */
         *ihb++ = 27;
         *ihb++ = 'W';
         *ihb++ = 0;
         *ihb++ = 27;
         *ihb++ = 'w';
         *ihb++ = 0;
         *ihb++ = 27;
         *ihb++ = 'P';

         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 21;
         *ihb++ = 0;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 10 * 3; i; --i) *ihb++ = 0;

         *ihb++ = 32;
         *ihb++ = 32;
         *ihb++ = 32;
         *ihb++ = 'I';
         *ihb++ = 'n';
         *ihb++ = 'h';
         *ihb++ = 'a';
         *ihb++ = 'l';
         *ihb++ = 't';
         *ihb++ = ':';
         *ihb++ = 32;
         *ihb++ = 32;
         *ihb++ = 32;

         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 21;
         *ihb++ = 0;
         for (i = 10 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 4. Zeile */
         inhalt_pointer[3] = ihb;

         /* |     | */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 20;
         *ihb++ = 1;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 254 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 5. Zeile */
         inhalt_pointer[4] = ihb;

         /* |     | */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 20;
         *ihb++ = 1;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 254 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 6. Zeile */
         inhalt_pointer[5] = ihb;

         /* | xxxxx kg | */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 36;
         *ihb++ = 0;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 25 * 3; i; --i) *ihb++ = 0;
         *ihb++ = 27;
         *ihb++ = 'W';
         *ihb++ = 1;
         *ihb++ = 27;
         *ihb++ = 'w';
         *ihb++ = 1;
         *ihb++ = 27;
         *ihb++ = 'M';
         strcpy(ihb,s);
         ihb += strlen(s);
         *ihb++ = 27;
         *ihb++ = 'W';
         *ihb++ = 0;
         *ihb++ = 27;
         *ihb++ = 'w';
         *ihb++ = 0;
         *ihb++ = 27;
         *ihb++ = 'P';
         *ihb++ = ' ';
         *ihb++ = 'k';
         *ihb++ = 'g';
         *ihb++ = ' ';
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 18;
         *ihb++ = 0;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 7. Zeile */
         inhalt_pointer[6] = ihb;

         /* |     | */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 20;
         *ihb++ = 1;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 254 * 3; i; --i) *ihb++ = 0;
         for (i = 4 * 3; i; --i) *ihb++ = 255;
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* 8. Zeile */
         inhalt_pointer[7] = ihb;

         /* unteres +-----+ */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 20;
         *ihb++ = 1;
         for (i = 0; i < 7 * 3; ++i) *ihb++ = 0;
         for (i = 0; i < 4; ++i) {
            ihb[0] = 255;
            ihb[1] = 252;
            ihb[2] = 0;
            ihb += 3;
         }
         for (i = 254 /* (5 * 30 + 3 * 18 + 2 * 7 + 2 * 18) */; i; --i) {
            ihb[0] = 0;
            ihb[1] = 60;
            ihb[2] = 0;
            ihb += 3;
         }
         for (i = 0; i < 4; ++i) {
            ihb[0] = 255;
            ihb[1] = 252;
            ihb[2] = 0;
            ihb += 3;
         }
         for (i = 7 * 3; i; --i) *ihb++ = 0;
         *ihb++ = '\n';

         /* (9. Zeile) */
         inhalt_pointer[8] = ihb;

         /* Zeilenl�ngen berechnen */
         for (i = 0; i < 8; ++i) {
            inhalt_length[i] = (int)(inhalt_pointer[i + 1] -
                  inhalt_pointer[i]);
         }
         break;

/*#ENDFD*/
      /*#FOLD: Gr��e 1 = Klein */

      case 1:
         /* 1. Zeile */
         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 135;
         *ihb++ = 0;
         for (j = 6 * 3; j; --j) *ihb++ = 0;
         for (j = 3; j; --j) {
            *ihb++ = 0;
            *ihb++ = 0;
            *ihb++ = 63;
         }
         for (j = 123; j; --j) {
            *ihb++ = 0;
            *ihb++ = 0;
            *ihb++ = 56;
         }
         for (j = 3; j; --j) {
            *ihb++ = 0;
            *ihb++ = 0;
            *ihb++ = 63;
         }
         *ihb++ = '\n';

         /* 2. Zeile */
         inhalt_pointer[1] = ihb;

         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 17;
         *ihb++ = 0;
         for (j = 6 * 3; j; --j) *ihb++ = 0;
         for (j = 3 * 3; j; --j) *ihb++ = 255;
         for (j = 8 * 3; j; --j) *ihb++ = 0;

         movmem("\x1bg Inhalt: \x1bP",ihb,13);
         ihb += 13;

         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 10;
         *ihb++ = 0;
         for (j = 7 * 3; j; --j) *ihb++ = 0;
         for (j = 3 * 3; j; --j) *ihb++ = 255;
         *ihb++ = '\n';

         /* 3. Zeile */
         inhalt_pointer[2] = ihb;

         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 15;
         *ihb++ = 0;
         for (j = 6 * 3; j; --j) *ihb++ = 0;
         for (j = 3 * 3; j; --j) *ihb++ = 255;
         for (j = 6 * 3; j; --j) *ihb++ = 0;

         *ihb++ = 27;
         *ihb++ = 'M';
         movmem(s,ihb,5);
         ihb += 5;
         movmem("\x1bg kg\x1bP",ihb,7);
         ihb += 7;

         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 9;
         *ihb++ = 0;
         for (j = 6 * 3; j; --j) *ihb++ = 0;
         for (j = 3 * 3; j; --j) *ihb++ = 255;
         *ihb++ = '\n';

         /* 4. Zeile */
         inhalt_pointer[3] = ihb;

         *ihb++ = 27;
         *ihb++ = '*';
         *ihb++ = 39;
         *ihb++ = 135;
         *ihb++ = 0;
         for (j = 6 * 3; j; --j) *ihb++ = 0;
         for (j = 3; j; --j) {
            *ihb++ = 255;
            *ihb++ = 0;
            *ihb++ = 0;
         }
         for (j = 123; j; --j) {
            *ihb++ = 7;
            *ihb++ = 0;
            *ihb++ = 0;
         }
         for (j = 3; j; --j) {
            *ihb++ = 255;
            *ihb++ = 0;
            *ihb++ = 0;
         }
         *ihb++ = '\n';

         /* (5. Zeile) */
         inhalt_pointer[4] = ihb;

         /* Zeilenl�ngen berechnen */
         for (i = 0; i < 4; ++i) {
            inhalt_length[i] = (int)(inhalt_pointer[i + 1] -
                  inhalt_pointer[i]);
         }
         break;

/*#ENDFD*/

   }
}

/*#ENDFD*/
/*#FOLD: at() */

at(t,l)
char *t;
{
   if (!l) l = strlen(t);
   movmem(t,pbp,l);
   pbp += l;
}

/*#ENDFD*/
/*#FOLD: as() */

as(s,l)
register char *s;
{
   static char uml[][7] = {
      '�','�','�','�','�','�','�',
      0x7b,0x7c,0x7d,0x5b,0x5c,0x5d,0x7e
   };
   register int i;

   if (l) l = l - strlen(s);
   while (*s) {
      for (i = 6; i >= 0; --i) {
         if (*s == uml[0][i]) {
            at("\x1bR\x02",3);
            *pbp++ = uml[1][i];
            at("\x1bR",3);
            break;
         }
      }
      if (i < 0) *pbp++ = *s;
      ++s;
   }
   for (i = l; i; --i) {
      *pbp++ = ' ';
   }
}

/*#ENDFD*/
/*#FOLD: inh() */

inh(no)
{
   at(inhalt_pointer[no],inhalt_length[no]);
}

/*#ENDFD*/
/*#FOLD: print() */

print()
{
   register int i,j;

   pbp = pbb;
   *pbp++ = 27;
   *pbp++ = '@';
   create_inhalt(inhalt);

   switch (groesse) {

      /*#FOLD: Gr��e 3 = Gro� */

      case 3:
         at("\x1b2\x1bW\x01\n\n\n\n\n",0);

         gfx_print(produkt,TITEL_XS,TITEL_YS);
         *pbp++ = '\n';
         gfx_print(komponente,KOMPONENTE_XS,KOMPONENTE_YS);
         *pbp++ = '\n';

         for (i = 0; i < 2; ++i) {
            at("\x1bM\x1bw\x01",0);
            as("",54);
            inh(i);
         }
         at("\x1bM\x1bw\x01      Farbton: ",0);
         as(farbton,15);
         at("   Charge: ",0);
         as(charge,7);
         as("",6);
         inh(2);
         for (i = 3; i < 7; ++i) {
            as("",54);
            inh(i);
         }
         as("      Mischungsverh�ltnis: ",0);
         as(mischung,20);
         as("",7);
         inh(7);
         for (i = 8; i < 11; ++i) {
            as("",54);
            inh(i);
         }
         at("\x1bW",3);
         as("\n\n\x1b2\x1bP          Produkt enth�lt: \x1bw",0);
         *pbp++ = 0;
         as(enthaelt[0],50);
         *pbp++ = '\n';
         for (i = 1; i < 4; ++i) {
            as("",27);
            as(enthaelt[i],0);
            *pbp++ = '\n';
         }
         at("\n\n          Gefahrenhinweise:\n",0);
         for (i = 0; i < 4; ++i) {
            as("",10);
            *pbp++ = 15;
            as(gefahren[i],0);
            at("\x12\n",0);
         }
         at("\n          Sicherheitshinweise:\n",0);
         for (i = 0; i < 4; ++i) {
            as("",10);
            *pbp++ = 15;
            as(hinweise[i],0);
            at("\x12\n",0);
         }
         i = 2535;
         break;

/*#ENDFD*/
      /*#FOLD: Gr��e 2 = Mittel */

      case 2:
         at("\x1b2\x1bW\x01\n\n\n\n",0);

         gfx_print(produkt,KOMPONENTE_XS,KOMPONENTE_YS);

         for (i = 0; i < 3; ++i) {
            as("",45);
            inh(i);
         }
         at("\x1bW\x00 \x1bW\x01\x1bw\x01",10);
         as("",23);
         as(komponente,0);
         at("\x1bW\x00\x1bw\x00\r",7);
         for (i = 3; i < 7; ++i) {
            as("",90);
            inh(i);
         };
         as("",10);
         at("Farbton: ",0);
         as(farbton,15);
         as("",16);
         at("Charge: ",0);
         as(charge,7);
         as("",25);
         inh(7);
         as("\n\n          Mischungsverh�ltnis: ",0);
         as(mischung,20);
         as("\n\n\n          Produkt enth�lt: \x0f",0);
         as(enthaelt[0],50);
         for (i = 1; i < 4; ++i) {
            as("\n\x12",29);
            *pbp++ = 15;
            as(enthaelt[i]);
         }
         at("\n\x12\n\n          Gefahrenhinweise:",0);
         for (i = 0; i < 4; ++i) {
            at("\n\x12          \x0f",0);
            as(gefahren[i],0);
         }
         at("\n\x12\n          Sicherheitshinweise:",0);
         for (i = 0; i < 4; ++i) {
            at("\n\x12          \x0f",0);
            as(hinweise[i],0);
         }
         i = 1770;
         break;

/*#ENDFD*/
      /*#FOLD: Gr��e 1 = Klein */

      case 1:
         at("\x1b+\x08\n\x1b0\n\x1bw\x01",0);
         as("",(i = 16 - (strlen(produkt) >> 1)) + 4);
         as(produkt,32 - i);
         at("\x1bw\x00\x1bP\r",6);
         as("",36);
         inh(0);
         as("",14);
         as(komponente,22);
         inh(1);
         as("",36);
         inh(2);
         at("\x1bA\x05    \x1bgFarbton: ",0);
         as(farbton,15);
         at("   Charge: ",0);
         as(charge,7);
         as("",6);
         inh(3);
         as("\n      \x1bgMischungsverh�ltnis: ",0);
         as(mischung,20);
         as("\n\n      Produkt enth�lt:",0);
         for (i = 0; i < 4; ++i) {
            as("\n      ",0);
            as(enthaelt[i],0);
         }
         as("\n      \x1bEGefahrenhinweise:\x1bF",0);
         for (i = 0; i < 4; ++i) {
            as("\n      ",0);
            as(gefahren[i],0);
         }
         as("\n      \x1bESicherheitshinweise:\x1bF",0);
         for (i = 0; i < 4; ++i) {
            as("\n      ",0);
            as(hinweise[i],0);
         }
         i = 728;
         break;

/*#ENDFD*/

   }

   i = papier_laengen[groesse - 1] - i;
   at("\x1b2",0);
   while (i >= 180) {
      at("\n\n\n",0);
      i -= 180;
   }
   if (i) {
      at("\x1b+",0);
      *pbp++ = i;
      *pbp++ = '\n';
   }
   at("\x1b2",0);
}

/*#ENDFD*/
/*#FOLD: prt() */

prt()
{
   iob->io_Command = PRD_RAWWRITE;
   iob->io_Data = (APTR)pbb;
   iob->io_Length = (long)(pbp - pbb);
   DoIO(iob);
   if (iob->io_Error) DisplayBeep(0L);
   return iob->io_Error;
}

/*#ENDFD*/

/*#ENDFD*/

/*------------------------------------------------------------------------*/

struct TextAttr Topaz_80 = {
   (STRPTR)"topaz.font",8,FS_NORMAL,FPF_ROMFONT
};

short status_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,547,-2,547,9,546,-1,546,9,-2,9
};
struct Border status_border = {
   0,0,1,0,JAM1,9,status_xy,0
};

/*#FOLD: 24. Gadget - Stop */

/*------ 24. Gadget - Stop ------*/

short stop_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,547,-2,547,9,546,-1,546,9,-2,9
};
struct Border stop_border = {
   2,1,1,0,JAM1,9,stop_xy,0
};
struct IntuiText stop_text = {
   1,0,JAM1,256,1,&Topaz_80,(STRPTR)"Stop",0
};
struct Gadget stop_gg = {
   0,18,-18,548,10,GADGHCOMP|GRELBOTTOM,RELVERIFY,BOOLGADGET,
   (APTR)&stop_border,0,&stop_text,0,0,24,0
};

/*#ENDFD*/
/*#FOLD: 23. Gadget - Gr��e */

/*------ 23. Gadget - Gr��e ------*/

short groesse_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,107,-2,107,9,106,-1,106,9,-2,9
};
struct Border groesse_border = {
   2,1,1,0,JAM1,9,groesse_xy,0
};
struct IntuiText groesse_text[] = { {
      1,0,JAM2,10,1,&Topaz_80,(STRPTR)"   Klein   ",0
   },{
      1,0,JAM2,14,1,&Topaz_80,(STRPTR)"Mittelgro�",0
   },{
      1,0,JAM2,14,1,&Topaz_80,(STRPTR)"   Gro�   ",0
   }
};
struct Gadget groesse_gg = {
   0,226,-18,108,10,GADGHCOMP|GRELBOTTOM,RELVERIFY,BOOLGADGET,
   (APTR)&groesse_border,0,groesse_text,0,0,23,0
};

/*#ENDFD*/
/*#FOLD: 22. Gadget - Anzahl */

/*------ 22. Gadget - Anzahl ------*/

short anzahl_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,51,-2,51,9,50,-1,50,9,-2,9
};
struct Border anzahl_border = {
   0,0,1,0,JAM1,9,anzahl_xy,0
};
struct IntuiText anzahl_text = {
   1,0,JAM1,-68,0,&Topaz_80,(STRPTR)"Anzahl:",0
};
struct StringInfo anzahl_info = {
   (STRPTR)anzahl,0,0,6,0
};
struct Gadget anzahl_gg = {
   &groesse_gg,-163,-17,48,8,GADGHCOMP|GRELRIGHT|GRELBOTTOM,LONGINT|
   STRINGRIGHT,STRGADGET,(APTR)&anzahl_border,0,&anzahl_text,0,
   (APTR)&anzahl_info,22,0
};

/*#ENDFD*/
/*#FOLD: 21. Gadget - Drucken */

/*------ 21. Gadget - Drucken ------*/

short drucken_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,75,-2,75,9,74,-1,74,9,-2,9
};
struct Border drucken_border = {
   2,1,1,0,JAM1,9,drucken_xy,0
};
struct IntuiText drucken_text = {
   1,0,JAM1,10,1,&Topaz_80,(STRPTR)"Drucken",0
};
struct Gadget drucken_gg = {
   &anzahl_gg,-93,-18,76,10,GADGHCOMP|GRELBOTTOM|GRELRIGHT,RELVERIFY,
   BOOLGADGET,(APTR)&drucken_border,0,&drucken_text,0,0,21,0
};

/*#ENDFD*/
/*#FOLD: 20. Gadget - L�schen */

/*------ 20. Gadget - L�schen ------*/

short loeschen_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,75,-2,75,9,74,-1,74,9,-2,9
};
struct Border loeschen_border = {
   2,1,1,0,JAM1,9,loeschen_xy,0
};
struct IntuiText loeschen_text = {
   1,0,JAM1,10,1,&Topaz_80,(STRPTR)"L�schen",0
};
struct Gadget loeschen_gg = {
   &drucken_gg,130,-18,76,10,GADGHCOMP|GRELBOTTOM,RELVERIFY,BOOLGADGET,
   (APTR)&loeschen_border,0,&loeschen_text,0,0,20,0
};

/*#ENDFD*/
/*#FOLD: 19. Gadget - Testdruck */

/*------ 19. Gadget - Testdruck ------*/

short testdruck_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,91,-2,91,9,90,-1,90,9,-2,9
};
struct Border testdruck_border = {
   2,1,1,0,JAM1,9,testdruck_xy,0
};
struct IntuiText testdruck_text = {
   1,0,JAM1,10,1,&Topaz_80,(STRPTR)"Testdruck",0
};
struct Gadget testdruck_gg = {
   &loeschen_gg,18,-18,92,10,GADGHCOMP|GRELBOTTOM,RELVERIFY,BOOLGADGET,
   (APTR)&testdruck_border,0,&testdruck_text,0,0,19,0
};

/*#ENDFD*/
/*#FOLD: 18. - 15. Gadget - Sicherheitshinweise */

/*------ 18. - 15. Gadget - Sicherheitshinweise ------*/

short hinweise_xy[] = {
   -3,-1,-3,33,-4,33,-4,-2,547,-2,547,33,546,-1,546,33,-2,33
};
struct Border hinweise_border = {
   0,0,1,0,JAM1,9,hinweise_xy,0
};
struct IntuiText hinweise_text = {
   1,0,JAM1,-4,-12,&Topaz_80,(STRPTR)"Sicherheitshinweise:",0
};
struct StringInfo hinweise_4_info = {
   (STRPTR)hinweise[3],0,0,51,0
};
struct Gadget hinweise_4_gg = {
   &testdruck_gg,20,GG_Y + 168,544,8,GADGHCOMP,RELVERIFY,STRGADGET,
   0,0,0,0,(APTR)&hinweise_4_info,18,0
};
struct StringInfo hinweise_3_info = {
   (STRPTR)hinweise[2],0,0,51,0
};
struct Gadget hinweise_3_gg = {
   &hinweise_4_gg,20,GG_Y + 160,544,8,GADGHCOMP,RELVERIFY,STRGADGET,
   0,0,0,0,(APTR)&hinweise_3_info,17,0
};
struct StringInfo hinweise_2_info = {
   (STRPTR)hinweise[1],0,0,51,0
};
struct Gadget hinweise_2_gg = {
   &hinweise_3_gg,20,GG_Y + 152,544,8,GADGHCOMP,RELVERIFY,STRGADGET,
   0,0,0,0,(APTR)&hinweise_2_info,16,0
};
struct StringInfo hinweise_1_info = {
   (STRPTR)hinweise[0],0,0,51,0
};
struct Gadget hinweise_gg = {
   &hinweise_2_gg,20,GG_Y + 144,544,8,GADGHCOMP,RELVERIFY,STRGADGET,
   (APTR)&hinweise_border,0,&hinweise_text,0,(APTR)&hinweise_1_info,15,0
};

/*#ENDFD*/
/*#FOLD: 14. - 11. Gadget - Gefahrenhinweise */

/*------ 14. - 11. Gadget: Gefahrenhinweise */

short gefahren_xy[] = {
   -3,-1,-3,33,-4,33,-4,-2,547,-2,547,33,546,-1,546,33,-2,33
};
struct Border gefahren_border = {
   0,0,1,0,JAM1,9,gefahren_xy,0
};
struct IntuiText gefahren_text = {
   1,0,JAM1,-4,-12,&Topaz_80,(STRPTR)"Gefahrenhinweise:",0
};
struct StringInfo gefahren_4_info = {
   (STRPTR)gefahren[3],0,0,51,0
};
struct Gadget gefahren_4_gg = {
   &hinweise_gg,20,GG_Y + 120,544,8,GADGHCOMP,RELVERIFY,STRGADGET,
   0,0,0,0,(APTR)&gefahren_4_info,14,0
};
struct StringInfo gefahren_3_info = {
   (STRPTR)gefahren[2],0,0,51,0
};
struct Gadget gefahren_3_gg = {
   &gefahren_4_gg,20,GG_Y + 112,544,8,GADGHCOMP,RELVERIFY,STRGADGET,
   0,0,0,0,(APTR)&gefahren_3_info,13,0
};
struct StringInfo gefahren_2_info = {
   (STRPTR)gefahren[1],0,0,51,0
};
struct Gadget gefahren_2_gg = {
   &gefahren_3_gg,20,GG_Y + 104,544,8,GADGHCOMP,RELVERIFY,STRGADGET,
   0,0,0,0,(APTR)&gefahren_2_info,12,0
};
struct StringInfo gefahren_1_info = {
   (STRPTR)gefahren[0],0,0,51,0
};
struct Gadget gefahren_gg = {
   &gefahren_2_gg,20,GG_Y + 96,544,8,GADGHCOMP,RELVERIFY,STRGADGET,
   (APTR)&gefahren_border,0,&gefahren_text,0,(APTR)&gefahren_1_info,11,0
};

/*#ENDFD*/
/*#FOLD: 10. - 7. Gadget - Produkt enth�lt */

/*------ 10. - 7. Gadget: Produkt enth�lt */

short enthaelt_xy[] = {
   -3,-1,-3,33,-4,33,-4,-2,411,-2,411,33,410,-1,410,33,-2,33
};
struct Border enthaelt_border = {
   0,0,1,0,JAM1,9,enthaelt_xy,0
};
struct IntuiText enthaelt_text = {
   1,0,JAM1,-140,0,&Topaz_80,(STRPTR)"Produkt enth�lt:",0
};
struct StringInfo enthaelt_4_info = {
   (STRPTR)enthaelt[3],0,0,51,0
};
struct Gadget enthaelt_4_gg = {
   &gefahren_gg,156,GG_Y + 72,408,8,GADGHCOMP,RELVERIFY,STRGADGET,
   0,0,0,0,(APTR)&enthaelt_4_info,10,0
};
struct StringInfo enthaelt_3_info = {
   (STRPTR)enthaelt[2],0,0,51,0
};
struct Gadget enthaelt_3_gg = {
   &enthaelt_4_gg,156,GG_Y + 64,408,8,GADGHCOMP,RELVERIFY,STRGADGET,0,0,
   0,0,(APTR)&enthaelt_3_info,9,0
};
struct StringInfo enthaelt_2_info = {
   (STRPTR)enthaelt[1],0,0,51,0
};
struct Gadget enthaelt_2_gg = {
   &enthaelt_3_gg,156,GG_Y + 56,408,8,GADGHCOMP,RELVERIFY,STRGADGET,0,0,
   0,0,(APTR)&enthaelt_2_info,8,0
};
struct StringInfo enthaelt_1_info = {
   (STRPTR)enthaelt[0],0,0,51,0
};
struct Gadget enthaelt_gg = {
   &enthaelt_2_gg,156,GG_Y + 48,408,8,GADGHCOMP,RELVERIFY,STRGADGET,
   (APTR)&enthaelt_border,0,&enthaelt_text,0,(APTR)&enthaelt_1_info,7,0
};

/*#ENDFD*/
/*#FOLD: 6. Gadget - Inhalt */

/*------ 6. Gadget: Inhalt */

short inhalt_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,51,-2,51,9,50,-1,50,9,-2,9
};
struct Border inhalt_border = {
   0,0,1,0,JAM1,9,inhalt_xy,0
};
struct IntuiText inhalt_text = {
   1,0,JAM1,-116,0,&Topaz_80,(STRPTR)"Inhalt in kg:",0
};
struct StringInfo inhalt_info = {
   (STRPTR)inhalt,0,0,6,0
};
struct Gadget inhalt_gg = {
   &enthaelt_gg,-67,GG_Y + 32,48,8,GADGHCOMP|GRELRIGHT,RELVERIFY|LONGINT,
   STRGADGET,(APTR)&inhalt_border,0,&inhalt_text,0,(APTR)&inhalt_info,6,0
};

/*#ENDFD*/
/*#FOLD: 5. Gadget - Mischungsverh�ltnis */

/*------ 5. Gadget: Mischungsverh�ltnis */

short mischung_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,171,-2,171,9,170,-1,170,9,-2,9
};
struct Border mischung_border = {
   0,0,1,0,JAM1,9,mischung_xy,0
};
struct IntuiText mischung_text = {
   1,0,JAM1,-172,0,&Topaz_80,(STRPTR)"Mischungsverh�ltnis:",0
};
struct StringInfo mischung_info = {
   (STRPTR)mischung,0,0,21,0
};
struct Gadget mischung_gg = {
   &inhalt_gg,188,GG_Y + 32,168,8,GADGHCOMP,RELVERIFY,STRGADGET,
   (APTR)&mischung_border,0,&mischung_text,0,(APTR)&mischung_info,5,0
};

/*#ENDFD*/
/*#FOLD: 4. Gadget - Charge */

/*------ 4. Gadget: Charge ------*/

short charge_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,67,-2,67,9,66,-1,66,9,-2,9
};
struct Border charge_border = {
   0,0,1,0,JAM1,9,charge_xy,0
};
struct IntuiText charge_text = {
   1,0,JAM1,-100,0,&Topaz_80,(STRPTR)"Charge:",0
};
struct StringInfo charge_info = {
   (STRPTR)charge,0,0,8,0
};
struct Gadget charge_gg = {
   &mischung_gg,-83,GG_Y + 16,64,8,GADGHCOMP|GRELRIGHT,RELVERIFY,STRGADGET,
   (APTR)&charge_border,0,&charge_text,0,(APTR)&charge_info,4,0
};

/*#ENDFD*/
/*#FOLD: 3. Gadget - Farbton */

/*------ 3. Gadget: Farbton ------*/

short farbton_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,131,-2,131,9,130,-1,130,9,-2,9
};
struct Border farbton_border = {
   0,0,1,0,JAM1,9,farbton_xy,0
};
struct IntuiText farbton_text = {
   1,0,JAM1,-76,0,&Topaz_80,(STRPTR)"Farbton:",0
};
struct StringInfo farbton_info = {
   (STRPTR)farbton,0,0,16,0
};
struct Gadget farbton_gg = {
   &charge_gg,92,GG_Y + 16,128,8,GADGHCOMP,RELVERIFY,STRGADGET,
   (APTR)&farbton_border,0,&farbton_text,0,(APTR)&farbton_info,3,0
};

/*#ENDFD*/
/*#FOLD: 2. Gadget - Komponente */

/*------ 2. Gadget: Komponente ------*/

short komponente_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,19,-2,19,9,18,-1,18,9,-2,9
};
struct Border komponente_border = {
   0,0,1,0,JAM1,9,komponente_xy,0
};
struct IntuiText komponente_text = {
   1,0,JAM1,-148,0,&Topaz_80,(STRPTR)"Komponente:",0
};
struct StringInfo komponente_info = {
   (STRPTR)&komponente[11],0,0,2,0
};
struct Gadget komponente_gg = {
   &farbton_gg,-35,GG_Y,16,8,GADGHCOMP|GRELRIGHT,RELVERIFY,STRGADGET,
   (APTR)&komponente_border,0,&komponente_text,0,(APTR)&komponente_info,2,0
};

/*#ENDFD*/
/*#FOLD: 1. Gadget - Produkt/Titel */

/*------ 1. Gadget: Produkt/Titel ------*/

short titel_xy[] = {
   -3,-1,-3,9,-4,9,-4,-2,251,-2,251,9,250,-1,250,9,-2,9
};
struct Border titel_border = {
   0,0,1,0,JAM1,9,titel_xy,0
};
struct IntuiText titel_text = {
   1,0,JAM1,-76,0,&Topaz_80,(STRPTR)"Produkt:",0
};
struct StringInfo titel_info = {
   (STRPTR)produkt,0,0,31,0
};
struct Gadget titel_gg = {
   &komponente_gg,92,GG_Y,248,8,GADGHCOMP,RELVERIFY|STRINGCENTER,STRGADGET,
   (APTR)&titel_border,0,&titel_text,0,(APTR)&titel_info,1,0
};

/*#ENDFD*/
/*#FOLD: new_wnd - NewWindow-Struktur */

/*------ NewWindow ------*/

struct NewWindow new_wnd = {
   28,12,584,243,-1,-1,GADGETUP|CLOSEWINDOW,WINDOWDRAG|WINDOWDEPTH|
   WINDOWCLOSE|SMART_REFRESH|ACTIVATE|NOCAREREFRESH|RMBTRAP,&titel_gg,
   0,(UBYTE *)"Etiketten-Druck-Programm - ETI 1.2",
   0,0,-1,-1,-1,-1,WBENCHSCREEN
};

/*#ENDFD*/

struct StringInfo *info_tab[] = {
   &hinweise_4_info,&hinweise_3_info,&hinweise_2_info,&hinweise_1_info,
   &gefahren_4_info,&gefahren_3_info,&gefahren_2_info,&gefahren_1_info,
   &enthaelt_4_info,&enthaelt_3_info,&enthaelt_2_info,&enthaelt_1_info,
   &mischung_info,&charge_info,&farbton_info,&komponente_info,&inhalt_info,
   &titel_info
};

/*#FOLD: clear_si() */

clear_si(si)
struct StringInfo *si;
{
   static struct StringInfo clear_si = { 0 };
   unsigned char *bufptr;
   int maxchars;

   bufptr = si->Buffer;
   maxchars = si->MaxChars;
   *si = clear_si;
   si->Buffer = bufptr;
   si->MaxChars = maxchars;
}

/*#ENDFD*/
/*#FOLD: clear() */

clear()
{
   register int i;

   for (i = 0; i < sizeof(info_tab) / sizeof(struct StringInfo *); ++i) {
      clear_si(info_tab[i]);
      info_tab[i]->Buffer[0] = 0;
   }
   RefreshGadgets(&titel_gg,wnd,0L);
}

/*#ENDFD*/
/*#FOLD: clear_IDCMP() */

clear_IDCMP()
{
   struct Message *msgp;

   while (msgp = GetMsg(wnd->UserPort)) ReplyMsg(msgp);
}

/*#ENDFD*/
/*#FOLD: clear_gg() */

clear_gg(ggp)
struct Gadget *ggp;
{
   SetAPen(wnd->RPort,0L);
   if (ggp->Flags & GRELBOTTOM) {
      RectFill(wnd->RPort,(long)(ggp->LeftEdge - 2),
            (long)(ggp->TopEdge + wnd->Height - 2),
            (long)(ggp->LeftEdge + ggp->Width + 1),
            (long)(ggp->TopEdge + wnd->Height + ggp->Height - 1));
   } else {
      RectFill(wnd->RPort,(long)(ggp->LeftEdge + 51 * 8),
            (long)(ggp->TopEdge),
            (long)(ggp->LeftEdge + ggp->Width),
            (long)(ggp->TopEdge + 31));
   }
   SetAPen(wnd->RPort,1L);
}

/*#ENDFD*/
/*#FOLD: message() */

message(s)
char *s;
{
   long l = strlen(s);

   if (!(((long)s) & 0x80000000)) {
      SetAPen(wnd->RPort,0L);
      RectFill(wnd->RPort,18L,18L,565L,27L);
      SetAPen(wnd->RPort,1L);
   }
   if (s) {
      Move(wnd->RPort,292L - (TextLength(wnd->RPort,s,l) >> 1),
            (long)(19 + wnd->RPort->TxBaseline));
      Text(wnd->RPort,s,l);
   }
}

/*#ENDFD*/
/*#FOLD: install_stop() */

install_stop()
{
   register int i;
   register struct Gadget *ggp;

   RemoveGList(wnd,&titel_gg,23L);
   clear_gg(&stop_gg);
   clear_IDCMP();
   ModifyIDCMP(wnd,GADGETUP);
   AddGadget(wnd,&stop_gg,-1L);
   RefreshGadgets(&stop_gg,wnd,0L);
}

/*#ENDFD*/
/*#FOLD: test_stop() */

test_stop()
{
   struct Message *msgp;

   if (msgp = GetMsg(wnd->UserPort)) ReplyMsg(msgp);
   return msgp ? 1 : 0;
}

/*#ENDFD*/
/*#FOLD: remove_stop() */

remove_stop()
{
   register int i;
   register struct Gadget *ggp;

   RemoveGadget(wnd,&stop_gg);
   clear_gg(&stop_gg);
   AddGList(wnd,&titel_gg,0L,23L,0L);
   clear_IDCMP();
   ModifyIDCMP(wnd,(long)new_wnd.IDCMPFlags);
   RefreshGadgets(&titel_gg,wnd,0L);
}

/*#ENDFD*/

/*------------------------------------------------------------------------*/

/*#FOLD: startup() */

struct TextAttr ta = {
   (STRPTR)FONT_NAME,FONT_HEIGHT,FS_NORMAL,FPF_DISKFONT
};

startup()
{
   int error = 20;

   vp.ColorMap = 0L;
   if (GfxBase = (struct GfxBase *)OpenLibrary("graphics.library",0L)) {
      if (IntuitionBase = (struct IntuitionBase *)
               OpenLibrary("intuition.library",0L)) {
         error = 10;
         if (DiskfontBase = OpenLibrary("diskfont.library",0L)) {
            if (TextFont = OpenDiskFont(&ta)) {
               if (mpp = CreatePort(0L,0L)) {
                  if (iob = CreateStdIO(mpp)) {
                     if (!OpenDevice("printer.device",0L,iob,0L)) {
                        open_flag = 1;
                        if (pbb = AllocMem((long)BUFFER_SIZE,MEMF_PUBLIC)) {
                           if (wnd = OpenWindow(&new_wnd)) return;
                           else puts("Unable to open a new window !");
                        } else puts("Not enough memory !");
                     } else puts("Can't open the 'printer.device' !");
                  } else puts("Unable to create the io request !");
               } else puts("Can't create reply port !");
            } else puts("Can't open the font 'Times 24'�!");
         } else puts("Unable to open the 'diskfont.library' !");
      } else puts("Unable to open the 'intuition.library' !");
   } else puts("Unable to open the 'graphics.library' !");
   exit(error);
}

/*#ENDFD*/
/*#FOLD: cleanup() */

cleanup()
{
   if (open_flag) CloseDevice(iob);
   if (mpp) DeletePort(mpp);
   if (iob) DeleteStdIO(iob);
   if (wnd) CloseWindow(wnd);
   if (vp.ColorMap) {
      FreeColorMap(vp.ColorMap);
      FreeVPortCopLists(&vp);
      FreeCprList(v.LOFCprList);
      FreeCprList(v.SHFCprList);
   }
   if (TextFont) CloseFont(TextFont);
   if (pbb) FreeMem(pbb,(long)BUFFER_SIZE);
   if (DiskfontBase) CloseLibrary(DiskfontBase);
   if (IntuitionBase) CloseLibrary(IntuitionBase);
   if (GfxBase) CloseLibrary(GfxBase);
}

/*#ENDFD*/
/*#FOLD: exit() */

exit(code)
{
   cleanup();
   if (cls_) (*cls_)();
   _exit(code);
}

/*#ENDFD*/

long _stack = 0, _priority = 0, _BackGroundIO = 0;
char *_procname = "ETI";

main(argc,argv)
char **argv;
{
   register long i,l;
   register struct Gadget *ggp;
   struct IntuiMessage imsg,*imsgp;
   char buf[80];

   startup();
   init_gfx();
   anzahl[0] = 0;
   DrawBorder(wnd->RPort,&status_border,20L,19L);
   clear();
   ActivateGadget(&titel_gg,wnd,0L);
   do {
      message("Bitte w�hlen Sie oder machen Sie ihre Eingaben...");
      WaitPort(wnd->UserPort);
      imsg = *(imsgp = (struct IntuiMessage *)GetMsg(wnd->UserPort));
      if (imsg.Class == GADGETUP) {
         ggp = (struct Gadget *)imsg.IAddress;
         if (ggp->GadgetID < 18) ActivateGadget(ggp->NextGadget,wnd,0L);
         switch (ggp->GadgetID) {
            case 19:
               install_stop();
               message("Druck-Daten werden berechnet...");
               print();
               if (!test_stop()) {
                  message("Es wird gedruckt...");
                  prt();
               }
               remove_stop();
               break;
            case 20:
               clear();
               ActivateGadget(&titel_gg,wnd,0L);
               break;
            case 21:
               if (anzahl_info.LongInt &&
                        (l = anzahl_info.LongInt) < 100000) {
                  install_stop();
                  message("Druck-Daten werden berechnet...");
                  print();
                  for (i = 1; i <= l; ++i) {
                     if (i != 1) Delay(delay);
                     if (test_stop()) break;
                     sprintf(buf,"Die %ld. Etikette wird ausgedruckt...",i);
                     message(((long)buf) | 0x80000000);
                     prt();
                  }
                  remove_stop();
                  break;
               }
            case 18:
               ActivateGadget(&anzahl_gg,wnd,0L);
               break;
            case 23:
               groesse_gg.GadgetText = &groesse_text[(groesse = groesse ==
                     3 ? 1 : groesse + 1) - 1];
               l = groesse == 1 ? 51 : 91;
               for (i = 0; i < 8; ++i) {
                  clear_si(info_tab[i]);
                  info_tab[i]->Buffer[(info_tab[i]->MaxChars = l) - 1] = 0;
               }
               clear_gg(&gefahren_gg);
               clear_gg(&hinweise_gg);
               RefreshGadgets(&gefahren_gg,wnd,0L);
               ActivateGadget(&titel_gg,wnd,0L);
               break;
         }
      }
      ReplyMsg(imsgp);
   } while (imsg.Class != CLOSEWINDOW);
   exit(0);
}

