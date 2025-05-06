;********************************************************************************
;                  H2O-Improved
;********************************************************************************
					
;DEFINE

;expermenting defines, not needed.
SX48RAM			= 	1			; unneeded memory remap, now working starting at $10 as sx48 has 1-f bank free. sx28 15-1f then or over 2x 4x 6x 8x Ax Cx Ex (had mistaken the or just for 2x bank rest free)

;SX Chip used. SX48 uncomment below. SX28 have commented.
SX48			= 	1			; uncomment for compiling for sx48 else is compiled for sx28 F=TR

;RSTBUMP			= 	1			; uncomment for compiling with restbump for ps1mode. sx28 or this and next define aswell for sx48. sx28 DECFCB1171D02DAE402AC30419CBBDAB
;USE SX48RSTBUMP ONLY FOR SX COMPILING FOR SX48. Both RSTBUMP and SX48RSTBUMP must be on
;SX48RSTBUMP			= 	1			; uncomment for compiling with restbump for ps1mode. for sx48 with RSTBUMP uncommented	4F544B1369ADFAFFA973F51FB47CD27B

;V14/V8jap identiy jmpers. if using sx48 needs the trim, sx28 either can go but stock code is without trim
;H2O75KJMPERS			= 	1			; uncomment for compiling with restbump for ps1mode. if compiling for rstbmp use one of the sx28/sx48 with h2o v14usa/v14jap/v8jap ident jmpers else use F=TR defines  sx28 C60170F11BFEF1210C677F3704202E21
;SX48H2O75KJMPERSTRIM			= 	1			; needed if using h2o jmpers ident with sx48 rstbmp. h needs to go to 5v if not jap console or triggers my cad. sx28 2CAC930CAEC1E5D3ED67A2AC89769636 sx48 5607357E1E0B3C2815F69713F2AE8970

;USE ONLY IF F=TR or RSTBUMP without H2O75KJMPERS.
;pal v14 dont define any. for jap/usa define only one for 75k this will make f=tr work correctly also h=rw usa/pal			f=tr 75k pal sx28 B0316082466C451B3E4C201697BB8D05 sx48 3C452A502DC31221D6E882D6A54D83C1
;USAv14			= 	1			;uncomment for fixed 75k being usa region. all prior still work any region		f=tr 75k usa sx28 5692BFA1416257ACAC48729793EB3F70 sx48 AA4EE16D3BF2D75C1410FAD7F0596092
;JAPv14orv8			= 	1			;uncomment for fixed 75k being jap region. all prior still work any region		f=tr 75k jap sx28 6666645ED508DCA4FABF59A2E4296E20 sx48 08F345CF0FD1183AFCD89A20ACCF6BC3
;also for v7 to use v9+ mechacon patch for v8 jap support f=tr 

;NTSCPS1YFIX75K		= 	1			;uncomment for 75k NTSC IMPORT YFIX PAL CONSOLE TESTED makes pal off screen but ntsc correct. off pal correct, ntsc crushed.

;only rstbump v8jap tested but rest should be right
	IFDEF	SX48
                   device        SX48,TURBO,BOROFF,OSCHS2,OPTIONX,WDRT006
                    ID                    'ICEREV'
	ELSE			
	device        SX28,TURBO,BOROFF,BANKS8,OSCHS2,OPTIONX
                    ID                    'ICEREV'
	ENDIF

;io pin assignments
IO_SCEX				=		ra.2 ; (PSX:SCEx)RA2(S)
IO_BIOS_OE			=		ra.0 ; (R)
IO_BIOS_CS			=		rb.1 ; (W)					; LOW = BIOS select ; 1 = no access to rom , 0 = access to rom
IO_REST				=		rb.2 ; 						; 1 = normal , 0 = reset
IO_EJECT			=		rb.3 ; (PS2:EJECT)RB3(Z) 			;  1 = tray open , 0 = tray closed
IO_CDDVD_OE_A_1Q		=		ra.1 ; (CDDVD:OE)RA1(A) (flipflop 1Q#) ;A from flip flop
IO_CDDVD_OE_A_1R		=		ra.3 ; (CDDVD:OE)RA3(A) (flipflop 1R#) ;flip flop clr
IO_CDDVD_BUS_i			=		rb.7 ; (I)(CDDVD:D7)
IO_CDDVD_BUS_b			=		rb.4 ; (B)(CDDVD:D2)
IO_CDDVD_BUS_f			=		rb.0 ; (F)(just used for usa v14 jmp or clash with f=tr on v14 usa)
IO_CDDVD_BUS_h			=		rb.6 ; (H)(how determins is jap v14 if connected, assumption is no RW support at all on v14 RSTBUMP unless sync works out for when checked)
IO_CDDVD_BUS			=		rb   ; $06
IO_BIOS_DATA			=		rc   ; $07 ; (V)RC0(BIOS:D0) - (M)RC7(BIOS:D7)
	IFDEF	SX48
;regs sx48
VAR_DC1             =           $0A
VAR_DC2             =           $0B
VAR_DC3             =           $0C
VAR_DC4         =           $0D
VAR_PSX_TEMP         =           $10
VAR_PSX_BYTE         =           $11
VAR_PATCH_FLAGS      =           $0E
VAR_SWITCH          =           $0F
VAR_BIOS_REV         =           $12
VAR_BIOS_YR          =           $13
VAR_BIOS_REGION_TEMP    =           $14
VAR_PSX_BITC         =           $15
VAR_PSX_BC_CDDVD_TEMP           =           $16
	ELSE
;regs sx28
VAR_DC1				=		$08 ; DS 1 ; delay counter 1(small)
VAR_DC2				=		$09 ; DS 1 ; delay counter 2(small)
VAR_DC3				=		$0A ; DS 1 ; delay counter 3(big)
VAR_DC4				=		$0b ; DS 1 ; delay counter 4
VAR_PSX_TEMP			=		$0C ; DS 1 ; SEND_SCEX:  rename later
VAR_PSX_BYTE			=		$0D ; DS 1 ; SEND_SCEX:  byte(to send)
VAR_PATCH_FLAGS			=		$0E ; DS 1
VAR_SWITCH			=		$0F ; DS 1
VAR_BIOS_REV			=		$10 ; DS 1 ; 1.X0 THE BIOS REVISION byte infront in BIOS string is X.00
VAR_BIOS_YR			=		$11 ; DS 1 ; byteC of ;BIOS_VERSION_MATCHING
VAR_BIOS_REGION_TEMP		=		$12 ; DS 1 ; temp storage to compare byte7 of ;BIOS_VERSION_MATCHING
VAR_PSX_BITC			=		$13 ; DS 1 ; SEND_SCEX:  bit counter ;note start at 8(works down to 0)
VAR_PSX_BC_CDDVD_TEMP		=		$14 ; DS 1 ; SEND_SCEX:  byte counter  note start at 4(works down to 0) ; also used with mechacon patches and ps1 detect
	ENDIF

;------------------------------------------------------------
;VAR_PATCH_FLAGS
;------------------------------------------------------------
EJ_FLAG = VAR_PATCH_FLAGS.0
;bit 0 used by eject routine

SOFT_RST = VAR_PATCH_FLAGS.1
;soft reset flag for disk patch 

PSX_FLAG = VAR_PATCH_FLAGS.2
;psx mode flag	

V10_FLAG = VAR_PATCH_FLAGS.3	
;bios 1.9 also used in conjuction with v12 2.0
;also v10 1.9 bios has own ps1 routine 

UK_FLAG = VAR_PATCH_FLAGS.4

USA_FLAG = VAR_PATCH_FLAGS.5

JAP_FLAG = VAR_PATCH_FLAGS.6

SCEX_FLAG = VAR_PATCH_FLAGS.7
;set when SCEX_LOW loop for injecting. once cleared knows patching done to flow forward

;------------------------------------------------------------
;VAR_SWITCH
;------------------------------------------------------------
V12_FLAG = VAR_SWITCH.0 
;v12 console 2.0 bios set

V12LOGO_FLAG = VAR_SWITCH.1
;PS1 V12 LOGO PATCH

JAP_V8 = VAR_SWITCH.2
;Jap V8 with last rev of mechacon needing dragon patches abghi

X_FLAG = VAR_SWITCH.3 
;xman patch 1 only for PS1
;can flow onto ps1 reboot into PS1_MODE if detect ps1 media

DEV1_FLAG = VAR_SWITCH.4
;DEV1 mode flag

V14_FLAG = VAR_SWITCH.5
;set due to W for region of BIOS which decka models

V0_FLAG = VAR_SWITCH.6
;V0 10-18K console flag ;;;; currently unused, for future 

;------------------------------------------------------------
;CODE
;------------------------------------------------------------

;mode setup for io's
;ref SX-SX-Users-Manual-R3.1.pdf section 5.3.2
	IFDEF	SX48
                    org           $0FFF							; Reset Vector
                    reset         STARTUP						; jmp to startup process on reset vector skipping boot inital

;****** Reset of the chip ********************************
                    org           $0000							; PAGE1 000-1FF
;INTERRUPT
;goes to sleep and wait for reset release ( 1 ) or tray close (0) ...		
                    mov           w,#$1f
                    mov           m,w
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    mov           w,#$ff
                    mov           !IO_CDDVD_BUS,w
                    mov           w,#$ff
                    mov           !ra,w
                    mov           w,#$1a
                    mov           m,w
                    mov           w,#$8
                    mov           !IO_CDDVD_BUS,w
                    mov           w,#$19
                    mov           m,w
                    clr           w
                    mov           !IO_CDDVD_BUS,w
                    mov           w,#$1b
                    mov           m,w
                    mov           w,#$f3
                    mov           !IO_CDDVD_BUS,w
                    mov           w,#$1f
                    mov           m,w
                    sleep      

;INIT_CHIP					
STARTUP
                    mov           w,#$1d
                    mov           m,w
                    mov           w,#$f7
                    mov           !IO_CDDVD_BUS,w
	IFDEF	H2O75KJMPERS					
                    mov           w,#$1e			;; extra needed for io v14jmp
                    mov           m,w
                    mov           w,#$be
                    mov           !IO_CDDVD_BUS,w		;; end extra io v14jmp	
	ENDIF					
                    mov           w,#$1f
                    mov           m,w
                    mov           w,#$7
                    mov           !ra,w
                    mov           w,#$ff
                    mov           !IO_CDDVD_BUS,w
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    mov           w,#$c7
                    mov           !option,w
					
;read power down register
                    clr           fsr
                    mov           w,#$19
                    mov           m,w
                    clr           w
                    mov           !IO_CDDVD_BUS,w
                    mov           VAR_PSX_BITC,w
                    mov           w,#$1f
                    mov           m,w
	ELSE
                    org           $07FF	
                    reset         STARTUP						; jmp to startup process on reset vector skipping boot inital

;****** Reset of the chip ********************************
                    org           $0000							; PAGE1 000-1FF
;INTERRUPT
;goes to sleep and wait for reset release ( 1 ) or tray close (0) ...					
                    mode          $000F
                    mov           w,#$ff					; 1111 1111
                    mov           !IO_BIOS_DATA,w				;to be sure ports are input ...
                    mov           w,#$ff					; 1111 1111
                    mov           !IO_CDDVD_BUS,w				;....
                    mov           w,#$ff					; 1111 1111
                    mov           !ra,w						;...
                    mode          $000A						;set up edge register
                    mov           w,#$8						; 0000 1000	
                    mov           !IO_CDDVD_BUS,w				;RB3 wait for LOW ( = 1 ),RB2 wait for hi ( =0 )
                    mode          $0009						;clear all wakeup pending bits
                    clr           w
                    mov           !IO_CDDVD_BUS,w
                    mode          $000B						;enable wakeup...
                    mov           w,#$f3					; 1111 0011
                    mov           !IO_CDDVD_BUS,w				;... on RB3 ( eject ) & RB2 (reset) 
                    mode          $000F
                    sleep         
					
;INIT_CHIP					
STARTUP          								;here from stby & wake up...
                    mode          $000D						;TTL/CMOS mode...
                    mov           w,#$f7					;1111 0111
                    mov           !IO_CDDVD_BUS,w				;set IO_EJECT input as cmos ( level '1' > 2.5V ) work better with noise ...
	IFDEF	H2O75KJMPERS
                    mode          $000E						;; h and f io jmpers needed/extra 75k/v8jap 
                    mov           w,#$be					; 1011 1110
                    mov           !IO_CDDVD_BUS,w					;; end
	ENDIF
                    mode          $000F						;port mode
                    mov           w,#$7						; 0000 0111
                    mov           !ra,w						;port mode : all input
                    mov           w,#$ff
                    mov           !IO_CDDVD_BUS,w
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    mov           w,#$c7
                    mov           !option,w					;rtcc enabled,no int,incr.on clock, prescaler (bit 2,1,0).
					
;read power down register					
                    clr           fsr
                    mode          $0009						;read power down register 
                    clr           w						;clear W
                    mov           !IO_CDDVD_BUS,w				;exchange registers = read pending bits
                    mov           VAR_PSX_BITC,w				;save wake up status ...
                    mode          $000F						;need 'cause removed from patch disk for speed !
		ENDIF
;execute correct startup...					
                    snb           pd
                    jmp           CLEAR_CONSOLE_INFO_PREFIND			;0 = power up from sleep , 1= power up from Power ON (STBY)
                    snb           VAR_PSX_BITC.2
                    jmp           TAP_BOOT_MODE
                    snb           IO_EJECT
                    jmp           TRAY_IS_EJECTED
                    snb           VAR_PSX_BITC.1				;xcdvdman reload check
                    page          $0200
                    jmp           IS_XCDVDMANX
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
					
;power up from STBY					
CLEAR_CONSOLE_INFO_PREFIND
                    clr           VAR_PATCH_FLAGS				;reset all used flag...
                    clr           VAR_SWITCH			
                    jmp           BIOS_GET_SYNC

;---------------------------------------------------------
;Delay routine using RTCC 
;---------------------------------------------------------

;--------------------------------------------------------------------------------
DELAY100m									;Precise delay routine using RTCC 
;--------------------------------------------------------------------------------
                    mov           w,#100;$64
                    mov           VAR_DC1,w					;delay = 100 millisec.
RTCC_SET_BIT
                    mov           w,#61;$3d				
                    mov           rtcc,w					;load  timer = 61 ; delay = (256-61)*256*0.02 micros.= 1000 micros. / 45 for 54M
RTCC_CHECK
                    mov           w,rtcc					;wait for timer= 0 ... (don't use TEST RTCC)
                    sb            z						;skip next bit if rtcc = 0
                    jmp           RTCC_CHECK					;loop w=rtcc till equal then will skip
                    decsz         VAR_DC1					;VAR_DC1 = 100 count then skip next bit
                    jmp           RTCC_SET_BIT
                    retp          						;Return from call


;--------------------------------------------------------------------------------
SET_INTRPT 									;setup interrupt routine
;--------------------------------------------------------------------------------
	IFDEF	SX48
                    mov           w,#$1a
                    mov           m,w
                    mov           w,#$6
                    mov           !IO_CDDVD_BUS,w
                    mov           w,#$19
                    mov           m,w
                    clr           w
                    mov           !IO_CDDVD_BUS,w
                    mov           w,#$1b
                    mov           m,w
                    mov           w,#$f3
                    mov           !IO_CDDVD_BUS,w
                    mov           w,#$1f
                    mov           m,w
                    retp          
	ELSE
                    mode          $000A						;set up edge register
                    mov           w,#$6						; 0000 0110
                    mov           !IO_CDDVD_BUS,w				; rb.1 IO_BIOS_CS rb.2 IO_REST high-to-low sense ;wait for low
                    mode          $0009						;clear all wakeup pending bits
                    clr           w						; 0000 0000
                    mov           !IO_CDDVD_BUS,w				; clear all wakeup pending bits
										; set to 0 indicates that no valid edge has occurred on the MIWU pin. 
										; The WKPND_B register comes up with undefine value upon reset.
                    mode          $000B						;enable interrupt ; MIWU operation. see Section 4.4.
                    mov           w,#$f3					; 1111 0011
                    mov           !IO_CDDVD_BUS,w				; rb.2 IO_REST rb.3 IO_EJECT enable interrupt
                    mode          $000F						; XFh mode direction for RA, RB, RC output
                    retp   
	ENDIF

;--------------------------------------------------------------------------------
SCEX_HI
;--------------------------------------------------------------------------------
                    setb          IO_SCEX					; SCEX HI
										; Delay About 5mS
                    mov           w,#59;$3b
                    mov           VAR_DC3,w
:loop1
                    mov           w,#212;$d4 ; #212 set for 50mhz
                    mov           VAR_DC2,w
                    not           ra
:loop2
                    mov           w,#3;$3
                    mov           VAR_DC1,w
:loop3
                    decsz         VAR_DC1
                    jmp           :loop3
                    decsz         VAR_DC2
                    jmp           :loop2
                    decsz         VAR_DC3
                    jmp           :loop1
                    ret           

;--------------------------------------------------------------------------------
SCEX_LOW
;--------------------------------------------------------------------------------
                    clrb          IO_SCEX					; SCEX LOW
										; Delay About 5mS+
                    mov           w,#59;$3b
                    mov           VAR_DC3,w
:loop1
                    mov           w,#212;$d4 ; #212 for 50mhz
                    mov           VAR_DC2,w
                    snb           IO_BIOS_CS					; next byte / wait for bios CE LOW = BIOS select
                    jmp           :loop2
                    setb          SCEX_FLAG
:loop2
                    mov           w,#3;$3
                    mov           VAR_DC1,w
:loop3
                    decsz         VAR_DC1
                    jmp           :loop3
                    decsz         VAR_DC2
                    jmp           :loop2
                    decsz         VAR_DC3
                    jmp           :loop1
                    ret           

;--------------------------------------------------------------------------------
SCEx_DATA
;--------------------------------------------------------------------------------
                    jmp           pc+w  ; retw values are ascii hex
                    retw          $53	; S	; USA	0
                    retw          $43	; C
                    retw          $45	; E
                    retw          $41	; A
					
                    retw          $53	; S	; JAP	4
                    retw          $43	; C
                    retw          $45	; E
                    retw          $49	; I
					
                    retw          $53	; S	; UK	8
                    retw          $43	; C
                    retw          $45	; E
                    retw          $45	; E

;--------------------------------------------------------------------------------
SEND_SCEX
;--------------------------------------------------------------------------------
	IFDEF	SX48
                    snb           USA_FLAG
                    jmp           usa				;; idea for space usa flow trigger
                    snb           UK_FLAG
                    jmp           uk
                    jmp           jap
usa
                    clr           VAR_DC4
                    jmp           SCEx_IO_SET
uk
                    mov           w,#$8
                    mov           VAR_DC4,w
                    jmp           SCEx_IO_SET
jap
                    mov           w,#$4
                    mov           VAR_DC4,w
SCEx_IO_SET
                    mov           w,#$1f
                    mov           m,w
                    mov           w,#$b
                    mov           !ra,w
                    mov           w,#$4
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
next_byte
                    mov           w,VAR_DC4
                    call          SCEx_DATA
                    mov           VAR_PSX_BYTE,w
                    not           VAR_PSX_BYTE
                    mov           w,#$8
                    mov           VAR_PSX_BITC,w
                    call          SCEX_LOW
                    call          SCEX_LOW
                    call          SCEX_HI
send
                    rr            VAR_PSX_BYTE
                    snb           c
                    jmp           hi
                    sc            
                    call          SCEX_LOW
                    jmp           next2
hi
                    call          SCEX_HI
next2
                    decsz         VAR_PSX_BITC
                    jmp           send
                    inc           VAR_DC4
                    decsz         VAR_PSX_BC_CDDVD_TEMP
                    jmp           next_byte
                    clrb          IO_SCEX
                    mov           w,#$16
                    mov           VAR_DC4,w
send_end
                    call          SCEX_LOW
                    decsz         VAR_DC4
                    jmp           send_end
                    mov           w,#$1f
                    mov           m,w
                    mov           w,#$f
                    mov           !ra,w
                    ret    
	ELSE	
                    snb           JAP_FLAG
                    jmp           jap
                    snb           UK_FLAG
                    jmp           uk
                    clr           VAR_DC4
                    jmp           SCEx_IO_SET
uk
                    mov           w,#8;$8
                    mov           VAR_DC4,w
                    jmp           SCEx_IO_SET
jap
                    mov           w,#4;$4
                    mov           VAR_DC4,w
                    jmp           SCEx_IO_SET
SCEx_IO_SET
                    mov           w,#4;$4
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,#$b
                    mov           !ra,w
next_byte
                    mov           w,VAR_DC4
                    call          SCEx_DATA
                    mov           VAR_PSX_BYTE,w
                    not           VAR_PSX_BYTE
                    mov           w,#8;$8
                    mov           VAR_PSX_BITC,w
                    call          SCEX_LOW
                    call          SCEX_LOW
                    call          SCEX_HI
send
                    rr            VAR_PSX_BYTE
                    snb           c
                    jmp           hi
                    sc            
                    call          SCEX_LOW
                    jmp           next2
hi
                    call          SCEX_HI
next2
                    decsz         VAR_PSX_BITC
                    jmp           send
                    inc           VAR_DC4
                    decsz         VAR_PSX_BC_CDDVD_TEMP
                    jmp           next_byte
                    clrb          IO_SCEX
                    mov           w,#22;$16
                    mov           VAR_DC4,w
send_end
                    call          SCEX_LOW
                    decsz         VAR_DC4
                    jmp           send_end
                    mov           w,#$f
                    mov           !ra,w
                    ret          
	ENDIF

;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P1
;--------------------------------------------------------------------------------
                    snb           IO_BIOS_OE
                    jmp           BIOS_WAIT_OE_LO_P1
                    ret           
BIOS_GET_SYNC          
	; wait for "S201" seems to wait for "PS20" since 0.94
	;       0123456789ABC
	; Read "PS201?0?C200?xxxx.bin"
	IFDEF	SX48H2O75KJMPERSTRIM
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low	
                    nop
	ELSE
                    snb           IO_BIOS_OE					; next byte / wait for bios OE low
                    jmp           BIOS_GET_SYNC
                    nop           
	ENDIF
                    mov           w,#$50					; ASCII P	; is byte0 = 'P' seems to be new count prior for "PS201?0?C200?xxxx.bin"
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           BIOS_GET_SYNC
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low
                    mov           w,#$53					; ASCII S	; is byte1 (byte0 0.94) = 'S'	; v8 fix
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           BIOS_GET_SYNC
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low
                    mov           w,#$32					; ASCII 2	; is byte2 (byte1 0.94) = '2'
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           BIOS_GET_SYNC
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low
                    mov           w,#$30					; ASCII 0	; is byte3 (byte2 0.94) = '0'
                    mov           w,IO_BIOS_DATA-w
                    sb            z							;; alt v0 ident if C
                    jmp           BIOS_GET_SYNC
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low
CAPTURE_BIOS_REV
                    sb            IO_BIOS_OE					; next byte / wait for bios OE high ; skipping byte4 for x.00 of bios
                    jmp           CAPTURE_BIOS_REV
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low
                    mov           w,IO_BIOS_DATA
                    mov           VAR_BIOS_REV,w				; capture byte5 as VAR_BIOS_REV ; v1.x0 of bios rev
CAPTURE_BIOS_REGION
	IFDEF	SX48H2O75KJMPERSTRIM
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low	
	ELSE
                    snb           IO_BIOS_OE					; next byte / wait for bios OE low
                    jmp           CAPTURE_BIOS_REGION
                    nop           ;; extra sx28
	ENDIF
                    mov           w,#$30					; ASCII 0; is byte6 0 as fixed value check
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           CAPTURE_BIOS_REGION				;loop back to CAPTURE_BIOS_REGION if not ASCII 0
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low
                    mov           w,IO_BIOS_DATA
                    mov           VAR_BIOS_REGION_TEMP,w			;store byte7 in VAR_BIOS_REGION_TEMP
CHECK_BYTE_AB_REGION_CAPTURE_YR
	IFDEF	SX48H2O75KJMPERSTRIM
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low	
	ELSE
                    snb           IO_BIOS_OE					; next byte / wait for bios OE low
                    jmp           CHECK_BYTE_AB_REGION_CAPTURE_YR
                    nop		;; extra sx28
	ENDIF						
                    mov           w,#$30					; ASCII 0 is byteA
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           CHECK_BYTE_AB_REGION_CAPTURE_YR		;loopback if byteA not 0 CHECK_BYTE_AB_REGION_CAPTURE_YR
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low
                    mov           w,#$30					; ASCII 0 is byteB
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           CHECK_BYTE_AB_REGION_CAPTURE_YR		;loopback if byteB not 0 CHECK_BYTE_AB_REGION_CAPTURE_YR
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low
                    mov           w,IO_BIOS_DATA
                    mov           VAR_BIOS_YR,w					;captured byteC
                    mov           w,#$41					;is byte7 ASCII A usa bios
                    mov           w,VAR_BIOS_REGION_TEMP-w			;capture byte7 compare to VAR_BIOS_REGION_TEMP if A
                    snb           z						;if compare dont = 0 (A) skip next line
                    jmp           BIOS_USA
                    mov           w,#$57					;is byte7 ASCII W v14/75k+ bios
                    mov           w,VAR_BIOS_REGION_TEMP-w
                    snb           z
                    jmp           BIOS_V14
                    mov           w,#$45					;is byte7 ASCII E europe bios
                    mov           w,VAR_BIOS_REGION_TEMP-w			;capture byte7 compare to VAR_BIOS_REGION_TEMP if E
                    snb           z						;if compare dont = 0 (E) skip next line	
                    jmp           BIOS_UK
                    mov           w,#$52					;is byte7 ASCII R ; 'R', uk	; RUS 39008 fix ; russia region which is pal
                    mov           w,VAR_BIOS_REGION_TEMP-w			;capture byte7 compare to VAR_BIOS_REGION_TEMP if R
                    snb           z						;if compare dont = 0 (R) skip next line
                    jmp           BIOS_UK
                    mov           w,#$43					;is byte7  ASCII C ; china region which pal region but ps2 ntsc-c made
                    mov           w,VAR_BIOS_REGION_TEMP-w			;capture byte7 compare to VAR_BIOS_REGION_TEMP if C
                    snb           z						;if compare dont = 0 (C) skip next line
                    jmp           BIOS_UK
                    jmp           BIOS_JAP					; no match on byte7 compares, assumed is jap region
BIOS_USA
                    setb          USA_FLAG
                    jmp           RESTDOWN_CHK_PS2MODEorOTHER
BIOS_V14
                    setb          V14_FLAG
	
	IFDEF	H2O75KJMPERS
                    clrb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_f				; check if USA JMPER set for v14
                    jmp           BIOS_USA
	ENDIF
	IFDEF	USAv14
	jmp           BIOS_USA
	ENDIF
	
	IFDEF	JAPv14orv8
	jmp           BIOS_JAP
	ENDIF
	
BIOS_UK
                    setb          UK_FLAG
                    jmp           RESTDOWN_CHK_PS2MODEorOTHER
BIOS_JAP
                    setb          JAP_FLAG
RESTDOWN_CHK_PS2MODEorOTHER
                    snb           IO_REST
                    jmp           TAP_BOOT_MODE
;DVD movie : GREEN fix + MACROVISION off					
MACRO_CHECK_IF_V9to14
                    setb          PSX_FLAG
                    mov           w,#$30						; is bios 2.0 for v12 ;V12 use V910 kernel :)
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14
                    mov           w,#$37						; is bios 1.7 for v9-10 ;select KERNEL TYPE V9 or V10
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14
                    mov           w,#$39						; is bios 1.9 for v11
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14
                    snb           V14_FLAG						; is v14 flag set from W region, should work all decka 75k+
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14		
;V1-8 kernels: sync 1E006334 then 2410 					
                    mov           w,#50;$32						; v1-8 bios VAR_DC1 set fall over no match for
                    mov           VAR_DC1,w		
				
MACRO_BIOS_PATCH_SYNC_V1toV8
                    snb           IO_BIOS_OE
                    jmp           MACRO_BIOS_PATCH_SYNC_V1toV8
                    nop           
                    mov           w,#$1e
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           MACRO_BIOS_PATCH_SYNC_V1toV8
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           MACRO_BIOS_PATCH_SYNC_V1toV8
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$63
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           MACRO_BIOS_PATCH_SYNC_V1toV8
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$34
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           MACRO_BIOS_PATCH_SYNC_V1toV8
MACRO_BIOS_PATCH_SYNC_V1toV8_L1
                    snb           IO_BIOS_OE
                    jmp           MACRO_BIOS_PATCH_SYNC_V1toV8_L1
                    nop           
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           MACRO_BIOS_PATCH_SYNC_V1toV8_L1
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$10
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           MACRO_BIOS_PATCH_SYNC_V1toV8_L1
MACRO_BIOS_PATCH_SYNC_V1toV8_L2
                    sb            IO_BIOS_OE
                    jmp           MACRO_BIOS_PATCH_SYNC_V1toV8_L2			; next byte / wait for bios OE low
MACRO_BIOS_V1toV8_PATCH          snb           IO_BIOS_OE
                    jmp           MACRO_BIOS_V1toV8_PATCH
                    decsz         VAR_DC1
                    jmp           MACRO_BIOS_PATCH_SYNC_V1toV8_L2
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w					; preload IO_BIOS_DATA for 0 for when change to output
	IFDEF	SX48
                    mov           w,#$1f
                    mov           m,w
	ELSE		
                    mode          $000F							; XFh mode direction for RA, RB, RC output 
	ENDIF
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0							; 0000 0000
                    mov           !IO_BIOS_DATA,w					; IO_BIOS_DATA all pins output start patching here once sync
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0							;send 00,00,00,00
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
MACRO_BIOS_V1toV8_IORESET_INPUT
                    sb            IO_BIOS_OE
                    jmp           MACRO_BIOS_V1toV8_IORESET_INPUT			; last 00 patch before set input
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    jmp           MODE_SELECT_START					;exit KERNEL PATCH
; V9/V10/V12 kernels	
;kernel_V910					
;Kstart_l0
MACRO_BIOS_PATCH_SYNC_V9toV14
                    snb           IO_BIOS_OE
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14				; patch 25 10 43 00 to 00 00 00 00 
                    nop           
                    mov           w,#$dc
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14
MACRO_BIOS_PATCH_SYNC_V9toV14_L1
                    sb            IO_BIOS_OE
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14_L1
MACRO_BIOS_PATCH_SYNC_V9toV14_L2
                    snb           IO_BIOS_OE
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14_L2
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14
MACRO_BIOS_PATCH_SYNC_V9toV14_L3
                    sb            IO_BIOS_OE
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14_L3
MACRO_BIOS_PATCH_SYNC_V9toV14_L4
                    snb           IO_BIOS_OE
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14_L4
                    mov           w,#$10
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14
MACRO_BIOS_PATCH_SYNC_V9toV14_L5
                    sb            IO_BIOS_OE
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14_L5					
MACRO_BIOS_V9toV14_PATCH1
                    snb           IO_BIOS_OE
                    jmp           MACRO_BIOS_V9toV14_PATCH1
                    mov           w,#$45
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           MACRO_BIOS_PATCH_SYNC_V9toV14
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w					; preload IO_BIOS_DATA for 0 for when change to output
	IFDEF	SX48
                    mov           w,#$1f
                    mov           m,w
	ELSE							
                    mode          $000F							; XFh mode direction for RA, RB, RC output 
	ENDIF
                    mov           w,#$0							; 0000 0000
                    mov           !IO_BIOS_DATA,w					; IO_BIOS_DATA all pins output start patching here once sync
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0							;send 00,00,00,00
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$ff						; 1111 1111
                    mov           !IO_BIOS_DATA,w					; IO_BIOS_DATA all pins input patch end for more sync
					
;**************************************************************************************************
;New mode select for PSX/DEV mode :
;Check RESET for about 4 sec ( 2 =initial delay + 2 from this routine )
;if exit before then enter PSX mode , else wait for reset release and wait again for 
;10 sec. If RESET is pressed again within 10 sec. then enter DEV mode else 
;definitively SLEEP chip for all media that no need patch ( VIDEO , MUSIC , ORIGINALS ).
;**************************************************************************************************			
;TEST_RESET
MODE_SELECT_START
                    mov           w,#10;$a					; 10x100ms ;test RESET for about 1sec
                    mov           VAR_DC2,w
;test_l1
MODE_SELECT_TIMER_L1
                    call          DELAY100m
                    snb           IO_REST
                    jmp           HOLD_BOOT_MODES					
                    decsz         VAR_DC2					; repeat n jump to HOLD_BOOT_MODES if under 1sec so tap 1+1=2sec
                    jmp           MODE_SELECT_TIMER_L1					
MODE_SELECT_TIMER_L2
                    sb            IO_REST					;wait RESET release for PS1_MODE
                    jmp           MODE_SELECT_TIMER_L2
                    mov           w,#5;$5					;debounce RESET for about 0.5 sec buffer for not exact 2sec hold
                    mov           VAR_DC2,w
;test_l2					
MODE_SELECT_TIMER_L3
                    call          DELAY100m					;test RESET again for about 10.0 sec.
                    decsz         VAR_DC2
                    jmp           MODE_SELECT_TIMER_L3
                    mov           w,#100;$64
                    mov           VAR_DC2,w 
;test_l3					
DISABLE_MODE
                    call          DELAY100m					;4secs = DISABLE_MODE but retap of reset within 10sec for DEV1
                    sb            IO_REST					;resetted ...enter DEV mode
                    page          $0600
                    jmp           DEV1_MODE_LOAD_START
                    decsz         VAR_DC2
                    jmp           DISABLE_MODE					;...sleep chip , can't wake up without put PS2 into stby
                    sleep         
;RESET0					
TAP_BOOT_MODE
                    clr           fsr
                    clrb          PSX_FLAG
;RESET_DOWN					
HOLD_BOOT_MODES
                    snb           DEV1_FLAG					;reenter dev mode if rest in dev mode
                    page          $0600
                    jmp           DEV1_MODE_LOAD_START
                    setb          SOFT_RST					;soft reset may need more than 1 disk patch  he he he ....
                    clrb          EJ_FLAG
                    setb          X_FLAG					;first XMAN patch flag
                    clrb          V12LOGO_FLAG					;clear V12 logo flag patch
                    page          $0200
                    jmp           PS2_MODE_START				;PS2 osd patch or PS1DRV init... (based on psx_flag status)
					
				

;---------------------------------------------------------------------
;PS2 : continue patch after  OSDSYS & wait for disk ready...
;---------------------------------------------------------------------
;PS2_PATCH2
CHECK_IF_START_PS2LOGO
                    clr           fsr
                    sb            PSX_FLAG
                    page          $0400
                    jmp           START_PS2LOGO_PATCH_LOAD
;CDDVD_EJECTED					
TRAY_IS_EJECTED
                    sb            IO_REST					;here from eject
                    jmp           TAP_BOOT_MODE					;reset
                    snb           IO_EJECT
                    jmp           TRAY_IS_EJECTED				;wait for tray closed...
;wait for bios cs inactive ( fix for  5 bit bus and cd boot )					
;DELAY1s
RESUME_MODE_FROM_EJECT
                    mov           w,#5;$5					;Precise delay routine using RTCC
                    mov           VAR_DC2,w
;ld_del0					
RESUME_MODE_FROM_EJECT_L1
                    mov           w,#100;$64					;delay = 100 millisec.
                    mov           VAR_DC1,w
;ld_del					
RESUME_MODE_FROM_EJECT_L2
                    mov           w,#61;59;$3b					;load  timer=61,delay = (256-61)*256*0.02 micros.= 1000 micros.
                    mov           rtcc,w
;ld_del1					
RESUME_MODE_FROM_EJECT_L3
                    sb            IO_BIOS_CS					;wait again 500msec if bios cs active
                    jmp           RESUME_MODE_FROM_EJECT
                    sb            IO_REST					;new reset check here ...	
                    jmp           TAP_BOOT_MODE
                    snb           IO_EJECT
                    jmp           TRAY_IS_EJECTED				;
                    mov           w,rtcc					;wait for timer= 0 ... (don't use TEST RTCC)
                    sb            z
                    jmp           RESUME_MODE_FROM_EJECT_L3
                    decsz         VAR_DC1
                    jmp           RESUME_MODE_FROM_EJECT_L2
                    decsz         VAR_DC2
                    jmp           RESUME_MODE_FROM_EJECT_L1
                    call          SET_INTRPT					;better here ....
                    clr           fsr
                    snb           DEV1_FLAG
                    page          $0600
                    jmp           START_CDDVD_PATCH				;patch media for DEVMODE
                    mov           w,#2;$2
                    mov           VAR_DC4,w
                    mov           w,#$32					;ASCI 2
                    mov           w,VAR_BIOS_YR-w				; is 2002 Year console
                    snb           z
                    jmp           CONSOLE_2002_JMP				;# of ps2logo patch for PS2 V7
                    mov           w,#1;$1
                    mov           VAR_DC4,w
;MEPATCH					
CONSOLE_2002_JMP
                    page          $0600
	IFDEF	H2O75KJMPERS
                    clrb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_f				; Check USA JMPER here for v8 Jap console
                    setb          JAP_V8
	ENDIF						
	IFDEF	JAPv14orv8
                    setb          JAP_V8
	ENDIF						
                    jmp           START_CDDVD_PATCH				;patch ps2 CD/DVD
					
					
;-------------------------------------------------------------------------
;NEW NEW NEW patch psx game... and some protected too 
;-------------------------------------------------------------------------	
;PSX_PATCH
PS1_MODE_START_PATCH
                    clr           fsr
                    clrb          SCEX_FLAG
                    mov           w,#$ff
                    mov           VAR_PSX_TEMP,w				;autosend correct # of SCEX (max value help bad optics) ;)
;psx_ptc_l0
RUN_PS1_SCEX_INJECT
                    call          SEND_SCEX
                    snb           SCEX_FLAG
                    jmp           PS1_SCEX_INJECT_COMPLETE
                    decsz         VAR_PSX_TEMP					; loop sending SCEX
                    jmp           RUN_PS1_SCEX_INJECT
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
;DRVPTC					
PS1_SCEX_INJECT_COMPLETE
                    snb           EJ_FLAG
                    jmp           RUN_PS1_SCEX_INJECT				;send all scex after bios patch then sleep
                    mov           w,#2;$2
                    mov           VAR_DC4,w					;# of PS1DRV patch for PS2 V7
                    mov           w,#$32
                    mov           w,VAR_BIOS_YR-w
                    snb           z
                    jmp           PS1_IS_V14orV1toV12PALorNTSC
                    mov           w,#1;$1
                    mov           VAR_DC4,w
;DRV					
PS1_IS_V14orV1toV12PALorNTSC
                    snb           V14_FLAG					; check if V14_FLAG set meaning v14/75k decka
                    jmp           PS1_V14_PATCH
                    snb           UK_FLAG					; fix for ntsc/pal ps1 route v1-12
                    page          $0400
                    jmp           PS1_CONSOLE_PAL_YFIX				; jmp to pal start if pal console
                    page          $0400
                    jmp           PS1_LOGO_PATCH				; fall over to ntsc start if no pal flag set
;V14DRV1
PS1_V14_PATCH
                    mov           w,#49;$31
                    mov           VAR_DC2,w
                    mov           w,#$1
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,#$40
                    mov           VAR_PSX_TEMP,w
                    mov           w,#$1b
                    mov           VAR_PSX_BITC,w
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    page          $0400
                    jmp           PS2_PS2LOGO::loop00x				;exec psxdrv patch + logo1 + set EJect flag and ret to PSX_PATCH

                    org           $0200						; PAGE2 200-3FF

;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P2
;--------------------------------------------------------------------------------

                    snb           IO_BIOS_OE					; next byte / wait for bios OE low
                    jmp           BIOS_WAIT_OE_LO_P2        			; next byte / wait for bios OE low
                    ret           

;---------------------------------------------------------
; NEW BIOS PATCH ROUT
;---------------------------------------------------------
;--------------------------------------------------------------------------------
RUN_BIOS_PATCHES_SRAM
;--------------------------------------------------------------------------------
	IFDEF	SX48RAM
                    mov           w,indf
                    mov           IO_BIOS_DATA,w
                    inc           fsr
RUN_BIOS_PATCHES_SRAM_SENDLOOP
                    snb           IO_BIOS_OE
                    jmp           RUN_BIOS_PATCHES_SRAM_SENDLOOP
                    decsz         VAR_DC2
                    jmp           RUN_BIOS_PATCHES_SRAM
END_BIOS_PATCHES_SRAM_RESET_IO
                    sb            IO_BIOS_OE
                    jmp           END_BIOS_PATCHES_SRAM_RESET_IO
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    clr           fsr
                    retp 
	ELSE		

                    mov           w,indf					; SRAM address moved to w and output to  IO_BIOS_DATA
                    mov           IO_BIOS_DATA,w
                    inc           fsr						; +1 to step through the SRAM cached patches
                    mov           w,#$10					; 10h or so always in SRAM address section 6.2.1
                    or            fsr,w						; so that ends in top address of registery which is SRAM access. bottom 0-f reserved so when gets 1f goes 30h than 20h
RUN_BIOS_PATCHES_SRAM_SENDLOOP
                    snb           IO_BIOS_OE					; next byte / wait for bios OE low
                    jmp           RUN_BIOS_PATCHES_SRAM_SENDLOOP		; jmp RUN_BIOS_PATCHES_SRAM_SENDLOOP if IO_BIOS_OE high
                    decsz         VAR_DC2					; loop calling of SRAM cache till VAR_DC2=0 then patch finished, VAR_DC2 set in loading of call here for ea patch
                    jmp           RUN_BIOS_PATCHES_SRAM
END_BIOS_PATCHES_SRAM_RESET_IO
                    sb            IO_BIOS_OE					; next byte / wait for bios OE high
                    jmp           END_BIOS_PATCHES_SRAM_RESET_IO		; jmp END_BIOS_PATCHES_SRAM_RESET_IO if IO_BIOS_OE high
                    mov           w,#$ff					; 1111 1111
                    mov           !IO_BIOS_DATA,w				; all pins Hi-Z input
                    clr           fsr						;moved here !
                    retp          						; patching done. Return from call
	ENDIF
;----------------------------------------------------------
;Patch PS2 game...
;----------------------------------------------------------
;--------------------------------------------------------------------------------
OSDSYS_BIOS_PATCH_DATA			;osdsys
;--------------------------------------------------------------------------------
                    jmp           pc+w
;V134
                    retw          $23	; 0
                    retw          $80	; 1
                    retw          $ac	; 2
                    retw          $c	; 3
                    retw          $0	; 4
                    retw          $0	; 5
                    retw          $0	; 6
;VX
                    retw          $24	; 7
                    retw          $10	; 8
                    retw          $3c	; 9
                    retw          $e4	; 10
                    retw          $24	; 11
                    retw          $80	; 12
                    retw          $ac	; 13
                    retw          $e4	; 14
                    retw          $22	; 15
                    retw          $90	; 16
                    retw          $ac	; 17
                    retw          $84	; 18
                    retw          $bc	; 19
                    mov           w,#79;$4f	; 20
                    mov           VAR_DC3,w	; 21							;;79 ; #### ber
                    jmp           OSDSYS_BIOS_PATCH_DATA_PART2_ALL	; 22
;V9
                    retw          $24	; 23
                    retw          $10	; 24
                    retw          $3c	; 25
                    retw          $74	; 26
                    retw          $2a	; 27
                    retw          $80	; 28
                    retw          $ac	; 29
                    retw          $74	; 30
                    retw          $28	; 31
                    retw          $90	; 32
                    retw          $ac	; 33
                    retw          $bc	; 34
                    retw          $d3	; 35
                    mov           w,#79;$4f	; 36
                    mov           VAR_DC3,w	; 37
                    jmp           OSDSYS_BIOS_PATCH_DATA_PART2_ALL	; 38
;V14
                    retw          $24	; 39 ;; +8 = 47
                    retw          $10	; 40
                    retw          $3c	; 41
                    retw          $78	; 42
                    retw          $2d	; 43
                    retw          $80	; 44
                    retw          $ac	; 45
                    retw          $40	; 46
                    retw          $2b	; 47
                    retw          $90	; 48
                    retw          $ac	; 49
                    retw          $a0	; 50
                    retw          $ff	; 60
					
                    mov           w,#79;$4f	; 61
                    mov           VAR_DC3,w	; 62
                    jmp           OSDSYS_BIOS_PATCH_DATA_PART2_ALL	; 63
;V10-12
                    retw          $24	; 64 ;; 39  +8 = 47
                    retw          $10	; 65
                    retw          $3c	; 66
                    retw          $e4	; 67
                    retw          $2c	; 68
                    retw          $80	; 69
                    retw          $ac	; 70
                    retw          $f4	; 71
                    retw          $2a	; 72
                    retw          $90	; 73
                    retw          $ac	; 74
					
                    snb           V12_FLAG	; 75
                    jmp           V12_CONSOLE_20_BIOS_JMP	; 76
                    mov           w,#70;$46	; 77
                    mov           VAR_DC3,w	; 78	;; 54 + 16 = 70
                    retw          $a4	; 79
                    retw          $ec	; 80
                    mov           w,#79;$4f	; 81
                    mov           VAR_DC3,w	; 82	;; 63 + 16 = 79
                    jmp           OSDSYS_BIOS_PATCH_DATA_PART2_ALL	; 83
;v12		
V12_CONSOLE_20_BIOS_JMP
                    mov           w,#77;$4d	; 84
                    mov           VAR_DC3,w	; 85	;; 61 + 16 = 77
                    retw          $c	; 86
                    retw          $f9	; 87
;LOAD_END
OSDSYS_BIOS_PATCH_DATA_PART2_ALL
                    retw          $91	; 88	;; 63    + 8  = 71          ;;79
                    retw          $34	; 89
                    retw          $0	; 90
                    retw          $0	; 91
                    retw          $30	; 92
                    retw          $ae	; 93
                    retw          $c	; 94
                    retw          $0	; 95
                    retw          $0	; 96
                    retw          $0	; 97
;LOAD_PSX1D					
                    retw          $c7	; 98	;; 73
                    retw          $2	; 99
                    retw          $34	; 100
                    retw          $19	; 101
                    retw          $19	; 102
                    retw          $e2	; 103
                    retw          $ba	; 104
                    retw          $11	; 105
                    retw          $19	; 106
                    retw          $e2	; 107
                    retw          $ba	; 108
;V14 jmp back					
                    retw          $3c	; 109	;; 71       + 8 = 79
                    retw          $c7	; 110	;; 73
                    retw          $2	; 111
                    retw          $34	; 112
			IFDEF NTSCPS1YFIX75K
			        retw          $29	; 113		;19pal/29ntsc yfix pal console
            ELSE
					retw          $19;$29	; 113		;19pal/29ntsc yfix pal console
			ENDIF
                    retw          $19	; 114
                    retw          $c2	; 115
                    retw          $bb	; 116
			IFDEF NTSCPS1YFIX75K
                    retw          $21	; 117		;11pal/21ntsc yfix pal console	
			ELSE
                    retw          $11;$21	; 117		;11pal/21ntsc yfix pal console
			ENDIF
                    retw          $19	; 118
                    retw          $c2	; 119
                    retw          $bb	; 120
					
                    retw          $60	; 121
                    retw          $9	; 122
                    retw          $8	; 123
                    retw          $8	; 124
					
;PS2_PATCH					
PS2_MODE_START
;load osdsys data patch for PS2 mode or ps1drv data patch for PSX mode 
                    clr           fsr
                    sb            PSX_FLAG
                    jmp           PS2_CHECK_IF_V1_v2or3_V4_V5to8			;ps2 mode selected , skip 
                    snb           V14_FLAG
                    page          $0400
                    jmp           PS1DRV_PATCHLOAD_v14
                    mov           w,#11;$b
                    mov           VAR_DC1,w					;psx mode : # of patch bytes  
                    mov           w,#$59					; 89 ;ps1drv data offset here ...
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_psx2					
PS2_CHECK_IF_V1_v2or3_V4_V5to8
;ps2 mode data offset 
                    clr           fsr
                    snb           V14_FLAG
                    jmp           CHECK_V9to14_REV				;jmp CHECK_V9to14_REV if CHECK_V9to14_REV set meaning W v14/75k+
                    mov           w,#$31					;ascii 1
                    mov           w,VAR_BIOS_REV-w				;does VAR_BIOS_REV = 1		;v1
                    snb           z						;skip next line if doesnt = 0 meaning is 1 ascii
                    jmp           V1_CONSOLE_11_BIOS				;jmp V1_CONSOLE_11_BIOS if VAR_BIOS_REV did = 1 ascii
                    mov           w,#$32					;ascii 2
                    mov           w,VAR_BIOS_REV-w				;does VAR_BIOS_REV = 2		;v2-3
                    snb           z						;skip next line if doesnt = 0 meaning is 2 ascii
                    jmp           V2or3_CONSOLE_12_BIOS				;jmp V2or3_CONSOLE_12_BIOS if VAR_BIOS_REV did = 2 ascii
                    mov           w,#$35					;ascii 5
                    mov           w,VAR_BIOS_REV-w				;does VAR_BIOS_REV = 5		;v4
                    snb           z						;skip next line if doesnt = 0 meaning is 5 ascii
                    jmp           V4_CONSOLE_15_BIOS				;jmp V4_CONSOLE_15_BIOS if VAR_BIOS_REV did = 5 ascii
                    jmp           CHECK_V9to14_REV				;jmp CHECK_V9to14_REV if VAR_BIOS_REV didnt = 5 ascii
;:set_V1					
V1_CONSOLE_11_BIOS
                    mov           w,#$c0
                    mov           IO_BIOS_DATA,w
                    mov           w,#176;$b0
                    mov           VAR_DC3,w
                    mov           w,#116;$74
                    mov           VAR_DC4,w
                    jmp           V1to8_CONTIUNE
;:set_V3					
V2or3_CONSOLE_12_BIOS
                    mov           w,#$d8
                    mov           IO_BIOS_DATA,w
                    mov           w,#64;$40
                    mov           VAR_DC3,w
                    mov           w,#122;$7a
                    mov           VAR_DC4,w
                    jmp           V1to8_CONTIUNE
;:set_V4					
V4_CONSOLE_15_BIOS
                    mov           w,#96;$60
                    mov           VAR_DC3,w
                    mov           w,#125;$7d
                    mov           VAR_DC4,w
                    mov           w,#12;$c
                    mov           IO_BIOS_DATA,w
;:set_P					
V1to8_CONTIUNE
                    mov           w,#7;$7						; V5678
                    mov           VAR_DC1,w
                    mov           VAR_DC2,w
                    clr           w
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_Vx					
CHECK_V9to14_REV
                    mov           w,#$2
                    mov           IO_BIOS_DATA,w
                    mov           w,#23;$17
                    mov           VAR_DC1,w
                    mov           VAR_DC2,w					; VAR_DC1 VAR_DC2 = 17h = 23
                    mov           w,#$37					;ascii 7
                    mov           w,VAR_BIOS_REV-w				;does VAR_BIOS_REV = 7 ;1.7bios v9-11 50k
                    snb           z
                    jmp           V9_CONSOLE_17_BIOS
                    mov           w,#$39					;ascii 9
                    mov           w,VAR_BIOS_REV-w				;does VAR_BIOS_REV = 9 ;1.9bios v9-11 50k
                    snb           z
                    jmp           V9_CONSOLE_19_BIOS
                    mov           w,#$30					;ascii 0
                    mov           w,VAR_BIOS_REV-w				;does VAR_BIOS_REV = 0 ;2.0bios v12
                    snb           z
                    jmp           V12_CONSOLE_20_BIOS
                    mov           w,#$32
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           V14_CONSOLE_22_BIOS
                    mov           w,#48;$30
                    mov           VAR_DC3,w
                    mov           w,#125;$7d
                    mov           VAR_DC4,w
                    mov           w,#7;$7						; V5678
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V9					
V9_CONSOLE_17_BIOS
                    mov           w,#4;$4
                    mov           VAR_DC3,w
                    mov           w,#148;$94
                    mov           VAR_DC4,w
                    mov           w,#23;$17
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V14					
V14_CONSOLE_22_BIOS
                    setb          V10_FLAG
                    setb          V14_FLAG
                    mov           w,#212;$d4
                    mov           VAR_DC3,w
                    mov           w,#169;$a9
                    mov           VAR_DC4,w
                    mov           w,#39;$27
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V10					
V9_CONSOLE_19_BIOS
                    setb          V10_FLAG
                    mov           w,#100;$64
                    mov           VAR_DC3,w
                    mov           w,#158;$9e
                    mov           VAR_DC4,w
                    mov           w,#55;$37
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V12					
V12_CONSOLE_20_BIOS
                    setb          V10_FLAG
                    setb          V12_FLAG
                    mov           w,#124;$7c
                    mov           VAR_DC3,w
                    mov           w,#169;$a9
                    mov           VAR_DC4,w
                    mov           w,#55;$37
;:loopxx					
ALL_CONTIUNE_BIOS_PATCH
                    snb           DEV1_FLAG
                    jmp           LOAD_PATCH_DEV1_STACK
                    mov           VAR_DC3,w
	IFDEF	SX48RAM
                    mov           w,#$10
	ELSE						
                    mov           w,#$15
	ENDIF					
                    mov           fsr,w
;:loop					
LOAD_OSDSYS_BIOS_PATCH_DATA
                    mov           w,VAR_DC3
                    call          OSDSYS_BIOS_PATCH_DATA
                    mov           indf,w					
                    inc           fsr
	IFDEF	SX48RAM

	ELSE						
                    mov           w,#$10
                    or            fsr,w
	ENDIF					
                    inc           VAR_DC3				; VAR_DC3 starting point and increased as retw and steps			
                    decsz         VAR_DC1				; VAR_DC1 lenght of patch to load decresing as retw
                    jmp           LOAD_OSDSYS_BIOS_PATCH_DATA
                    clr           fsr
                    snb           PSX_FLAG
                    page          $0000
                    jmp           TRAY_IS_EJECTED				;PS2_PATCH2		;exit osd patch if psx mode selected ...
					
;:loop0					
; OSDSYS Wait for 60 00 04 08 ... fixed for V10 :)					
OSDSYS_BIOS_PATCH_SYNC
                    snb           IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC
                    mov           w,#$60
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           OSDSYS_BIOS_PATCH_SYNC
OSDSYS_BIOS_PATCH_SYNC_LOOP1
                    sb            IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_LOOP1
OSDSYS_BIOS_PATCH_SYNC_LOOP2
                    snb           IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_LOOP2
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           OSDSYS_BIOS_PATCH_SYNC
OSDSYS_BIOS_PATCH_SYNC_LOOP3
                    sb            IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_LOOP3
OSDSYS_BIOS_PATCH_SYNC_LOOP4
                    snb           IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_LOOP4
                    mov           w,#$4
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           OSDSYS_BIOS_PATCH_SYNC
OSDSYS_BIOS_PATCH_SYNC_LOOP5
                    sb            IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_LOOP5
OSDSYS_BIOS_PATCH_SYNC_LOOP6
                    snb           IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_LOOP6
                    mov           w,#$8
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           OSDSYS_BIOS_PATCH_SYNC
	IFDEF	SX48RAM
                    mov           w,#$10;15
	ELSE						
                    mov           w,#$15
	ENDIF
                    mov           fsr,w
					
;-----------------------------------------------------------
; Patch data for bios OSDSYS 
;-----------------------------------------------------------
;:loop1
OSDSYS_BIOS_PATCH_SYNC_P2
                    snb           IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_P2
                    mov           w,#$7
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           OSDSYS_BIOS_PATCH_SYNC_P2
OSDSYS_BIOS_PATCH_SYNC_P3
                    snb           IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_P3
                    mov           w,#$3
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           OSDSYS_BIOS_PATCH_SYNC_P3
;:loop66					
OSDSYS_BIOS_PATCH_SYNC_P4
                    sb            IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_P4
OSDSYS_BIOS_PATCH_SYNC_P4_L1
                    snb           IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_P4_L1
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           OSDSYS_BIOS_PATCH_SYNC_P3
OSDSYS_BIOS_PATCH_SYNC_P4_L2
                    sb            IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_P4_L2
                    mov           !IO_BIOS_DATA,w
OSDSYS_BIOS_PATCH_SYNC_P4_L3
                    snb           IO_BIOS_OE
                    jmp           OSDSYS_BIOS_PATCH_SYNC_P4_L3
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    snb           DEV1_FLAG
                    page          $0600
                    jmp           FINISHED_RUN_START
                    snb           V12LOGO_FLAG
                    page          $0400
                    jmp           PS2_PS2LOGO:back			;logo patch for V12
                    page          $0000
                    jmp           CHECK_IF_START_PS2LOGO			;end of osd patch
	IFDEF	SX48RAM
;SETUPDEV				
LOAD_PATCH_DEV1_STACK
                    mov           w,#$17;1c
                    mov           fsr,w
                    mov           w,VAR_DC3
                    mov           indf,w
                    inc           fsr
                    mov           w,VAR_DC4
                    mov           indf,w
                    clr           fsr
                    mov           w,#$4
                    mov           IO_BIOS_DATA,w
                    mov           w,#$77
                    mov           VAR_DC2,w
                    page          $0200
                    jmp           OSDSYS_BIOS_PATCH_SYNC

SET_V14DRV
                    mov           w,#$1f;34
                    mov           fsr,w
                    mov           w,#$14
                    mov           indf,w
                    inc           fsr
                    mov           w,#$2
                    mov           indf,w
                    mov           w,#$2b;50
                    mov           fsr,w
                    mov           w,#$20
                    mov           indf,w
                    mov           w,#$2f;54
                    mov           fsr,w
                    mov           w,#$5c
                    mov           indf,w
                    inc           fsr
                    mov           w,#$25
                    mov           indf,w
                    mov           w,#$35;5a
                    mov           fsr,w
                    mov           w,#$8
                    mov           indf,w
                    mov           w,#16;$10
                    mov           VAR_DC1,w
                    mov           w,#100;$64
                    mov           VAR_DC3,w
                    mov           w,#$37;5c
                    mov           fsr,w
                    page          $0200						; PAGE2
                    jmp           LOAD_OSDSYS_BIOS_PATCH_DATA
	ELSE						
;SETUPDEV				
LOAD_PATCH_DEV1_STACK
                    mov           w,#$1c
                    mov           fsr,w
                    mov           w,VAR_DC3
                    mov           indf,w
                    inc           fsr
                    mov           w,VAR_DC4
                    mov           indf,w
                    clr           fsr
                    mov           w,#$4
                    mov           IO_BIOS_DATA,w
                    mov           w,#115;$73
                    mov           VAR_DC2,w
                    page          $0200
                    jmp           OSDSYS_BIOS_PATCH_SYNC
					
					
SET_V14DRV
                    mov           w,#$34
                    mov           fsr,w
                    mov           w,#$14
                    mov           indf,w
                    inc           fsr
                    mov           w,#$2
                    mov           indf,w
                    mov           w,#$50
                    mov           fsr,w
                    mov           w,#$20
                    mov           indf,w
                    mov           w,#$54
                    mov           fsr,w
                    mov           w,#$5c
                    mov           indf,w
                    inc           fsr
                    mov           w,#$25
                    mov           indf,w
                    mov           w,#$5a
                    mov           fsr,w
                    mov           w,#$8
                    mov           indf,w
                    mov           w,#16;$10
                    mov           VAR_DC1,w
                    mov           w,#100;$64
                    mov           VAR_DC3,w
                    mov           w,#$5c
                    mov           fsr,w
                    page          $0200						; PAGE2
                    jmp           LOAD_OSDSYS_BIOS_PATCH_DATA
	ENDIF					
					
;----------------------------------------------------------
;XCDVDMAN routine
;---------------------------------------------------------- 

IS_XCDVDMANX
                    page          $0000						; PAGE1
                    call          SET_INTRPT
					
IS_XCDVDMAN
                    snb           DEV1_FLAG
                    page          $0600
                    jmp           FINISHED_RUN_START_P2
                    mov           w,#200;100;$64					; 100
                    mov           VAR_DC4,w					; 30-35 sec wait for BIOS

IS_XCDVDMAN:loop4
                    mov           w,#255;$ff
                    mov           VAR_DC3,w				
IS_XCDVDMAN:loop3
                    mov           w,#255;$ff
                    mov           VAR_DC2,w			
IS_XCDVDMAN:loop2
                    mov           w,#255;$ff
                    mov           VAR_DC1,w				
IS_XCDVDMAN:loopx
                    sb            IO_BIOS_CS
                    jmp           IS_XCDVDMAN:loop1
                    decsz         VAR_DC1
                    jmp           IS_XCDVDMAN:loopx
                    decsz         VAR_DC2
                    jmp           IS_XCDVDMAN:loop2
                    decsz         VAR_DC3
                    jmp           IS_XCDVDMAN:loop3
                    decsz         VAR_DC4
                    jmp           IS_XCDVDMAN:loop4
                    jmp           PS2_MODE_RB_IO_SET_SLEEP			; no xcdvdman reload ...
										
IS_XCDVDMAN:loop0
                    snb           IO_BIOS_CS
                    jmp           IS_XCDVDMAN:loopx					
IS_XCDVDMAN:loop1
                    mov           w,#$a2					;sync A2 93 23 for V1-V10
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           IS_XCDVDMAN:loop0
                    call          BIOS_WAIT_OE_LO_P2
                    mov           w,#$93
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           IS_XCDVDMAN:loop0
                    call          BIOS_WAIT_OE_LO_P2
                    mov           w,#$34
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           IS_XCDVDMAN:loop0
;XCDVDMAN					
                    clr           fsr
                    mov           w,#7;$7
                    mov           VAR_DC2,w
                    mov           w,#$8
                    mov           IO_BIOS_DATA,w				;send 08					
xcdvdman1_l0a
                    snb           IO_BIOS_OE
                    jmp           xcdvdman1_l0a
                    mov           w,#$27					;27 18 00 A3 (A3)
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           xcdvdman1_l0a
                    call          BIOS_WAIT_OE_LO_P2
                    mov           w,#$18
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           xcdvdman1_l0a
                    call          BIOS_WAIT_OE_LO_P2
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           xcdvdman1_l0a
                    call          BIOS_WAIT_OE_LO_P2
                    mov           w,#$a3
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           xcdvdman1_l0a
; patch it
; Addr 00006A28 export 0x23(Cd Check) kill it
; 00006A28: 08 00 E0 03  jr ra
; 00006A2C: 00 00 00 00  nop					
                    snb           X_FLAG					;first XMAN executed !
                    jmp           xcdvdman_patch_again
;xcdvdman1_next					
	IFDEF	SX48RAM
                    mov           w,#$10;15
	ELSE	
                    mov           w,#$15
	ENDIF
                    mov           fsr,w					
xcdvdman1_l1
                    snb           IO_BIOS_OE
                    jmp           xcdvdman1_l1
                    nop           
                    mov           w,#$27
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           xcdvdman1_l1
xcdvdman1_l1_P2
                    sb            IO_BIOS_OE
                    jmp           xcdvdman1_l1_P2
                    mov           !IO_BIOS_DATA,w
xcdvdman_patch
                    snb           IO_BIOS_OE
                    jmp           xcdvdman_patch
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    sb            EJ_FLAG
                    page          $0000
                    jmp           TRAY_IS_EJECTED				;jump to EJECTED if no EJ_FLAG = first xman patch for originals
                    jmp           IS_XCDVDMAN			;? da verificare !!!
;again
xcdvdman_patch_again
                    clrb          X_FLAG
                    jmp           IS_XCDVDMAN			;patch cddvdman & xcdvdman

;TO SLEEP ... , PERHARPS TO DREAM ...
PS2_MODE_RB_IO_SET_SLEEP
                    mode          $000A						; XAh WKED_B Each register bit selects the edge sensitivity of the corresponding Port B input pin for MIWU operation. ;todo
                    mov           w,#$6						; 0000 0110 Set the bit to 1 to sense falling (high-to-low) edges.
                    mov           !IO_CDDVD_BUS,w				; rb.1 IO_BIOS_CS rb.2 IO_REST high-to-low sense
                    mode          $0009						; X9h Exchange WKPND_B
                    clr           w						; 0000 0000
                    mov           !IO_CDDVD_BUS,w				; A bit set to 1 indicates that a valid edge has occurred on the corresponding MIWU pin, triggering a wakeup or interrupt. 
										; A bit set to 0 indicates that no valid edge has occurred on the MIWU pin. 
										; The WKPND_B register comes up with undefine value upon reset.
                    mode          $000B						; XBh WKEN_B	Multi-Input Wakeup/Interrupt (MIWU) function for the corresponding Port B input pin. 
										; Clear the bit to 0 to enable MIWU operation or set the bit to 1 to disable MIWU operation.
                    snb           PSX_FLAG					; jmp PS1_MODE_RB_IO_SET_SLEEP if PSX_FLAG is set
                    jmp           PS1_MODE_RB_IO_SET_SLEEP			; skip below io set and jmp PS1_MODE_RB_IO_SET_SLEEP
                    mov           w,#$f1					; 1111 0001
                    mov           !IO_CDDVD_BUS,w				; rb.1 IO_BIOS_CS rb.2 IO_REST rb.3 IO_EJECT enabled
                    sleep         
					
PS1_MODE_RB_IO_SET_SLEEP
                    mov           w,#$f3					; 1111 0011
                    mov           !IO_CDDVD_BUS,w				; rb.2 IO_REST rb.3 IO_EJECT enabled
                    sleep         

                    org           $0400						; PAGE4 400-5FF

;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P4
;--------------------------------------------------------------------------------
                    snb           IO_BIOS_OE
                    jmp           BIOS_WAIT_OE_LO_P2
                    ret           

;--------------------------------------------------------------------------------
PS2LOGO_PATCH
;--------------------------------------------------------------------------------
                    jmp           pc+w
;LOAD_XMAN					
                    retw          $0	; 0
                    retw          $e0	; 1
                    retw          $3	; 2
                    retw          $21	; 3
                    retw          $10	; 4
                    retw          $0	; 5
                    retw          $0	; 6
					
                    mov           w,#51;$33	; 7
                    mov           VAR_DC3,w	; 8
                    sb            V14_FLAG	; 9
                    jmp           PS2LOGO_PATCH_not22_JMP1	; 10
;v14				
                    mov           w,#13;$d	; 11
                    mov           VAR_DC3,w	; 12
                    retw          $40	; 13
                    retw          $8	; 14
                    retw          $11	; 15
                    retw          $3c	; 16
                    retw          $8	; 17
                    retw          $0	; 18
                    retw          $32	; 19
                    retw          $36	; 20
					
                    retw          $f8	; 21
                    retw          $1	; 22
					
                    retw          $92	; 23
                    retw          $ac	; 24
					
                    retw          $21	; 25
                    retw          $0	; 26
                    retw          $40	; 27
                    retw          $8	; 28
					
                    retw          $b	; 29
                    retw          $0	; 30
                    retw          $32	; 31
                    retw          $36	; 32
					
                    retw          $10	; 33
                    retw          $0	; 34
                    retw          $4	; 35
                    retw          $3c	; 36
					
                    retw          $18	; 37
                    retw          $16	; 38
					
                    retw          $92	; 39
                    retw          $ac	; 40
					
                    retw          $0	; 41
                    retw          $0	; 42
                    retw          $4	; 43
                    retw          $8	; 44
					
                    mov           w,#70;$46	; 45
                    mov           VAR_DC3,w	; 46
                    snb           V14_FLAG	; 47
                    jmp           PS2LOGO_PATCH_22_JMP2	; 48
;not v14 patches, how flows?					
                    mov           w,#51;$33	; 49
                    mov           VAR_DC3,w	; 50
;v12					
PS2LOGO_PATCH_not22_JMP1
                    retw          $8	; 51
                    retw          $11	; 52
                    retw          $3c	; 53
                    retw          $c1	; 54
                    retw          $0	; 55
                    retw          $32	; 56
                    retw          $36	; 57
                    retw          $18	; 58
                    retw          $16	; 59
                    retw          $92	; 60
                    retw          $ac	; 61
                    retw          $c	; 62
                    retw          $0	; 63
                    retw          $0	; 64
                    retw          $0	; 65
LOGO2					

                    retw          $0	; 66
                    retw          $0	; 67
                    retw          $0	; 68
                    retw          $0	; 69
PS2LOGO_PATCH_22_JMP2			; fix for v14 stablity jmp instead of LOGO2
                    retw          $20	; 70
                    retw          $38	; 71
                    retw          $11	; 72
                    retw          $0	; 73
                    retw          $0	; 74
                    retw          $60	; 75			;;60
                    retw          $3	; 76
                    retw          $24	; 77
                    retw          $0	; 78
                    retw          $0	; 79
                    retw          $e2	; 80
                    retw          $90	; 81
                    retw          $0	; 82
                    retw          $0	; 83
                    retw          $e4	; 84
                    retw          $90	; 85
                    retw          $ff	; 86
                    retw          $ff	; 87
                    retw          $63	; 88
                    retw          $24	; 89
                    retw          $26	; 90
                    retw          $20	; 91
                    retw          $82	; 92
                    retw          $0	; 93
                    retw          $0	; 94
                    retw          $0	; 95
                    retw          $e4	; 96
                    retw          $a0	; 97
                    retw          $fb	; 98
                    retw          $ff	; 99
                    retw          $61	; 100
                    retw          $4	; 101
                    retw          $1	; 102
                    retw          $0	; 103
                    retw          $e7	; 104
                    retw          $24	; 105			;;42	;61	;91
                    mov           w,#117;$75	; 106
                    mov           VAR_DC3,w	; 107
                    snb           V10_FLAG	; 108
                    jmp           PS2LOGO_PATCH_19_20_JMP1	; 109
                    mov           w,#112;$70	; 110
                    mov           VAR_DC3,w	; 111
                    retw          $d0	; 112
                    retw          $80	; 113
                    mov           w,#119	; 114 ;;$77
                    mov           VAR_DC3,w	; 115
                    jmp           PS2LOGO_PATCH_11_17_JMP1	; 116
;LOADV10A					
PS2LOGO_PATCH_19_20_JMP1
                    retw          $50	; 117
                    retw          $81	; 118
;LOADL1					
PS2LOGO_PATCH_11_17_JMP1
                    retw          $80	; 119
                    retw          $af	; 120
                    retw          $2e	; 121
                    retw          $1	; 122
                    retw          $22	; 123
                    retw          $92	; 124
                    retw          $2f	; 125
                    retw          $1	; 126
                    retw          $23	; 127
                    retw          $92	; 128
                    retw          $26	; 129
                    retw          $10	; 130
                    retw          $43	; 131
                    retw          $0	; 132
                    retw          $1a	; 133
                    retw          $0	; 134
                    retw          $3	; 135
                    retw          $24	; 136
                    retw          $3	; 137
                    retw          $0	; 138
                    retw          $43	; 139
                    retw          $14	; 140
                    retw          $1	; 141
                    retw          $0	; 142
                    retw          $7	; 143
                    retw          $24	; 144
                    mov           w,#171;$ab	; 145
                    mov           VAR_DC3,w	; 146
                    snb           V10_FLAG	; 147
                    jmp           PS2LOGO_PATCH_19_20_JMP2	; 148
                    mov           w,#151	; 149 ;;$97
                    mov           VAR_DC3,w	; 150
                    retw          $bd	; 151
                    retw          $5	; 152
                    retw          $4	; 153
                    retw          $8	; 154
                    retw          $cc	; 155
                    retw          $80	; 156
                    retw          $87	; 157
                    retw          $af	; 158
                    retw          $0	; 159
                    retw          $0	; 160
                    retw          $7	; 161
                    retw          $24	; 162
                    retw          $bd	; 163
                    retw          $5	; 164
                    retw          $4	; 165
                    retw          $8	; 166
                    retw          $cc	; 167
                    retw          $80	; 168
                    retw          $87	; 169
                    retw          $af	; 170
;V10-12				
PS2LOGO_PATCH_19_20_JMP2
                    retw          $af	; 171
                    retw          $5	; 172
                    retw          $4	; 173
                    retw          $8	; 174
                    retw          $4c	; 175
                    retw          $81	; 176
                    retw          $87	; 177
                    retw          $af	; 178
                    retw          $0	; 179
                    retw          $0	; 180
                    retw          $7	; 181
                    retw          $24	; 182		
                    retw          $af	; 183
                    retw          $5	; 184
                    retw          $4	; 185
                    retw          $8	; 186
                    retw          $4c	; 187
                    retw          $81	; 188
                    retw          $87	; 189
                    retw          $af	; 190
				

;V14DRV
PS1DRV_PATCHLOAD_v14
                    mov           w,#39;$27
                    mov           VAR_DC1,w
                    jmp           PS2LOGO_PATCHLOAD_22_JMP2
;XMAN					
START_PS2LOGO_PATCH_LOAD
                    mov           w,#123;$7b
                    mov           VAR_DC1,w
                    snb           V14_FLAG
                    jmp           PS2LOGO_PATCHLOAD_22_JMP2
                    mov           w,#110;$6e
                    mov           VAR_DC1,w
;PS2_PS2LOGO					
;PS2_PS2LOGO:loopa					
PS2LOGO_PATCHLOAD_22_JMP2
                    clr           w
                    mov           VAR_DC3,w
	IFDEF	SX48RAM
                    mov           w,#$10
	ELSE					
                    mov           w,#$15
	ENDIF					
                    mov           fsr,w
;PS2_PS2LOGO:loop
PS2LOGO_PATCHLOAD_LOOP
                    mov           w,VAR_DC3
                    call          PS2LOGO_PATCH
                    mov           indf,w
                    inc           fsr
	IFDEF	SX48RAM

	ELSE						
                    mov           w,#$10
                    or            fsr,w
	ENDIF					
                    inc           VAR_DC3
                    decsz         VAR_DC1
                    jmp           PS2LOGO_PATCHLOAD_LOOP
                    clr           fsr
                    snb           PSX_FLAG
                    page          $0200
                    jmp           SET_V14DRV
                    snb           X_FLAG
                    page          $0200
                    jmp           IS_XCDVDMAN
							
PS2_PS2LOGO:loopz
                    clr           fsr
                    mov           w,#117;$75
                    mov           VAR_DC2,w
                    mov           w,#$1
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,#$c0
                    mov           VAR_PSX_TEMP,w
                    mov           w,#$72
                    mov           VAR_PSX_BITC,w
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    snb           V14_FLAG
                    jmp           PS2_PS2LOGO:loop4
;load regs with v12 logo sync		
                    mov           w,#103;$67
                    mov           VAR_DC2,w					;V12 logo lenght
                    mov           w,#$8
                    mov           VAR_PSX_BC_CDDVD_TEMP,w			;V12 sync data
                    mov           w,#$e0
                    mov           VAR_PSX_TEMP,w
                    mov           w,#$9d
                    mov           VAR_PSX_BITC,w
                    mov           w,#$40
                    mov           IO_BIOS_DATA,w				;V12 bios preload
                    snb           V12_FLAG
                    jmp           PS2_PS2LOGO:loop4
;load regs with v10 sync					
                    mov           w,#$af
                    mov           VAR_PSX_BC_CDDVD_TEMP,w			;V10 sync data
                    mov           w,#$6
                    mov           VAR_PSX_TEMP,w
                    mov           w,#$8
                    mov           VAR_PSX_BITC,w
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w				;V1-V10 bios preload
                    snb           V10_FLAG
                    jmp           PS2_PS2LOGO:patchlogo2
;load regs with v1-v9 sync					
                    mov           w,#$1e
                    mov           VAR_PSX_TEMP,w				;V1-V9 sync data 

PS2_PS2LOGO:patchlogo2
                    mov           w,#87;$57
                    mov           VAR_DC2,w					
PS2_PS2LOGO:loop4
                    mov           w,#$50
                    mov           VAR_PSX_BYTE,w
;PS2_PS2LOGO:loop3					
PS2_PS2LOGO:loop3
                    mov           w,#255;$ff
                    mov           VAR_DC3,w				
PS2_PS2LOGO:loop2
                    mov           w,#255;$ff
                    mov           VAR_DC1,w					
PS2_PS2LOGO:loopx
                    sb            IO_BIOS_CS
                    jmp           PS2_PS2LOGO:loop1x
                    decsz         VAR_DC1
                    jmp           PS2_PS2LOGO:loopx
                    decsz         VAR_DC3
                    jmp           PS2_PS2LOGO:loop2
                    decsz         VAR_PSX_BYTE
                    jmp           PS2_PS2LOGO:loop3
												
;AUTORESET 	
;NEW!!! future board design using a 2N7002 mosfet					
	IFDEF	RSTBUMP
		IFDEF	SX48RSTBUMP
;NEW!!! future board design using a 2N7002 mosfet		
       				mov           w,#$1b
                    mov           m,w					
                    mov           w,#$ff
                    mov           !IO_CDDVD_BUS,w
                    mov           w,#$1f
                    mov           m,w
                    mov           w,#$0
                    mov           IO_CDDVD_BUS,w
                    mov           w,#$fb
		ELSE	
                   mode          $000B						;disable interrupt , need !!! ...
                   mov           w,#$ff						; 1111 1111
                   mov           !IO_CDDVD_BUS,w				; above set for IO_CDDVD_BUS
                   mode          $000F						; XFh mode direction for RA, IO_CDDVD_BUS, RC output
                   mov           w,#$0						; 0000 0000
                   mov           IO_CDDVD_BUS,w					; IO_CDDVD_BUS = 0 ? clear IO_CDDVD_BUS values
                   mov           w,#$fb						; 1111 1011 IO_REST IO_REST output
		ENDIF		
	ELSE			
                    mov           w,#$0
                    mov           IO_CDDVD_BUS,w
                    mov           w,#$fe
	ENDIF
	
                    mov           !IO_CDDVD_BUS,w
                    page          $0000
                    call          DELAY100m
                    mov           w,#$ff
                    mov           !IO_CDDVD_BUS,w
                    setb          PSX_FLAG
                    page          $0000
                    jmp           MACRO_CHECK_IF_V9to14
					
;sync for all versions using regs :))	 
PS2_PS2LOGO::loop00x        
                    snb           IO_BIOS_CS
                    jmp           PS2_PS2LOGO:loopx	
PS2_PS2LOGO:loop1x
                    mov           w,VAR_PSX_BC_CDDVD_TEMP
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS2_PS2LOGO::loop00x
PS2_PS2LOGO:loop1x_L1
                    sb            IO_BIOS_OE
                    jmp           PS2_PS2LOGO:loop1x_L1
PS2_PS2LOGO:loop1x_L2
                    snb           IO_BIOS_OE
                    jmp           PS2_PS2LOGO:loop1x_L2
                    mov           w,VAR_PSX_TEMP
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS2_PS2LOGO::loop00x
PS2_PS2LOGO:loop1x_L3
                    sb            IO_BIOS_OE
                    jmp           PS2_PS2LOGO:loop1x_L3
PS2_PS2LOGO:loop1x_L4
                    snb           IO_BIOS_OE
                    jmp           PS2_PS2LOGO:loop1x_L4
                    mov           w,VAR_PSX_BITC
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS2_PS2LOGO::loop00x
	IFDEF	SX48RAM
                    mov           w,#$16;1b	
	ELSE						
                    mov           w,#$1b
	ENDIF
                    mov           fsr,w
                    snb           V14_FLAG
                    jmp           PS2_PS2LOGO:loop1x_L5
                    snb           V12_FLAG
                    jmp           PS1_MODE_v12_PATCHS
	IFDEF	SX48RAM
                    mov           w,#$27;3C	
	ELSE					
                    mov           w,#$3c
	ENDIF					
                    mov           fsr,w
PS2_PS2LOGO:loop1x_L5
                    snb           IO_BIOS_OE
                    jmp           PS2_PS2LOGO:loop1x_L5
                    nop           
                    mov           w,#$c
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS2_PS2LOGO:loop1x_L5
PS2_PS2LOGO:loop1x_L6
                    sb            IO_BIOS_OE
                    jmp           PS2_PS2LOGO:loop1x_L6
                    mov           !IO_BIOS_DATA,w					
PS2_PS2LOGO:loop
                    snb           IO_BIOS_OE
                    jmp           PS2_PS2LOGO:loop
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    decsz         VAR_DC4
                    jmp           PS2_PS2LOGO:patchlogo2		;patch logo 2 times for V7 only !					
PS2_PS2LOGO:back
                    snb           PSX_FLAG
                    jmp           PS1_LOGO_PATCH
                    setb          EJ_FLAG
                    page          $0200
                    jmp           IS_XCDVDMAN
					
;V12 logo sync					
PS1_MODE_v12_PATCHS
	IFDEF	SX48RAM
                    mov           w,#$17;1c	
	ELSE	
                    mov           w,#$1c
	ENDIF
                    mov           fsr,w
                    setb          V12LOGO_FLAG
                    page          $0200
                    jmp           OSDSYS_BIOS_PATCH_SYNC_P2
					
;psx1 driver patch ...
;PSX1DRV
PS1_CONSOLE_PAL_YFIX
;V7DRV
                    mov           w,#$3c
                    mov           IO_BIOS_DATA,w
                    mov           w,#11;$b
                    mov           VAR_DC2,w
	IFDEF	SX48RAM
                    mov           w,#$10	
	ELSE						
                    mov           w,#$15					; fsr decimal 21
	ENDIF
                    mov           fsr,w

;10 01 00 43 30	
;psx1drv_l0
PS1_CONSOLE_PAL_YFIX_SYNC
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
                    mov           w,#$11
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$11
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$9
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
;psx1drv_l0a					
PS1_CONSOLE_PAL_YFIX_SYNC_L1
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L1
                    nop           
                    mov           w,#$30
                    mov           w,IO_BIOS_DATA-w				; 3C C7 34 19 19 E2 B2 19 E2 BA
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L1
PS1_CONSOLE_PAL_YFIX_SYNC_L2
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L2
                    mov           !IO_BIOS_DATA,w
PS1_CONSOLE_PAL_YFIX_SYNC_L3
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L3
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    decsz         VAR_DC4
                    jmp           PS1_CONSOLE_PAL_YFIX
;LOGO					
PS1_LOGO_PATCH
                    mov           w,#52;$34					; should jmp here for ntsc but is no flow to here besides via ps1 hence poor ntsc console ps1 support h2o. is no ntsc yfix
                    mov           VAR_DC1,w
                    mov           w,#24;$18
                    mov           VAR_DC3,w
                    mov           VAR_DC4,w
;logo_l1									;match FDFF8514
PS1_LOGO_PATCH_SYNC
                    snb           IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC
                    mov           w,#$fd
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_LOGO_PATCH_SYNC
PS1_LOGO_PATCH_SYNC_L1
                    sb            IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC_L1
PS1_LOGO_PATCH_SYNC_L2
                    snb           IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC_L2
                    mov           w,#$ff
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_LOGO_PATCH_SYNC
PS1_LOGO_PATCH_SYNC_L3
                    sb            IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC_L3
PS1_LOGO_PATCH_SYNC_L4
                    snb           IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC_L4
                    mov           w,#$85
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_LOGO_PATCH_SYNC
PS1_LOGO_PATCH_SYNC_L5
                    sb            IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC_L5
PS1_LOGO_PATCH_SYNC_L6
                    snb           IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC_L6
                    mov           w,#$14
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_LOGO_PATCH_SYNC
;logo_skip					
PS1_LOGO_PATCH_SYNC_L7
                    sb            IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC_L7
PS1_LOGO_PATCH_SYNC_L8
                    snb           IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC_L8
                    decsz         VAR_DC1
                    jmp           PS1_LOGO_PATCH_SYNC_L7
                    mov           w,#$3
                    mov           IO_BIOS_DATA,w
PS1_LOGO_PATCH_PATCH1
                    sb            IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_PATCH1
                    mov           w,#$0
                    mov           !IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$80
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$4
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$3c
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
;logo_skip2					
PS1_LOGO_PATCH_SYNC2
                    sb            IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC2
PS1_LOGO_PATCH_SYNC2_L1
                    snb           IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC2_L1
                    decsz         VAR_DC3
                    jmp           PS1_LOGO_PATCH_SYNC2
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
PS1_LOGO_PATCH_PATCH2
                    sb            IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_PATCH2
                    mov           w,#$0
                    mov           !IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
;logo_skip3					
PS1_LOGO_PATCH_SYNC3
                    sb            IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC3
PS1_LOGO_PATCH_SYNC3_L1
                    snb           IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC3_L1
                    decsz         VAR_DC4
                    jmp           PS1_LOGO_PATCH_SYNC3
                    mov           w,#$88
                    mov           IO_BIOS_DATA,w
PS1_LOGO_PATCH_SYNC3_L2
                    sb            IO_BIOS_OE
                    jmp           PS1_LOGO_PATCH_SYNC3_L2
                    mov           w,#$0
                    mov           !IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$2
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$80
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$a4
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    setb          EJ_FLAG
                    page          $0000
                    jmp           PS1_MODE_START_PATCH

                    org           $0600					; PAGE8 600-7FF

;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P8
;--------------------------------------------------------------------------------

                    snb           IO_BIOS_OE          			; next byte / wait for bios OE low
                    jmp           BIOS_WAIT_OE_LO_P8
                    ret           

;--------------------------------------------------------------------------------
BIOS_PATCH_DEV1 ;  straight patch flow 0 - 115
;--------------------------------------------------------------------------------
;LOAD_DEVMODE
                    jmp           pc+w
                    retw          $8	;0
                    retw          $10
                    retw          $3c
                    retw          $72
                    retw          $0
                    retw          $11
                    retw          $36
                    retw          $7c
                    retw          $a9
                    retw          $92
                    retw          $34
                    retw          $0
                    retw          $0
                    retw          $51
                    retw          $ae
                    retw          $c
                    retw          $0
                    retw          $0
                    retw          $0
                    retw          $3
                    retw          $0
                    retw          $5
                    retw          $24
                    retw          $10
                    retw          $0
                    retw          $6
                    retw          $3c
                    retw          $ec
                    retw          $1
                    retw          $c4
                    retw          $34	;30
                    retw          $e0
                    retw          $1
                    retw          $c6
                    retw          $34
                    retw          $6
                    retw          $0
                    retw          $3
                    retw          $24
                    retw          $c
                    retw          $0
                    retw          $0
                    retw          $0
                    retw          $f7
                    retw          $1
                    retw          $10
                    retw          $0
                    retw          $7
                    retw          $2
                    retw          $10
                    retw          $0
                    retw          $15
                    retw          $2
                    retw          $10
                    retw          $0
                    retw          $6d
                    retw          $6f
                    retw          $64
                    retw          $75
                    retw          $6c	;60
                    retw          $65
                    retw          $6c
                    retw          $6f
                    retw          $61
                    retw          $64
                    retw          $0
                    retw          $2d
                    retw          $6d
                    retw          $20
                    retw          $72
                    retw          $6f
                    retw          $6d
                    retw          $30
                    retw          $3a
                    retw          $53
                    retw          $49
                    retw          $4f
                    retw          $32
                    retw          $4d
                    retw          $41
                    retw          $4e
                    retw          $0
                    retw          $2d
                    retw          $6d
                    retw          $20
                    retw          $72
                    retw          $6f
                    retw          $6d
                    retw          $30
                    retw          $3a	;90
                    retw          $4d
                    retw          $43
                    retw          $4d
                    retw          $41
                    retw          $4e
                    retw          $0
                    retw          $6d
                    retw          $63
                    retw          $30
                    retw          $3a
                    retw          $2f
                    retw          $42
                    retw          $4f
                    retw          $4f
                    retw          $54
                    retw          $2f
                    retw          $42
                    retw          $4f
                    retw          $4f
                    retw          $54
                    retw          $2e
                    retw          $45
                    retw          $4c
                    retw          $46
                    retw          $0	;115
					
DEV1_MODE_LOAD_START
                    clrb          PSX_FLAG				; PSX_FLAG clrb here from being set due to HOLD_BOOT_MODES ran then reset
                    setb          SOFT_RST
                    setb          EJ_FLAG				; skip logo patch after media for DEVMODE
                    setb          DEV1_FLAG				;set DEVMODE flags
                    mov           w,#115;$73
                    mov           VAR_DC1,w				; VAR_DC1 = 73h = 115
                    clr           w
                    mov           VAR_DC3,w				; VAR_DC3 = 0
	IFDEF	SX48RAM
                    mov           w,#$10	
	ELSE					
                    mov           w,#$15
	ENDIF					
                    mov           fsr,w					; fsr = 15h with fsr starting for SRAM patch caching. start 15h due to 10-14 disabled bank 0
DEV1_MODE_LOAD_LOOP
                    mov           w,VAR_DC3
                    call          BIOS_PATCH_DEV1
                    mov           indf,w				; mov value in w from patch data retw to indf which places it in the SRAM memory cache as addressed cycling.
                    inc           fsr					; +1 fsr to step up SRAM patch caching
	IFDEF	SX48RAM
	
	ELSE
                    mov           w,#$10				; so that ends in top address of registery which is SRAM access. bottom 0-f reserved so when gets 1f goes 30h than 20h
                    or            fsr,w					; section 6.2.1 fig. 6-1 start at 15h then increase one 0001 0110 or 0001 0000 = 0001 1101 = 16h repeat
	ENDIF
                    inc           VAR_DC3				; + 1 VAR_DC3 starting 0 above
                    decsz         VAR_DC1				; jmp DEV1_MODE_LOAD_LOOP till VAR_DC1 = 0 start 119
                    jmp           DEV1_MODE_LOAD_LOOP
                    page          $0200					; PAGE2
                    jmp           PS2_CHECK_IF_V1_v2or3_V4_V5to8

;--------------------------------------------------------------------------------
MECHACON_WAIT_OE
;--------------------------------------------------------------------------------

;CDDVDSKIP_P8
                    snb           IO_CDDVD_OE_A_1Q 			; jmp MECHACON_WAIT_OE if ^Q = 1
                    jmp           MECHACON_WAIT_OE			; wait until flipflop ^Q == 0
                    clrb          IO_CDDVD_OE_A_1R  			; reset flipflop so Q = 0 (and ^Q = 1)
                    nop                             			; ...
                    setb          IO_CDDVD_OE_A_1R  			; reset flipflop so ready for if lower sensed on cp (A) CONSOLE_IO_CDDVD_OE_A
                    decsz         VAR_DC1           			; decrement counter and repeat MECHACON_WAIT_OE if not yet zero
                    jmp           MECHACON_WAIT_OE  			; ...
                    ret                            			; counter finished: return        

;--------------------------------------------------------------------------------
CDDVD_PATCH_DATA
;--------------------------------------------------------------------------------
;PACKIT_BYTE
                    jmp           pc+w					; when called VAR_DC2 is in w so determins start point
                                     					; 1 is sent first rb.4-rb.7 then follows to nibble and send 2 to rb.4-rb.7 then flow for 8 bytes
                                     					;  1    2   ; G not patched on ps2 v1-v8 due to not connected. but is same overall patch for v1-v12 ea region.
                                     					; IHGB IHGB	; Remember b/f swapped final from v9kit sch, H=RW pal support f=tr or but how F=F rstbmp? USA H same as pal?
                    retw          $3b					; 0011 1011 ; 0 ; USA start
                    retw          $a0					; 1010 0000 ; 1
                    retw          $33					; 0011 0011 ; 2
                    retw          $28					; 0010 1000 ; 3
                    retw          $20					; 0010 0000 ; 4
                    retw          $ff					; 1111 1111 ; 5
                    retw          $4					; 0000 0100 ; 6
                    retw          $41					; 0100 0001 ; 7 ; USA end
                    retw          $44					; 0100 0100 ; 8	; PAL start
                    retw          $fd					; 1111 1101 ; 9
                    retw          $13					; 0001 0011 ; 10
                    retw          $2b					; 0010 1011 ; 11
                    retw          $61					; 0110 0001 ; 12
                    retw          $22					; 0010 0010 ; 13
                    retw          $13					; 0001 0011 ; 14
                    retw          $31					; 0011 0001 ; 15 ; PAL end
                    retw          $8c					; 1000 1100 ; 16 ; JAP start
                    retw          $b0					; 1011 0000 ; 17
                    retw          $3					; 0000 0011 ; 18
                    retw          $3a					; 0011 1010 ; 19
                    retw          $31					; 0011 0001 ; 20
                    retw          $33					; 0011 0011 ; 21
                    retw          $19					; 0001 1001 ; 22
                    retw          $91					; 1001 0001 ; 23 ; JAP end					

;MEDIA_PATCH					
START_CDDVD_PATCH
                    clr           fsr
                    setb          IO_CDDVD_OE_A_1R
;execute first patch for V12 only ...					
                    snb           V14_FLAG
                    jmp           V9toV14_CONSOLE_CDDVD_START
                    snb           JAP_V8        
                    jmp           V9toV14_CONSOLE_CDDVD_START		;patch DVD media for V8 jap last mechacon spc rev						
                    mov           w,#$30			
                    mov           w,VAR_BIOS_REV-w
                    snb           z				
                    jmp           V9toV14_CONSOLE_CDDVD_START		;patch DVD media for V12
                    mov           w,#$37
                    mov           w,VAR_BIOS_REV-w
                    snb           c
                    jmp           V9toV14_CONSOLE_CDDVD_START		;patch DVD media for V9-10
;V1-V8 version... fix for HDD operations ( bios activity )	
;HDD_FIX
V1toV8_CONSOLE_CDDVD_START
                    mov           w,#4;$4
                    mov           VAR_DC1,w
;:l0					
V1toV8_AND_BYTE_SYNC1
                    mov           w,#$90
V1toV8_AND_BYTE_SYNC1_L1
                    snb           IO_CDDVD_OE_A_1Q			;wait sync byte FF FF FF FF
                    jmp           V1toV8_AND_BYTE_SYNC1_L1
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    and           w,IO_CDDVD_BUS
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,#$90
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    sb            z
                    jmp           V1toV8_CONSOLE_CDDVD_START
                    decsz         VAR_DC1
                    jmp           V1toV8_AND_BYTE_SYNC1
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
					
;dvd_patch					
V9toV14_CONSOLE_CDDVD_START
                    mov           w,#15;$f
                    mov           VAR_DC1,w				;skip 16 byte for V9-10-12 dvd patch ,15 is a fix !!!
;dvd_patch1					
V9toV14_AND_BYTE_SYNC1
                    mov           w,#$b0
V9toV14_AND_BYTE_SYNC1_L1
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           V9toV14_AND_BYTE_SYNC1_L1
                    clrb          IO_CDDVD_OE_A_1R
                    and           w,IO_CDDVD_BUS
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    setb          IO_CDDVD_OE_A_1R
                    mov           w,#$a0
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    sb            z
                    jmp           V9toV14_AND_BYTE_SYNC1		;FA-FC
                    mov           w,#$b0
;media_l1					
V9toV14_AND_BYTE_SYNC1_L2
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           V9toV14_AND_BYTE_SYNC1_L2
                    clrb          IO_CDDVD_OE_A_1R
                    and           w,IO_CDDVD_BUS
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    setb          IO_CDDVD_OE_A_1R
                    mov           w,#$b0				;FF	
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    snb           z
                    jmp           V9toV12_AND_BYTE_SYNC2
                    mov           w,#$0					;00
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    sb            z
                    jmp           V9toV14_AND_BYTE_SYNC1
;media_l2					
V9toV12_AND_BYTE_SYNC2
                    mov           w,#$b0
V9toV12_AND_BYTE_SYNC2_L1
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           V9toV12_AND_BYTE_SYNC2_L1
                    clrb          IO_CDDVD_OE_A_1R
                    and           w,IO_CDDVD_BUS
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    setb          IO_CDDVD_OE_A_1R
                    mov           w,#$b0				;FF	
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    snb           z
                    jmp           V9toV12_CONSOLE_PATCH1_POST
                    mov           w,#$a0				;FC
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    sb            z
                    jmp           V9toV14_AND_BYTE_SYNC1
                    snb           PSX_FLAG
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP				
                    call          MECHACON_WAIT_OE			;sleep for DVD media loaded in PSX mode
;dvd_patch2	
;Patch bus first time	
;only F,G bit need patch :)
;patch to	0X 0X 0X 0X 
;dvdr game  is 	0F 25 0F 25
;dvdrom game is 02 01 02 01
;dvd-rw game is 0F 32 0F 32
;dvd9 video is  02 01 02 01
                    mov           w,#$0					;patch bus first time !
                    mov           IO_CDDVD_BUS,w
                    mov           w,#$1f				;0001 1111	;mechacon bus: IHGBXXXF ; '0' = output !
V9toV12_AND_BYTE_SYNC2_L2
                    snb           IO_CDDVD_OE_A_1Q		
                    jmp           V9toV12_AND_BYTE_SYNC2_L2		;patch 4 bytes
                    clrb          IO_CDDVD_OE_A_1R			;this is byte #1
                    mov           !IO_CDDVD_BUS,w
                    setb          IO_CDDVD_OE_A_1R			;
					
                    mov           w,#5;$5
                    mov           VAR_DC1,w				;skip 5 bytes , FIX for 15 bytes skip (see above ...)
                    call          MECHACON_WAIT_OE
                    mov           w,#$ff				;1111 1111
                    mov           !IO_CDDVD_BUS,w
;CDDVD_PATCH					
V9toV12_CONSOLE_PATCH1_POST
                    snb           PSX_FLAG
                    page          $0000
                    jmp           PS1_MODE_START_PATCH
;CDDVD_PATCH_V1
;wait for mecha FA-FF-FF-01-00-00-01 then patch to 81
;dvd_l1
ALL_CDDVD_PATCH1_GET_SYNC_BIT
                    sb            IO_BIOS_CS
                    jmp           CDDVD_IS_PS1
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT		;wait sync byte FA FF FF ...
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;dvd_l2					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L1
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L1
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;dvd_l3					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L2
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L2
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;dvd_l4					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L3
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L3
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;dvd_l5					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L4
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L4
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           V9toV12_CONSOLE_PATCH1_POST
;dvd_l6					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L5
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L5
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           V9toV12_CONSOLE_PATCH1_POST
;dvd_l7					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L6
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L6
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           V9toV12_CONSOLE_PATCH1_POST
					
	IFDEF	H2O75KJMPERS
                    sb            IO_CDDVD_BUS_h
                    setb          JAP_FLAG
	ENDIF
                    snb           PSX_FLAG
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP			;V1-V8: sleep for DVD media loaded in PSX mode
;dvd_c1					
                    mov           w,#$90					;NEW 1 time 1 BYTE patch !!!!!!!!!
                    mov           IO_CDDVD_BUS,w
                    mov           w,#$6f
ALL_CDDVD_PATCH1
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1
                    clrb          IO_CDDVD_OE_A_1R
                    mov           !IO_CDDVD_BUS,w
                    setb          IO_CDDVD_OE_A_1R
CDDVD_REGION
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           CDDVD_REGION
                    clrb          IO_CDDVD_OE_A_1R
                    mov           w,#$ff
                    mov           !IO_CDDVD_BUS,w
                    setb          IO_CDDVD_OE_A_1R
;prepare patch region , here for speed !!! No move!!!						
                    snb           JAP_FLAG
                    jmp           CDDVD_JAP
                    snb           UK_FLAG
                    jmp           CDDVD_PAL
;:reg_usa					;; idea for trim, usa flag not needed set here, will for ps1drv scex??
                    clr           w
                    jmp           ALL_CDDVD_PATCH_SET_VAR_DC3
;:reg_uk					
CDDVD_PAL
                    mov           w,#8;$8
                    jmp           ALL_CDDVD_PATCH_SET_VAR_DC3
;:reg_jap					
CDDVD_JAP
                    mov           w,#16;$10
ALL_CDDVD_PATCH_SET_VAR_DC3
                    mov           VAR_DC2,w					; save offset...
                    mov           w,#8;$8					;region patch : # of bytes to patch
                    mov           VAR_DC3,w
                    mov           w,#$ff
                    mov           IO_CDDVD_BUS,w				;!!!!!!!!!!!!!	critical	
;WAIT_DISK
;wait_dvd_lx
ALL_CDDVD_PATCH_SYNC2_BIT
                    mov           w,#3;$3
                    mov           VAR_DC1,w					;skip 6 byte (FA,FF,FF,FA,FF,FF)
;wait_dvd_l0					
ALL_CDDVD_PATCH_SYNC2_BIT_L1
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT_L1
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT
ALL_CDDVD_PATCH_SYNC2_BIT_L2
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT_L2
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT
ALL_CDDVD_PATCH_SYNC2_BIT_L3
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT_L3
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT
                    decsz         VAR_DC1
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT_L1
;patch region ...				
	IFDEF	SX48
                    mov           w,#$1f
                    mov           m,w
	ENDIF		
                    mov           w,#$f						; 0000 1111 = 0 output
                    mov           !IO_CDDVD_BUS,w
;reg_l1					
RUN_CDDVD_PATCH
                    mov           w,VAR_DC2
                    call          CDDVD_PATCH_DATA
RUN_CDDVD_PATCH_NIBBLE
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           RUN_CDDVD_PATCH_NIBBLE
                    mov           IO_CDDVD_BUS,w
                    clrb          IO_CDDVD_OE_A_1R
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,<>VAR_PSX_BC_CDDVD_TEMP
                    setb          IO_CDDVD_OE_A_1R
RUN_CDDVD_PATCH_NIBBLE_SEND
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           RUN_CDDVD_PATCH_NIBBLE_SEND
                    mov           IO_CDDVD_BUS,w
                    clrb          IO_CDDVD_OE_A_1R
                    inc           VAR_DC2
                    setb          IO_CDDVD_OE_A_1R
                    decsz         VAR_DC3
                    jmp           RUN_CDDVD_PATCH
CDDVD_PATCH_POST_RB_INPUT
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           CDDVD_PATCH_POST_RB_INPUT
                    mov           w,#$ff
                    mov           !IO_CDDVD_BUS,w
                    snb           SOFT_RST
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;exit_patch					
CDDVD_IS_PS1
                    clrb          SOFT_RST
                    snb           EJ_FLAG
                    page          $0200
                    jmp           IS_XCDVDMAN
                    page          $0400
                    jmp           PS2_PS2LOGO:loopz
					
;Modload repatch...					
FINISHED_RUN_START
                    page          $0000
                    call          SET_INTRPT
                    mov           w,#4;$4
                    mov           VAR_DC1,w
FINISHED_RUN_START_P2
                    snb           IO_BIOS_OE
                    jmp           FINISHED_RUN_START_P2
                    mov           w,#$c4
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$27
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$18
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2
FINISHED_RUN_START_P2_L1
                    snb           IO_BIOS_OE
                    jmp           FINISHED_RUN_START_P2_L1
                    mov           w,#$d0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2_L1
FINISHED_RUN_START_P2_L2
                    sb            IO_BIOS_OE
                    jmp           FINISHED_RUN_START_P2_L2
FINISHED_RUN_START_P2_L3
                    snb           IO_BIOS_OE
                    jmp           FINISHED_RUN_START_P2_L3
                    mov           w,#$ff
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2_L1
FINISHED_RUN_START_P2_L4
                    sb            IO_BIOS_OE
                    jmp           FINISHED_RUN_START_P2_L4
FINISHED_RUN_END
                    snb           IO_BIOS_OE
                    jmp           FINISHED_RUN_END
                    mov           w,#$42
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2_L1
                    mov           w,#$34
                    mov           IO_BIOS_DATA,w
                    mov           w,#$0
                    mov           !IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    decsz         VAR_DC1
                    jmp           FINISHED_RUN_START_P2
                    page          $0000
                    call          DELAY100m
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
					
	IFDEF	SX48
		

                    org           $0800
					
                    org           $0A00

                    org           $0C00
					
                    org           $0E00					


	ENDIF					

                    end
