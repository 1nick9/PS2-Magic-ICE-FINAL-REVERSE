;********************************************************************************
;                  final-48.sxh				hash 3267F8B788048663ABC6E1116F0F6048
;********************************************************************************
                   device        SX48,TURBO,BOROFF,OSCHS2,OPTIONX,WDRT006
                    ID                    'ICEREV'
					;; double ; for needs attension for mistakes or areas to change to function alike h2o or just general check here marker
;DEFINE
;RSTBUMP			= 	1			; uncomment for compiling with restbump for ps1mode. else is compiled as f=tr			DBE25B9DD8BF68CD48CBE23B16534DEA

;;ignore these defines below for now, not implemented yet

;USE ONLY IF F=TR commented out RSTBUMP
;pal v14 dont define any. for jap/usa define only one for 75k this will make f=tr work correctly also h=rw usa/pal			f=tr 75k pal d8d6a5acf3e30901b45b75b001ff457c
;USAv14			= 	1			;uncomment for fixed 75k being usa region. all prior still work any region		f=tr 75k usa 809aa1533abed9cbdf2ed612a6fc5627
;JAPv14orv8			= 	1			;uncomment for fixed 75k being jap region. all prior still work any region		f=tr 75k jap 7a35a0a6001a04ed71509a1c18b6544f
;also for v7 to use v9+ mechacon patch for v8 jap support f=tr 
;NTSCPS1YFIX75K		= 	1			;uncomment for 75k NTSC IMPORT YFIX PAL CONSOLE TESTED makes pal off screen but ntsc correct. off pal correct, ntsc crushed.
;NTSCPS1YFIX75K ON rstbump 891246cec7e63bc112c4005b700a7a22 f=tr 75k pal ec962491125e6e2196e215b6cb5222a1
;only rstbump v8jap tested but rest should be right

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

;regs
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

;------------------------------------------------------------
;VAR_PATCH_FLAGS
;------------------------------------------------------------
EJ_FLAG = VAR_PATCH_FLAGS.0
;bit 0 used by eject routine

SOFT_RST = VAR_PATCH_FLAGS.1
;soft reset flag for disk patch 

PSX_FLAG = VAR_PATCH_FLAGS.2
;psx mode flag	

V10_FLAG = VAR_PATCH_FLAGS.3	;bios 1.9 or 2.0
;also v10 1.9 bios has own ps1 routine 

UK_FLAG = VAR_PATCH_FLAGS.4

USA_FLAG = VAR_PATCH_FLAGS.5

JAP_FLAG = VAR_PATCH_FLAGS.6

SCEX_FLAG = VAR_PATCH_FLAGS.7
;set when SCEX_LOW loop for injecting. once cleared knows patching done to flow forward

;------------------------------------------------------------
;VAR_SWITCH
;------------------------------------------------------------
V12_FLAG = VAR_SWITCH.0 ;v12 console 2.0 bios set

V12LOGO_FLAG = VAR_SWITCH.1 ;PS1_MODE v12 2.0 bios console flag ?
;SECOND_BIOS_PATCH_END ref if was doing ps1 patching for 2.0 v12 as redirects flow there for different patch. 

X_FLAG = VAR_SWITCH.2
;set when HOLD_BOOT_MODES only clrb when end ?
;can flow onto ps1 reboot into PS1_MODE if detect ps1 media

;;JAP_V8 = VAR_SWITCH.3 		;;


DEV1_FLAG = VAR_SWITCH.4

;;V14_FLAG = VAR_SWITCH.5		;;
;set due to W for region of BIOS which decka models

;;V0_FLAG = VAR_SWITCH.6		;;


;------------------------------------------------------------
;CODE
;------------------------------------------------------------

;mode setup for io's ;todo
;ref SX-SX-Users-Manual-R3.1.pdf section 5.3.2
                    org           $07FF							; Reset Vector
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
					
;execute correct startup...						
                    snb           pd
                    jmp           CLEAR_CONSOLE_INFO_PREFIND
                    snb           VAR_PSX_BITC.2
                    jmp           TAP_BOOT_MODE
                    snb           IO_EJECT
                    jmp           TRAY_IS_EJECTED
                    snb           VAR_PSX_BITC.1
                    page          $0200
                    jmp           POST_PATCH_4_MODE_START
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
					
;power up from STBY					
CLEAR_CONSOLE_INFO_PREFIND
                    clr           VAR_PATCH_FLAGS
                    clr           VAR_SWITCH
                    jmp           BIOS_GET_SYNC

;--------------------------------------------------------------------------------
DELAY100m
;--------------------------------------------------------------------------------
                    mov           w,#$64
                    mov           VAR_DC1,w
RTCC_SET_BIT          mov           w,#$3d
                    mov           rtcc,w
RTCC_CHECK          mov           w,rtcc
                    sb            z
                    jmp           RTCC_CHECK
                    decsz         VAR_DC1
                    jmp           RTCC_SET_BIT
                    retp          

;--------------------------------------------------------------------------------
SET_INTRPT
;--------------------------------------------------------------------------------
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

;--------------------------------------------------------------------------------
SCEX_HI
;--------------------------------------------------------------------------------
                    setb          IO_SCEX
                    mov           w,#$3b
                    mov           VAR_DC3,w
:loop1
                    mov           w,#$d4
                    mov           VAR_DC2,w
                    not           ra
:loop2
                    mov           w,#$3
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
                    clrb          IO_SCEX
                    mov           w,#$3b
                    mov           VAR_DC3,w
:loop1
                    mov           w,#$d4
                    mov           VAR_DC2,w
                    snb           IO_BIOS_CS
                    jmp           :loop2
                    setb          SCEX_FLAG
:loop2
                    mov           w,#$3
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
                    snb           USA_FLAG
                    jmp           usa
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
                    sb            z
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
;                    nop     ;; extra sx28      
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
;                    nop ;; extra sx28
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
                    mov           w,#$45					;is byte7 ASCII E europe bios
                    mov           w,VAR_BIOS_REGION_TEMP-w			;capture byte7 compare to VAR_BIOS_REGION_TEMP if E
                    snb           z						;if compare dont = 0 (E) skip next line	
                    jmp           BIOS_UK
                    mov           w,#$52					;is byte7 ASCII R ; 'R', uk	; RUS 39008 fix ; russia region which is pal
                    mov           w,VAR_BIOS_REGION_TEMP-w			;capture byte7 compare to VAR_BIOS_REGION_TEMP if R
                    snb           z						;if compare dont = 0 (R) skip next line
                    jmp           BIOS_UK
;                    mov           w,#$49					;is byte7 ASCII I europe bios	;; remove as unneeded, make use of jap fall over		
;                    mov           w,VAR_BIOS_REGION_TEMP-w
;                    snb           z
;                    jmp           BIOS_JAP
                    jmp           BIOS_JAP
BIOS_USA
                    setb          USA_FLAG
                    jmp           RESTDOWN_CHK_PS2MODEorOTHER
BIOS_UK
                    setb          UK_FLAG
                    jmp           RESTDOWN_CHK_PS2MODEorOTHER
BIOS_JAP
                    setb          JAP_FLAG
RESTDOWN_CHK_PS2MODEorOTHER
                    snb           IO_REST
                    jmp           TAP_BOOT_MODE
					
;DVD movie : GREEN fix + MACROVISION off					
CHECK_IF_V9to14
                    setb          PSX_FLAG
                    mov           w,#$37
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
                    mov           w,#$39
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
                    mov           w,#$30
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
                    mov           w,#$32
                    mov           VAR_DC1,w
;V1-8 kernels: sync 1E006334 then 2410 
START_BIOS_PATCH_SYNC_V1toV8
                    snb           IO_BIOS_OE
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
START_BIOS_PATCH_SYNC_V1toV8_L1
                    snb           IO_BIOS_OE
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
START_BIOS_PATCH_SYNC_V1toV8_L2
                    sb            IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V1toV8_L2
BIOS_V1toV8_PATCH1
                    snb           IO_BIOS_OE
                    jmp           BIOS_V1toV8_PATCH1
                    decsz         VAR_DC1
                    jmp           START_BIOS_PATCH_SYNC_V1toV8_L2
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    mov           w,#$1f
                    mov           m,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           !IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
BIOS_V1toV8_IORESET_INPUT
                    sb            IO_BIOS_OE
                    jmp           BIOS_V1toV8_IORESET_INPUT
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    jmp           MODE_SELECT_START
					
; V9/V10/V12 kernels	
;kernel_V910					
;Kstart_l0					
START_BIOS_PATCH_SYNC_V9toV14
                    snb           IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
                    nop           
                    mov           w,#$dc
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
START_BIOS_PATCH_SYNC_V9toV14_L1
                    sb            IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14_L1
START_BIOS_PATCH_SYNC_V9toV14_L2
                    snb           IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14_L2
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
START_BIOS_PATCH_SYNC_V9toV14_L3
                    sb            IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14_L3
START_BIOS_PATCH_SYNC_V9toV14_L4
                    snb           IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14_L4
                    mov           w,#$10
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
START_BIOS_PATCH_SYNC_V9toV14_L5
                    sb            IO_BIOS_OE
                    jmp           START_BIOS_PATCH_SYNC_V9toV14_L5
BIOS_V9toV14_PATCH1
                    snb           IO_BIOS_OE
                    jmp           BIOS_V9toV14_PATCH1
                    mov           w,#$45
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV14
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    mov           w,#$1f
                    mov           m,w
                    mov           w,#$0
                    mov           !IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
					
;**************************************************************************************************
;New mode select for PSX/DEV mode :
;Check RESET for about 4 sec ( 2 =initial delay + 2 from this routine )
;if exit before then enter PSX mode , else wait for reset release and wait again for 
;10 sec. If RESET is pressed again within 10 sec. then enter DEV mode else 
;definitively SLEEP chip for all media that no need patch ( VIDEO , MUSIC , ORIGINALS ).
;**************************************************************************************************			
;TEST_RESET					
MODE_SELECT_START
                    mov           w,#$a
                    mov           VAR_DC2,w
;test_l1					
MODE_SELECT_TIMER_L1
                    call          DELAY100m
                    snb           IO_REST
                    jmp           HOLD_BOOT_MODES
                    decsz         VAR_DC2
                    jmp           MODE_SELECT_TIMER_L1
MODE_SELECT_TIMER_L2
                    sb            IO_REST
                    jmp           MODE_SELECT_TIMER_L2
                    mov           w,#$5
                    mov           VAR_DC2,w
;test_l2					
MODE_SELECT_TIMER_L3
                    call          DELAY100m
                    decsz         VAR_DC2
                    jmp           MODE_SELECT_TIMER_L3
                    mov           w,#$64
                    mov           VAR_DC2,w
;test_l3					
DISABLE_MODE
                    call          DELAY100m
                    sb            IO_REST
                    page          $0600
                    jmp           DEV1_MODE_LOAD_START
                    decsz         VAR_DC2
                    jmp           DISABLE_MODE
                    sleep     
					
;RESET0					
TAP_BOOT_MODE
                    clrb          PSX_FLAG
;RESET_DOWN					
HOLD_BOOT_MODES
                    clr           fsr
                    snb           DEV1_FLAG
                    page          $0600
                    jmp           DEV1_MODE_LOAD_START
                    setb          SOFT_RST
                    clrb          EJ_FLAG
                    setb          X_FLAG
                    clrb          V12LOGO_FLAG
                    page          $0200
                    jmp           PS2_MODE_START
					
;---------------------------------------------------------------------
;PS2 : continue patch after  OSDSYS & wait for disk ready...
;---------------------------------------------------------------------
;PS2_PATCH2					
CHECK_IF_START_PS2LOGO
                    clr           fsr
                    sb            PSX_FLAG
                    page          $0a00
                    jmp           START_PS2LOGO_PATCH_LOAD
					
;CDDVD_EJECTED					
TRAY_IS_EJECTED
                    sb            IO_REST
                    jmp           TAP_BOOT_MODE
                    snb           IO_EJECT
                    jmp           TRAY_IS_EJECTED
					
;wait for bios cs inactive ( fix for  5 bit bus and cd boot )					
;DELAY1s
RESUME_MODE_FROM_EJECT
                    mov           w,#$5
                    mov           VAR_DC2,w
					
;ld_del0					
RESUME_MODE_FROM_EJECT_L1
                    mov           w,#$64
                    mov           VAR_DC1,w
					
;ld_del					
RESUME_MODE_FROM_EJECT_L2
                    mov           w,#$3a
                    mov           rtcc,w
;ld_del1					
RESUME_MODE_FROM_EJECT_L3
                    sb            IO_BIOS_CS
                    jmp           RESUME_MODE_FROM_EJECT
                    sb            IO_REST
                    jmp           TAP_BOOT_MODE
                    snb           IO_EJECT
                    jmp           TRAY_IS_EJECTED
                    mov           w,rtcc
                    sb            z
                    jmp           RESUME_MODE_FROM_EJECT_L3
                    decsz         VAR_DC1
                    jmp           RESUME_MODE_FROM_EJECT_L2
                    decsz         VAR_DC2
                    jmp           RESUME_MODE_FROM_EJECT_L1
                    call          SET_INTRPT
                    clr           fsr
                    snb           DEV1_FLAG
                    page          $0400
                    jmp           START_CDDVD_PATCH
                    mov           w,#$2
                    mov           VAR_DC4,w
                    mov           w,#$32
                    mov           w,VAR_BIOS_YR-w
                    snb           z
                    jmp           CONSOLE_2002_JMP
                    mov           w,#$1
                    mov           VAR_DC4,w
					
;MEPATCH					
CONSOLE_2002_JMP
                    page          $0400
                    jmp           START_CDDVD_PATCH
					
;-------------------------------------------------------------------------
;NEW NEW NEW patch psx game... and some protected too 
;-------------------------------------------------------------------------	
;PSX_PATCH
PS1_MODE_START_PATCH
                    clr           fsr
                    clrb          SCEX_FLAG
                    mov           w,#$ff
                    mov           VAR_PSX_TEMP,w
					
;psx_ptc_l0
RUN_PS1_SCEX_INJECT
                    call          SEND_SCEX
                    snb           SCEX_FLAG
                    jmp           PS1_SCEX_INJECT_COMPLETE
                    decsz         VAR_PSX_TEMP
                    jmp           RUN_PS1_SCEX_INJECT
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
					
;DRVPTC					
PS1_SCEX_INJECT_COMPLETE
                    snb           EJ_FLAG
                    jmp           RUN_PS1_SCEX_INJECT
                    mov           w,#$2
                    mov           VAR_DC4,w
                    mov           w,#$32
                    mov           w,VAR_BIOS_YR-w
                    snb           z
                    jmp           PS1_IS_V14orV1toV12PALorNTSC
                    mov           w,#$1
                    mov           VAR_DC4,w
					
;DRV					
PS1_IS_V14orV1toV12PALorNTSC
                    snb           USA_FLAG
                    page          $0800
                    jmp           PS1_CONSOLE_ALL_JMPNTSC
                    snb           JAP_FLAG
                    page          $0800
                    jmp           PS1_CONSOLE_ALL_JMPNTSC
                    page          $0800
                    jmp           PS1_CONSOLE_PAL_YFIX

                    org           $0200

;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P2
;--------------------------------------------------------------------------------
                    snb           IO_BIOS_OE
                    jmp           BIOS_WAIT_OE_LO_P2
                    ret           

;---------------------------------------------------------
; NEW BIOS PATCH ROUT
;---------------------------------------------------------
;--------------------------------------------------------------------------------
RUN_BIOS_PATCHES_SRAM
;--------------------------------------------------------------------------------
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

;----------------------------------------------------------
;Patch PS2 game...
;----------------------------------------------------------
;--------------------------------------------------------------------------------
BIOS_PATCH_DATA
;--------------------------------------------------------------------------------
                    jmp           pc+w
;V134					
                    retw          $23			;0
                    retw          $80
                    retw          $ac
                    retw          $c
                    retw          $0
                    retw          $0
                    retw          $0
;VX					
                    retw          $24			;7
;;Label_0039
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
                    mov           w,#$3f
                    mov           VAR_DC3,w
                    jmp           BIOS_PATCH_DATA_PART2_ALL
;V9					
                    retw          $24
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
                    mov           w,#$3f
                    mov           VAR_DC3,w
                    jmp           BIOS_PATCH_DATA_PART2_ALL
;V10-12					
                    retw          $24
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
                    mov           w,#$36
                    mov           VAR_DC3,w
                    retw          $a4
                    retw          $ec
                    mov           w,#$3f
                    mov           VAR_DC3,w
                    jmp           BIOS_PATCH_DATA_PART2_ALL
;v12					
V12_CONSOLE_20_BIOS_JMP
                    mov           w,#$3d
                    mov           VAR_DC3,w
                    retw          $c
                    retw          $f9
;LOAD_END					
BIOS_PATCH_DATA_PART2_ALL
                    retw          $91
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
					
;PS2_PATCH					
PS2_MODE_START
;load osdsys data patch for PS2 mode or ps1drv data patch for PSX mode 
                    sb            PSX_FLAG
                    jmp           CHECK_IF_V1_v2or3_V4_V5to8
                    mov           w,#$b
                    mov           VAR_DC1,w
                    mov           w,#$49
                    jmp           ALL_CONTIUNE_BIOS_PATCH
					
;:set_psx2					;;todo v0
CHECK_IF_V1_v2or3_V4_V5to8
;ps2 mode data offset
                    clr           fsr
                    mov           w,#$31
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           V1_CONSOLE_11_BIOS
                    mov           w,#$32
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           V2or3_CONSOLE_12_BIOS
                    mov           w,#$35
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           V4_CONSOLE_15_BIOS
                    jmp           CHECK_V9to14_REV
					
;:set_V1					
V1_CONSOLE_11_BIOS
                    mov           w,#$c0
                    mov           IO_BIOS_DATA,w
                    mov           w,#$b0
                    mov           VAR_DC3,w
                    mov           w,#$74
                    mov           VAR_DC4,w
                    jmp           V1to8_CONTIUNE

;:set_V3					
V2or3_CONSOLE_12_BIOS
                    mov           w,#$d8
                    mov           IO_BIOS_DATA,w
                    mov           w,#$40
                    mov           VAR_DC3,w
                    mov           w,#$7a
                    mov           VAR_DC4,w
                    jmp           V1to8_CONTIUNE

;:set_V4					
V4_CONSOLE_15_BIOS
                    mov           w,#$60
                    mov           VAR_DC3,w
                    mov           w,#$7d
                    mov           VAR_DC4,w
                    mov           w,#$c
                    mov           IO_BIOS_DATA,w

;:set_P					
V1to8_CONTIUNE
                    mov           w,#$7
                    mov           VAR_DC1,w
                    mov           VAR_DC2,w
                    clr           w
                    jmp           ALL_CONTIUNE_BIOS_PATCH

;:set_Vx					
CHECK_V9to14_REV
                    mov           w,#$2
                    mov           IO_BIOS_DATA,w
                    mov           w,#$17
                    mov           VAR_DC1,w
                    mov           VAR_DC2,w
                    mov           w,#$37
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           V9_CONSOLE_17_BIOS
                    mov           w,#$39
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           V9_CONSOLE_19_BIOS
                    mov           w,#$30
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           V12_CONSOLE_20_BIOS
                    mov           w,#$30
                    mov           VAR_DC3,w
                    mov           w,#$7d
                    mov           VAR_DC4,w
                    mov           w,#$7
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V9					
V9_CONSOLE_17_BIOS
                    mov           w,#$4
                    mov           VAR_DC3,w
                    mov           w,#$94
                    mov           VAR_DC4,w
                    mov           w,#$17
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V10					
V9_CONSOLE_19_BIOS
                    setb          V10_FLAG
                    mov           w,#$64
                    mov           VAR_DC3,w
                    mov           w,#$9e
                    mov           VAR_DC4,w
                    mov           w,#$27
                    jmp           ALL_CONTIUNE_BIOS_PATCH
;:set_V12					
V12_CONSOLE_20_BIOS
                    setb          V10_FLAG
                    setb          V12_FLAG
                    mov           w,#$f4
                    mov           VAR_DC3,w
                    mov           w,#$9e
                    mov           VAR_DC4,w
                    mov           w,#$27
;:loopxx					
ALL_CONTIUNE_BIOS_PATCH
                    snb           DEV1_FLAG
                    jmp           SECONDBIOS_PATCH_DEV1_STACK
                    mov           VAR_DC3,w
                    mov           w,#$20
                    mov           fsr,w
;:loop					
LOAD_BIOS_PATCH_DATA
                    mov           w,VAR_DC3
                    call          BIOS_PATCH_DATA
                    mov           indf,w
                    inc           fsr
                    inc           VAR_DC3
                    decsz         VAR_DC1
                    jmp           LOAD_BIOS_PATCH_DATA
                    snb           PSX_FLAG
                    page          $0000
                    jmp           TRAY_IS_EJECTED
					
;:loop0					
; OSDSYS Wait for 60 00 04 08 ... fixed for V10 :)					
SECOND_BIOS_PATCH_SYNC
                    snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC
                    mov           w,#$60
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
SECOND_BIOS_PATCH_SYNC_LOOP1
                    sb            IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP1
SECOND_BIOS_PATCH_SYNC_LOOP2
                    snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP2
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
SECOND_BIOS_PATCH_SYNC_LOOP3
                    sb            IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP3
SECOND_BIOS_PATCH_SYNC_LOOP4
                    snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP4
                    mov           w,#$4
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
SECOND_BIOS_PATCH_SYNC_LOOP5
                    sb            IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP5
SECOND_BIOS_PATCH_SYNC_LOOP6
                    snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP6
                    mov           w,#$8
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
                    mov           w,#$20
                    mov           fsr,w
					
;-----------------------------------------------------------
; Patch data for bios OSDSYS 
;-----------------------------------------------------------
;:loop1
SECOND_BIOS_PATCH_SYNC_P2
                    snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P2
                    mov           w,#$7
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC_P2
SECOND_BIOS_PATCH_SYNC_P3
                    snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P3
                    mov           w,#$3
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC_P3
;:loop66					
SECOND_BIOS_PATCH_SYNC_P4
                    sb            IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P4
SECOND_BIOS_PATCH_SYNC_P4_L1
                    snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P4_L1
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC_P3
SECOND_BIOS_PATCH_SYNC_P4_L2
                    sb            IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P4_L2
                    mov           !IO_BIOS_DATA,w
SECOND_BIOS_PATCH_SYNC_P4_L3
                    snb           IO_BIOS_OE
                    jmp           SECOND_BIOS_PATCH_SYNC_P4_L3
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    snb           DEV1_FLAG
                    page          $0600
                    jmp           POST_PATCH_4_MODE_START_2
                    snb           V12LOGO_FLAG
                    page          $0a00
                    jmp           PS1_MODE_SUCESSFUL_END
                    page          $0000
                    jmp           CHECK_IF_START_PS2LOGO

;SETUPDEV				
SECONDBIOS_PATCH_DEV1_STACK
                    mov           w,#$27
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
                    jmp           SECOND_BIOS_PATCH_SYNC

;----------------------------------------------------------
;XCDVDMAN routine
;---------------------------------------------------------- 
;IS_XCDVDMANX
POST_PATCH_4_MODE_START
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
;IS_XCDVDMAN					
POST_PATCH_4_MODE_START2
                    snb           DEV1_FLAG
                    page          $0600
                    jmp           POST_PATCH_4_MODE_START2_2
                    mov           w,#$64
                    mov           VAR_DC4,w
;IS_XCDVDMAN:loop4
POST_PATCH_4_MODE_START_L1
                    mov           w,#$ff
                    mov           VAR_DC3,w
;IS_XCDVDMAN:loop3				
POST_PATCH_4_MODE_START_L2
                    mov           w,#$ff
                    mov           VAR_DC2,w
;IS_XCDVDMAN:loop2				
POST_PATCH_4_MODE_START_L3
                    mov           w,#$ff
                    mov           VAR_DC1,w
;IS_XCDVDMAN:loopx				
POST_PATCH_4_MODE_START_L4
                    sb            IO_BIOS_CS
                    jmp           POST_PATCH_4_MODE_START_P2
                    decsz         VAR_DC1
                    jmp           POST_PATCH_4_MODE_START_L4
                    decsz         VAR_DC2
                    jmp           POST_PATCH_4_MODE_START_L3
                    decsz         VAR_DC3
                    jmp           POST_PATCH_4_MODE_START_L2
                    decsz         VAR_DC4
                    jmp           POST_PATCH_4_MODE_START_L1
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
;IS_XCDVDMAN:loop0					
POST_PATCH_4_MODE_START_L5
                    snb           IO_BIOS_CS
                    jmp           POST_PATCH_4_MODE_START_L4
;IS_XCDVDMAN:loop1					
POST_PATCH_4_MODE_START_P2
                    mov           w,#$a2
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
                    mov           IO_BIOS_DATA,w
;xcdvdman1_l0a					
POST_PATCH4MODE_START_P2_L1
                    snb           IO_BIOS_OE
                    jmp           POST_PATCH4MODE_START_P2_L1
                    nop           
                    mov           w,#$27
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
                    snb           X_FLAG
                    jmp           POST_PATCH4MODE_END_P2
;xcdvdman1_next					
                    mov           w,#$20
                    mov           fsr,w
;xcdvdman1_l1					
POST_PATCH4MODE_START_P2_L2
                    snb           IO_BIOS_OE
                    jmp           POST_PATCH4MODE_START_P2_L2
;; call bios wait oe worked here seemed					
                    nop           
                    mov           w,#$27
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L2
POST_PATCH4MODE_START_P2_L3
                    sb            IO_BIOS_OE
                    jmp           POST_PATCH4MODE_START_P2_L3
                    mov           !IO_BIOS_DATA,w
POST_PATCH4MODE_END_P1
                    snb           IO_BIOS_OE
                    jmp           POST_PATCH4MODE_END_P1
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    sb            EJ_FLAG
                    page          $0000
                    jmp           TRAY_IS_EJECTED
                    jmp           POST_PATCH_4_MODE_START2
;again
POST_PATCH4MODE_END_P2
                    clrb          X_FLAG
                    jmp           POST_PATCH_4_MODE_START2
;TO SLEEP ... , PERHARPS TO DREAM ...
PS2_MODE_RB_IO_SET_SLEEP
                    mode          $000A
                    mov           w,#$6
                    mov           !IO_CDDVD_BUS,w
                    mode          $0009
                    clr           w
                    mov           !IO_CDDVD_BUS,w
                    mode          $000B
                    snb           PSX_FLAG
                    jmp           PS1_MODE_RB_IO_SET_SLEEP
                    mov           w,#$f1
                    mov           !IO_CDDVD_BUS,w
                    sleep   
					
PS1_MODE_RB_IO_SET_SLEEP
                    mov           w,#$f3
                    mov           !IO_CDDVD_BUS,w
                    sleep         

                    org           $0400						; PAGE4 400-5FF
;; page4 mechacon area
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

;--------------------------------------------------------------------------------
MECHACON_WAIT_OE
;--------------------------------------------------------------------------------
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           MECHACON_WAIT_OE				;;todo weird jump Label_0039
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    decsz         VAR_DC1
                    jmp           MECHACON_WAIT_OE				;;todo weird jump Label_0039
                    ret           

;MEDIA_PATCH					
START_CDDVD_PATCH
                    clr           fsr
                    setb          IO_CDDVD_OE_A_1R
;execute first patch for V12 only ...						
                    mov           w,#$30
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           V9toV14_CONSOLE_CDDVD_START
                    mov           w,#$37
                    mov           w,VAR_BIOS_REV-w
                    snb           c
                    jmp           V9toV14_CONSOLE_CDDVD_START
;V1-V8 version... fix for HDD operations ( bios activity )	
;HDD_FIX
V1toV8_CONSOLE_CDDVD_START
                    mov           w,#$4
                    mov           VAR_DC1,w
;:l0					
V1toV8_AND_BYTE_SYNC1
                    mov           w,#$90
V1toV8_AND_BYTE_SYNC1_L1
                    snb           IO_CDDVD_OE_A_1Q
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
                    mov           w,#$f
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
                    mov           w,#$b0
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    snb           z
                    jmp           V9toV12_CONSOLE_PATCH1_POST
                    mov           w,#$a0
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
                    mov           w,#$1f
V9toV12_AND_BYTE_SYNC2_L2
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           V9toV12_AND_BYTE_SYNC2_L2		;patch 4 bytes
                    clrb          IO_CDDVD_OE_A_1R			;this is byte #1
                    mov           !IO_CDDVD_BUS,w
                    setb          IO_CDDVD_OE_A_1R			;
					
                    mov           w,#$5
                    mov           VAR_DC1,w				;skip 5 bytes , FIX for 15 bytes skip (see above ...)
                    call          MECHACON_WAIT_OE
                    mov           w,#$ff
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
;dvd_l5					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L3
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L3
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
;dvd_l6					
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L4
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L4
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           V9toV12_CONSOLE_PATCH1_POST
;dvd_l7					
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
                    snb           PSX_FLAG
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
;dvd_c1					
                    mov           w,#$90
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
                    snb           USA_FLAG
                    jmp           CDDVD_USA
                    snb           UK_FLAG
                    jmp           CDDVD_UK
                    mov           w,#$10
                    jmp           ALL_CDDVD_PATCH_SET_VAR_DC3
CDDVD_UK
                    mov           w,#$8
                    jmp           ALL_CDDVD_PATCH_SET_VAR_DC3
CDDVD_USA
                    clr           w
ALL_CDDVD_PATCH_SET_VAR_DC3
                    mov           VAR_DC2,w					; save offset...
                    mov           w,#$8						;region patch : # of bytes to patch
                    mov           VAR_DC3,w
                    mov           w,#$ff
                    mov           IO_CDDVD_BUS,w				;!!!!!!!!!!!!!	critical
;WAIT_DISK
;wait_dvd_lx
ALL_CDDVD_PATCH_SYNC2_BIT
                    mov           w,#$3
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
;wait_dvd_l0					
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
                    mov           w,#$1f
                    mov           m,w
                    mov           w,#$f
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
                    mov           w,#$ff
CDDVD_PATCH_POST_RB_INPUT
                    snb           IO_CDDVD_OE_A_1Q
                    jmp           CDDVD_PATCH_POST_RB_INPUT
                    mov           !IO_CDDVD_BUS,w
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           SOFT_RST
                    jmp           V9toV12_CONSOLE_PATCH1_POST
;exit_patch					
CDDVD_IS_PS1
                    clrb          IO_CDDVD_OE_A_1R
                    clrb          SOFT_RST
                    snb           EJ_FLAG
                    page          $0200
                    jmp           POST_PATCH_4_MODE_START2
                    page          $0a00
                    jmp           PS1_DETECTED_REBOOT

                    org           $0600
;; page 6 DEV1 COMPLETELY DIFFERENT
;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P6
;--------------------------------------------------------------------------------
                    snb           IO_BIOS_OE
                    jmp           BIOS_WAIT_OE_LO_P6
                    ret           

;--------------------------------------------------------------------------------
BIOS_PATCH_DEV1		;;h2o dev1 ported
;--------------------------------------------------------------------------------
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
                    clrb          PSX_FLAG
                    setb          SOFT_RST
                    setb          EJ_FLAG
                    setb          DEV1_FLAG
                    mov           w,#$73
                    mov           VAR_DC1,w
                    clr           w
                    mov           VAR_DC3,w
;;PS2LOGO_PATCH_19_20_JMP2				;; is error for where in ps2 bios load v10 jmp ??
                    mov           w,#$20
                    mov           fsr,w
DEV1_MODE_LOAD_LOOP
                    mov           w,VAR_DC3
                    call          BIOS_PATCH_DEV1
                    mov           indf,w
                    inc           fsr
                    inc           VAR_DC3
                    decsz         VAR_DC1
;;Label_0198			;;  error
                    jmp           DEV1_MODE_LOAD_LOOP
                    page          $0200
                    jmp           CHECK_IF_V1_v2or3_V4_V5to8

;----------------------------------------------------------
;XCDVDMAN routine 2 ??? ps1 XCDVDMAN ??
;---------------------------------------------------------- ;;todo
					
POST_PATCH_4_MODE_START_2
                    page          $0000
                    call          SET_INTRPT
POST_PATCH_4_MODE_START2_2
                    mov           w,#$64
                    mov           VAR_DC4,w
POST_PATCH_4_MODE_START_L1_2
                    mov           w,#$ff
                    mov           VAR_DC3,w
POST_PATCH_4_MODE_START_L2_2
                    mov           w,#$ff
                    mov           VAR_DC2,w
POST_PATCH_4_MODE_START_L3_2
                    mov           w,#$ff
                    mov           VAR_DC1,w
POST_PATCH_4_MODE_START_L4_2
                    sb            IO_BIOS_CS
                    jmp           POST_PATCH_4_MODE_START_P2_2
                    decsz         VAR_DC1
                    jmp           POST_PATCH_4_MODE_START_L4_2
                    decsz         VAR_DC2
                    jmp           POST_PATCH_4_MODE_START_L3_2
                    decsz         VAR_DC3
                    jmp           POST_PATCH_4_MODE_START_L2_2
                    decsz         VAR_DC4
                    jmp           POST_PATCH_4_MODE_START_L1_2
                    page          $0200
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
					
;--------------------------------------------------			;;todo
POST_PATCH_4_MODE_START_L5_2
                    snb           IO_BIOS_CS
                    jmp           POST_PATCH_4_MODE_START_L4_2
POST_PATCH_4_MODE_START_P2_2
                    mov           w,#$43
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH_4_MODE_START_L5_2
                    call          BIOS_WAIT_OE_LO_P6
                    mov           w,#$14
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH_4_MODE_START_L5_2
                    call          BIOS_WAIT_OE_LO_P6
                    mov           w,#$74
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH_4_MODE_START_L5_2
Label_0184
                    snb           IO_BIOS_OE
                    jmp           Label_0184
                    mov           w,#$d0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           Label_0184
Label_0185
                    sb            IO_BIOS_OE
                    jmp           Label_0185
Label_0186
                    snb           IO_BIOS_OE
                    jmp           Label_0186
                    mov           w,#$ff
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           Label_0184
Label_0187
                    sb            IO_BIOS_OE
                    jmp           Label_0187
Label_0188
                    snb           IO_BIOS_OE
                    jmp           Label_0188
PS1_DETECTED_REBOOT_JMP11to17_ALL			;; check PS1_DETECTED_REBOOT_JMP11to17_ALL
                    mov           w,#$42
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           Label_0184
                    mov           w,#$34
                    mov           IO_BIOS_DATA,w
                    mov           w,#$0
                    mov           !IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P6
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    jmp           POST_PATCH_4_MODE_START2_2

                    org           $0800
;; page8 ps1drv page4 sx28
;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P8
;--------------------------------------------------------------------------------
                    snb           IO_BIOS_OE
                    jmp           BIOS_WAIT_OE_LO_P8
                    ret   
					
;psx1 driver patch ...
;PSX1DRV
PS1_CONSOLE_PAL_YFIX
;V7DRV
                    mov           w,#$3c
                    mov           IO_BIOS_DATA,w
                    mov           w,#$20
                    mov           fsr,w
                    mov           w,#$b
                    mov           VAR_DC2,w
;10 01 00 43 30	
;psx1drv_l0
PS1_CONSOLE_PAL_YFIX_SYNC
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
                    mov           w,#$11
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$11
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC					;; weird jmp Label_0189
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC					;; weird jmp Label_0189
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$9
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC					;; weird jmp Label_0189
;psx1drv_l0a					
PS1_CONSOLE_PAL_YFIX_SYNC_L1		;; added fix			
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L1				;; weird jmp Label_0190					
                    nop           
                    mov           w,#$30				; 3C C7 34 19 19 E2 B2 19 E2 BA
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L1				;; weird jmp Label_0190	
PS1_CONSOLE_PAL_YFIX_SYNC_L2		;; added fix			
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L2				;; here weird jmp Label_0191 ;; error
                    mov           !IO_BIOS_DATA,w
PS1_CONSOLE_PAL_YFIX_SYNC_L3		;; added fix		
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L3				;; weird jmp Label_0192
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    clr           fsr
                    decsz         VAR_DC4
                    jmp           PS1_CONSOLE_PAL_YFIX			;; different jmp BIOS_PATCH_DEV1 , error
;LOGO					
PS1_CONSOLE_ALL_JMPNTSC
                    clr           fsr
                    mov           w,#$34
                    mov           VAR_DC1,w
                    mov           w,#$18
                    mov           VAR_DC3,w
                    mov           VAR_DC4,w
;logo_l1									;match FDFF8514
PS1_CONSOLE_ALL_JMPNTSC_SYNC
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC
                    mov           w,#$fd
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L1
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L1
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L2
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L2
                    mov           w,#$ff
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L3
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L3
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L4
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L4
                    mov           w,#$85
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L5
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L5
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L6
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L6
                    mov           w,#$14
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC
;logo_skip					
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L7
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L7
PS1_CONSOLE_ALL_JMPNTSC_SYNC_L8
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L8
                    decsz         VAR_DC1
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC_L7
                    mov           w,#$3
                    mov           IO_BIOS_DATA,w
PS1_CONSOLE_ALL_JMPNTSC_PATCH1
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_PATCH1
                    mov           w,#$0
                    mov           !IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$80
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$4
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$3c
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
;logo_skip2					
PS1_CONSOLE_ALL_JMPNTSC_SYNC2	;; added fix					
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC2		;;todo  weird jmp Label_0194
PS1_CONSOLE_ALL_JMPNTSC_SYNC2_L1	;; added fix
                    snb           IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC2_L1		;;todo weird jmp Label_0195
                    decsz         VAR_DC3
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC2		;;todo weird jmp Label_0194
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
PS1_CONSOLE_ALL_JMPNTSC_PATCH2	;; added fix					
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_PATCH2		;;todo weird jmp Label_0196
                    mov           w,#$0
                    mov           !IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
;logo_skip3					
PS1_CONSOLE_ALL_JMPNTSC_SYNC3	;; added fix
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC3		;; weird jmp PS2LOGO_PATCH_19_20_JMP2 ;; error 
PS1_CONSOLE_ALL_JMPNTSC_SYNC3_L1	;; added fix			
                    snb           IO_BIOS_OE	
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC3_L1				;; weird jmp DEV1_MODE_LOAD_LOOP ;; error 
                    decsz         VAR_DC4
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC3		;; weird jmp PS2LOGO_PATCH_19_20_JMP2 ;;  error 
                    mov           w,#$88
                    mov           IO_BIOS_DATA,w
PS1_CONSOLE_ALL_JMPNTSC_SYNC3_L2		;; added fix					
                    sb            IO_BIOS_OE
                    jmp           PS1_CONSOLE_ALL_JMPNTSC_SYNC3_L2			;; weird jmp Label_0198 ;;  error 
                    mov           w,#$0
                    mov           !IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$2
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$80
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$a4
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P8
                    mov           w,#$ff
                    mov           !IO_BIOS_DATA,w
                    clr           fsr		;; extra than sx28
                    setb          EJ_FLAG
                    page          $0000
                    jmp           PS1_MODE_START_PATCH

                    org           $0A00
					;; page A ps2logo ?? page4 sx28
					;; weird broken oe wait not even called. wait needed for flow ??
;--------------------------------------------------------------------------------					
BIOS_WAIT_OE_LO_PA	
;--------------------------------------------------------------------------------				
                    snb           IO_BIOS_OE
                    jmp           BIOS_WAIT_OE_LO_PA
                    ret           

;--------------------------------------------------------------------------------
PS2LOGO_PATCH
;--------------------------------------------------------------------------------
                    jmp           pc+w
;LOAD_XMAN					
                    retw          $0		; 0
                    retw          $e0
                    retw          $3
                    retw          $0
                    retw          $0
                    retw          $0
                    retw          $0
;v12
                    retw          $8
                    retw          $11
                    retw          $3c
                    retw          $c1
                    retw          $0
                    retw          $31
                    retw          $36
                    retw          $18
                    retw          $16
                    retw          $91
                    retw          $ac
                    retw          $c
                    retw          $0
                    retw          $0
                    retw          $0
;LOGO2					
                    retw          $0
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
                    mov           w,#$49
                    mov           VAR_DC3,w
                    snb           V10_FLAG
                    jmp           PS2LOGO_PATCH_11_17_JMP1
                    mov           w,#$44
                    mov           VAR_DC3,w
                    retw          $d0
                    retw          $80
                    mov           w,#$4b
                    mov           VAR_DC3,w
                    jmp           PS2LOGO_PATCH_19_20_JMP1		;; error  NOTBUG_JMP1	; edit from bugged jmp middle of dev1, gone now due to h2o dev1 ported		  
;; h2o diff
;LOADV10A					
PS2LOGO_PATCH_11_17_JMP1
                    retw          $50
                    retw          $81
;LOADL1	;;	
PS2LOGO_PATCH_19_20_JMP1				
                    retw          $80
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
                    mov           w,#$7f
                    mov           VAR_DC3,w
                    snb           V10_FLAG
                    jmp           PS2LOGO_PATCH_19_20_JMP2		;;	
                    mov           w,#$6b
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
PS2LOGO_PATCH_19_20_JMP2		
                    retw          $af
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
;;					
                    retw          $af
                    retw          $5
                    retw          $4
                    retw          $8
;;V14DRV
					
;XMAN					
START_PS2LOGO_PATCH_LOAD
                    mov           w,#$72
                    mov           VAR_DC1,w
                    mov           VAR_DC2,w
                    clr           w
                    mov           VAR_DC3,w
                    mov           w,#$20
                    mov           fsr,w
					
;;PS2_PS2LOGO					
;;PS2_PS2LOGO:loopa						
					
;PS2_PS2LOGO:loop
PS2LOGO_PATCHLOAD_LOOP
                    mov           w,VAR_DC3
                    call          PS2LOGO_PATCH
                    mov           indf,w
                    inc           fsr
                    inc           VAR_DC3
                    decsz         VAR_DC1
                    jmp           PS2LOGO_PATCHLOAD_LOOP
                    clr           fsr
                    snb           X_FLAG
                    page          $0200
                    jmp           POST_PATCH_4_MODE_START2
;PS2_PS2LOGO:loopz		
PS1_DETECTED_REBOOT			;;
                    clr           fsr
                    mov           w,#$6b
                    mov           VAR_DC2,w
                    mov           w,#$8
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,#$e0
                    mov           VAR_PSX_TEMP,w
                    mov           w,#$9d
                    mov           VAR_PSX_BITC,w
                    mov           w,#$40
                    mov           IO_BIOS_DATA,w
                    snb           V12_FLAG
                    jmp           PS1_MODE_START
;load regs with v10 sync					
                    mov           w,#$af
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,#$6
                    mov           VAR_PSX_TEMP,w
                    mov           w,#$8
                    mov           VAR_PSX_BITC,w
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    snb           V10_FLAG
                    jmp           PS1_DETECTED_REBOOT_JMP11to17_JMP2					;; originally Label_0183 two different call in sx48 vs sx28
;load regs with v1-v9 sync					
                    mov           w,#$1e
                    mov           VAR_PSX_TEMP,w
PS1_DETECTED_REBOOT_JMP11to17_JMP2	;;
                    mov           w,#$57
                    mov           VAR_DC2,w
                    mov           w,#$50
                    mov           VAR_PSX_BYTE,w
PS1_DETECTED_REBOOT_L1
                    mov           w,#$ff
                    mov           VAR_DC3,w
PS1_DETECTED_REBOOT_L2
                    mov           w,#$ff
                    mov           VAR_DC1,w
AUTO_REBOOT_PS1MODE
                    sb            IO_BIOS_CS
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
                    jmp           CHECK_IF_V9to14
PS1_MODE_START
                    snb           IO_BIOS_CS
                    jmp           AUTO_REBOOT_PS1MODE
PSX_MODE_START_P2
                    mov           w,VAR_PSX_BC_CDDVD_TEMP
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_START
PS1_MODE_L1
                    sb            IO_BIOS_OE
                    jmp           PS1_MODE_L1
PS1_MODE_L2
                    snb           IO_BIOS_OE
                    jmp           PS1_MODE_L2
                    mov           w,VAR_PSX_TEMP
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_START
PS1_MODE_L3
                    sb            IO_BIOS_OE
                    jmp           PS1_MODE_L3
PS1_MODE_L4
                    snb           IO_BIOS_OE
                    jmp           PS1_MODE_L4
                    mov           w,VAR_PSX_BITC
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_START
                    snb           V12_FLAG
                    jmp           PS1_MODE_v12_PATCHS
                    mov           w,#$37
                    mov           fsr,w
PS1_MODE_L5
                    snb           IO_BIOS_OE
                    jmp           PS1_MODE_L5
                    nop           
                    mov           w,#$c
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_L5
PS1_MODE_L6
                    sb            IO_BIOS_OE
                    jmp           PS1_MODE_L6
                    mov           !IO_BIOS_DATA,w
;PS2_PS2LOGO:loop1					
PS1_MODE_L7
                    snb           IO_BIOS_OE
                    jmp           PS1_MODE_L7
                    page          $0200
                    call          RUN_BIOS_PATCHES_SRAM
                    decsz         VAR_DC4
                    jmp           PS1_DETECTED_REBOOT_JMP11to17_ALL			;; check PS1_DETECTED_REBOOT_JMP11to17_ALL . think right
;PS2_PS2LOGO:back					
PS1_MODE_SUCESSFUL_END
                    setb          EJ_FLAG
                    page          $0200
                    jmp           POST_PATCH_4_MODE_START2
;V12 logo sync					
PS1_MODE_v12_PATCHS
                    mov           w,#$27
                    mov           fsr,w
                    setb          V12LOGO_FLAG
                    page          $0200
                    jmp           SECOND_BIOS_PATCH_SYNC_P2
                    end
