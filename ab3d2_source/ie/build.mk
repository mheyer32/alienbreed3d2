IE_TARGET ?= ab3d2_ie68.ie68
IE_MAP ?= $(BUILD_DIR)/ie68.map
IE_SYMBOLS ?= diag_symbols.lua
IE_DIAG_SYMBOLS_FILE ?= ie/diag_symbols.txt
IE_DIAG_SYMBOL_NAMES = $(shell cat $(IE_DIAG_SYMBOLS_FILE) 2>/dev/null)
IE_MENU_BUILD_DIR ?= $(BUILD_DIR)/ie_menu
IE_UNPACKED_MEDIA_DIR ?= $(BUILD_DIR)/ie_unpacked/media
MEDIA_PROFILE ?= original
IE_MEDIA_PROFILE_DIR ?= $(BUILD_DIR)/ie_media/$(MEDIA_PROFILE)
IE_PROFILE_BUILD_DIR ?= $(BUILD_DIR)/ie/$(MEDIA_PROFILE)
VLINK ?= $(shell command -v vlink 2>/dev/null || printf /opt/amiga/bin/vlink)

IE_PROFILE_DEFS :=
IE_PROFILE_INCLUDES :=
IE_MEDIA_PROFILE_STAMP :=

ifeq ($(MEDIA_PROFILE),original)
else ifeq ($(MEDIA_PROFILE),redux-high)
IE_PROFILE_DEFS += -DIE_MEDIA_REDUX_HIGH=1
IE_PROFILE_INCLUDES += -I$(IE_MEDIA_PROFILE_DIR)/includes
IE_MEDIA_PROFILE_STAMP := $(IE_MEDIA_PROFILE_DIR)/.stamp
else ifeq ($(MEDIA_PROFILE),redux-low)
IE_PROFILE_DEFS += -DIE_MEDIA_REDUX_LOW=1
IE_PROFILE_INCLUDES += -I$(IE_MEDIA_PROFILE_DIR)/includes
IE_MEDIA_PROFILE_STAMP := $(IE_MEDIA_PROFILE_DIR)/.stamp
else
$(error Unsupported MEDIA_PROFILE=$(MEDIA_PROFILE); use original, redux-high, or redux-low)
endif

.PHONY: ie68 ie68_sw ie68-redux-high ie68-redux-low

ie68: ie68_sw

ie68-redux-high:
	$(MAKE) ie68 MEDIA_PROFILE=redux-high IE_TARGET=ab3d2_ie68_redux_high.ie68 IE_MAP=$(BUILD_DIR)/ie68_redux_high.map

ie68-redux-low:
	$(MAKE) ie68 MEDIA_PROFILE=redux-low IE_TARGET=ab3d2_ie68_redux_low.ie68 IE_MAP=$(BUILD_DIR)/ie68_redux_low.map

$(IE_MENU_BUILD_DIR)/menu_assets.stamp: menu/back2.raw menu/credits_only.raw menu/font16x16.raw2 menu/back.pal menu/firepal.pal2 menu/font16x16.pal2 ie/tools/convert_menu_assets.py
	$(info Converting IE menu assets)
	@python3 ie/tools/convert_menu_assets.py --source menu --out $(IE_MENU_BUILD_DIR)

$(IE_UNPACKED_MEDIA_DIR)/.stamp: ie/tools/unpack_sb_assets.py
	$(info Unpacking IE runtime media assets)
	@python3 ie/tools/unpack_sb_assets.py --source ../media --out $(IE_UNPACKED_MEDIA_DIR)

$(BUILD_DIR)/ie_media/redux-high/.stamp: ie/tools/prepare_media_profile.py
	$(info Preparing IE Redux high media profile)
	@python3 ie/tools/prepare_media_profile.py --profile redux-high --repo-root .. --out $(BUILD_DIR)/ie_media/redux-high
	@touch $@

$(BUILD_DIR)/ie_media/redux-low/.stamp: ie/tools/prepare_media_profile.py
	$(info Preparing IE Redux low media profile)
	@python3 ie/tools/prepare_media_profile.py --profile redux-low --repo-root .. --out $(BUILD_DIR)/ie_media/redux-low
	@touch $@

ie68_sw: $(IE_MENU_BUILD_DIR)/menu_assets.stamp $(IE_UNPACKED_MEDIA_DIR)/.stamp $(IE_MEDIA_PROFILE_STAMP)
	$(info Assembling full software renderer IE build from hires.s + IE platform)
	@mkdir -p $(BUILD_DIR) $(IE_PROFILE_BUILD_DIR)
	@PREFIX=$$(./getprefix.sh "$(CC)"); \
	$(ASS) -m68020 -chklabels -align -maxerrors=200 \
		-Dmnu_nocode=1 -DUSE_16X16_TEXEL_MULS -DIFD=1 -DIS_IE=1 $(IE_PROFILE_DEFS) \
		$(IE_PROFILE_INCLUDES) -I../ -I$$PREFIX/m68k-amigaos/ndk-include -I../media -I../media/includes \
		-Fhunk hires.s -o $(IE_PROFILE_BUILD_DIR)/ie_hires.o
	@$(ASS) -m68020 -chklabels -align -maxerrors=200 \
		-DIFD=1 -DIS_IE=1 $(IE_PROFILE_DEFS) -Fhunk ie/ie_hires_platform.s -o $(IE_PROFILE_BUILD_DIR)/ie_hires_platform.o
	@$(VLINK) -M -b rawbin1 -Ttext 0x1000 \
		-N .bsschip .bss -N .datachip .data \
		-o $(IE_TARGET) $(IE_PROFILE_BUILD_DIR)/ie_hires.o $(IE_PROFILE_BUILD_DIR)/ie_hires_platform.o > $(IE_MAP)
	@awk -v names="$(IE_DIAG_SYMBOL_NAMES)" '\
		BEGIN { n = split(names, ordered, /[[:space:]]+/); print "return {" } \
		BEGIN { for (i = 1; i <= n; i++) want[ordered[i]] = 1 } \
		/^  0x[0-9A-Fa-f]+ / { sym = $$2; sub(/:$$/, "", sym); if ((sym in want) && !(sym in seen)) { printf("  %s = %s,\n", sym, $$1); seen[sym] = 1 } } \
		END { missing = 0; for (i = 1; i <= n; i++) if (!(ordered[i] in seen)) { printf("missing IE diagnostic symbol: %s\n", ordered[i]) > "/dev/stderr"; missing = 1 } print "}"; exit missing }' \
		$(IE_MAP) > $(IE_SYMBOLS)
	@cp $(IE_SYMBOLS) ie/diag_symbols.lua
