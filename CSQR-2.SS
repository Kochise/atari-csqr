; /// > NTC Color Square - KOSS 2001 < ///

	OPT	p=68030/68882
	comment	HEAD=7	; FastLoad

; --- EQUATE ASSEMBLY ---

; CSQR_EA_OVERLAY_DEMO

; --- EQUATE DATA ---

CSQR_ED_DAY:	EQU	5	; Binary Date Format
CSQR_ED_MONTH:	EQU	8	;  FEDC BA98 7654 3210
CSQR_ED_YEAR:	EQU	2001	; %YYYY YYYM MMMD DDDD
CSQR_ED_DATE:	EQU	((CSQR_ED_YEAR-1980)<<9)|(CSQR_ED_MONTH<<5)|(CSQR_ED_DAY)

; --- EQUATE INDEX ---

; /////////////////////////////////////////////////////////////////////////////	
	SECTION	TEXT
; /////////////////////////////////////////////////////////////////////////////	
	
;	BRA	CSQR_TUI_START
	
;	dc.b	"ProgHEAD"	; ProgHEADER
;	dc.w	$0100	; ProgVERSION
;	dc.w	CSQR_ED_DATE	; ProgDATE
;	dc.b	"Color Square",0	; ProgNAME
;	dc.b	"Kochise",0	; ProgAUTHOR
	
	EVEN
	
; --- TEXT USER INIT ---
	
CSQR_TUI_START:	movea.l	(4,SP),A6	; ADDR PROG BLOCK START (BASEPAGE)
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

	tst.w	D0	; Si D0<>0, problŠme grave
	BNE	CSQR_TUE_PTERM

	move.w	#-1,-(SP)
	move.w	#88,-(SP)	; - VSETMODE -
	TRAP	#14	; *** XBIOS ***
	addq.l	#4,SP

	move.w	D0,CSQR_BFB_OLD_SCR_MODE
	move.w	D0,D6
	move.w	D0,D5
	andi.w	#%110000,D5
	
	move.w	#2,-(SP)	; - PHYSBASE -
	trap	#14	; *** XBIOS ***
	addq.l	#2,SP
	
	move.l	D0,CSQR_BDB_OLD_SCR_ADDR
	move.l	D0,CSQR_BDB_SCR_ADDR

	move.w	#89,-(SP)	; - MON_TYPE -
	TRAP	#14	; *** XBIOS ***
	addq.l	#2,SP
		
	lea	CSQR_DAT_MON_TYPE_JMP,A0
	JSR	([A0,D0.w*4])

	cmp.w	D5,D6
	SEQ	CSQR_BFB_SCR_UNCHG
	BEQ	CSQR_TUI_SCR_INIT
	
	move.w	D5,D6
	
	clr.w	-(SP)
	move.l	CSQR_BDB_SCR_SIZE,-(SP)
	move.w	#$44,-(SP)	; - M_XALLOC -
	TRAP	#1	; *** GEMDOS ***
	addq.l	#8,SP
			
	move.l	D0,CSQR_BDB_SCR_ADDR
	move.l	D0,D5

	BSR	CSQR_TUS_SCR_SET

CSQR_TUI_SCR_INIT:	move.l	CSQR_BDB_SCR_SIZE,D1
	move.l	CSQR_BDB_SCR_ADDR,A0
	
CSQR_TUI_CLR_SCR:	clr.l	(A0)+

	subq.l	#1,D1
	BPL	CSQR_TUI_CLR_SCR

	; - Pr‚paration du Tableau de d‚placement -

	move.w	#$11,-(SP)	; - RANDOM -
	TRAP	#14	; *** XBIOS ***
	addq.l	#2,SP
	
	andi.w	#%0000000000000111,D0
	cmpi.w	#5,D0
	BLE	CSQR_TUI_SET_POINTERS
	
	bclr.l	#1,D0

CSQR_TUI_SET_POINTERS:	lea	CSQR_DDA_COLOR_ORDER,A0
	lea	(A0,D0.w*8),A0
	lea	CSQR_BDB_COLOR_TABLE,A1
	lea	CSQR_DDA_COLOR_SCALE,A2
	lea	CSQR_DDA_COLOR_LIMIT,A3
	move.l	CSQR_BDB_SCR_ADDR,A4

	moveq.l	#2,D0

CSQR_TUI_CALC_COLOR:	move.w	(A0,D0.w*2),D1
	move.w	(A2,D1.w*2),(A1,D0.w*2)	
	
	DBF	D0,CSQR_TUI_CALC_COLOR
	
	; - Pr‚calculs des d‚placements -
	
	move.w	(0*2,A1),D2	; D2h == color(0)
	move.w	(1*2,A1),D3	; D3h == color(1)
	move.w	(2*2,A1),D4	; D4h == color(2)
	
	swap	D2
	swap	D3
	swap	D4

	; base%=rgb&(modulo&(2))*largeur&
	clr.l	D1
	clr.l	D7
	move.w	(2*2,A0),D7
	move.w	(A3,D7.w*2),D7
	addq.w	#1,D7
	move.w	CSQR_DDA_SCR_WIDTH,D1
	mulu.l	D1,D7	; D7 == Base
	
	; disbase2&=rgb&(modulo&(1))*2
	clr.l	D1
	clr.l	D6
	move.w	(1*2,A0),D6
	move.w	(A3,D6.w*2),D6
	addq.w	#1,D6
	move.w	D6,D1
	lsl.l	#1,D6	; D6 == DisBase2
	
	; disbase1&=8/(rgb&(modulo&(1))/32)
	lsr.l	#5,D1
	moveq.l	#8,D5
	divu.w	D1,D5	; D5 == DisBase1
	
	; ccount
	move.w	(0*2,A0),D2
	move.w	(A3,D2.w*2),D2	; D2l == ccount

; --- TEXT USER MAIN ---

	; ycount
CSQR_TUM_COLOR_SECTOR:	move.w	(2*2,A0),D4
	move.w	(A3,D4.w*2),D4	; D4l == ycount

	; xcount
CSQR_TUM_COLOR_Y_AXIS:	move.w	(1*2,A0),D3
	move.w	(A3,D3.w*2),D3	; D3l == xcount

	; - Calcul de la Couleur Gouraud pour commencer -

; ccount&*color&(0)+xcount&*color&(1)+ycount&*color&(2)


CSQR_TUM_COLOR_X_AXIS:	move.w	D2,D1
	swap	D2
	lsl.w	D2,D1
	swap	D2
	move.w	D1,D0	; ccount&*color&(0)
	
	move.w	D3,D1
	swap	D3
	lsl.w	D3,D1
	swap	D3
	or.w	D1,D0	; +xcount&*color&(1)
	
	move.w	D4,D1
	swap	D4
	lsl.w	D4,D1
	swap	D4
	or.w	D1,D0	; +ycount&*color&(2)
	
	move.w	D0,-(SP)	; ColorNTC - OK
		
	; - Calcul de l'adresse, qui peut ˆtre optimis‚ -

; screen_adr%+xcount&*2+(ccount& MOD disbase1&)*disbase2&+INT(ccount& MOD disbase1&)*base%+ycount&*largeur&
		
	clr.l	D0
	clr.l	D1
	move.w	CSQR_DDA_SCR_WIDTH,D0
	move.w	D4,D1
	mulu.l	D1,D0	; ycount*largeur

	move.w	D3,D1
	asl.l	#1,D1
	add.l	D1,D0 	; +xcount*2
	movea.l	D0,A5	; =ycount*largeur+xcount*2
		
	clr.l	D0
	clr.l	D1
	move.w	D2,D0
	divu.l	D5,D1:D0
	move.l	D0,A6	; ccount MOD disbase1
	mulu.l	D6,D1	; *disbase2

	move.l	A5,D0	; ycount*largeur+xcount*2
	add.l	D1,D0	; +(ccount MOD disbase1)*disbase2

	move.l	A6,D1	; ccount MOD disbase1
	mulu.l	D7,D1	; *base
	
	add.l	D1,D0	; Pixel Address

	move.w	(SP)+,(A4,D0.l)

	DBF	D3,CSQR_TUM_COLOR_X_AXIS
	
	DBF	D4,CSQR_TUM_COLOR_Y_AXIS
	
	DBF	D2,CSQR_TUM_COLOR_SECTOR

	IFD CSQR_EA_OVERLAY_DEMO ; ---------------------------,

	BSR	CSQR_TUS_C_RAWCIN
	BSR	CSQR_TUS_OBIT_CHG_CALL
	BSR	CSQR_TUS_C_RAWCIN
	BSR	CSQR_TUS_OBIT_CHG_CALL

	ENDC ; CSQR_EA_OVERLAY_DEMO --------------------------'

	BSR	CSQR_TUS_C_RAWCIN
	
; --- TEXT USER EXIT ---
	
	clr.w	D0

	tst.b	CSQR_BFB_SCR_UNCHG
	BNE	CSQR_TUE_PTERM

	move.w	CSQR_BFB_OLD_SCR_MODE,D6
	move.l	CSQR_BDB_OLD_SCR_ADDR,D5

	BSR	CSQR_TUS_SCR_SET	

	move.l	CSQR_BDB_SCR_ADDR,-(SP)
	move.w	#$49,-(SP)	; - M_FREE -
	TRAP	#1	; *** GEMDOS ***
	addq.l	#6,SP

CSQR_TUE_PTERM:	move.w	D0,-(SP)
	move.w	#$4C,-(SP)	; - P_TERM -
	TRAP	#1	; *** GEMDOS ***

; --- TEXT USER SUB ---

CSQR_TUS_RGB_MON_INIT:	ori.w	#%100000100,D5	; 320*400*NTC

	move.l	#64000-1,CSQR_BDB_SCR_SIZE

	RTS
	
CSQR_TUS_VGA_MON_INIT:	ori.w	#%100,D5	; 320*480*NTC
	
	move.l	#76800-1,CSQR_BDB_SCR_SIZE
	
	RTS

CSQR_TUS_SCR_SET:	move.w	D6,-(SP)
	move.w	#3,-(SP)
	move.l	D5,-(SP)
	move.l	D5,-(SP)
	move.w	#5,-(SP)	; - SETSCREEN -
	TRAP	#14	; *** XBIOS ***
	lea	(14,SP),SP
	
	RTS

CSQR_TUS_C_RAWCIN:	move.w	#7,-(SP)	; - C_RAWCIN -
	trap	#1	; *** GEMDOS ***
	addq.l	#2,SP

	RTS

	IFD CSQR_EA_OVERLAY_DEMO ; ---------------------------,
	
CSQR_TUS_OBIT_CHG_CALL:	pea	CSQR_TSS_OBIT_CHG
	move.w	#$26,-(SP)	; - SUPEXEC -
	trap	#14	; *** XBIOS ***
	addq.l	#6,SP
	
	RTS

; --- TEXT SUPER SUB ---

CSQR_TSS_OBIT_CHG:	bchg.b	#1,$FFFF8266.w

	RTS

	ENDC ; CSQR_EA_OVERLAY_DEMO --------------------------'
	
; /////////////////////////////////////////////////////////////////////////////	
	SECTION	DATA
; /////////////////////////////////////////////////////////////////////////////	
	
; --- DATA ADDRESS TABLE ---
	
CSQR_DAT_MON_TYPE_JMP:	dc.l	CSQR_TUE_PTERM	; Monochrome
	dc.l	CSQR_TUS_RGB_MON_INIT	; Couleur ST
	dc.l	CSQR_TUS_VGA_MON_INIT	; VGA
	dc.l	CSQR_TUS_RGB_MON_INIT	; TV
	
; --- DATA DEFINED ARRAY ---

CSQR_DDA_COLOR_ORDER:	dc.w	0,1,2,0
	dc.w	0,2,1,0
	dc.w	1,0,2,0
	dc.w	1,2,0,0
	dc.w	2,0,1,0
	dc.w	2,1,0,0
CSQR_DDA_COLOR_SCALE:	dc.w	11,5,0	; RGB
CSQR_DDA_COLOR_LIMIT:	dc.w	31,63,31	; RGB
CSQR_DDA_SCR_WIDTH:	dc.w	320*2
	
; /////////////////////////////////////////////////////////////////////////////	
	SECTION	BSS
; /////////////////////////////////////////////////////////////////////////////	

; --- BSS DATA BUFFER ---

CSQR_BDB_OLD_SCR_ADDR:	ds.l	1
CSQR_BDB_SCR_ADDR:	ds.l	1
CSQR_BDB_SCR_SIZE:	ds.l	1
CSQR_BDB_COLOR_TABLE:	ds.w	3

; --- BSS FLAG BUFFER ---

CSQR_BFB_OLD_SCR_MODE:	ds.w	1
CSQR_BFB_SCR_UNCHG:	ds.w	1	
