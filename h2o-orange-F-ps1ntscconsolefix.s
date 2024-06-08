;********************************************************************************
;                  h2o-orange-F-ntscconsoleps1fix.hex				hash e34d47d9460e37dc78bd3bedc6b87cef
;********************************************************************************
                   device        SX28,TURBO,PROTECT,BOROFF,BANKS8,OSCHS2,OPTIONX
                    ID                    'ICEREV'
					
;DEFINE
RSTBUMP			EQU 1			; uncomment for compiling with restbump for ps1mode. else is compiled as f=tr
;USE ONLY IF F=TR commented out RSTBUMP
;pal v14 dont define any. for jap/usa define only one for 75k this will make f=tr work correctly also h=rw usa/pal			f=tr 75k pal aaa45bfc43e3f1786c5fb1fa4e9815f8
;USAv14			EQU 1			;uncomment for fixed 75k being usa region. all prior still work any region					f=tr 75k usa 15aca3108d239eb682f27d17cc1ed3d1
;JAPv14			EQU 1			;uncomment for fixed 75k being jap region. all prior still work any region					f=tr 75k jap 9b55a672a34c1d54e712ec6859f927dd

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
IO_CDDVD_BUS_h			=		rb.6 ; (H)(how determins is jap v14 if connected, assumption is no RW support at all on v14 unless sync works out for when checked)
IO_CDDVD_BUS			=		rb   ; $06
IO_BIOS_DATA			=		rc   ; $07 ; (V)RC0(BIOS:D0) - (M)RC7(BIOS:D7)

;regs
VAR_DC1				equ		$08 ; DS 1 ; delay counter 1(small)
VAR_DC2				equ		$09 ; DS 1 ; delay counter 2(small)
VAR_DC3				equ		$0A ; DS 1 ; delay counter 3(big)
VAR_TOFFSET			equ		$0b ; DS 1 ; table offset
VAR_PSX_TEMP			equ		$0C ; DS 1 ; SEND_SCEX:  rename later
VAR_PSX_BC_CDDVD_TEMP		equ		$14 ; DS 1 ; SEND_SCEX:  byte counter  note start at 4(works down to 0) ; also used with mechacon patches and ps1 detect
VAR_PSX_BYTE			equ		$0D ; DS 1 ; SEND_SCEX:  byte(to send)
VAR_PSX_BITC			equ		$13 ; DS 1 ; SEND_SCEX:  bit counter ;note start at 8(works down to 0)
VAR_BIOS_REV			equ		$10 ; DS 1 ; 1.X0 THE BIOS REVISION byte infront in BIOS string is X.00
VAR_BIOS_YR			equ		$11 ; DS 1 ; byteC of ;BIOS_VERSION_MATCHING
VAR_BIOS_REGION_TEMP		equ		$12 ; DS 1 ; temp storage to compare byte7 of ;BIOS_VERSION_MATCHING
VAR_SWITCH			equ		$0F ; DS 1 ; ? 0.94 comment ; bit 0=xcddvdman mode + PSX1 region switch, 1=PSX1/PSX2 wakeup mode, 2=PSX1 PAL/NTSC , 3=PSX2 logo patch , 4=DEV1 
VAR_PATCH_FLAGS			equ		$0E ; DS 1 ; appears to be bits set for running patch routines .0-.7 for setb an offset

;------------------------------------------------------------

EJ_FLAG = VAR_PATCH_FLAGS.0
;bit 0 used by eject routine

SOFT_RST = VAR_PATCH_FLAGS.1
;soft reset flag for disk patch 

PSX_FLAG = VAR_PATCH_FLAGS.2
;psx mode flag	
;seems to be ref for mode started and mode end, cleared when finished mode run or on reset if mode was incomplete finish not checking
;clrb on TAP_BOOT_MODE to set for flow PS1_MODE ?

V10_FLAG = VAR_PATCH_FLAGS.3	;bios 1.9 or 2.0
;also v10 1.9 bios has own ps1 routine 

UK_Flag = VAR_PATCH_FLAGS.4

USA_Flag = VAR_PATCH_FLAGS.5

JAP_Flag = VAR_PATCH_FLAGS.6

SCEX_FLAG = VAR_PATCH_FLAGS.7
;set when SCEX_LOW loop for injecting. once cleared knows patching done to flow forward

;------------------------------------------------------------
V12_FLAG = VAR_SWITCH.0 ;v12 console 2.0 bios set

V12Logo_Flag = VAR_SWITCH.1 ;PS1_MODE v12 2.0 bios console flag ?
;SECOND_BIOS_PATCH_END ref if was doing ps1 patching for 2.0 v12 as redirects flow there for different patch. 

;VAR_SWITCH.2 = not used

X_FLAG = VAR_SWITCH.3 
;PS2_MODE ref set when HOLD_BOOT_MODES only clrb when end ?
;can flow onto ps1 reboot into PS1_MODE if detect ps1 media

DEV1_Flag = VAR_SWITCH.4

V14_Flag = VAR_SWITCH.5
;set due to W for region of BIOS which decka models
;-------------------------------------------------------------

;mode setup for io's ;todo
;ref SX-SX-Users-Manual-R3.1.pdf section 5.3.2
                    org           $07FF							; Reset Vector
                    reset         STARTUP						; jmp to startup process on reset vector skipping boot inital

;****** Reset of the chip ********************************
                    org           $0000							; PAGE1 000-1FF
;INTERRUPT
;goes to sleep and wait for reset release ( 1 ) or tray close (0) ...					
                    mode          $000F
                    mov           w,#$ff					; 1111 1111
                    mov           !IO_BIOS_DATA,w			;to be sure ports are input ...
                    mov           w,#$ff					; 1111 1111
                    mov           !IO_CDDVD_BUS,w			;....
                    mov           w,#$ff					; 1111 1111
                    mov           !ra,w						;...
                    mode          $000A						;set up edge register
                    mov           w,#$8						; 0000 1000	
                    mov           !IO_CDDVD_BUS,w			;RB3 wait for LOW ( = 1 ),RB2 wait for hi ( =0 )
                    mode          $0009						;clear all wakeup pending bits
                    clr           w
                    mov           !IO_CDDVD_BUS,w
                    mode          $000B						;enable wakeup...
                    mov           w,#$f3					; 1111 0011
                    mov           !IO_CDDVD_BUS,w			;... on RB3 ( eject ) & RB2 (reset) 
                    mode          $000F
                    sleep         
					
;INIT_CHIP					
STARTUP          											;here from stby & wake up...
					mode          $000D						;TTL/CMOS mode...
                    mov           w,#$f7					;1111 0111
                    mov           !IO_CDDVD_BUS,w			;set IO_EJECT input as cmos ( level '1' > 2.5V ) work better with noise ...
                    mode          $000E						;?
                    mov           w,#$be					; 1011 1110
                    mov           !IO_CDDVD_BUS,w
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
                    clr           w							;clear W
                    mov           !IO_CDDVD_BUS,w			;exchange registers = read pending bits
                    mov           VAR_PSX_BITC,w			;save wake up status ...
                    mode          $000F						;need 'cause removed from patch disk for speed !
					
;execute correct startup...					
                    snb           pd
                    jmp           CLEAR_CONSOLE_INFO_PREFIND		;0 = power up from sleep , 1= power up from Power ON (STBY)
                    snb           VAR_PSX_BITC.2
                    jmp           TAP_BOOT_MODE
                    snb           IO_EJECT
                    jmp           TRAY_IS_EJECTED
                    snb           VAR_PSX_BITC.1					;xcdvdman reload check
                    page          $0200
                    jmp           POST_PATCH_4_MODE_START
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
					
;power up from STBY					
CLEAR_CONSOLE_INFO_PREFIND          clr           VAR_PATCH_FLAGS	;reset all used flag 
                    clr           VAR_SWITCH						;reset all used flag 
                    jmp           BIOS_GET_SYNC

;---------------------------------------------------------
;Delay routine using RTCC 
;---------------------------------------------------------

;--------------------------------------------------------------------------------
DELAY100m											;Precise delay routine using RTCC 
;--------------------------------------------------------------------------------
                    mov           w,#$64			;w = #$64 = 100	
                    mov           VAR_DC1,w			;delay = 100 millisec.
RTCC_SET_BIT          mov           w,#$3d			;w = #$3d = 61
                    mov           rtcc,w			;load  timer = 61	,delay = (256-61)*256*0.02 micros.= 1000 micros. / 45 for 54M
RTCC_CHECK          mov           w,rtcc			;wait for timer= 0 ... (don't use TEST RTCC)
                    sb            z					;skip next bit if rtcc = 0
                    jmp           RTCC_CHECK		;loop w=rtcc till equal then will skip
                    decsz         VAR_DC1			;VAR_DC1 = 100 count then skip next bit
                    jmp           RTCC_SET_BIT
                    retp          					;Return from call


;--------------------------------------------------------------------------------
SET_INTRPT 											;setup interrupt routine
;--------------------------------------------------------------------------------
                    mode          $000A							;set up edge register
                    mov           w,#$6							; 0000 0110
                    mov           !IO_CDDVD_BUS,w				; rb.1 IO_BIOS_CS rb.2 IO_REST high-to-low sense ;wait for low
                    mode          $0009							;clear all wakeup pending bits
                    clr           w								; 0000 0000
                    mov           !IO_CDDVD_BUS,w				; clear all wakeup pending bits
																; set to 0 indicates that no valid edge has occurred on the MIWU pin. 
																; The WKPND_B register comes up with undefine value upon reset.
                    mode          $000B							;enable interrupt ; MIWU operation. see Section 4.4.
                    mov           w,#$f3						; 1111 0011
                    mov           !IO_CDDVD_BUS,w				; rb.2 IO_REST rb.3 IO_EJECT enable interrupt
                    mode          $000F							; XFh mode direction for RA, RB, RC output
                    retp          

;--------------------------------------------------------------------------------
SCEX_HI
;--------------------------------------------------------------------------------
                    setb          IO_SCEX		; SCEX HI
										; Delay About 5mS
                    mov           w,#$3b				;#59 var_dc3 mov
                    mov           VAR_DC3,w
:loop1          mov           w,#$d4 ; #212 set for 50mhz
                    mov           VAR_DC2,w
                    not           ra
:loop2          mov           w,#$3
                    mov           VAR_DC1,w
:loop3          decsz         VAR_DC1
                    jmp           :loop3
                    decsz         VAR_DC2
                    jmp           :loop2
                    decsz         VAR_DC3
                    jmp           :loop1
                    ret           

;--------------------------------------------------------------------------------
SCEX_LOW
;--------------------------------------------------------------------------------
                    clrb          IO_SCEX		; SCEX LOW
									; Delay About 5mS+
                    mov           w,#$3b
                    mov           VAR_DC3,w
:loop1          	mov           w,#$d4 ; #212 for 50mhz
                    mov           VAR_DC2,w
                    snb           IO_BIOS_CS				; next byte / wait for bios CE LOW = BIOS select
                    jmp           :loop2
                    setb          SCEX_FLAG
:loop2          mov           w,#$3
                    mov           VAR_DC1,w
:loop3          decsz         VAR_DC1
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
					
                    retw          $53	; S	; UK	4
                    retw          $43	; C
                    retw          $45	; E
                    retw          $49	; I
					
                    retw          $53	; S ; JAP	8
                    retw          $43	; C
                    retw          $45	; E
                    retw          $45	; E

;--------------------------------------------------------------------------------
SEND_SCEX
;--------------------------------------------------------------------------------
                    snb           JAP_Flag
                    jmp           jap
                    snb           UK_Flag
                    jmp           uk
                    clr           VAR_TOFFSET
                    jmp           usa
uk          mov           w,#$8
                    mov           VAR_TOFFSET,w
                    jmp           usa
jap          mov           w,#$4
                    mov           VAR_TOFFSET,w
                    jmp           usa
usa          mov           w,#$4
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,#$b
                    mov           !ra,w
next_byte          mov           w,VAR_TOFFSET
                    call          SCEx_DATA
                    mov           VAR_PSX_BYTE,w
                    not           VAR_PSX_BYTE
                    mov           w,#$8
                    mov           VAR_PSX_BITC,w
                    call          SCEX_LOW
                    call          SCEX_LOW
                    call          SCEX_HI
send          rr            VAR_PSX_BYTE
                    snb           c
                    jmp           hi
                    sc            
                    call          SCEX_LOW
                    jmp           next2
hi          call          SCEX_HI
next2          decsz         VAR_PSX_BITC
                    jmp           send
                    inc           VAR_TOFFSET
                    decsz         VAR_PSX_BC_CDDVD_TEMP
                    jmp           next_byte
                    clrb          IO_SCEX
                    mov           w,#$16
                    mov           VAR_TOFFSET,w
send_end          call          SCEX_LOW
                    decsz         VAR_TOFFSET
                    jmp           send_end
                    mov           w,#$f
                    mov           !ra,w
                    ret           

;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P1
;--------------------------------------------------------------------------------
NOTCALLED0          snb           IO_BIOS_OE
                    jmp           BIOS_WAIT_OE_LO_P1
                    ret           
BIOS_GET_SYNC          
	; wait for "S201" seems to wait for "PS20" since 0.94
	;       0123456789ABC
	; Read "PS201?0?C200?xxxx.bin"
					snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_GET_SYNC
                    nop           
                    mov           w,#$50					; ASCII P	; is byte0 = 'P' seems to be new count prior for "PS201?0?C200?xxxx.bin"
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           BIOS_GET_SYNC
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$53					; ASCII S	; is byte1 (byte0 0.94) = 'S'	; v8 fix
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           BIOS_GET_SYNC
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$32					; ASCII 2	; is byte2 (byte1 0.94) = '2'
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           BIOS_GET_SYNC
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$30					; ASCII 0	; is byte3 (byte2 0.94) = '0'
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           BIOS_GET_SYNC
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
CAPTURE_BIOS_REV          sb            IO_BIOS_OE				; next byte / wait for bios OE high ; skipping byte4 for x.00 of bios
                    jmp           CAPTURE_BIOS_REV
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,IO_BIOS_DATA
                    mov           VAR_BIOS_REV,w					; capture byte5 as VAR_BIOS_REV ; v1.x0 of bios rev
CAPTURE_BIOS_REGION          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           CAPTURE_BIOS_REGION
                    nop           
                    mov           w,#$30					; ASCII 0	; is byte6 0 as fixed value check
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           CAPTURE_BIOS_REGION				;loop back to CAPTURE_BIOS_REGION if not ASCII 0
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,IO_BIOS_DATA
                    mov           VAR_BIOS_REGION_TEMP,w				;store byte7 in VAR_BIOS_REGION_TEMP
CHECK_BYTE_AB_REGION_CAPTURE_YR          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           CHECK_BYTE_AB_REGION_CAPTURE_YR
                    nop
                    mov           w,#$30					; ASCII 0 is byteA
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           CHECK_BYTE_AB_REGION_CAPTURE_YR				;loopback if byteA not 0 CHECK_BYTE_AB_REGION_CAPTURE_YR
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$30					; ASCII 0 is byteB
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           CHECK_BYTE_AB_REGION_CAPTURE_YR				;loopback if byteB not 0 CHECK_BYTE_AB_REGION_CAPTURE_YR
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,IO_BIOS_DATA
                    mov           VAR_BIOS_YR,w				;captured byteC
                    mov           w,#$41					;is byte7 ASCII A usa bios
                    mov           w,VAR_BIOS_REGION_TEMP-w		;capture byte7 compare to VAR_BIOS_REGION_TEMP if A
                    snb           z								;if compare dont = 0 (A) skip next line
                    jmp           BIOS_USA
                    mov           w,#$57					;is byte7 ASCII W v14/75k+ bios
                    mov           w,VAR_BIOS_REGION_TEMP-w
                    snb           z
                    jmp           BIOS_V14
                    mov           w,#$45					;is byte7 ASCII E europe bios
                    mov           w,VAR_BIOS_REGION_TEMP-w		;capture byte7 compare to VAR_BIOS_REGION_TEMP if E
                    snb           z								;if compare dont = 0 (E) skip next line	
                    jmp           BIOS_UK
                    mov           w,#$52					;is byte7 ASCII R ; 'R', uk	; RUS 39008 fix ; russia region which is pal
                    mov           w,VAR_BIOS_REGION_TEMP-w		;capture byte7 compare to VAR_BIOS_REGION_TEMP if R
                    snb           z								;if compare dont = 0 (R) skip next line
                    jmp           BIOS_UK
                    mov           w,#$43					;is byte7  ASCII C ; china region which pal region but ps2 ntsc-c made
                    mov           w,VAR_BIOS_REGION_TEMP-w		;capture byte7 compare to VAR_BIOS_REGION_TEMP if C
                    snb           z								;if compare dont = 0 (C) skip next line
                    jmp           BIOS_UK
                    jmp           BIOS_JAP					; no match on byte7 compares, assumed is jap region
BIOS_USA          setb          USA_Flag
                    jmp           RESTDOWN_CHK_PS2MODEorOTHER
BIOS_V14          setb          V14_Flag
	
	IFDEF	RSTBUMP
                    clrb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_f
                    jmp           BIOS_USA
	ENDIF
	
	IFDEF	USAv14
	jmp           BIOS_USA
	ENDIF
	
	IFDEF	JAPv14
	jmp           BIOS_JAP
	ENDIF
	
BIOS_UK          setb          UK_Flag
                    jmp           RESTDOWN_CHK_PS2MODEorOTHER
BIOS_JAP          setb          JAP_Flag
RESTDOWN_CHK_PS2MODEorOTHER          snb           IO_REST
                    jmp           TAP_BOOT_MODE
;DVD movie : GREEN fix + MACROVISION off					
CHECK_IF_V9to14          setb          PSX_FLAG
                    mov           w,#$30							; is bios 2.0 for v12 ;V12 use V910 kernel :)
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
                    mov           w,#$37							; is bios 1.7 for v9-10 ;select KERNEL TYPE V9 or V10
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
                    mov           w,#$39							; is bios 1.9 for v11
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
                    snb           V14_Flag							; is v14 flag set from W region, should work all decka 75k+
                    jmp           START_BIOS_PATCH_SYNC_V9toV14		
;V1-8 kernels: sync 1E006334 then 2410 					
                    mov           w,#$32							; v1-8 bios VAR_DC1 set fall over no match for
                    mov           VAR_DC1,w					
START_BIOS_PATCH_SYNC_V1toV8          snb           IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V1toV8
                    nop           
                    mov           w,#$1e
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V1toV8
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V1toV8
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$63
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V1toV8
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$34
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V1toV8
START_BIOS_PATCH_SYNC_V1toV8_L1          snb           IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V1toV8_L1
                    nop           
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V1toV8_L1
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$10
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V1toV8_L1
START_BIOS_PATCH_SYNC_V1toV8_L2          sb            IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V1toV8_L2	; next byte / wait for bios OE low
BIOS_V1toV8_PATCH1          snb           IO_BIOS_OE
                    jmp           BIOS_V1toV8_PATCH1
                    decsz         VAR_DC1
                    jmp           START_BIOS_PATCH_SYNC_V1toV8_L2
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    mode          $000F								; XFh mode direction for RA, RB, RC output 
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0								; 0000 0000
                    mov           !IO_BIOS_DATA,w					; IO_BIOS_DATA all pins output start patching here once sync
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0								;send 00,00,00,00
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
BIOS_V1toV8_IORESET_INPUT          sb            IO_BIOS_OE
                    jmp           BIOS_V1toV8_IORESET_INPUT
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    jmp           MODE_SELECT_START					;exit KERNEL PATCH
; V9/V10/V12 kernels	
;kernel_V910					
;Kstart_l0
START_BIOS_PATCH_SYNC_V9toV14          snb           IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14		; patch 25 10 43 00 to 00 00 00 00 
                    nop           
                    mov           w,#$dc
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
START_BIOS_PATCH_SYNC_V9toV14_L1          sb            IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14_L1
START_BIOS_PATCH_SYNC_V9toV14_L2          snb           IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14_L2
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
START_BIOS_PATCH_SYNC_V9toV14_L3          sb            IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14_L3
START_BIOS_PATCH_SYNC_V9toV14_L4          snb           IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14_L4
                    mov           w,#$10
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
START_BIOS_PATCH_SYNC_V9toV14_L5          sb            IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14_L5					
BIOS_V9toV14_PATCH1          snb           IO_BIOS_OE
                    jmp           BIOS_V9toV14_PATCH1
                    mov           w,#$45
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    mode          $000F							; XFh mode direction for RA, RB, RC output 
                    mov           w,#$0							; 0000 0000
                    mov           !IO_BIOS_DATA,w				; IO_BIOS_DATA all pins output start patching here once sync
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
                    mov           !IO_BIOS_DATA,w				; IO_BIOS_DATA all pins input patch end for more sync
					
;**************************************************************************************************
;New mode select for PSX/DEV mode :
;Check RESET for about 4 sec ( 2 =initial delay + 2 from this routine )
;if exit before then enter PSX mode , else wait for reset release and wait again for 
;10 sec. If RESET is pressed again within 10 sec. then enter DEV mode else 
;definitively SLEEP chip for all media that no need patch ( VIDEO , MUSIC , ORIGINALS ).
;**************************************************************************************************			
;TEST_RESET
MODE_SELECT_START          mov           w,#$a					; 10 ;test RESET for about 2.0 sec
                    mov           VAR_DC2,w
;test_l1
MODE_SELECT_TIMER_L1          call          DELAY100m
                    snb           IO_REST
                    jmp           HOLD_BOOT_MODES					
                    decsz         VAR_DC2						; repeat n jump to HOLD_BOOT_MODES if under 1sec so tap 1+1=2sec
                    jmp           MODE_SELECT_TIMER_L1					
MODE_SELECT_TIMER_L2          sb            IO_REST				;wait RESET release
                    jmp           MODE_SELECT_TIMER_L2
                    mov           w,#$5							;debounce RESET for about 0.5 sec
                    mov           VAR_DC2,w
;test_l2					
MODE_SELECT_TIMER_L3          call          DELAY100m			;test RESET again for about 10.0 sec. ;5 + 20 = 2.5s
                    decsz         VAR_DC2
                    jmp           MODE_SELECT_TIMER_L3
                    mov           w,#$64						;100
                    mov           VAR_DC2,w						;100+15=115 ? 12.5secs
;test_l3					
DISABLE_MODE          call          DELAY100m
                    sb            IO_REST						;resetted ...enter DEV mode
                    page          $0600
                    jmp           DEV1_MODE_LOAD_START
                    decsz         VAR_DC2
                    jmp           DISABLE_MODE					;...sleep chip , can't wake up without put PS2 into stby
                    sleep         
;RESET0					
TAP_BOOT_MODE          clr           fsr
                    clrb          PSX_FLAG
;RESET_DOWN					
HOLD_BOOT_MODES          snb           DEV1_Flag				;reenter dev mode if rest in dev mode
                    page          $0600
                    jmp           DEV1_MODE_LOAD_START
                    setb          SOFT_RST					;soft reset may need more than 1 disk patch  he he he ....
                    clrb          EJ_FLAG
                    setb          X_FLAG					;first XMAN patch flag
                    clrb          V12Logo_Flag				;clear V12 logo flag patch
                    page          $0200
                    jmp           PS2_MODE_START			;PS2 osd patch or PS1DRV init... (based on psx_flag status)
					
				

;---------------------------------------------------------------------
;PS2 : continue patch after  OSDSYS & wait for disk ready...
;---------------------------------------------------------------------
;PS2_PATCH2
CHECK_IF_START_PS2LOGO          clr           fsr
                    sb            PSX_FLAG
                    page          $0400
                    jmp           START_PS2LOGO_PATCH_LOAD
                    sb            PSX_FLAG
                    jmp           TRAY_IS_EJECTED
;CDDVD_EJECTED					
TRAY_IS_EJECTED          sb            IO_REST				;here from eject
                    jmp           TAP_BOOT_MODE				;reset ?
                    snb           IO_EJECT
                    jmp           TRAY_IS_EJECTED			;wait for tray closed...
;wait for bios cs inactive ( fix for  5 bit bus and cd boot )					
;DELAY1s
RESUME_MODE_FROM_EJECT          mov           w,#$5			;Precise delay routine using RTCC
                    mov           VAR_DC2,w
;ld_del0					
RESUME_MODE_FROM_EJECT_L1          mov           w,#$64		;delay = 100 millisec.
                    mov           VAR_DC1,w
;ld_del					
RESUME_MODE_FROM_EJECT_L2          mov           w,#$3b		;load  timer=61,delay = (256-61)*256*0.02 micros.= 1000 micros.
                    mov           rtcc,w
;ld_del1					
RESUME_MODE_FROM_EJECT_L3          sb            IO_BIOS_CS	;wait again 500msec if bios cs active
                    jmp           RESUME_MODE_FROM_EJECT
                    sb            IO_REST					;new reset check here ...	
                    jmp           TAP_BOOT_MODE
                    snb           IO_EJECT
                    jmp           TRAY_IS_EJECTED			;
                    mov           w,rtcc					;wait for timer= 0 ... (don't use TEST RTCC)
                    sb            z
                    jmp           RESUME_MODE_FROM_EJECT_L3
                    decsz         VAR_DC1
                    jmp           RESUME_MODE_FROM_EJECT_L2
                    decsz         VAR_DC2
                    jmp           RESUME_MODE_FROM_EJECT_L1
                    call          SET_INTRPT				;better here ....
                    clr           fsr
                    snb           DEV1_Flag
                    page          $0600
                    jmp           START_CDDVD_PATCH			;patch media for DEVMODE
                    mov           w,#$2
                    mov           VAR_TOFFSET,w
                    mov           w,#$32					;ASCI 2
                    mov           w,VAR_BIOS_YR-w			; is 2002 Year console
                    snb           z
                    jmp           CONSOLE_2002_JMP			;# of ps2logo patch for PS2 V7
                    mov           w,#$1
                    mov           VAR_TOFFSET,w
;MEPATCH					
CONSOLE_2002_JMP          page          $0600
                    jmp           START_CDDVD_PATCH			;patch ps2 CD/DVD
					
					
;-------------------------------------------------------------------------
;NEW NEW NEW patch psx game... and some protected too 
;-------------------------------------------------------------------------	
;PSX_PATCH
PS1_MODE_START_PATCH          clr           fsr
                    clrb          SCEX_FLAG
                    mov           w,#$ff
                    mov           VAR_PSX_TEMP,w			;autosend correct # of SCEX (max value help bad optics) ;)
;psx_ptc_l0
RUN_PS1_SCEX_INJECT          call          SEND_SCEX
                    snb           SCEX_FLAG
                    jmp           PS1_SCEX_INJECT_COMPLETE
                    decsz         VAR_PSX_TEMP				; loop sending SCEX
                    jmp           RUN_PS1_SCEX_INJECT
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
;DRVPTC					
PS1_SCEX_INJECT_COMPLETE          snb           EJ_FLAG
                    jmp           RUN_PS1_SCEX_INJECT		;send all scex after bios patch then sleep
                    mov           w,#$2
                    mov           VAR_TOFFSET,w				;# of PS1DRV patch for PS2 V7
                    mov           w,#$32
                    mov           w,VAR_BIOS_YR-w
                    snb           z
                    jmp           PS1_IS_V14orV1toV12PALorNTSC
                    mov           w,#$1
                    mov           VAR_TOFFSET,w
;DRV					
PS1_IS_V14orV1toV12PALorNTSC
                    snb           V14_Flag					; check if V14_Flag set meaning v14/75k decka
                    jmp           PS1_V14_PATCH
                    snb           UK_Flag					; fix for ntsc/pal ps1 route v1-12
                    page          $0400
                    jmp           PS1_CONSOLE_PAL_YFIX		; jmp to pal start if pal console
                    page          $0400
                    jmp           PS1_CONSOLE_ALL_JMPNTSC	; fall over to ntsc start if no pal flag set
PS1_V14_PATCH          mov           w,#$31
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
                    jmp           PS1_MODE_START			;exec psxdrv patch + logo1 + set EJect flag and ret to PSX_PATCH

                    org           $0200							; PAGE2 200-3FF

;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P2
;--------------------------------------------------------------------------------
NOTCALLED3          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_WAIT_OE_LO_P2        ; next byte / wait for bios OE low
                    ret           

;---------------------------------------------------------
; NEW BIOS PATCH ROUT
;---------------------------------------------------------
;--------------------------------------------------------------------------------
RUN_BIOS_PATCHES_SRAM
;--------------------------------------------------------------------------------
NOTCALLED1          mov           w,indf									; SRAM address moved to w and output to  IO_BIOS_DATA
                    mov           IO_BIOS_DATA,w
                    inc           fsr										; +1 to step through the SRAM cached patches
                    mov           w,#$10									; 10h or so always in SRAM address section 6.2.1
                    or            fsr,w										; so that ends in top address of registery which is SRAM access. bottom 0-f reserved so when gets 1f goes 30h than 20h
RUN_BIOS_PATCHES_SRAM_SENDLOOP          snb           IO_BIOS_OE			; next byte / wait for bios OE low
                    jmp           RUN_BIOS_PATCHES_SRAM_SENDLOOP			; jmp RUN_BIOS_PATCHES_SRAM_SENDLOOP if IO_BIOS_OE high
                    decsz         VAR_DC2									; loop calling of SRAM cache till VAR_DC2=0 then patch finished, VAR_DC2 set in loading of call here for ea patch
                    jmp           RUN_BIOS_PATCHES_SRAM
END_BIOS_PATCHES_SRAM_RESET_IO          sb            IO_BIOS_OE			; next byte / wait for bios OE high
                    jmp           END_BIOS_PATCHES_SRAM_RESET_IO			; jmp END_BIOS_PATCHES_SRAM_RESET_IO if IO_BIOS_OE high
                    mov           w,#$ff									; 1111 1111
                    mov           !IO_BIOS_DATA,w							; all pins Hi-Z input
                    clr           fsr										;moved here !
                    retp          											; patching done. Return from call
;----------------------------------------------------------
;Patch PS2 game...
;----------------------------------------------------------
;--------------------------------------------------------------------------------
BIOS_PATCH_DATA			;osdsys
;--------------------------------------------------------------------------------
                    jmp           pc+w
;V134
                    retw          $23
                    retw          $80
                    retw          $ac
                    retw          $c
                    retw          $0
                    retw          $0
                    retw          $0
;VX
                    retw          $24	; 7
                    retw          $10
                    retw          $3c
                    retw          $e4
                    retw          $24
                    retw          $80
                    retw          $ac
                    retw          $e4
                    retw          $22
                    retw          $90
                    retw          $ac
                    retw          $84
                    retw          $bc
                    mov           w,#$4f
                    mov           VAR_DC3,w							;79 ; #### ber
                    jmp           BIOS_PATCH_DATA_PART2_ALL
;V9
                    retw          $24	; 23
                    retw          $10
                    retw          $3c
                    retw          $74
                    retw          $2a
                    retw          $80
                    retw          $ac
                    retw          $74
                    retw          $28
                    retw          $90
                    retw          $ac
                    retw          $bc
                    retw          $d3
                    mov           w,#$4f
                    mov           VAR_DC3,w
                    jmp           BIOS_PATCH_DATA_PART2_ALL
;V14?
                    retw          $24	; 39
                    retw          $10
                    retw          $3c
                    retw          $78
                    retw          $2d
                    retw          $80
                    retw          $ac
                    retw          $40
                    retw          $2b
                    retw          $90
                    retw          $ac
                    retw          $a0
                    retw          $ff
                    mov           w,#$4f
                    mov           VAR_DC3,w
                    jmp           BIOS_PATCH_DATA_PART2_ALL
;V10
                    retw          $24	; 55 +8 = 63 ?
                    retw          $10
                    retw          $3c
                    retw          $e4
                    retw          $2c
                    retw          $80
                    retw          $ac
                    retw          $f4
                    retw          $2a
                    retw          $90
                    retw          $ac
                    snb           V12_FLAG
                    jmp           V12_CONSOLE_20_BIOS_JMP
                    mov           w,#$46
                    mov           VAR_DC3,w
                    retw          $a4
                    retw          $ec
                    mov           w,#$4f
                    mov           VAR_DC3,w
                    jmp           BIOS_PATCH_DATA_PART2_ALL
;v12		
V12_CONSOLE_20_BIOS_JMP          mov           w,#$4d
                    mov           VAR_DC3,w
                    retw          $c
                    retw          $f9
;LOAD_END
BIOS_PATCH_DATA_PART2_ALL          retw          $91
                    retw          $34
                    retw          $0
                    retw          $0
                    retw          $30
                    retw          $ae
                    retw          $c
                    retw          $0
                    retw          $0
                    retw          $0
;LOAD_PSX1D					
                    retw          $c7
                    retw          $2
                    retw          $34
                    retw          $19
                    retw          $19
                    retw          $e2
                    retw          $ba
                    retw          $11
                    retw          $19
                    retw          $e2
                    retw          $ba
;extra from final ?					
                    retw          $3c
                    retw          $c7
                    retw          $2
                    retw          $34
                    retw          $19
                    retw          $19
                    retw          $c2
                    retw          $bb
                    retw          $11
                    retw          $19
                    retw          $c2
                    retw          $bb
                    retw          $60
                    retw          $9
                    retw          $8
                    retw          $8
					
;PS2_PATCH					
PS2_MODE_START
;load osdsys data patch for PS2 mode or ps1drv data patch for PSX mode 
                    clr           fsr
                    sb            PSX_FLAG
                    jmp           CHECK_IF_V1_v2or3_V4_V5to8				;ps2 mode selected , skip 
                    snb           V14_Flag
                    page          $0400
                    jmp           PS2LOGO_PATCHLOAD_22_JMP1
                    mov           w,#$b
                    mov           VAR_DC1,w									;psx mode : # of patch bytes  
                    mov           w,#$59									; 89 ;ps1drv data offset here ...
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_psx2					
CHECK_IF_V1_v2or3_V4_V5to8
;ps2 mode data offset 
                    clr           fsr
                    snb           V14_Flag
                    jmp           CHECK_V9to14_REV			;jmp CHECK_V9to14_REV if CHECK_V9to14_REV set meaning W v14/75k+
                    mov           w,#$31					;ascii 1
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 1		;v1
                    snb           z							;skip next line if doesnt = 0 meaning is 1 ascii
                    jmp           V1_CONSOLE_11_BIOS		;jmp V1_CONSOLE_11_BIOS if VAR_BIOS_REV did = 1 ascii
                    mov           w,#$32					;ascii 2
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 2		;v2-3
                    snb           z							;skip next line if doesnt = 0 meaning is 2 ascii
                    jmp           V2or3_CONSOLE_12_BIOS		;jmp V2or3_CONSOLE_12_BIOS if VAR_BIOS_REV did = 2 ascii
                    mov           w,#$35					;ascii 5
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 5		;v4
                    snb           z							;skip next line if doesnt = 0 meaning is 5 ascii
                    jmp           V4_CONSOLE_15_BIOS		;jmp V4_CONSOLE_15_BIOS if VAR_BIOS_REV did = 5 ascii
                    jmp           CHECK_V9to14_REV			;jmp CHECK_V9to14_REV if VAR_BIOS_REV didnt = 5 ascii
;:set_V1					
V1_CONSOLE_11_BIOS          mov           w,#$c0
                    mov           IO_BIOS_DATA,w
                    mov           w,#$b0
                    mov           VAR_DC3,w
                    mov           w,#$74
                    mov           VAR_TOFFSET,w
                    jmp           V1to8_CONTIUNE
;:set_V3					
V2or3_CONSOLE_12_BIOS          mov           w,#$d8
                    mov           IO_BIOS_DATA,w
                    mov           w,#$40
                    mov           VAR_DC3,w
                    mov           w,#$7a
                    mov           VAR_TOFFSET,w
                    jmp           V1to8_CONTIUNE
;:set_V4					
V4_CONSOLE_15_BIOS          mov           w,#$60
                    mov           VAR_DC3,w
                    mov           w,#$7d
                    mov           VAR_TOFFSET,w
                    mov           w,#$c
                    mov           IO_BIOS_DATA,w
;:set_P					
V1to8_CONTIUNE          mov           w,#$7					; V5678
                    mov           VAR_DC1,w
                    mov           VAR_DC2,w
                    clr           w
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_Vx					
CHECK_V9to14_REV          mov           w,#$2
                    mov           IO_BIOS_DATA,w
                    mov           w,#$17
                    mov           VAR_DC1,w
                    mov           VAR_DC2,w					; VAR_DC1 VAR_DC2 = 17h = 23
                    mov           w,#$37					;ascii 7
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 7 ;1.7bios v9-11 50k
                    snb           z
                    jmp           V9_CONSOLE_17_BIOS
                    mov           w,#$39					;ascii 9
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 9 ;1.9bios v9-11 50k
                    snb           z
                    jmp           V9_CONSOLE_19_BIOS
                    mov           w,#$30					;ascii 0
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 0 ;2.0bios v12
                    snb           z
                    jmp           V12_CONSOLE_20_BIOS
                    mov           w,#$32
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           V14_CONSOLE_22_BIOS
                    mov           w,#$30
                    mov           VAR_DC3,w
                    mov           w,#$7d
                    mov           VAR_TOFFSET,w
                    mov           w,#$7						; V5678
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V9					
V9_CONSOLE_17_BIOS          mov           w,#$4
                    mov           VAR_DC3,w
                    mov           w,#$94
                    mov           VAR_TOFFSET,w
                    mov           w,#$17
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V14					
V14_CONSOLE_22_BIOS          setb          V10_FLAG
                    setb          V14_Flag
                    mov           w,#$d4
                    mov           VAR_DC3,w
                    mov           w,#$a9
                    mov           VAR_TOFFSET,w
                    mov           w,#$27
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V10					
V9_CONSOLE_19_BIOS          setb          V10_FLAG
                    mov           w,#$64
                    mov           VAR_DC3,w
                    mov           w,#$9e
                    mov           VAR_TOFFSET,w
                    mov           w,#$37
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V12					
V12_CONSOLE_20_BIOS          setb          V10_FLAG
                    setb          V12_FLAG
                    mov           w,#$7c
                    mov           VAR_DC3,w
                    mov           w,#$a9
                    mov           VAR_TOFFSET,w
                    mov           w,#$37
;:loopxx					
ALL_CONTIUNE_BIOS_PATCH          snb           DEV1_Flag
                    jmp           SECONDBIOS_PATCH_DEV1_STACK
                    mov           VAR_DC3,w
                    mov           w,#$15
                    mov           fsr,w
;:loop					
LOAD_BIOS_PATCH_DATA          mov           w,VAR_DC3
                    call          BIOS_PATCH_DATA
                    mov           indf,w
                    inc           fsr
                    mov           w,#$10
                    or            fsr,w
                    inc           VAR_DC3
                    decsz         VAR_DC1
                    jmp           LOAD_BIOS_PATCH_DATA
                    clr           fsr
                    snb           PSX_FLAG
                    page          $0000
                    jmp           TRAY_IS_EJECTED					;PS2_PATCH2		;exit osd patch if psx mode selected ...
					
;:loop0					
; OSDSYS Wait for 60 00 04 08 ... fixed for V10 :)					
SECOND_BIOS_PATCH_SYNC          snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC
                    mov           w,#$60
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
SECOND_BIOS_PATCH_SYNC_LOOP1          sb            IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP1
SECOND_BIOS_PATCH_SYNC_LOOP2          snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP2
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
SECOND_BIOS_PATCH_SYNC_LOOP3          sb            IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP3
SECOND_BIOS_PATCH_SYNC_LOOP4          snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP4
                    mov           w,#$4
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
SECOND_BIOS_PATCH_SYNC_LOOP5          sb            IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP5
SECOND_BIOS_PATCH_SYNC_LOOP6          snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP6
                    mov           w,#$8
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
                    mov           w,#$15
                    mov           fsr,w
					
;-----------------------------------------------------------
; Patch data for bios OSDSYS 
;-----------------------------------------------------------
;:loop1
SECOND_BIOS_PATCH_SYNC_P2          snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P2
                    mov           w,#$7
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC_P2
SECOND_BIOS_PATCH_SYNC_P3          snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P3
                    mov           w,#$3
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC_P3
;:loop66					
SECOND_BIOS_PATCH_SYNC_P4          sb            IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P4
SECOND_BIOS_PATCH_SYNC_P4_L1          snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P4_L1
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC_P3
SECOND_BIOS_PATCH_SYNC_P4_L2          sb            IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P4_L2
                    mov           !IO_BIOS_DATA,w
SECOND_BIOS_PATCH_SYNC_P4_L3          snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P4_L3
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    snb           DEV1_Flag
                    page          $0600
                    jmp           FINISHED_RUN_START
                    snb           V12Logo_Flag
                    page          $0400
                    jmp           PS1_MODE_SUCESSFUL_END			;logo patch for V12
                    page          $0000
                    jmp           CHECK_IF_START_PS2LOGO			;end of osd patch
					
;SETUPDEV				
SECONDBIOS_PATCH_DEV1_STACK          mov           w,#$1c
                    mov           fsr,w
                    mov           w,VAR_DC3
                    mov           indf,w
                    inc           fsr
                    mov           w,VAR_TOFFSET
                    mov           indf,w
                    clr           fsr
                    mov           w,#$4
                    mov           IO_BIOS_DATA,w
                    mov           w,#$73
                    mov           VAR_DC2,w
                    page          $0200
                    jmp           SECOND_BIOS_PATCH_SYNC
					
					
Label_0097          mov           w,#$34				; ? likely some 75k patches?
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
                    mov           w,#$10
                    mov           VAR_DC1,w
                    mov           w,#$64
                    mov           VAR_DC3,w
                    mov           w,#$5c
                    mov           fsr,w
                    page          $0200							; PAGE2
                    jmp           LOAD_BIOS_PATCH_DATA
					
;----------------------------------------------------------
;XCDVDMAN routine
;---------------------------------------------------------- 
;IS_XCDVDMANX
POST_PATCH_4_MODE_START          page          $0000							; PAGE1
                    call          SET_INTRPT
;IS_XCDVDMAN					
POST_PATCH_4_MODE_START2          snb           DEV1_Flag
                    page          $0600
                    jmp           FINISHED_RUN_START_P2
                    mov           w,#$64							; 100
                    mov           VAR_TOFFSET,w						; 30-35 sec wait for BIOS
;IS_XCDVDMAN:loop4
POST_PATCH_4_MODE_START_L1          mov           w,#$ff
                    mov           VAR_DC3,w
;IS_XCDVDMAN:loop3				
POST_PATCH_4_MODE_START_L2          mov           w,#$ff
                    mov           VAR_DC2,w
;IS_XCDVDMAN:loop2				
POST_PATCH_4_MODE_START_L3          mov           w,#$ff
                    mov           VAR_DC1,w
;IS_XCDVDMAN:loopx				
POST_PATCH_4_MODE_START_L4          sb            IO_BIOS_CS
                    jmp           POST_PATCH_4_MODE_START_P2
                    decsz         VAR_DC1
                    jmp           POST_PATCH_4_MODE_START_L4
                    decsz         VAR_DC2
                    jmp           POST_PATCH_4_MODE_START_L3
                    decsz         VAR_DC3
                    jmp           POST_PATCH_4_MODE_START_L2
                    decsz         VAR_TOFFSET
                    jmp           POST_PATCH_4_MODE_START_L1
                    jmp           PS2_MODE_RB_IO_SET_SLEEP			; no xcdvdman reload ...
					
;IS_XCDVDMAN:loop0					
POST_PATCH_4_MODE_START_L5          snb           IO_BIOS_CS
                    jmp           POST_PATCH_4_MODE_START_L4
;IS_XCDVDMAN:loop1					
POST_PATCH_4_MODE_START_P2          mov           w,#$a2			;sync A2 93 23 for V1-V10
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH_4_MODE_START_L5
                    call          BIOS_WAIT_OE_LO_P2
                    mov           w,#$93
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH_4_MODE_START_L5
                    call          BIOS_WAIT_OE_LO_P2
                    mov           w,#$34
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH_4_MODE_START_L5
;XCDVDMAN					
                    clr           fsr
                    mov           w,#$7
                    mov           VAR_DC2,w
                    mov           w,#$8
                    mov           IO_BIOS_DATA,w					;send 08
;xcdvdman1_l0a					
POST_PATCH4MODE_START_P2_L1          snb           IO_BIOS_OE
                    jmp           POST_PATCH4MODE_START_P2_L1
                    mov           w,#$27							;27 18 00 A3 (A3)
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L1
                    call          BIOS_WAIT_OE_LO_P2
                    mov           w,#$18
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L1
                    call          BIOS_WAIT_OE_LO_P2
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L1
                    call          BIOS_WAIT_OE_LO_P2
                    mov           w,#$a3
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L1
; patch it
; Addr 00006A28 export 0x23(Cd Check) kill it
; 00006A28: 08 00 E0 03  jr ra
; 00006A2C: 00 00 00 00  nop					
                    snb           X_FLAG							;first XMAN executed !
                    jmp           POST_PATCH4MODE_END_P2
;xcdvdman1_next					
                    mov           w,#$15
                    mov           fsr,w
;xcdvdman1_l1					
POST_PATCH4MODE_START_P2_L2          snb           IO_BIOS_OE
                    jmp           POST_PATCH4MODE_START_P2_L2
                    nop           
                    mov           w,#$27
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L2
POST_PATCH4MODE_START_P2_L3          sb            IO_BIOS_OE
                    jmp           POST_PATCH4MODE_START_P2_L3
                    mov           !IO_BIOS_DATA,w
POST_PATCH4MODE_END_P1          snb           IO_BIOS_OE
                    jmp           POST_PATCH4MODE_END_P1
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    sb            EJ_FLAG
                    page          $0000
                    jmp           TRAY_IS_EJECTED				;jump to EJECTED if no EJ_FLAG = first xman patch for originals
                    jmp           POST_PATCH_4_MODE_START2		;? da verificare !!!
;again
POST_PATCH4MODE_END_P2          clrb          X_FLAG
                    jmp           POST_PATCH_4_MODE_START2		;patch cddvdman & xcdvdman

;TO SLEEP ... , PERHARPS TO DREAM ...
PS2_MODE_RB_IO_SET_SLEEP          mode          $000A			; XAh WKED_B Each register bit selects the edge sensitivity of the corresponding Port B input pin for MIWU operation. ;todo
                    mov           w,#$6							; 0000 0110 Set the bit to 1 to sense falling (high-to-low) edges.
                    mov           !IO_CDDVD_BUS,w				; rb.1 IO_BIOS_CS rb.2 IO_REST high-to-low sense
                    mode          $0009							; X9h Exchange WKPND_B
                    clr           w								; 0000 0000
                    mov           !IO_CDDVD_BUS,w				; A bit set to 1 indicates that a valid edge has occurred on the corresponding MIWU pin, triggering a wakeup or interrupt. 
																; A bit set to 0 indicates that no valid edge has occurred on the MIWU pin. 
																; The WKPND_B register comes up with undefine value upon reset.
                    mode          $000B							; XBh WKEN_B	Multi-Input Wakeup/Interrupt (MIWU) function for the corresponding Port B input pin. 
																; Clear the bit to 0 to enable MIWU operation or set the bit to 1 to disable MIWU operation.
                    snb           PSX_FLAG				; jmp PS1_MODE_RB_IO_SET_SLEEP if PSX_FLAG is set
                    jmp           PS1_MODE_RB_IO_SET_SLEEP		; skip below io set and jmp PS1_MODE_RB_IO_SET_SLEEP
                    mov           w,#$f1						; 1111 0001
                    mov           !IO_CDDVD_BUS,w				; rb.1 IO_BIOS_CS rb.2 IO_REST rb.3 IO_EJECT enabled
                    sleep         
					
PS1_MODE_RB_IO_SET_SLEEP          mov           w,#$f3						; 1111 0011
                    mov           !IO_CDDVD_BUS,w				; rb.2 IO_REST rb.3 IO_EJECT enabled
                    sleep         

                    org           $0400							; PAGE4 400-5FF

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
                    retw          $e0
                    retw          $3
                    retw          $21
                    retw          $10
                    retw          $0
                    retw          $0
					
                    mov           w,#$33							;51
                    mov           VAR_DC3,w
                    sb            V14_Flag
                    jmp           PS2LOGO_PATCH_not22_JMP1
;v14?				
                    mov           w,#$d								;13
                    mov           VAR_DC3,w
                    retw          $40
                    retw          $8
                    retw          $11
                    retw          $3c
                    retw          $8
                    retw          $0
                    retw          $32
                    retw          $36
                    retw          $f8
                    retw          $1
                    retw          $92
                    retw          $ac
                    retw          $21
                    retw          $0
                    retw          $40
                    retw          $8
                    retw          $b
                    retw          $0
                    retw          $32
                    retw          $36
                    retw          $10
                    retw          $0
                    retw          $4
                    retw          $3c
                    retw          $18
                    retw          $16
                    retw          $92
                    retw          $ac
                    retw          $0
                    retw          $0
                    retw          $4
                    retw          $8
                    mov           w,#$46							;70
                    mov           VAR_DC3,w
                    snb           V14_Flag
                    jmp           PS2LOGO_PATCH_22_JMP2
;not v14 patches, how flows?					
                    mov           w,#$33							;51
                    mov           VAR_DC3,w
;v12					
PS2LOGO_PATCH_not22_JMP1          retw          $8
                    retw          $11
                    retw          $3c
                    retw          $c1
                    retw          $0
                    retw          $32
                    retw          $36
                    retw          $18
                    retw          $16
                    retw          $92
                    retw          $ac
                    retw          $c
                    retw          $0
                    retw          $0
                    retw          $0
;LOGO2					
PS2LOGO_PATCH_22_JMP2          retw          $0
                    retw          $0
                    retw          $0
                    retw          $0
                    retw          $20
                    retw          $38
                    retw          $11
                    retw          $0
                    retw          $0
                    retw          $60
                    retw          $3
                    retw          $24
                    retw          $0
                    retw          $0
                    retw          $e2
                    retw          $90
                    retw          $0
                    retw          $0
                    retw          $e4
                    retw          $90
                    retw          $ff
                    retw          $ff
                    retw          $63
                    retw          $24
                    retw          $26
                    retw          $20
                    retw          $82
                    retw          $0
                    retw          $0
                    retw          $0
                    retw          $e4
                    retw          $a0
                    retw          $fb
                    retw          $ff
                    retw          $61
                    retw          $4
                    retw          $1
                    retw          $0
                    retw          $e7
                    retw          $24
                    mov           w,#$75							;117
                    mov           VAR_DC3,w
                    snb           V10_FLAG
                    jmp           PS2LOGO_PATCH_19_20_JMP1
                    mov           w,#$70							;112
                    mov           VAR_DC3,w
                    retw          $d0
                    retw          $80
                    mov           w,#$77							;119
                    mov           VAR_DC3,w
                    jmp           PS2LOGO_PATCH_11_17_JMP1
;LOADV10A					
PS2LOGO_PATCH_19_20_JMP1          retw          $50
                    retw          $81
;LOADL1					
PS2LOGO_PATCH_11_17_JMP1          retw          $80
                    retw          $af
                    retw          $2e
                    retw          $1
                    retw          $22
                    retw          $92
                    retw          $2f
                    retw          $1
                    retw          $23
                    retw          $92
                    retw          $26
                    retw          $10
                    retw          $43
                    retw          $0
                    retw          $1a
                    retw          $0
                    retw          $3
                    retw          $24
                    retw          $3
                    retw          $0
                    retw          $43
                    retw          $14
                    retw          $1
                    retw          $0
                    retw          $7
                    retw          $24
                    mov           w,#$ab							;171
                    mov           VAR_DC3,w
                    snb           V10_FLAG
                    jmp           PS2LOGO_PATCH_19_20_JMP2
                    mov           w,#$97							;151
                    mov           VAR_DC3,w
                    retw          $bd
                    retw          $5
                    retw          $4
                    retw          $8
                    retw          $cc
                    retw          $80
                    retw          $87
                    retw          $af
                    retw          $0
                    retw          $0
                    retw          $7
                    retw          $24
                    retw          $bd
                    retw          $5
                    retw          $4
                    retw          $8
                    retw          $cc
                    retw          $80
                    retw          $87
                    retw          $af
;V10-12				
PS2LOGO_PATCH_19_20_JMP2          retw          $af
                    retw          $5
                    retw          $4
                    retw          $8
                    retw          $4c
                    retw          $81
                    retw          $87
                    retw          $af
                    retw          $0
                    retw          $0
                    retw          $7
                    retw          $24				
                    retw          $af
                    retw          $5
                    retw          $4
                    retw          $8
                    retw          $4c
                    retw          $81
                    retw          $87
                    retw          $af
				

;XMAN?
PS2LOGO_PATCHLOAD_22_JMP1          mov           w,#$27				;39
                    mov           VAR_DC1,w
                    jmp           PS2LOGO_PATCHLOAD_22_JMP2
;XMAN?					
START_PS2LOGO_PATCH_LOAD          mov           w,#$7b				;123
                    mov           VAR_DC1,w
                    snb           V14_Flag
                    jmp           PS2LOGO_PATCHLOAD_22_JMP2
                    mov           w,#$6e							;110
                    mov           VAR_DC1,w
;PS2_PS2LOGO					
;PS2_PS2LOGO:loopa					
PS2LOGO_PATCHLOAD_22_JMP2          clr           w
                    mov           VAR_DC3,w
                    mov           w,#$15							;21
                    mov           fsr,w
;PS2_PS2LOGO:loop
PS2LOGO_PATCHLOAD_LOOP          mov           w,VAR_DC3
                    call          PS2LOGO_PATCH
                    mov           indf,w
                    inc           fsr
                    mov           w,#$10							;16
                    or            fsr,w
                    inc           VAR_DC3
                    decsz         VAR_DC1
                    jmp           PS2LOGO_PATCHLOAD_LOOP
                    clr           fsr
                    snb           PSX_FLAG
                    page          $0200
                    jmp           Label_0097
                    snb           X_FLAG
                    page          $0200
                    jmp           POST_PATCH_4_MODE_START2
					
;PS2_PS2LOGO:loopz		
PS1_DETECTED_REBOOT          clr           fsr
                    mov           w,#$75
                    mov           VAR_DC2,w
                    mov           w,#$1
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,#$c0
                    mov           VAR_PSX_TEMP,w
                    mov           w,#$72
                    mov           VAR_PSX_BITC,w
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    snb           V14_Flag
                    jmp           PS1_DETECTED_REBOOT_JMP20to22
;load regs with v12 logo sync					
                    mov           w,#$67							;107
                    mov           VAR_DC2,w							;V12 logo lenght
                    mov           w,#$8
                    mov           VAR_PSX_BC_CDDVD_TEMP,w			;V12 sync data
                    mov           w,#$e0
                    mov           VAR_PSX_TEMP,w
                    mov           w,#$9d
                    mov           VAR_PSX_BITC,w
                    mov           w,#$40
                    mov           IO_BIOS_DATA,w					;V12 bios preload
                    snb           V12_FLAG
                    jmp           PS1_DETECTED_REBOOT_JMP20to22
;load regs with v10 sync					
                    mov           w,#$af
                    mov           VAR_PSX_BC_CDDVD_TEMP,w			;V10 sync data
                    mov           w,#$6
                    mov           VAR_PSX_TEMP,w
                    mov           w,#$8
                    mov           VAR_PSX_BITC,w
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w					;V1-V10 bios preload
                    snb           V10_FLAG
                    jmp           PS1_DETECTED_REBOOT_JMP11to17_ALL
;load regs with v1-v9 sync					
                    mov           w,#$1e
                    mov           VAR_PSX_TEMP,w					;V1-V9 sync data 

;PS2_PS2LOGO:patchlogo2
PS1_DETECTED_REBOOT_JMP11to17_ALL          mov           w,#$57
                    mov           VAR_DC2,w
;PS2_PS2LOGO:loop4					
PS1_DETECTED_REBOOT_JMP20to22          mov           w,#$50
                    mov           VAR_PSX_BYTE,w
;PS2_PS2LOGO:loop3					
PS1_DETECTED_REBOOT_L1          mov           w,#$ff
                    mov           VAR_DC3,w
;PS2_PS2LOGO:loop2					
PS1_DETECTED_REBOOT_L2          mov           w,#$ff
                    mov           VAR_DC1,w
;PS2_PS2LOGO:loopx					
AUTO_REBOOT_PS1MODE          sb            IO_BIOS_CS
                    jmp           PSX_MODE_START_P2
                    decsz         VAR_DC1
                    jmp           AUTO_REBOOT_PS1MODE
                    decsz         VAR_DC3
                    jmp           PS1_DETECTED_REBOOT_L2
                    decsz         VAR_PSX_BYTE
                    jmp           PS1_DETECTED_REBOOT_L1
					
;AUTORESET 	
;NEW!!! future board design using a 2N7002 mosfet					
	IFDEF	RSTBUMP
                   mode          $000B						;disable interrupt , need !!! ...
                   mov           w,#$ff						; 1111 1111
                   mov           !IO_CDDVD_BUS,w						; above set for IO_CDDVD_BUS
                   mode          $000F						; XFh mode direction for RA, IO_CDDVD_BUS, RC output
                   mov           w,#$0						; 0000 0000
                   mov           IO_CDDVD_BUS,w						; IO_CDDVD_BUS = 0 ? clear IO_CDDVD_BUS values
                   mov           w,#$fb						; 1111 1011 IO_REST IO_REST output
	ELSE
                   mov           w,#$0						; set w = #$0 = 0
                   mov           IO_CDDVD_BUS,w						; set IO_CDDVD_BUS = w = 0 ? clear IO_CDDVD_BUS values
                   mov           w,#$fe						; 1111 1110 IO_CDDVD_BUS_f F output
	ENDIF
	
                    mov           !IO_CDDVD_BUS,w
                    page          $0000
                    call          DELAY100m
                    mov           w,#$ff
                    mov           !IO_CDDVD_BUS,w
                    setb          PSX_FLAG
                    page          $0000
                    jmp           CHECK_IF_V9to14
					
;sync for all versions using regs :))	
;PS2_PS2LOGO::loop00x 
PS1_MODE_START          snb           IO_BIOS_CS
                    jmp           AUTO_REBOOT_PS1MODE
;PS2_PS2LOGO:loop1x		
PSX_MODE_START_P2          mov           w,VAR_PSX_BC_CDDVD_TEMP
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_START
PS1_MODE_L1          sb            IO_BIOS_OE
                    jmp           PS1_MODE_L1
PS1_MODE_L2          snb           IO_BIOS_OE
                    jmp           PS1_MODE_L2
                    mov           w,VAR_PSX_TEMP
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_START
PS1_MODE_L3          sb            IO_BIOS_OE
                    jmp           PS1_MODE_L3
PS1_MODE_L4          snb           IO_BIOS_OE
                    jmp           PS1_MODE_L4
                    mov           w,VAR_PSX_BITC
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_START
                    mov           w,#$1b
                    mov           fsr,w
                    snb           V14_Flag
                    jmp           PS1_MODE_L5
                    snb           V12_FLAG
                    jmp           PS1_MODE_v12_PATCHS
                    mov           w,#$3c
                    mov           fsr,w
PS1_MODE_L5          snb           IO_BIOS_OE
                    jmp           PS1_MODE_L5
                    nop           
                    mov           w,#$c
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_L5
PS1_MODE_L6          sb            IO_BIOS_OE
                    jmp           PS1_MODE_L6
                    mov           !IO_BIOS_DATA,w
;PS2_PS2LOGO:loop1					
PS1_MODE_L7          snb           IO_BIOS_OE
                    jmp           PS1_MODE_L7
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    decsz         VAR_TOFFSET
                    jmp           PS1_DETECTED_REBOOT_JMP11to17_ALL		;patch logo 2 times for V7 only !
;PS2_PS2LOGO:back					
PS1_MODE_SUCESSFUL_END          snb           PSX_FLAG
                    jmp           PS1_CONSOLE_ALL_JMPNTSC
                    setb          EJ_FLAG
                    page          $0200
                    jmp           POST_PATCH_4_MODE_START2
					
;V12 logo sync					
PS1_MODE_v12_PATCHS          mov           w,#$1c
                    mov           fsr,w
                    setb          V12Logo_Flag
                    page          $0200
                    jmp           SECOND_BIOS_PATCH_SYNC_P2
					
;psx1 driver patch ...
;PSX1DRV
PS1_CONSOLE_PAL_YFIX
;V7DRV
                    mov           w,#$3c
                    mov           IO_BIOS_DATA,w
                    mov           w,#$b
                    mov           VAR_DC2,w
                    mov           w,#$15					; fsr decimal 21
                    mov           fsr,w

;10 01 00 43 30	
;psx1drv_l0
PS1_CONSOLE_PAL_YFIX_SYNC          snb           IO_BIOS_OE
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
PS1_CONSOLE_PAL_YFIX_SYNC_L1          snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L1
                    nop           
                    mov           w,#$30
                    mov           w,IO_BIOS_DATA-w					; 3C C7 34 19 19 E2 B2 19 E2 BA
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L1
PS1_CONSOLE_PAL_YFIX_SYNC_L2          sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L2
                    mov           !IO_BIOS_DATA,w
PS1_CONSOLE_PAL_YFIX_SYNC_L3          snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L3
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    decsz         VAR_TOFFSET
                    jmp           PS1_CONSOLE_PAL_YFIX
;LOGO					
PS1_CONSOLE_ALL_JMPNTSC          mov           w,#$34								; should jmp here for ntsc but is no flow to here besides via ps1 hence poor ntsc console ps1 support h2o. is no ntsc yfix
                    mov           VAR_DC1,w
                    mov           w,#$18
                    mov           VAR_DC3,w
                    mov           VAR_TOFFSET,w
;logo_l1															;match FDFF8514
PS1_CONSOLE_ALL_JMPNTSC_SYNC          snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC
                    mov           w,#$fd
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L1          sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L1
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L2          snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L2
                    mov           w,#$ff
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L3          sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L3
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L4          snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L4
                    mov           w,#$85
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L5          sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L5
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L6          snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L6
                    mov           w,#$14
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC
;logo_skip					
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L7          sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L7
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L8          snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L8
                    decsz         VAR_DC1
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L7
                    mov           w,#$3
                    mov           IO_BIOS_DATA,w
PS1_CONSOLE_ALL_JMPNTSC_PATCH1          sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_PATCH1
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
PS1_CONSOLE_ALL_JMPNTSC_SYNC2          sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC2
PS1_CONSOLE_ALL_JMPNTSC_SYNC2_L1          snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC2_L1
                    decsz         VAR_DC3
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC2
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
PS1_CONSOLE_ALL_JMPNTSC_PATCH2          sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_PATCH2
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
PS1_CONSOLE_ALL_JMPNTSC_SYNC3          sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC3
PS1_CONSOLE_ALL_JMPNTSC_SYNC3_L1          snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC3_L1
                    decsz         VAR_TOFFSET
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC3
                    mov           w,#$88
                    mov           IO_BIOS_DATA,w
PS1_CONSOLE_ALL_JMPNTSC_SYNC3_L2          sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC3_L2
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

                    org           $0600							; PAGE8 600-7FF

;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P8
;--------------------------------------------------------------------------------
NOTCALLED4          snb           IO_BIOS_OE          		; next byte / wait for bios OE low
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
					
DEV1_MODE_LOAD_START          clrb          PSX_FLAG			; PSX_FLAG clrb here related finish mode run ?
                    setb          SOFT_RST
                    setb          EJ_FLAG						; skip logo patch after media for DEVMODE
                    setb          DEV1_Flag						;set DEVMODE flags
                    mov           w,#$73
                    mov           VAR_DC1,w				; VAR_DC1 = 73h = 115
                    clr           w
                    mov           VAR_DC3,w				; VAR_DC3 = 0
                    mov           w,#$15
                    mov           fsr,w						; fsr = 15h with fsr starting for SRAM patch caching. start 15h due to 10-14 disabled bank 0
DEV1_MODE_LOAD_LOOP          mov           w,VAR_DC3
                    call          BIOS_PATCH_DEV1
                    mov           indf,w					; mov value in w from patch data retw to indf which places it in the SRAM memory cache as addressed cycling.
                    inc           fsr						; +1 fsr to step up SRAM patch caching
                    mov           w,#$10					; so that ends in top address of registery which is SRAM access. bottom 0-f reserved so when gets 1f goes 30h than 20h
                    or            fsr,w						; section 6.2.1 fig. 6-1 start at 15h then increase one 0001 0110 or 0001 0000 = 0001 1101 = 16h repeat
                    inc           VAR_DC3					; + 1 VAR_DC3 starting 0 above
                    decsz         VAR_DC1					; jmp DEV1_MODE_LOAD_LOOP till VAR_DC1 = 0 start 119
                    jmp           DEV1_MODE_LOAD_LOOP
                    page          $0200								; PAGE2
                    jmp           CHECK_IF_V1_v2or3_V4_V5to8

;--------------------------------------------------------------------------------
MECHACON_WAIT_OE
;--------------------------------------------------------------------------------
NOTCALLED2
;CDDVDSKIP_P8
                    snb           IO_CDDVD_OE_A_1Q  ; jmp MECHACON_WAIT_OE if ^Q = 1
                    jmp           MECHACON_WAIT_OE  ; wait until flipflop ^Q == 0
                    clrb          IO_CDDVD_OE_A_1R  ; reset flipflop so Q = 0 (and ^Q = 1)
                    nop                             ; ...
                    setb          IO_CDDVD_OE_A_1R  ; reset flipflop so ready for if lower sensed on cp (A) CONSOLE_IO_CDDVD_OE_A
                    decsz         VAR_DC1           ; decrement counter and repeat MECHACON_WAIT_OE if not yet zero
                    jmp           MECHACON_WAIT_OE  ; ...
                    ret                             ; counter finished: return        

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
START_CDDVD_PATCH          clr           fsr
                    setb          IO_CDDVD_OE_A_1R
;execute first patch for V12 only ...					
                    snb           V14_Flag
                    jmp           V9toV14_CONSOLE_CDDVD_START
                    mov           w,#$30			
                    mov           w,VAR_BIOS_REV-w
                    snb           z				
                    jmp           V9toV14_CONSOLE_CDDVD_START			;patch DVD media for V12
                    mov           w,#$37
                    mov           w,VAR_BIOS_REV-w
                    snb           c
                    jmp           V9toV14_CONSOLE_CDDVD_START			;patch DVD media for V9-10
;V1-V8 version... fix for HDD operations ( bios activity )	
;HDD_FIX
V1toV8_CONSOLE_CDDVD_START          mov           w,#$4
                    mov           VAR_DC1,w
;:l0					
V1toV8_AND_BYTE_SYNC1          mov           w,#$90
V1toV8_AND_BYTE_SYNC1_L1          snb           IO_CDDVD_OE_A_1Q		;wait sync byte FF FF FF FF
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
V9toV14_CONSOLE_CDDVD_START          mov           w,#$f				;15
                    mov           VAR_DC1,w								;skip 16 byte for V9-10-12 dvd patch ,15 is a fix !!!
;dvd_patch1					
V9toV14_AND_BYTE_SYNC1          mov           w,#$b0
V9toV14_AND_BYTE_SYNC1_L1          snb           IO_CDDVD_OE_A_1Q
                    jmp           V9toV14_AND_BYTE_SYNC1_L1
                    clrb          IO_CDDVD_OE_A_1R
                    and           w,IO_CDDVD_BUS
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    setb          IO_CDDVD_OE_A_1R
                    mov           w,#$a0
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    sb            z
                    jmp           V9toV14_AND_BYTE_SYNC1				;FA-FC
                    mov           w,#$b0
;media_l1					
V9toV14_AND_BYTE_SYNC1_L2          snb           IO_CDDVD_OE_A_1Q
                    jmp           V9toV14_AND_BYTE_SYNC1_L2
                    clrb          IO_CDDVD_OE_A_1R
                    and           w,IO_CDDVD_BUS
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    setb          IO_CDDVD_OE_A_1R
                    mov           w,#$b0								;FF	
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    snb           z
                    jmp           V9toV12_AND_BYTE_SYNC2
                    mov           w,#$0									;00
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    sb            z
                    jmp           V9toV14_AND_BYTE_SYNC1
;media_l2					
V9toV12_AND_BYTE_SYNC2          mov           w,#$b0
V9toV12_AND_BYTE_SYNC2_L1          snb           IO_CDDVD_OE_A_1Q
                    jmp           V9toV12_AND_BYTE_SYNC2_L1
                    clrb          IO_CDDVD_OE_A_1R
                    and           w,IO_CDDVD_BUS
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    setb          IO_CDDVD_OE_A_1R
                    mov           w,#$b0								;FF	
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    snb           z
                    jmp           V9toV12_CONSOLE_PATCH1_POST
                    mov           w,#$a0								;FC
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    sb            z
                    jmp           V9toV14_AND_BYTE_SYNC1
                    snb           PSX_FLAG
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP				
                    call          MECHACON_WAIT_OE						;sleep for DVD media loaded in PSX mode
;dvd_patch2	
;Patch bus first time	
;only F,G bit need patch :)
;patch to	0X 0X 0X 0X 
;dvdr game  is 	0F 25 0F 25
;dvdrom game is 02 01 02 01
;dvd-rw game is 0F 32 0F 32
;dvd9 video is  02 01 02 01
                    mov           w,#$0									;patch bus first time !
                    mov           IO_CDDVD_BUS,w
                    mov           w,#$1f								;0001 1111	;mechacon bus: IHGBXXXF ; '0' = output !
V9toV12_AND_BYTE_SYNC2_L2          snb           IO_CDDVD_OE_A_1Q		
                    jmp           V9toV12_AND_BYTE_SYNC2_L2				;patch 4 bytes
                    clrb          IO_CDDVD_OE_A_1R						;this is byte #1
                    mov           !IO_CDDVD_BUS,w
                    setb          IO_CDDVD_OE_A_1R						;
					
                    mov           w,#$5
                    mov           VAR_DC1,w								;skip 5 bytes , FIX for 15 bytes skip (see above ...)
                    call          MECHACON_WAIT_OE
                    mov           w,#$ff								;1111 1111
                    mov           !IO_CDDVD_BUS,w
;CDDVD_PATCH					
V9toV12_CONSOLE_PATCH1_POST          snb           PSX_FLAG
                    page          $0000
                    jmp           PS1_MODE_START_PATCH
;CDDVD_PATCH_V1
;wait for mecha FA-FF-FF-01-00-00-01 then patch to 81
;dvd_l1
ALL_CDDVD_PATCH1_GET_SYNC_BIT          sb            IO_BIOS_CS
                    jmp           CDDVD_IS_PS1
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT			;wait sync byte FA FF FF ...
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;dvd_l2					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L1          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L1
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;dvd_l3					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L2          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L2
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;dvd_l4					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L3          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L3
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;dvd_l5					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L4          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L4
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           V9toV12_CONSOLE_PATCH1_POST
;dvd_l6					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L5          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L5
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           V9toV12_CONSOLE_PATCH1_POST
;dvd_l7					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L6          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L6
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           V9toV12_CONSOLE_PATCH1_POST
					
	IFDEF	RSTBUMP
                    sb            IO_CDDVD_BUS_h
                    setb          JAP_Flag
	ENDIF
                    snb           PSX_FLAG
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP					;V1-V8: sleep for DVD media loaded in PSX mode
;dvd_c1					
                    mov           w,#$90									;NEW 1 time 1 BYTE patch !!!!!!!!!
                    mov           IO_CDDVD_BUS,w
                    mov           w,#$6f
ALL_CDDVD_PATCH1          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1
                    clrb          IO_CDDVD_OE_A_1R
                    mov           !IO_CDDVD_BUS,w
                    setb          IO_CDDVD_OE_A_1R
CDDVD_REGION          snb           IO_CDDVD_OE_A_1Q
                    jmp           CDDVD_REGION
                    clrb          IO_CDDVD_OE_A_1R
                    mov           w,#$ff
                    mov           !IO_CDDVD_BUS,w
                    setb          IO_CDDVD_OE_A_1R
;prepare patch region , here for speed !!! No move!!!						
                    snb           JAP_Flag
                    jmp           CDDVD_JAP
                    snb           UK_Flag
                    jmp           CDDVD_PAL
;:reg_usa					
                    clr           w
                    jmp           ALL_CDDVD_PATCH_SET_VAR_DC3
;:reg_uk					
CDDVD_PAL          mov           w,#$8
                    jmp           ALL_CDDVD_PATCH_SET_VAR_DC3
;:reg_jap					
CDDVD_JAP          mov           w,#$10
ALL_CDDVD_PATCH_SET_VAR_DC3          mov           VAR_DC2,w				; save offset...
                    mov           w,#$8										;region patch : # of bytes to patch
                    mov           VAR_DC3,w
                    mov           w,#$ff
                    mov           IO_CDDVD_BUS,w							;!!!!!!!!!!!!!	critical	
;WAIT_DISK
;wait_dvd_lx
ALL_CDDVD_PATCH_SYNC2_BIT          mov           w,#$3
                    mov           VAR_DC1,w									;skip 6 byte (FA,FF,FF,FA,FF,FF)
;wait_dvd_l0					
ALL_CDDVD_PATCH_SYNC2_BIT_L1          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT_L1
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT
ALL_CDDVD_PATCH_SYNC2_BIT_L2          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT_L2
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH_SYNC2_BIT
ALL_CDDVD_PATCH_SYNC2_BIT_L3          snb           IO_CDDVD_OE_A_1Q
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
                    mov           w,#$f										; 0000 1111 = 0 output
                    mov           !IO_CDDVD_BUS,w
;reg_l1					
RUN_CDDVD_PATCH          mov           w,VAR_DC2
                    call          CDDVD_PATCH_DATA
RUN_CDDVD_PATCH_NIBBLE          snb           IO_CDDVD_OE_A_1Q
                    jmp           RUN_CDDVD_PATCH_NIBBLE
                    mov           IO_CDDVD_BUS,w
                    clrb          IO_CDDVD_OE_A_1R
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,<>VAR_PSX_BC_CDDVD_TEMP
                    setb          IO_CDDVD_OE_A_1R
RUN_CDDVD_PATCH_NIBBLE_SEND          snb           IO_CDDVD_OE_A_1Q
                    jmp           RUN_CDDVD_PATCH_NIBBLE_SEND
                    mov           IO_CDDVD_BUS,w
                    clrb          IO_CDDVD_OE_A_1R
                    inc           VAR_DC2
                    setb          IO_CDDVD_OE_A_1R
                    decsz         VAR_DC3
                    jmp           RUN_CDDVD_PATCH
CDDVD_PATCH_POST_RB_INPUT          snb           IO_CDDVD_OE_A_1Q
                    jmp           CDDVD_PATCH_POST_RB_INPUT
                    mov           w,#$ff
                    mov           !IO_CDDVD_BUS,w
                    snb           SOFT_RST
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;exit_patch					
CDDVD_IS_PS1          clrb          SOFT_RST
                    snb           EJ_FLAG
                    page          $0200
                    jmp           POST_PATCH_4_MODE_START2
                    page          $0400
                    jmp           PS1_DETECTED_REBOOT
					
;Modload repatch...					
FINISHED_RUN_START          page          $0000
                    call          SET_INTRPT
                    mov           w,#$4
                    mov           VAR_DC1,w
FINISHED_RUN_START_P2          snb           IO_BIOS_OE
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
FINISHED_RUN_START_P2_L1          snb           IO_BIOS_OE
                    jmp           FINISHED_RUN_START_P2_L1
                    mov           w,#$d0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2_L1
FINISHED_RUN_START_P2_L2          sb            IO_BIOS_OE
                    jmp           FINISHED_RUN_START_P2_L2
FINISHED_RUN_START_P2_L3          snb           IO_BIOS_OE
                    jmp           FINISHED_RUN_START_P2_L3
                    mov           w,#$ff
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2_L1
FINISHED_RUN_START_P2_L4          sb            IO_BIOS_OE
                    jmp           FINISHED_RUN_START_P2_L4
FINISHED_RUN_END          snb           IO_BIOS_OE
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
                    end
