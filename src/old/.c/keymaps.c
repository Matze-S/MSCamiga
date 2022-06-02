
#ifdef AZTEC_C
_wb_parse(){}
_cli_parse(){}
#endif

#include <exec/execbase.h>
#include <devices/keymap.h>
#include <stdio.h>

extern struct ExecBase *SysBase;

main()
{
   register struct KeyMapResource *kmr,*FindName();
   register struct KeyMapNode *kmn;

   if (kmr = FindName(&SysBase->ResourceList,"keymap.resource")) {
      puts("The system contains the following keymaps:");
      puts("------------------------------------------");
      for (kmn = (struct KeyMapNode *)kmr->kr_List.lh_Head;
               kmn->kn_Node.ln_Succ;
               kmn = (struct KeyMapNode *)kmn->kn_Node.ln_Succ)
         puts(kmn->kn_Node.ln_Name);
   }
}

