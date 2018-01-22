*-----------------------------------------------------------------------------
* Lisa nanoBug scc test - Copyright (C) 2005, by Ray Arachelian,
*                          All Rights Reserved
*               A Part of the Lisa Emulation Project
*
* Small program meant to fit within 512 bytes of a boot sector and attempt
* various serial port settings in order to do testing for nanoBug, quick and dirty
* don't care about anything, butt ugly one time use hack of the day
*
*------------------------------------------------------------------------------


                ORG     $20000               * E68K uses 7000, Lisa Boot uses  20000
*               LOAD    $20000

START           EQU             *


*       Main Program

STARTUP          ORI #$2700,SR
                 MOVE.L #$21000,A7           * Setup stack
                 BSR EJECT

NEXTBPS           BSR INITSCC
                  NOP
                  NOP
                  NOP
                  NOP
                  BSR NEWLINE
                  BSR NEWLINE

                  LEA BAUDHIGH,A0
                  MOVE.B (A0),D0
                  LSL.L #8,D0
                  LEA BAUDLOW,A0
                  MOVE.B (A0),D0

                  CMP.W #1665,D0
                  BGT  NEXTPORT

                  BSR PRHX4

                  MOVE.B #' ',D0
                  BSR SCCOUT
                  LEA PORTNUM,A0
                  MOVE.B (A0),D0
                  ADD.B #'A',D0
                  BSR SCCOUT
                  BSR NEWLINE
                  BSR NEWLINE

                  LEA BAUDLOW,A0
                  MOVE.B (A0),D0
                  ADDQ #1,D0
                  MOVE.B D0,(A0)
                  CMP.B #00,D0
                  BNE NEXTBPS

                  LEA BAUDHIGH,A0
                  MOVE.B (A0),D0
                  ADDQ #1,D0
                  MOVE.B D0,(A0)
                  CMP.B #00,D0
                  BNE NEXTBPS

NEXTPORT        LEA PORTNUM,A0
                MOVE.B (A0),D0
                EOR.B #1,D0
                MOVE.B D0,(A0)

                LEA BAUDHIGH,A0
                LEA BAUDLOW,A1
                MOVE.B #$00,(a0)
                MOVE.B #$00,(a1)
                JMP NEXTBPS



PRINTHEXBYTE     MOVEM.L A0-A6/D0-D7,-(A7)  * Save all regs

                 MOVE.L D0,D3               * Save the value to print
                 LSR #4,D0                  * top nibble
		 BSR OUTHEXNIB

                 MOVE.B D3,D0               * restore it & print the low nibble
		 BSR OUTHEXNIB

RTSREST          MOVEM.L (A7)+,A0-A6/D0-D7  * restore regs and return  * several routines use this!
		 RTS



* common code used by PRINTAT - print an address
PRHX4            MOVE.L D0,D7
                 SWAP D0                    * 0th byte
		 LSR.L #8,D0
		 BSR PRINTHEXBYTE

                 MOVE.L D7,D0               * 1st byte
		 SWAP D0
		 BSR PRINTHEXBYTE

                 MOVE.L D7,D0               * 2nd byte
		 LSR.L #8,D0
		 BSR PRINTHEXBYTE

                 MOVE.L D7,D0               * 3rd byte
		 BRA PRINTHEXBYTE


* Print LFCR
NEWLINE
PRINTPROMPT      MOVE.B #10,D0
                 BSR SCCOUT
                 MOVE.B #13,D0
                 BRA SCCOUT



OUTHEXNIB       LEA HEXTEXT,A5
                MOVE.W D0,D4
                AND.W #15,D0
                MOVE.B 0(A5,D0.W),D0
                BSR SCCOUT
                MOVE.W D4,D0
                RTS


HEXTEXT   DC.B  '0123456789ABCDEF'
PORTNUM   DC.B  01

* not sure this will work on 68000 81810202 -> FCC000

EJECT           MOVE.L #$FCC000,A0
                MOVE.L #$81810202,(A0)
                RTS

GETSCCPORT      LEA PORTNUM,A3
                CMP.B #$00,(A3)
                BEQ GETSCCPRTA
                MOVE.L #$FCD245,A3    * Port B Data       ** or  0xFCD247 for port A Control
                MOVE.L #$FCD241,A4    * Port B Control    ** or  0xFCD243 for port A Control
                RTS

GETSCCPRTA      MOVE.L #$FCD247,A3    * Port A Data
                MOVE.L #$FCD243,A4    * Port A Control
                RTS


SCCOUT          MOVEM.L A0-A6/D1-D7,-(A7)
                BSR GETSCCPORT
XSCCOUTW        BTST    #2,(A4)      * wait for xmit buffer to be ready
                BEQ XSCCOUTW
                MOVE.L  (A7),(A7)    * delay a bit
                MOVE.B D0,(A3)       * write the byte
                MOVE.L  (A7),(A7)    * delay a bit
                MOVEM.L (A7)+,A0-A6/D1-D7
                RTS

SCCINITDATA     DC.B   2,$00          * 2 disable SCC IRQ's
                DC.B   9,$00          * 4 disable SCC IRQ's
                DC.B   4,$4           * 6 x16 clk, 1 stop bits, no parity
                DC.B  11,$50          * 8 baud rate gen enable rx/tx
                DC.B  12
BAUDLOW         DC.B  00              *10 low  TC for 9600 is 10 - change to 11 if on port A
                DC.B  13
BAUDHIGH        DC.B  00              *12 high TC for 9600 is 0
                DC.B  14,$03          *14 baud rate generator
                DC.B   3,$C1          *16 8bits/char on receiver, enable
                DC.B   5,$68          *18 DTR low, 8 bits/char xmit, enable


INITSCC         MOVEM.L A0-A6/D0-D7,-(A7)  * Save all regs
                BSR GETSCCPORT
                MOVE.B (A4),D0       * make sure SCC is sync'ed up
                LEA SCCINITDATA,A0   * get

                MOVE.W #18,D0        * count of bytes in SCCINITDATA above to send  *** change me

XINITSC1        BSR GETSCCPORT       * delay
                MOVE.L (A7),(A7)     * DELAY
                MOVE.L (A7),(A7)     * DELAY
                MOVE.B (A0)+,(A4)    * output the data
                DBRA  D0,XINITSC1

                MOVEM.L (A7)+,A0-A6/D0-D7
                RTS




* ****************************************** Padding to go upto 512 bytes
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP


*   Junk code for testing E68K environment
*   **************************************** Replace these for Lisa **152 bytes left for Z8530 SCC routines****
E68KSCCOUT          MOVEM.L A0-A6/D0-D7,-(A7)  * Save all regs
                MOVE.B D0,D1
                MOVE.B #6,D0
                TRAP #15
                BRA RTSREST

E68KREADSCC     MOVEM.L A0-A6/D1-D7,-(A7)

E68KRDSCC1      MOVE.B #7,D0             * 7 : Set D1.B to 1 if keyboard input is pending, otherwise set to 0.
                TRAP #15
                BTST #0,D1
                BEQ E68KRDSCC1

                MOVE.B #5,D0             * 5 : Read single char from keyboard into D1.B.
                TRAP #15

                MOVE.B D1,D0             * Copy it to D0, and restore the other regs
                MOVEM.L (A7)+,A0-A6/D1-D7
                RTS

E68KINITSCC
                MOVE.B #13,D0
                BSR SCCOUT
                RTS


BUFF            DC.B  $4e,$75,$4e,$75,$4e,$75,$4e,$75,$4e,$75

         END            $20000           *     End of assembly
