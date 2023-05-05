CC=m68k-amigaos-gcc
LINK=m68k-amigaos-gcc
ASS=vasmm68k_mot
VLINK=vlink

STRIP=m68k-amigaos-strip

#find the toolchain's directory
PREFIX = $(shell ./getprefix.sh "$(CC)")

#-DCD32VER

CFLAGS = -m68020-60 -mtune=68030 -noixemul -g -ggdb -Og
LFLAGS = -noixemul -g -ggdb

AFLAGS = -Fhunk -m68060 -linedebug -chklabels -align -L listing.txt -Dmnu_nocode=1 -DUSE_16X16_TEXEL_MULS

AFLAGS += -I../ \
		  -I$(PREFIX)/m68k-amigaos/ndk-include \
		  -I../media \
		  -I../media/includes

VFLAGS = -b amigahunk -sc -l amiga -L $(PREFIX)m68k-amigaos/ndk/lib/libs

all:	hires hiresC
dev:	AFLAGS += -DDEV=1
dev:	hires hiresC

hiresC: hires.o main.o
	$(LINK) $(LFLAGS) $^ -o $@

clean:
	rm *.o

hires: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

%.o: %.s Makefile
	$(ASS) $(AFLAGS) $< -o $@

%.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

%_stripped:	%
	$(STRIP) --strip-debug --strip-unneeded -o $@ $<

#############################################################
#
#############################################################
