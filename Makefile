PREFIX ?= $(HOME)/m68k-elf-toolchain

.PHONY: build fetch clean verify help

help:
	@echo "m68k-elf-toolchain"
	@echo ""
	@echo "Targets:"
	@echo "  make fetch    - Download pre-built toolchain from GitHub Releases"
	@echo "  make build    - Build toolchain from source (~20 min)"
	@echo "  make verify   - Verify installed toolchain is correct"
	@echo "  make clean    - Remove installed toolchain"
	@echo ""
	@echo "Options:"
	@echo "  PREFIX=<path>   Install location (default: ~/m68k-elf-toolchain)"
	@echo "  BUILD_GDB=1     Also build GDB (default: off)"
	@echo ""
	@echo "Example:"
	@echo "  make build PREFIX=/opt/m68k-elf BUILD_GDB=1"

fetch:
	bash fetch.sh $(PREFIX)

build:
	bash build.sh $(PREFIX)

verify:
	@echo "Checking for m68k-elf-gcc..."
	@$(PREFIX)/bin/m68k-elf-gcc --version | head -1
	@echo ""
	@echo "Checking --with-cpu=68000 (no 68020 instructions in libgcc)..."
	@LIBGCC=$$($(PREFIX)/bin/m68k-elf-gcc -m68000 -print-libgcc-file-name) && \
	 if $(PREFIX)/bin/m68k-elf-objdump -d "$$LIBGCC" | grep -qE '(muls\.l|mulu\.l|divs\.l|divu\.l|extb\.l)'; then \
	   echo "FAIL: libgcc.a contains 68020 instructions!"; exit 1; \
	 else \
	   echo "OK: libgcc.a contains only 68000 instructions"; \
	 fi
	@echo ""
	@echo "Checking binutils..."
	@$(PREFIX)/bin/m68k-elf-as --version | head -1
	@$(PREFIX)/bin/m68k-elf-ld --version | head -1
	@echo ""
	@echo "All checks passed."

clean:
	rm -rf $(PREFIX)
