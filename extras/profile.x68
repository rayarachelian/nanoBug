*-----------------------------------------------------------------------------
* Profile dumper - Copyright (C) 2005, by Ray Arachelian, All Rights Reserved
*
*                A Part of the Lisa Emulation Project
*
*------------------------------------------------------------------------------

* TODO - enable hardware handshaking here!


                ORG     $22000               * E68K uses 7000, Lisa Boot uses  20000
*               LOAD    $22000

START           EQU             *
                BRA DUMPONE


CRC16           EQU     $0002ff80
SECNUM          EQU     $0002ff84
SECEND          EQU     $0002ff88
RESULT          EQU     $0002ff8c
RESD1           EQU     $0002ff90

TAGDATA         EQU     $0002ffc0
TAGDATA0        EQU     $0002ffc0
TAGDATA1        EQU     $0002ffc4
TAGDATA2        EQU     $0002ffc8
TAGDATA3        EQU     $0002ffcc
TAGDATA4        EQU     $0002ffd0
TAGDATA5        EQU     $0002ffd4
DATABLOCK       EQU     $00030000
DATAEND         EQU     $00030200




PRINTTEXT:      MOVEM.L   A0-A6/D0-D7,-(A7)        * save regs
PRNTNXT         MOVE.B    (A0)+,D0                 * get the char
                TST.B     D0
                BEQ       PRTXEND                  * end on null
                JSR       $000201A4                * print the character (SCCOUT)
                BRA       PRNTNXT
PRTXEND         MOVEM.L   (A7)+,A0-A6/D0-D7
                RTS


PRINTCOLON      MOVEM.L   A0-A6/D0-D7,-(A7)
                MOVE.B #':',D0
                JSR    $000201A4
                MOVEM.L   (A7)+,A0-A6/D0-D7
                RTS

PRINTDASH       MOVEM.L   A0-A6/D0-D7,-(A7)
                MOVE.B #'-',D0
                JSR    $000201A4
                MOVEM.L   (A7)+,A0-A6/D0-D7
                RTS


PRINTCOMMA      MOVEM.L   A0-A6/D0-D7,-(A7)
                MOVE.B #',',D0
                JSR    $000201A4
                MOVEM.L   (A7)+,A0-A6/D0-D7
                RTS


TWONEWLINES     MOVEM.L   A0-A6/D0-D7,-(A7)
                JSR $00020138               * print newline
                JSR $00020138               * print newline
                MOVEM.L   (A7)+,A0-A6/D0-D7
                RTS


NEWLINE         MOVEM.L   A0-A6/D0-D7,-(A7)
                JSR $00020138               * print newline
                MOVEM.L   (A7)+,A0-A6/D0-D7
                RTS



PRINTHEX4       MOVEM.L   A0-A6/D0-D7,-(A7)           * Print value in D0 (SLR) already in D0
                JSR    $000200E0
                MOVEM.L   (A7)+,A0-A6/D0-D7
                RTS

SLEEP           MOVEM.L   A0-A6/D0-D7,-(A7)           * Print value in D0 (SLR) already in D0

                MOVE.L #$000002F0,D0
SLP1            MOVE.L (A7),(A7)
                MOVE.L (A7),(A7)
                MOVE.L (A7),(A7)
                SUBQ.L #1,D0
                BNE SLP1

                MOVEM.L   (A7)+,A0-A6/D0-D7
                RTS


STARTING        DC.B 13,10,10,'Starting dump of profile',13,10,10,0
TXTSECNUM       DC.B 13,10,10,'-----------------------------------------------',13,10,'Sector Number: ',0
TXRETVAL        DC.B 13,10,'Return Value (0=good): ',0
TXERRBYTES      DC.B 13,10,'Error bytes: ',0
TXTAGS          DC.B 13,10,'TAGS: ',0

WIPEASS         MOVE.L #CRC16,A0
WIPE1           MOVE.L #$DEADBEEF,(A0)+
                CMP.L  #DATAEND,A0
                BNE    WIPE1

DUMPONE         MOVE.L #$00000001,D0           ; end sector
                MOVE.L D0,SECEND
                MOVE.L #$00FFFFFE,D0           ; startsector
                MOVE.L D0,SECNUM
                BRA DUMPPROF

PRODUMP         MOVE.L #$00002601,D0           ; end sector
                MOVE.L D0,SECEND
                MOVE.L #$00FFFFFE,D0
                MOVE.L D0,SECNUM


DUMPPROF        MOVE.L #$FCC000,A0
                MOVE.L #$8585ffff,(A0)         ; tell the floppy controller to clear any IRQ's (i.e. post eject)

                LEA STARTING,A0
                BSR PRINTTEXT

PRNXSEC         LEA TXTSECNUM,A0               ; entry point for partial dump
                BSR PRINTTEXT

                BSR SLEEP

                MOVE.L SECNUM,D0
                BSR PRINTHEX4

                BSR SLEEP


                BSR  PREADSEC       ; read the sector

                ORI.W #$2700,SR

                LEA TXRETVAL,A0
                BSR PRINTTEXT

                BSR SLEEP

                MOVE.L RESULT,D0  ; return value
                BSR PRINTHEX4
                BSR SLEEP

                LEA TXERRBYTES,A0
                BSR PRINTTEXT
                BSR SLEEP

                MOVE.L RESD1,D0  ; error byte value
                BSR PRINTHEX4
                BSR SLEEP

                LEA TXTAGS,A0
                BSR PRINTTEXT
                BSR SLEEP

                MOVE.L TAGDATA0,D0   ; tag bytes - ec-ef  ;20 tags, 4 bytes in a long, we do this 5x
                BSR PRINTHEX4
                BSR PRINTCOMMA
                BSR SLEEP

                MOVE.L TAGDATA1,D0
                BSR PRINTHEX4
                BSR PRINTCOMMA
                BSR SLEEP

                MOVE.L TAGDATA2,D0
                BSR PRINTHEX4
                BSR PRINTCOMMA
                BSR SLEEP

                MOVE.L TAGDATA3,D0
                BSR PRINTHEX4
                BSR PRINTCOMMA
                BSR SLEEP

                MOVE.L TAGDATA4,D0
                BSR PRINTHEX4
                BSR PRINTCOMMA
                BSR SLEEP

                MOVE.L TAGDATA5,D0
                BSR PRINTHEX4

                BSR NEWLINE
                BSR SLEEP


                CLR.L D3              ; dump sector here
                MOVE.L #DATABLOCK,A0

PRSEC0          CLR.L D0
                MOVE.B D3,D0
                BSR PRINTHEX4
                BSR PRINTCOLON
                BSR SLEEP

PRSEC1          BSR SLEEP
                MOVE.L (A0)+,D0
                BSR PRINTHEX4
                BSR PRINTCOMMA

                ADD.L  #$10,D3        ; increment index
                CMP.L  #$200,D3       ; did we print the whole sector
                BEQ PRS2A             ; yes? do the next one

                MOVE.B D3,D4          ; did we print 4 values already?
                AND.B #$3,D4
                BNE PRSEC1            ; no, continue on the same line
                BSR NEWLINE           ; yes, print a new line and next print the address

                BSR SLEEP

                BRA PRSEC0


PRS2A           MOVE.L SECNUM,D0      ; done printing this sector, get sector #
                ADDQ.L #1,D0          ; increment it
                AND.L #$00FFFFFF,D0
                MOVE.L D0,SECNUM      ; save it

                CMP.L SECEND,D0       ; did we read the entire profile drive
                BNE   PRNXSEC         ; no, print the next sector

                BSR TWONEWLINES

                BSR SLEEP


                JMP $0002001a         ; return to nanobug




*;-----------------------------------------------------------------------------
*;  First initialize and then ensure disk is attached by checking OCD line.
*;  Assumes ACR and IER registers of VIA set up by caller.  For boot, these
*;  are cleared by power-up reset.
*;  Register usage:
*;    D0 = scratch use           A0 = VIA address for parallel port interface
*;    D1 = block to read         A1 = address to save header
*;    D2 = timeout count         A2 = address to save data
*;    D3 = retry count           A3 = scratch
*;    D4 = threshold count       A4 = unused
*;  Returns
*;    D0 = error code (0 = OK)
*;    D1 = error bytes (4)
*;    D2 - D7 and A1 - A6 are preserved
*;-----------------------------------------------------------------------------


PREADSEC        MOVE.L  #$00fcdd81,A3           ; get kybd VIA base address
                ORI.B   #$A0,$0(A3)             ; ORB1  initialize profile-reset and parity-reset
                ORI.B   #$A0,$4(A3)             ; DDRB1 and set lines as outputs
                MOVE.L  #$00fcd901,A0           ;       get paraport VIA base address
                ANDI.B  #$7B,$60(A0)            ; PCR2  set ctrl CA2 pulse mode/positive edge
                ORI.B   #$6B,$60(A0)
                MOVE.B  #$00,$18(A0)            ; DDRA2 set port A bits to input
                ORI.B   #$18,$0(A0)             ; ORB2  then set direction=in, cmd=false,
                ANDI.B  #$FB,$0(A0)             ; ORB2  enable=true
                ANDI.B  #$FC,$10(A0)            ; DDRB2 set port B bits 0,1=in,
                ORI.B   #$1C,$10(A0)            ;  2,3,4=out

OCDCHK:         BTST    #0,0(A0)                ; IRB2 check OCD line
                BNE     OCDCHK                  ; wait until profile is ready

                MOVE.L  SECNUM,D1               ; get address of block # to read from xmodem header block
                AND.L   #$00FFFFFF,D1

                MOVE.L  #TAGDATA0,A1            ; buffer address for tags
                MOVE.L  #DATABLOCK,A2           ; buffer address for sector
                MOVE.L  #$0120000,D2            ; timeout
                MOVEQ   #10,D3                  ; retry
                MOVEQ   #3,D4                   ; threshold count

                JSR     $00FE0090               ; Call ROM to do a ProFile read - not sure if this is in early ROM's!

*;                                              *; D0=return value 0=OK
*;                                              *; D1=4 error bytes

                MOVE.L D0,RESULT
                MOVE.L D1,RESD1

                RTS

         END            $22000           *     End of assembly


