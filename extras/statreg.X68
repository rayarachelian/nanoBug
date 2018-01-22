                ORG     $22000           * E68K uses 7000, Lisa Boot uses  20000, nanoBot loads at 22000
*               LOAD    $22000

START           EQU             *


                MOVE.L #$0F8000,A0        * video ram address (estimated for a 1MB Lisa, could be wrong!)
                MOVE.L #$0FFFF8,A1        * end of video memory + a little padding to be safe.

ZEROLINE        MOVE.L #$59,D0             * 90 bytes/line or 45 words per line
                CLR.L D2                  * what to write to memory
NEXT0LINE       MOVE.B D2,(A0)+
                CMP.L  A0,A1
                BEQ   SCREENDONE
                DBRA  D0,NEXT0LINE

                MOVE.L #$59,D0             * 90 bytes/line or 45 words per line
                MOVE.B #$FF,D2          * what to write to memory
NEXT1LINE       MOVE.B D2,(A0)+
                CMP.L  A0,A1
                BEQ   SCREENDONE
                DBRA  D0,NEXT1LINE

                BRA ZEROLINE


SCREENDONE      LEA      STATGRAB,A0     ; Load subroutine address - used to JSR to
                MOVE.L   A0,A1           ; copy the address to the filler routine

                MOVE.L  #$4BC0,D0       ; This is ~3 screenfulls worth, s/b plenty
                MOVE.W  #$12D2,D1       ; this is    MOVE.B     (A2),(A1)+

FILLSUB         MOVE.W  D1,(A1)+
                SUBI.L  #1,D0
                BPL     FILLSUB

                MOVE.W #$4E75,D1        ; this is    RTS
                MOVE.W D1,(A1)+

                MOVE.L   #$030004,A1    ; load A1 with the start of result buffer
                MOVE.L   #$FCF801,A2    ; address of src to capture - STATREG=$FCF801, SERNO=FEF800
                MOVE.L   #$fce018,A3    ; VTIR on/off latches
                MOVE.L   #$fce01a,A4
                MOVE.L   #$FCF801,A5    ; address of status register $FCF801 always for VTIR sync before capture

                NOP                     ; settle any caches - not really applicable to MC68000, but more like 68020's
                NOP
                NOP
                NOP

                MOVE.L  #2,D0           ; VTIR bit in STATREG is 2
                TST.B   (A3)
                TST.B   (A4)

XLOOP           BTST    D0,(A5)         ; Wait for vertical retrace
                BNE     XLOOP

                TST.B    (A3)           ; Turn off/on virq again, and run the grab routine.
                TST.B    (A4)

                JSR (A0)                ; grab results

                MOVE.L  #$30000,A0      ; Save address of last data read, for spitting out of nanoBug
                MOVE.L  A1,D0
                MOVE.L  D0,(A0)         ; save it at 30000

                RTS                     ; return to nanoBug

STATGRAB        DC.L $4e754e75


                RTS


         END            $22000           *     End of assembly

