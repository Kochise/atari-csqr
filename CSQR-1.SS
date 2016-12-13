; /// ATARI Falcon030 NearTrueColor Displayer - KOSS 1997-1999 ///

	comment	HEAD=7

; *****************************************************************************
	SECTION	TEXT
; *****************************************************************************

	movea.l	(4,SP),A6	; ADDR PROG BLOCK START (BASEPAGE)
	move.l	(12,A6),D0	; SIZE SECTION TEXT
	add.l	(20,A6),D0	; SIZE SECTION DATA +
	add.l	(28,A6),D0	; SIZE SECTION BSS  +
	addi.l	#$100,D0	; SIZE BASEPAGE     +
	addi.l	#$400,D0	; SIZE NEW STACK    +
	move.l	D0,D1	; SIZE PROG BLOCK   =
	move.l	D0,D7
	add.l	A6,D1	; ADDR PROG BLOCK END (NEW STACK BLOCK END)
	andi.l	#-2,D1	; ADDR PROG BLOCK END (EVEN ADDR)              
	subq.l	#8,D1	; ADDR NEW STACK BLOCK END - 8 (NEW STACK POINTER START)
	move.l	(4,SP),D2	; ADDR PROG BLOCK START SAVE (BASEPAGE)
	movea.l	D1,SP	; ADDR NEW STACK POINTER START INSTALL
	move.l	D2,(4,SP)	; ADDR PROG BLOCK START RESTORE (BASEPAGE)
	move.l	D0,-(SP)	; SIZE PROG BLOCK RESERVE
	move.l	A6,-(SP)	; ADDR PROG BLOCK START RESERVE
	clr.w	-(SP)	; RESERVED
	move.w	#$4A,-(SP)	; - M_SHRINK -
	TRAP	#1	; *** GEMDOS ***
	lea	(12,SP),SP

	tst	D0	; Si D0<>0, problŠme grave
	BNE	P_Term

	move.w	#89,-(SP)	; - MON_TYPE -
	trap	#14	; *** XBIOS ***
	addq.l	#2,SP
	
	lea	MonJump,A0
	JMP	([A0,D0.w*4])
	
MonJump	dc.l	P_Term	; Monochrome
	dc.l	RGB_Mon	; Couleur ST
	dc.l	VGA_Mon	; VGA
	dc.l	RGB_Mon	; TV
	
RGB_Mon	BSR	SaveScreen

	andi.w	#%110000,D0
	ori.w	#%100000100,D0	; 320*400*NTC

	move.l	#64000-1,SizeScreen

	cmp.w	D0,D1
	BEQ	LetScreen
	
	BSR	NewScreen
	
	BRA	LaunchColors
	
VGA_Mon	BSR	SaveScreen

	andi.w	#%110000,D0
	ori.w	#%100,D0	; 320*480*NTC
	
	move.l	#76800-1,SizeScreen
	
	cmp.w	D0,D1
	BEQ	LetScreen

	BSR	NewScreen
		
LaunchColors	; On efface l'‚cran

	move.l	#0,D0
	move.l	SizeScreen,D1
	move.l	ScreenAddr,A0
	
ClearScreen	move.l	D0,(A0)+

	subq.l	#1,D1
	BPL	ClearScreen

	; - Pr‚paration du Tableau de d‚placement -

	lea	Modulo,A0
	lea	Colors,A1
	lea	VCT_NewColorTable,A2
	move.l	ScreenAddr,A3
	lea	Rgb,A4

	moveq.w	#2,D0

VCT_NewColorBase	move.w	(A0,D0.w*2),D1
	move.w	(A2,D1.w*2),(A1,D0.w*2)	
	
	DBF	D0,VCT_NewColorBase
	
	; - Pr‚calculs des d‚placements -
	
	move.w	(0*2,A1),D2
	move.w	(1*2,A1),D3
	move.w	(2*2,A1),D4
	
	swap	D2
	swap	D3
	swap	D4

	clr.l	D1
	clr.l	D7
	move.w	(2*2,A0),D7
	move.w	(A4,D7.w*2),D7
	move.w	Largeur,D1
	mulu.l	D1,D7	; D7 == Base
	
	clr.l	D1
	clr.l	D6
	move.w	(1*2,A0),D6
	move.w	(A4,D6.w*2),D6
	move.w	D6,D1
	lsl.l	#1,D6	; D6 == DisBase2
	
	lsr.l	#5,D1
	moveq.l	#8,D5
	divu.w	D1,D5	; D5 == DisBase1
	
	move.w	(0*2,A0),D2
	move.w	(A4,D2.w*2),D2	
	subq.w	#1,D2	; D2 == CCount
	
VCT_NTCGouraud_Color	move.w	(2*2,A0),D4
	move.w	(A4,D4.w*2),D4	
	subq.w	#1,D4	; D4 == YCount

VCT_NTCGouraud_YAxis	move.w	(1*2,A0),D3
	move.w	(A4,D3.w*2),D3	
	subq.w	#1,D3	; D3 == XCount

	; - Calcul de la Couleur Gouraud pour commencer -

VCT_NTCGouraud_XAxis	move.w	D2,D1
	swap	D2
	mulu.w	D2,D1
	swap	D2
	move.w	D1,D0	; 1er calcul
	
	move.w	D3,D1
	swap	D3
	mulu.w	D3,D1
	swap	D3
	add.w	D1,D0	; 2Šme Calcul
	
	move.w	D4,D1
	swap	D4
	mulu.w	D4,D1
	swap	D4
	add.w	D1,D0	; 3Šme Calcul
	
	move.w	D0,-(SP)	; ColorNTC - OK
		
	; - Calcul de l'adresse, qui peut ˆtre optimis‚ -
		
	clr.l	D0
	clr.l	D1
	move.w	Largeur,D0
	move.w	D4,D1
	mulu.l	D1,D0	; YCount*Largeur

	move.w	D3,D1
	lsl.l	#1,D1	; XCount*2
	
	add.l	D1,D0
	movea.l	D0,A5
		
	clr.l	D0
	clr.l	D1
	move.w	D2,D0
	divu.l	D5,D1:D0
	move.l	D0,A6	; CCount/DisBase1
	mulu.l	D6,D1	; (CCount MOD DisBase1)*DisBase2

	move.l	A5,D0
	add.l	D1,D0

	move.l	A6,D1
	mulu.l	D7,D1	; (CCount/DisBase1)*Base
	
	add.l	D1,D0	; Pixel Address

	move.w	(SP)+,(A3,D0.l)

	DBF	D3,VCT_NTCGouraud_XAxis
	
	DBF	D4,VCT_NTCGouraud_YAxis
	
	DBF	D2,VCT_NTCGouraud_Color
		
;	move.w	#7,-(SP)	; - C_RAWCIN -
;	trap	#1	; *** GEMDOS ***
;	addq.l	#2,SP

;	BSR	OverlayChange

;	move.w	#7,-(SP)	; - C_RAWCIN -
;	trap	#1	; *** GEMDOS ***
;	addq.l	#2,SP
	
;	BSR	OverlayChange
	
	move.w	#7,-(SP)	; - C_RAWCIN -
	trap	#1	; *** GEMDOS ***
	addq.l	#2,SP

	cmpi.w	#-1,LetFlag
	BEQ	P_Term
	
	move.w	OldScreenMode,D0	
	BSR	NewScreen
	
	clr.w	D0

P_Term	move.w	D0,-(SP)
	move.w	#$4C,-(SP)	; - P_TERM -
	trap	#1	; *** GEMDOS ***

LetScreen	move.w	#-1,LetFlag

	BRA	LaunchColors

SaveScreen	move.w	#-1,-(SP)
	move.w	#88,-(SP)	; - VSETMODE -
	trap	#14	; *** XBIOS ***
	addq.l	#4,SP

	move.w	D0,OldScreenMode
	
	move.w	D0,D1
	
	RTS

NewScreen	move.w	D0,-(SP)
	move.w	#3,-(SP)
	clr.l	-(SP)
	clr.l	-(SP)
	move.w	#5,-(SP)	; - SETSCREEN -
	trap	#14	; *** XBIOS ***
	lea	(14,SP),SP
	
	move.w	#2,-(SP)	; - PHYSBASE -
	trap	#14	; *** XBIOS ***
	addq.l	#2,SP
	
	move.l	D0,ScreenAddr
	
	RTS

;OverlayChange	pea	OverFun
;	move.w	#$26,-(SP)	; - SUPEXEC -
;	trap	#14	; *** XBIOS ***
;	addq.l	#6,SP
	
;	RTS
	
;OverFun	bchg.b	#1,$FFFF8266.w

;	RTS

; *****************************************************************************
	SECTION	DATA
; *****************************************************************************

VCT_NewColorTable	dc.w	2048	; Rouge
	dc.w	32	; Vert
	dc.w	1	; Bleu

XDisplay	dc.w	320
YDisplay	dc.w	240
Largeur	dc.w	320*2	; XDisplay*2
Rgb	dc.w	32,64,32
Modulo	dc.w	2,1,0
	
; *****************************************************************************
	SECTION	BSS
; *****************************************************************************
	
Colors	ds.w	3
ScreenAddr	ds.l	1
OldScreenAddr	ds.l	1
OldScreenMode	ds.w	1
LetFlag	ds.w	1
SizeScreen	ds.l	1