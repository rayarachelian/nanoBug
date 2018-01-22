
#nanoBug

Copyright 2006 by Ray Arachelian, All Rights Reserved
Released under the Terms of the GNU GPL 3.0


This is a nano debugger program meant to fit within 512 bytes of a boot sector to open up remote access to a Lisa via a serial port B.  It allows remote memory read/write/execute memory access in hex.  No more, no less.

The Lisa does have [a similar facility in its ROM](http://lisafaq.sunder.net/single.html#lisafaq-hw-rom_servicemode) , however, it's not as useful since you must interact with it via the Lisa keyboard and CRT display and you won't be able to save things like the ROMs unless you go through a lot of effort to do so.  This code makes it a lot easier to save things by simply using a terminal program such as ZTerm or Minicom, Hyperterm, etc., and enabling a recording facility, or by writing your own custom serial port code.

This is optimized for SPACE, not for speed!  It's not a nice friendly program, it's meant mainly as a loader for code sent over a serial port from another computer connected by null modem cable at 9600,N,8,1 ASCII.

The code normally loaded at $0002000 is replaced with a boot loader which reads in the rest of the sectors on track 0.  (In some versions it loads at $2200)

Commands accepted over the serial port:
	
	  +  display the current byte at the current cursor address and advance cursor by one byte
	
	  -  go back one byte (does not display memory, just decrements the cursor address)
	
	  R  display next 16 hex bytes at the current cursor address and advance cursor by 16 bytes
	
	  @  enter a new cursor address (and the execute address) - you must type in eight valid hex characters.  Only 0-9 and a-f are accepted. The letters a-f must be lower case.  Any other text aborts the command.  Your input does not get echoed back to you other than the @ character until address entry is completed.
	 
	    Note that upper case HEX letters A-F are treated as unrecognized.
	 
	   0-9a-f - write a byte to memory at the current cursor address.
	 
	    When you press one of these valid hex characters, an EQL will be eched back to you signifying that you
	    are about to write to memory.
	 
	    Only 0-9 and a-f are accepted. The letters a-f must be lower case.  Any other text aborts the command
	    and the cursor does not advance to the next address.
	 
	    Your input does not get echoed back to you other than the = character until the entry is completed.
	 
	    If you did not wish to write to memory, you can abort by typing a non hex character - i.e. ESC key.
	    After you enter both the high and low nibbles of the hex byte, the full byte will be displayed after the =
	    and the cursor will be advanced to the next byte.
	 
	    Note that upper case HEX letters A-F are treated as unrecognized.
	 
	  X  execute code at the last @ address (not affected cursor change via +,-,<,>,R keys) by doing
	      a JSR to the last entered @ address.
	 
	    No feedback is given when you press X other than it echoing X back.  Once your code returns to
	    nanobug, the cursor address will be reset to the last @ address and will be displayed.  If it
	    doesn't, your code just crashed and you'll need to press the reset button.  If the floppy is
	    in the drive, nanoBug will boot up again.  (Isn't life fun?!)
	 
	    Your code must restore the A7 stack pointer and return with RTS or equivalent, or bad things
	    may happen to nanoBug.  Any register changes made by the code are lost, so if your code does
	    not explictly write output to the serial port either using it's own functions or by calling parts
	    of nanoBug, it can write to memory, which you can use the R or + nanoBug commands to read post
	    execution.
	 
	    Pressing X again will execute the same code again as the @ cursor address will be restored.
	 
	    ALL ELSE - ignored, the prompt will simply repeat.
	
	   No other commands are available.  If you want to do things like eject the floppy or shut down the
	   Lisa, you must upload code via nanobug and execute it.  Although not recommended, you could set
	   the @ cursor to I/O memory and read/write, or use the Lisa's POST ROM routines, but this way lies
	   madness and crashing.
	
 As mentioned, its reason for existance is to be as tiny as possible while still being a useful serial port umbilical cord.  Being tiny also allows you to hand type it in carefully via the [Lisa boot/POST ROM's hidden Service Mode monitor.](http://lisafaq.sunder.net/single.html#lisafaq-hw-rom_servicemode)   You would want to use that if are using Twiggys on a Lisa1 or your floppy drive is broken, but you want to use it  to transfer data from a functional ProFile or Widget drive for example, etc.

 When it boots, you'll see nothing on the Lisa's display other than the hour glass that the boot ROM left, nor will you be able to use the Lisa's keyboard or mouse.  You can only interact with this code over the serial port!

== If you don't understand what this is, don't use it, it's not for you!==

 When writing code for nanoBug, I suggest you copy and paste it as hex into your terminal window, or write a small program to slowly paste it to the serial  port.

 When entering commands or hex values, your input will not be echoed back to you.

 If you enter an unrecognized character, the address of the cursor will be  printed back to you.

The code here is provided as is, in the hopes that it will be useful, but no effort was made to provide makefiles or such, this is more of a snapshot in time of code I wrote a long time ago, and I've also  included random bits of code I used to poke and probe at the Lisa's internals during the creation of LisaEm.  I've left an xmodem module (which today is used in BLU [http://sigmasevensystems.com/BLU.html ](http://sigmasevensystems.com/BLU.html ) as well as some code to snarf up the status register and a few other gems.  Not everything is indended as a complete program, and indeed some of the code is just left over cruft.

The code was assembled with the [http://www.easy68k.com/](http://www.easy68k.com/) suite which I ran inside of Wine (Darwine back then.)  After a NANOBUG.BIN was generated, I loaded it into
a disk image using one of the included make-nanobug.sh scripts, which need [lisafsh-tool](https://github.com/rayarachelian/lisafsh-tool-libdc42)  to be installed in the $PATH.

Pre-assembled bz2ip compressed variations of nanobug are available in the bin directory with different serial port options including Hardware Handshaking.
