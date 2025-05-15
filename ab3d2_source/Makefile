#disable built-in rules
.SUFFIXES:
# don't delete intermeditae .o and build directories
.PRECIOUS: %.o %/.
#enable second expansion, so we can use $(@D) as dependency
.SECONDEXPANSION:

CC=m68k-amigaos-gcc
LINK=m68k-amigaos-gcc
ASS=vasmm68k_mot
STRIP=m68k-amigaos-strip

#find the toolchain's directory
PREFIX = $(shell ./getprefix.sh "$(CC)")

FLAVORS =dev test release
CPUS =060 040 030

FLAVOR ?=dev
CPU ?=060

TARGETNAME = tkg_$(FLAVOR)_$(CPU)

SRC_DIR = c
BUILD_DIR ?= _build
INTERMEDIATE_DIR = $(BUILD_DIR)/$(CPU)/$(FLAVOR)

SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(INTERMEDIATE_DIR)/hires.o

OBJS +=$(SRCS:$(SRC_DIR)/%.c=$(INTERMEDIATE_DIR)/%.o)

#- DCD32VER
CFLAGS += --std=c99 -noixemul
LFLAGS += -noixemul

#Allow 040 + instructions to be emitted in runtime detection cases
AFLAGS = -Fhunk -m68060 -linedebug -chklabels -align -L listing.txt -Dmnu_nocode=1 -DUSE_16X16_TEXEL_MULS
AFLAGS += -I../ \
		  -I$(PREFIX)/m68k-amigaos/ndk-include \
		  -I../media \
		  -I../media/includes

#AFLAGS += -DMEMTRACK = 1

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

AFLAGS += -DBUILD_WITH_C
#Use gcc for linking the C build
$(TARGETNAME): $(OBJS)
	$(info Linking $@)
	$(LINK) $(LFLAGS) $(OBJS) -o $@
	$(info ========================================================)


all: $(foreach F,$(FLAVORS),$(foreach C,$(CPUS),build-$(F)-$(C)))

build-%:
	$(eval FLAVOR := $(strip $(word 1,$(subst -, ,$*))))
	$(eval CPU := $(strip $(word 2,$(subst -, ,$*))))
	$(if $(FLAVOR),,$(error Missing FLAVOR in $*))
	$(if $(CPU),,$(error Missing CPU in $*))
	$(MAKE) FLAVOR=$(FLAVOR) CPU=$(CPU) $(TARGETNAME)
#############################################################

clean:
	rm -f *.o
	rm -rf $(BUILD_DIR)

$(INTERMEDIATE_DIR)/%.o: $(SRC_DIR)/%.c Makefile
	$(info >>> build $@ from $<)
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -c $< -o $@

$(INTERMEDIATE_DIR)/%.o: $(SRC_DIR)/%.s Makefile
	$(info >>> build $@ from $<)
	@mkdir -p $(@D)
	@$(ASS) $(AFLAGS) $< -o $@

$(INTERMEDIATE_DIR)/%.o: %.s Makefile
	$(info >>> build $@ from $<)
	@mkdir -p $(@D)
	@$(ASS) $(AFLAGS) $< -o $@

%_stripped:	%
	$(STRIP) --strip-debug --strip-unneeded -o $@ $<

#############################################################
#
#############################################################
