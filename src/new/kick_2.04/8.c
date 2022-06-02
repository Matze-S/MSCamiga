
#define ECS_SPECIFIC

#include <exec/types.h>
#include <hardware/custom.h>
#include <graphics/monitor.h>
#include <stdio.h>

void main()
{
   printf("%08lx\n", VGA70_BEAMCON);
}

