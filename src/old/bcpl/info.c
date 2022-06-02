/* Copyright (C) 1989 by Matthias Schmidt */

/*

      Info-Command in Aztec C with 'bcpl.lib'.

      #INIT=mc

*/

#include "bcpl.h"

/* main code */

long start(g)
struct globals g;
{
   register long *lp,*dp = ((long *)(root()[6] << 2)) + 1,i,j,
         *dps = dp,av[20],di[9],dnv[8],dn = ((long)dnv >> 2) | IS_BSTR;
   static char *states[] = {
      "Read Only","Validating","Read/Write"
   };

   rdargs("DEVICE",av,20L);
   if (av[0]) callgv(0x1acL,(long)dnv >> 2,(long)':',
         bstr(av[0],av[0] >> 2),1L);
   writes("\nMounted disks:\n");
   writes("Unit      Size    Used    Free Full Errs   Status   Name\n");
   doexec(-0x84L);
   while (dp = (long *)(*dp << 2))
      if (dp[1] || !dp[2] || (av[0] && stricmp(dp[10] | IS_BSTR,dn)) ||
               !dospkt(0L,dp[2],25L,TRUE,0L,(long)di >> 2)) continue;
      else {
         writef("%S:",dp[10] | IS_BSTR);
         for (i = *(unsigned char *)(dp[10] << 2); ++i < 10;
               wrch((long)' '));
         switch (di[6]) {
            case -1:
               lp = (long *)"No disk present\n";
               break;
            case 'NDOS':
               lp = (long *)"Not a DOS disk\n";
               break;
            case 'KICK':
               lp = (long *)"Kickstart disk\n";
               break;
            case 'DOS\0':
               if (dp[7] && (lp = (long *)(((long *)(dp[7] << 2))[2] << 2)))
                  i = (lp[10] - lp[9] + 1) * lp[3] * lp[5] * lp[1];
               else
                  i = di[3] * di[5] >> 2;
               if ((j = (i >>= 8) / 1000) >= 10) writef("%I3M",j);
               else if (j) writef("%N.%NM",j,(i % 1000) / 100);
               else writef("%I3K",i);
               writef("%I8%I8%I4%%%I4  %TB%S\n",di[4],di[3] - di[4],
                     di[4] * 100 / di[3],di[0],states[di[2] - 80],di[7] ?
                     ((long *)(di[7] << 2))[10] | IS_BSTR : 0L);
               continue;
            default:
               lp = (long *)"Unreadable disk\n";
         }
         writes(lp);
      }
   i = TRUE;
   dp = dps;
   while (dp = (long *)(*dp << 2))
      if (dp[1] != 2 || (av[0] && stricmp(dp[10] | IS_BSTR,dn)))
         continue;
      else {
         if (i) {
            writes("\nVolumes available:\n");
            i = FALSE;
         }
         writef("%S%S\n",dp[10] | IS_BSTR,dp[2] ? " [Mounted]" : 0L);
      }
   doexec(-0x8aL);
   return 0;
}

