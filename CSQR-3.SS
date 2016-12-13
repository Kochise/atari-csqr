; /// > NTC Color Square - KOSS 2001 < ///

	OPT	p=68030/68882
	comment	HEAD=7	; FastLoad

; --- EQUATE ASSEMBLY ---

;CSQR_EA_OVERLAY_DEMO
;CSQR_EA_DEBUG

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
;	dc.w	$0101	; ProgVERSION
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

	IFND CSQR_EA_DEBUG ; --------------------------------,
	
CSQR_TUI_CLR_SCR:	clr.l	(A0)+

	subq.l	#1,D1
	BPL	CSQR_TUI_CLR_SCR

	ENDC ; CSQR_EA_DEBU ----------------------------------'

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
	lea	CSQR_DDA_COLOR_SCALE,A1
	lea	CSQR_DDA_COLOR_LIMIT,A2

	move.w	(0*2,A0),D2	; C
	move.w	(1*2,A0),D3	; X
	move.w	(2*2,A0),D4	; Y
	
	move.w	(A2,D4.w*2),D5	; YC
	swap	D5
	swap	D4
	move.w	(A2,D3.w*2),D4	; XC
	swap	D4
	swap	D3
	move.w	(A2,D2.w*2),D3	; CC
	swap	D3
	
	move.w	(A1,D4.w*2),D4	; YS
	move.w	(A1,D3.w*2),D3	; XS
	move.w	(A1,D2.w*2),D2	; CS

	lea	CSQR_BDB_CCNT_MUL_CS,A0
	lea	CSQR_BDB_XCNT_MUL_XS,A1
	lea	CSQR_BDB_YCNT_MUL_YS,A2
	lea	CSQR_BDB_YCNT_MUL_SCRW,A3
	lea	CSQR_BDB_XCNT_MUL_2,A4
	lea	CSQR_BDB_COM_MUL_DBAS2,A5
	lea	CSQR_BDB_COM_MUL_BASE,A6

	; ccount&*color&(0)

	swap	D3
	move.w	D3,D0	; CC
	swap	D3
	
CSQR_TUI_CCNT_MUL_CS:	move.w	D0,D1
	lsl.w	D2,D1
	move.w	D1,(A0,D0.w*2)
	
	DBF	D0,CSQR_TUI_CCNT_MUL_CS

	; xcount&*color&(1)

	swap	D4
	move.w	D4,D0	; XC
	swap	D4

CSQR_TUI_XCNT_MUL_XS:	move.w	D0,D1
	lsl.w	D3,D1
	move.w	D1,(A1,D0.w*2)
	
	DBF	D0,CSQR_TUI_XCNT_MUL_XS
	
	; ycount&*color&(2)

	swap	D5
	move.w	D5,D0	; YC
	swap	D5

CSQR_TUI_XCNT_MUL_YS:	move.w	D0,D1
	lsl.w	D4,D1
	move.w	D1,(A2,D0.w*2)
	
	DBF	D0,CSQR_TUI_XCNT_MUL_YS
		
	; ycount*largeur

	clr.l	D0
	swap	D5
	move.w	D5,D0	; YC
	swap	D5
	clr.l	D6
	move.w	CSQR_DDA_SCR_WIDTH,D6
	
CSQR_TUI_YCNT_MUL_SCRW:	move.l	D6,D1
	mulu.l	D0,D1
	move.l	D1,(A3,D0.w*4)

	DBF	D0,CSQR_TUI_YCNT_MUL_SCRW

	; xcount*2

	swap	D4
	move.w	D4,D0	; XC
	swap	D4
	clr.l	D1

CSQR_TUI_XCNT_MUL_2:	move.w	D0,D1
	lsl.l	#1,D1
	move.l	D1,(A4,D0.w*4)
	
	DBF	D0,CSQR_TUI_XCNT_MUL_2
	
	; disbase1=256/X

	clr.l	D6
	swap	D4
	move.w	D4,D6	; XC
	swap	D4
	addq.w	#1,D6
	move.l	#256,D2
	divu.w	D6,D2

	; disbase2=X*2

	lsl.l	#1,D6

	; base=Y*largeur

	clr.l	D1
	clr.l	D7
	swap	D5
	move.w	D5,D7	; YC
	swap	D5
	addq.w	#1,D7
	move.w	CSQR_DDA_SCR_WIDTH,D1
	mulu.l	D1,D7

	; ccount MOD disbase1

	swap	D3
	move.w	D3,D5	; CC
	swap	D3
	
CSQR_TUI_COM_MUL_CALC:	clr.l	D0
	clr.l	D1
	move.w	D5,D0
	divu.l	D2,D1:D0

	; (ccount MOD disbase1)*disbase2
	mulu.l	D6,D1
	move.l	D1,(A5,D5.w*4)

	; (ccount MOD disbase1)*base
	mulu.l	D7,D0
	move.l	D0,(A6,D5.w*4)
	
	DBF	D5,CSQR_TUI_COM_MUL_CALC
	
; --- TEXT USER MAIN ---
	
	move.l	SP,CSQR_BDB_STACK_ADDR
	movea.l	CSQR_BDB_SCR_ADDR,SP

	; - Calcul de la Couleur Gouraud pour commencer -

; ccount&*color&(0)+xcount&*color&(1)+ycount&*color&(2)

	swap	D3
	move.w	D3,D2	; CC
	swap	D4
	move.w	D4,D3	; XC
	swap	D5
	move.w	D5,D4	; YC
	
	move.w	D2,D5	; CC

	; ycount
CSQR_TUM_COLOR_C_BLOCK:	move.w	D4,D7	; YC

	; xcount
CSQR_TUM_COLOR_Y_AXIS:	move.w	D3,D6	; XC

CSQR_TUM_COLOR_X_AXIS:	move.w	(A0,D5.w*2),D0	; ccount&*color&(0)
	or.w	(A1,D6.w*2),D0	; xcount&*color&(1)
	or.w	(A2,D7.w*2),D0	; ycount&*color&(2)
		
	; - Calcul de l'adresse, qui peut ˆtre optimis‚ -

; screen_adr%+xcount&*2+(ccount& MOD disbase1&)*disbase2&+INT(ccount& MOD disbase1&)*base%+ycount&*largeur&

	move.l	(A3,D7.w*4),D1	; ycount*largeur
	add.l	(A4,D6.w*4),D1	; xcount*2
	add.l	(A5,D5.w*4),D1	; (ccount MOD disbase1)*disbase2
	add.l	(A6,D5.w*4),D1	; (ccount MOD disbase1)*base
			
	move.w	D0,(A7,D1.l)

	DBF	D6,CSQR_TUM_COLOR_X_AXIS
	
	DBF	D7,CSQR_TUM_COLOR_Y_AXIS

	DBF	D5,CSQR_TUM_COLOR_C_BLOCK

	movea.l	CSQR_BDB_STACK_ADDR,SP

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
CSQR_BDB_STACK_ADDR:	ds.l	1

CSQR_BDB_CCNT_MUL_CS:	ds.w	64	
CSQR_BDB_XCNT_MUL_XS:	ds.w	64
CSQR_BDB_YCNT_MUL_YS:	ds.w	64
CSQR_BDB_YCNT_MUL_SCRW:	ds.l	64
CSQR_BDB_XCNT_MUL_2:	ds.l	64
CSQR_BDB_COM_MUL_DBAS2:	ds.l	64
CSQR_BDB_COM_MUL_BASE:	ds.l	64

; --- BSS FLAG BUFFER ---

CSQR_BFB_OLD_SCR_MODE:	ds.w	1
CSQR_BFB_SCR_UNCHG:	ds.w	1	
