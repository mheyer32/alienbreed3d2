IE_BIN_DIR ?= ie/bin
IE_TARGET ?= $(IE_BIN_DIR)/ab3d2_ie68.ie68
IE_MAP ?= $(BUILD_DIR)/ie68.map
IE_SYMBOLS ?= diag_symbols.lua
IE_DIAG_SYMBOLS_OUT ?= ie/diag_symbols.lua
IE_ENGINE_SOURCE ?= ../../IntuitionEngine
IE_ENGINE ?= $(IE_ENGINE_SOURCE)/bin/IntuitionEngine
ifeq ($(origin IE_HEADLESS_ENGINE),undefined)
IE_HEADLESS_ENGINE := $(IE_ENGINE_SOURCE)/bin/ie_headless
IE_BUILD_HEADLESS ?= 1
else
IE_BUILD_HEADLESS ?= 0
endif
ifeq ($(origin IE_GAMEPAD_ENGINE),undefined)
IE_GAMEPAD_ENGINE := $(IE_HEADLESS_ENGINE)
IE_BUILD_GAMEPAD_ENGINE ?= $(IE_BUILD_HEADLESS)
else
IE_BUILD_GAMEPAD_ENGINE ?= 0
endif
IE_GAMEPAD_ACCEPTANCE_ENGINE ?= $(IE_ENGINE)
IE68_REDUX_HIGH ?= $(IE_BIN_DIR)/ab3d2_ie68_redux_high.ie68
IE68_JIT_PROGRESS_SCRIPT ?= $(IE_BIN_DIR)/ab3d2_ie68_guest_progress.ies
IE68_REDUX_HIGH_JIT_PROGRESS_SCRIPT ?= $(IE_BIN_DIR)/ab3d2_ie68_redux_high_progress.ies
IE_DIAG_SYMBOLS_FILE ?= ie/diag_symbols.txt
IE_DIAG_SYMBOL_NAMES = $(shell cat $(IE_DIAG_SYMBOLS_FILE) 2>/dev/null)
IE_MENU_BUILD_DIR ?= $(BUILD_DIR)/ie_menu
IE_UNPACKED_MEDIA_DIR ?= $(BUILD_DIR)/ie_unpacked/media
IE_ORIGINAL_RUNTIME_DIR ?= $(BUILD_DIR)/ie_original_runtime
IE_SOURCE_ROOT ?= .
IE_SOURCE_OVERLAY ?= $(BUILD_DIR)/ie-source
IE_HIRES_SOURCE ?= $(IE_SOURCE_OVERLAY)/hires.s
IE_OVERLAY_PREPARE ?= ie/tools/prepare_source_overlay.py
IE_PATCH_DIR ?= ie/patches
IE_ENTRY_MAKEFILE ?= ie/Makefile
IE_GAMEPAD_TEST ?= 0
IE_FPS_TEST ?= 0
IE_BLITTER_TEST ?= 0
MEDIA_PROFILE ?= original
IE_MEDIA_PROFILE_DIR ?= $(BUILD_DIR)/ie_media/$(MEDIA_PROFILE)
IE_PROFILE_BUILD_DIR ?= $(BUILD_DIR)/ie/$(MEDIA_PROFILE)
IE_MEDIA_PROFILE_INCLUDE ?= $(IE_PROFILE_BUILD_DIR)/media_profile.i
VLINK ?= $(shell command -v vlink 2>/dev/null || printf /opt/amiga/bin/vlink)

IE_PROFILE_DEFS :=
IE_PROFILE_INCLUDES :=
IE_MEDIA_PROFILE_STAMP :=
IE_MEDIA_ROOT := media/
IE_SOUND_ROOT := media/ab3dsfx/

ifeq ($(IE_GAMEPAD_TEST),1)
IE_PROFILE_DEFS += -DIE_GAMEPAD_TEST=1
else ifeq ($(IE_GAMEPAD_TEST),0)
else
$(error Unsupported IE_GAMEPAD_TEST=$(IE_GAMEPAD_TEST); use 0 or 1)
endif

ifeq ($(IE_FPS_TEST),1)
IE_PROFILE_DEFS += -DIE_FPS_TEST=1
else ifeq ($(IE_FPS_TEST),0)
else
$(error Unsupported IE_FPS_TEST=$(IE_FPS_TEST); use 0 or 1)
endif

ifeq ($(IE_BLITTER_TEST),1)
IE_PROFILE_DEFS += -DIE_BLITTER_TEST=1
else ifeq ($(IE_BLITTER_TEST),0)
else
$(error Unsupported IE_BLITTER_TEST=$(IE_BLITTER_TEST); use 0 or 1)
endif

ifeq ($(MEDIA_PROFILE),original)
else ifeq ($(MEDIA_PROFILE),redux-high)
IE_PROFILE_INCLUDES += -I$(IE_MEDIA_PROFILE_DIR)/includes
IE_MEDIA_PROFILE_STAMP := $(IE_MEDIA_PROFILE_DIR)/.stamp
IE_MEDIA_ROOT := _build/ie_media/redux-high/
IE_SOUND_ROOT := _build/ie_media/redux-high/soundfx/
else
$(error Unsupported MEDIA_PROFILE=$(MEDIA_PROFILE); use original or redux-high)
endif

.PHONY: ie68 ie68-raw ie68_sw ie68-all ie68-redux-high ie68-pack ie68-pack-test ie68-pack-smoke ie68-pack-save-test ie68-original-pack-smoke ie68-original-pack-save-test ie68-jit-progress-test ie68-gamepad-test ie68-gamepad-acceptance ie68-fps-test ie68-blitter-test \
	ie-source-overlay ie-patches-check ie-source-overlay-test ie-prose-check

ie68:
	$(MAKE) -f $(IE_ENTRY_MAKEFILE) ie68-raw IE_TARGET=$(BUILD_DIR)/ab3d2_ie68_raw.ie68 IE_MAP=$(BUILD_DIR)/ie68.map IE_SYMBOLS=$(BUILD_DIR)/diag_symbols_ie68.lua
	python3 ie/tools/prepare_original_runtime.py --media-root $(IE_UNPACKED_MEDIA_DIR) --output $(IE_ORIGINAL_RUNTIME_DIR)
	python3 ie/tools/pack_ie68.py $(BUILD_DIR)/ab3d2_ie68_raw.ie68 $(IE_ORIGINAL_RUNTIME_DIR) _build/ie_unpacked/media $(IE_BIN_DIR)/ab3d2_ie68.ie68

ie68-raw: ie68_sw

ie-source-overlay:
	@python3 $(IE_OVERLAY_PREPARE) --source-root $(IE_SOURCE_ROOT) --patch-dir $(IE_PATCH_DIR) --output $(IE_SOURCE_OVERLAY)

ie-patches-check:
	@python3 $(IE_OVERLAY_PREPARE) --source-root $(IE_SOURCE_ROOT) --patch-dir $(IE_PATCH_DIR) --output $(IE_SOURCE_OVERLAY) --check

ie-source-overlay-test:
	@python3 ie/tools/test_source_overlay.py

ie-prose-check:
	@python3 ie/tools/check_prose.py
	@python3 ie/tools/test_readme_contract.py

ie68-all:
	$(MAKE) -f $(IE_ENTRY_MAKEFILE) ie68
	$(MAKE) -f $(IE_ENTRY_MAKEFILE) ie68-redux-high
	@cp $(BUILD_DIR)/diag_symbols_ie68.lua ie/diag_symbols.lua

ie68-redux-high:
	$(MAKE) -f $(IE_ENTRY_MAKEFILE) ie68-raw MEDIA_PROFILE=redux-high IE_TARGET=$(BUILD_DIR)/ab3d2_ie68_redux_high_raw.ie68 IE_MAP=$(BUILD_DIR)/ie68_redux_high.map IE_SYMBOLS=$(BUILD_DIR)/diag_symbols_ie68_redux_high.lua
	python3 ie/tools/pack_ie68.py $(BUILD_DIR)/ab3d2_ie68_redux_high_raw.ie68 $(BUILD_DIR)/ie_media/redux-high _build/ie_media/redux-high $(IE68_REDUX_HIGH)

ie68-pack: ie68

ie68-pack-test:
	python3 ie/tools/test_pack_ie68.py
	python3 ie/tools/test_build_mk.py
	python3 ie/tools/test_pack_loader_source.py
	python3 ie/tools/test_generate_pack_save_smoke.py
	python3 ie/tools/test_prepare_original_runtime.py

ie68-pack-smoke: ie68-redux-high
ifeq ($(IE_BUILD_HEADLESS),1)
	$(MAKE) -C $(IE_ENGINE_SOURCE) headless
endif
	@tmp=$$(mktemp -d /tmp/ab3d2-ie68-pack.XXXXXX); trap 'rm -r "$$tmp"' EXIT; \
	cp $(IE68_REDUX_HIGH) "$$tmp/game.ie68"; \
	log=$$(mktemp); trap 'rm -f "$$log"; rm -r "$$tmp"' EXIT; \
	if ! IE_NO_IPC=1 $(IE_HEADLESS_ENGINE) --script-owned-term -script $(IE68_REDUX_HIGH_JIT_PROGRESS_SCRIPT) "$$tmp/game.ie68" >"$$log" 2>&1; then cat "$$log"; exit 1; fi; \
	cat "$$log"; \
	grep -Fq 'AB3D2_GUEST_PROGRESS mode=jit ' "$$log" || { echo 'ie68-pack-smoke: guest progress was not reported' >&2; exit 1; }; \
	unexpected=$$(find "$$tmp" -mindepth 1 ! -name game.ie68 -print -quit); \
	test -z "$$unexpected" || { echo "ie68-pack-smoke: unexpected runtime file $$unexpected" >&2; exit 1; }

ie68-pack-save-test: ie68-redux-high
	python3 ie/tools/generate_pack_save_smoke.py $(BUILD_DIR)/diag_symbols_ie68_redux_high.lua ie/pack_save_smoke.ies $(BUILD_DIR)/pack_save_smoke.ies
ifeq ($(IE_BUILD_HEADLESS),1)
	$(MAKE) -C $(IE_ENGINE_SOURCE) headless
endif
	@tmp=$$(mktemp -d /tmp/ab3d2-ie68-save.XXXXXX); log=$$(mktemp); trap 'rm -f "$$log"; rm -r "$$tmp"' EXIT; \
	cp $(IE68_REDUX_HIGH) "$$tmp/game.ie68"; \
	if ! IE_NO_IPC=1 $(IE_HEADLESS_ENGINE) --script-owned-term -script $(BUILD_DIR)/pack_save_smoke.ies "$$tmp/game.ie68" >"$$log" 2>&1; then cat "$$log"; exit 1; fi; \
	cat "$$log"; \
	grep -Fq 'AB3D2_PACK_SAVE PASS' "$$log" || { echo 'ie68-pack-save-test: save override was not proved' >&2; exit 1; }; \
	test -f "$$tmp/ab3d2-save.dat" || { echo 'ie68-pack-save-test: save file was not created' >&2; exit 1; }; \
	rm -f "$$tmp/ab3d2-save.dat"; \
	if ! IE_NO_IPC=1 $(IE_HEADLESS_ENGINE) --script-owned-term -script $(IE68_REDUX_HIGH_JIT_PROGRESS_SCRIPT) "$$tmp/game.ie68" >"$$log" 2>&1; then cat "$$log"; exit 1; fi; \
	grep -Fq 'AB3D2_GUEST_PROGRESS mode=jit ' "$$log" || { cat "$$log"; echo 'ie68-pack-save-test: embedded boot fallback did not reach gameplay' >&2; exit 1; }

ie68-original-pack-smoke: ie68
ifeq ($(IE_BUILD_HEADLESS),1)
	$(MAKE) -C $(IE_ENGINE_SOURCE) headless
endif
	@tmp=$$(mktemp -d /tmp/ab3d2-ie68-original-pack.XXXXXX); log=$$(mktemp); trap 'rm -f "$$log"; rm -r "$$tmp"' EXIT; \
	cp $(IE_BIN_DIR)/ab3d2_ie68.ie68 "$$tmp/game.ie68"; \
	if ! IE_NO_IPC=1 $(IE_HEADLESS_ENGINE) --script-owned-term -script $(IE68_JIT_PROGRESS_SCRIPT) "$$tmp/game.ie68" >"$$log" 2>&1; then cat "$$log"; exit 1; fi; \
	cat "$$log"; \
	grep -Fq 'AB3D2_GUEST_PROGRESS mode=jit ' "$$log" || { echo 'ie68-original-pack-smoke: guest progress was not reported' >&2; exit 1; }; \
	unexpected=$$(find "$$tmp" -mindepth 1 ! -name game.ie68 -print -quit); \
	test -z "$$unexpected" || { echo "ie68-original-pack-smoke: unexpected runtime file $$unexpected" >&2; exit 1; }

ie68-original-pack-save-test: ie68
	python3 ie/tools/generate_pack_save_smoke.py $(BUILD_DIR)/diag_symbols_ie68.lua ie/pack_save_smoke.ies $(BUILD_DIR)/pack_save_smoke_original.ies
ifeq ($(IE_BUILD_HEADLESS),1)
	$(MAKE) -C $(IE_ENGINE_SOURCE) headless
endif
	@tmp=$$(mktemp -d /tmp/ab3d2-ie68-original-save.XXXXXX); log=$$(mktemp); trap 'rm -f "$$log"; rm -r "$$tmp"' EXIT; \
	cp $(IE_BIN_DIR)/ab3d2_ie68.ie68 "$$tmp/game.ie68"; \
	if ! IE_NO_IPC=1 $(IE_HEADLESS_ENGINE) --script-owned-term -script $(BUILD_DIR)/pack_save_smoke_original.ies "$$tmp/game.ie68" >"$$log" 2>&1; then cat "$$log"; exit 1; fi; \
	cat "$$log"; \
	grep -Fq 'AB3D2_PACK_SAVE PASS' "$$log" || { echo 'ie68-original-pack-save-test: save override was not proved' >&2; exit 1; }; \
	test -f "$$tmp/ab3d2-save.dat" || { echo 'ie68-original-pack-save-test: save file was not created' >&2; exit 1; }; \
	rm -f "$$tmp/ab3d2-save.dat"; \
	if ! IE_NO_IPC=1 $(IE_HEADLESS_ENGINE) --script-owned-term -script $(IE68_JIT_PROGRESS_SCRIPT) "$$tmp/game.ie68" >"$$log" 2>&1; then cat "$$log"; exit 1; fi; \
	grep -Fq 'AB3D2_GUEST_PROGRESS mode=jit ' "$$log" || { cat "$$log"; echo 'ie68-original-pack-save-test: no-save fallback did not reach gameplay' >&2; exit 1; }

ie68-jit-progress-test: ie68-redux-high
ifeq ($(IE_BUILD_HEADLESS),1)
	$(MAKE) -C $(IE_ENGINE_SOURCE) headless
endif
	@log=$$(mktemp); trap 'rm -f "$$log"' EXIT; \
	if ! IE_NO_IPC=1 $(IE_HEADLESS_ENGINE) -file-root "$$PWD" -script $(IE68_REDUX_HIGH_JIT_PROGRESS_SCRIPT) $(IE68_REDUX_HIGH) >"$$log" 2>&1; then \
		cat "$$log"; exit 1; \
	fi; \
	cat "$$log"; \
	grep -Fq 'AB3D2_GUEST_PROGRESS mode=jit ' "$$log" || { \
		echo 'ie68-jit-progress-test: progress script did not complete under the M68K JIT' >&2; exit 1; \
	}

ie68-gamepad-test:
ifeq ($(IE_BUILD_GAMEPAD_ENGINE),1)
	$(MAKE) -C $(IE_ENGINE_SOURCE) headless
endif
	$(MAKE) -f $(IE_ENTRY_MAKEFILE) ie68-raw IE_GAMEPAD_TEST=1 IE_TARGET=$(IE_BIN_DIR)/ab3d2_ie68_gamepad_test.ie68 IE_MAP=$(BUILD_DIR)/ie68_gamepad_test.map IE_SYMBOLS=$(BUILD_DIR)/diag_symbols_gamepad_test.lua IE_DIAG_SYMBOLS_FILE=ie/diag_gamepad_symbols.txt IE_DIAG_SYMBOLS_OUT=$(IE_BIN_DIR)/diag_gamepad_symbols.lua
	@cp ie/gamepad_test.ies $(IE_BIN_DIR)/gamepad_test.ies
	@log=$$(mktemp); result=$(IE_BIN_DIR)/gamepad-test.result; trap 'rm -f "$$log" "$$result"' EXIT; rm -f "$$result"; \
	if ! IE_NO_IPC=1 $(IE_GAMEPAD_ENGINE) --script-owned-term -file-root "$$PWD" -script $(IE_BIN_DIR)/gamepad_test.ies $(IE_BIN_DIR)/ab3d2_ie68_gamepad_test.ie68 >"$$log" 2>&1; then \
		cat "$$log"; exit 1; \
	fi; \
	cat "$$log"; \
	grep -Fq 'AB3D2_GAMEPAD PASS' "$$result" || { \
		 test ! -f "$$result" || cat "$$result"; \
		 echo 'ie68-gamepad-test: diagnostic did not report success' >&2; exit 1; \
	}

ie68-fps-test:
ifeq ($(IE_BUILD_HEADLESS),1)
	$(MAKE) -C $(IE_ENGINE_SOURCE) headless
endif
	$(MAKE) -f $(IE_ENTRY_MAKEFILE) ie68-raw IE_FPS_TEST=1 IE_TARGET=$(IE_BIN_DIR)/ab3d2_ie68_fps_test.ie68 IE_MAP=$(BUILD_DIR)/ie68_fps_test.map IE_SYMBOLS=$(BUILD_DIR)/diag_symbols_fps_test.lua IE_DIAG_SYMBOLS_FILE=ie/diag_fps_symbols.txt IE_DIAG_SYMBOLS_OUT=$(IE_BIN_DIR)/diag_symbols_fps_test.lua
	@cp ie/fps_test.ies $(IE_BIN_DIR)/fps_test.ies
	@log=$$(mktemp); result=$(IE_BIN_DIR)/fps-test.result; trap 'rm -f "$$log" "$$result"' EXIT; rm -f "$$result"; \
	if ! IE_NO_IPC=1 $(IE_HEADLESS_ENGINE) --script-owned-term -file-root "$$PWD" -script $(IE_BIN_DIR)/fps_test.ies $(IE_BIN_DIR)/ab3d2_ie68_fps_test.ie68 >"$$log" 2>&1; then \
		cat "$$log"; exit 1; \
	fi; \
	cat "$$log"; \
	grep -Fq 'AB3D2_FPS PASS' "$$log" || { \
		test ! -f "$$result" || cat "$$result"; \
		echo 'ie68-fps-test: diagnostic did not report success' >&2; exit 1; \
	}

ie68-blitter-test:
ifeq ($(IE_BUILD_HEADLESS),1)
	$(MAKE) -C $(IE_ENGINE_SOURCE) headless
endif
	$(MAKE) -f $(IE_ENTRY_MAKEFILE) ie68-raw IE_BLITTER_TEST=1 MEDIA_PROFILE=redux-high IE_TARGET=$(IE_BIN_DIR)/ab3d2_ie68_blitter_test.ie68 IE_MAP=$(BUILD_DIR)/ie68_blitter_test.map IE_SYMBOLS=$(BUILD_DIR)/diag_symbols_blitter_test.lua IE_DIAG_SYMBOLS_FILE=ie/diag_blitter_symbols.txt IE_DIAG_SYMBOLS_OUT=$(IE_BIN_DIR)/diag_blitter_symbols.lua
	@cp ie/blitter_test.ies $(IE_BIN_DIR)/blitter_test.ies
	@log=$$(mktemp); result=$(IE_BIN_DIR)/blitter-test.result; trap 'rm -f "$$log" "$$result"' EXIT; rm -f "$$result"; \
	if ! IE_NO_IPC=1 $(IE_HEADLESS_ENGINE) --script-owned-term -file-root "$$PWD" -script $(IE_BIN_DIR)/blitter_test.ies $(IE_BIN_DIR)/ab3d2_ie68_blitter_test.ie68 >"$$log" 2>&1; then \
		cat "$$log"; exit 1; \
	fi; \
	cat "$$log"; \
	grep -Fq 'AB3D2_BLITTER PASS' "$$result" || { \
		test ! -f "$$result" || cat "$$result"; \
		echo 'ie68-blitter-test: diagnostic did not report success' >&2; exit 1; \
	}

ie68-gamepad-acceptance: ie68-redux-high
	@cp ie/gamepad_acceptance.ies $(IE_BIN_DIR)/gamepad_acceptance.ies
	@cp $(BUILD_DIR)/diag_symbols_ie68_redux_high.lua $(IE_BIN_DIR)/gamepad_acceptance_symbols.lua
	@IE_NO_IPC=1 $(IE_GAMEPAD_ACCEPTANCE_ENGINE) --script-owned-term -file-root "$$PWD" -script $(IE_BIN_DIR)/gamepad_acceptance.ies $(IE68_REDUX_HIGH)

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

ie68_sw: ie-source-overlay $(IE_MENU_BUILD_DIR)/menu_assets.stamp $(IE_UNPACKED_MEDIA_DIR)/.stamp $(IE_MEDIA_PROFILE_STAMP)
	$(info Assembling full software renderer IE build from the generated upstream-source overlay + IE platform)
	@mkdir -p $(BUILD_DIR) $(IE_PROFILE_BUILD_DIR) $(dir $(IE_TARGET))
	@printf '%s\n' \
		'.ie_media_prefix:' \
		"				dc.b	'$(IE_MEDIA_ROOT)',0" \
		'.ie_sfx_prefix:' \
		"				dc.b	'$(IE_SOUND_ROOT)',0" \
		> $(IE_MEDIA_PROFILE_INCLUDE)
	@PREFIX=$$($(abspath $(IE_SOURCE_ROOT))/getprefix.sh "$(CC)"); \
	cd $(IE_SOURCE_OVERLAY) && $(ASS) -m68020 -chklabels -align -maxerrors=200 \
		-Dmnu_nocode=1 -DUSE_16X16_TEXEL_MULS -DIFD=1 -DIS_IE=1 $(IE_PROFILE_DEFS) \
		-I$(abspath $(IE_MEDIA_PROFILE_DIR)/includes) -I$(abspath $(IE_PROFILE_BUILD_DIR)) -I. -I$(abspath $(IE_SOURCE_ROOT)) -I$(abspath $(IE_SOURCE_ROOT)/..) -I$$PREFIX/m68k-amigaos/ndk-include -I$(abspath $(IE_SOURCE_ROOT)/../media) -I$(abspath $(IE_SOURCE_ROOT)/../media/includes) \
		-Fhunk hires.s -o $(abspath $(IE_PROFILE_BUILD_DIR)/ie_hires.o)
	@$(ASS) -m68020 -chklabels -align -maxerrors=200 \
		-DIFD=1 -DIS_IE=1 $(IE_PROFILE_DEFS) -Fhunk ie/platform/ie_hires_platform.s -o $(IE_PROFILE_BUILD_DIR)/ie_hires_platform.o
	@$(VLINK) -M -b rawbin1 -Ttext 0x1000 \
		-N .bsschip .bss -N .datachip .data \
		-o $(IE_TARGET) $(IE_PROFILE_BUILD_DIR)/ie_hires.o $(IE_PROFILE_BUILD_DIR)/ie_hires_platform.o > $(IE_MAP)
	@awk -v names="$(IE_DIAG_SYMBOL_NAMES)" '\
		BEGIN { n = split(names, ordered, /[[:space:]]+/); print "return {" } \
		BEGIN { for (i = 1; i <= n; i++) want[ordered[i]] = 1 } \
		/^  0x[0-9A-Fa-f]+ / { sym = $$2; sub(/:$$/, "", sym); if ((sym in want) && !(sym in seen)) { printf("  %s = %s,\n", sym, $$1); seen[sym] = 1 } } \
		END { missing = 0; for (i = 1; i <= n; i++) if (!(ordered[i] in seen)) { printf("missing IE diagnostic symbol: %s\n", ordered[i]) > "/dev/stderr"; missing = 1 } print "}"; exit missing }' \
		$(IE_MAP) > $(IE_SYMBOLS)
	@cp $(IE_SYMBOLS) $(IE_DIAG_SYMBOLS_OUT)
ifeq ($(IE_GAMEPAD_TEST),0)
	@if grep -Eq 'IE_GAMEPAD_TEST|ie_gamepad_test_' $(IE_MAP); then \
		echo 'production IE map contains gamepad test-seam symbols' >&2; exit 1; \
	fi
endif
ifeq ($(IE_FPS_TEST),0)
	@if grep -Eq 'IE_FPS_TEST|ie_fps_test_' $(IE_MAP); then \
		echo 'production IE map contains FPS test-seam symbols' >&2; exit 1; \
	fi
endif
ifeq ($(IE_BLITTER_TEST),0)
	@if grep -Eq 'IE_BLITTER_TEST|ie_blitter_test_' $(IE_MAP); then \
		echo 'production IE map contains blitter test-seam symbols' >&2; exit 1; \
	fi
endif
