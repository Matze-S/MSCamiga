
#define radius ((double)1.0)

extern void printf();
extern double sqrt();

main()
{
   double length,halflength,help1,help2,count;

   length = radius * sqrt((double)2.0);
   count = 2.0;
   do {
      halflength = length / ((double)2.0);
      help1 = halflength * halflength;
      help2 = radius - sqrt(radius * radius - help1);
      length = sqrt(help1 + help2 * help2);
      count *= 2.0;
   } while (length != halflength);
   printf(" pi = %.14lf\n",length * count);
}
