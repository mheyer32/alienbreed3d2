CC=m68k-amigaos-gcc
ASS=vasmm68k_mot
LINK=vlink

PREFIX = $(shell ./getprefix.sh "$(CC)")

#-noixemul
#-fbaserel
#-mcrt=clib2
#-mcrt=nix13
#-msmall-code
#-Wa,-adhln
#-mregparm=4
#-v   #verbose
#-fstrength-reduce

CLIB_CFLAGS = -mcrt=clib2 -DUSECLIB2 -mregparm=4
CLIB_LDFLAGS =

NOIXEMUL_CFLAGS = -noixemul -DUSENOIXEMUL -mregparm=4
NOIXEMUL_LDFLAGS =

USEIXEMUL ?= 1

ifeq ($(USEIXEMUL), 1)
RUNTIME_CFLAGS = $(NOIXEMUL_CFLAGS)
RUNTIME_LDFLAGS = $(NOIXEMUL_LDFLAGS)
else
	RUNTIME_CFLAGS = $(CLIB_CFLAGS)
	RUNTIME_LDFLAGS = $(CLIB_LDFLAGS
endif

#
CFLAGS = $(RUNTIME_CFLAGS)
CFLAGS += -fbaserel -m68030 -m68881 -msmall-code
CFLAGS += -Ofast -fstrength-reduce -fomit-frame-pointer
CFLAGS += -Werror -Wimplicit -Wstrict-prototypes

#-DRANGECHECK
CFLAGS += -DNDEBUG -D__BIG_ENDIAN__ -DAMIGA -D__NO_NET_API

LDFLAGS = $(RUNTIME_LDFLAGS)
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


INTERMEDIATE =$(CURDIR)/build/
OUT = $(CURDIR)/bin/

OBJS = 

OUTOBJS = $(addprefix $(INTERMEDIATE), $(OBJS))

#$(info $(OBJS))

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
