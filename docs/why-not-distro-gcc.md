# Why not the distro compiler?

> **TL;DR:** `apt install gcc-m68k-linux-gnu` will silently break any program
> using 64-bit arithmetic on the base 68000. The failure is completely silent --
> no crash message, no output, just an infinite exception loop.

## The problem

Debian/Ubuntu's `gcc-m68k-linux-gnu` targets Linux on 68k, which requires an
MMU (68010+ minimum). The compiler and its `libgcc.a` are built for the 68020
or later.

While `-m68000` controls code generation for **your** code, `libgcc.a` is
pre-compiled and contains 68020-only instructions:

| Instruction   | What it does                  | Why it fails on 68000           |
|---------------|-------------------------------|---------------------------------|
| `BSR.L`       | 32-bit PC-relative call       | 68000 only has 8/16-bit offsets |
| `EXTB.L`      | Sign-extend byte to long      | 68020+ only                     |
| `MULS.L`/`MULU.L` | 32x32 multiply           | 68000 only has 16x16            |
| `DIVS.L`/`DIVU.L` | 32/32 hardware divide    | 68000 only has 32/16            |
| `RTD`         | Return and deallocate          | 68010+                          |

Any `long long` multiply, divide, or modulus -- including inside `strtoull`,
`vsnprintf`, and `strtoimax` -- pulls in these 68020 libgcc functions and causes
the 68000 to silently hang.

## What `--with-cpu=68000` enforces

Building GCC with `--with-cpu=68000` ensures:

- Only base 68000 instructions are emitted (in both your code and libgcc)
- Branches use 8/16-bit offsets (no `BSR.L`)
- Software division loops instead of `DIVS.L`/`DIVU.L`
- `EXT.W` + `EXT.L` instead of `EXTB.L`
- `MULS.W`/`MULU.W` (16x16->32) for multiplication

## Comparison

| Factor                | Distro `m68k-linux-gnu-gcc`     | This toolchain (`m68k-elf-gcc`) |
|-----------------------|---------------------------------|---------------------------------|
| Default CPU           | 68020+                          | 68000                           |
| ELF target            | m68k-linux-gnu (Linux ABI)      | m68k-elf (bare metal)           |
| libgcc instructions   | Contains 68020 instructions     | 68000 only                      |
| `BSR.L` emitted?      | Yes (causes hang)               | No                              |
| 32/32 divide          | `DIVS.L` (68020 hardware)       | Software loop                   |
