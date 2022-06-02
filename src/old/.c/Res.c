
#include <exec/execbase.h>
#include <exec/resident.h>

extern struct ExecBase *SysBase;

main()
{
   register struct Resident *ptr,**resptr =
      (struct Resident **)SysBase->ResModules;

   printf(" -------- Name: --------  Priority:  Flags:  Version:  Init:\n");

   while (ptr = *resptr++) {
      printf("  %-21s     %4d      %3u      %3u    $%lx\n",
         ptr->rt_Name,(int)ptr->rt_Pri,(unsigned int)ptr->rt_Flags,
         (unsigned int)ptr->rt_Version,ptr->rt_Init);
   }
}
