
/*
 * 'Dir'-Command (WB1.3) in C - Version 1.0
 *
 * Written at 15-Nov-88 by Matthias Schmidt
 * Copyright © 1988 by The Software Highlights
 *
 * Remark: This version don't know what to do with
 *         Wildcard-Patterns and with the Interactive-Mode !
 */

#include <libraries/dos.h>
#include <libraries/dosextens.h>
#include <ctype.h>

struct FileNode
{
struct FileNode *fn_Next;
char fn_Name[108];
};

#define OPTF_ALL 1
#define OPTF_DIRS 2
#define OPTF_FILES 4
#define OPTF_INTERACTIVE 8

char *malloc(),*calloc();
long Examine(),ExNext(),Lock(),CurrentDir();

char *Options[]={"OPT","ALL","FILES","DIRS","INTER"};
char OptDo[][2]={0,-1,OPTF_ALL,-1,0,~OPTF_DIRS,0,~OPTF_FILES,
   OPTF_INTERACTIVE,0};

short DirSpaces=0,Modes=OPTF_FILES|OPTF_DIRS;

main(argc,argv)
int argc;
char **argv;
{
   register char argcnt,mode=0,cnt,*charptr,*s=0;

   if (!strcmp("?",argv[1])&&argc==2) {
      printf("DIR,OPT/K,ALL/S,DIRS/S,FILES/S,INTER/S: ");
   } else {
      for (argcnt=1;argcnt<argc;argcnt++) {
         for (charptr=argv[argcnt];charptr<(strlen(argv[argcnt])+
               argv[argcnt]);charptr++) {
            if (islower(*charptr)) *charptr=_toupper(*charptr);
            if (mode) {
               switch (*charptr) {
                  case 'A':
                     Modes|=OPTF_ALL;
                     break;
                  case 'I':
                     Modes|=OPTF_INTERACTIVE;
                     break;
                  default:
                     printf("Option '%c' ignored.\n",*charptr);
               }        
            }
         }
         if (!mode) {
            for (cnt=0;cnt<(sizeof(Options)/(sizeof(char *)));cnt++)
               if (!strcmp(argv[argcnt],Options[cnt])) break;
            if (!cnt) mode=1;
            else if (cnt<5) Modes=(Modes|OptDo[cnt][0])&OptDo[cnt][1];
                 else if (s) {
                         printf("Bad arguments\n");
                         exit(0);
                      } else s=argv[argcnt];
         } else mode=0;
      }
   dir(s);
   }
}

prtspcs()
{
   register short cnt;
   for (cnt=0;cnt<DirSpaces;cnt++) printf("     ");
}

qsortstrcmp(a,b)
char **a,**b;
{
   return (strcmp(*a,*b));
}

dir(s)
register char *s;
{
   register short filecnt;
   register short usecnt;
   register struct FileInfoBlock *fib;
   register long lock,savelock;
   register struct FileNode *files_act,*files_strt;
   char **ptrs;

   if (fib=(struct FileInfoBlock *)malloc(sizeof(*fib))) {
      if (lock=Lock(s,ACCESS_READ)) {
         if (Examine(lock,fib)) {
            files_act=(struct FileNode *)&files_act;
            files_strt=0;
            filecnt=0;
            while (ExNext(lock,fib))
               if (fib->fib_DirEntryType<0) {
                  if (Modes & OPTF_FILES) {
                     if (files_act->fn_Next=(struct FileNode *)
                           calloc(sizeof(struct FileNode),1)) {
                        if (files_strt) files_act=files_act->fn_Next;
                        else files_strt=files_act;
                        strcpy(&files_act->fn_Name,&fib->fib_FileName);
                        filecnt++;
                     } else {
                        printf("Not enough heap-space!\n");
                        break;
                     }
                  }
               } else {
                  if (Modes & OPTF_DIRS) {
                     prtspcs();
                     printf("     %s (dir)\n",&fib->fib_FileName);
                  }
                  if (Modes & OPTF_ALL) {
                     DirSpaces++;
                     savelock=CurrentDir(lock);
                     dir(&fib->fib_FileName);
                     CurrentDir(savelock);
                  }
               }
            if (Modes & OPTF_FILES) {
               usecnt=0;
               if (ptrs=(char **)malloc(filecnt*sizeof(char *))) {
                  files_act=files_strt;
                  while (files_act) {
                     ptrs[usecnt++]=(char *)(&files_act->fn_Name);
                     files_act=files_act->fn_Next;
                  }
                  qsort(ptrs,filecnt,4,qsortstrcmp);
                  usecnt=-1;
                  filecnt=0;
                  while (files_strt) {
                     if (usecnt=~usecnt) printf("  %s\n",ptrs[filecnt++]);
                     else {
                        prtspcs();
                        printf("  %-31s",ptrs[filecnt++]);
                     }
                     files_act=files_strt;
                     files_strt=files_strt->fn_Next;
                     free(files_act);
                  }
                  free(ptrs);
                  if (!usecnt) printf("\n");
               }
            }
         }
         UnLock(lock);
      }
      free(fib);
   }
DirSpaces--;
}
