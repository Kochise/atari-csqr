; /// VIDEL REGISTERS SCANNER - KOSS 1999 ///

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

	pea	VidelScan
	move.w	#$26,-(SP)	; - SUPEXEC -
	trap	#14	; *** XBIOS ***
	addq.l	#6,SP
		
	lea	OSTNL,A0
	lea	VidelFileData,A1
	lea	VidelTextBank,A3
	
	move.w	#20,D7
	
FileStruct	lea	TKR_NumBuffer,A2
	clr.l	(A2)+
	clr.l	(A2)+
	clr.w	(A2)+

	BSR	TKRFiller
	
	DBF	D7,FileStruct	
	
	clr.w	-(SP)
	pea	VidelFileName
	move.w	#$3C,-(SP)	; - F_CREATE -
	trap	#1	; *** GEMDOS ***
	addq.l	#8,SP
	
	move.w	D0,D7
	
	lea	VidelFileData,A0
	clr.l	D0
	
ScanLoop	move.b	(A0)+,D1
	BEQ	ScanEnd
	
	addq.l	#1,D0
	
	BRA	ScanLoop

ScanEnd	pea	VidelFileData
	move.l	D0,-(SP)
	move.w	D7,-(SP)
	move.w	#$40,-(SP)	; - F_WRITE -
	trap	#1	; *** GEMDOS ***
	lea	(12,SP),SP
	
	move.w	D7,-(SP)
	move.w	#$3E,-(SP)	; - F_CLOSE -
	trap	#1	; *** GEMDOS ***
	addq.l	#4,SP

	move.w	D0,-(SP)
	move.w	#$4C,-(SP)	; - P_TERM -
	trap	#1	; *** GEMDOS ***

VidelScan	move.w	#-1,$FFFF82C0.w
	move.w	#-1,$FFFF82C2.w
	
	move.w	#-1,$FFFF820E.w
	move.w	#-1,$FFFF8210.w
	move.w	#-1,$FFFF8260.w
	move.b	#-1,$FFFF8265.w
	move.w	#-1,$FFFF8266.w
	move.w	#-1,$FFFF8282.w
	move.w	#-1,$FFFF8284.w
	move.w	#-1,$FFFF8286.w
	move.w	#-1,$FFFF8288.w
	move.w	#-1,$FFFF828A.w
	move.w	#-1,$FFFF828C.w
	move.w	#-1,$FFFF828E.w
	move.w	#-1,$FFFF8290.w
	move.w	#-1,$FFFF82A2.w
	move.w	#-1,$FFFF82A4.w
	move.w	#-1,$FFFF82A6.w
	move.w	#-1,$FFFF82A8.w
	move.w	#-1,$FFFF82AA.w
	move.w	#-1,$FFFF82AC.w

	move.w	$FFFF820E.w,OSTNL
	move.w	$FFFF8210.w,VWRAP
	move.w	$FFFF8260.w,STSHIFT
	move.b	$FFFF8265.w,HSR
	move.w	$FFFF8266.w,SPSHIFT
	move.w	$FFFF8282.w,HHT
	move.w	$FFFF8284.w,HBB
	move.w	$FFFF8286.w,HBE
	move.w	$FFFF8288.w,HDB
	move.w	$FFFF828A.w,HDE
	move.w	$FFFF828C.w,HSS
	move.w	$FFFF828E.w,HFS
	move.w	$FFFF8290.w,HEE
	move.w	$FFFF82A2.w,VFT
	move.w	$FFFF82A4.w,VBB
	move.w	$FFFF82A6.w,VBE
	move.w	$FFFF82A8.w,VDB
	move.w	$FFFF82AA.w,VDE
	move.w	$FFFF82AC.w,VSS
	move.w	$FFFF82C0.w,RCO
	move.w	$FFFF82C2.w,VCO

	RTS

TKRFiller	BSR	TKR_DCW
	
	clr.l	D6
	clr.l	D0
	move.w	(A0)+,D6

	tst.l	D6	; La m‚moire … garder
	BNE	TKR_Memory	; Y'a
	
	move.b	#"0",(A1)+	; 0
		
	BRA	TKR_Ending

TKR_Memory	move.l	D6,D1	; Yops...
	lea	TKR_Buffer,A2
	
TKR_DecDigit	divu.l	#10,D0:D1	; En D0, le Reste (unit‚)
			; En D1, le Quotient
	
	cmpi.l	#10,D1	; On arrive … la fin?
	BLT	TKR_LastDigit
	
	move.b	D0,-(A2)	; On place le Reste
	clr.l	D0	; On efface pour ne pas influencer
			; le calcul suivant
	
	BRA	TKR_DecDigit
	
TKR_LastDigit	move.b	D0,-(A2)	; On place la derniŠre unit‚e
	move.b	D1,-(A2)	; On place la derniŠre dizaine en d‚but

	move.w	#9,D0	; Nombre maximum de chiffres
			; significatifs … corriger
	lea	TKR_NumBuffer,A2
	
TKR_ASCII	add.b	#$30,(A2)+	; On corrige la taille
	DBF	D0,TKR_ASCII
	
	move.w	#9,D1	; Idem … propos des chiffres
	lea	TKR_NumBuffer,A2
	
TKR_StartNum	move.b	(A2)+,D0
	cmpi.b	#"0",D0
	BNE	TKR_LockNum	; On a trouv‚ le d‚but du nombre,
			; en se passant des "0" du d‚but
	
	DBF	D1,TKR_StartNum
	
TKR_LockNum	subq.l	#1,A2	; On se place juste avant

TKR_CopyNum	move.b	(A2)+,(A1)+
	DBF	D1,TKR_CopyNum	; On utilise le reste du DBF pr‚c‚dent
			
TKR_Ending	BSR	TKR_Copy	; On complete

	BSR	TKR_EOL

	RTS
	
TKR_DCW	move.l	#$0964632E,(A1)+
	move.w	#$7709,(A1)+
	
	RTS
	
TKR_EOL	move.w	#$0D0A,(A1)+

	RTS
	
TKR_Copy	move.b	(A3)+,(A1)+
	BNE	TKR_Copy
	
	subq.l	#1,A1
	
	RTS

	SECTION	DATA
	
VidelFileName	dc.b	"\VIDEL.DAT",0

VidelDCB	dc.b	9,"dc.w",9,0

VidelTextBank	dc.b	9,"; OSTNL",0
	dc.b	9,"; VWRAP",0
	dc.b	9,"; STSHIFT",0
	dc.b	9,"; HSR",0
	dc.b	9,"; SPSHIFT",0
	dc.b	9,"; HHT",0
	dc.b	9,"; HSS",0
	dc.b	9,"; HBE",0
	dc.b	9,"; HDB",0
	dc.b	9,"; HDE",0
	dc.b	9,"; HBB",0
	dc.b	9,"; HFS",0
	dc.b	9,"; HEE",0
	dc.b	9,"; VFT",0
	dc.b	9,"; VSS",0
	dc.b	9,"; VBE",0
	dc.b	9,"; VDB",0
	dc.b	9,"; VDE",0
	dc.b	9,"; VBB",0
	dc.b	9,"; RCO",0
	dc.b	9,"; VCO",0

	SECTION	BSS
	
OSTNL	ds.w	1
VWRAP	ds.w	1
STSHIFT	ds.w	1
preHSR	ds.b	1
HSR	ds.b	1
SPSHIFT	ds.w	1
HHT	ds.w	1
HSS	ds.w	1
HBE	ds.w	1
HDB	ds.w	1
HDE	ds.w	1
HBB	ds.w	1
HFS	ds.w	1
HEE	ds.w	1
VFT	ds.w	1
VSS	ds.w	1
VBE	ds.w	1
VDB	ds.w	1
VDE	ds.w	1
VBB	ds.w	1
RCO	ds.w	1
VCO	ds.w	1

TKR_NumBuffer	ds.b	10
TKR_Buffer	ds.w	1

VidelFileData	ds.b	5000