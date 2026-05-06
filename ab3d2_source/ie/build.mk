IE_TARGET ?= ab3d2_ie68.ie68
IE_MAP ?= $(BUILD_DIR)/ie68.map
IE_SYMBOLS ?= diag_symbols.lua
IE_DIAG_SYMBOLS_FILE ?= ie/diag_symbols.txt
IE_DIAG_SYMBOL_NAMES = $(shell cat $(IE_DIAG_SYMBOLS_FILE) 2>/dev/null)
VLINK ?= $(shell command -v vlink 2>/dev/null || printf /opt/amiga/bin/vlink)

.PHONY: ie68 ie68_sw

ie68: ie68_sw

ie68_sw:
	$(info Assembling full software renderer IE build from hires.s + IE platform)
	@mkdir -p $(BUILD_DIR)
	@PREFIX=$$(./getprefix.sh "$(CC)"); \
	$(ASS) -m68020 -chklabels -align -maxerrors=200 \
		-Dmnu_nocode=1 -DUSE_16X16_TEXEL_MULS -DIFD=1 -DIS_IE=1 \
		-I../ -I$$PREFIX/m68k-amigaos/ndk-include -I../media -I../media/includes \
		-Fhunk hires.s -o $(BUILD_DIR)/ie_hires.o
	@$(ASS) -m68020 -chklabels -align -maxerrors=200 \
		-DIFD=1 -DIS_IE=1 -Fhunk ie/ie_hires_platform.s -o $(BUILD_DIR)/ie_hires_platform.o
	@$(VLINK) -M -b rawbin1 -Ttext 0x1000 \
		-N .bsschip .bss -N .datachip .data \
		-o $(IE_TARGET) $(BUILD_DIR)/ie_hires.o $(BUILD_DIR)/ie_hires_platform.o > $(IE_MAP)
	@awk -v names="$(IE_DIAG_SYMBOL_NAMES)" '\
		BEGIN { n = split(names, ordered, /[[:space:]]+/); print "return {" } \
		BEGIN { for (i = 1; i <= n; i++) want[ordered[i]] = 1 } \
		/^  0x[0-9A-Fa-f]+ / { sym = $$2; sub(/:$$/, "", sym); if ((sym in want) && !(sym in seen)) { printf("  %s = %s,\n", sym, $$1); seen[sym] = 1 } } \
		END { missing = 0; for (i = 1; i <= n; i++) if (!(ordered[i] in seen)) { printf("missing IE diagnostic symbol: %s\n", ordered[i]) > "/dev/stderr"; missing = 1 } print "}"; exit missing }' \
		$(IE_MAP) > $(IE_SYMBOLS)
	@cp $(IE_SYMBOLS) ie/diag_symbols.lua
