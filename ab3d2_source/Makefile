#disable built-in rules
.SUFFIXES:
# don't delete intermeditae .o and build directories
.PRECIOUS: %.o %/.
#enable second expansion, so we can use $(@D) as dependency
.SECONDEXPANSION:

CC=m68k-amigaos-gcc
LINK=m68k-amigaos-gcc
ASS=vasmm68k_mot
VLINK=vlink
STRIP=m68k-amigaos-strip

#find the toolchain's directory
PREFIX = $(shell ./getprefix.sh "$(CC)")

FLAVORS =dev test release
CPUS =060 040 030
BUILDS =c asm

FLAVOR ?=dev
CPU ?=060
BUILD ?=c

TARGETNAME = tkg$(BUILD)_$(CPU)_$(FLAVOR)

SRC_DIR = c
BUILD_DIR ?= _build
INTERMEDIATE_DIR = $(BUILD_DIR)/$(CPU)/$(FLAVOR)/$(BUILD)

SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(INTERMEDIATE_DIR)/hires.o

ifeq ($(BUILD),c)
	OBJS +=$(SRCS:$(SRC_DIR)/%.c=$(INTERMEDIATE_DIR)/%.o) 
endif


$(info Variable FLAVOR is $(FLAVOR))
$(info Intermediate Directory is $(INTERMEDIATE_DIR))
$(info SRCS is $(SRCS))
$(info OBJS is $(OBJS))
$(info TARGETNAME is $(TARGETNAME))

#- DCD32VER
CFLAGS = -noixemul
LFLAGS = -noixemul 

#Allow 040 + instructions to be emitted in runtime detection cases
AFLAGS = -Fhunk -m68060 -linedebug -chklabels -align -L listing.txt -Dmnu_nocode=1 -DUSE_16X16_TEXEL_MULS
AFLAGS += -I../ \
		  -I$(PREFIX)/m68k-amigaos/ndk-include \
		  -I../media \
		  -I../media/includes

#AFLAGS += -DMEMTRACK = 1

VFLAGS = -b amigahunk -sc -l amiga -L $(PREFIX)m68k-amigaos/ndk/lib/libs

ifeq ($(FLAVOR),dev)
	AFLAGS += -DDEV=1 -DZONE_DEBUG=1
	CFLAGS += -O3 -DDEV -DZONE_DEBUG
	LFLAGS += -g -ggdb
else ifeq ($(FLAVOR),test)
	LFLAGS += -g -ggdb
	CFLAGS += -O3
else
	CFLAGS += -O3
endif

ifeq ($(CPU),040)
	AFLAGS += -DOPT040
	CFLAGS += -m68040 -mtune=68040
else ifeq ($(CPU),060)
	AFLAGS += -DOPT060
	CFLAGS += -m68060 -mtune=68060
else
	CFLAGS += -m68020-60 -mtune=68030
endif

ifeq ($(BUILD),c)
	AFLAGS += -DBUILD_WITH_C
#Use gcc for the C build
$(TARGETNAME): $(OBJS)
	$(LINK) $(LFLAGS) $(OBJS) -o $@ 

else
	LFLAGS += -nostartfiles -nodefaultlibs

$(TARGETNAME): $(OBJS)
	$(VLINK) $(VFLAGS) $(OBJS) -o $@ 
endif


all: $(foreach F,$(FLAVORS),$(foreach C,$(CPUS),$(foreach T,$(BUILDS),build-$(F)-$(C)-$(T))))

build-%:
	$(eval FLAVOR := $(strip $(word 1,$(subst -, ,$*))))
	$(eval CPU := $(strip $(word 2,$(subst -, ,$*))))
	$(eval BUILD := $(strip $(word 3,$(subst -, ,$*))))
	$(if $(FLAVOR),,$(error Missing FLAVOR in $*))
	$(if $(CPU),,$(error Missing CPU in $*))
	$(if $(BUILD),,$(error Missing BUILD in $*))
	$(MAKE) FLAVOR=$(FLAVOR) CPU=$(CPU) BUILD=$(BUILD) $(TARGETNAME)
#############################################################

clean:
	rm -f *.o
	rm -rf $(BUILD_DIR)

$(INTERMEDIATE_DIR)/%.o: $(SRC_DIR)/%.c Makefile
	$(info Building TARGETNAME $@ from source $<)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@
	
$(INTERMEDIATE_DIR)/%.o: $(SRC_DIR)/%.s Makefile
	$(info Building TARGETNAME $@ from source $<)
	@mkdir -p $(@D)
	$(ASS) $(AFLAGS) $< -o $@

$(INTERMEDIATE_DIR)/%.o: %.s Makefile
	$(info Building TARGETNAME $@ from source $<)
	@mkdir -p $(@D)
	$(ASS) $(AFLAGS) $< -o $@

#%_stripped:	%
#	$(STRIP) --strip-debug --strip-unneeded -o $@ $<

#############################################################
#
#############################################################
