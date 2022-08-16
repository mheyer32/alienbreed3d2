CC=m68k-amigaos-gcc
ASS=vasmm68k_mot
LINK=vlink

#find the toolchain's directory
PREFIX = $(shell ./getprefix.sh "$(CC)")

CHEESEY ?= 0

#-DCD32VER

AFLAGS = -Fhunk -m68030 -devpac -linedebug -align -L listing.txt -DCHEESEY=${CHEESEY} -Dmnu_nocode=1
AFLAGS += -I../ \
		  -I$(PREFIX)/m68k-amigaos/ndk-include \
		  -I../media \
		  -I../media/includes

LFLAGS = -b amigahunk -sc -l amiga -L $(PREFIX)m68k-amigaos/ndk/lib/libs

all:	 hires

clean:
	rm *.o

%:	%.s Makefile
	$(ASS) $(AFLAGS) -o $@.o $<
#	$(LINK) $(LFLAGS) $@.o -o $@
	$(CC) -g -ggdb -nostartfiles -nostdlib -L $(PREFIX)/m68k-amigaos/lib  $@.o -l amiga -o $@

%.o:	%.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

#############################################################
#
#############################################################
