*;-----------------------------------------------------------------------------
*; nanoBug exception Vector trapping extension
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
*; The purpose of this code is to allow nanoBug to recover from Address, BUS,
*; and NMI exceptions.  Since nanoBug is so tiny, there's no room for any ISR's
*; so, this code implements them.  (Now you know why the default start address
*; for uploadable code is 22000 and not immediately after nanoBug itself.)
*;
*;
*;------------------------------------------------------------------------------

                ORG     $20200                  * Addon to nanoBug
*               LOAD    $20200

START           EQU             *


*       Main Program
*       Setup exception vectors and return to nanoBug

INITVEC         LEA  BUSERR,A0
                MOVE.L A0,$8

                LEA  ADRERR,A0
                MOVE.L A0,$C

                LEA  NMI,A0
                MOVE.L A0,$7C

                LEA  ILLGL,A0                  * send illegal instructions and others here
                MOVE.L A0,$10

                LEA  SPURI,A0                  * Spurious
                MOVE.L A0,$60

                LEA  FLINE,A0                  * A or F line
                MOVE.L A0,$28
                MOVE.L A0,$2C

                LEA  AUTOVEC,A0
                MOVE.L A0,$64
                MOVE.L A0,$68
                MOVE.L A0,$6c
                MOVE.L A0,$70
                MOVE.L A0,$74
                MOVE.L A0,$78


                LEA  OTHER,A0
                MOVE.L A0,$14
                MOVE.L A0,$1C
                MOVE.L A0,$20
                MOVE.L A0,$24
                MOVE.L A0,$60

                LEA  LOADED,A0
                JSR  PRINTTEXT


                JMP  FILLMEM

* * * ********************** Vector Traps **********************************************************
BUSERR          MOVE.L D0,TNUMD0
                CLR.L D0
                MOVE.B #'B',D0
                MOVE.W D0,TNUMHIT
                JMP SAVEREGS

ADRERR          MOVE.L D0,TNUMD0
                CLR.L D0
                MOVE.B #'A',D0
                MOVE.W D0,TNUMHIT
                JMP SAVEREGS

ILLGL           MOVE.L D0,TNUMD0
                CLR.L D0
                MOVE.B #'I',D0
                MOVE.W D0,TNUMHIT
                JMP SAVEREGS

FLINE           MOVE.L D0,TNUMD0
                CLR.L D0
                MOVE.B #'F',D0
                MOVE.W D0,TNUMHIT
                JMP SAVEREGS


SPURI           MOVE.L D0,TNUMD0
                CLR.L D0
                MOVE.B #'S',D0
                MOVE.W D0,TNUMHIT
                JMP SAVEREGS

AUTOVEC         MOVE.L D0,TNUMD0           * catchall for autovectors - should expand this perhaps
                CLR.L D0
                MOVE.B #'V',D0
                MOVE.W D0,TNUMHIT
                JMP SAVEREGS

OTHER           MOVE.L D0,TNUMD0
                CLR.L D0
                MOVE.B #'?',D0              * should expand this out to individual exception handlers
                MOVE.W D0,TNUMHIT
                JMP SAVEREGS



NMI             MOVE.L D0,TNUMD0
                CLR.L D0
                MOVE.B #'N',D0
                MOVE.W D0,TNUMHIT         * fall through on this one to save a few bytes

SAVEREGS        MOVE.W SR,D0                * SR is on the stack anyway, so no worries that the above
                MOVE.W D0,TNUMSR            * moves whacks N,Z flags
                ORI #$2700,SR               * Reset SR to what we want
                MOVE.L #$21000,A7           * Setup stack to what we want

                MOVE.L D1,TNUMD1
                MOVE.L D2,TNUMD2
                MOVE.L D3,TNUMD3
                MOVE.L D4,TNUMD4
                MOVE.L D5,TNUMD5
                MOVE.L D6,TNUMD6
                MOVE.L D7,TNUMD7

                MOVE.L A0,TNUMA0
                MOVE.L A1,TNUMA1
                MOVE.L A2,TNUMA2
                MOVE.L A3,TNUMA3
                MOVE.L A4,TNUMA4
                MOVE.L A5,TNUMA5
                MOVE.L A6,TNUMA6
                MOVE.L A7,TNUMA7

                MOVE.B #'T',D0              * print the trap # as T:3
                JSR    $000201A4
                JSR     PRINTCOLON
                MOVE.W TNUMHIT,D0           * add the trap #
                JSR    $000201A4            * print it

                JSR    TWONEWLINES


                JSR     PRINTD
                MOVE.B #'0',D0
                JSR    $000201A4
                JSR     PRINTCOLON
                MOVE.L TNUMD0,D0
                JSR    $000200E0            * print the value prhx4
                JSR    $0002014E            * print a space

                JSR     PRINTD
                MOVE.B #'1',D0
                JSR    $000201A4
                JSR     PRINTCOLON
                MOVE.L TNUMD1,D0
                JSR    $000200E0            * print the value prhx4
                JSR    $0002014E            * print a space

                JSR     PRINTD
                MOVE.B #'2',D0
                JSR    $000201A4
                JSR     PRINTCOLON
                MOVE.L TNUMD2,D0
                JSR    $000200E0            * print the value
                JSR    $0002014E            * print a space

                JSR     PRINTD
                MOVE.B #'3',D0
                JSR    $000201A4
                JSR     PRINTCOLON
                MOVE.L TNUMD3,D0
                JSR    $000200E0            * print the value
                JSR    $0002014E            * print a space

                JSR     PRINTD
                MOVE.B #'4',D0
                JSR    $000201A4
                JSR     PRINTCOLON
                MOVE.L TNUMD4,D0
                JSR    $000200E0            * print the value
                JSR    $0002014E            * print a space

                JSR     PRINTD
                MOVE.B #'5',D0
                JSR    $000201A4
                JSR     PRINTCOLON
                MOVE.L TNUMD5,D0
                JSR    $000200E0            * print the value
                JSR    $0002014E            * print a space

                JSR     PRINTD
                MOVE.B #'6',D0
                JSR    $000201A4
                JSR     PRINTCOLON
                MOVE.L TNUMD6,D0
                JSR    $000200E0            * print the value
                JSR    $0002014E            * print a space

                JSR     PRINTD
                MOVE.B #'7',D0
                JSR    $000201A4
                JSR     PRINTCOLON
                MOVE.L TNUMD7,D0
                JSR    $000200E0            * print the value
                JSR    $00020138            * print newline

* Now it's time to print the address registers

                JSR     PRINTA
                MOVE.B #'0',D0
                JSR    $000201A4
                JSR     PRINTCOLON
                MOVE.L TNUMA0,D0
                JSR    $000200E0            * print the value
                JSR    $0002014E            * print a space

                JSR     PRINTA
                MOVE.B  #'1',D0
                JSR     $000201A4
                JSR     PRINTCOLON
                MOVE.L  TNUMA1,D0
                JSR     $000200E0           * print the value
                JSR     $0002014E           * print a space

                JSR     PRINTA
                MOVE.B  #'2',D0
                JSR     $000201A4
                JSR     PRINTCOLON
                MOVE.L  TNUMA2,D0
                JSR     $000200E0           * print the value
                JSR     $0002014E           * print a space

                JSR     PRINTA
                MOVE.B  #'3',D0
                JSR     $000201A4
                JSR     PRINTCOLON
                MOVE.L  TNUMA3,D0
                JSR     $000200E0           * print the value
                JSR     $0002014E           * print a space

                JSR     PRINTA
                MOVE.B  #'4',D0
                JSR     $000201A4
                JSR     PRINTCOLON
                MOVE.L  TNUMA4,D0
                JSR     $000200E0           * print the value
                JSR     $0002014E           * print a space

                JSR     PRINTA
                MOVE.B  #'5',D0
                JSR     $000201A4
                JSR     PRINTCOLON
                MOVE.L  TNUMA5,D0
                JSR     $000200E0           * print the value
                JSR     $0002014E           * print a space

                JSR     PRINTA
                MOVE.B  #'6',D0
                JSR     $000201A4
                JSR     PRINTCOLON
                MOVE.L  TNUMA6,D0
                JSR     $000200E0           * print the value
                JSR     $0002014E           * print a space

                JSR     PRINTA
                MOVE.B #'7',D0
                JSR     $000201A4
                JSR     PRINTCOLON
                MOVE.L  TNUMA7,D0
                JSR     $000200E0           * print the value
                JSR     $00020138           * print newline

* now print the values off the stack, as these were pushed by the exception


                JMP NOTBUS                  * bug somewhere in here, so skip over it, if A7 points to invalid RAM, this dies

                MOVE.L  TNUMA7,A6
                MOVE.W  TNUMHIT,D0
                CMP.B   #'B',D0
                BEQ     ISBUS
                CMP.B   #'A',D0
                BNE     NOTBUS

ISBUS           LEA     BUSFN,A0            * Bus function Word
                JSR     PRINTTEXT
                CLR.L   D0
                MOVE.W  (A6)+,D0
                JSR     $000200E0           * print the value
                JSR     $00020138           * print newline

                LEA     ADRER,A0            * ADDRESS ERROR LONG
                JSR     PRINTTEXT
                MOVE.L  (A6)+,D0
                JSR     $00200E0            * print the value
                JSR     $00020138           * print newline


                LEA     IRREG,A0            * Instruction register word
                JSR     PRINTTEXT
                CLR.L   D0
                MOVE.W  (A6)+,D0
                JSR     $000200E0           * print the value
                JSR     $00020138           * print newline

NOTBUS          LEA     STATREG,A0          * Status register word
                JSR     PRINTTEXT
                CLR.L   D0
                MOVE.W  (A6)+,D0
                JSR     $000200E0           * print the value
                JSR     $00020138           * print newline


                LEA     PCTEXT,A0           * program counter
                JSR     PRINTTEXT
                MOVE.L  (A6)+,D0
                JSR     $000200E0           * print the value
                JSR     $00020138           * print newline

                LEA     MEALTCH,A0          * print the contents of the memory error latch
                JSR     PRINTTEXT
                CLR.L   D0
                MOVE.W  $FCF000,D0
                LSL.L   #5,D0
                JSR     $00200E0
                CLR.L   D0
                MOVE.W  D0,$FCF000          * clear MEAL if it will let us 20051228

                JSR    TWONEWLINES

                JMP    $0002001a            * re-enter nanoBug

* * ******** Subroutines and extra tests **************************************************


* some subs for this code

PRINTD          MOVE.B #'D',D0              * print D
                JMP    $000201A4

PRINTA          MOVE.B #'A',D0              * print A
                JMP    $000201A4

PRINTCOLON      MOVE.B #':',D0              * print d4:
                JMP    $000201A4

PRINTDASH       MOVE.B #'-',D0              * print d4:
                JMP    $000201A4


TWONEWLINES     JSR $00020138               * print newline
                JMP $00020138               * print newline

PRINTTEXT:      MOVEM.L   A0-A6/D0-D7,-(A7)        * save regs
PRNTNXT         MOVE.B    (A0)+,D0                 * get the char
                TST.B     D0
                BEQ       PRTXEND                  * end on null
                JSR       $000201A4                * print the character (SCCOUT)
                JMP       PRNTNXT
PRTXEND         MOVEM.L   (A7)+,A0-A6/D0-D7
                RTS



* special stuff
* Fill memory from 192KB-1MB with the same address so we can test memory
FILLMEM         MOVE.L  #$00030000,A0
FILMEM1         MOVE.L  A0,D0
                MOVE.L  D0,(A0)+
                CMP.L   #$100000,A0
                BLT FILMEM1

                LEA     MEMFILLED,A0
                JMP     PRINTTEXT                   * implied RTS, leaf call, no fall through


* dump the current MMU map (only context 0)
PRINTMMU        LEA       MMUHEAD,A0
                JSR       PRINTTEXT
                CLR.L   D3


PRMMUNXT        MOVE.L  D3,D0
                MOVEM.L   A0-A6/D0-D7,-(A7)          * print the address
                JSR    $000200E0
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR PRINTCOLON
                CLR.L D0
                CLR.L D1
                JSR GETMMU

                MOVEM.L   A0-A6/D0-D7,-(A7)           * Print value in D0 (SLR) already in D0
                JSR    $000200E0
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR PRINTDASH

                MOVE.L D1,D0                          * Print value in D1 (SOR)
                MOVEM.L   A0-A6/D0-D7,-(A7)
                JSR    $000200E0
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR $00020138                         * new line

                ADD.L #$20000,D3                      * are we done?
                CMP.L #$01000000,D3
                BLT   PRMMUNXT

                JMP   TWONEWLINES                     * new lines and leaf call/RTS




* Set an MMU register. D0=REGNUM, D1=SOR, D2=SLR
* these will only work with the H ROM!
*  00fe00A4  - READMMU   -->05d0
*  00fe008C  - WRITEMMU  -->05ba
*
* D0 = value for base reg
* D1 = value for limit reg
* D3 = segment #



PREPMMU         AND.L     #$00FE0000,D3           * filter out junk if any from D3
                OR.L      #$8000,D3               * flag as MMU register
                MOVE.L    D3,A3                   * map D1<->(A3), A3 holds LIM address
                OR.L      #8,D3
                MOVE.L    D3,A2                   * map D0<->(A2), A2 holds SOR address (LIM+8)
                CLR.L     D2                      * D2=segment # in READ, but not WRITE mmu, we want seg0, so clear it
                MOVE.L    D2,A5                   * A5 used to increment A2,A3 by ROM call, don't want that to happen.
                RTS

* weirdness in Lisa ROM - this only works on the current segment while read works on any segment.
* d2 normally should be the context # but it isn't.

SETMMU          MOVEM.L   A0-A6/D0-D7,-(A7)       * save registers, no return values expected.

                JSR       PREPMMU

                LEA       SETMMUDONE,A4           * return addr from call
                JMP       $00fe008c               * call ROM (must be Lisa2 compatible)

SETMMUDONE      MOVEM.L   (A7)+,A0-A6/D0-D7       * restore registers
                RTS


GETMMU        MOVEM.L   A0-A6/D2-D7,-(A7)         * save regs. d0 and d1 which are return values

                JSR       PREPMMU

                LEA       GETMMUR,A4              * get return address
                JMP       $00fe00A4               * call ROM (must be Lisa2 compatible)

GETMMUR         MOVEM.L   (A7)+,A0-A6/D2-D7       * restore regs
                RTS


* **** Special Tests to perform **********************************************************************************************

*; Convert mmu RAM segment corresponding to 80000 (512K) into a r/o stack segment so we can test the MMU behavior

TESTSTK         MOVE.L  #$00080000,D3       * addr whose MMU entry we want to set, this is also addr of the MMU segment values.

                JSR     GETMMU              * get MMU values

                LEA     MMURES1,A4          * save results for later analysis
                MOVE.L  D0,(A4)
                LEA     MMURES2,A4
                MOVE.L  D1,(A4)

                CLR.L   D0                  *; clear SOR
                MOVE.W  #$700,D1            *; *;nope  #$0480,D1  was  *change SLR to R/O Stack
                JSR     SETMMU              * set it

                LEA     MMURES3,A4          * save results for later analysis
                MOVE.L  D0,(A4)
                LEA     MMURES4,A4
                MOVE.L  D1,(A4)

                LEA     STKSEGSET,A0        * print the status
                JMP     PRINTTEXT           * no RTS needed on leaf call

TSTOPHRAM       MOVE.L  #$00a80000,D3       * What Lisa OS does
                MOVE.W  #$0be0,D0           * sort of.  top page of this should be interesting - top 16KB should be interesting
                MOVE.W  #$0700,D1
                JSR     SETMMU
                LEA     TSTOTEXT,A0
                JMP     PRINTTEXT

TSTJMP          MOVE.L  #$000a0000,D3
                JSR     GETMMU
                MOVE.W  #$0c00,D1
                JSR     SETMMU
                LEA     UNTEXT,A0
                JSR     PRINTTEXT

                MOVE.L  #$00030000,A7
                NOP
                NOP
                NOP
                JMP     $000a0010
                NOP
                NOP
                NOP
                NOP
                NOP
                RTS

TSTJSR          MOVE.L  #$00030000,A7
                NOP
                NOP
                JSR     $000a0010
                NOP
                NOP
                NOP
                NOP
                RTS

TSTRTS          MOVE.L  #$00030000,A7
                MOVE.L  #$000a0010,D0
                MOVE.L  D0,-(A7)
                NOP
                NOP
                RTS
                NOP
                NOP
                NOP
                RTS



TSTROMEM        MOVE.L    #$c0000,D3
                JSR       GETMMU
                MOVE.W    #$0580,D1
                JSR       SETMMU
                LEA       ROTEXT,A0
                JMP       PRINTTEXT


WALKSEG         LEA       WALKBERR,A0
                MOVE.L    A0,$8

                MOVE.L    A7,WALKA7
                MOVE.L    #$00080000,D0            * Address to test
                MOVE.L    D0,WALKA0

WALKCONT        MOVE.L    WALKA0,D0
                ADD.L     #$100,D0                 * setup next address - incase there's a bus error

                CMP.L     #$a0000,D0
                BEQ       WALKDONE

                MOVE.L    D0,WALKA0                * save it
                NOP
                NOP
                MOVE.L    D0,A0

                MOVEM.L   A0-A6/D0-D7,-(A7)        * print the address we're about to try to access
                JSR       $000200E0
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR       PRINTDASH

                MOVE.L    (A7),(A7)                * delay a bit
                MOVE.L    (A7),(A7)
                MOVE.L    (A7),(A7)

                MOVE.L    (A0),D0                  * access the memory
                NOP
                NOP
                NOP
                NOP
                MOVEM.L   A0-A6/D0-D7,-(A7)        * if we got this far, no bus error, print the value
                JSR       $000200E0
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR    $00020138                   * print newline

                JMP WALKCONT


WALKDONE        LEA  BUSERR,A0                     * Restore buserror vector
                MOVE.L A0,$8                       * and we're done
                RTS


WALKBERR        MOVE.L  WALKA7,A7                  * Restore stack pointer
                LEA     BUSTEXT,A0                 * Print bus error text
                JSR     PRINTTEXT

                CLR.L   D0
                MOVE.W  $FCF000,D0                 * get MEAL, print it, clear it
                LSL.L   #5,D0
                JSR     $00200E0
                CLR.L   D0
                MOVE.W  D0,$FCF000

                JSR    $00020138                   * print newline

                MOVE.L  WALKA0,A0
                JMP     WALKCONT



BUSTEXT         DC.B 'BUSERROR - MEAL:',00
WALKA7          DC.L $00000000
WALKA0          DC.L $00000000


VIACLRIRQ       MOVE.B #$7f,D5
                ORI #$2700,SR                      * Disable IRQ's
                MOVE.B D5,$00FCE018                * Disable VTIR as we'll enable IRQ1 later.

                MOVE.L #$FCC000,A0
                MOVE.L #$8585ffff,(A0)             * tell the floppy controller to clear any IRQ's (i.e. post eject)

                MOVE.B D5,$FCDD9D                  * Disable all IRQ's on VIA1
                MOVE.B D5,$FCD971                  * Disable all IRQ's on VIA2
                MOVE.B #$A0,D5
                MOVE.B D5,$FCD971                  * enable Timer2 on VIA2
                RTS

VITATEST        LEA   VIA2ISR,A0
                MOVE.L A0,$64                      * hook up our vector handler
                JSR   VIACLRIRQ                    * clear any pending IRQ's

                CLR.L   D7                         * Set Test # to perform to test 0
                CLR.L   D0                         * initial pre-value to write to T2H-1 (will be incremented to 16 for #$1000)

VIATNXT         LEA  VIATXT,A0
                JSR  PRINTTEXT

                ADD.B     #$10,D0                  * Update timer value

                CMP.B     #$50,D0                  * finished this test? go on to the next one
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


VIATEST0        JSR    VIACLRIRQ                   * clear pending IRQ's
                MOVE.W #$2000,D4
                MOVE.W D4,SR                       * Enable IRQ's

                MOVE.B D0,$FCD941                  * write value to T2Low
                MOVE.B D1,$FCD949                  * Write 0 to T2High    (cycle counter D1 is 0 already)
VIATLOP0        ADDQ.L #1,D1                       * increment count
                JMP VIATLOP0                       * and keep going until interrupted by IRQ1


VIATEST1        JSR    VIACLRIRQ
                MOVE.W #$2000,D4
                MOVE.W D4,SR

                MOVE.B D0,$FCD941
                MOVE.B D1,$FCD949
VIATLOP1        ADDQ.L #1,D1
                MOVE.B (A7),(A7)                   * access VID/RAM - delta between test 0,1 will tell us ram waits
                JMP VIATLOP1

VIATEST2        JSR    VIACLRIRQ
                MOVE.W #$2000,D4
                MOVE.W D4,SR

                MOVE.B D0,$FCD941
                MOVE.B D1,$FCD949
VIATLOP2        ADDQ.L #1,D1
                MOVE.W (A7),(A7)                   * same as test 1, but with word instead of byte
                JMP VIATLOP2

VIATEST3        JSR    VIACLRIRQ
                MOVE.W #$2000,D4
                MOVE.W D4,SR

                MOVE.B D0,$FCD941
                MOVE.B D1,$FCD949
VIATLOP3        ADDQ.L #1,D1
                MOVE.L (A7),(A7)                   * same as test 1, but with long
                JMP VIATLOP3



VIATDONE        MOVE.W #$2700,D4
                MOVE.W D4,SR                       * Disable IRQ's
                JSR    VIACLRIRQ

                ADDQ #1,D7                         * see if there are further tests
                CMP.B #$07,D7                      * 0=no mem, 1=B, 2=W, 3=L,4=VIDRAM Byte, 5=VIDRAMW, 6=VIDRAML, 7=DONE
                BEQ VIATDN1

                LEA  VTNXTXT,A0
                JSR  PRINTTEXT

                MOVE.B  D7,D0
                ADD.B  #'0',D0
                JSR    $000201A4
                JSR    TWONEWLINES
                JMP    VIATNXT


VIATDN1         ORI #$2700,SR                      * disable IRQ's
                LEA  AUTOVEC,A0
                MOVE.L A0,$64                      * Restore previous vector
                JSR    VIACLRIRQ                   * clear pending IRQ's
                RTS                                * done, return to nanoBug


VIA2ISR         ORI #$2700,SR                      * Disable all IRQ's
                MOVE.L A6,A7                       * Restore the stack
                JSR PRINTCOLON
                MOVE.L D1,D0                       * copy count from D1 to D0, so it can be printed

                MOVEM.L   A0-A6/D0-D7,-(A7)        * print the cycles counted for the timer value
                JSR       $000200E0
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR    $00020138                   * print a newline

                JSR    VIACLRIRQ
                JMP    VIATNXT                     * continue with the next test


* Variables we store

VTNXTXT         DC.B 13,10,10,'VIA Memory Test # (1=B, 2=W, 3=L, 4=VIDRAMB, 5=VIDRAMW, 6=VIDRAML):',0

VIATXT          DC.B 'VIAT2H:CYCLES - ',00
MEALTCH         DC.B 'MEMERLATCH: ',00
BUSFN           DC.B 'BUSFUNCTION:',00
ADRER           DC.B 'ADDR ERROR: ',00
IRREG           DC.B 'Instr reg : ',00
STATREG         DC.B 'Status Reg: ',00
PCTEXT          DC.B 'PC:         ',00
LOADED          DC.B 'nanoBug vectors loaded',13,10,10,0
MEMFILLED       DC.B 'Memory filled from 0x00030000-00100000 ',13,10,10,0
STKSEGSET       DC.B 13,10,10,'R/O Stack segment setup at 00080000 for half that space',13,10,10,0
TSTOTEXT        DC.B 'R/W mem segment setup at 00a80000 for space like LisaOS does',13,10,10,0
UNTEXT          DC.B 'Unused segment set up at 000a0000 for half that space.',13,10,0
ROTEXT          DC.B 'R/O mem segment set up at 000c0000 for half that space.',13,10,0
MMUHEAD         DC.B 13,10,10,'MMU Registers (addr:SLR:SOR)',13,10,0


MMURES1         DC.L $00000000
MMURES2         DC.L $00000000
MMURES3         DC.L $00000000
MMURES4         DC.L $00000000


* Save area for exceptions

TNUMHIT         DC.W  $0000,$0000                  * trap number (and padding)

TNUMD0          DC.L  $00000000                    * registers d0-d7
TNUMD1          DC.L  $00000000
TNUMD2          DC.L  $00000000
TNUMD3          DC.L  $00000000
TNUMD4          DC.L  $00000000
TNUMD5          DC.L  $00000000
TNUMD6          DC.L  $00000000
TNUMD7          DC.L  $00000000

TNUMA0          DC.L  $00000000                    * registers a0-a7
TNUMA1          DC.L  $00000000
TNUMA2          DC.L  $00000000
TNUMA3          DC.L  $00000000
TNUMA4          DC.L  $00000000
TNUMA5          DC.L  $00000000
TNUMA6          DC.L  $00000000
TNUMA7          DC.L  $00000000

TNUMFILL1       DC.W  $0000                        *  filler padding
TNUMSR          DC.W  $0000                        *  status register


         END            $20200           *     End of assembly
