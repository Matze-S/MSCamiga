
/*
**  menustructs.c
**
**  includes the structures for the filerequester-menu.
*/

struct IntuiText itemtext3 = {
   0,1,JAM1,0,0,NULL,(STRPTR)"Quit",NULL
};
struct IntuiText itemtext2 = {
   0,1,JAM2,0,0,NULL,(STRPTR)"Save",NULL
};
struct IntuiText itemtext1 = {
   0,1,JAM2,0,0,NULL,(STRPTR)"Load",NULL
};
struct MenuItem item3 = {
   NULL,0,18,80,8,ITEMTEXT|HIGHCOMP|ITEMENABLED|COMMSEQ,0,
   (APTR)&itemtext3,NULL,'Q',NULL,0
};
struct MenuItem item2 = {
   &item3,0,9,80,8,ITEMTEXT|HIGHCOMP|ITEMENABLED|COMMSEQ,0,
   (APTR)&itemtext2,NULL,'S',NULL,0
};
struct MenuItem item1 = {
   &item2,0,0,80,8,ITEMTEXT|HIGHCOMP|ITEMENABLED|COMMSEQ,0,
   (APTR)&itemtext1,NULL,'L',NULL,0
};
struct Menu menu = {
   NULL,10,0,64,10,MENUENABLED,"Project",&item1
};
