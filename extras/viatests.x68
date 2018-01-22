*;-----------------------------------------------------------------------------
*; VIA Tests
*;
*; A loadable module for nanoBug
*;
*; Lisa nanoBug - Copyright (C) 2005, by Ray Arachelian, All Rights Reserved
*;               A Part of the Lisa Emulation Project
*;
*; This codes provides a very primitive trap system for exception handling such
*; that we can save the registers and print them out, then restart nanoBug.
*; doesn't do much else.
*;
*; As this code is loaded in by nanoBug, it's not quite as tight on space as
*; nanoBug itself is.
*;
*; The purpose of this code is to allow nanoBug to capture VIA and memory timing.
*;
*;------------------------------------------------------------------------------

                ORG     $22000                  * Addon to nanoBug
*               LOAD    $22000

START           EQU             *


                BRA VITATEST


* * ******** Subroutines and extra tests **************************************************


* some subs for this code

PRINTD          MOVE.B #'D',D0              * print D
                JMP    $000201A4

PRINTA          MOVE.B #'A',D0              * print A
                JMP    $000201A4

PRINTCOLON      MOVE.B #':',D0              * print d4:
                JMP    $000201A4

PRINTDASH       MOVE.B #'-',D0                     * print d4:
                JMP    $000201A4


TWONEWLINES     JSR $00020138                      * print newline
                JMP $00020138                      * print newline

PRINTTEXT:      MOVEM.L   A0-A6/D0-D7,-(A7)        * save regs
PRNTNXT         MOVE.B    (A0)+,D0                 * get the char
                TST.B     D0
                BEQ       PRTXEND                  * end on null
                JSR       $000201A4                * print the character (SCCOUT)
                BRA       PRNTNXT
PRTXEND         MOVEM.L   (A7)+,A0-A6/D0-D7
                RTS



VIACLRIRQ       MOVE.B #$7f,D5
                ORI #$2700,SR                      * Disable IRQ's
                MOVE.B D5,$00FCE018                * Disable VTIR as we'll enable IRQ1 later.

                MOVE.L #$FCC000,A0
                MOVE.L #$8585ffff,(A0)             * tell the floppy controller to clear any IRQ's (i.e. post eject)

                MOVE.B D5,$FCDD9D                  * Disable all IRQ's on VIA1
                MOVE.B D5,$FCD971                  * Disable all IRQ's on VIA2

                RTS



VITATEST        LEA   VIA2ISR,A0
                MOVE.L A0,$64                      * hook up our vector handler
                BSR   VIACLRIRQ                    * clear any pending IRQ's
                MOVE.L A7,A6                       * Save stack register for ISR to restore

                CLR.L   D7                         * Set Test # to perform to test 0

                CLR.L   D0                         * initial pre-value to write to T2 (will be incremented 3 opcodes from now)

VIATNXT         LEA  VIATXT,A0
                JSR  PRINTTEXT

                ADD.B     #$10,D0                   * Update timer value

                CMP.B     #$50,D0                   * finished this test? go on to the next one
                BEQ       VIATDONE                 * don't want to do too many as it'll be too slow


                MOVEM.L   A0-A6/D0-D7,-(A7)        * print the timer value we're about to use
                JSR       $000200E0
                MOVEM.L   (A7)+,A0-A6/D0-D7

                CLR.L  D1                          * Clear cyle counter
                MOVE.L A7,A6                       * Save stack register for ISR to restore

                MOVE.L #$00030000,A3               * use regular memory for access, not vidram for tests 1-3.

                CMP.B  #0,D7
                BEQ    VIATEST0

                CMP.B  #1,D7
                BEQ    VIATEST1

                CMP.B  #2,D7
                BEQ    VIATEST2

                CMP.B  #3,D7
                BEQ    VIATEST3

                MOVE.L #$0F8000,A3                 * use vidram to expose any extra wait cycles on shared cpu-video ram on 4-6

                CMP.B  #4,D7
                BEQ    VIATEST1

                CMP.B  #5,D7
                BEQ    VIATEST2

                CMP.B  #6,D7
                BEQ    VIATEST3


VIATEST0        BSR    VIACLRIRQ                   * clear pending IRQ's

                MOVE.B #$A0,D5
                MOVE.B D5,$FCD971                  * enable Timer2 on VIA2
                MOVE.L #$deadbeef,D1               * sentinel value incase IRQ gets fired here
                MOVE.W #$2000,SR                   * Enable IRQ's

                NOP                                ;* MOVE.B D1,$FCD941        * write T2Low  (cycle counter D1 is 0 already)
                CLR.L D1

                MOVE.B D0,$FCD949                  * Write T2High
VIATLOP0        ADDQ.L #1,D1                       * increment count
                BRA VIATLOP0                       * and keep going until interrupted by IRQ1


VIATEST1        BSR    VIACLRIRQ
                MOVE.B #$A0,D5
                MOVE.B D5,$FCD971                  * enable Timer2 on VIA2
                MOVE.W #$2000,SR                   * Enable IRQ's

                MOVE.B D0,$FCD949                  * Write T2High
VIATLOP1        ADDQ.L #1,D1
                MOVE.B (A7),(A7)                   * access VID/RAM - delta between test 0,1 will tell us ram waits
                BRA VIATLOP1

VIATEST2        BSR    VIACLRIRQ
                MOVE.B #$A0,D5
                MOVE.B D5,$FCD971                  * enable Timer2 on VIA2
                MOVE.W #$2000,SR                   * Enable IRQ's


                MOVE.B D0,$FCD949
VIATLOP2        ADDQ.L #1,D1
                MOVE.W (A7),(A7)                   * same as test 1, but with word instead of byte
                BRA VIATLOP2

VIATEST3        BSR    VIACLRIRQ
                MOVE.B #$A0,D5
                MOVE.B D5,$FCD971                  * enable Timer2 on VIA2
                MOVE.W #$2000,SR                   * Enable IRQ's


                MOVE.B D0,$FCD949
VIATLOP3        ADDQ.L #1,D1
                MOVE.L (A7),(A7)                   * same as test 1, but with long
                BRA VIATLOP3



VIATDONE        MOVE.W #$2700,SR
                BSR    VIACLRIRQ
                CLR.L D0                          * reset value to feed timer back to zero for next test.

                ADD.B #1,D7                       * see if there are further tests
                CMP.B #7,D7                       * 0=no mem, 1=B, 2=W, 3=L,4=VIDRAM Byte, 5=VIDRAMW, 6=VIDRAML, 7=DONE
                BEQ VIATDN1

                LEA  VTNXTXT,A0
                JSR  PRINTTEXT

                MOVE.B  D7,D0
                ADD.B  #'0',D0
                JSR    $000201A4
                JSR    TWONEWLINES
                JMP    VIATNXT

VIATDN1         MOVE.W #$2700,SR                   * disable IRQ's
                BRA    VIACLRIRQ                   * clear pending IRQ's and return to nanoBug


VIA2ISR         ORI #$2700,SR                      * Disable all IRQ's
                MOVE.L A6,A7                       * Restore the stack, discarding stuff IRQ wrote

                MOVEM.L   A0-A6/D0-D7,-(A7)        * save regs

                BSR PRINTCOLON

                MOVE.L    D1,D0                    * copy count from D1 to D0, so it can be printed
                JSR       $000200E0                * print the cycles counted for the timer value
                JSR       $00020138                * print a newline
                BSR       VIACLRIRQ                * clear IRQ's

                MOVEM.L   (A7)+,A0-A6/D0-D7        * restore regs

                JMP    VIATNXT                     * continue with the next test


* Variables we store

VTNXTXT         DC.B 13,10,10,'VIA Memory Test # (1=B, 2=W, 3=L, 4=VIDRAMB, 5=VIDRAMW, 6=VIDRAML):',0

VIATXT          DC.B 'VIAT2H:CYCLES - ',00

         END            $22000           *     End of assembly
