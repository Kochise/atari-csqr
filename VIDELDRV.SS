; /// VIDEL Driver - KOSS 1999 ///

; WARNING : START  A7.l = 2
; BUG       OPCODE      move.B Dx,-(SP)
; REPORT    END    A7.l = 0, and NOT 1

	comment	HEAD=7
	
; *****************************************************************************
	SECTION	TEXT
; *****************************************************************************
	
; --- Le Driver Videl ---

; /// Videl Control Registers - ZerkMan (c) 1995, Chris of AURA (c) 1995 & KOSS (c) 1999 ///
; WARNING : PARENTAL ADVISORY >> Ultra HOT CONTENT... Falcon & Videl EXPLICIT Informations !
;
; -_ CONTROL REGISTERS _-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
;
; MonitorType	b $FFFF8006.w	Bit 10
;		    00 Monochrome - SM124
;		    01 Color RGB  - SC1224 or SC1435
;		    10 Color VGA  -
;		    11 Color TV   -
;
;		TIPS : if MonitorType > 0, then Color
;		       if Bit 0=1, then Interlaced Possible
;		       if Bit 0=0, then Interlaced Impossible
;
; -----------------------------------------------------------------------------
;
; Screen Address	b $FFFF8201.w hi  byte	This address SHOULD be multiple of 4 !!
;	b $FFFF8203.w mid byte	WARNING : movep Instruction is FORBIDEN
;	b $FFFF820D.w low byte
;
; -----------------------------------------------------------------------------
;
; Screen Counter - Read	b $FFFF8205.w hi  byte
; Dynamic register	b $FFFF8207.w mid byte
;	b $FFFF8209.w low byte
;
; -----------------------------------------------------------------------------
;
; Sync Mode	b $FFFF820A.w 	Bit 10
;		    .0 Internal Synchronisation
;		    .1 External Synchronisation
;		    0  Monochrom Monitor Vertical Frequency
;		    1  Color     Monitor Vertical Frequency
; WARNING : NEVER touch these Bits !!!
;
; -----------------------------------------------------------------------------
;
; OSTNL	w $FFFF820E.w	OffSet to NextLine  IN WORD
;  9 Bits register		¯ OSTNL = VirtualLineWidth - DisplayedLineWidth
;  MaxValue : 1023 WORDs	On a 'Normal' screen (NonVirtualScreen),
;  Mono : 16368 pixels 		OSTNL is ALWAYS at 0 !
;  Med  :  8184 pixels
;  16c  :  4092 pixels		WARNING : Depend on the Videl HardWare !
;  256c :  2046 pixels		          NEVER less than 34 !!!
;  NTC  :  1023 pixels
;
; NOTE : This register is used for VirtualScreen
;
; -----------------------------------------------------------------------------
;
; VWrap	w $FFFF8210.w	Width of the DisplayedLine IN WORD
; 10 Bits register		¯ VWrap = DisplayedLineWidth
;  MaxValue : 2047 WORDs
;  Mono : 32752 pixels		WARNING : Depend on the Videl HardWare !
;  Med  : 16376 pixels		          NEVER less than 34 !!!
;  16c  :  8188 pixels
;  256c :  4094 pixels
;  NTC  :  2027 pixels
;
; -----------------------------------------------------------------------------
;
; ST Palette	w $FFFF8240.w	16 WORDs
;                    to w $FFFF825E.w	STColor=....rRRR gGGGbBBB
;
; WARNING : STColors are built like this : Bit 0321 for compatibility with
;           512 Colors Shifters (Bit 210 ONLY per Color)
;           So, you'll get this order : 0, 2, 4, 6, 8, A, C, E, 1, 3, 5, 7, 9, B, D, F
;
; -----------------------------------------------------------------------------
;
; ST Shifter	w $FFFF8260.w	Bit ..10
;  4 Bits register		      00 ST Low
;		      01 ST Middle
;		      10 ST High
;		Write here 0, 1 or 2 turn your
;		Falcon030 into a compatible ST
;		resolution. Reading here give
;		the previous Value wrote, even
;		if the resolution has changed
;		since...
;
; -----------------------------------------------------------------------------
;
; HSR	b $FFFF8265.w	Horizontal Scroll Register
;		Not used in TrueColor, because adding
;		2 to the Screen Address is enough.
;		Put here a number between 0 and 15
;		then your screen scroll to the right
;		If !=0, then change OSTNL or VWrap 
;		like this :
;		  VWrap=VWrap-NumberOfColorPlane
;		because the Videl have to read more WORDs
;		from the memory. These WORDs already read,
;		it doesn't jump too far when the line is
;		displayed
;
; -----------------------------------------------------------------------------
;
; SPSHIFT	w $FFFF8266.w	
; 11 Bits register		Bit A98.6543210
;		    ... ...'+++-> 16 Colors Bank
;		    ... ...       When in 16 Colors Mode, you
;		    ... ...       can choose which Bank of 16 Colors
;		    ... ...       in the 256 Colors Palette will
;		    ... ...       be used. 
; 		    ... .1.     External VSync
;		    ... 1 .     External HSync
;		    .0.   .     Overlay Bit NOT used (64k Colors in TC Mode)
;		    .1.   .     Overlay Bit USED     (32k Colors in TC Mode)
;		    0 0   0      16 Colors
;		    0 0   1     256 Colors
;		    0 1   0     TrueColors
;		    1 0   0     Monochrome
;		Never set more than ONE BIT for Bits A,8 and 4
;
; NOTE : How can you turn your Falcon030 into 4 Colors ?
;        TIPS : How to Turn your Falcon030 Crazy-In-Four-Colors !
;               Put 0 in SPSHIFT (16c), then force Bit 8 (256) of STSHIFT to 1...
;
; WARNING : TrueColor Pixel is made up with : Bits FEDCBA9876543210
;                                                  RRRRRGGGGGgBBBBB
;           where 'g' is the Overlay Bit used for Genlocking ^
;           If Overlay Bit Off, then TRUE 64k Colors, else ONLY 32k Colors
;
; -_ HORIZONTAL REGISTERS _-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_
;
; HHC - Read ONLY	w $FFFF8280.w	Horizontal Hold Counter
; Dynamic register
;
; /------------------------------------- HHT->HHC ------------------------------------\
; |          HBE ........... HDB xxxxxxxxxxxxxxxxxxxxx HDE ............ HBB           |HBL
;  LeftBorder  LeftColor0Border       DisplayedLine     RightColor0Border  RightBorder
;     if HDB=HBE, then no LeftColor0Border       if HDE=HBB, then no RightColor0Border
;
; WARNING : It's REALLY useful to keep LeftBorder and RightBorder in VGA, because
;           it allows us to move the DisplayedScreen horizontaly...
;
; -----------------------------------------------------------------------------
;
; HHT	w $FFFF8282.w	Horizontal Hold Timer
;  9 Bits register		Time between two HBL
;  MaxValue : 1023
;
; WARNING, some values could destroy your monitor
;
; -----------------------------------------------------------------------------
;
; HBB	w $FFFF8284.w	Horizontal Border Begin
;  9 Bits register		End of ScanLine
;  MaxValue : 1023
;
; -----------------------------------------------------------------------------
;
; HBE	w $FFFF8286.w	Horizontal Border End
;  9 Bits register		Begin of ScanLine
;  MaxValue : 1023
;
; -----------------------------------------------------------------------------
;
; HDB	w $FFFF8288.w	Horizontal Display Begin
; 10 Bits register		Begin of DisplayedLine
;  MaxValue : 1023		Bit A..........
; +SetStartBit		    0           Start to Display from Left Border
;		    1           Start to Display from Middle Screen
;
; -----------------------------------------------------------------------------
;
; HDE	w $FFFF828A.w	Horizontal Display End
;  9 Bits register		End of DisplayedLine
;  MaxValue : 1023
;
; -----------------------------------------------------------------------------
;
; HSS	w $FFFF828C.w	Horizontal Scan Start
;  9 Bits register		Screen start to be scanned when HHC=HSS
;  MaxValue : 1023		¯ WARNING : HSS<<HHT
;
; -----------------------------------------------------------------------------
;
; HFS - Don't Touch	w $FFFF828E.w	Horizontal FS
;  9 Bits register		> ALWAYS 0 ! <
;  MaxValue : 1023
;
; -----------------------------------------------------------------------------
;
; HEE - Don't Touch	w $FFFF8290.w	Horizontal EE
;  9 Bits register		> ALWAYS 0 ! <
;  MaxValue : 1023
;
; -_ VERTICAL REGISTERS _-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_
;
; VFC - Read ONLY	w $FFFF82A0.w	Vertical Frequency Counter
; Dynamic register
; 
;  /UpperBorder VFC=VFT
; |         VBE
; |          .  UpperColor0Border
; |         VDB if VDB=VBE, then no UpperColor0Border
; |          x
; VFT->VFC   x  DisplayedLines
; |          x
; |         VDE 
; |         VBB if VDE=VBB, then no LowerColor0Border
; | LowerBorder
;  \LowerBorder VFC=0
; VBL
;
; WARNING : It's REALLY NO USE (in Mono or VGA) to keep UpperBorder and LowerBorder
;           because nothing can affect them (like Vertical Controls of your monitor...).
;
; -----------------------------------------------------------------------------
;
; VFT	w $FFFF82A2.w	Vertical Frequency Timer IN HALFLINE
; 11 Bits register		
;  MaxValue : 4095
;
; -----------------------------------------------------------------------------
;
; VBB	w $FFFF82A4.w	Vertical Border Begin    IN HALFLINE
; 11 Bits register		End   of the Scanned Screen
;  MaxValue : 4095
;
; -----------------------------------------------------------------------------
;
; VBE	w $FFFF82A6.w	Vertical Border End      IN HALFLINE
; 11 Bits register		Start of the Scanned Screen
;  MaxValue : 4095
;
; -----------------------------------------------------------------------------
;
; VDB	w $FFFF82A8.w	Vertical Display Begin   IN HALFLINE
; 11 Bits register		Top    of the Displayed Screen
;  MaxValue : 4095
;
; -----------------------------------------------------------------------------
;
; VDE	w $FFFF82AA.w	Vertical Display End     IN HALFLINE
; 11 Bits register		Bottom of the Displayed Screen
;  MaxValue : 4095
;
; -----------------------------------------------------------------------------
;
; VSS	w $FFFF82AC.w	Vertical SS              IN HALFLINE
; 11 Bits register		Screen start to be scanned when VFC=VSS
;  MaxValue : 4095		SCANNED is NOT DISPLAYED !!!
;		
;		WARNING : VSS SHOULD be a little bit
;		          less than VFT (2 for Mono,
;		          4 for VGA, and 6 for Color)
;
; -----------------------------------------------------------------------------
;
; -_ STATUT REGISTERS _-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_
;
; RCO	w $FFFF82C0.w	Video Clock
;  9 Bits register		Bit 876543210
;		    .......00 Monochrome - SM124
;		    .......01 Color RGB  - SC1224 or SC1435
;		    .......10 Color VGA  -
;		    .......11 Color TV   -
;		    ......0   VidelClock to 32Mhz (PixelWidth is thiner)
;		    ......1   VidelClock to 25.175MHz
;		    .....0    if Interlaced, then lines are displayed on the same location (flashy...)
;		    .....1    if Interlaced, then lines are displayed REALLY interlaced
;		    ....1     Screen Displayed a little bit to the right. Can be useful on some TV
;		    ...0      Negative VSync Edge (when signal fall from 5V to 0V)
;		    ...1      Positive VSync Edge (when signal rise from 0V to 5V)
;		    ..0       Negative HSync Edge (when signal fall from 5V to 0V)
;		    ..1       Positive HSync Edge (when signal rise from 0V to 5V)
;		    .0        Video Bus to 16 Bits : > ! NEVER  ! <
;		    .1        Video Bus to 32 Bits : > ! ALWAYS ! <
;		    0         Horizontal OffSet to 128 Video Clock Pulse
;		    1         Horizontal OffSet to 64  Video Clock Pulse
;		    11000     > The BEAST solution EVER ! ALWAYS ! <
;
; -----------------------------------------------------------------------------
;
; VCO	w $FFFF82C2.w	Video Control
;  4 Bits register		Bit 3210
;		    ...0 DoubleLine   -> 400 VGA,  200 RGB
;		    ...1                 200 VGA,  100 RGB
;		    ..0  Interlace, set VFT Bit 0 to 0
;		    ...               -> xxxxxxx,  200 RGB
;		    ..1                  xxxxxxx,  400 RGB
;		    ++-->PixelWidth in Videl Clock Pulse
;		    00   4 -> 160 VGA,  320 RGB
;		    01   2 -> 320 VGA,  640 RGB   
;		    10   1 -> 640 VGA, 1280 RGB !!
;		    11   0 -> Shut Off the Videl Processor, and if the Screen is 
;                                                             Energy Start Compatible, it Switch Off itself.
;		         Restoring these Bits (<>%11) will Switch it On
;		         WARNING : There is ABSOLUTELY NO DANGER to do that !
;		                   I do it VERY OFTEN, my screen mostly shuted off
;		                   with this system to listen to the music played by my 
;		                   CD-ROM Device... It cut the VidelClock -> FULL POWeR !
;
; -----------------------------------------------------------------------------
;
; Videl Palette	l $FFFF9800.w	256 LONGs
;                    to	l $FFFF98FC.w	FalconColor=RRRRRRrr GGGGGGgg ........ BBBBBBbb$
;
; -----------------------------------------------------------------------------
;
; The same system was put into the ATARI Jaguar (Tom processor)
; Different, but also very near from what you've just see above...
; No Video Memory, but a Graphic Processor working with an Object List !
; Quite easier too, because of no FUCKING BACKWARD COMPATIBILITY (no bad ST Emulation !)
;
; Now, let's see the way to create a New Resolution using the Videl Generator !
;
; First the Driver's Constants :
;
;ScreenLimits	4s	Mono Monitor
;	4s	RGB Monitor
;	4s	VGA Monitor
;	4s	TV Monitor
;ScreenEnergyStar	w	0==YES, 1==NO
;ScreenToleranceFactor	s	ñ5% WARNING	
;ScreenRatio	s	Normal
;ScreenRealSize	s	in Meters
;ScreenVidelClock0	s	in Hz (32MHz)
;ScreenVidelClock1	s	in Hz (25.175MHz)
;ScreenVidelClockBOOST	s	in Hz (50MHz)
;ScreenVidelBrust	w	17 in LONG
;ScreenZoomFactor	w	0==FullScreen, 1==VirtualScreen
;
; Now the Values given by the programmer who want to create a new Resolution :
;
;DisplayWidth	w
;DisplayHeight	w
;NbBitsPerColor	w	1, 2, 4, 8, 16
;
; There're ONLY FEW, isn't it ?
;
;   Ha ha ha, OK, let's talk a little, please. There is SO MANY things to see before
; creating a new Resolution...
;
; Well, 'DisplayHeight' and 'NbBitsPerColor' are 'ALWAYS' good.
; To prevent from errors, start to clean 'NbBitPerColor' :
;
;>  andi.w	 #%11111,NbBitsPerColor	; -> Now we're 'SAFE'
;
; Imagine there is more than 1 Bit set in 'NbBitsPerColor' :
;
;>  BFFFO 	NbBitsPerColor{11:5},D0	; Look for the Greatest Color Bit
;		; WARNING : For BFxxx Instructions,
;		; Bit 0 is Bit 31, so here 27 give
;		; Bit 4, then count 5 Bit (-> Bit 0)
;		; WORKS ONLY ON LONG, AND THERE WE'RE
;		; WORKING ON A WORD !
;   BEQ	NoBitsPerColor	; Hey, are U silly, 0 Bit per Color ?
;   move.l	#15,D1	; We'R working on a WORD !
;   sub.l	D0,D1
;   moveq.l	#1,D0	; Just 1 Bit, for sure NOW...
;   lsl.l	D1,D0	; Put it on the right upper place found
;   move.w	D0,NbBitsPerColor	; OK, that's it !
;
; OK, now the 'NbBitsPerColor' is REALLY safe, but NOT the 'DisplayWidth' ! Yes,
; because remember, 'OSTNL' and 'VWrap' are given in WORD, and depending on the
; number of color we want, 1 WORD can contain from 1 Pixel (NTC) till 16 Pixels.
; Basically, you've just to 'perform' a Modulo with an added PixelWidth :
;
;>  move.w	NbBitsPerColor,D0	; OK, that would be useful ;) )
;   move.w	#16,D1	; Arf, that's too...
;   divu.w	D0,D1	; Number of Pixels in a WORD
;   move.w	DisplayWidth,D0	; OK, let's do some math !
;   add.w	D1,D0	; FEW Pixels more (avoid SideEffect)
;   divu.w	D1,D0	; In D0.w, the number of WORDs per Line
;   andi.l	#$FFFF,D0	; Clean UpperWORD of D0
;   mulu.w	D1,D0	; Correct 'DisplayWidth'
;   move.w	D0,DisplayWidth	; Done...
;
; Well well well, young guy, now another problem : Is the Resolution asked
; compatible with your Screen ? That's to say : "Is the RefreshRate of the new
; screen compatible with your Screen's and your Videl's" ?
; What a good question, isn't it ?
;
;
;         | Monochrom Monitor       | RGB or TV Monitor       | Super VGA Monitor
; --------+-------------------------+-------------------------+-------------------------
; OSTNL   |    INT[ VirtualLineLenght * (NbBitsPerColor / 16)] - VWrap (OK for VirtualScreen)
; OK      |             in Pixel
;         | or INT[(VirtualLineLenght - DisplayLineLenght) * (NbBitsPerColor / 16)]
;         |
;         | - (NbBitsPerColor & %01110)//HSR
;         | WARNING : If HSR != 0 and IF you're using a VirtualScreen, then sub the
;         |           number of color plane already read by the Videl for 
;         |           UltraSmoothScrooling !!! (-> DON'T touch VWrap in this case !)
;         |
;         | WARNING : If you're using a VirtualScreen, then be awarn that OSTNL SHOULD
;         |           NOT be less than 34 (17 LONGs).
;         |           Yeah, due of the VidelHardWare, loading 17 LONGs by BrustCycle,
;         |           you'll jump too near, so the Videl will jump at least 17 LONGs
;         |           away.
;         |           Then you'll not start where you wanted !!!
;         |
;         | WARNING : Using HSR is not necessary in NTC, U've 'just' to change the
;         |           ScreenAdress. In Monochrom, that's IMPOSSIBLE because OSTNL or
;         |           VWrap would become ODD !!!
; --------+-----------------------------------------------------------------------------
; VWrap   |    INT[ DisplayLineLenght * (NbBitsPerColor / 16)] - NbBitsPerColor//HSR
; OK      |             in Pixel
;         | WARNING : If HSR != 0 and OSTNL == 0, then sub the number of color plane
;         |           already read by the Videl for UltraSmoothScrooling !!!
;         |           The screen would 'turn' on itself !
;         |
;         | WARNING : The Value here SHOULD NOT be less than 34 (17 LONGs). Read just
;         |           above to know WHY !
; --------+-------------------------+---------------------------------------------------
; STSHIFT | Put 2 here              | Put 0 to select 16 ST Colors Mode (ST LOW) 
; OK      |                         |     1            4 ST Colors Mode (ST MED) 
;         |                         |     2            2 ST Colors Mode (ST HI)
;         |                         | For 'Normal' 4 Colors, put 0 before in SPSHIFT
;         |                         | then force Bit 8 to 1 !
; --------+-------------------------+---------------------------------------------------
; HSR     | Put there a Value between 0 and 15. Then the Videl would scrool the whole
; OK      | screen on the left. Change OSTNL or VWrap (depending on which case U R) !!!
; --------+-------------------------+---------------------------------------------------
; SPSHIFT | Put 0 here              | Bit A98.6543210
; OK      |                         |     100.000,,,, for Monochrom
;         |                         |     000.000,,,, for 4 or 16 Colors
;         |                         |     000.0010000 for 256 Colors  
;         |                         |     001.0000000 for TrueColors
;         |                         | ,,,, depend on which 16 Colors Modus Bank you
;         |                         |      wanna use
; --------+-------------------------+-------------------------+-------------------------
; HHT     |    INT[
;         |
;         |
; --------+-------------------------+-------------------------+-------------------------
; HBB     | Put 0 here              |    INT[
;         |                         |
;         |                         |
; --------+-------------------------+-------------------------+-------------------------
; HBE     | Put 0 here              |    INT[
;         |                         |
;         |                         |
; --------+-------------------------+-------------------------+-------------------------
; HDB     |    INT[
;         |
;         |
; --------+-------------------------+-------------------------+-------------------------
; HDE     |    INT[
;         |
;         |
; --------+-------------------------+-------------------------+-------------------------
; HSS     |    INT[ HHT - (HHT * Factor)] with for MonType -> Factor    (use Bit 0 of
; OK      |                                        0 (Mono)   0.20-0.25       MonType ;-)
;         |                                        1 (RGB)    0.10-0.15
;         |                                        2 (VGA)    0.20-0.25
;         | Bit 0 == 0 > ! ALWAYS ! <              3 (TV)     0.10-0.15
; --------+-------------------------+-------------------------+-------------------------
; VFT     |    INT[ LowVRez * 2 * ((/Bit 0 MonType) * 2)] + 100 
;         | The last Value (100) can be changed
;         | Then check if VFT is compatible with the VFreq range of your Monitor !!
;         | Bit 0 == /(Bit 1 VCO) <- InterlaceBit
; --------+-------------------------+-------------------------+-------------------------
; VBB     | Put 0 here              |    INT[
;         |                         |
;         |                         |
;         |                         |                         +-------------------------
;         |                         |                         | For SVGA, just copy VDE,
;         |                         |                         | then you'll get NO
;         |                         |                         | LowerColor0Border
; --------+-------------------------+-------------------------+-------------------------
; VBE     | Put 0 here              |    INT[
;         |                         |
;         |                         |                         +-------------------------
;         |                         |                         | For SVGA, just copy VDB,
;         |                         |                         | then you'll get NO
;         |                         |                         | UpperColor0Border
; --------+-------------------------+-------------------------+-------------------------
; VDB     |    INT[
;         |
;         | - /(Bit 1 VCO) <- InterlaceBit
; --------+-------------------------+-------------------------+-------------------------
; VDE     |    INT[
;         |
;         | - /(Bit 1 VCO) <- InterlaceBit
; --------+-------------------------+-------------------------+-------------------------
; VSS     |    INT[ VFT - MonAccess ] with for MonType -> MonAccess
; OK      |                                    0 (Mono)   2
;         |                                    1 (RGB)    6
;         |                                    2 (VGA)    4
;         | Bit 0 == 1 > ! ALWAYS ! <          3 (TV)     6
; --------+-------------------------+-------------------------+-------------------------
; RCO     | Put $80 here            | Put $182 here           | Put $181 here
;         | > VideoBus to 32 Bits & | >             VideoClock == 32 MHz 
; --------+-------------------------+-------------------------+-------------------------
; VCO     | Put 8 here              | Bit 3210                | Bit 3210
; OK      | > 640*400 'VGA'         |     ..00 VRez>400       |     ..01 100<VRez<200 
;         |                         |     ..01 VRez<400       |     ..00 200<VRez<400
;         |                         |     ..                  |     ..10 VRez>400
;         |                         |     00   160<HRez<320   |     00   320<HRez<640
;         |                         |     01   320<HRez<640   |     01   640<HRez<1280
;         |                         |     10   HRez>640       |     10   HRez>1280 (16 Colors ONLY)
;         |
;         | %11.. SWITCH OFF THE VIDEL, THEN YOUR SCREEN (ONLY IF ENERGY-STAR-COMPATIBLE !!!)
;
; HFreq = VidelFreq / (HHT 
;
; VFreq = (HFreq * 2) / (VFT + (Bit 1 VCO)) <- InterlaceBit
;
; For any Resolution Change, you've to set the Registers in this order, just after
; a VSync : OSTNL, VWrap, SPSHIFT, (ST Mode for 4 Colors), RCO, VCO, HBB, HBE, HDB, HDE,
;           VBB, VBE, VDB, VDE, HHT & VFT (Timers at the end...).
; 
; But you can also set them in the Memory Address Order (ONLY if the Videl is clocked
; under 32 Mhz)
;
; - SCREEN_SHUTOFF -
;
;
; Parameters :
; Return     :
; Stack      :
;
; - SCREEN_COLORTEST -
;
;
; Parameters :
; Return     :
; Stack      :

;


VidelDriver	pea	VIDEL_Generator
	move.w	#$26,-(SP)	; - SUPEXEC -
	trap	#14	; *** XBIOS ***
	addq.l	#6,SP

	RTS

; WARNING : Massive FPU Use for registers calculations...

VIDEL_Generator	

	RTS



	; >> Calcul de OSTNL
	
VidelMath_OSTNL
	RTS

	; >> Calcul de VWrap
	
VidelMath_VWrap
	RTS

	; >> Calcul de STSHIFT

VidelMath_STSHIFT
	RTS

	; >> Calcul de HSR

VidelMath_HSR
	RTS

	; >> Calcul de SPSHIFT
	
VidelMath_SPSHIFT
	RTS

	; >> Calcul de HHT

VidelMath_HHT
	RTS

	; >> Calcul de HBB

VidelMath_HBB
	RTS

	; >> Calcul de HBE

VidelMath_HBE
	RTS

	; >> Calcul de HDB

VidelMath_HDB
	RTS

	; >> Calcul de HDE

VidelMath_HDE
	RTS

	; >> Calcul de HSS

VidelMath_HSS	clr.w	D0
	move.b	$FFFF8006.w,D0	; MonType
	andi.b	#1,D0
	
	lea	VM_HSSMonAccessTable,A0
	
	fmove.s	(A0,D0.w*4),FP0
	
	fmove.w	HHT,FP1
	fmul.x	FP1,FP0
	fsub.x	FP0,FP1
	fmove.w	FP1,D0
	
	andi.w	#%111111110,D0	; Modulo+B0<0
	move.w	D0,HSS	; Done...
	
	RTS
	
VM_HSSMonAccessTable	dc.s	0.25
	dc.s	0.15

	; >> Calcul de VFT

VidelMath_VFT
	RTS

	; >> Calcul de VBB

VidelMath_VBB
	RTS

	; >> Calcul de VBE

VidelMath_VBE
	RTS

	; >> Calcul de VDB

VidelMath_VDB
	RTS

	; >> Calcul de VDE

VidelMath_VDE
	RTS

	; >> Calcul de VSS
	
VidelMath_VSS	clr.w	D0
	move.b	$FFFF8006.w,D0	; MonType
	andi.b	#%11,D0
	
	lea	VM_VSSMonAccessTable,A0
	
	move.w	(A0,D0.w*2),D0
	
	move.w	VFT,D1
	sub.w	D0,D1
	move.w	D1,VSS	; Done...
	
	RTS
	
VM_VSSMonAccessTable	dc.w	2
	dc.w	6
	dc.w	4
	dc.w	6
	
	; >> Calcul de RCO

VidelMath_RCO
	RTS

	; >> Calcul de VCO

VidelMath_VCO
	RTS



; *** SCREEN_COLORTEST ***

VIDEL_ColorTest	; - Pr‚paration du Tableau de d‚placement -

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

	- Calcul de la Couleur Gouraud pour commencer -

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
		
	- Calcul de l'adresse, qui peut ˆtre optimis‚ -
		
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

	RTS

VCT_NewColorTable	dc.w	2048	; Rouge
	dc.w	32	; Vert
	dc.w	1	; Bleu

; *****************************************************************************
	SECTION	DATA
; *****************************************************************************

; -- Screens Configuration --

ScreenLimits	; Mono Monitor
	dc.s	34000	; HFreq Min
	dc.s	38000	; HFreq Max
	dc.s	68	; VFreq Min
	dc.s	76	; VFreq Max
	
	; RGB Monitor
	dc.s	15625	; HFreq Min
	dc.s	15625	; HFreq Max
	dc.s	45	; VFreq Min
	dc.s	65	; VFreq Max
	
	; VGA Monitor
	dc.s	31000	; HFreq Min
	dc.s	38100	; HFreq Max
	dc.s	50	; VFreq Min
	dc.s	90	; VFreq Max
	
	; TV Monitor
	dc.s	15625	; HFreq Min
	dc.s	15625	; HFreq Max
	dc.s	45	; VFreq Min
	dc.s	55	; VFreq Max

ScreenEnergyStar	dc.w	0	; 0==YES, 1==NO
	
ScreenToleranceFactor	dc.s	0.05	; ñ5% WARNING	

ScreenRatio	dc.s	4/3	; Normal

ScreenRealSize	dc.s	0.335	; in Meters

ScreenVidelClock0	dc.s	32000000	; in Hz
ScreenVidelClock1	dc.s	25175000	; in Hz
ScreenVidelClockBOOST	dc.s	50000000	; in Hz

ScreenVidelBrust	dc.w	17	; in LONG

ScreenZoomFactor	dc.w	0	; 0==FullScreen, 1==VirtualScreen

; -- Progiz Value --

XDisplay	dc.w	320
YDisplay	dc.w	240
Largeur	dc.w	XDisplay*2
Rgb	dc.w	32,64,32
Modulo	dc.w	0,2,1
	
VidelPalette	; ST Palette
	ds.w	16
	
	; Falcon030 Palette
	ds.l	256

; *****************************************************************************
	SECTION	BSS
; *****************************************************************************

ScreenVariables	ds.w	1	; OSTNL
	ds.w	1	; VWrap
	ds.w	1	; ST Mode
	ds.w	1	; SPSHIFT
	ds.w	1	; HHT
	ds.w	1	; HBB
	ds.w	1	; HBE
	ds.w	1	; HDB
	ds.w	1	; HDE
	ds.w	1	; HSS
	ds.w	1	; VFT
	ds.w	1	; VBB
	ds.w	1	; VBE
	ds.w	1	; VDB
	ds.w	1	; VDE
	ds.w	1	; VSS
	ds.w	1	; RCO
	ds.w	1	; VCO
		
Colors	ds.w	3
SizeScreen	ds.l	1

