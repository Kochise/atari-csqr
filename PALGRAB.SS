; ///  - KOSS 1999 ///

; WARNING : START  A7.l = 2
; BUG       OPCODE      move.B Dx,-(SP)
; REPORT    END    A7.l = 0, and NOT 1

	comment	HEAD=7
	
	SECTION	TEXT

	movea.l	(4,SP),A6	; Adresse de la BASEPAGE
	move.l	($C,A6),D0	; Taille du SEGMENT TEXT
	add.l	($14,A6),D0	; Additionne la taille du SEGMENT DATA … D0
	add.l	($1C,A6),D0	; Additionne la taille du SEGMENT BSS … D0
	addi.l	#$100,D0	; Additionne la taille de la BASEPAGE … D0
	addi.l	#$400,D0	; Additionne la taille de la future PILE (Ici, 256 positions longues (1024 OCTETS))
	move.l	D0,D1	; Copie D0 dans D1 (Taille … r‚server)
	move.l	D0,D7
	add.l	A6,D1	; Additionne l'adresse du d‚but du programme avec D1 (La taille … r‚server)
	andi.l	#-2,D1	; Rend D1 pair (Au cas o— il ne l'‚tait pas)
	subq.l	#8,D1	; Garde de la place pour l'adresse de la BASEPAGE
	move.l	(4,SP),D2	; Sauvegarde l'adresse de la BASEPAGE
	movea.l	D1,SP	; Installe l'adresse de fin du programme+place nouvelle PILE dans la PILE
	move.l	D2,(4,SP)	; R‚installe l'adresse de la BASEPAGE
	move.l	D0,-(SP)	; EmPILE la taille … r‚server
	move.l	A6,-(SP)	; EmPILE l'adresse du programme
	clr.w	-(SP)	; R‚serv‚
	move.w	#$4A,-(SP)	; - M_SHRINK -
	trap	#1	; *** GEMDOS ***
	lea	(12,SP),SP

	pea	PalGrab
	move.w	#$26,-(SP)	; - SUPEXEC -
	trap	#14	; *** XBIOS ***
	addq.l	#6,SP
	
	clr.w	-(SP)
	pea	PaletteName
	move.w	#$3C,-(SP)	; - F_CREATE -
	trap	#1	; *** GEMDOS ***
	addq.l	#8,SP
	
	move.w	D0,D7
	
	pea	STPalette
	move.l	#32+1024,-(SP)
	move.w	D0,-(SP)
	move.w	#$40,-(SP)	; - F_WRITE -
	trap	#1	; *** GEMDOS ***
	lea	(12,SP),SP
	
	move.w	D7,-(SP)
	move.w	#$3E,-(SP)	; - F_CLOSE -
	trap	#1	; *** GEMDOS ***
	addq.l	#4,SP

	clr.w	-(SP)
	trap	#1	; *** GEMDOS ***

PalGrab	lea	STPalette,A0
	move.l	#$FFFF8240,A1
	lea	FalconPalette,A2
	move.l	#$FFFF9800,A3
		
	move.w	#16-1,D0
STGrab	move.w	(A1)+,(A0)+
	DBF	D0,STGrab

	move.w	#256-1,D0
FalconGrab	move.l	(A3)+,(A2)+
	DBF	D0,FalconGrab
	
	RTS

	SECTION	DATA

PaletteName	dc.b	"D:\PAL.DAT",0
	
	SECTION	BSS
	
STPalette	ds.w	16
FalconPalette	ds.l	256