;------------------------------------------
;	MAGICE ICE Final SX28 ANGELICA labels address value off
;------------------------------------------

VAR_DC1             	    =           $08 ; DS 1 ; delay counter 1(small)
VAR_DC2             	    =           $09 ; DS 1 ; delay counter 2(small)
VAR_DC3             	    =           $0A ; DS 1 ; delay counter 3(big)
VAR_TOFFSET         	    =           $0b ; DS 1 ; table offset
VAR_PSX_BC     			    =           $14 ; DS 1 ; SEND_SCEX:  byte counter  note start at 4(works down to 0)
VAR_PSX_BYTE        	    =           $0D ; DS 1 ; SEND_SCEX:  byte(to send)
VAR_PSX_TEMP                =           $0C ; DS 1 ; SEND_SCEX:  rename later
VAR_PSX_BITC                =           $13 ; DS 1 ; SEND_SCEX:  bit counter ;note start at 8(works down to 0)
VAR_BIOS_REGION_TEMP        =           $12 ; temp storage to compare byte7 of ;BIOS_VERSION_MATCHING
VAR_SWITCH                  =           $0F ;  ? ; bit 0=xcddvdman mode + PSX1 region switch, 1=PSX1/PSX2 wakeup mode, 2=PSX1 PAL/NTSC , 3=PSX2 logo patch , 4=DEV1 
VAR_BIOS_YR                 =           $11 ; DS 1 ; / ; byteC of ;BIOS_VERSION_MATCHING
VAR_PATCH_FLAGS             =           $0E ; appears to be bits set for running patch routines .0-.7 for setb an offset
VAR_BIOS_REV                =           $10 ; 1.X0 THE BIOS REVISION byte infront in BIOS string is X.00

ra	=	$05
;IO_SCEX = ra.2 ;(PSX:SCEx)RA2(S)
;IO_BIOS_OE = ra.0 ; (BIOS:OE#)RA0(R)
;IO_BIOS_CS = rb.1 ; LOW = BIOS select ; (BIOS0 CS)RB4(W)
;IO_REST = rb.2 ; LOW = rest down ; (PSX2REST)RA3(REST) via 33k
IO_BIOS_DATA = $07 ; rc
;IO_BIOS_DATA-v = rc.0
;IO_BIOS_DATA-u = rc.1
;IO_BIOS_DATA-t = rc.2
;IO_BIOS_DATA-q = rc.3
;IO_BIOS_DATA-p = rc.4
;IO_BIOS_DATA-o = rc.5
;IO_BIOS_DATA-n = rc.6
;IO_BIOS_DATA-m = rc.7
;IO_EJECT = rb.3 ; LOW = CD IN, HI = CD OUT ; (PS2:EJECT)RB3(Z)
rb = $06 ; rb
;IO_CDDVD_BUS_f = rb.0
;IO_CDDVD_BUS_b = rb.4
;IO_CDDVD_BUS_g = rb.5
;IO_CDDVD_BUS_h = rb.6
;IO_CDDVD_BUS_i = rb.7
;IO_CDDVD_OE_A_1Q = ra.1 ; (CDDVD:OE)RA1(A flipflop 1Q#)
;IO_CDDVD_OE_A_1QR = ra.3 ; A 1R# flipflop
