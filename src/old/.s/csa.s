
; 
; Verbesserte Datensatz/Speichern (Amiga + 'S') - Funktion für
; Superbase Professional 3.02.
; Die zu ändernden Daten liegen im 73. Segment, Offset 0xf8a.
;
; by 'Top Secret!' of SHADOW 22:30 13-Mar-90
;
; Org-Words:
;  0cad 0000 018f ffc4 6622 2f3c 0000 1001 7000 2f00 2f00 2f00
;

	move.w	#(-1),$547c(a6)
	cmp.w	#$18f,-$3a(a5)
	bne.s	*+$20
	pea.l	($1001).w
	clr.l	-(sp)
	clr.l	-(sp)
	clr.l	-(sp)

