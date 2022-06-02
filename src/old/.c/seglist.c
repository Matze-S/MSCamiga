
#include <libraries/dosextens.h>
#include <libraries/filehandler.h>

extern struct DosLibrary *DOSBase;

char *btoc(b,t)
long b;
char *t;
{
   register char c,*s,*d;
   for (s = (char *)BADDR(b), c = *s++, d = t; c; --c) *d++ = *s++;
   *d = 0;        
   return (t);
}

main()
{
   register struct DeviceNode *dn;
   register char *p,l;
   char buf[100];

   dn = (struct DeviceNode *)BADDR(((struct DosInfo *)BADDR(((struct RootNode *)DOSBase->dl_Root)->rn_Info))->di_DevInfo);
   do {
      printf("Name: '%s'\n",btoc(dn->dn_Name,buf));
      if (strcmp("RAD",buf) == 0) {
         printf("SegList: $%06lx\n",dn->dn_SegList<<2);
         exit (0);
      }
   } while (dn = (struct DeviceNode *)BADDR(dn->dn_Next));
   printf("RAD not found !\n");
}
