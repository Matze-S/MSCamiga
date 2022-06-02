
#include "shell.h"

static struct CommandLineInterface *cli = NULL;

init_cli()
{
   register struct CommandLineInterface *clip;
   register long *lp, l, *slp, *olp;
   register struct Process *pp,*wbpp;
   char *cp;

   if ((pp = (struct Process *)FindTask(NULL))->pr_CLI) return 1;
   if (cli = clip = (struct CommandLineInterface *)
            malloc(sizeof *clip + (78 * 4))) {
      lp = (long *)(clip + 1);
      for (l = 0; l < 78; ++l) lp[l] = 0L;
      lp[0] = (long)&lp[1] >> 2;
      lp[11] = (long)&lp[12] >> 2;
      lp[44] = (long)&lp[45] >> 2;
      lp[56] = (long)&lp[57] >> 2;
      clip->cli_Result2 = clip->cli_ReturnCode = clip->cli_Background = 0L;
      clip->cli_SetName = lp[56];
      *(cp = (char *)&lp[57]) = 4;
      clip->cli_CommandName = lp[11];
      clip->cli_FailLevel = 10L;
      clip->cli_Prompt = lp[0];
      *(cp = (char *)&lp[1]) = 4;
      strncpy(cp + 1,"%N> ",4);
      clip->cli_Interactive = IsInteractive(clip->cli_StandardInput =
            clip->cli_CurrentInput = (long)Input());
      clip->cli_CommandFile = lp[44];
      clip->cli_CurrentOutput = clip->cli_StandardOutput = (long)Output();
      clip->cli_DefaultStack = pp->pr_StackSize;
      clip->cli_Module = clip->cli_CommandDir = NULL;
      if ((wbpp = (struct Process *)FindTask("Workbench")) &&
               wbpp->pr_CLI && (lp = (long *)BADDR
               (((struct CommandLineInterface *)
               BADDR(wbpp->pr_CLI))->cli_CommandDir))) {
         olp = (long *)&clip->cli_CommandDir;
         do {
            if ((slp = (long *)AllocMem(12L,1L)) == NULL ||
                     (slp[2] = (long)DupLock(lp[1])) == NULL) {
               cleanup_cli();
               return 0;
            }
            slp[0] = 12L;
            slp[1] = 0L;
            *olp = (long)++slp >> 2;
            olp = slp;
         } while (lp = (long *)BADDR(lp[0]));
      }
      pp->pr_CLI = (BPTR)clip >> 2;
      return 1;
   } else
      return 0;
}

cleanup_cli()
{
   if (cli) {
      free_path();
      ((struct Process *)FindTask(NULL))->pr_CLI = NULL;
      free(cli);
      cli = NULL;
   }
}

free_path()
{
   register struct CommandLineInterface *clip =
         (struct CommandLineInterface *)BADDR(((struct Process *)
         FindTask(NULL))->pr_CLI);
   register long *slp, *lp = (long *)BADDR(clip->cli_CommandDir);

   while (slp = lp) {
      lp = (long *)BADDR(*slp);
      UnLock(slp[1]);
      FreeMem(--slp,12L);
   }
   clip->cli_CommandDir = NULL;
}
