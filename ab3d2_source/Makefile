CC=m68k-amigaos-gcc
LINK=m68k-amigaos-gcc
ASS=vasmm68k_mot
VLINK=vlink

STRIP=m68k-amigaos-strip

#find the toolchain's directory
PREFIX = $(shell ./getprefix.sh "$(CC)")

#-DCD32VER

CFLAGS = -noixemul -g -ggdb -O3
LFLAGS = -noixemul -g -ggdb

# Allow 040+ instructions to be emitted in runtime detection cases
AFLAGS = -Fhunk -m68060 -linedebug -chklabels -align -L listing.txt -Dmnu_nocode=1 -DUSE_16X16_TEXEL_MULS

AFLAGS += -I../ \
		  -I$(PREFIX)/m68k-amigaos/ndk-include \
		  -I../media \
		  -I../media/includes

#AFLAGS += -DMEMTRACK=1

VFLAGS = -b amigahunk -sc -l amiga -L $(PREFIX)m68k-amigaos/ndk/lib/libs

all:	tkg tkgC
dev:	AFLAGS += -DDEV=1
dev:	tkg tkgC

OBJS = c/main.o \
	   c/screen.o \
	   c/system.o \
	   c/menu.o \
	   c/draw.o \
	   c/message.o \
	   c/game_properties.o \
	   c/game_preferences.o \
	   c/game_progress.o \
	   c/game.o \
	   c/hires.o

tkg: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgC: AFLAGS+=-DBUILD_WITH_C
tkgC: CFLAGS+=-m68020-60 -mtune=68030
tkgC: ${OBJS}
		$(LINK) $(LFLAGS) $^ -ldebug -o $@

040:	tkg040 tkgC040
040_dev:	AFLAGS += -DDEV=1
040_dev:	tkg040 tkgC040


tkg040: AFLAGS+=-DOPT040
tkg040: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgC040: AFLAGS+=-DBUILD_WITH_C -DOPT040
tkgC040: CFLAGS+=-m68040 -mtune=68040
tkgC040: ${OBJS}
		$(LINK) $(LFLAGS) $^ -ldebug -o $@

060:	tkg060 tkgC060
060_dev:	AFLAGS += -DDEV=1
060_dev:	tkg060 tkgC060


tkg060: AFLAGS+=-DOPT060
tkg060: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgC060: AFLAGS+=-DBUILD_WITH_C -DOPT060
tkgC060: CFLAGS+=-m68060 -mtune=68060
tkgC060: ${OBJS}
		$(LINK) $(LFLAGS) $^ -ldebug -o $@


clean:
	rm -f *.o
	rm -f ${OBJS}

c/%.o: %.s Makefile
	$(ASS) $(AFLAGS) $< -o $@


%.o: %.s Makefile
	$(ASS) $(AFLAGS) $< -o $@

%.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

%_stripped:	%
	$(STRIP) --strip-debug --strip-unneeded -o $@ $<

#############################################################
#
#############################################################
