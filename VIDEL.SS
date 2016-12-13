; /// SSAVCALL 3.02 - Videl DRIVER - ATARI Falcon030 - KOSS 2000 //////////////

; Author   : Kochise
; Date     : 02/10/07/2000
; Type     : SSAVCALL DRIVER Module
; Language : Assembler (Motorola 68030)
; Sequence : None
; Purpose  : ATARI Falcon030 Videl VideoDRIVER

; Machina  : ATARI Falcon030
; O.S.     : SSAVCALL 3

; Note     : Thanks to ZerkMan (c) 1995, Chris of AURA (c) 1995 & KOSS (c) 1999
; WARNING  : PARENTAL ADVISORY >> Ultra HOT CONTENT... 
;            Falcon030 & Videl EXPLICIT Informations !


; ### HardWare Informations ###################################################
; Address     Size Status Name         Purpose
;
;                                      --- Video Control Registers ---
;
; $FFFF8006.w WORD R/W    Falcon030 Processor Control / Don't EVEN care about the
;                                      other Bits there...
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 | | | | | | | | x | | x | | x |
;                                                 | | | | | | | |   | |   | |   |
;                         MonitorTYPE ------------+-' x x x x x x   x x   x x   x
;                             MonoChrom Monitor : 0 0
;                             RGB Color Monitor : 0 1
;                             VGA Color Monitor : 1 0
;                             TV Color PAL/NTSC : 1 1
;
;
;                                      TIPS : if MonitorType > 0, then Color
;                                             if Bit F=1, then Interlaced Possible
;                                             if Bit F=0, then Interlaced Impossible
;
; -----------------------------------------------------------------------------
;
; $FFFF8201.w BYTE R/W    ScreenADDRESS HI  / This address SHOULD be multiple of 4 !!
; $FFFF8203.w BYTE R/W                  MID
; $FFFF820D.w BYTE R/W                  LOW
;
; WARNING : movep Instruction is FORBIDEN
;
; -----------------------------------------------------------------------------
;
; $FFFF8205.w BYTE READ   ScreenCOUNTER HI  / DYNAMIC REGISTER
; $FFFF8207.w BYTE READ                 MID
; $FFFF8209.w BYTE READ                 LOW
;
; -----------------------------------------------------------------------------
;
; $FFFF820A.w BYTE READ   Sync Mode    WARNING : NEVER touch these Bits !!!
;
;                         BitField            BIT 7 6 5 4 3 2 1 0
;                                                 x x x x x x | |
;                                                             | |
;                         Frequency --------------------------' |
;                      Monochrom Monitor Vertical Frequency : 0 |
;                      Color     Monitor Vertical Frequency : 1 |
;                         Synchronisation ----------------------'
;                                    Internal Synchronisation : 0
;                                    External Synchronisation : 1
;
; -----------------------------------------------------------------------------
;
; $FFFF820E.w WORD R/W    OSTNL        OffSet to NextLine  
;                                      > IN WORD <
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x | | | | | | | | |
;                                                               | | | | | | | | |
;                         OSTNL --------------------------------+-+-+-+-+-+-+-+-'
;
; 9 Bits register, MaxValue is 511 WORDs : NTC =  511 pixels
;                                         256c = 1022 pixels
;                                          16c = 2044 pixels
;                                          Med = 4088 pixels
;                                         Mono = 8176 pixels
;
; ¯ OSTNL = VirtualLineWidth - DisplayedLineWidth
;
; On a 'Normal' screen (NonVirtualScreen), OSTNL is ALWAYS at 0 !
;
; Note    : This register is used for VirtualScreen
; WARNING : Depend on the Videl HardWare : NEVER less than 34 !!!
;
; -----------------------------------------------------------------------------
;
; $FFFF8210.w WORD R/W    VWrap        Width of the DisplayedLine
;                                      > IN WORD <
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x | | | | | | | | | |
;                                                             | | | | | | | | | |
;                         VWrap ------------------------------+-+-+-+-+-+-+-+-+-'
;
; 10 Bits register, MaxValue is 1023 WORDs : NTC =  1023 pixels
;                                           256c =  2046 pixels
;                                            16c =  4092 pixels
;                                            Med =  8184 pixels
;                                           Mono = 16368 pixels
;
; ¯ VWrap = DisplayedLineWidth
;
; WARNING : Depend on the Videl HardWare : NEVER less than 34 !!!
;
; -----------------------------------------------------------------------------
;
; $FFFF8240.w WORD R/W    ST Palette   16 WORDs
;        :
; $FFFF825E.w WORD R/W	STColor=....rRRR gGGGbBBB
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x | | | | | | | | | | | |
;                                                         | | | | | | | | | | | |
;                         Red   (bit 0321) ---------------+-+-+-' | | | | | | | |
;                                                                 | | | | | | | |
;                         Green (bit 0321) -----------------------+-+-+-' | | | |
;                                                                         | | | |
;                         Blue  (bit 0321) -------------------------------+-+-+-'
;
; WARNING : STf Color Mode :  512 Colors, with bit 210
;           STe Color Mode : 4096 Colors, with bit 3210 (SADLY NOT TRUE)
;
;           BUT in order to keep a (F......) backward compatibility :
;           STe Color Mode : 4096 Colors, with bit 0321
;
;           So, you'll get this (STUPID) order : 0246 8ACE 1357 9BDF
;
; -----------------------------------------------------------------------------
;
; $FFFF8260.w BYTE R/W    ST Shifter
;
;                         BitField            BIT 7 6 5 4 3 2 1 0
;                                                 x x x x x x | |
;                                                             | |
;                         STSHIFT ----------------------------+-'
;                                                    ST Low : 0 0
;                                                 ST Middle : 0 1
;                                                   ST High : 1 0
;
; WARNING : Write here 0, 1 or 2 turn your Falcon030 into a compatible ST
;           resolution. Reading here give the previous Value wrote, even
;           if the resolution has changed since (especialy VidelREGISTER)...
;
; -----------------------------------------------------------------------------
;
; $FFFF8265.w BYTE R/W    HSR          Horizontal Scroll Register
;
;                         BitField            BIT 7 6 5 4 3 2 1 0
;                                                 x x x x | | | |
;                                                         | | | |
;                         HSR ----------------------------+-+-+-'
;
; Note    : Not used in TrueColor, because adding 2 to the Screen Address is enough.
;           Put here a number between 0 and 15 then your screen scroll to the right
;
;           If !=0, then change OSTNL or VWrap like this :
;
;           ¯ VWrap=VWrap-NumberOfColorPlane
;
;           because the Videl have to read more WORDs from the memory. These WORDs
;           already read, it doesn't jump too far when the line is displayed
;
; -----------------------------------------------------------------------------
;
; $FFFF8266.w WORD R/W    SPSHIFT
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x | | | x | | | | | | |
;                                                           | | |   | | | | | | |
;                         Color Mode (bit A84) -------------+-|-+---|-|-' | | | |
;                                               16 Colors : 0 | 0   | | 0 | | | |
;                                              256 Colors : 0 | 0   | | 1 | | | |
;                                          NearTrueColors : 0 | 1   | | 0 | | | |
;                                              Monochrome : 1 | 0   | | 0 | | | |
;                         Overlay Mode -----------------------'     | |   | | | |
;                          NOT Used (64k Colors in TC Mode) : 0     | |   | | | |
;                              USED (32k Colors in TC Mode) : 1     | |   | | | |
;                                                                   | |   | | | |
;                         HSync ------------------------------------' |   | | | |
;                                              Internal (Default) : 0 |   | | | |
;                                              External           : 1 |   | | | |
;                         VSync --------------------------------------'   | | | |
;                                                Internal (Default) : 0   | | | |
;                                                External           : 1   | | | |
;                                                                         | | | |
;                         16 Colors Bank ---------------------------------+-+-+-'
;                           When in 16 Colors Mode, U can choose which Bank of
;                           16 Colors (among 16) in the 256 Colors Palette will
;                           be used...
;
; WARNING : Never set more than ONE BIT for Bits A,8 and 4
;
; Note    : How can you turn your Falcon030 into 4 Colors ?
; TIPS    : How to Turn your Falcon030 Crazy-In-Four-Colors !
;           Put 0 in SPSHIFT\Color Mode (16c), then put %01 in STSHIFT (4c)...
;
; WARNING : NearTrueColor Pixel is made up like this :
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 | | | | | | | | | | | | | | | |
;                                                 | | | | | | | | | | | | | | | |
;                         Red (5 bits) -----------+-+-+-+-' | | | | | | | | | | |
;                                                           | | | | | | | | | | |
;                         Green (5/6 bits) -----------------+-+-+-+-' | | | | | |
;                         Green / OverlayBIT -------------------------' | | | | |
;                                                                       | | | | |
;                         Blue (5 bits) --------------------------------+-+-+-+-'
;
; Note    : The OverlayBIT is used for Genlocking !
;           If that OverlayBIT is OFF, then TRUE 64k Colors, else ONLY 32k Colors
;
; -----------------------------------------------------------------------------
;
;                                      --- Horizontal Registers ---
;
; $FFFF8280.w WORD READ   HHC          Horizontal Hold Counter
;                                      DYNAMIC REGISTER
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x | | | | | | | | |
;                                                               | | | | | | | | |
;                         HHC ----------------------------------+-+-+-+-+-+-+-+-'
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
; $FFFF8282.w WORD R/W    HHT          Horizontal Hold Timer
;                                      Time between two HBL
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x | | | | | | | | |
;                                                               | | | | | | | | |
;                         HHT ----------------------------------+-+-+-+-+-+-+-+-'
;
; 9 Bits register, MaxValue is 511
;
; WARNING : some values could destroy your monitor
;
; -----------------------------------------------------------------------------
;
; $FFFF8284.w WORD R/W    HBB          Horizontal Border Begin
;                                      End of ScanLine
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x | | | | | | | | |
;                                                               | | | | | | | | |
;                         HBB ----------------------------------+-+-+-+-+-+-+-+-'
;
; 9 Bits register, MaxValue is 511
;
; -----------------------------------------------------------------------------
;
; $FFFF8286.w WORD R/W    HBE          Horizontal Border End
;                                      Begin of ScanLine
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x | | | | | | | | |
;                                                               | | | | | | | | |
;                         HBE ----------------------------------+-+-+-+-+-+-+-+-'
;
; 9 Bits register, MaxValue is 511
;
; -----------------------------------------------------------------------------
;
; $FFFF8288.w WORD R/W    HDB          Horizontal Display Begin
;                                      Begin of DisplayedLine
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x | | | | | | | | | |
;                                                             | | | | | | | | | |
;                         StartBIT ---------------------------' | | | | | | | | |
;                         Start to Display from Left Border : 0 | | | | | | | | |
;                       Start to Display from Middle Screen : 1 | | | | | | | | |
;                                                               | | | | | | | | |
;                         HDB ----------------------------------+-+-+-+-+-+-+-+-'
;
; 9 Bits register, MaxValue is 511
;
; -----------------------------------------------------------------------------
;
; $FFFF828A.w WORD R/W    HDE          Horizontal Display End
;                                      End of DisplayedLine
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x | | | | | | | | |
;                                                               | | | | | | | | |
;                         HDE ----------------------------------+-+-+-+-+-+-+-+-'
;
; 9 Bits register, MaxValue is 511
;
; -----------------------------------------------------------------------------
;
; $FFFF828C.w WORD R/W    HSS          Horizontal Scan Start
;                                      Screen start to be scanned when HHC=HSS
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x | | | | | | | | |
;                                                               | | | | | | | | |
;                         HSS ----------------------------------+-+-+-+-+-+-+-+-'
;
; 9 Bits register, MaxValue is 511
;
; WARNING : HSS<<HHT
;
; -----------------------------------------------------------------------------
;
; $FFFF828E.w WORD R/W    HFS          Horizontal FS
;                                      Don't Touch
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x | | | | | | | | |
;                                                               | | | | | | | | |
;                         HFS ----------------------------------+-+-+-+-+-+-+-+-'
;
; 9 Bits register, MaxValue is 511
;
; WARNING : > ALWAYS 0 ! <
;
; -----------------------------------------------------------------------------
;
; $FFFF8290.w WORD R/W    HEE          Horizontal EE
;                                      Don't Touch
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x | | | | | | | | |
;                                                               | | | | | | | | |
;                         HEE ----------------------------------+-+-+-+-+-+-+-+-'
;
; 9 Bits register, MaxValue is 511
;
; WARNING : > ALWAYS 0 ! <
;
; -----------------------------------------------------------------------------
;
;                                      --- Vertical Registers ---
;
; $FFFF82A0.w WORD READ   VFC          Vertical Frequency Counter
;                                      DYNAMIC REGISTER
; 
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x | | | | | | | | | | |
;                                                           | | | | | | | | | | |
;                         VFC ------------------------------+-+-+-+-+-+-+-+-+-+-'
;
; 11 Bits register, MaxValue is 2047 (1023.5 lines)
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
; $FFFF82A2.w WORD R/W    VFT          Vertical Frequency Timer
;                                      IN HALFLINE
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x | | | | | | | | | | |
;                                                           | | | | | | | | | | |
;                         VFT ------------------------------+-+-+-+-+-+-+-+-+-+-'
;
; 11 Bits register, MaxValue is 2047 (1023.5 lines)
;
; -----------------------------------------------------------------------------
;
; $FFFF82A4.w WORD R/W    VBB          Vertical Border Begin
;                                      End of the Scanned Screen
;                                      IN HALFLINE
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x | | | | | | | | | | |
;                                                           | | | | | | | | | | |
;                         VBB ------------------------------+-+-+-+-+-+-+-+-+-+-'
;
; 11 Bits register, MaxValue is 2047 (1023.5 lines)
;
; -----------------------------------------------------------------------------
;
; $FFFF82A6.w WORD R/W    VBE          Vertical Border End
;                                      Start of the Scanned Screen
;                                      IN HALFLINE
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x | | | | | | | | | | |
;                                                           | | | | | | | | | | |
;                         VBE ------------------------------+-+-+-+-+-+-+-+-+-+-'
;
; 11 Bits register, MaxValue is 2047 (1023.5 lines)
;
; -----------------------------------------------------------------------------
;
; $FFFF82A8.w WORD R/W    VDB          Vertical Display Begin
;                                      Top of the Displayed Screen
;                                      IN HALFLINE
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x | | | | | | | | | | |
;                                                           | | | | | | | | | | |
;                         VDB ------------------------------+-+-+-+-+-+-+-+-+-+-'
;
; 11 Bits register, MaxValue is 2047 (1023.5 lines)
;
; -----------------------------------------------------------------------------
;
; $FFFF82AA.w WORD R/W    VDE          Vertical Display End
;                                      Bottom of the Displayed Screen
;                                      IN HALFLINE
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x | | | | | | | | | | |
;                                                           | | | | | | | | | | |
;                         VDE ------------------------------+-+-+-+-+-+-+-+-+-+-'
;
; 11 Bits register, MaxValue is 2047 (1023.5 lines)
;
; -----------------------------------------------------------------------------
;
; $FFFF82AC.w WORD R/W    VSS          Vertical SS
;                                      Screen start to be scanned when VFC=VSS
;                                      IN HALFLINE
;
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x | | | | | | | | | | |
;                                                           | | | | | | | | | | |
;                         VSS ------------------------------+-+-+-+-+-+-+-+-+-+-'
;
; 11 Bits register, MaxValue is 2047 (1023.5 lines)
;
; WARNING : SCANNED is * NOT * DISPLAYED !!!
;		
; WARNING : VSS SHOULD be a little bit less than VFT
;           (2 for Mono, 4 for VGA, and 6 for Color)
;
; -----------------------------------------------------------------------------
;
;                                      --- STATUT REGISTERS ---
;
; $FFFF82C0.w WORD R/W    RCO          Video Clock
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x | | | | | | | | |
;                                                               | | | | | | | | |
; Horizontal OffSet
; ;                         VIDEL BusSIZE ----------------------' |   | |   | |   |
;                                         16 Bits           : 0 |   | |   | |   |
;                                         32 Bits (Default) : 1 |   | |   | |   |
; HSync Edge
; VSync Edge
; Interlaced Method
; Videl Clock
;                         MonitorTYPE ------------+-' | | | | | |   | |   | |   |
;                             MonoChrom Monitor : 0 0 | | | | | |   | |   | |   |
;                             RGB Color Monitor : 0 1 | | | | | |   | |   | |   |
;                             VGA Color Monitor : 1 0 | | | | | |   | |   | |   |
;                             TV Color PAL/NTSC : 1 1 | | | | | |   | |   | |   |



;Bit 876543210
;    .......00 Monochrome - SM124
;    .......01 Color RGB  - SC1224 or SC1435
;    .......10 Color VGA  -
;    .......11 Color TV   -
;    ......0   VidelClock to 32Mhz (PixelWidth is thiner)
;    ......1   VidelClock to 25.175MHz
;    .....0    if Interlaced, then lines are displayed on the same location (flashy...)
;    .....1    if Interlaced, then lines are displayed REALLY interlaced
;    .....1     Screen Displayed a little bit to the right. Can be useful on some TV
;    ...0      Negative VSync Edge (when signal fall from 5V to 0V)
;    ...1      Positive VSync Edge (when signal rise from 0V to 5V)
;    ..0       Negative HSync Edge (when signal fall from 5V to 0V)
;    ..1       Positive HSync Edge (when signal rise from 0V to 5V)
;    .0        Video Bus to 16 Bits : > ! NEVER  ! <
;    .1        Video Bus to 32 Bits : > ! ALWAYS ! <
;    0         Horizontal OffSet to 128 Video Clock Pulse
;    1         Horizontal OffSet to 64  Video Clock Pulse
;    11000     > The BEAST solution EVER ! ALWAYS ! <
;
	dc.w	511	; RCO
; -----------------------------------------------------------------------------
;
; $FFFF82C2.w WORD R/W    VCO          Video Control
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                                                 x x x x x x x x x x x x | | | |
;                                                                         | | | |




;Bit 3210
;    ...0 DoubleLine   -> 400 VGA,  200 RGB
;    ...1                 200 VGA,  100 RGB
;    ..0  Interlace, set VFT Bit 0 to 0
;    ...               -> xxxxxxx,  200 RGB
;    ..1                  xxxxxxx,  400 RGB
;    ++-->PixelWidth in Videl Clock Pulse
;    00   4 -> 160 VGA,  320 RGB
;    01   2 -> 320 VGA,  640 RGB   
;    10   1 -> 640 VGA, 1280 RGB !!
;    11   0 -> Shut Off the Videl Processor, and if the Screen is 
;              Energy Start Compatible, it Switch Off itself.
;         Restoring these Bits (<>%11) will Switch it On
;         WARNING : There is ABSOLUTELY NO DANGER to do that !
;                   I do it VERY OFTEN, my screen mostly shuted off
;                   with this system to listen to the music played by my 
;                   CD-ROM Device... It cut the VidelClock -> FULL POWeR !
;
	dc.w	15	; VCO
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

