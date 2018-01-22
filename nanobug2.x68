*;-----------------------------------------------------------------------------
*; Lisa nanoBug - Copyright (C) 2006, by Ray Arachelian, All Rights Reserved
*;               A Part of the Lisa Emulation Project
*;
*; Small program meant to fit within 512 bytes of a boot sector to open up
*; remote access to a Lisa via a serial port B.  It allows remote memory
*; read/write/execute memory access in hex.  No more, no less.
*;
*; This is optimized for SPACE, not for speed!  It's not a nice friendly
*; program, it's meant mainly as a loader for code sent over a serial port
*; from another computer connected by null modem cable at 9600,N,8,1 ASCII.
*; (note that the bps rate can be changed, 9600 is only a sample.)
*;
*; This is the "deluxe" version of nanoBug meant to be booted off a floppy
*; along with some extra "liJMPry" code.  It is incompatible with the normal
*; nanoBug in the sense that it loads at a different address range, and so
*; the subroutines in here can't be used with the other version.
*;
*; The code normally loaded at $0002000 is replaced with a boot loader which
*; reads in the rest of the sectors on track 0.
*;------------------------------------------------------------------------------
*;
*;
*;
*; +  display the current byte at the current cursor address and advance cursor by one byte
*;
*; -  go back one byte (does not display memory, just decrements the cursor address)
*;
*; R  display next 16 hex bytes at the current cursor address and advance cursor by 16 bytes
*;
*;
*; @  enter a new cursor address (and the execute address) - you must type in eight valid hex characters.
*;    Only 0-9 and a-f are accepted. The letters a-f must be lower case.  Any other text aborts the command.
*;    Your input does not get echoed back to you other than the @ character until address entry is completed.
*;
*;    Note that upper case HEX letters A-F are treated as unrecognized.
*;
*; 0-9a-f - write a byte to memory at the current cursor address.
*;
*;    When you press one of these valid hex characters, an EQL will be eched back to you signifying that you
*;    are about to write to memory.
*;
*;    Only 0-9 and a-f are accepted. The letters a-f must be lower case.  Any other text aborts the command
*;    and the cursor does not advance to the next address.
*;
*;    Your input does not get echoed back to you other than the = character until the entry is completed.
*;
*;    If you did not wish to write to memory, you can abort by typing a non hex character - i.e. ESC key.
*;    After you enter both the high and low nibbles of the hex byte, the full byte will be displayed after the =
*;    and the cursor will be advanced to the next byte.
*;
*;    Note that upper case HEX letters A-F are treated as unrecognized.
*;
*;
*; X  execute code at the last @ address (not affected cursor change via +,-,<,>,R keys) by doing
*;    a JSR to the last entered @ address.
*;
*;    No feedback is given when you press X other than it echoing X back.  Once your code returns to
*;    nanobug, the cursor address will be reset to the last @ address and will be displayed.  If it
*;    doesn't, your code just crashed and you'll need to press the reset button.  If the floppy is
*;    in the drive, nanoBug will boot up again.  (Isn't life fun?!)
*;
*;    Your code must restore the A7 stack pointer and return with RTS or equivalent, or bad things
*;    may happen to nanoBug.  Any register changes made by the code are lost, so if your code does
*;    not explictly write output to the serial port either using it's own functions or by calling parts
*;    of nanoBug, it can write to memory, which you can use the R or + nanoBug commands to read post
*;    execution.
*;
*;    Pressing X again will execute the same code again as the @ cursor address will be restore.
*;
*; ALL ELSE - ignored, the prompt will simply repeat.
*;
*; No other commands are available.  If you want to do things like eject the floppy or shut down the
*; Lisa, you must upload code via nanobug and execute it.  Although not recommended, you could set
*; the @ cursor to I/O memory and read/write, or use the Lisa's POST ROM routines, but this way lies
*; madness and crashing.
*;
*;************************************************************************************************************
*;
*; As mentioned, its reason for existance is to be as tiny as possible while still
*; being a useful serial port umbilical cord.  Being tiny also allows
*; you to hand type it in carefully via the Lisa boot/POST ROM's hidden
*; Service Mode monitor.  You would want to use that if are using
*; Twiggys on a Lisa1 or your floppy drive is broken, but you want to use it
*; to transfer data from a functional ProFile or Widget drive for example, etc.
*;
*; When it boots, you'll see nothing on the Lisa's display other than the hour glass
*; that the boot ROM left, nor will you be able to use the Lisa's keyboard or mouse.
*; You can only interact with this code over the serial port!
*;
*; If you don't understand this, don't use it, it's not for you!
*;
*; When writing code for nanoBug, I suggest you copy and paste it as hex into
*; your terminal window.
*;
*; When entering commands or hex values, your input will not be echoed back to you.
*;
*; If you enter an unrecognized character, the address of the cursor will be
*; printed back to you.
*;
*;*********************************************************************************************



*; i.e. if you type this:     @000220004e714e714e714e75X
*; You'll see this as the output (assuming that you don't turn on local echo or half duplex
*;
*;  00022000 @
*;  00022200 =4E
*;  00022201 =71
*;  00022202 =4E
*;  00022203 =71
*;  00022204 =4E
*;  00022205 =71
*;  00022206 =4E
*;  00022207 =75
*;  00022208 X
*;  00022200
*;
*; (The above code is loaded at address 22000, it consists of NOP,NOP,NOP,RTS, which
*; as you might imagine does nothing 3 times and then returns to nanoBug.  Not too
*; thrilling, but it's an easy example.)
*;
*; Note that after execution, the cursor returns back to the last @ address.  This
*; allows you to re-enter the code.
*;
*; Here's another example:
*;
*; If you type in @000220004e714e414e75------R<X
*;
*; You'll see the following
*;
*; 00022000 @
*; 00022200 =4E
*; 00022201 =71
*; 00022202 =4E
*; 00022203 =71
*; 00022204 =4E
*; 00022205 =75
*; 00022206
*; 00022205
*; 00022204
*; 00022203
*; 00022202
*; 00022201
*; 00022200 4E 71 4E 71 4E 75 00 00 00 00 00 00 00 00 00 00
*; 00022210
*; 00022200 X
*; 00022200
*;
*; This means, set the cursor at 22000, enter NOP,NOP,RTS, move the cursor back 6 bytes (the - keys), display 16 bytes of HEX with the R
* command, then execute (X command)
*;
*;
*; Although it's possible to interact with nanoBug using a terminal program on
*; your other computer to control your Lisa, I highly recommend you do not just
*; start typing away on it, but rather compose your code ahead of time using a
*; cross 68000 assembler, and prepare the hex output as a text script as examples
*; above show, then paste that text script into your terminal program carefully
*; before executing it.
*;
*; If you randomly type in hex values, you will clobber memory that you care about
*; and will crash your Lisa.   Tread carefully!  Beware of I/O space, don't use
*; nanoBug to read/write there as you'll almost certainly crash your Lisa.
*;
*; It is very possible that line noise will ruin your day.  No provisions are
*; made to prevent this, sorry, use good hardware in an RFI-noise free environment
*; and hope for the best.   Therefore, it's not a good idea to hook up a real
*; modem to nanoBug. :)
*;
*; It is highly recommended that your uploaded code traps autovectors, NMI, BUS,
*; and ADDRESS errors, does it's own output to the serial port (it's ok to call
*; nanoBug internal subroutines) and then gracefully returns to nanoBug when done.
*;
*; Use nanoBug as a program loader, not as a full fledged debugger if you can
*; help it.  Expand nanoBug into a full fledged debugger, but use nanoBug itself
*; to load that expanded debugger code!  Good luck!
*;
*;------------------------------------------------------------------------------


                ORG     $20000               ; E68K uses 7000, Lisa Boot uses  20000
*               LOAD    $20000

VIADDR          EQU  $00FCDD81
FLOPREAD        EQU  $00fe0094
TAGBUFF         EQU  $0001fff4
TIMEOUT         EQU  $00C00000
FLOPRAM         EQU  $00FCC001
START           EQU             *

*                                            ;JUMP TABLE
                JMP  RETRY
                JMP  PROMPT
                JMP  EJECT
                JMP  OUTHEXNIB
                JMP  PRINTHEXBYTE
                JMP  ISHEXCHAR
                JMP  GETHEXNIBBLE
                JMP  NEWLINE
                JMP  PRINTAT
                JMP  PRINTASPACE
                JMP  PRINTANEQL
                JMP  GETSCCPORT
                JMP  SCCOUT
                JMP  PRINTDASH
                JMP  PRINTCOLON
                JMP  PRINTA
                JMP  PRINTD
                JMP  TWONEWLINES
                JMP  PRINTTEXT
                JMP  READSCC
                JMP  INITSCC
                JMP  INITVEC
                JMP  FILLMEM
                JMP  RTSREST
                JMP  PRINTMMU
                JMP  SETMMU
                JMP  GETMMU
                JMP  CRC16
                JMP XMSENDROM
                JMP XMSENDFIN
                JMP XMSENDBLK
                JMP XMSENDMEM
                JMP CPIOROM
                JMP PREADSEC
                JMP GETCRC

RETRY           LEA    LASTSECT,A0
                MOVE.L (A0),D1

                MOVE.L #VIADDR,A3          ; VIA address
                MOVE.L #TAGBUFF,A1         ; tag buffer
                MOVE.L #TIMEOUT,D2         ; timeout
                MOVE.L #FLOPRAM,A0         ; floppy I/O RAM block
                CLR.L  D0                  ; speed - let the I/O ROM fill this in

                JSR    FLOPREAD            ;
                BCS    RETRY               ; error

                LEA    LASTADDR,A0         ; queue up the next address
                MOVE.L (A0),D0
                ADD.L  #$200,D0            ; this will only work for 512 byte/sec floppies
                MOVE.L D0,(A0)

                LEA    LASTSECT,A0
                MOVE.L (A0),D1
                ADD.L  #$100,D1            ; increment sector
                MOVE.L D1,(A0)             ; save it
                CMP.L #$0c,D1
                BNE RETRY                  ; do next sector

                JMP  $22000                ; startup

EJECT           MOVE.L A0,-(A7)            ; save A0
                MOVE.L #$FCC000,A0         ; eject floppy
                MOVE.L #$81810202,(A0)
                MOVE.L (A7)+,A0            ; restore A0
                RTS

LASTADDR        DC.L  $00022000
LASTSECT        DC.L  $00000000

                DC.B 'nanoBug Disk loader - A Part of the Lisa Emulator Project.',13,10,
                DC.B 'Copyright (C) MMVI by Ray A. Arachelian, All Rights Reserved.',13,10,
                DC.B 'Released under the terms of the GNU Public License 2.0.',13,10,$00

                NOP                        ; padding upto next sector.
                NOP
                NOP



NANOBUG          ORI #$2700,SR
                 MOVE.L #$21000,A7           * Setup stack
                 JSR EJECT
                 JSR INITSCC
                 JSR INITSCC
                 MOVE.L #$22000,A0           * Set start of execution/load buffer
                 MOVE.L A0,A1
EPROMPT
PROMPT
                 JSR PRINTAT                 * was PRINTPROMPT

NOPROMPT         JSR READSCC                 * waitfor and get a command byte

                 CMP.B #'-',D0               * backspace (cursor back 1 byte)
                 BEQ CURSORBACK

                 CMP.B #'R',D0               * read the next 16 bytes
                 BEQ READCMD

                 CMP.B #'+',D0               * same as read, but only one byte (also serves as opposite of - )
                 BEQ READ1CMD

                 CMP.B #'X',D0               * Execute at last @ entered cursor
                 BEQ EXECCMD

                 CMP.B #'@',D0               * Set a new address for the cursor
                 BEQ ADDRCMD

                 JSR ISHEXCHAR
                 BMI PROMPT
                 JMP WRITECMD

*** Commands

CURSORBACK       SUBA #1,A0                  * cursor back one char
                 JMP PROMPT

* Display the current byte under the cursor and advance it
READ1CMD         MOVE.B (A0)+,D0
                 JSR PRINTHEXBYTE
                 JSR PRINTASPACE
                 JMP PROMPT

* Display 16 bytes at cursor address and advance it

READCMD          MOVE.W #15,D6

NEXTRD           MOVE.B (A0)+,D0
                 JSR PRINTHEXBYTE
                 JSR PRINTASPACE
                 DBRA D6,NEXTRD

                 JMP PROMPT

* Execute at cursor
EXECCMD          MOVE.L A1,A0               * Reset cursor to last @ address
                 MOVEM.L A0-A6/D0-D7,-(A7)  * Save all the registers, so we can hit X to execute it again
                 JSR SCCOUT                 * give feedback incase it crashes that X was pressed.
                 JSR (A1)                   * Execute it at the last @ that was set.
                 MOVEM.L (A7)+,A0-A6/D0-D7  * Restore all registers and return to the prompt
                 JMP PROMPT                 * hopefully we made it here without crashing.

* Write memory
WRITECMD         MOVE.L D0,D2               * save high nibble of data entry in D2
                 JSR PRINTANEQL             * give some feedback
                 LSL.L #4,D2                * shift it to the high nibble position
                 JSR GETHEXNIBBLE           * get the lowest significant nibble
                 BMI PROMPT                 * or abort data entry
                 OR.B D0,D2                 * OR it with the previous nibble
                 MOVE.B D2,(A0)+            * Write to memory
                 MOVE.B D2,D0
                 JSR PRINTHEXBYTE           * feedback of what was written to memory
                 JMP PROMPT

* Set a new address and execute cursor
ADDRCMD          JSR SCCOUT                 * echo the @ sign for feedback

                 MOVE.W #7,D2               * Get 8 nibbles

G_NEXTADY        JSR GETHEXNIBBLE           * read and echo back a byte (limit warning, can't backspace!)
                 BMI PROMPT
                 LSL.L #4,D1
                 OR.B  D0,D1                * write it into D1's low nibble and shift it over

                 DBRA D2,G_NEXTADY          * loop until we got all 8.

                 MOVE.L D1,A0               * save addr to @cursor
                 MOVE.L D1,A1               * save addr to 2nd @cursor for Xecute command
                 JMP PROMPT                 * done.


PRINTHEXBYTE     MOVEM.L A0-A6/D0-D7,-(A7)  * Save all regs

                 MOVE.L D0,D3               * Save the value to print
                 LSR #4,D0                  * top nibble
                 JSR OUTHEXNIB

                 MOVE.B D3,D0               * restore it & print the low nibble
                 JSR OUTHEXNIB

RTSREST          MOVEM.L (A7)+,A0-A6/D0-D7  * restore regs and return  * several routines use this!
		 RTS



* common code used by PRINTAT - print an address
PRHX4            MOVE.L D0,D7
                 SWAP D0                    * 0th byte
		 LSR.L #8,D0
                 JSR PRINTHEXBYTE

                 MOVE.L D7,D0               * 1st byte
		 SWAP D0
                 JSR PRINTHEXBYTE

                 MOVE.L D7,D0               * 2nd byte
		 LSR.L #8,D0
                 JSR PRINTHEXBYTE

                 MOVE.L D7,D0               * 3rd byte
                 JMP PRINTHEXBYTE


*Is this an ascii hex char? if so returns 0-15, else returns -1

ISHEXCHAR        CMPI.B #'0',D0
                 BLT ISHEXNX1
                 CMPI.B #'9',D0
                 BGT ISHEXNX1

                 SUBI.B #'0',D0
                 RTS

ISHEXNX1         CMPI.B #'a',D0
                 BLT ISNOTHEX
                 CMPI.B #'f',D0
                 BGT ISNOTHEX
                 SUBI.B #87,D0
                 RTS

ISNOTHEX         CLR.L D0             * get a -1 so we can use BMI
                 NOT.L D0
JUSTRTS          RTS


* Get a hex nibble in D0 from serial port, if it's not a hex char that was entered, beep and retry

GETHEXNIBBLE     JSR READSCC
                 JSR ISHEXCHAR
                 BMI JUSTRTS
                 MOVEM.L A0-A6/D0-D7,-(A7)
                 JMP RTSREST

* mini leaf-subs

* Print LFCR
NEWLINE
PRINTPROMPT      MOVE.B #10,D0
                 JSR SCCOUT
                 MOVE.B #13,D0
                 JMP SCCOUT


*                                     * Print address:
PRINTAT          JSR NEWLINE
                 MOVE.L A0,D0
                 JSR PRHX4
*                                     * Fall through to printaspace
PRINTASPACE      MOVE.B #' ',D0
                 JMP SCCOUT
PRINTANEQL       MOVE.B #'=',D0
                 JMP SCCOUT

OUTHEXNIB       LEA HEXTEXT,A5
                MOVE.W D0,D4
                AND.W #15,D0
                MOVE.B 0(A5,D0.W),D0
                JSR SCCOUT
                MOVE.W D4,D0
                RTS

HEXTEXT   DC.B  '0123456789ABCDEF'


GETSCCPORT      MOVE.L #$FCD245,A3    ;* Port B Data       ** or  0xFCD247 for port A Control
                MOVE.L #$FCD241,A4    ;* Port B Control    ** or  0xFCD243 for port A Control
                RTS

SCCOUT          MOVEM.L A0-A6/D1-D7,-(A7)
                JSR     GETSCCPORT
XSCCOUTW        BTST    #2,(A4)      ;* wait for xmit buffer to be ready (empty)                                ****
                BEQ XSCCOUTW
QSCCOUTW        BTST    #5,(A4)      ;* are we clear to send now?
                BEQ QSCCOUTW         ;*
                MOVE.L  (A7),(A7)    ;* delay a bit
                MOVE.B D0,(A3)       ;* write the byte
                MOVE.L  (A7),(A7)    ;* delay a bit

YSCCOUTW        BTST    #2,(A4)      ;* wait for xmit buffer to be empty again, i.e. byte sent successfully     ****
                BEQ     YSCCOUTW
                JMP RTSREST1         ;* done


READSCC         MOVEM.L A0-A6/D1-D7,-(A7) * save regs
                JSR HWXOFF           ;* talk to me now please
XSCCINW         BTST    #0,(A4)      ;* wait for data to arrive
                BEQ XSCCINW
                MOVE.L  (A7),(A7)    * delay a bit
                MOVE.B  (A3),D0      * read the data
                BEQ XSCCINW          * keep waiting if it's a null (might have been a break?)
                JSR HWXON            ;* shut up now, please
RTSREST1        MOVEM.L (A7)+,A0-A6/D1-D7       * Save this for move mems that exclude d0
                RTS

SCCINITDATA     DC.B   2,$00          ;* 2 disable SCC IRQ's
                DC.B   9,$00          ;* 4 disable SCC IRQ's
                DC.B   4,$4           ;* 6 x16 clk, 1 stop bits, no parity
                DC.B  11,$50          ;* 8 baud rate gen enable rx/tx
                DC.B  12,$32          ;* 10 low  TC port B:  9600: 0xCE:C6-D7  19200: 66:62-6A
*                                     ;*                    38400: 0x32:30-34  57600: 20:1f-22 (21)
                DC.B  13,$00          ;* 12 high TC 0 for 9600 and above
                DC.B  14,$03          ;* 14 baud rate generator
                DC.B   3,$C1          ;* 16 8bits/char on receiver, enable
                DC.B   3,$E1          ;* 18 8bits/char on receiver, enable, autoenable
                DC.B   5,$68          ;* 20 DTR low, 8 bits/char xmit, enable

HWXON           JSR GETSCCPORT        ;* HW Handshake Version of XON - flip RTS - bit 2
                MOVE.B #5,(A4)
                MOVE.L (A7),(A7)
                MOVE.B #$6A,(A4)      ;* might want EA here
                RTS

HWXOFF          JSR GETSCCPORT        ;* HW Handshake Version of XOFF - flip RTS
                MOVE.B #5,(A4)
                MOVE.L (A7),(A7)
                MOVE.B #$68,(A4)      ;* might want E8 here
                RTS


INITSCC         JSR GETSCCPORT
                MOVE.B (A4),D0       * make sure SCC is sync'ed up
                LEA SCCINITDATA,A0   * get

                MOVE.W #19,D0        * count of bytes in SCCINITDATA above to send  *** change me
XINITSC1        JSR GETSCCPORT       * delay
                MOVE.L (A7),(A7)     * DELAY
                MOVE.B (A0)+,(A4)    * output the data
                DBRA  D0,XINITSC1
                RTS

* ****************************************** Padding to go upto 512 bytes
                DC.B 'nanoBug'
                NOP
                NOP
                NOP
                NOP
                NOP

BUFF            DC.B  $4e,$75,$4e,$75,$4e,$75,$4e,$75,$4e,$75


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
                JSR    SCCOUT
                JSR     PRINTCOLON
                MOVE.W TNUMHIT,D0           * add the trap #
                JSR    SCCOUT            * print it

                JSR    TWONEWLINES


                JSR     PRINTD
                MOVE.B #'0',D0
                JSR    SCCOUT
                JSR     PRINTCOLON
                MOVE.L TNUMD0,D0
                JSR    PRHX4            * print the value prhx4
                JSR    PRINTASPACE            * print a space

                JSR     PRINTD
                MOVE.B #'1',D0
                JSR    SCCOUT
                JSR     PRINTCOLON
                MOVE.L TNUMD1,D0
                JSR    PRHX4            * print the value prhx4
                JSR    PRINTASPACE            * print a space

                JSR     PRINTD
                MOVE.B #'2',D0
                JSR    SCCOUT
                JSR     PRINTCOLON
                MOVE.L TNUMD2,D0
                JSR    PRHX4            * print the value
                JSR    PRINTASPACE            * print a space

                JSR     PRINTD
                MOVE.B #'3',D0
                JSR    SCCOUT
                JSR     PRINTCOLON
                MOVE.L TNUMD3,D0
                JSR    PRHX4            * print the value
                JSR    PRINTASPACE            * print a space

                JSR     PRINTD
                MOVE.B #'4',D0
                JSR    SCCOUT
                JSR     PRINTCOLON
                MOVE.L TNUMD4,D0
                JSR    PRHX4            * print the value
                JSR    PRINTASPACE            * print a space

                JSR     PRINTD
                MOVE.B #'5',D0
                JSR    SCCOUT
                JSR     PRINTCOLON
                MOVE.L TNUMD5,D0
                JSR    PRHX4            * print the value
                JSR    PRINTASPACE            * print a space

                JSR     PRINTD
                MOVE.B #'6',D0
                JSR    SCCOUT
                JSR     PRINTCOLON
                MOVE.L TNUMD6,D0
                JSR    PRHX4            * print the value
                JSR    PRINTASPACE            * print a space

                JSR     PRINTD
                MOVE.B #'7',D0
                JSR    SCCOUT
                JSR     PRINTCOLON
                MOVE.L TNUMD7,D0
                JSR    PRHX4            * print the value
                JSR    NEWLINE            * print NEWLINE

* Now it's time to print the address registers

                JSR     PRINTA
                MOVE.B #'0',D0
                JSR    SCCOUT
                JSR     PRINTCOLON
                MOVE.L TNUMA0,D0
                JSR    PRHX4            * print the value
                JSR    PRINTASPACE            * print a space

                JSR     PRINTA
                MOVE.B  #'1',D0
                JSR     SCCOUT
                JSR     PRINTCOLON
                MOVE.L  TNUMA1,D0
                JSR     PRHX4           * print the value
                JSR     PRINTASPACE           * print a space

                JSR     PRINTA
                MOVE.B  #'2',D0
                JSR     SCCOUT
                JSR     PRINTCOLON
                MOVE.L  TNUMA2,D0
                JSR     PRHX4           * print the value
                JSR     PRINTASPACE           * print a space

                JSR     PRINTA
                MOVE.B  #'3',D0
                JSR     SCCOUT
                JSR     PRINTCOLON
                MOVE.L  TNUMA3,D0
                JSR     PRHX4           * print the value
                JSR     PRINTASPACE           * print a space

                JSR     PRINTA
                MOVE.B  #'4',D0
                JSR     SCCOUT
                JSR     PRINTCOLON
                MOVE.L  TNUMA4,D0
                JSR     PRHX4           * print the value
                JSR     PRINTASPACE           * print a space

                JSR     PRINTA
                MOVE.B  #'5',D0
                JSR     SCCOUT
                JSR     PRINTCOLON
                MOVE.L  TNUMA5,D0
                JSR     PRHX4           * print the value
                JSR     PRINTASPACE           * print a space

                JSR     PRINTA
                MOVE.B  #'6',D0
                JSR     SCCOUT
                JSR     PRINTCOLON
                MOVE.L  TNUMA6,D0
                JSR     PRHX4           * print the value
                JSR     PRINTASPACE           * print a space

                JSR     PRINTA
                MOVE.B #'7',D0
                JSR     SCCOUT
                JSR     PRINTCOLON
                MOVE.L  TNUMA7,D0
                JSR     PRHX4           * print the value
                JSR     NEWLINE           * print NEWLINE

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
                JSR     PRHX4           * print the value
                JSR     NEWLINE           * print NEWLINE

                LEA     ADRER,A0            * ADDRESS ERROR LONG
                JSR     PRINTTEXT
                MOVE.L  (A6)+,D0
                JSR     PRHX4            * print the value
                JSR     NEWLINE           * print NEWLINE


                LEA     IRREG,A0            * Instruction register word
                JSR     PRINTTEXT
                CLR.L   D0
                MOVE.W  (A6)+,D0
                JSR     PRHX4           * print the value
                JSR     NEWLINE           *  print NEWLINE

NOTBUS          LEA     STATREG,A0          * Status register word
                JSR     PRINTTEXT
                CLR.L   D0
                MOVE.W  (A6)+,D0
                JSR     PRHX4               * print the value
                JSR     NEWLINE             * print NEWLINE


                LEA     PCTEXT,A0           * program counter
                JSR     PRINTTEXT
                MOVE.L  (A6)+,D0
                JSR     PRHX4               * print the value
                JSR     NEWLINE             * print NEWLINE

                LEA     MEALTCH,A0          * print the contents of the memory error latch
                JSR     PRINTTEXT
                CLR.L   D0
                MOVE.W  $FCF000,D0
                LSL.L   #5,D0
                JSR     PRHX4
                CLR.L   D0
                MOVE.W  D0,$FCF000          * clear MEAL if it will let us 20051228

                JSR    TWONEWLINES

                JMP    PROMPT               * re-enter nanoBug

* * ******** Subroutines and extra tests **************************************************


* some subs for this code

PRINTD          MOVE.B #'D',D0              * print D
                JMP    SCCOUT

PRINTA          MOVE.B #'A',D0              * print A
                JMP    SCCOUT

PRINTCOLON      MOVE.B #':',D0              * print d4:
                JMP    SCCOUT

PRINTDASH       MOVE.B #'-',D0              * print d4:
                JMP    SCCOUT


TWONEWLINES     JSR NEWLINE               * print NEWLINE
                JMP NEWLINE               * print NEWLINE

PRINTTEXT:      MOVEM.L   A0-A6/D0-D7,-(A7)        * save regs
PRNTNXT         MOVE.B    (A0)+,D0                 * get the char
                TST.B     D0
                BEQ       PRTXEND                  * end on null
                JSR       SCCOUT                * print the character (SCCOUT)
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
                JSR    PRHX4
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR PRINTCOLON
                CLR.L D0
                CLR.L D1
                JSR GETMMU

                MOVEM.L   A0-A6/D0-D7,-(A7)           * Print value in D0 (SLR) already in D0
                JSR    PRHX4
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR PRINTDASH

                MOVE.L D1,D0                          * Print value in D1 (SOR)
                MOVEM.L   A0-A6/D0-D7,-(A7)
                JSR    PRHX4
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR NEWLINE                         * new line

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
                JSR       PRHX4
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
                JSR       PRHX4
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR    NEWLINE                   * print NEWLINE

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
                JSR     PRHX4
                CLR.L   D0
                MOVE.W  D0,$FCF000

                JSR    NEWLINE                   * print NEWLINE

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
                JSR       PRHX4
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
                JSR    SCCOUT
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
                JSR       PRHX4
                MOVEM.L   (A7)+,A0-A6/D0-D7

                JSR    NEWLINE                   * print a NEWLINE

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

                 JSR XMINIT

RESTART          MOVE.L #$00022000,A0
                 MOVE.L #$00080000,A1        * Max 512KB

CONTRCV          JSR XMGETBLK
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

XMGET1          JSR POLLSCC                 * get a character
                TST.L D1
                BEQ  XMGET1                 * did we get it without a timeout?

                ADDQ.L #1,D4
                CMP #10,D4
                BEQ XMCANCEL

XMGNAK          MOVE.B #$15,D0              * send NAK
                JSR  SCCOUT
                MOVE.L A2,A0                * restore A0
                JMP  XMGET1                 * start over

XMCANCEL        MOVE.B #$18,D0
                JSR SCCOUT
                JSR SCCOUT
                JSR SCCOUT
                MOVE.L #$FF,D0
                JMP XMGETFIN

XMGET2          CMP.B  #$04,D0               * did we get an EOT?
                BNE  XMGET3
                CLR.L D0                     * signal end of transmission
                JMP  XMGETFIN

XMGET3          CMP.B  #$18,d0               * did we get a cancel
                BNE  XMGET4

                JSR    POLLSCC               * wait for a 2nd one to be sure it's not line noise
                TST.L  D1
                BNE    XMGNAK
                CMP.B  #$18,D0
                BEQ XMCANCEL


XMGET4          CMP.B  #$01,D0               * expect SOH, if not send NAK
                BNE    XMGNAK

                JSR    POLLSCC               * expect the block #
                TST.L  D1
                BNE    XMGNAK

                MOVE.L D0,D2                 * save the block #

                JSR    POLLSCC               * expect the 1's complimented block #
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
                JMP    XMGACCEPT             * and allow sender to resend the previous block

XMGNXBK         ADDQ.B #1,D3                 * undo block# substraction
                CMP.L  D2,D3
                BNE XMCANCEL

XMGACCEPT       MOVE.L #127,D2               * D2=number of bytes to read
                CLR.L  D3                    * D3=running checksum

XMGNEXTBYTE     JSR    POLLSCC               * get a byte
                TST.L  D1
                BNE    XMGNAK

                MOVE.B D0,(A0)+

                CMPA.L A0,A1
                BLT    XMCANCEL              * overflow

                ADD.B  D0,D3                 * checksum

                DBRA   D2,XMGNEXTBYTE

                JSR    POLLSCC               * expect checksum
                TST.L  D1
                BNE    XMGNAK
                CMP.B  D3,D0                 * does it match?
                BNE    XMGNAK                * No? go resend the block please

                MOVE.L A0,A2                 * update the pointer

                MOVE.B #$05,D0               * send ACK, the block is good
                JSR SCCOUT

                MOVE.L XMBLKNUM,D0           * increment the block number as we expect another one
                ADD.L #1,D0
                AND.L #$000000FF,D0
                MOVE.L D0,XMBLKNUM

                MOVE.L #1,D0                 * signal that we received one block

XMGETFIN        MOVEM.L  A2/D1-D7,-(A7)
                RTS




POLLSCC         MOVEM.L A0-A6/D2-D7,-(A7) * save regs
                JSR GETSCCPORT
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

                MOVEM.L (A7)+,A0-A6/D2-D7       * Save this for move mems that exclude d0
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
                JSR XMSENDBLK             * otherwise send the current block
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

                JSR    POLLSCC           * wait for ACK/Cancel/etc.
                TST.L  D1
                BNE    XMSRESEND

                CMP.B  #$05,D0           * Got Ack, continue on
                BNE    XMS2

                MOVE.L XMBLKNUM,D0       * increment the block number, so we can do the next one
                ADD.B #1,D0
                AND.L #$000000FF,D0
                MOVE.L D0,XMBLKNUM

                CLR.L  D0                * signal that all is good
                JMP XMSDONE

XMS2            CMP.B  #$15,D0           * Got back NAK
                JMP    XMSRESEND

                CMP.B  #$18,D0           * Did we get CANCEL?
                BNE    XMSRESEND         * got garbage instead, resend

                JSR    POLLSCC           * wait for 2nd CANCEL
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
                JSR SCCOUT
                JSR SCCOUT
                JSR SCCOUT
                JSR SCCOUT
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
* liJMPrian, and compatibility use.
*
* Source code is not a forum for legal discussions, therefore
* I will not continue further discussing this.
*
***********************************************************************************
XMSENDROM       JSR XMINIT
                MOVE.L #$00FE0000,D0
                MOVE.L #$00FE4000,D1
                JMP    XMSENDMEM



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

         MOVE.L #$FCC000,A0            ; execute
         MOVE.L #$81810202,(A0)

*;         *                             ; need a delay here
*;         *                             ; copy page to buffer
*;         *                             ; Setup to copy the next page
         LEA    IOPGNUM,A0
         MOVE.B (A0),D0
         ADD.B #1,D0
         CMP.B  #$20,D0
         BEQ IORCDONE
         JMP CPI0


IORCDONE RTS



IORCPY   DC.B  $a2,$00                 ;' LDX #$00         ' 0,1          6504 ROM 1000-1fff
         DC.B  $bd,$00
IOPGNUM  DC.B  $10                     ;' LDA $1000,X      '@2,3,4 overwrite from $10..$1f

         DC.B  $9d,$00,$08             ;' STA $0300,X      '5,6,7         buffer here in 2nd half of buffer
         DC.B  $e8                     ;' INX              '8
         DC.B  $d0,$f7                 ;' BNE @2           '9,a  #next opc at addr b, want 2.  b-2=9. F7
         DC.B  $60                     ;' RTS              'b    return to 6504 ROM



DUMPPROF







PREADSEC

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
*;  Returns:
*;    D0 = error code (0 = OK)
*;    D1 = error bytes (4)
*;    D2 - D7 and A1 - A6 are preserved
*;-----------------------------------------------------------------------------

                MOVE.L #$002ff80,A1            ; fill details in xmodem header blk, some text, some binary

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

                MOVE.L  #$00fcd901,A0           ;       get paraport VIA base address
                JSR     $00FE0090               ; Call ROM to do a ProFile read - not sure if this is in early ROM's!

*                                               *; D0=return value 0=OK
*                                                *; D1=4 error bytes

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
                JSR CRC16
                CMPA.L #$00030200,A1
                BNE GETCRC1


*;                                              ; CRC16  D0.W=CRC D1.W=DATA D2 trashed
CRC16:          MOVE.W D0,D2            ; swap16 D0 (CRC) - wonder if ROL.W #8,D2 would work better?
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
                LSL.W #8,D2
                LSL.W #4,D2
                AND.W #$0FF0,D2
                EOR.W D2,D0

                MOVE.W D0,D2            ; return crc^(((crc & 0x00ff)<<4)<<1);
                AND.W #$00ff,D2
                LSL.W #4,D2
                LSL.W #1,D2
                EOR.W D0,D2

                RTS

TESTCLR         ORI.B   #31,CCR         ; flip on all bits.
                CLR.L   D0              ; clear D0
                BEQ PASSCLR
                LEA FALCLRT,A0
                JMP PRINTTEXT

PASSCLR         LEA PASCLRT,A0
                JMP PRINTTEXT

PASCLRT         DC.B 'Clear does set the Z flag',13,10,10,0
FALCLRT         DC.B 'Clear does NOT set the Z flag',13,10,10,0

         END            $20000           *     End of assembly
