	device        SX28,TURBO,BOROFF,BANKS8,OSCHS2,OPTIONX
                    ID                    'mecha'
					
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
;;
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


;------------------------------------------------------------
;VAR_PATCH_FLAGS
;------------------------------------------------------------
EJ_FLAG = VAR_PATCH_FLAGS.0
;reboot read to do reinitalise of mechacon unlock

SOFT_RST = VAR_PATCH_FLAGS.1
;soft reset flag for disk patch 

PSX_FLAG = VAR_PATCH_FLAGS.2

V10_FLAG = VAR_PATCH_FLAGS.3	
;bios 1.9 also used in conjuction with v12 2.0
;also v10 1.9 bios has own ps1 routine 

UK_FLAG = VAR_PATCH_FLAGS.4

USA_FLAG = VAR_PATCH_FLAGS.5

JAP_FLAG = VAR_PATCH_FLAGS.6



;------------------------------------------------------------
;VAR_SWITCH
;------------------------------------------------------------
V12_FLAG = VAR_SWITCH.0 
;v12 console 2.0 bios set

V12LOGO_FLAG = VAR_SWITCH.1
;PS1 V12 LOGO PATCH

JAP_V8 = VAR_SWITCH.2
;Jap V8 with last rev of mechacon needing dragon patches abghi


V14_FLAG = VAR_SWITCH.5



;------------------------------------------------------------
;CODE
;------------------------------------------------------------					
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
                    mode          $000E						;; h and f io jmpers needed/extra 75k/v8jap 
                    mov           w,#$be					; 1011 1110
                    mov           !IO_CDDVD_BUS,w					;; end
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

;execute correct startup...					
 ;execute correct startup...					
                    snb           pd
                    jmp           CLEAR_CONSOLE_INFO_PREFIND			;0 = power up from sleep , 1= power up from Power ON (STBY)
                  ;  snb           VAR_PSX_BITC.2
                  ;  jmp           TAP_BOOT_MODE
                   ; snb           IO_EJECT
                   ; jmp           TRAY_IS_EJECTED
                   ; snb           VAR_PSX_BITC.1				;xcdvdman reload check
                   ; page          $0200
                   ; jmp           IS_XCDVDMANX
                   ; page          $0200
				   snb EJ_FLAG				;needed for retriggering of tray gets ejected or else flows to do bios sync again n wont forward.
				   page $0600
				   jmp START_CDDVD_PATCH
                    jmp           PS2_MODE_RB_IO_SET_SLEEP			; fail safe sleep incase misses a condition as the sx gets hot :P
;power up from STBY					
CLEAR_CONSOLE_INFO_PREFIND
                    clr           VAR_PATCH_FLAGS				;reset all used flag...
                    clr           VAR_SWITCH			
                    jmp           BIOS_GET_SYNC

;--------------------------------------------------------------------------------
SET_INTRPT 									;setup interrupt routine
;--------------------------------------------------------------------------------

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
                    snb           IO_BIOS_OE					; next byte / wait for bios OE low
                    jmp           BIOS_GET_SYNC
                    nop           

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

                    snb           IO_BIOS_OE					; next byte / wait for bios OE low
                    jmp           CAPTURE_BIOS_REGION
                    nop           ;; extra sx28

                    mov           w,#$30					; ASCII 0; is byte6 0 as fixed value check
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           CAPTURE_BIOS_REGION				;loop back to CAPTURE_BIOS_REGION if not ASCII 0
                    call          BIOS_WAIT_OE_LO_P1          			; next byte / wait for bios OE low
                    mov           w,IO_BIOS_DATA
                    mov           VAR_BIOS_REGION_TEMP,w			;store byte7 in VAR_BIOS_REGION_TEMP
CHECK_BYTE_AB_REGION_CAPTURE_YR

                    snb           IO_BIOS_OE					; next byte / wait for bios OE low
                    jmp           CHECK_BYTE_AB_REGION_CAPTURE_YR
                    nop		;; extra sx28
					
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
                    clrb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_f				; check if USA JMPER set for v14
                    jmp           BIOS_USA

	
BIOS_UK
                    setb          UK_FLAG
                    jmp           RESTDOWN_CHK_PS2MODEorOTHER
BIOS_JAP
                    setb          JAP_FLAG
RESTDOWN_CHK_PS2MODEorOTHER
                    clr           fsr ;;
                    clrb          PSX_FLAG ;;
jmp TRAY_IS_EJECTED ;;;;
					
					;CDDVD_EJECTED					
TRAY_IS_EJECTED


      ;;;;              sb            IO_REST					;here from eject
     ;;;;              jmp           TAP_BOOT_MODE					;reset
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
           ;;;         sb            IO_REST					;new reset check here ...	
     ;;;;               jmp           TAP_BOOT_MODE
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
;;
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
                    clrb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_f				; Check USA JMPER here for v8 Jap console
                    setb          JAP_V8					
                    jmp           START_CDDVD_PATCH				;patch ps2 CD/DVD
					
					org $0200
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
setb EJ_FLAG 
 sleep         
					
PS1_MODE_RB_IO_SET_SLEEP
                    mov           w,#$f3					; 1111 0011
                    mov           !IO_CDDVD_BUS,w				; rb.2 IO_REST rb.3 IO_EJECT enabled
                    sleep         					

                    org           $0600					; PAGE8 600-7FF

;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P8
;--------------------------------------------------------------------------------

                    snb           IO_BIOS_OE          			; next byte / wait for bios OE low
                    jmp           BIOS_WAIT_OE_LO_P8
                    ret           
					
					
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
               ;;     snb           PSX_FLAG
             ;;      page          $0000
           ;;        jmp           PS1_MODE_START_PATCH
;CDDVD_PATCH_V1
;wait for mecha FA-FF-FF-01-00-00-01 then patch to 81
;dvd_l1
ALL_CDDVD_PATCH1_GET_SYNC_BIT
     ;;               sb            IO_BIOS_CS
     ;;               jmp           CDDVD_IS_PS1
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
					;;
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
;;
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
              ;      snb           SOFT_RST
               ;     jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
					
					page  $0200
					jmp PS2_MODE_RB_IO_SET_SLEEP ;;;;
