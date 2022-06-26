CC=m68k-amigaos-gcc
ASS=vasmm68k_mot
LINK=vlink

PREFIX = $(shell ./getprefix.sh "$(CC)")

CHEESEY ?= 0

#-DCD32VER=0
AFLAGS = -Fhunk -devpac -m68030 -ignore-mult-inc -linedebug -L listing.txt -DCHEESEY=${CHEESEY} -Dmnu_nocode=1
AFLAGS += -I../ \
		  -I../devpac/Include/include \
		  -I../includes \
		  -I../devpac \
		  -I$(PREFIX)/m68k-amigaos/ndk-include
 

LFLAGS = -bamigahunk -textbaserel
LFLAGS += -L./Devpac/Include/lib

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
