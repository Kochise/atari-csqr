; ///  - KOSS 1999 ///

; WARNING : START  A7.l = 2
; BUG       OPCODE      move.B Dx,-(SP)
; REPORT    END    A7.l = 0, and NOT 1

	comment	HEAD=7
	
	SECTION	TEXT

	pea	Save
	move.w	#$26,-(SP)
	trap	#14
	addq.l	#6,SP

	moveq.w	#3,D7
	
VidelTest	pea	TestLoop
	move.w	#$26,-(SP)
	trap	#14
	addq.l	#6,SP

	move.w	#7,-(SP)
	trap	#1
	addq.l	#2,SP
	
	DBF	D7,VidelTest
	
	pea	Restore
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
	
	SECTION	BSS
	
Test	ds.w	1