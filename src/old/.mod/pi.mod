MODULE pi;

FROM	Terminal	IMPORT	WriteString,WriteLn;
FROM	LongRealInOut	IMPORT	WriteReal;
FROM	MathLibLong	IMPORT	sqrt;

VAR	length,halflength,help1,help2 :	LONGREAL;
	count :				LONGINT;

CONST	radius = 1.0;

BEGIN
	length := radius;
	count := 3;
	REPEAT
		halflength := length / 2.0;
		help1 := halflength * halflength;
		help2 := radius - sqrt(radius * radius - help1);
		length := sqrt(help1 + help2 * help2);
		count := count * 2;
	UNTIL length = halflength;
	WriteString(" pi := ");
	WriteReal(length * LONGREAL(count),-50,48);
	WriteLn;
END pi.
