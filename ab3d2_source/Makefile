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
IE_TARGET ?= ab3d2_ie68.ie68
IE_VOODOO_TARGET ?= ab3d2_ie68_voodoo.ie68
IE_ENTRY ?= ie/ie_main.s
IE_VOODOO_ENTRY ?= ie/ie_voodoo_main.s

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

IE_AFLAGS = -m68020 -devpac -chklabels -align -Dmnu_nocode=1 -DUSE_16X16_TEXEL_MULS
IE_AFLAGS += -I../ \
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

#Use gcc for linking the C build
$(TARGETNAME): $(OBJS)
	$(info Linking $@)
	$(LINK) $(LFLAGS) $(OBJS) -o $@
	$(info ========================================================)

.PHONY: bump_build
.PHONY: ie68 ie68_voodoo ie68_sw ie68_bootstrap

bump_build:
	./bumprev.py --build

ie68: ie68_sw

ie68_bootstrap:
	@if [ ! -f "$(IE_ENTRY)" ]; then \
		echo "Missing $(IE_ENTRY). Add IE port assembly sources first."; \
		exit 1; \
	fi
	$(info Assembling $(IE_TARGET) from $(IE_ENTRY))
	@$(ASS) $(IE_AFLAGS) -DIFD=1 -DIS_IE=1 -Fbin $(IE_ENTRY) -o $(IE_TARGET)

ie68_voodoo:
	@if [ ! -f "$(IE_VOODOO_ENTRY)" ]; then \
		echo "Missing $(IE_VOODOO_ENTRY). Add IE voodoo entry assembly first."; \
		exit 1; \
	fi
	$(info Assembling $(IE_VOODOO_TARGET) from $(IE_VOODOO_ENTRY))
	@$(ASS) $(IE_AFLAGS) -DIFD=1 -DIS_IE=1 -DIE_VOODOO=1 -Fbin $(IE_VOODOO_ENTRY) -o $(IE_VOODOO_TARGET)

ie68_sw:
	$(info Assembling full software renderer IE build from hires.s + IE shim)
	@mkdir -p $(BUILD_DIR)
	@PREFIX=$$(./getprefix.sh "$(CC)"); \
	$(ASS) -m68020 -chklabels -align -maxerrors=200 \
		-Dmnu_nocode=1 -DUSE_16X16_TEXEL_MULS -DIFD=1 -DIS_IE=1 \
		-I../ -I$$PREFIX/m68k-amigaos/ndk-include -I../media -I../media/includes \
		-Fhunk hires.s -o $(BUILD_DIR)/ie_hires.o
	@$(ASS) -m68020 -chklabels -align -maxerrors=200 \
		-DIFD=1 -DIS_IE=1 -Fhunk ie/ie_hires_shim.s -o $(BUILD_DIR)/ie_hires_shim.o
	@/opt/amiga/bin/vlink -b rawbin1 -Ttext 0x1000 \
		-N .bsschip .bss -N .datachip .data \
		-o $(IE_TARGET) $(BUILD_DIR)/ie_hires.o $(BUILD_DIR)/ie_hires_shim.o

new:	bump_build $(foreach F,$(FLAVORS),$(foreach C,$(CPUS),build-$(F)-$(C)))

all:	$(foreach F,$(FLAVORS),$(foreach C,$(CPUS),build-$(F)-$(C)))

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
	./bumprev.py

bump:
	./bumprev.py --revision


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
