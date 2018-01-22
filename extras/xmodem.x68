*-----------------------------------------------------------------------------
* Lisa XMLoader - Copyright (C) 2005, by Ray Arachelian, All Rights Reserved
*
*                A Part of the Lisa Emulation Project
*
* Small program meant to fit within 512 bytes of a boot sector to open up
* remote access to a Lisa via a serial port B by using the well known
* X-Modem protocol by Ward Christensen.
*
* This is optimized for SPACE, not for speed!  It's not a nice friendly
* program, it's meant as a loader for code sent over a serial port
* from another computer connected by null modem cable at 57600,N,8,1 ASCII
*
* This code is incompatible with nanoBug, but serves as a quicker, safer loader
* program, where nanoBug can be used interactively.
*
* Why should this fit within the 1st 512bytes?  Incase you either have a Lisa 1
* or a Lisa with a broken floppy, but do have a Widget/ProFile hard drive that
* you need access to, you can enter service mode and manually type in this code
* in hex, and execute it.  Yes, that is quite ugly and evil, but, if you're
* careful and do it right, you only need to do it once in order to image your
* hard disk and gather information about your Lisa.
*
* It is, of course, far more efficient to load all the needed code from a
* floppy, but, see the above paragraph again, typing 512 bytes is better than
* several hundred KB. :)
*
*------------------------------------------------------------------------------

* TODO - enable hardware handshaking here!


                ORG     $20000               * E68K uses 7000, Lisa Boot uses  20000
*               LOAD    $20000

START           EQU             *


*       Main Program

STARTUP          ORI #$2700,SR
                 MOVE.L #$21000,A7           * Setup stack
                 BSR EJECT
                 BSR INITSCC
                 BSR XMINIT

RESTART          MOVE.L #$00022000,A0
                 MOVE.L #$00080000,A1        * Max 512KB

CONTRCV          BSR XMGETBLK
                 TST.B D0
                 BMI RESTART                 * If we got a cancel, start over
                 BNE CONTRCV                 * If we didn't finish, get the next block
                 JMP $00022000               * If we're done, execute

* <soh> 01H - Start of header
* <eot> 04H - end of transmission
* <ack> 05H - Acknowledge
* <nak> 15H - Negative Ack
* <can> 18H - cancel

XMINIT          MOVE.L  D0,-(A7)
                MOVE.L #1,D0
                MOVE.L D0,XMBLKNUM
                CLR.L D0
                MOVE.L  (A7)+,D0
                RTS

* Receive an XModem block
*
*
* outputs:  D0=FF means cancel, D0=00 means done with file, D0=01 means got a block successfully
*           A0 is the current data pointer is returned/reset as needed so can be re-used.
* input:    global vars and A0 which is pointer to buffer gets updated.
*
*******************************************************************************************************

XMGETBLK        MOVEM.L  A2/D1-D7,-(A7)
                CLR.L  D4
                MOVE.L A0,A2                * save A0 incase we have to restart

XMGET1          BSR POLLSCC                 * get a character
                TST.L D1
                BEQ  XMGET1                 * did we get it without a timeout?

                ADDQ.L #1,D4
                CMP #10,D4
                BEQ XMCANCEL

XMGNAK          MOVE.B #$15,D0              * send NAK
                BSR  SCCOUT
                MOVE.L A2,A0                * restore A0
                BRA  XMGET1                 * start over

XMCANCEL        MOVE.B #$18,D0
                BSR SCCOUT
                BSR SCCOUT
                BSR SCCOUT
                MOVE.L #$FF,D0
                BRA XMGETFIN

XMGET2          CMP.B  #$04,D0               * did we get an EOT?
                BNE  XMGET3
                CLR.L D0                     * signal end of transmission
                BRA  XMGETFIN

XMGET3          CMP.B  #$18,d0               * did we get a cancel
                BNE  XMGET4

                BSR    POLLSCC               * wait for a 2nd one to be sure it's not line noise
                TST.L  D1
                BNE    XMGNAK
                CMP.B  #$18,D0
                BEQ XMCANCEL


XMGET4          CMP.B  #$01,D0               * expect SOH, if not send NAK
                BNE    XMGNAK

                BSR    POLLSCC               * expect the block #
                TST.L  D1
                BNE    XMGNAK

                MOVE.L D0,D2                 * save the block #

                BSR    POLLSCC               * expect the 1's complimented block #
                TST.L  D1
                BNE    XMGNAK

                ADD.B  D0,D2
                CMP.B  #$FF,D2
                BNE    XMGNAK                * if they don't match, NAK

                CLR.L  D2                    * if the block # doesn't match what we expect, cancel, we're out of sync
                MOVE.B D0,D2

                MOVE.L D3,XMBLKNUM           * Was the previous block resent? If so the sender didn't get our ACK, accept it.
                SUBQ.L #1,D3
                CMP.L  D2,D3
                BNE    XMGNXBK

                MOVE.L D3,XMBLKNUM           * Fix up the block #
                SUBA   #128,A0               * roll back pointers
                MOVE.L A0,A2                 * and save it
                BRA    XMGACCEPT             * and allow sender to resend the previous block

XMGNXBK         ADDQ.B #1,D3                 * undo block# substraction
                CMP.L  D2,D3
                BNE XMCANCEL

XMGACCEPT       MOVE.L #127,D2               * D2=number of bytes to read
                CLR.L  D3                    * D3=running checksum

XMGNEXTBYTE     BSR    POLLSCC               * get a byte
                TST.L  D1
                BNE    XMGNAK

                MOVE.B D0,(A0)+

                CMPA.L A0,A1
                BLT    XMCANCEL              * overflow

                ADD.B  D0,D3                 * checksum

                DBRA   D2,XMGNEXTBYTE

                BSR    POLLSCC               * expect checksum
                TST.L  D1
                BNE    XMGNAK
                CMP.B  D3,D0                 * does it match?
                BNE    XMGNAK                * No? go resend the block please

                MOVE.L A0,A2                 * update the pointer

                MOVE.B #$05,D0               * send ACK, the block is good
                BSR SCCOUT

                MOVE.L XMBLKNUM,D0           * increment the block number as we expect another one
                ADD.L #1,D0
                AND.L #$000000FF,D0
                MOVE.L D0,XMBLKNUM

                MOVE.L #1,D0                 * signal that we received one block

XMGETFIN        MOVEM.L  A2/D1-D7,-(A7)
                RTS




POLLSCC         MOVEM.L A0-A6/D2-D7,-(A7) * save regs
                BSR GETSCCPORT
                CLR.L   D1            * clear timeout
PSCCINW
                ADDQ    #1,D1
                CMP.L   #$00150000,D1 * about 10 seconds
                BGE     RTSREST1

                BTST    #0,(A4)       * wait for data to arrive
                BEQ PSCCINW

                CLR.L   D1
                MOVE.L  (A7),(A7)     * delay a bit
                MOVE.B  (A3),D0       * read the data

RTSREST1        MOVEM.L (A7)+,A0-A6/D2-D7       * Save this for move mems that exclude d0
                RTS

EJECT           MOVE.L #$FCC000,A0
                MOVE.L #$81810202,(A0)
                BRA INITSCC           * was r,t,s - suspect a 2nd init will help

GETSCCPORT      MOVE.L #$FCD245,A3    * Port B Data       ** or  0xFCD247 for port A Control
                MOVE.L #$FCD241,A4    * Port B Control    ** or  0xFCD243 for port A Control
                RTS

SCCOUT          MOVEM.L A0-A6/D1-D7,-(A7)
                BSR GETSCCPORT
XSCCOUTW        BTST    #2,(A4)      * wait for xmit buffer to be ready
                BEQ XSCCOUTW
                MOVE.L  (A7),(A7)    * delay a bit
                MOVE.B D0,(A3)       * write the byte
                BRA RTSREST1         * done

SCCINITDATA     DC.B   2,$00          ;* 2 disable SCC IRQ's
                DC.B   9,$00          ;* 4 disable SCC IRQ's
                DC.B   4,$4           ;* 6 x16 clk, 1 stop bits, no parity
                DC.B  11,$50          ;* 8 baud rate gen enable rx/tx
                DC.B  12,$21          ;* 10 low  TC port B:  9600: 0xCE:C6-D7  19200: 66:62-6A
*                                     ;*                    38400: 0x32:30-34  57600: 20:1f-22
                DC.B  13,$00          ;* 12 high TC 0 for 9600 and above
                DC.B  14,$03          ;* 14 baud rate generator             ; 76543210
                DC.B   3,$C1          ;* 16 8bits/char on receiver, enable  ; 11000001=C1, with AutoEnable=11100001=E1
                DC.B   3,$E1          ;* 18 8bits/char on receiver, enable  ; 11000001=C1, with AutoEnable=11100001=E1
                DC.B   5,$68          ;* 20 DTR low, 8 bits/char xmit, enable

INITSCC         BSR GETSCCPORT
                MOVE.B (A4),D0       * make sure SCC is sync'ed up
                LEA SCCINITDATA,A0   * get

                MOVE.W #18,D0        * count of bytes in SCCINITDATA above to send  *** change me

XINITSC1        MOVE.L (A7),(A7)     * DELAY
                MOVE.B (A0)+,(A4)    * output the data
                DBRA  D0,XINITSC1
                RTS




*; Global variables

XMBLKNUM        DC.L $00000001           * current block number
XMADDR          DC.L $00000000           * address of data to send/receive from





***********************************************************************************
* XModem Send Memory
*
* This routine sends a block of data in the Lisa's memory over the serial port
* using the XModem protocol.
*
* Inputs: D0-start address, D1-end address
* outputs: D0=0 success, D0=FF-canceled, A0=last address send
*
***********************************************************************************

XMSENDMEM       MOVE.L D0,A0              * A0 is the current block expected
XMSR            CMP.L D1,A0               * Did we reach the end?
                BEQ XMSENDFIN             * Yes, send EOT, this returns 0 in D0
                BSR XMSENDBLK             * otherwise send the current block
                CMP.B #0,D0               * was the current block sent successfully?
                BEQ XMSR                  * Yes, continue with the next block.
                RTS                       * If we got here, xfer was canceled, D0=ff


************************************************************************************
* XModem Send Block
*
* This chunk does not have to be included in the loader code, but is useful
* once the loader starts up.
*
*
* Send an Xmodem Block.  A0 is a pointer to the buffer to send.
* Outputs: D0=0 if the block was sent successful, the caller then needs to
*          either signal an EOT, or send the next block.
*          newly updated A0=buffer address
* Inputs:  A0 = buffer to data to send.
*
************************************************************************************

XMSENDBLK       MOVEM.L A2/D1/D3,-(A7)   * save registers
                MOVE.L  A0,A2            * save pointer incase we get a NAK

XMSRESEND       MOVE.L  A2,A0            * restore if we got a NAK, or just starting

                MOVE.B  #1,D0            * Send SOH
                JSR     SCCOUT

                MOVE.L  XMBLKNUM,D0      * Send the block number
                JSR     SCCOUT

                NEG.L   D0               * send the compliment of the block number
                JSR     SCCOUT

                MOVE.L  #127,D1          * number of bytes to send
                CLR.L   D3

XMSND1          MOVE.B  (A0)+,D0         * loop over the buffer sending the bytes
                ADD.B   D0,D3            * keep running checksum
                JSR     SCCOUT
                DBRA    D1,XMSND1

                MOVE.B  D3,D0            * send checksum
                JSR     SCCOUT

                BSR    POLLSCC           * wait for ACK/Cancel/etc.
                TST.L  D1
                BNE    XMSRESEND

                CMP.B  #$05,D0           * Got Ack, continue on
                BNE    XMS2

                MOVE.L XMBLKNUM,D0       * increment the block number, so we can do the next one
                ADD.B #1,D0
                AND.L #$000000FF,D0
                MOVE.L D0,XMBLKNUM

                CLR.L  D0                * signal that all is good
                BRA XMSDONE

XMS2            CMP.B  #$15,D0           * Got back NAK
                BRA    XMSRESEND

                CMP.B  #$18,D0           * Did we get CANCEL?
                BNE    XMSRESEND         * got garbage instead, resend

                BSR    POLLSCC           * wait for 2nd CANCEL
                TST.L  D1
                BNE    XMSRESEND
                CMP.B  #$18,D0           * Got Confirmation of cancel?
                BNE    XMSRESEND         * no, was line noise
                MOVE.L #$FF,D0           * yes, we really did get a cancel, flag error
                MOVE.L A2,A0

XMSDONE         MOVEM.L  (A7)+,A2/D1/D3  * return to caller
                RTS

*****************************************************************************
* XModem Send End of File to signal successful upload
*
*****************************************************************************
XMSENDFIN       MOVE.B #$4,D0
                BSR SCCOUT
                BSR SCCOUT
                BSR SCCOUT
                BSR SCCOUT
                CLR.L D0          * Return 0 indicating successful xfer
                RTS



***********************************************************************************
* XModem Send ROM
*
* This routine sends a copy of the Lisa Boot ROM over XMODEM.
*
* I'm not a lawyer, nor play one on TV, so checking with one is highly recommended
* before using, however so long as you own the Lisa and do not distribute the ROM
* it should be fine, under fair use laws that regards educational, and historic
* librarian, and compatibility use.
*
* Source code is not a forum for legal discussions, therefore
* I will not continue further discussing this.
*
***********************************************************************************
XMSENDROM       BSR XMINIT
                MOVE.L #$00FE0000,D0
                MOVE.L #$00FE4000,D1
                BRA    XMSENDMEM



***********************************************************************************
* This block of code is 6504 code to copy a single page from ROM to the RAM
* buffer used to hold a sector.  It will store the results in the 2nd half of
* the buffer as this code will be in the 1st half.
*
* It will be repeatedly code once for each page, replacing byte at IOPGNUM
* with values #$10 to #$1f.
*
***********************************************************************************

CPIOROM  LEA    IOPGNUM,A0
         MOVE.L #$FC0000,A1

         MOVE.B #$10,(A0)              ; start at IO ROM page $10

CPI0     LEA    IORCPY,A0
         MOVE.L #$0c,D0
CPI1     MOVE.B (A0)+,D1
         EXT.W  D1                     ; Floppy RAM is on odd bytes
         MOVE.W D1,(A1)+
         DBRA   D0,CPI1

         NOP
         NOP

         ; execute
         MOVE.L #$FCC000,A0
         MOVE.L #$81810202,(A0)

         ; need a delay here
         ; copy page to buffer

         ; Setup to copy the next page
         LEA    IOPGNUM,A0
         MOVE.B (A0),D0
         ADD.B #1,D0
         CMP.B D0,#$20
         BEQ IORCDONE
         BRA CPI0


IORCDONE RTS



IORCPY   DC.B  $a2,$00                 ;' LDX #$00         ' 0,1          6504 ROM 1000-1fff
         DC.B  $bd,$00
IOPGNUM  DC.B  $10                     ;' LDA $1000,X      '@2,3,4 overwrite from $10..$1f

         DC.B  $9d,$00,$08             ;' STA $0300,X      '5,6,7         buffer here in 2nd half of buffer
         DC.B  $e8                     ;' INX              '8
         DC.B  $d0,$f7                 ;' BNE @2           '9,a  #next opc at addr b, want 2.  b-2=9. F7
         DC.B  $60                     ;' RTS              'b    return to 6504 ROM



DUMPPROF







PREADSEC        *

;-----------------------------------------------------------------------------
;  First initialize and then ensure disk is attached by checking OCD line.
;  Assumes ACR and IER registers of VIA set up by caller.  For boot, these
;  are cleared by power-up reset.
;  Register usage:
;    D0 = scratch use           A0 = VIA address for parallel port interface
;    D1 = block to read         A1 = address to save header
;    D2 = timeout count         A2 = address to save data
;    D3 = retry count           A3 = scratch
;    D4 = threshold count       A4 = unused
;  Returns:
;    D0 = error code (0 = OK)
;    D1 = error bytes (4)
;    D2 - D7 and A1 - A6 are preserved
;-----------------------------------------------------------------------------

                MOVE.L #$9002ff80,A1            ; fill details in xmodem header blk, some text, some binary

                MOVE.L #'PROF',(A1)+            ; 80-83 fill 0th XMODEM block to send
                MOVE.L #'ILE ',(A1)+            ; 84-87 with text PROFILE BLOCK NUMBER
                MOVE.L #'BLOC',(A1)+            ; 88-8b
                MOVE.L #'K NU',(A1)+            ; 8c-8f
                MOVE.L #'MBER',(A1)+            ; 90-93  - 94-97 contains the block # to read

                MOVE.L  #$00fcdd81,A3           ; get kybd VIA base address
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

                MOVE.L  #$0002ff94,A1           ; get address of block # to read from xmodem header block
                MOVE.L  (A1),D1                 ; D1 contains block # to read

                MOVE.L  #$002ffec,A1            ; buffer address for tags
                MOVE.L  #$0030000,A2            ; buffer address for sector
                MOVE.L  #$0120000,D2            ; timeout
                MOVEQ   #20,D3                  ; retry
                MOVEQ   #3,D4                   ; threshold count
                                                ;
                MOVE.L  #$00fcd901,A0           ;       get paraport VIA base address
                JSR     $00FE0090               ; Call ROM to do a ProFile read - not sure if this is in early ROM's!

                                                ; D0=return value 0=OK
                                                ; D1=4 error bytes

                MOVE.L #$0002ff98,A1

                MOVE.L #'RETU',(A1)+            ; 98-9b
                MOVE.L #'RN V',(A1)+            ; 9c-9f
                MOVE.L #'ALUE',(A1)+            ; a0-a3
                MOVE.L #' D0:',(A1)+            ; a4-a7

                MOVE.L D0,(A1)+                 ; a8-ab

                MOVE.L #'ERRO',(A1)+            ; ac-af
                MOVE.L #'R BY',(A1)+            ; b0-b3
                MOVE.L #'TES ',(A1)+            ; b4-b7
                MOVE.L #' D1:',(A1)+            ; b8-bb
                MOVE.L D1,(A1)+                 ; bc-bf



                MOVE.L #$0002ffc0,A1            ; c0-eb junk bytes - clear'em out, ec-ef: TAGS

                CLR.L  (A1)+                    ; c0
                CLR.L  (A1)+                    ; c4
                CLR.L  (A1)+                    ; c8
                CLR.L  (A1)+                    ; cc
                CLR.L  (A1)+                    ; d0
                CLR.L  (A1)+                    ; d4
                CLR.L  (A1)+                    ; d8
                CLR.L  (A1)+                    ; dc
                CLR.L  (A1)+                    ; d0
                CLR.L  (A1)+                    ; d4
                CLR.L  (A1)+                    ; d8
                CLR.L  (A1)+                    ; dc
                CLR.L  (A1)+                    ; e0
                CLR.L  (A1)+                    ; e4

                MOVE.L #$0002ffe8,A1            ; reload to be sure I've not made an error
                MOVE.L #'TAGS',(A1)             ; e8-eb

                RTS

GETCRC          MOVE.L #$FFFF,D0                ; set CRC16 start value
                MOVE.L #$0002ff82,A0            ; pointer to data to get CRC over

GETCRC1         MOVE.W (A0)+,D1
                BSR CRC16
                CMP #$00030200,A1
                BNE GETCRC1


*;                                              ; CRC16  D0.W=CRC D1.W=DATA D2 trashed
CRC16:                  MOVE.W D0,D2            ; swap16 D0 (CRC) - wonder if ROL.W #8,D2 would work better?
			LSR.W #8,D2
			LSL.W #8,D0
			CLR.B D0
                        OR.B D2,D0

                        EOR.W D1,D0             ; CRC=SWAP16(CRC)^DATA

                        CLR.W D2                ; CRC=CRC^((CRC & 0x00f0)>>4)
			MOVE.B D0,D2
			LSR.B #4,D2
			AND.W #$00F0,D2
			EOR.W D2,D0

                        MOVE.W D0,D2            ; crc^=(crc<<12);
			LSL.W #12,D2
			AND.W #$0FF0,D2
			EOR.W D2,D0

                        MOVE.W D0,D2            ; return crc^(((crc & 0x00ff)<<4)<<1);
			AND.W #$00ff,D2
			LSL.W #4,D2
			LSL.W #1,D2
			EOR.W D0,D2

			RTS



         END            $20000           *     End of assembly
