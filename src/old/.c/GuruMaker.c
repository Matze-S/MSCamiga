/* Copyright (C) 1990 by Matthias Schmidt */

/*-------------------------------------------------------------------------*
 *                                                                         *
 * GuruMaker.c -- a program for creating gurus, alerts, task helds ...     *
 * v1.2 -- 14:03 08-Mar-90                                                 *
 *                                                                         *
 *-------------------------------------------------------------------------*
 *                                                                         *
 * Syntax:                                                                 *
 *                                                                         *
 *  GuruMaker options <textfilename>                                       *
 *                                                                         *
 *    where options can be:                                                *
 *                                                                         *
 *       -b                -- The led will blink before the guru comes     *
 *       -c                -- The text will be centered                    *
 *       -d                -- The rest of the screen will be dark          *
 *       -e                -- The alert is a DEADEND_ALERT                 *
 *       -f                -- = -rtr -- for compatibility
 *       -g                -- Standard Guru Parameters                     *
 *       -h <height>       -- Define the height of the Alert               *
 *       -l <x-pos>        -- Define the left edge of the displayed text   *
 *       -r[x] <width> <line1> <line2> <line3> <leftgadget> <rightgadget>  *
 *                         -- Create own requester with 3 text lines       *
 *       -rt[x]            -- Create 'task held' requester                 *
 *          x:  l|r   -- The reqs will stop displaying if you hit the      *
 *                       left (l), the right (r) or both (lr) gadgets      *
 *                    (Note: Standard-width is 320!)                       *
 *       -s                -- Use the TOPAZ_SIXTY font                     *
 *       -t <y-pos>        -- Define the top edge of the displayed text    *
 *       -y <y-add>  -- Define the number of pixels between the text lines *
 *                                                                         *
 *  This program was written using the workbench - 'ED' and the            *
 *  Aztec 3.6a C Compiler.                                                 *
 *                                                                         *
 *------------------------------------------------------------------------*/

#define MAXNUM_REQS 10

#define OPT_ALERT 1
#define OPT_CENTERED 2
#define OPT_DARK 4
#define OPT_DEADEND 8
#define OPT_SIXTY 16
#define OPT_HEIGHT 32
#define OPT_BLINK 64
#define OPT_REQ 128

void **IntuitionBase,**OpenLibrary();
extern int Enable_Abort;
int sysreq_width = 0;

struct {
   int w,f;
   char *l1,*l2,*l3,*l,*r;
} reqs[MAXNUM_REQS];

#define F_TASKHELD 1
#define F_CALCWIDTH 2
#define F_LEFT 4
#define F_RIGHT 8

void chg_led();
#asm
_chg_led:
   bchg.b #1,$bfe001
   rts
#endasm

make_req(t1,t2,t3,lt,rt)
char *t1,*t2,*t3,*lt,*rt;
{
   static struct {
      char fp,bp,dm,pad;
      short le,te;
      void *f,*s,*n;
   } it[5] = {
      0,1,1,0,15,5,0,0,&it[1],
      0,1,1,0,15,15,0,0,&it[2],
      0,1,1,0,15,25,0,0,0,
      0,1,1,0,6,3,0,0,0,
      0,1,1,0,6,3,0,0,0
   };

   it[0].s = t1;
   it[1].s = t2;
   it[2].s = t3;
   it[3].s = lt;
   it[4].s = rt;
   return (AutoRequest(0L,it,&it[3],&it[4],0L,0L,sysreq_width ?
         (long)sysreq_width : 320L,72L));
}

main(argc,argv)
char **argv;
{
   static struct {
      short s0[5];
      char c0[2];
      short s1[2];
      void *p0[4];
   } ns = {
      0,0,320,-1,1,0,0,0,0x10f,0,0,0,0
   };
   static short cols[] = {
      0x888,0xfff,0x111
   };
   int i,j,k,l,lin_cnt,opt = 0,size,*ip,rc = 0,req_cnt = -1;
   int leftedge = 8,topedge = 4,height,yadd = 8;
   char *name = 0,*buf,*as = 0,*cp,*malloc();
   void **col_map,**sp = 0,*aw,*fp,*fopen(),**OpenScreen();
   short prefbuf_s[59],prefbuf_n[59],*col_tab;

   if (argc == 1) {
      printf("Usage: %s options <textfilename>\n",argv[0]);
      puts("where options can be:");
      puts("  -b          blink led");
      puts("  -c          centered text");
      puts("  -d          dark background");
      puts("  -e          dead_end alert");
      puts("  -f          = -rtr -- for compatibility");
      puts("  -g          normal guru parms");
      puts("  -h <height> height of alert");
      puts("  -l <x-pos>  left edge of text");
      puts("  -r[x] <w> <1> <2> <3> <l> <r> display requester");
      puts("  -rt[x]      standard 'task held' requester");
      puts("     x: l|r hit Left/Right gadget(s) to cancel");
      puts("     note: standard width is 320!");
      puts("  -s          use topaz_sixty font");
      puts("  -t <y-pos>  top edge of text");
      puts("  -y <y-add>  # of pixels between the lines");
      exit(0);
   }
   for (i = 1; i < argc; ++i) {
      if (argv[i][0] != '-') {
         if (name) {
            puts("Too many file names!");
            exit(20);
         }
         name = argv[i];
      } else {
         for (j = 1; argv[i][j]; ++j) {
            k = 256;
            switch(argv[i][j]) {
               case 'b':
               case 'B':
                  k = OPT_BLINK;
                  break;
               case 'c':
               case 'C':
                  k = OPT_CENTERED;
                  break;
               case 'd':
               case 'D':
                  k = OPT_DARK;
                  break;
               case 'e':
               case 'E':
                  k = OPT_DEADEND;
                  break;
               case 'f':
               case 'F':
                  if (req_cnt == 9) {
                     printf("Requester definition table is full!\n");
                     exit(20);
                  }
                  k = OPT_REQ;
                  reqs[++req_cnt].f = F_TASKHELD|F_RIGHT;
                  break;
               case 'g':
               case 'G':
                  topedge = 9;
                  leftedge = 38;
                  yadd = 15;
                  height = 40;
                  k = OPT_HEIGHT;
                  break;
               case 'h':
               case 'H':
                  ip = &height;
                  k |= OPT_HEIGHT;
                  break;
               case 'l':
               case 'L':
                  ip = &leftedge;
                  break;
               case 'r':
               case 'R':
                  if (req_cnt == 9) {
                     printf("Too many requester definitions!\n");
                     exit(20);
                  }
                  k = OPT_REQ;
                  reqs[++req_cnt].f = 0;
                  for (++j; argv[i][j]; ++j) {
                     switch(argv[i][j]) {
                        case 'l':
                        case 'L':
                           reqs[req_cnt].f |= F_LEFT;
                           break;
                        case 'r':
                        case 'R':
                           reqs[req_cnt].f |= F_RIGHT;
                           break;
                        case 't':
                        case 'T':
                           reqs[req_cnt].f |= F_TASKHELD;
                           break;
                        default:
                           printf("Invalid option '%c' after -r ignored!\n",
                                 argv[i][j]);
                     }
                  }
                  if (!(reqs[req_cnt].f & F_TASKHELD)) {
                     if (argc - i - 7 < 0) {
                        printf("Missed arguments after -r!\n");
                        exit(20);
                     }
                     if (!(reqs[req_cnt].w = atoi(argv[++i])))
                        reqs[req_cnt].f |= F_CALCWIDTH;
                     for (l = 0; l < 5; ++l)
                        ((char **)&reqs[req_cnt].l1)[l] = argv[++i];
                     k |= 512;
                  }
                  --j;
                  break;
               case 's':
               case 'S':
                  k = OPT_SIXTY;
                  break;
               case 't':
               case 'T':
                  ip = &topedge;
                  break;
               case 'y':
               case 'Y':
                  ip = &yadd;
                  break;
               default:
                  printf("Invalid option '%c' ignored.\n",argv[i][j]);
                  k = 0;
            }
            if (k & 256) {
               if (!argv[++i]) {
                  printf("Missed parameter after option -%c!\n",
                        argv[i - 1][j]);
                  exit(20);
               }
               *ip = atoi(argv[i]);
               argv[i] = 0;
               opt |= (k & ~256);
               break;
            }
            opt |= k;
            if (k & 512) break;
         }
      }
   }
   if (name) {
      opt |= OPT_ALERT;
      if (fp = fopen(name,"r")) {
         fseek(fp,0L,2);
         if (buf = malloc((size = ftell(fp)) + 1)) {
            fseek(fp,0L,0);
            fread(buf,1,size,fp);
            fclose(fp);
            buf[size] = 0;
            for (i = 0, lin_cnt = 0; buf[i]; ++i)
               if (buf[i] == '\n') {
                  ++lin_cnt;
                  buf[i] = 0;
               }
            if (as = malloc(size + (lin_cnt << 2))) {
               for (cp = as,i = j = 0; i < lin_cnt; ++i) {
                  if (i) *cp++ = 0xff;
                  *cp++ = (k = opt & OPT_CENTERED ? (320 -
                        (strlen(&buf[j]) * (opt & OPT_SIXTY ? 5 : 4))) :
                        leftedge) >> 8;
                  *cp++ = k & 255;
                  *cp++ = i * yadd + topedge + 6;
                  while (buf[j]) *cp++ = buf[j++];
                  ++j;
                  *cp++ = 0;
               }
               *cp++ = 0;
               free(buf);
            } else {
               printf("Not enough memory for the alert string!\n");
               exit(20);
            }
         } else {
            printf("Not enough memory for the file buffer!\n");
            exit(20);
         }
      } else {
         printf("Unable to open '%s' for reading!\n",name);
         exit(20);
      }
   }
   if (IntuitionBase = OpenLibrary("intuition.library",0L)) {
      Enable_Abort = 0;
      if (opt & OPT_REQ)
         for (i = 0; i <= req_cnt; i = (i == req_cnt) ? req_cnt : i + 1) {
            if (reqs[i].f & F_TASKHELD) {
               sysreq_width = 0;
               rc = make_req("Software error - task held",
                     " Finish ALL disk activity",
                     "Select CANCEL to reset/debug","Retry","Cancel");
            } else {
               if ((k = strlen(reqs[i].l1)) < (l = strlen(reqs[i].l2)))
                  k = l;
               if (k < (l = strlen(reqs[i].l3))) k = l;
               sysreq_width = reqs[i].f & F_CALCWIDTH ? (k << 3) + 52 :
                     reqs[i].w;
               rc = make_req(reqs[i].l1,reqs[i].l2,reqs[i].l3,reqs[i].l,
                     reqs[i].r);
            }
            rc = rc ? 5 : 0;
            if ((reqs[i].f & F_LEFT && rc) || (reqs[i].f & F_RIGHT && !rc) ||
                  Chk_Abort())
               break;
         }
      aw = IntuitionBase[13];
      if (opt & OPT_ALERT) {
         GetPrefs(&prefbuf_s,118L);
         for (i = 0; i < 59; ++i) prefbuf_n[i] = prefbuf_s[i];
         *(char *)prefbuf_n = opt & OPT_SIXTY ? 9 : 8;
         if (opt & OPT_DARK) {
            for (i = 14; i < 59; ++i) prefbuf_n[i] = 0;
            prefbuf_n[55] = opt & OPT_BLINK ? prefbuf_s[55] : 0x111;
         }
         if (opt & OPT_BLINK) {
            Forbid();
            *(char *)0xbfe001 |= 2;
            for (i = 12; i; --i) {
               for (j = -1; j; --j);
               for (j = 41000; j; --j);
               chg_led();
            }
            Permit();
         }
         SetPrefs(prefbuf_n,118L,0L);
         if ((opt & OPT_DARK) && !(sp = OpenScreen(&ns))) {
            puts("Unable to open a dark screen!");
            CloseLibrary(IntuitionBase);
            exit(20);
         }
         if (opt & OPT_BLINK) {
            col_map = sp[12];
            col_tab = col_map[1];
            for (i = 0; i < sizeof(cols) / sizeof(short); ++i) {
               for (j = -1; j; --j);
               if (i) for (j = -1; j; --j);
               if ((*col_tab = cols[i]) == 0x888) chg_led();
               RemakeDisplay();
            }
         }
         if (DisplayAlert(0L,as,(long)(opt & OPT_HEIGHT ? height :
               topedge * 2 + yadd * (lin_cnt - 1) + 9))) rc = 5;
         if (opt & OPT_DEADEND) {
            SuperState();
            (*((void (*)())0xfc0002))();
         }
         SetPrefs(prefbuf_s,118L,0L);
         if (sp) CloseScreen(sp);
         free(as);
      }
      if (aw) ActivateWindow(aw);
      CloseLibrary(IntuitionBase);
      Enable_Abort = 1;
   } else {
      puts("Unable to open the 'intuition.library'!");
      exit(20);
   }
   exit(rc);
}
