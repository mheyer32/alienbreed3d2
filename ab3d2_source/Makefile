CC=m68k-amigaos-gcc
ASS=vasmm68k_mot
LINK=vlink

#PREFIX = $(shell ./getprefix.sh "$(CC)")

CHEESEY ?= 0

#-DCD32VER

AFLAGS = -Fhunk -m68060 -linedebug -align -L listing.txt -DCHEESEY=${CHEESEY} -Dmnu_nocode=1
AFLAGS += -I../ \
		  -I../devpac/Include/include \
		  -I../media \
		  -I../media/includes

#		  -I$(PREFIX)/m68k-amigaos/ndk-include

LFLAGS = -b amigahunk -sd -sc -l amiga -L ../devpac/Include/lib

all:	 hires

clean:
	rm *.o

%:	%.s Makefile
	$(ASS) $(AFLAGS) -o $@.o $<
	$(LINK) $(LFLAGS) $@.o -o $@

%.o:	%.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

#############################################################
#
#############################################################
