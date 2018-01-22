*-----------------------------------------------------------------------------
* Lisa nanoBug - Copyright (C) 2005, by Ray Arachelian, All Rights Reserved
*               A Part of the Lisa Emulation Project
*
* Small program meant to fit within 512 bytes of a boot sector to open up
* remote access to a Lisa via a serial port B.  It allows remote memory
* read/write/execute memory access in hex.  No more, no less.
*
* This is optimized for SPACE, not for speed!  It's not a nice friendly
* program, it's meant mainly as a loader for code sent over a serial port
* from another computer connected by null modem cable at 9600,N,8,1 ASCII.
*
*
*------------------------------------------------------------------------------
*
*
*
* +  display the current byte at the current cursor address and advance cursor by one byte
*
* -  go back one byte (does not display memory, just decrements the cursor address)
*
* R  display next 16 hex bytes at the current cursor address and advance cursor by 16 bytes
*
*
* @  enter a new cursor address (and the execute address) - you must type in eight valid hex characters.
*    Only 0-9 and a-f are accepted. The letters a-f must be lower case.  Any other text aborts the command.
*    Your input does not get echoed back to you other than the @ character until address entry is completed.
*
*    Note that upper case HEX letters A-F are treated as unrecognized.
*
* 0-9a-f - write a byte to memory at the current cursor address.
*
*    When you press one of these valid hex characters, an EQL will be eched back to you signifying that you
*    are about to write to memory.
*
*    Only 0-9 and a-f are accepted. The letters a-f must be lower case.  Any other text aborts the command
*    and the cursor does not advance to the next address.
*
*    Your input does not get echoed back to you other than the = character until the entry is completed.
*
*    If you did not wish to write to memory, you can abort by typing a non hex character - i.e. ESC key.
*    After you enter both the high and low nibbles of the hex byte, the full byte will be displayed after the =
*    and the cursor will be advanced to the next byte.
*
*    Note that upper case HEX letters A-F are treated as unrecognized.
*
*
* X  execute code at the last @ address (not affected cursor change via +,-,<,>,R keys) by doing
*    a JSR to the last entered @ address.
*
*    No feedback is given when you press X other than it echoing X back.  Once your code returns to
*    nanobug, the cursor address will be reset to the last @ address and will be displayed.  If it
*    doesn't, your code just crashed and you'll need to press the reset button.  If the floppy is
*    in the drive, nanoBug will boot up again.  (Isn't life fun?!)
*
*    Your code must restore the A7 stack pointer and return with RTS or equivalent, or bad things
*    may happen to nanoBug.  Any register changes made by the code are lost, so if your code does
*    not explictly write output to the serial port either using it's own functions or by calling parts
*    of nanoBug, it can write to memory, which you can use the R or + nanoBug commands to read post
*    execution.
*
*    Pressing X again will execute the same code again as the @ cursor address will be restore.
*
* ALL ELSE - ignored, the prompt will simply repeat.
*
* No other commands are available.  If you want to do things like eject the floppy or shut down the
* Lisa, you must upload code via nanobug and execute it.  Although not recommended, you could set
* the @ cursor to I/O memory and read/write, or use the Lisa's POST ROM routines, but this way lies
* madness and crashing.
*
*************************************************************************************************************
*
* As mentioned, its reason for existance is to be as tiny as possible while still
* being a useful serial port umbilical cord.  Being tiny also allows
* you to hand type it in carefully via the Lisa boot/POST ROM's hidden
* Service Mode monitor.  You would want to use that if are using
* Twiggys on a Lisa1 or your floppy drive is broken, but you want to use it
* to transfer data from a functional ProFile or Widget drive for example, etc.
*
* When it boots, you'll see nothing on the Lisa's display other than the hour glass
* that the boot ROM left, nor will you be able to use the Lisa's keyboard or mouse.
* You can only interact with this code over the serial port!
*
* If you don't understand this, don't use it, it's not for you!
*
* When writing code for nanoBug, I suggest you copy and paste it as hex into
* your terminal window.
*
* When entering commands or hex values, your input will not be echoed back to you.
*
* If you enter an unrecognized character, the address of the cursor will be
* printed back to you.
*
**********************************************************************************************



* i.e. if you type this:     @000220004e714e714e714e75X
* You'll see this as the output (assuming that you don't turn on local echo or half duplex
*
*  00022000 @
*  00022200 =4E
*  00022201 =71
*  00022202 =4E
*  00022203 =71
*  00022204 =4E
*  00022205 =71
*  00022206 =4E
*  00022207 =75
*  00022208 X
*  00022200
*
* (The above code is loaded at address 22000, it consists of NOP,NOP,NOP,RTS, which
* as you might imagine does nothing 3 times and then returns to nanoBug.  Not too
* thrilling, but it's an easy example.)
*
* Note that after execution, the cursor returns back to the last @ address.  This
* allows you to re-enter the code.
*
* Here's another example:
*
* If you type in @000220004e714e414e75------R<X
*
* You'll see the following
*
* 00022000 @
* 00022200 =4E
* 00022201 =71
* 00022202 =4E
* 00022203 =71
* 00022204 =4E
* 00022205 =75
* 00022206
* 00022205
* 00022204
* 00022203
* 00022202
* 00022201
* 00022200 4E 71 4E 71 4E 75 00 00 00 00 00 00 00 00 00 00
* 00022210
* 00022200 X
* 00022200
*
* This means, set the cursor at 22000, enter NOP,NOP,RTS, move the cursor back 6 bytes (the - keys), display 16 bytes of HEX with the R
* command, then execute (X command)
*
*
* Although it's possible to interact with nanoBug using a terminal program on
* your other computer to control your Lisa, I highly recommend you do not just
* start typing away on it, but rather compose your code ahead of time using a
* cross 68000 assembler, and prepare the hex output as a text script as examples
* above show, then paste that text script into your terminal program carefully
* before executing it.
*
* If you randomly type in hex values, you will clobber memory that you care about
* and will crash your Lisa.   Tread carefully!  Beware of I/O space, don't use
* nanoBug to read/write there as you'll almost certainly crash your Lisa.
*
* It is very possible that line noise will ruin your day.  No provisions are
* made to prevent this, sorry, use good hardware in an RFI-noise free environment
* and hope for the best.   Therefore, it's not a good idea to hook up a real
* modem to nanoBug. :)
*
* It is highly recommended that your uploaded code traps autovectors, NMI, BUS,
* and ADDRESS errors, does it's own output to the serial port (it's ok to call
* nanoBug internal subroutines) and then gracefully returns to nanoBug when done.
*
* Use nanoBug as a program loader, not as a full fledged debugger if you can
* help it.  Expand nanoBug into a full fledged debugger, but use nanoBug itself
* to load that expanded debugger code!  Good luck!
*
*------------------------------------------------------------------------------


                ORG     $20000               * E68K uses 7000, Lisa Boot uses  20000
*               LOAD    $20000

START           EQU             *


*       Main Program

STARTUP          ORI #$2700,SR
                 MOVE.L #$21000,A7           * Setup stack
                 BSR EJECT
                 BSR INITSCC
                 MOVE.L #$22000,A0           * Set start of execution/load buffer
                 MOVE.L A0,A1
EPROMPT
PROMPT
                 BSR PRINTAT                 * was PRINTPROMPT

NOPROMPT         BSR READSCC                 * waitfor and get a command byte

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

                 BSR ISHEXCHAR
                 BMI PROMPT
                 BRA WRITECMD

*** Commands

CURSORBACK       SUBA #1,A0                  * cursor back one char
                 BRA PROMPT

* Display the current byte under the cursor and advance it
READ1CMD         MOVE.B (A0)+,D0
                 BSR PRINTHEXBYTE
                 BSR PRINTASPACE
                 BRA PROMPT

* Display 16 bytes at cursor address and advance it

READCMD          MOVE.W #15,D6

NEXTRD           MOVE.B (A0)+,D0
                 BSR PRINTHEXBYTE
                 BSR PRINTASPACE
                 DBRA D6,NEXTRD

                 BRA PROMPT

* Execute at cursor
EXECCMD          MOVE.L A1,A0               * Reset cursor to last @ address
                 MOVEM.L A0-A6/D0-D7,-(A7)  * Save all the registers, so we can hit X to execute it again
                 BSR SCCOUT                 * give feedback incase it crashes that X was pressed.
                 JSR (A1)                   * Execute it at the last @ that was set.
                 MOVEM.L (A7)+,A0-A6/D0-D7  * Restore all registers and return to the prompt
                 BRA PROMPT                 * hopefully we made it here without crashing.

* Write memory
WRITECMD         MOVE.L D0,D2               * save high nibble of data entry in D2
                 BSR PRINTANEQL             * give some feedback
                 LSL.L #4,D2                * shift it to the high nibble position
                 BSR GETHEXNIBBLE           * get the lowest significant nibble
                 BMI PROMPT                 * or abort data entry
                 OR.B D0,D2                 * OR it with the previous nibble
                 MOVE.B D2,(A0)+            * Write to memory
                 MOVE.B D2,D0
                 BSR PRINTHEXBYTE           * feedback of what was written to memory
                 BRA PROMPT

* Set a new address and execute cursor
ADDRCMD          BSR SCCOUT                 * echo the @ sign for feedback

                 MOVE.W #7,D2               * Get 8 nibbles

G_NEXTADY        BSR GETHEXNIBBLE           * read and echo back a byte (limit warning, can't backspace!)
                 BMI PROMPT
                 LSL.L #4,D1
                 OR.B  D0,D1                * write it into D1's low nibble and shift it over

                 DBRA D2,G_NEXTADY          * loop until we got all 8.

                 MOVE.L D1,A0               * save addr to @cursor
                 MOVE.L D1,A1               * save addr to 2nd @cursor for Xecute command
                 BRA PROMPT                 * done.


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

** unused code, commented out to save space
** *********************** * Prints a null terminated C string pointed to by A0.
**PRINTTEXT        MOVEM.L A0-A6/D0-D7,-(A7) * Save all regs
**
**NEXTPRINT        MOVE.B (A0)+,D0      * grab a character
**                 BEQ RTSREST          * is it a null? if so, return
**                 BSR SCCOUT           * no, print it
**                 BRA NEXTPRINT
************************************************************************************************
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

GETHEXNIBBLE     BSR READSCC
                 BSR ISHEXCHAR
                 BMI JUSTRTS
                 MOVEM.L A0-A6/D0-D7,-(A7)
                 BRA RTSREST

* mini leaf-subs

* Print LFCR
NEWLINE
PRINTPROMPT      MOVE.B #10,D0
                 BSR SCCOUT
                 MOVE.B #13,D0
                 BRA SCCOUT


*                                     * Print address:
PRINTAT          BSR NEWLINE
                 MOVE.L A0,D0
                 BSR PRHX4
*                                     * Fall through to printaspace
PRINTASPACE      MOVE.B #' ',D0
                 BRA SCCOUT
PRINTANEQL       MOVE.B #'=',D0
                 BRA SCCOUT

OUTHEXNIB       LEA HEXTEXT,A5
                MOVE.W D0,D4
                AND.W #15,D0
                MOVE.B 0(A5,D0.W),D0
                BSR SCCOUT
                MOVE.W D4,D0
                RTS


HEXTEXT   DC.B  '0123456789ABCDEF'

* not sure this will work on 68000 81810202 -> FCC000

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
                MOVE.L  (A7),(A7)    * delay a bit
                BRA RTSREST1         * done


READSCC         MOVEM.L A0-A6/D1-D7,-(A7) * save regs
                BSR GETSCCPORT
XSCCINW         BTST    #0,(A4)      * wait for data to arrive
                BEQ XSCCINW
                MOVE.L  (A7),(A7)    * delay a bit
                MOVE.B  (A3),D0      * read the data
                BEQ XSCCINW          * keep waiting if it's a null (might have been a break?)
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

INITSCC         BSR GETSCCPORT
                MOVE.B (A4),D0       * make sure SCC is sync'ed up
                LEA SCCINITDATA,A0   * get

                MOVE.W #19,D0        * count of bytes in SCCINITDATA above to send  *** change me
XINITSC1        BSR GETSCCPORT       * delay
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

         END            $20000           *     End of assembly
