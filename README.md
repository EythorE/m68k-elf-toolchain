# m68k-elf-toolchain

Cross-compiler toolchain for the Motorola 68000, targeting bare-metal `m68k-elf`.

Built with `--with-cpu=68000` so that **both your code and libgcc** contain only
base 68000 instructions. This is critical for hardware like the Sega Mega Drive
(7.67 MHz 68000, no MMU, no 68020 extensions).

## Components

| Component  | Version |
|------------|--------|
| binutils   | 2.43    |
| GCC        | 14.2.0  |
| GMP        | 6.2.1   |
| MPFR       | 4.2.1   |
| MPC        | 1.3.1   |
| GDB        | 15.2 |

## Quick start

### Option 1: Fetch pre-built (x86_64 Linux)

```bash
bash fetch.sh
export PATH=~/m68k-elf-toolchain/bin:$PATH
```

### Option 2: Build from source

```bash
bash build.sh
export PATH=~/m68k-elf-toolchain/bin:$PATH
```

Only `build-essential` is required. GMP/MPFR/MPC are built in-tree.

### Custom install prefix

```bash
bash build.sh /opt/m68k-elf
# or
bash fetch.sh /opt/m68k-elf
```

## Verify

Check that the installed toolchain is correct and contains no 68020 instructions:

```bash
make verify
```

## Why not `apt install gcc-m68k-linux-gnu`?

The distro compiler's `libgcc.a` is pre-compiled for the 68020 and contains
instructions (`MULU.L`, `DIVU.L`, `BSR.L`, `EXTB.L`) that cause **silent hangs**
on the base 68000. The `-m68000` flag only affects *your* code -- it does not
recompile libgcc.

Building GCC with `--with-cpu=68000` ensures libgcc itself only uses 68000
instructions. See [docs/why-not-distro-gcc.md](docs/why-not-distro-gcc.md) for
the full explanation.

## CI

The GitHub Actions workflow (`.github/workflows/build.yml`) builds the toolchain
on every push to `build.sh` and uploads a tarball to the `toolchain-latest`
release. The default build includes `m68k-elf-gdb`, and CI verifies it is present.

## License

The build scripts in this repository are MIT-licensed. The toolchain components
(GCC, binutils, GMP, MPFR, MPC, GDB) are distributed under their respective
licenses (GPL, LGPL).
