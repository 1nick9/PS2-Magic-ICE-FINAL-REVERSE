;********************************************************************************
;				Final-fix ICE SX28 reverse
;********************************************************************************
                   device        SX28,TURBO,PROTECT,BOROFF,BANKS8,OSCHS2,OPTIONX
                    ID                    'ICEREV'


;DEFINE
;RSTBUMP			EQU 1			; uncomment for compiling with restbump for ps1mode. else is compiled as f=tr

;io pin assignments
IO_SCEX				=		ra.2 ; (PSX:SCEx)RA2(S)
IO_BIOS_OE			=		ra.0 ; (R)
IO_BIOS_CS			=		rb.1 ; (W)					; LOW = BIOS select
IO_REST				=		rb.2 ; 						; HIGH = 1 NOT PRESSED LOW = 0 = rest down = pressed
IO_EJECT			=		rb.3 ; (PS2:EJECT)RB3(Z) 			; LOW = CD IN, HI = CD OUT
IO_CDDVD_OE_A_1Q		=		ra.1 ; (CDDVD:OE)RA1(A) (flipflop 1Q#) 
IO_CDDVD_OE_A_1R		=		ra.3 ; (CDDVD:OE)RA3(A) (flipflop 1R#)
IO_CDDVD_BUS_i			=		rb.7 ; (I)(CDDVD:D7)
IO_CDDVD_BUS_b			=		rb.4 ; (B)(CDDVD:D2)
IO_CDDVD_BUS			=		rb   ; $06
IO_BIOS_DATA			=		rc   ; $07 ; (V)RC0(BIOS:D0) - (M)RC7(BIOS:D7)

;reg known
VAR_DC1				equ		$08 ; DS 1 ; delay counter 1(small)
VAR_DC2				equ		$09 ; DS 1 ; delay counter 2(small)
VAR_DC3				equ		$0A ; DS 1 ; delay counter 3(big)
VAR_TOFFSET			equ		$0b ; DS 1 ; table offset
VAR_PSX_TEMP			equ		$0C ; DS 1 ; SEND_SCEX:  rename later
VAR_PSX_BC_CDDVD_TEMP			equ		$14 ; DS 1 ; SEND_SCEX:  byte counter  note start at 4(works down to 0) ; also used with mechacon patches and ps1 detect
VAR_PSX_BYTE			equ		$0D ; DS 1 ; SEND_SCEX:  byte(to send)
VAR_PSX_BITC			equ		$13 ; DS 1 ; SEND_SCEX:  bit counter ;note start at 8(works down to 0)
VAR_BIOS_REV			equ		$10 ; DS 1 ; 1.X0 THE BIOS REVISION byte infront in BIOS string is X.00
VAR_BIOS_YR			equ		$11 ; DS 1 ; byteC of ;BIOS_VERSION_MATCHING
VAR_BIOS_REGION_TEMP		equ		$12 ; DS 1 ; temp storage to compare byte7 of ;BIOS_VERSION_MATCHING
VAR_SWITCH			equ		$0F ; DS 1 ; ? 0.94 comment ; bit 0=xcddvdman mode + PSX1 region switch, 1=PSX1/PSX2 wakeup mode, 2=PSX1 PAL/NTSC , 3=PSX2 logo patch , 4=DEV1 
VAR_PATCH_FLAGS			equ		$0E ; DS 1 ; appears to be bits set for running patch routines .0-.7 for setb an offset


;------------------------------------------------------------

;ps1 related = VAR_PATCH_FLAGS.0	; related to ps1 and dev1, process mode reboot flag??

;?????? = VAR_PATCH_FLAGS.1			; related to dev1

;MODE_START_END_REF = VAR_PATCH_FLAGS.2		
;seems to be ref for mode started and mode end, cleared when finished mode run or on reset if mode was incomplete finish not checking
;clrb on PS1_BOOT_MODE to set for flow PS1_MODE ?

;V9_V12_CONSOLE_19_20_BIOS = VAR_PATCH_FLAGS.3		;3=1 ; also seems to be for ps1

;BIOS_UK = VAR_PATCH_FLAGS.4

;BIOS_USA = VAR_PATCH_FLAGS.5

;BIOS_JAP = VAR_PATCH_FLAGS.6

;ps1 related = VAR_PATCH_FLAGS.7		; is ps1 related for sure, if ran sucessfully???

;------------------------------------------------------------
;VAR_SWITCH.0 = v12 console 2.0 bios set

;VAR_SWITCH.1 = PS1_MODE ref
;SECOND_BIOS_PATCH_END set start. 
;clrb when TAP_BOOT_MODE (PS2 MODE default run with CDDVD_IS_PS1 check then sticks if reboot no TAP_BOOT_MODE tap due to reboot holds IO_REST for PS1_MODE)
;ref when end 1=PS1_MODE_SUCESSFUL_END 0=CHECK_IF_START_PS2LOGO

;VAR_SWITCH.2 = not used

;VAR_SWITCH.3 = PS2_MODE ref set when TAP_BOOT_MODE only clrb when end
;can flow onto ps1 reboot into PS1_MODE if detect ps1 media

;VAR_SWITCH.4 = DEV1 FLAG set
;-------------------------------------------------------------

;mode setup for io's ;todo
;ref SX-SX-Users-Manual-R3.1.pdf section 5.3.2
                    org           $07FF							; Reset Vector
                    reset         STARTUP						; jmp to startup process on reset vector skipping boot inital

                    org           $0000							; PAGE1 000-1FF
					
;BOOT INITIALISE ALL IO AS INPUTS
                    mode          $000F							;XFh mode direction for RA, RB, RC output
                    mov           w,#$ff						;set w = #$ff = 1111 1111 ;all pins Hi-Z inputs
                    mov           !IO_BIOS_DATA,w				;above set for IO_BIOS_DATA ; rc
                    mov           w,#$ff						;set w = #$ff = 1111 1111 ;all pins Hi-Z inputs
                    mov           !IO_CDDVD_BUS,w				;above set for IO_CDDVD_BUS ;rb
                    mov           w,#$ff						;set w = #$ff = 1111 1111 ;all pins Hi-Z inputs
                    mov           !ra,w							;above set for ra
					
;BOOT INITIALISE IO_BIOS_DATA IO WAKEUP TYPES					
                    mode          $000A							;rb WKED_B: Wakeup Edge Register (MODE=XAh) sense rising, low-to-high. 
																;Set the bit to 1 to sense falling (high-to-low) edges. The bit is set to 1 after all resets.
                    mov           w,#$8							;set w = #$8 = 0000 1000
                    mov           !IO_CDDVD_BUS,w				;rb.3 IO_EJECT set high-to-low sense
                    mode          $0009							;rb WKPND_B: Wakeup Pending Flag Register (MODE=X9h) 0 indicates that no valid edge has occurred on the MIWU pin ?
                    clr           w								;set w = 0
                    mov           !IO_CDDVD_BUS,w				;all rb IO_CDDVD_BUS
                    mode          $000B							;rb WKEN_B: Wakeup Enable Register (MODE=XBh) Clear the bit to 0 to enable MIWU operation or set the bit to 1 to disable, MIWU operation. see Section 4.4. ?
                    mov           w,#$f3						;set w = #$f3 = 1111 0011
                    mov           !IO_CDDVD_BUS,w				;set rb.2 IO_REST rb.3 IO_EJECT to enable MIWU operation 
                    mode          $000F							;XFh mode direction for RA, RB, RC output
                    sleep
					
					;todo
STARTUP          mode          $000D							;XDh mode direction for LVL_A, LVL_B, LVL_C
                    mov           w,#$f7						;set w = #$f7 = 1111 0111
                    mov           !IO_CDDVD_BUS,w				; ?
                    mode          $000F							;XFh mode direction for RA, RB, RC output
                    mov           w,#$7							;set w = #$7 = 0000 0111
                    mov           !ra,w							;set ra.0 IO_BIOS_OE ra.1 IO_CDDVD_OE_A_1Q ra.2 IO_SCEX as inputs
                    mov           w,#$ff						;set w = #$ff = 1111 1111 ;all pins Hi-Z inputs
                    mov           !IO_CDDVD_BUS,w				;set rb IO_CDDVD_BUS as inputs
                    mov           w,#$ff						;set w = #$ff = 1111 1111 ;all pins Hi-Z inputs
                    mov           !IO_BIOS_DATA,w				;set rc IO_BIOS_DATA as inputs
                    mov           w,#$c7						;set w = #$c7 = 1100 0111
                    mov           !option,w						; ?
                    clr           fsr
                    mode          $0009							;!rb=Exchange WKPND_B
                    clr           w								;w = 0
                    mov           !IO_CDDVD_BUS,w				;set IO_CDDVD_BUS Each bit indicates the status of the corresponding MIWU pin. ?
																;A bit set to 0 indicates that no valid edge has occurred on the MIWU pin.
																;The WKPND_B register comes up with undefine value upon reset
                    mov           VAR_PSX_BITC,w
                    mode          $000F							;XFh mode direction for RA, RB, RC output
																; appears part of boot if boot is from ps1 auto detect due to VAR_PSX_BITC.2 VAR_PSX_BITC.1 checks
                    snb           pd							; ? if pd is true jmp CLEAR_CONSOLE_INFO_PREFIND
                    jmp           CLEAR_CONSOLE_INFO_PREFIND
                    snb           VAR_PSX_BITC.2				; jmp PS1_BOOT_MODE if VAR_PSX_BITC.2 = 1
                    jmp           PS1_BOOT_MODE
                    snb           IO_EJECT						; jmp TRAY_IS_EJECTED if IO_EJECT = 1 not HI ; CD out
                    jmp           TRAY_IS_EJECTED
                    snb           VAR_PSX_BITC.1				; jmp POST_PATCH_4_MODE_START if VAR_PSX_BITC.1 = 1
                    page          $0200							; PAGE2 jmp POST_PATCH_4_MODE_START
                    jmp           POST_PATCH_4_MODE_START
                    page          $0200							; PAGE2 jmp PS2_MODE_RB_IO_SET_SLEEP
                    jmp           PS2_MODE_RB_IO_SET_SLEEP					; jmp PS2_MODE_RB_IO_SET_SLEEP if VAR_PSX_BITC.1 = 0
CLEAR_CONSOLE_INFO_PREFIND          clr           VAR_PATCH_FLAGS				; clear any set VAR_PATCH_FLAGS
                    clr           VAR_SWITCH					; clear any set VAR_SWITCH
                    jmp           BIOS_GET_SYNC					; jmp to BIOS_GET_SYNC to start setting VAR_BIOS_REV, VAR_BIOS_YR, VAR_PATCH_FLAGS

;--------------------------------------------------------------------------------
MODE_SELECT_TIMER		;todo ; seems boot timer setting for decsz related to rtcc set
;--------------------------------------------------------------------------------
                    mov           w,#$64			;w = #$64 = 100 
                    mov           VAR_DC1,w			;set VAR_DC1 = #$64 =100 
RTCC_SET_BIT          mov           w,#$3d			;w = #$3d = 61
                    mov           rtcc,w			;rtcc = w
RTCC_CHECK          mov           w,rtcc			;compare rtcc 
                    sb            z					;skip next bit if rtcc = 0
                    jmp           RTCC_CHECK		;loop w=rtcc till equal then will skip
                    decsz         VAR_DC1			;VAR_DC1 = 100 count then skip next bit ; IS TIME PRESSED FOR MODES
                    jmp           RTCC_SET_BIT
                    retp          					;Return from call,Same as RET but the return address bits 11, 10 & 9 (on the stack) are written to the page-select bits PA2, PA1 & PA0 in the STATUS register. 
													;Thus the page-select bits are properly set to the page being returned to.

;--------------------------------------------------------------------------------
SET_RB_IO_BUS ;todo
;--------------------------------------------------------------------------------
                    mode          $000A							; rb WKED_B: Wakeup Edge Register (MODE=XAh) sense rising, low-to-high
                    mov           w,#$6							; 0000 0110
                    mov           !IO_CDDVD_BUS,w				; rb.1 IO_BIOS_CS rb.2 IO_REST high-to-low sense
                    mode          $0009							; rb WKPND_B: Wakeup Pending Flag Register (MODE=X9h) 0 indicates that no valid edge has occurred on the MIWU pin
                    clr           w								; 0000 0000
                    mov           !IO_CDDVD_BUS,w				; A bit set to 1 indicates that a valid edge has occurred on the corresponding MIWU pin, triggering a wakeup or interrupt. A bit
																; set to 0 indicates that no valid edge has occurred on the MIWU pin. 
																; The WKPND_B register comes up with undefine value upon reset.
                    mode          $000B							; rb WKEN_B: Wakeup Enable Register (MODE=XBh) Clear the bit to 0 to enable MIWU operation or set the bit to 1 to disable, MIWU operation. see Section 4.4.
                    mov           w,#$f3						; 1111 0011
                    mov           !IO_CDDVD_BUS,w				; rb.2 IO_REST rb.3 IO_EJECT enabled
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
                    setb          VAR_PATCH_FLAGS.7
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
                    snb           VAR_PATCH_FLAGS.5
                    jmp           usa
                    snb           VAR_PATCH_FLAGS.4
                    jmp           uk
                    jmp           jap
usa          clr           VAR_TOFFSET					; clear VAR_TOFFSET so runs at byte 0 scea
                    jmp           send_byte
uk          mov           w,#$8
                    mov           VAR_TOFFSET,w			; jump 8 bytes of SCEx_DATA to scee
                    jmp           send_byte
jap          mov           w,#$4		
                    mov           VAR_TOFFSET,w			; jump 4 bytes of SCEx_DATA to scei
send_byte          mov           w,#$b
                    mov           !ra,w					; output:SCEX, input:all others
                    mov           w,#$4
                    mov           VAR_PSX_BC_CDDVD_TEMP,w			; 4 bytes to send
next_byte          mov           w,VAR_TOFFSET
                    call          SCEx_DATA
                    mov           VAR_PSX_BYTE,w
                    not           VAR_PSX_BYTE
                    mov           w,#$8
                    mov           VAR_PSX_BITC,w		; 8 bits in a byte
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
                    clrb          IO_SCEX			; SCEX LOW
                    mov           w,#$16
                    mov           VAR_TOFFSET,w
send_end          call          SCEX_LOW
                    decsz         VAR_TOFFSET
                    jmp           send_end
                    mov           w,#$f				; input:all
                    mov           !ra,w
                    ret           

;--------------------------------------------------------------------------------
;BIOS_VERSION_MATCHING							;todo sx48 is
;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
					snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
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
CAPTURE_BIOS_REV          sb            IO_BIOS_OE				; next byte / wait for bios OE high ; skipping byte4 ; v14 and v0 support need this captured for x.00 of bios and extra compare 1 or 2 routine with current
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
BIOS_USA          setb          VAR_PATCH_FLAGS.5
                    jmp           RESTDOWN_CHK_PS2MODEorOTHER
BIOS_UK          setb          VAR_PATCH_FLAGS.4
                    jmp           RESTDOWN_CHK_PS2MODEorOTHER
BIOS_JAP          setb          VAR_PATCH_FLAGS.6

RESTDOWN_CHK_PS2MODEorOTHER          snb           IO_REST						; skip jmp PS1_BOOT_MODE if IO_REST = 1 HIGH
                    jmp           PS1_BOOT_MODE									; jmp PS1_BOOT_MODE if reset is not held/pressed
					
					;bios rev check for flagging patch route for mode
CHECK_IF_V9to12          setb          VAR_PATCH_FLAGS.2			; VAR_PATCH_FLAGS.2 set here related to start mode Version of BIOS compare ?
                    mov           w,#$30					; ASCII 0 	v12 ; v14 v0 support needed check after byte4 1 or 2 compare
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 0
                    snb           z
                    jmp           START_BIOS_PATCH_SYNC_V9toV12
                    mov           w,#$37					; ASCII 7	50k v9-11
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 7
                    snb           z
                    jmp           START_BIOS_PATCH_SYNC_V9toV12
                    mov           w,#$39					; ASCII 9	50k v9-11
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 9
                    snb           z
                    jmp           START_BIOS_PATCH_SYNC_V9toV12
                    mov           w,#$32
                    mov           VAR_DC1,w									; no match is assumed v1-v8
START_BIOS_PATCH_SYNC_V1toV8          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           START_BIOS_PATCH_SYNC_V1toV8
                    nop           
                    mov           w,#$1e
                    mov           w,IO_BIOS_DATA-w			; is byte = #$1e	
                    sb            z							; skip jump START_BIOS_PATCH_SYNC_V1toV8 if = #$1e
                    jmp           START_BIOS_PATCH_SYNC_V1toV8
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w			; is byte = #$0
                    sb            z							; skip jump START_BIOS_PATCH_SYNC_V1toV8 if = #$0
                    jmp           START_BIOS_PATCH_SYNC_V1toV8
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$63
                    mov           w,IO_BIOS_DATA-w			; is byte = #$63
                    sb            z							; skip jump START_BIOS_PATCH_SYNC_V1toV8 if = #$63
                    jmp           START_BIOS_PATCH_SYNC_V1toV8
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$34
                    mov           w,IO_BIOS_DATA-w			; is byte = #$34
                    sb            z							; skip jump START_BIOS_PATCH_SYNC_V1toV8 if = #$34
                    jmp           START_BIOS_PATCH_SYNC_V1toV8
BIOS_PATCH_SYNC_V1toV8_LOOP1          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_PATCH_SYNC_V1toV8_LOOP1
                    nop           
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w			; is byte = #$24
                    sb            z							; skip jump BIOS_PATCH_SYNC_V1toV8_LOOP1 if = #$24
                    jmp           BIOS_PATCH_SYNC_V1toV8_LOOP1
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$10
                    mov           w,IO_BIOS_DATA-w			; is byte = #$10
                    sb            z							; skip jump BIOS_PATCH_SYNC_V1toV8_LOOP1 if = #$10
                    jmp           BIOS_PATCH_SYNC_V1toV8_LOOP1
BIOS_PATCH_SYNC_V1toV8_LOOP2          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           BIOS_PATCH_SYNC_V1toV8_LOOP2
BIOS_PATCH_SYNC_V1toV8_LOOP3          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_PATCH_SYNC_V1toV8_LOOP3
                    decsz         VAR_DC1					;skip if VAR_DC1 = 0
                    jmp           BIOS_PATCH_SYNC_V1toV8_LOOP2
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w			; make IO_BIOS_DATA = #$0
                    mode          $000F						; XFh mode direction for RA, RB, RC output 
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$0						; 0000 0000
                    mov           !IO_BIOS_DATA,w			; IO_BIOS_DATA all pins output start patching here once sync
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w			; patching 0 to bios
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$0						; patching 0 to bios
                    mov           IO_BIOS_DATA,w
BIOS_PATCH_SYNC_V1toV8_LOOP4          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           BIOS_PATCH_SYNC_V1toV8_LOOP4
                    mov           w,#$ff					; 1111 1111 
                    mov           !IO_BIOS_DATA,w			;IO_BIOS_DATA all set input, patching end
                    jmp           MODE_SELECT_START			
START_BIOS_PATCH_SYNC_V9toV12          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           START_BIOS_PATCH_SYNC_V9toV12
                    nop           
                    mov           w,#$dc
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV12
BIOS_PATCH_SYNC_V9toV12_LOOP1          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           BIOS_PATCH_SYNC_V9toV12_LOOP1
BIOS_PATCH_SYNC_V9toV12_LOOP2          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_PATCH_SYNC_V9toV12_LOOP2
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV12
BIOS_PATCH_SYNC_V9toV12_LOOP3          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           BIOS_PATCH_SYNC_V9toV12_LOOP3
BIOS_PATCH_SYNC_V9toV12_LOOP4          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_PATCH_SYNC_V9toV12_LOOP4
                    mov           w,#$10
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV12
BIOS_PATCH_SYNC_V9toV12_LOOP5          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           BIOS_PATCH_SYNC_V9toV12_LOOP5
BIOS_PATCH_SYNC_V9toV12_LOOP6          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_PATCH_SYNC_V9toV12_LOOP6
                    mov           w,#$45
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           START_BIOS_PATCH_SYNC_V9toV12
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    mode          $000F									; XFh mode direction for RA, RB, RC output
                    mov           w,#$0									; 0000 0000
                    mov           !IO_BIOS_DATA,w						; IO_BIOS_DATA as output start patching once sync
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$0									; patch 0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$0									; patch 0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$0									; patch 0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P1          								; next byte / wait for bios OE low
                    mov           w,#$ff						; 1111 1111
                    mov           !IO_BIOS_DATA,w				;IO_BIOS_DATA all set input, patch end done for futher sync
MODE_SELECT_START          mov           w,#$a					;todo once understand rtcc for timer
                    mov           VAR_DC2,w						; VAR_DC2 = a = 10 = 1sec
MODE_SELECT_TIMER_L1          call          MODE_SELECT_TIMER
                    snb           IO_REST						; jmp TAP_BOOT_MODE IO_REST = 1 HIGH
                    jmp           TAP_BOOT_MODE					; jmp TAP_BOOT_MODE if reset is NOT held/pressed
                    decsz         VAR_DC2						; if jmp MODE_SELECT_TIMER_L1
                    jmp           MODE_SELECT_TIMER_L1
MODE_SELECT_TIMER_L2          sb            IO_REST						; skip MODE_SELECT_TIMER_L2 IO_REST = 1 HIGH
                    jmp           MODE_SELECT_TIMER_L2					; skip jmp MODE_SELECT_TIMER_L2 if reset is not held/pressed
                    mov           w,#$5
                    mov           VAR_DC2,w						; VAR_DC2 5dec 
MODE_SELECT_TIMER_L3          call          MODE_SELECT_TIMER
                    decsz         VAR_DC2
                    jmp           MODE_SELECT_TIMER_L3					; jmp MODE_SELECT_TIMER_L3 
                    mov           w,#$64						; 100dec 
                    mov           VAR_DC2,w						; 
DISABLE_MODE          call          MODE_SELECT_TIMER
                    sb            IO_REST						; skip jmp DEV1_MODE_LOAD_START IO_REST = 1 HIGH not pressed
                    page          $0600							; PAGE8
                    jmp           DEV1_MODE_LOAD_START						; skip jmp DEV1_MODE_LOAD_START if reset is not pressed 4sec + reset tap in 10sec
                    decsz         VAR_DC2						; 10 sec timer to loop for dev1 mode same 4sec hold but release and press reset again withing 10secs.
                    jmp           DISABLE_MODE					; loop for 10secs		
                    sleep         								; no following press is modchip is disabled = sleep. kept till next standby ?
PS1_BOOT_MODE          clr           fsr						; fsr ?
                    clrb          VAR_PATCH_FLAGS.2				; VAR_PATCH_FLAGS.2 clrb here related to cross ref on new mode run if last incomplete ?
TAP_BOOT_MODE          snb           VAR_SWITCH.4				; jmp DEV1_MODE_LOAD_START if VAR_SWITCH.4 = 1 . reset from boot mode kept from first standby mode set
                    page          $0600							; PAGE8
                    jmp           DEV1_MODE_LOAD_START
                    setb          VAR_PATCH_FLAGS.1
                    clrb          VAR_PATCH_FLAGS.0
                    setb          VAR_SWITCH.3
                    clrb          VAR_SWITCH.1
                    page          $0200							; PAGE2
                    jmp           PS2_MODE_START
					
					
CHECK_IF_START_PS2LOGO          clr           fsr
                    sb            VAR_PATCH_FLAGS.2				; jmp START_PS2LOGO_PATCH_LOAD if VAR_PATCH_FLAGS.2 not set meaning last process finished
                    page          $0400							; PAGE4
                    jmp           START_PS2LOGO_PATCH_LOAD
                    sb            VAR_PATCH_FLAGS.2
                    jmp           TRAY_IS_EJECTED
TRAY_IS_EJECTED          sb            IO_REST					; skip jmp PS1_BOOT_MODE if IO_REST = 1 HIGH
                    jmp           PS1_BOOT_MODE
                    snb           IO_EJECT						; jmp TRAY_IS_EJECTED if IO_EJECT = 1 not HI ; CD out
                    jmp           TRAY_IS_EJECTED
RESUME_MODE_FROM_EJECT          mov           w,#$5
                    mov           VAR_DC2,w
RESUME_MODE_FROM_EJECT_L1          mov           w,#$64
                    mov           VAR_DC1,w
RESUME_MODE_FROM_EJECT_L2          mov           w,#$3b
                    mov           rtcc,w						; timer related due to rtcc
RESUME_MODE_FROM_EJECT_L3          sb            IO_BIOS_CS		; next byte / wait for bios CE high
                    jmp           RESUME_MODE_FROM_EJECT
                    sb            IO_REST						; skip jmp PS1_BOOT_MODE if IO_REST = 1 HIGH
                    jmp           PS1_BOOT_MODE
                    snb           IO_EJECT						; jmp TRAY_IS_EJECTED IO_EJECT = 1 not HI ; CD out
                    jmp           TRAY_IS_EJECTED
                    mov           w,rtcc						; timer related due to rtcc
                    sb            z
                    jmp           RESUME_MODE_FROM_EJECT_L3
                    decsz         VAR_DC1
                    jmp           RESUME_MODE_FROM_EJECT_L2
                    decsz         VAR_DC2
                    jmp           RESUME_MODE_FROM_EJECT_L1
                    call          SET_RB_IO_BUS
                    clr           fsr
                    snb           VAR_SWITCH.4
                    page          $0600						; PAGE8
                    jmp           START_CDDVD_PATCH
                    mov           w,#$2
                    mov           VAR_TOFFSET,w
                    mov           w,#$32					; ascii 2
                    mov           w,VAR_BIOS_YR-w
                    snb           z							; jmp CONSOLE_2002_JMP if VAR_BIOS_YR = #$32 = 2 ascii = 2002
                    jmp           CONSOLE_2002_JMP
                    mov           w,#$1						; doesnt run if 2002
                    mov           VAR_TOFFSET,w				; doesnt run if 2002
CONSOLE_2002_JMP          page          $0600						; PAGE8			
                    jmp           START_CDDVD_PATCH			; all run just VAR_TOFFSET set #$1 doesnt happen if not 2002


PS1_MODE_START_PATCH          clr           fsr
                    clrb          VAR_PATCH_FLAGS.7
                    mov           w,#$ff
                    mov           VAR_PSX_TEMP,w
RUN_PS1_SCEX_INJECT          call          SEND_SCEX							;sending scex string ;so is ps1mode area
                    snb           VAR_PATCH_FLAGS.7					; jmp PS1_SCEX_INJECT_COMPLETE if VAR_PATCH_FLAGS.7 set ps1 string loop did finish ?
                    jmp           PS1_SCEX_INJECT_COMPLETE
                    decsz         VAR_PSX_TEMP
                    jmp           RUN_PS1_SCEX_INJECT
                    page          $0200							; PAGE2
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
PS1_SCEX_INJECT_COMPLETE          snb           VAR_PATCH_FLAGS.0
                    jmp           RUN_PS1_SCEX_INJECT
                    mov           w,#$2
                    mov           VAR_TOFFSET,w
                    mov           w,#$32						; ascii 2
                    mov           w,VAR_BIOS_YR-w
                    snb           z							; jmp PS1_PALorNTSC if VAR_BIOS_YR = #$32 = 2 ascii = 2002
                    jmp           PS1_PALorNTSC
                    mov           w,#$1						; doesnt run if 2002
                    mov           VAR_TOFFSET,w				; doesnt run if 2002
PS1_PALorNTSC          snb           VAR_PATCH_FLAGS.5			; jmp PS1_CONSOLE_NTSC_YFIX if BIOS_USA set
                    page          $0400						; PAGE4
                    jmp           PS1_CONSOLE_NTSC_YFIX				; PS1_CONSOLE_NTSC_YFIX ntsc jmp
                    snb           VAR_PATCH_FLAGS.6			; jmp PS1_CONSOLE_NTSC_YFIX if BIOS_JAP set
                    page          $0400						; PAGE4
                    jmp           PS1_CONSOLE_NTSC_YFIX				; PS1_CONSOLE_NTSC_YFIX ntsc jmp
                    page          $0400						; PAGE4
                    jmp           PS1_CONSOLE_PAL_YFIX				; jmp PS1_CONSOLE_PAL_YFIX if BIOS_JAP BIOS_USA not set mean pal

                    org           $0200							; PAGE2 200-3FF

;--------------------------------------------------------------------------------
;SX28_PAGE2          								;todo sx48 is same
;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P2          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_WAIT_OE_LO_P2          								; next byte / wait for bios OE low
                    ret           

;--------------------------------------------------------------------------------
RUN_BIOS_PATCHES_SDRAM
;--------------------------------------------------------------------------------
NOTCALLED1          mov           w,indf						; sdram address moved to w and output to  IO_BIOS_DATA
                    mov           IO_BIOS_DATA,w
                    inc           fsr							; +1 to step through the sdram cached patches
                    mov           w,#$10						; 10h or so always in sdram address section 6.2.1
                    or            fsr,w							; so that ends in top 8-16 address of registery which is sdram access. bottom 0-7 reserved so when gets 1f goes 30h than 20h
RUN_BIOS_PATCHES_SDRAM_SENDLOOP          snb           IO_BIOS_OE			; next byte / wait for bios OE low
                    jmp           RUN_BIOS_PATCHES_SDRAM_SENDLOOP			; jmp RUN_BIOS_PATCHES_SDRAM_SENDLOOP if IO_BIOS_OE high
                    decsz         VAR_DC2						; loop calling of sdram cache till VAR_DC2=0 then patch finished, VAR_DC2 set in loading of call here for ea patch
                    jmp           RUN_BIOS_PATCHES_SDRAM
END_BIOS_PATCHES_SDRAM_RESET_IO          sb            IO_BIOS_OE			; next byte / wait for bios OE high
                    jmp           END_BIOS_PATCHES_SDRAM_RESET_IO			; jmp END_BIOS_PATCHES_SDRAM_RESET_IO if IO_BIOS_OE high
                    mov           w,#$ff						; 1111 1111
                    mov           !IO_BIOS_DATA,w					; all pins Hi-Z input
                    clr           fsr
                    retp          							; patching done. Return from call

;--------------------------------------------------------------------------------
BIOS_PATCH_DATA
;--------------------------------------------------------------------------------
                    jmp           pc+w
                    retw          $23			; 0
                    retw          $80			; 1
                    retw          $ac			; 2
                    retw          $c			; 3
                    retw          $0			; 4
                    retw          $0			; 5
                    retw          $0			; 6
                    retw          $24			; 7
                    retw          $10			; 8
                    retw          $3c			; 9
                    retw          $e4			; 10
                    retw          $24			; 11
                    retw          $80			; 12
                    retw          $ac			; 13
                    retw          $e4			; 14
                    retw          $22			; 15
                    retw          $90			; 16
                    retw          $ac			; 17
                    retw          $84			; 18
                    retw          $bc			; 19
                    mov           w,#$3f		; 20			; 3fh = 63
                    mov           VAR_DC3,w		; 21			; VAR_DC3 = 63
                    jmp           BIOS_PATCH_DATA_PART2_ALL	;22			; straight jmp flow. might be byte counter set like bit counter VAR_TOFFSET in SCEx ?
                    retw          $24			; 23
                    retw          $10			; 24
                    retw          $3c			; 25
                    retw          $74			; 26
                    retw          $2a			; 27
                    retw          $80			; 28
                    retw          $ac			; 29
                    retw          $74			; 30
                    retw          $28			; 31
                    retw          $90			; 32
                    retw          $ac			; 33
                    retw          $bc			; 34
                    retw          $d3			; 35
                    mov           w,#$3f			; 36
                    mov           VAR_DC3,w			; 37
                    jmp           BIOS_PATCH_DATA_PART2_ALL			; 38			; straight jmp flow. might be byte counter set like bit counter VAR_TOFFSET in SCEx ?
                    retw          $24			; 39
                    retw          $10			; 40
                    retw          $3c			; 41
                    retw          $e4			; 42
                    retw          $2c			; 43
                    retw          $80			; 44
                    retw          $ac			; 45
                    retw          $f4			; 46
                    retw          $2a			; 47
                    retw          $90			; 48
                    retw          $ac			; 49
                    snb           VAR_SWITCH.0			; 50
                    jmp           V12_CONSOLE_20_BIOS_JMP		; 51			; jmp V12_CONSOLE_20_BIOS_JMP if VAR_SWITCH.0 set = V12_CONSOLE_20_BIOS
                    mov           w,#$36				; 52		; run all but skip till V12_CONSOLE_20_BIOS_JMP
                    mov           VAR_DC3,w			; 53
                    retw          $a4			; 54
                    retw          $ec			; 55
                    mov           w,#$3f			; 56
                    mov           VAR_DC3,w			; 57
                    jmp           BIOS_PATCH_DATA_PART2_ALL			; 58
V12_CONSOLE_20_BIOS_JMP          mov           w,#$3d			; 59
                    mov           VAR_DC3,w			; 60
                    retw          $c			; 61
                    retw          $f9			; 62
BIOS_PATCH_DATA_PART2_ALL          retw          $91			; 63 ; all to land here part2 VAR_DC3 = 63
                    retw          $34			; 64
                    retw          $0			; 65
                    retw          $0			; 66
                    retw          $30			; 67
                    retw          $ae			; 68
                    retw          $c			; 69
                    retw          $0			; 70
                    retw          $0			; 71
                    retw          $0			; 72
                    retw          $c7			; 73
                    retw          $2			; 74
                    retw          $34			; 75
                    retw          $19			; 76
                    retw          $19			; 77
                    retw          $e2			; 78
                    retw          $ba			; 79
                    retw          $11			; 80
                    retw          $19			; 81
                    retw          $e2			; 82
                    retw          $ba			; 83

					
PS2_MODE_START          clr           fsr
                    sb            VAR_PATCH_FLAGS.2
                    jmp           CHECK_IF_V1_v2or3_V4_V5to8
                    mov           w,#$b
                    mov           VAR_DC1,w
                    mov           w,#$49
                    jmp           ALL_CONTIUNE_BIOS_PATCH
CHECK_IF_V1_v2or3_V4_V5to8          clr           fsr
                    mov           w,#$31					;ascii 1
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 1		;v1
                    snb           z							;skip next line if doesnt = 0 meaning is 1 ascii
                    jmp           V1_CONSOLE_11_BIOS		;jmp V1_CONSOLE_11_BIOS if VAR_BIOS_REV did = 1 ascii
                    mov           w,#$32					;ascii 2
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 2		;v2-3
                    snb           z							;skip next line if doesnt = 0 meaning is 2 ascii
                    jmp           V2or3_CONSOLE_12_BIOS				;jmp V2or3_CONSOLE_12_BIOS if VAR_BIOS_REV did = 2 ascii
                    mov           w,#$35					;ascii 5
                    mov           w,VAR_BIOS_REV-w			;does VAR_BIOS_REV = 5		;v4
                    snb           z							;skip next line if doesnt = 0 meaning is 5 ascii
                    jmp           V4_CONSOLE_15_BIOS				;jmp V4_CONSOLE_15_BIOS if VAR_BIOS_REV did = 5 ascii
                    jmp           CHECK_V9to12_REV				;jmp CHECK_V9to12_REV if VAR_BIOS_REV didnt = 5 ascii
V1_CONSOLE_11_BIOS          mov           w,#$c0
                    mov           IO_BIOS_DATA,w
                    mov           w,#$b0
                    mov           VAR_DC3,w
                    mov           w,#$74
                    mov           VAR_TOFFSET,w
                    jmp           V1to8_CONTIUNE
V2or3_CONSOLE_12_BIOS          mov           w,#$d8
                    mov           IO_BIOS_DATA,w
                    mov           w,#$40
                    mov           VAR_DC3,w
                    mov           w,#$7a
                    mov           VAR_TOFFSET,w
                    jmp           V1to8_CONTIUNE
V4_CONSOLE_15_BIOS          mov           w,#$60
                    mov           VAR_DC3,w
                    mov           w,#$7d
                    mov           VAR_TOFFSET,w
                    mov           w,#$c
                    mov           IO_BIOS_DATA,w
V1to8_CONTIUNE          mov           w,#$7
                    mov           VAR_DC1,w
                    mov           VAR_DC2,w
                    clr           w
                    jmp           ALL_CONTIUNE_BIOS_PATCH
CHECK_V9to12_REV          mov           w,#$2
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
                    mov           w,#$30
                    mov           VAR_DC3,w
                    mov           w,#$7d
                    mov           VAR_TOFFSET,w
                    mov           w,#$7
                    jmp           ALL_CONTIUNE_BIOS_PATCH
V9_CONSOLE_17_BIOS          mov           w,#$4
                    mov           VAR_DC3,w								; VAR_DC3 = 4 line start 1.7 BIOS ?
                    mov           w,#$94
                    mov           VAR_TOFFSET,w
                    mov           w,#$17
                    jmp           ALL_CONTIUNE_BIOS_PATCH
V9_CONSOLE_19_BIOS          setb          VAR_PATCH_FLAGS.3
                    mov           w,#$64
                    mov           VAR_DC3,w								; VAR_DC3 = 64h = 100 line start 1.9 BIOS ?
                    mov           w,#$9e
                    mov           VAR_TOFFSET,w
                    mov           w,#$27
                    jmp           ALL_CONTIUNE_BIOS_PATCH
V12_CONSOLE_20_BIOS          setb          VAR_PATCH_FLAGS.3
                    setb          VAR_SWITCH.0
                    mov           w,#$7c
                    mov           VAR_DC3,w								; VAR_DC3 = 7ch = 124 line start 2.0 BIOS ?
                    mov           w,#$a9
                    mov           VAR_TOFFSET,w
                    mov           w,#$27								; 27h = 39
ALL_CONTIUNE_BIOS_PATCH          snb           VAR_SWITCH.4						; jmp SECONDBIOS_PATCH_DEV1_STACK if VAR_SWITCH.4 set
                    jmp           SECONDBIOS_PATCH_DEV1_STACK
                    mov           VAR_DC3,w								; VAR_DC3 27h = 39 start line ?
                    mov           w,#$15
                    mov           fsr,w									; fsr = 15h with fsr starting for sdram patch caching
LOAD_BIOS_PATCH_DATA          mov           w,VAR_DC3							; VAR_DC3 moved w. VAR_DC3 equal start line orignally for LOAD_BIOS_PATCH_DATA
                    call          BIOS_PATCH_DATA
                    mov           indf,w								; mov value in w from patch data retw to indf which places it in the sdram memory cache as addressed cycling.
                    inc           fsr									; +1 fsr to step up sdram patch caching
                    mov           w,#$10								; 10h or so that ends in top 8-16 address of registery which is sdram access. bottom 0-7 reserved so when gets 1f goes 30h than 20h
                    or            fsr,w									; section 6.2.1 fig. 6-1 start at 15h then increase one 0001 0110 or 0001 0000 = 0001 1101 = 16h repeat
                    inc           VAR_DC3								; +1 VAR_DC3 increased for LOAD_BIOS_PATCH_DATA loop pc+w line flow to retw
                    decsz         VAR_DC1								; -1 VAR_DC1 till 0 then skip LOAD_BIOS_PATCH_DATA. has finished LOAD_BIOS_PATCH_DATA
                    jmp           LOAD_BIOS_PATCH_DATA
                    clr           fsr
                    snb           VAR_PATCH_FLAGS.2				; jmp TRAY_IS_EJECTED if VAR_PATCH_FLAGS.2 is set
                    page          $0000							; PAGE1
                    jmp           TRAY_IS_EJECTED
SECOND_BIOS_PATCH_SYNC          snb           IO_BIOS_OE				; next byte / wait for bios OE low ; ? is this verifying patch correct ???
                    jmp           SECOND_BIOS_PATCH_SYNC
                    mov           w,#$60
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
SECOND_BIOS_PATCH_SYNC_LOOP1          sb            IO_BIOS_OE				; skipping a byte next byte / wait for bios OE high
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP1
SECOND_BIOS_PATCH_SYNC_LOOP2          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP2
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
SECOND_BIOS_PATCH_SYNC_LOOP3          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP3
SECOND_BIOS_PATCH_SYNC_LOOP4          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP4
                    mov           w,#$4
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
SECOND_BIOS_PATCH_SYNC_LOOP5          sb            IO_BIOS_OE				; skipping a byte next byte / wait for bios OE high
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP5
SECOND_BIOS_PATCH_SYNC_LOOP6          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           SECOND_BIOS_PATCH_SYNC_LOOP6
                    mov           w,#$8
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC
                    mov           w,#$15
                    mov           fsr,w
SECOND_BIOS_PATCH_SYNC_P2          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           SECOND_BIOS_PATCH_SYNC_P2
                    mov           w,#$7
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC_P2
SECOND_BIOS_PATCH_SYNC_P3          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           SECOND_BIOS_PATCH_SYNC_P3
                    mov           w,#$3
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           SECOND_BIOS_PATCH_SYNC_P3
SECOND_BIOS_PATCH_SYNC_P4          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           SECOND_BIOS_PATCH_SYNC_P4
SECOND_BIOS_PATCH_SYNC_P4_L1          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           SECOND_BIOS_PATCH_SYNC_P4_L1
                    mov           w,#$24
                    mov           w,IO_BIOS_DATA-w
                    sb            z											; w = 0000 0000 go to SECOND_BIOS_PATCH_SYNC_P4_L2
                    jmp           SECOND_BIOS_PATCH_SYNC_P3
SECOND_BIOS_PATCH_SYNC_P4_L2          sb            IO_BIOS_OE				; skip byte next byte / wait for bios OE high
                    jmp           SECOND_BIOS_PATCH_SYNC_P4_L2
                    mov           !IO_BIOS_DATA,w							; from above w = 0000 0000 all IO_BIOS_DATA output. call RUN_BIOS_PATCHES_SDRAM to send patch.
SECOND_BIOS_PATCH_SYNC_P4_L3          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           SECOND_BIOS_PATCH_SYNC_P4_L3
                    page          $0200							; PAGE2
                    call          RUN_BIOS_PATCHES_SDRAM
                    snb           VAR_SWITCH.4					; jmp FINISHED_RUN_START if VAR_SWITCH.4 is set
                    page          $0600							; PAGE8
                    jmp           FINISHED_RUN_START
                    snb           VAR_SWITCH.1					; jmp PS1_MODE_SUCESSFUL_END if VAR_SWITCH.1 is set
                    page          $0400							; PAGE4
                    jmp           PS1_MODE_SUCESSFUL_END
                    page          $0000							; PAGE1
                    jmp           CHECK_IF_START_PS2LOGO		; jmp CHECK_IF_START_PS2LOGO if both VAR_SWITCH.1 VAR_SWITCH.4 not set 
					
					
SECONDBIOS_PATCH_DEV1_STACK          mov           w,#$1c
                    mov           fsr,w
                    mov           w,VAR_DC3
                    mov           indf,w								; mov value in w from patch data retw to indf which places it in the sdram memory cache as addressed cycling.
                    inc           fsr									; +1 fsr to step up sdram patch caching
                    mov           w,VAR_TOFFSET
                    mov           indf,w
                    clr           fsr
                    mov           w,#$4
                    mov           IO_BIOS_DATA,w
                    mov           w,#$77
                    mov           VAR_DC2,w
                    page          $0200							; PAGE2
                    jmp           SECOND_BIOS_PATCH_SYNC
					
					
POST_PATCH_4_MODE_START          page          $0000							; PAGE1
                    call          SET_RB_IO_BUS
POST_PATCH_4_MODE_START2          snb           VAR_SWITCH.4					; jmp FINISHED_RUN_START_2 if DEV1 mode
                    page          $0600							; PAGE8
                    jmp           FINISHED_RUN_START_2
                    mov           w,#$64
                    mov           VAR_TOFFSET,w
POST_PATCH_4_MODE_START_L1          mov           w,#$ff
                    mov           VAR_DC3,w
POST_PATCH_4_MODE_START_L2          mov           w,#$ff
                    mov           VAR_DC2,w
POST_PATCH_4_MODE_START_L3          mov           w,#$ff
                    mov           VAR_DC1,w
POST_PATCH_4_MODE_START_L4          sb            IO_BIOS_CS				; next byte / wait for bios CE high
                    jmp           POST_PATCH_4_MODE_START_P2
                    decsz         VAR_DC1
                    jmp           POST_PATCH_4_MODE_START_L4
                    decsz         VAR_DC2
                    jmp           POST_PATCH_4_MODE_START_L3
                    decsz         VAR_DC3
                    jmp           POST_PATCH_4_MODE_START_L2
                    decsz         VAR_TOFFSET
                    jmp           POST_PATCH_4_MODE_START_L1
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
POST_PATCH_4_MODE_START_L5          snb           IO_BIOS_CS				; next byte / wait for bios CE LOW = BIOS select
                    jmp           POST_PATCH_4_MODE_START_L4
POST_PATCH_4_MODE_START_P2          mov           w,#$a2
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH_4_MODE_START_L5
                    call          BIOS_WAIT_OE_LO_P2          								; next byte / wait for bios OE low
                    mov           w,#$93
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH_4_MODE_START_L5
                    call          BIOS_WAIT_OE_LO_P2          								; next byte / wait for bios OE low
                    mov           w,#$34
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH_4_MODE_START_L5
                    clr           fsr
                    mov           w,#$7
                    mov           VAR_DC2,w
                    mov           w,#$8
                    mov           IO_BIOS_DATA,w
POST_PATCH4MODE_START_P2_L1          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           POST_PATCH4MODE_START_P2_L1
                    mov           w,#$27
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L1
                    call          BIOS_WAIT_OE_LO_P2          								; next byte / wait for bios OE low
                    mov           w,#$18
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L1
                    call          BIOS_WAIT_OE_LO_P2          								; next byte / wait for bios OE low
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L1
                    call          BIOS_WAIT_OE_LO_P2          								; next byte / wait for bios OE low
                    mov           w,#$a3
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L1
                    snb           VAR_SWITCH.3									; jmp POST_PATCH4MODE_END_P2 if VAR_SWITCH.3 set
                    jmp           POST_PATCH4MODE_END_P2
                    mov           w,#$15
                    mov           fsr,w
POST_PATCH4MODE_START_P2_L2          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           POST_PATCH4MODE_START_P2_L2
                    nop           
                    mov           w,#$27
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           POST_PATCH4MODE_START_P2_L2
POST_PATCH4MODE_START_P2_L3          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           POST_PATCH4MODE_START_P2_L3
                    mov           !IO_BIOS_DATA,w			; IO_BIOS_DATA mode change ? how
POST_PATCH4MODE_END_P1          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           POST_PATCH4MODE_END_P1
                    page          $0200							; PAGE2
                    call          RUN_BIOS_PATCHES_SDRAM
                    sb            VAR_PATCH_FLAGS.0
                    page          $0000							; PAGE1
                    jmp           TRAY_IS_EJECTED
                    jmp           POST_PATCH_4_MODE_START2
POST_PATCH4MODE_END_P2          clrb          VAR_SWITCH.3
                    jmp           POST_PATCH_4_MODE_START2
					
					
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
                    snb           VAR_PATCH_FLAGS.2				; jmp PS1_MODE_RB_IO_SET_SLEEP if VAR_PATCH_FLAGS.2 is set
                    jmp           PS1_MODE_RB_IO_SET_SLEEP		; skip below io set and jmp PS1_MODE_RB_IO_SET_SLEEP
                    mov           w,#$f1						; 1111 0001
                    mov           !IO_CDDVD_BUS,w				; rb.1 IO_BIOS_CS rb.2 IO_REST rb.3 IO_EJECT enabled
                    sleep         
PS1_MODE_RB_IO_SET_SLEEP          mov           w,#$f3						; 1111 0011
                    mov           !IO_CDDVD_BUS,w				; rb.2 IO_REST rb.3 IO_EJECT enabled
                    sleep         

                    org           $0400							; PAGE4 400-5FF

;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P4          								;todo SX28 define not for sx48
;--------------------------------------------------------------------------------
                    snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    ret           

;--------------------------------------------------------------------------------
PS2LOGO_PATCH			; xcddvdman used to inject logo ?
;--------------------------------------------------------------------------------
                    jmp           pc+w
                    retw          $0
                    retw          $e0
                    retw          $3
                    retw          $0
                    retw          $0
                    retw          $0
                    retw          $0
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
                    retw          $0
                    retw          $0
                    retw          $0
                    retw          $0
                    retw          $20 ;start ps2logo line 1
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
                    retw          $24 ;ps2logo end of line 9
                    mov           w,#$49
                    mov           VAR_DC3,w
                    snb           VAR_PATCH_FLAGS.3					;skip next line if not 1.9-2.0 bios
                    jmp           PS2LOGO_PATCH_11_17_JMP1
                    mov           w,#$44							;1.9-2.0 ONLY PS2LOGO
                    mov           VAR_DC3,w
                    retw          $d0
                    retw          $80
                    mov           w,#$4b
                    mov           VAR_DC3,w
                    jmp           PS2LOGO_PATCH_19_20_JMP1
PS2LOGO_PATCH_11_17_JMP1          retw          $50					;1.1-1.7 ONLY PS2LOGO BYTE SKIPPING ABOVE 1.9-2.0 ONLY
                    retw          $81
PS2LOGO_PATCH_19_20_JMP1          retw          $80					;ALL BIOS PATCH RUN JUST LINKING FROM ABOVE SNB JMP
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
                    snb           VAR_PATCH_FLAGS.3					;skip next line if not 1.9-2.0 bios
                    jmp           PS2LOGO_PATCH_19_20_JMP2
                    mov           w,#$6b							;1.1-1.7 ONLY PS2LOGO BYTE SKIPPING ABOVE 1.9-2.0 ONLY
                    mov           VAR_DC3,w
                    retw          $bd ; start second last line ps2logo
                    retw          $5
                    retw          $4
                    retw          $8
                    retw          $cc
                    retw          $80
                    retw          $87
                    retw          $af ; end last line ps2logo
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
PS2LOGO_PATCH_19_20_JMP2          retw          $af					;ALL BIOS PATCH RUN JUST LINKING FROM ABOVE SNB JMP
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
                    retw          $af
                    retw          $5
                    retw          $4
                    retw          $8
					

START_PS2LOGO_PATCH_LOAD          mov           w,#$72			; 72h = 114
                    mov           VAR_DC1,w					; VAR_DC1 = 114
                    mov           VAR_DC2,w					; VAR_DC2 = 114
                    clr           w							; 0
                    mov           VAR_DC3,w					; VAR_DC3 = 0
                    mov           w,#$15
                    mov           fsr,w						; fsr = 15h with fsr starting for sdram patch caching
PS2LOGO_PATCHLOAD_LOOP          mov           w,VAR_DC3
                    call          PS2LOGO_PATCH
                    mov           indf,w					; mov value in w from patch data retw to indf which places it in the sdram memory cache as addressed cycling.
                    inc           fsr						; +1 fsr to step up sdram patch caching
                    mov           w,#$10					; 10h or so that ends in top 8-16 address of registery which is sdram access. bottom 0-7 reserved so when gets 1f goes 30h than 20h
                    or            fsr,w						; section 6.2.1 fig. 6-1 start at 15h then increase one 0001 0110 or 0001 0000 = 0001 1101 = 16h repeat
                    inc           VAR_DC3					; +1 VAR_DC3 starting 0
                    decsz         VAR_DC1					; jmp PS2LOGO_PATCHLOAD_LOOP till VAR_DC1 = 0
                    jmp           PS2LOGO_PATCHLOAD_LOOP
                    clr           fsr						; ?
                    snb           VAR_SWITCH.3					; jmp POST_PATCH_4_MODE_START2 if VAR_SWITCH.3 set
                    page          $0200						; PAGE2
                    jmp           POST_PATCH_4_MODE_START2
					
					
PS1_DETECTED_REBOOT          clr           fsr
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
                    snb           VAR_SWITCH.0
                    jmp           PS1_MODE_START
                    mov           w,#$af
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    mov           w,#$6
                    mov           VAR_PSX_TEMP,w
                    mov           w,#$8
                    mov           VAR_PSX_BITC,w
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    snb           VAR_PATCH_FLAGS.3					; skip jmp PS1_DETECTED_REBOOT_JMP11to17_ALL line if not 1.9-2.0 bios
                    jmp           PS1_DETECTED_REBOOT_JMP11to17_ALL						;jmp PS1_DETECTED_REBOOT_JMP11to17_ALL if is 1.1-1.7 bios
                    mov           w,#$1e							; only ran for 1.9-2.0 bios
                    mov           VAR_PSX_TEMP,w					; set VAR_PSX_TEMP = #$1e if 1.9-2.0 bios
PS1_DETECTED_REBOOT_JMP11to17_ALL          mov           w,#$57
                    mov           VAR_DC2,w
                    mov           w,#$50
                    mov           VAR_PSX_BYTE,w
PS1_DETECTED_REBOOT_L1          mov           w,#$ff
                    mov           VAR_DC3,w
PS1_DETECTED_REBOOT_L2          mov           w,#$ff
                    mov           VAR_DC1,w
AUTO_REBOOT_PS1MODE          sb            IO_BIOS_CS				; next byte / wait for bios CE high
                    jmp           PSX_MODE_START_P2
                    decsz         VAR_DC1
                    jmp           AUTO_REBOOT_PS1MODE
                    decsz         VAR_DC3
                    jmp           PS1_DETECTED_REBOOT_L2
                    decsz         VAR_PSX_BYTE
					jmp           PS1_DETECTED_REBOOT_L1
	IFDEF	RSTBUMP
                   mode          $000B						; XBh rb WKEN_B: Wakeup Enable Register (MODE=XBh) Clear the bit to 0 to enable MIWU operation or set the bit to 1 to disable, MIWU operation. see Section 4.4.
                   mov           w,#$ff						; 1111 1111
                   mov           !rb,w						; above set for rb
                   mode          $000F						; XFh mode direction for RA, RB, RC output
                   mov           w,#$0						; 0000 0000
                   mov           rb,w						; rb = 0 ? clear rb values
                   mov           w,#$fb						; 1111 1011 rb.2 IO_REST output
	ELSE
                   mov           w,#$0						; set w = #$0 = 0
                   mov           rb,w						; set rb = w = 0 ? clear rb values
                   mov           w,#$fe						; 1111 1110 rb.0 F output
	ENDIF
                    mov           !IO_CDDVD_BUS,w			; set from above routine to rb bus
                    page          $0000						; PAGE1
                    call          MODE_SELECT_TIMER			; calls MODE_SELECT_TIMER for ps1 mode set
                    mov           w,#$ff					; 1111 1111
                    mov           !IO_CDDVD_BUS,w			; all rb inputs
                    setb          VAR_PATCH_FLAGS.2			; ps1 mode set VAR_PATCH_FLAGS.2 related here ?
                    page          $0000						; PAGE1
                    jmp           CHECK_IF_V9to12
					
			
PS1_MODE_START          snb           IO_BIOS_CS				; next byte / wait for bios CE LOW = BIOS select
                    jmp           AUTO_REBOOT_PS1MODE
PSX_MODE_START_P2          mov           w,VAR_PSX_BC_CDDVD_TEMP
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_START
PS1_MODE_L1          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_MODE_L1
PS1_MODE_L2          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_MODE_L2
                    mov           w,VAR_PSX_TEMP
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_START
PS1_MODE_L3          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_MODE_L3
PS1_MODE_L4          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_MODE_L4
                    mov           w,VAR_PSX_BITC
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_START
                    snb           VAR_SWITCH.0
                    jmp           PS1_MODE_END_MOREBIOSPATCH
                    mov           w,#$3c
                    mov           fsr,w
PS1_MODE_L5          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_MODE_L5
                    nop           
                    mov           w,#$c
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_MODE_L5
PS1_MODE_L6          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_MODE_L6
                    mov           !IO_BIOS_DATA,w
PS1_MODE_L7          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_MODE_L7
                    page          $0200							; PAGE2
                    call          RUN_BIOS_PATCHES_SDRAM
                    decsz         VAR_TOFFSET
                    jmp           PS1_DETECTED_REBOOT_JMP11to17_ALL
PS1_MODE_SUCESSFUL_END          setb          VAR_PATCH_FLAGS.0
                    page          $0200							; PAGE2
                    jmp           POST_PATCH_4_MODE_START2
PS1_MODE_END_MOREBIOSPATCH          mov           w,#$1c
                    mov           fsr,w
                    setb          VAR_SWITCH.1
                    page          $0200							; PAGE2
                    jmp           SECOND_BIOS_PATCH_SYNC_P2
					
					
PS1_CONSOLE_PAL_YFIX          mov           w,#$3c					; todo is yfix pal console as seems no patch data ?
                    mov           IO_BIOS_DATA,w
                    mov           w,#$b
                    mov           VAR_DC2,w							; VAR_DC2 = bh = 11
                    mov           w,#$15
                    mov           fsr,w
PS1_CONSOLE_PAL_YFIX_SYNC          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
                    mov           w,#$11
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$11
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$9
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC
PS1_CONSOLE_PAL_YFIX_SYNC_L1          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L1
                    nop           
                    mov           w,#$30
                    mov           w,IO_BIOS_DATA-w
                    sb            z								; 0000 0000
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L1
PS1_CONSOLE_PAL_YFIX_SYNC_L2          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L2
                    mov           !IO_BIOS_DATA,w			; all IO_BIOS_DATA output. patches start ?
PS1_CONSOLE_PAL_YFIX_SYNC_L3          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_CONSOLE_PAL_YFIX_SYNC_L3
                    page          $0200							; PAGE2
                    call          RUN_BIOS_PATCHES_SDRAM
                    decsz         VAR_TOFFSET
                    jmp           PS1_CONSOLE_PAL_YFIX
PS1_CONSOLE_NTSC_YFIX          mov           w,#$34
                    mov           VAR_DC1,w
                    mov           w,#$18
                    mov           VAR_DC3,w
                    mov           VAR_TOFFSET,w
PS1_CONSOLE_NTSC_YFIX_SYNC          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC
                    mov           w,#$fd
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC
PS1_CONSOLE_NTSC_YFIX_SYNC_L1          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC_L1
PS1_CONSOLE_NTSC_YFIX_SYNC_L2          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC_L2
                    mov           w,#$ff
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC
PS1_CONSOLE_NTSC_YFIX_SYNC_L3          sb            IO_BIOS_OE				; skip byte next byte / wait for bios OE high
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC_L3
PS1_CONSOLE_NTSC_YFIX_SYNC_L4          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC_L4
                    mov           w,#$85
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC
PS1_CONSOLE_NTSC_YFIX_SYNC_L5          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC_L5
PS1_CONSOLE_NTSC_YFIX_SYNC_L6          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC_L6
                    mov           w,#$14
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC
PS1_CONSOLE_NTSC_YFIX_SYNC_L7          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC_L7
PS1_CONSOLE_NTSC_YFIX_SYNC_L8          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC_L8
                    decsz         VAR_DC1
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC_L7
                    mov           w,#$3
                    mov           IO_BIOS_DATA,w
PS1_CONSOLE_NTSC_YFIX_PATCH_1          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_CONSOLE_NTSC_YFIX_PATCH_1
                    mov           w,#$0						; 0000 0000
                    mov           !IO_BIOS_DATA,w			; all IO_BIOS_DATA output. patches start
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$80
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$4
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$3c
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$ff					; 1111 1111 
                    mov           !IO_BIOS_DATA,w			; all IO_BIOS_DATA Hi-Z input. end patch
PS1_CONSOLE_NTSC_YFIX_SYNC2          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC2
PS1_CONSOLE_NTSC_YFIX_SYNC2_L1          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC2_L1
                    decsz         VAR_DC3
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC2
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
PS1_CONSOLE_NTSC_YFIX_PATCH_2          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_CONSOLE_NTSC_YFIX_PATCH_2
                    mov           w,#$0						; 0000 0000
                    mov           !IO_BIOS_DATA,w			; all IO_BIOS_DATA output. patches start
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$0
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$ff					; 1111 1111 
                    mov           !IO_BIOS_DATA,w			; all IO_BIOS_DATA Hi-Z input. patch end
PS1_CONSOLE_NTSC_YFIX_SYNC3          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC3
PS1_CONSOLE_NTSC_YFIX_SYNC3_L1          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC3_L1
                    decsz         VAR_TOFFSET
                    jmp           PS1_CONSOLE_NTSC_YFIX_SYNC3
                    mov           w,#$88
                    mov           IO_BIOS_DATA,w
PS1_CONSOLE_NTSC_YFIX_PATCH_3          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           PS1_CONSOLE_NTSC_YFIX_PATCH_3
                    mov           w,#$0						; 0000 0000
                    mov           !IO_BIOS_DATA,w			; all IO_BIOS_DATA output. patches start
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$2
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$80
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$a4
                    mov           IO_BIOS_DATA,w
                    call          BIOS_WAIT_OE_LO_P4          								; next byte / wait for bios OE low
                    mov           w,#$ff						; 1111 1111
                    mov           !IO_BIOS_DATA,w				; all IO_BIOS_DATA Hi-Z input. patch end
                    setb          VAR_PATCH_FLAGS.0
                    page          $0000							; PAGE1
                    jmp           PS1_MODE_START_PATCH

                    org           $0600							; PAGE8 600-7FF

;--------------------------------------------------------------------------------
;SX28_PAGE8          								;todo sx48 is define
;--------------------------------------------------------------------------------
BIOS_WAIT_OE_LO_P8          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           BIOS_WAIT_OE_LO_P8          		; next byte / wait for bios OE low
                    ret           

;--------------------------------------------------------------------------------
BIOS_PATCH_DEV1 ;  straight patch flow 0 - 118
;--------------------------------------------------------------------------------
                    jmp           pc+w
                    retw          $8		; 0
                    retw          $10		; 1
                    retw          $3c		; 2
                    retw          $72		; 3
                    retw          $0		; 4
                    retw          $11		; 5
                    retw          $36		; 6
                    retw          $0		; 7
                    retw          $0		; 8
                    retw          $92		; 9
                    retw          $34		; 10
                    retw          $0		; 11
                    retw          $0		; 12
                    retw          $51		; 13
                    retw          $ae		; 14
                    retw          $c		; 15
                    retw          $0		; 16
                    retw          $0		; 17
                    retw          $0		; 18
                    retw          $3		; 19
                    retw          $0		; 20
                    retw          $5		; 21
                    retw          $24		; 22
                    retw          $10		; 23
                    retw          $0		; 24
                    retw          $4		; 25
                    retw          $3c		; 26
                    retw          $f0		; 27
                    retw          $1		; 28
                    retw          $84		; 29
                    retw          $34		; 30
                    retw          $10		; 31
                    retw          $0		; 32
                    retw          $6		; 33
                    retw          $3c		; 34
                    retw          $e4		; 35
                    retw          $1		; 36
                    retw          $c6		; 37
                    retw          $34		; 38
                    retw          $6		; 39
                    retw          $0		; 40
                    retw          $3		; 41
                    retw          $24		; 42
                    retw          $c		; 43
                    retw          $0		; 44
                    retw          $0		; 45
                    retw          $0		; 46
                    retw          $fb		; 47
                    retw          $1		; 48
                    retw          $10		; 49
                    retw          $0		; 50
                    retw          $b		; 51
                    retw          $2		; 52
                    retw          $10		; 53
                    retw          $0		; 54
                    retw          $19		; 55
                    retw          $2		; 56
                    retw          $10		; 57
                    retw          $0		; 58
                    retw          $6d		; 59
                    retw          $6f		; 60
                    retw          $64		; 61
                    retw          $75		; 62
                    retw          $6c		; 63
                    retw          $65		; 64
                    retw          $6c		; 65
                    retw          $6f		; 66
                    retw          $61		; 67
                    retw          $64		; 68
                    retw          $0		; 69
                    retw          $2d		; 70
                    retw          $6d		; 71
                    retw          $20		; 72
                    retw          $72		; 73
                    retw          $6f		; 74
                    retw          $6d		; 75
                    retw          $30		; 76
                    retw          $3a		; 77
                    retw          $53		; 78
                    retw          $49		; 79
                    retw          $4f		; 80
                    retw          $32		; 81
                    retw          $4d		; 82
                    retw          $41		; 83
                    retw          $4e		; 84
                    retw          $0		; 85
                    retw          $2d		; 86
                    retw          $6d		; 87
                    retw          $20		; 88
                    retw          $72		; 89
                    retw          $6f		; 90
                    retw          $6d		; 91
                    retw          $30		; 92
                    retw          $3a		; 93
                    retw          $4d		; 94
                    retw          $43		; 95
                    retw          $4d		; 96
                    retw          $41		; 97
                    retw          $4e		; 98
                    retw          $0		; 99
                    retw          $6d		; 100
                    retw          $63		; 101
                    retw          $30		; 102
                    retw          $3a		; 103
                    retw          $2f		; 104
                    retw          $42		; 105
                    retw          $4f		; 106
                    retw          $4f		; 107
                    retw          $54		; 108
                    retw          $2f		; 109
                    retw          $42		; 110
                    retw          $4f		; 111
                    retw          $4f		; 112
                    retw          $54		; 113
                    retw          $2e		; 114
                    retw          $45		; 115
                    retw          $4c		; 116
                    retw          $46		; 117
                    retw          $0		; 118
					
DEV1_MODE_LOAD_START          clrb          VAR_PATCH_FLAGS.2			; VAR_PATCH_FLAGS.2 clrb here related finish mode run ?
                    setb          VAR_PATCH_FLAGS.1
                    setb          VAR_PATCH_FLAGS.0
                    setb          VAR_SWITCH.4
                    mov           w,#$77
                    mov           VAR_DC1,w				; VAR_DC1 = 77h = 119
                    clr           w
                    mov           VAR_DC3,w				; VAR_DC3 = 0
                    mov           w,#$15
                    mov           fsr,w						; fsr = 15h with fsr starting for sdram patch caching
DEV1_MODE_LOAD_LOOP          mov           w,VAR_DC3
                    call          BIOS_PATCH_DEV1
                    mov           indf,w					; mov value in w from patch data retw to indf which places it in the sdram memory cache as addressed cycling.
                    inc           fsr						; +1 fsr to step up sdram patch caching
                    mov           w,#$10					; 10h or so that ends in top 8-16 address of registery which is sdram access. bottom 0-7 reserved so when gets 1f goes 30h than 20h
                    or            fsr,w						; section 6.2.1 fig. 6-1 start at 15h then increase one 0001 0110 or 0001 0000 = 0001 1101 = 16h repeat
                    inc           VAR_DC3					; + 1 VAR_DC3 starting 0 above
                    decsz         VAR_DC1					; jmp DEV1_MODE_LOAD_LOOP till VAR_DC1 = 0 start 119
                    jmp           DEV1_MODE_LOAD_LOOP
                    page          $0200								; PAGE2
                    jmp           CHECK_IF_V1_v2or3_V4_V5to8

;--------------------------------------------------------------------------------
;CDDVD_AREA
;--------------------------------------------------------------------------------
MECHACON_WAIT_OE          
                    snb           IO_CDDVD_OE_A_1Q  ; jmp MECHACON_WAIT_OE if ^Q = 1
                    jmp           MECHACON_WAIT_OE  ; wait until flipflop ^Q == 0
                    clrb          IO_CDDVD_OE_A_1R  ; reset flipflop so Q = 0 (and ^Q = 1)
                    nop                             ; ...
                    setb          IO_CDDVD_OE_A_1R  ; reset flipflop so ready for if lower sensed on cp (A) CONSOLE_IO_CDDVD_OE_A
                    decsz         VAR_DC1           ; decrement counter and repeat MECHACON_WAIT_OE if not yet zero
                    jmp           MECHACON_WAIT_OE  ; ...
                    ret                             ; counter finished: return

;--------------------------------------------------------------------------------
CDDVD_PATCH_DATA										; different get sync for where patch is spc/dragon ?
;--------------------------------------------------------------------------------
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
                    retw          $4					; 0000 0100 ; 6 ; USA end
                    retw          $41					; 0100 0001 ; 7 ; PAL start
                    retw          $44					; 0100 0100 ; 8
                    retw          $fd					; 1111 1101 ; 9
                    retw          $13					; 0001 0011 ; 10
                    retw          $2b					; 0010 1011 ; 11
                    retw          $61					; 0110 0001 ; 12
                    retw          $22					; 0010 0010 ; 13
                    retw          $13					; 0001 0011 ; 14 ; PAL end
                    retw          $31					; 0011 0001 ; 15 ; JAP start
                    retw          $8c					; 1000 1100 ; 16
                    retw          $b0					; 1011 0000 ; 17
                    retw          $3					; 0000 0011 ; 18
                    retw          $3a					; 0011 1010 ; 19
                    retw          $31					; 0011 0001 ; 20
                    retw          $33					; 0011 0011 ; 21
                    retw          $19					; 0001 1001 ; 22
                    retw          $91					; 1001 0001 ; 23 ; JAP end
					
START_CDDVD_PATCH          clr           fsr
                    setb          IO_CDDVD_OE_A_1R
                    mov           w,#$30									;ascii 0
                    mov           w,VAR_BIOS_REV-w
                    snb           z
                    jmp           V9toV12_CONSOLE_CDDVD_START				; jmp V9toV12_CONSOLE_CDDVD_START if is #$30 = 0 ascii = 2.0 bios v12
                    mov           w,#$37									;ascii 7
                    mov           w,VAR_BIOS_REV-w
                    snb           c											; compare VAR_BIOS_REV #$37 7 jmp V9toV12_CONSOLE_CDDVD_START if is equal 37 or above
                    jmp           V9toV12_CONSOLE_CDDVD_START				; jmp V9toV12_CONSOLE_CDDVD_START for v9 1.7 - 1.9 bios 
V1toV8_CONSOLE_CDDVD_START          mov           w,#$4
                    mov           VAR_DC1,w
V1toV8_AND_BYTE_SYNC1          mov           w,#$90
V1toV8_AND_BYTE_SYNC1_L1          snb           IO_CDDVD_OE_A_1Q
                    jmp           V1toV8_AND_BYTE_SYNC1_L1
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    and           w,IO_CDDVD_BUS					; The instruction and performs bit-wise AND operation on its operands.
                    mov           VAR_PSX_BC_CDDVD_TEMP,w						; w and moved to VAR_PSX_BC_CDDVD_TEMP
                    mov           w,#$90							; 1001 0000
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w					; when VAR_PSX_BC_CDDVD_TEMP which has been and = 1001 0000
                    sb            z									; VAR_PSX_BC_CDDVD_TEMP and = 1001 0000 skips V1toV8_CONSOLE_CDDVD_START loop meaning on sync
                    jmp           V1toV8_CONSOLE_CDDVD_START		; restart sync to start, V1toV8_CONSOLE_CDDVD_START if not on sync. would loop here till gets least one and = 1001 0000
                    decsz         VAR_DC1							; VAR_DC1 = 4 cycles V1toV8_AND_BYTE_SYNC1 counting down so 4x and = 1001 0000
                    jmp           V1toV8_AND_BYTE_SYNC1				; jmp V1toV8_AND_BYTE_SYNC1 if VAR_DC1 not 0
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT	; jmp when VAR_DC1 = 0


V9toV12_CONSOLE_CDDVD_START          mov           w,#$f					; only 50k+ run, dragon G patch stack ?
                    mov           VAR_DC1,w
V9toV12_AND_BYTE_SYNC1          mov           w,#$b0
V9toV12_AND_BYTE_SYNC1_L1          snb           IO_CDDVD_OE_A_1Q
                    jmp           V9toV12_AND_BYTE_SYNC1_L1
                    clrb          IO_CDDVD_OE_A_1R
                    and           w,IO_CDDVD_BUS					; The instruction and performs bit-wise AND operation on its operands.
                    mov           VAR_PSX_BC_CDDVD_TEMP,w						; w and moved to VAR_PSX_BC_CDDVD_TEMP
                    setb          IO_CDDVD_OE_A_1R
                    mov           w,#$a0							; 1010 0000
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w					; when VAR_PSX_BC_CDDVD_TEMP which has been and = 1010 0000
                    sb            z									; VAR_PSX_BC_CDDVD_TEMP and = 1010 0000 skips V9toV12_AND_BYTE_SYNC1 loop1 meaning on sync start
                    jmp           V9toV12_AND_BYTE_SYNC1
                    mov           w,#$b0
V9toV12_AND_BYTE_SYNC1_L3          snb           IO_CDDVD_OE_A_1Q
                    jmp           V9toV12_AND_BYTE_SYNC1_L3
                    clrb          IO_CDDVD_OE_A_1R
                    and           w,IO_CDDVD_BUS
                    mov           VAR_PSX_BC_CDDVD_TEMP,w
                    setb          IO_CDDVD_OE_A_1R
                    mov           w,#$b0							; 1011 0000
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w					
                    snb           z									; jmp V9toV12_AND_BYTE_SYNC2 if AND = 1011 0000
                    jmp           V9toV12_AND_BYTE_SYNC2
                    mov           w,#$0								; 0000 0000
                    mov           w,VAR_PSX_BC_CDDVD_TEMP-w
                    sb            z									; skip jmp V9toV12_AND_BYTE_SYNC1 if AND = 0
                    jmp           V9toV12_AND_BYTE_SYNC1
V9toV12_AND_BYTE_SYNC2          mov           w,#$b0
V9toV12_AND_BYTE_SYNC2_L1          snb           IO_CDDVD_OE_A_1Q
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
                    jmp           V9toV12_AND_BYTE_SYNC1
                    snb           VAR_PATCH_FLAGS.2				; jmp PS2_MODE_RB_IO_SET_SLEEP if VAR_PATCH_FLAGS.2 is set
                    page          $0200							; PAGE2
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
                    call          MECHACON_WAIT_OE
                    mov           w,#$0
                    mov           IO_CDDVD_BUS,w
                    mov           w,#$1f
V9toV12_CONSOLE_PATCH1          snb           IO_CDDVD_OE_A_1Q
                    jmp           V9toV12_CONSOLE_PATCH1
                    clrb          IO_CDDVD_OE_A_1R
                    mov           !IO_CDDVD_BUS,w				; IO_CDDVD_BUS set output start patching ?
                    setb          IO_CDDVD_OE_A_1R
                    mov           w,#$5
                    mov           VAR_DC1,w
                    call          MECHACON_WAIT_OE
                    mov           w,#$ff						; 1111 1111
                    mov           !IO_CDDVD_BUS,w				; IO_CDDVD_BUS all pins Hi-Z input patching end
V9toV12_CONSOLE_PATCH1_POST          snb           VAR_PATCH_FLAGS.2				; jmp PS1_MODE_START_PATCH if VAR_PATCH_FLAGS.2 is set
                    page          $0000							; PAGE1
                    jmp           PS1_MODE_START_PATCH						; ALL_CDDVD_PATCH1_GET_SYNC_BIT all consoles run, B I H side ?
ALL_CDDVD_PATCH1_GET_SYNC_BIT          sb            IO_BIOS_CS				; next byte / wait for bios CE high
                    jmp           CDDVD_IS_PS1
                    snb           IO_CDDVD_OE_A_1Q							; jmp ALL_CDDVD_PATCH1_GET_SYNC_BIT if flipflop ^Q == 1 / wait to go low (A)
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT				; loop ALL_CDDVD_PATCH1_GET_SYNC_BIT till IO_CDDVD_OE_A_1Q = 0
                    clrb          IO_CDDVD_OE_A_1R							; reset flipflop so ^Q = 1
                    nop           
                    setb          IO_CDDVD_OE_A_1R							; set flipflop ready for if lower sensed on cp (A) CONSOLE_IO_CDDVD_OE_A
                    snb           IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L1          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L1
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L2          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L2
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    snb           IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L3          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L3
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L4          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L4
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           V9toV12_CONSOLE_PATCH1_POST
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L5          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L5
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    sb            IO_CDDVD_BUS_b
                    jmp           V9toV12_CONSOLE_PATCH1_POST
ALL_CDDVD_PATCH1_GET_SYNC_BIT_L6          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT_L6
                    clrb          IO_CDDVD_OE_A_1R
                    nop           
                    setb          IO_CDDVD_OE_A_1R
                    sb            IO_CDDVD_BUS_i
                    snb           IO_CDDVD_BUS_b
                    jmp           V9toV12_CONSOLE_PATCH1_POST
                    snb           VAR_PATCH_FLAGS.2				; jmp PS2_MODE_RB_IO_SET_SLEEP if VAR_PATCH_FLAGS.2 is set
                    page          $0200							; PAGE2
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
                    mov           w,#$90
                    mov           IO_CDDVD_BUS,w
                    mov           w,#$6f
ALL_CDDVD_PATCH1          snb           IO_CDDVD_OE_A_1Q
                    jmp           ALL_CDDVD_PATCH1
                    clrb          IO_CDDVD_OE_A_1R
                    mov           !IO_CDDVD_BUS,w				; IO_CDDVD_BUS set output start patching ?
                    setb          IO_CDDVD_OE_A_1R
ALL_CDDVD_PATCH1_POST          snb           IO_CDDVD_OE_A_1Q	; 0 being patched as nothing set ? after this sync
                    jmp           ALL_CDDVD_PATCH1_POST
                    clrb          IO_CDDVD_OE_A_1R
                    mov           w,#$ff						; 1111 1111
                    mov           !IO_CDDVD_BUS,w				; IO_CDDVD_BUS all pins Hi-Z input patching end
                    setb          IO_CDDVD_OE_A_1R
                    snb           VAR_PATCH_FLAGS.5
                    jmp           CDDVD_USA
                    snb           VAR_PATCH_FLAGS.4
                    jmp           CDDVD_PAL
                    mov           w,#$10						; JAP start 10h = 16 line
                    jmp           CDDVD_JAP
CDDVD_PAL          mov           w,#$8							; PAL start 8h = 8 line
                    jmp           CDDVD_JAP
CDDVD_USA          clr           w								; USA start 0h = 0 line
CDDVD_JAP          mov           VAR_DC2,w
                    mov           w,#$8
                    mov           VAR_DC3,w						; set line count to run to 8
                    mov           w,#$ff
                    mov           IO_CDDVD_BUS,w
ALL_CDDVD_PATCH_SYNC2_BIT          mov           w,#$3
                    mov           VAR_DC1,w
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
                    mov           w,#$f						; 0000 1111
                    mov           !IO_CDDVD_BUS,w			; set rb.4 (B) rb.5 (G) rb.6 (H) rb.7 (I) output start patching
RUN_CDDVD_PATCH          mov           w,VAR_DC2			; VAR_DC2 moved into w, used for offset start in patch. how ea way ?
                    call          CDDVD_PATCH_DATA
RUN_CDDVD_PATCH_NIBBLE          snb           IO_CDDVD_OE_A_1Q			; jmp RUN_CDDVD_PATCH_NIBBLE if IO_CDDVD_OE_A_1Q 1
                    jmp           RUN_CDDVD_PATCH_NIBBLE
                    mov           IO_CDDVD_BUS,w
                    clrb          IO_CDDVD_OE_A_1R
                    mov           VAR_PSX_BC_CDDVD_TEMP,w				; IO_CDDVD_BUS moved to VAR_PSX_BC_CDDVD_TEMP
                    mov           w,<>VAR_PSX_BC_CDDVD_TEMP			; nibble VAR_PSX_BC_CDDVD_TEMP into w eg turn 0110 1010 into 1010 0110 just eg not actual value ; hex just swap 2x byte digits shortcut f1 = 1f as same 4x bits just order
                    setb          IO_CDDVD_OE_A_1R
RUN_CDDVD_PATCH_NIBBLE_SEND          snb           IO_CDDVD_OE_A_1Q
                    jmp           RUN_CDDVD_PATCH_NIBBLE_SEND
                    mov           IO_CDDVD_BUS,w
                    clrb          IO_CDDVD_OE_A_1R
                    inc           VAR_DC2					; +1 the VAR_DC2 set for start point for region
                    setb          IO_CDDVD_OE_A_1R
                    decsz         VAR_DC3					; set 8 here and counts down till 0 then skip the jmp RUN_CDDVD_PATCH loop. 
                    jmp           RUN_CDDVD_PATCH
CDDVD_PATCH_POST_RB_INPUT          snb           IO_CDDVD_OE_A_1Q
                    jmp           CDDVD_PATCH_POST_RB_INPUT
                    mov           w,#$ff						; 1111 1111
                    mov           !IO_CDDVD_BUS,w				; IO_CDDVD_BUS all pins Hi-Z input patching end
                    snb           VAR_PATCH_FLAGS.1
                    jmp           ALL_CDDVD_PATCH1_GET_SYNC_BIT					; jmp ALL_CDDVD_PATCH1_GET_SYNC_BIT if VAR_PATCH_FLAGS.1 set
CDDVD_IS_PS1          clrb          VAR_PATCH_FLAGS.1
                    snb           VAR_PATCH_FLAGS.0
                    page          $0200							; PAGE2
                    jmp           POST_PATCH_4_MODE_START2
                    page          $0400							; PAGE4
                    jmp           PS1_DETECTED_REBOOT
					
					
FINISHED_RUN_START          page          $0000							; PAGE1
                    call          SET_RB_IO_BUS
FINISHED_RUN_START_2          mov           w,#$64						; SLEEP FOR ALL = if no BIOS akt		FINISHED_RUN_START_2 = IS_XCDVDMAN	
                    mov           VAR_TOFFSET,w					; 30-35 sec wait for BIOS
FINISHED_RUN_START_L1          mov           w,#$ff
                    mov           VAR_DC3,w
FINISHED_RUN_START_L2          mov           w,#$ff
                    mov           VAR_DC2,w
FINISHED_RUN_START_L3          mov           w,#$ff
                    mov           VAR_DC1,w
FINISHED_RUN_START_L4          sb            IO_BIOS_CS					; next byte / wait for bios CE high
                    jmp           FINISHED_RUN_START_P2
                    decsz         VAR_DC1
                    jmp           FINISHED_RUN_START_L4
                    decsz         VAR_DC2
                    jmp           FINISHED_RUN_START_L3
                    decsz         VAR_DC3
                    jmp           FINISHED_RUN_START_L2
                    decsz         VAR_TOFFSET
                    jmp           FINISHED_RUN_START_L1
                    page          $0200							; PAGE2
                    jmp           PS2_MODE_RB_IO_SET_SLEEP
FINISHED_RUN_START_L5          snb           IO_BIOS_CS				; next byte / wait for bios CE LOW = BIOS select
                    jmp           FINISHED_RUN_START_L4
FINISHED_RUN_START_P2          mov           w,#$43
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_L5
                    call          BIOS_WAIT_OE_LO_P8          								; next byte / wait for bios OE low
                    mov           w,#$14
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_L5
                    call          BIOS_WAIT_OE_LO_P8          								; next byte / wait for bios OE low
                    mov           w,#$74
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_L5
FINISHED_RUN_START_P2_L1          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           FINISHED_RUN_START_P2_L1
                    mov           w,#$d0
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2_L1
FINISHED_RUN_START_P2_L2          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           FINISHED_RUN_START_P2_L2
FINISHED_RUN_START_P2_L3          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           FINISHED_RUN_START_P2_L3
                    mov           w,#$ff
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2_L1
FINISHED_RUN_START_P2_L4          sb            IO_BIOS_OE				; next byte / wait for bios OE high
                    jmp           FINISHED_RUN_START_P2_L4
FINISHED_RUN_END          snb           IO_BIOS_OE				; next byte / wait for bios OE low
                    jmp           FINISHED_RUN_END
                    mov           w,#$42
                    mov           w,IO_BIOS_DATA-w
                    sb            z
                    jmp           FINISHED_RUN_START_P2_L1
                    mov           w,#$34
                    mov           IO_BIOS_DATA,w
                    mov           w,#$0						; 0000 0000
                    mov           !IO_BIOS_DATA,w			; IO_BIOS_DATA all pins output ? why
                    call          BIOS_WAIT_OE_LO_P8        ; next byte / wait for bios OE low
                    mov           w,#$ff					; 1111 1111 
                    mov           !IO_BIOS_DATA,w			; IO_BIOS_DATA all pins Hi-Z input
                    jmp           FINISHED_RUN_START_2
                    end
