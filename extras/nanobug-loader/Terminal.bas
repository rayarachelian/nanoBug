compile long if def _usingLiteRuntime = _false
dim x
call paramtext ("This program is designed to run with the lite runtime.","","","")
x = fn stopalert(128,0)
end 
compile end if

CLEAR LOCAL
LOCAL FN getSCCChar$()
   o$ = inkey$(_PrinterPort)           
END FN=o$



/* Wait for a character, but time out after 3 seconds, or midnight flip */
CLEAR LOCAL
LOCAL FN waitForChar$()
  DIM now&
  now&=TIMER
  do
   c$ = inkey$(_PrinterPort)
  until c$>=" " OR (TIMER-now&)>2 OR (TIMER-now&)<0
  
  if (TIMER-now&)>3 OR (TIMER-now&)<0 THEN c$=chr$(13)+"[TIMEOUT]"+chr$(13)

  if c$>=" " then print c$;
    
END FN=c$


CLEAR LOCAL
LOCAL FN isHex(c$)
  dim r%
  r%=0
  if c$>="0" && c$<="9" then r%=1
  if c$>="a" && c$<="f" then r%=1
  if c$>="A" && c$<="F" then r%=1
END FN=r%


CLEAR LOCAL
LOCAL FN getCursor&()
 dim done%, addr&, a$,c$,addr$

 do

  ' grab char, expect @, ignore CR/LF and space, unless we timeout
  c$=FN waitForChar$()

  ' prompt starts with @, if we didn't get it, send a CR, to ask for one.
  LONG IF c$<>"@" 
    do
     PRINT #_PrinterPort,CHR$(13);
     c$=FN waitForChar$() 
    until c$="@"
  END IF

  ' want 8 hex digits for 32 bit long
  a$=FN waitForChar$() : if FN isHex(a$) then addr$=addr$+a$   '1
  a$=FN waitForChar$() : if FN isHex(a$) then addr$=addr$+a$   '2
  a$=FN waitForChar$() : if FN isHex(a$) then addr$=addr$+a$   '3
  a$=FN waitForChar$() : if FN isHex(a$) then addr$=addr$+a$   '4
  a$=FN waitForChar$() : if FN isHex(a$) then addr$=addr$+a$   '5
  a$=FN waitForChar$() : if FN isHex(a$) then addr$=addr$+a$   '6
  a$=FN waitForChar$() : if FN isHex(a$) then addr$=addr$+a$   '7
  a$=FN waitForChar$() : if FN isHex(a$) then addr$=addr$+a$   '8

  if len(addr$)=8 then done%=1  'check to see if we got a timeout or other issue.

 until done%

 addr&=VAL("&H"+add$)

END FN=addr&

/* dumbass FB3 has UCASE$ but no LCASE$ and HEX$ is uppercase! */
CLEAR LOCAL
LOCAL FN LCASE(i$)

	DIM i%,j$,c$
	FOR i%=1 TO LEN(i$)
		C$=MID$(i$,i%,1)
		IF C$>="A" AND C$<="Z" THEN C$=CHR$(  ASC(C$)-ASC("A")+ASC("a") )
		j$=j$+C$
	NEXT 

END FN=j$


CLEAR LOCAL
LOCAL FN setCursor(want&)

 do
   now=FN getCursor&()

   ' if the address is off by a single byte, can use +/- commands, else have to use @
   LONG if (now&=want&+1) 
        print #_PrinterPort,"-"; print "-"
   XELSE
       LONG if (now&=want&-1) 
            print #_PrinterPort,"+"; print "+"
       XELSE

            h$="@"+HEX$(want&)
	    h$=FN LCASE(h$)

            FOR i%=1 to LEN(h$)
	      a$=MID$(h$,i%,1)
              PRINT #_PrinterPort,a$;
              PRINT               a$;
              DELAY 110
            NEXT
            PRINT
       ENDIF
   ENDIF

 until want&=now&

END FN=now&






' Main program
DIM cursor&,want&,buffer$,o$

' Open the serial port. Want to use Printer port, because on old
' Macintoshes, the Printer port can better handle higher baud rates.
'
open "C",_PrinterPort,57600,_noParity,_OneStopBit,_EightBits,10000
buffer$ = ""'clear string buffer


NEXTFILE:

' Ask for file name to send commands from
fileName$ = FILES$(_fOpen,"TEXT","HEX File to upload", 1)
OPEN "I",1,filename$

do
REM READ #1,o$;1   ' read a single char

  INPUT #1,o$    ' read a line

  'set cursor address command.
  LONG if LEFT$(o$,1)="@" 

    PRINT "Setting address to ";o$
    want&=VAL("&H"+VAL(MID$(O$,2))   ' convert to long int
    cursor&=FN setCursor(want&)      ' tell nanoBug to set it to that.

  XELSE

   ' if we see two hex chars, then we're writing to memory.
   LONG if LEN(o$)=2 AND FN isHex(LEFT$(o$,1)) AND FN isHex(RIGHT$(o$,1))

    dim done%
    done%=0

    DO

     o$=FN LCASE$(o$)                  ' we write hex to nanoBug in lower case.
     PRINT #_PrinterPort,LEFT$(o$,1);  ' send the 1st char
     DELAY 110
     a$=waitForChar$()                 ' nanoBug answers with =, we then send 2nd char
     LONG IF A$="="

        PRINT #_PrinterPort,RIGHT$(o$,1);
        DELAY 110

        a$=waitForChar$()              ' nanobug now sends the full hex byte in upper case as two hex letters.
        b$=waitForChar$()

        ' if what nanoBug wrote is what we sent, we're done, otherwise, send it again.
        LONG IF UCASE$(a$)=LEFT$(o$,1) AND UCASE$(b$)=RIGHT$(o$,1) 
              done%=1  ' if they match what we expect, we're good.
        XELSE
              ' we didn't get the right char, so make sure we're still at the right address
	      cursor&=FN setCursor(want&)                
        END IF
     END IF     
      
    UNTIL done%=1

    want&=cursor&+1
    cursor&=FN setCursor(want&)   'Make sure we're in the right place - nanoBug will echo back the addr as a prompt.

   XELSE

     ''' other commands, just send'em out as they are without the CR's.
     if LEN(o$)>1 THEN PRINT #_PrinterPort,$o;

     ' eat any output, and we're done.
     do
        a$=FN waitForChar$()
        if a$<>chr$(13)+"[TIMEOUT]"+chr$(13) THEN print a$;
     UNTIL a$=chr$(13)+"[TIMEOUT]"+chr$(13)

   END IF
  END IF 

until EOF(1)
CLOSE #1

' Now we're a cheapo terminal program

PRINT
PRINT "Completed sending of ";fileName$
PRINT "Hit Control-F to send another file, or Control-Q to quit"
PRINT


do

  o$ = inkey$(_PrinterPort)

  select o$
  case "",chr$(10)'didn't get anything or got a line feed
  case => " "'space or greater
  print o$;'print it
  end select

  o$ = inkey$

  if o$=ASC("F")+64 THEN GOTO NEXTFILE
  if o$=ASC("Q")+64 THEN CLOSE #_PrinterPort: END


  if len(o$) then print #_PrinterPort,o$;

until 0
