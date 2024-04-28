CC=m68k-amigaos-gcc
LINK=m68k-amigaos-gcc
ASS=vasmm68k_mot
VLINK=vlink

STRIP=m68k-amigaos-strip

#find the toolchain's directory
PREFIX = $(shell ./getprefix.sh "$(CC)")

#-DCD32VER

CFLAGS = -noixemul -O3
LFLAGS = -noixemul

# Allow 040+ instructions to be emitted in runtime detection cases
AFLAGS = -Fhunk -m68060 -linedebug -chklabels -align -L listing.txt -Dmnu_nocode=1 -DUSE_16X16_TEXEL_MULS

AFLAGS += -I../ \
		  -I$(PREFIX)/m68k-amigaos/ndk-include \
		  -I../media \
		  -I../media/includes

#AFLAGS += -DMEMTRACK=1

VFLAGS = -b amigahunk -sc -l amiga -L $(PREFIX)m68k-amigaos/ndk/lib/libs

# Generic dev builds - dev features, debugging on, unstripped
dev:	tkg_dev tkgc_dev
dev:	AFLAGS += -DDEV=1
dev:	CFLAGS += -m68020-60 -mtune=68030 -DDEV -g -ggdb
dev:	LFLAGS += -g -ggdb

# Generic test builds, release features, debugging on, unstripped
test:	tkg_test tkgc_test
test:	CFLAGS += -m68020-60 -mtune=68030 -g -ggdb
test:	LFLAGS += -g -ggdb

# Generic release builds, release features, debugging off, stripped
rel:	tkg tkgc
rel:	CFLAGS+=-m68020-60 -mtune=68030
rel:
	$(STRIP) --strip-debug --strip-unneeded tkg
	$(STRIP) --strip-debug --strip-unneeded tkgc

# 68040 tuned dev builds
dev040:	tkg_dev_040 tkgc_dev_040
dev040:	AFLAGS += -DDEV=1 -DOPT040
dev040:	CFLAGS += -m68040 -mtune=68040 -DDEV -g -ggdb
dev040:	LFLAGS += -g -ggdb

# 68040 tuned test builds
test040:	tkg_test_040 tkgc_test_040
test040:	CFLAGS += -m68040 -mtune=68040 -g -ggdb
test040:	LFLAGS += -g -ggdb

# 68040 tuned release builds
rel040:	tkg_040 tkgc_040
rel040:	AFLAGS += -DOPT040
rel040:	CFLAGS += -m68040 -mtune=68040
rel040:
	$(STRIP) --strip-debug --strip-unneeded tkg_040
	$(STRIP) --strip-debug --strip-unneeded tkgc_040

# 68060 tuned dev builds
dev060:	tkg_dev_060 tkgc_dev_060
dev060:	AFLAGS += -DDEV=1 -DOPT060
dev060:	CFLAGS += -m68060 -mtune=68060 -DDEV -g -ggdb
dev060:	LFLAGS += -g -ggdb

# 68060 tuned test builds
test060:	tkg_test_060 tkgc_test_060
test060:	CFLAGS += -m68060 -mtune=68060 -g -ggdb
test060:	LFLAGS += -g -ggdb

# 68060 tuned release builds
rel060:	tkg_060 tkgc_060
rel060:	AFLAGS += -DOPT060
rel060:	CFLAGS += -m68060 -mtune=68060
rel060:
	$(STRIP) --strip-debug --strip-unneeded tkg_060
	$(STRIP) --strip-debug --strip-unneeded tkgc_060

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

# GENERIC ##################################

tkg_dev: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgc_dev:	AFLAGS+=-DBUILD_WITH_C
tkgc_dev:	${OBJS}
	$(LINK) $(LFLAGS) $^ -o $@

tkg_test: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgc_test:	AFLAGS+=-DBUILD_WITH_C
tkgc_test:	${OBJS}
	$(LINK) $(LFLAGS) $^ -o $@

tkg: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgc:	AFLAGS+=-DBUILD_WITH_C
tkgc:	${OBJS}
	$(LINK) $(LFLAGS) $^ -o $@

# 68040 ##################################

tkg_dev_040: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgc_dev_040:	AFLAGS+=-DBUILD_WITH_C
tkgc_dev_040:	${OBJS}
	$(LINK) $(LFLAGS) $^ -o $@

tkg_test_040: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgc_test_040:	AFLAGS+=-DBUILD_WITH_C
tkgc_test_040:	${OBJS}
	$(LINK) $(LFLAGS) $^ -o $@

tkg_040: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgc_040:	AFLAGS+=-DBUILD_WITH_C
tkgc_040:	${OBJS}
	$(LINK) $(LFLAGS) $^ -o $@

# 68060 ##################################

tkg_dev_060: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgc_dev_060:	AFLAGS+=-DBUILD_WITH_C
tkgc_dev_060:	${OBJS}
	$(LINK) $(LFLAGS) $^ -o $@

tkg_test_060: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgc_test_060:	AFLAGS+=-DBUILD_WITH_C
tkgc_test_060:	${OBJS}
	$(LINK) $(LFLAGS) $^ -o $@

tkg_060: hires.o
	$(VLINK) $(VFLAGS) $< -o $@

tkgc_060:	AFLAGS+=-DBUILD_WITH_C
tkgc_060:	${OBJS}
	$(LINK) $(LFLAGS) $^ -o $@

#############################################################

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
