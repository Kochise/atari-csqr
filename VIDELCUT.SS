; /// VIDEL CUT - KOSS 1999 ///

	comment	HEAD=7
	
	SECTION	TEXT

	pea	Save
	move.w	#$26,-(SP)
	trap	#14
	addq.l	#6,SP
	
	moveq.w	#3,D7
	
	pea	TestLoop
	move.w	#$26,-(SP)
	trap	#14
	addq.l	#6,SP

KeysLoop	move.w	#7,-(SP)
	trap	#1
	addq.l	#2,SP
	
	swap	D0
	
	cmpi.w	#1,D0
	BEQ	Exit
	
	cmpi.w	#$3B,D0
	BGE	FirstHalfPass
	
	BRA	KeysLoop
	
FirstHalfPass	cmpi.w	#$54,D0
	BGE	SecondHalfPass
	
	cmpi.w	#$44,D0
	BLE	FirstMETADOS
	
	BRA	KeysLoop
	
FirstMETADOS	subi.w	#$3B-1,D0
	
	BRA	METADOS

SecondHalfPass	cmpi.w	#$5D,D0
	BLE	SecondMETADOS
	
	BRA	KeysLoop
	
SecondMETADOS	subi.w	#$54-11,D0

METADOS	move.w	D0,D7

	move.w	#-1,-(SP)
	move.w	#11,-(SP)	; - KBSHIFT -
	trap	#13	; *** BIOS ***
	addq.l	#4,SP
	
	btst.l	#2,D0
	BEQ	DirectMeta

	add.w	#20,D7

DirectMeta	move.b	D7,TrackNumber

	pea	TrackNumber
	move.w	#$4304,-(SP)
	move.l	#"FCTL",-(SP)
	move.w	#$41,-(SP)
	move.w	#$37,-(SP)
	trap	#14
	lea	(14,SP),SP

	BRA	KeysLoop
		
Exit	pea	Restore
	move.w	#$26,-(SP)
	trap	#14
	addq.l	#6,SP

	clr.w	-(SP)
	trap	#1	; *** GEMDOS ***

Save	move.w	$FFFF82C2.w,Test
	
	RTS
	
TestLoop	move.w	$FFFF82C2.w,D0
	
	move.w	D7,D1
	lsl.w	#2,D1
	andi.w	#3,D0
	or.w	D1,D0
	move.w	D0,$FFFF82C2.w
	
	RTS
	
Restore	move.w	Test,$FFFF82C2.w

	RTS
	
	SECTION	DATA
	
TrackNumber	dc.b	0,1,$63,1  
	
	SECTION	BSS
	
Test	ds.w	1