
#define cmd "C:Dir"

main()
{
   char buffer[260];
   long bptr = (((long)buffer+3)&(~3))>>2,rc,seg,LoadSeg(),bcpl();

   if (seg = LoadSeg(cmd)) {
      rc = bcpl(0x1e4L,seg,4000L);
      bcpl(0x128L,bcpl(-0x7cL," --- returncode := %I3 ---\n",bptr),rc);
      UnLoadSeg(seg);
   } else
      bcpl(0x124L,bcpl(-0x7cL,"Cannot load program !\n",bptr));
}
