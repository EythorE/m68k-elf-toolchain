#!/bin/bash
# Build m68k-elf cross-compiler toolchain (GCC 14.2.0 + binutils 2.43)
#
# Produces a bare-metal m68k-elf toolchain with --with-cpu=68000,
# ensuring libgcc.a contains only base 68000 instructions.
#
# Usage:
#   bash build.sh                    # Install to ~/m68k-elf-toolchain
#   bash build.sh /opt/m68k-elf      # Install to custom prefix
#
# Requirements: build-essential (gcc, make, etc.)
# No other apt packages needed -- GMP/MPFR/MPC are built in-tree.
set -euo pipefail

PREFIX="${1:-$HOME/m68k-elf-toolchain}"
SRCDIR="$PREFIX/src"
BUILDDIR="$PREFIX/build"
JOBS="$(nproc)"

BINUTILS_VER="2.43"
GCC_VER="14.2.0"
GMP_VER="6.2.1"
MPFR_VER="4.2.1"
MPC_VER="1.3.1"
GDB_VER="15.2"

BUILD_GDB="${BUILD_GDB:-0}"

mkdir -p "$SRCDIR" "$BUILDDIR"
cd "$SRCDIR"

# ── Download ──────────────────────────────────────────────────────────

echo "=== Downloading sources ==="
wget -q --show-progress https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.gz
wget -q --show-progress https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.gz
wget -q --show-progress https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VER}.tar.xz
wget -q --show-progress https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VER}.tar.gz
wget -q --show-progress https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VER}.tar.gz

if [ "$BUILD_GDB" = "1" ]; then
    wget -q --show-progress https://ftp.gnu.org/gnu/gdb/gdb-${GDB_VER}.tar.gz
fi

# ── Extract ───────────────────────────────────────────────────────────

echo "=== Extracting ==="
tar -xzf binutils-${BINUTILS_VER}.tar.gz
tar -xzf gcc-${GCC_VER}.tar.gz
tar -xf  gmp-${GMP_VER}.tar.xz
tar -xzf mpfr-${MPFR_VER}.tar.gz
tar -xzf mpc-${MPC_VER}.tar.gz

if [ "$BUILD_GDB" = "1" ]; then
    tar -xzf gdb-${GDB_VER}.tar.gz
fi

# Symlink GMP/MPFR/MPC into GCC source tree (built in-tree, no -dev packages)
ln -sf "$SRCDIR/gmp-${GMP_VER}"  "gcc-${GCC_VER}/gmp"
ln -sf "$SRCDIR/mpfr-${MPFR_VER}" "gcc-${GCC_VER}/mpfr"
ln -sf "$SRCDIR/mpc-${MPC_VER}"  "gcc-${GCC_VER}/mpc"

export PATH="$PREFIX/bin:$PATH"

# ── binutils ──────────────────────────────────────────────────────────

echo "=== Building binutils ${BINUTILS_VER} ==="
mkdir -p "$BUILDDIR/binutils" && cd "$BUILDDIR/binutils"
"$SRCDIR/binutils-${BINUTILS_VER}/configure" \
    --target=m68k-elf \
    --prefix="$PREFIX" \
    --disable-nls \
    --disable-werror \
    MAKEINFO=true
make -j"$JOBS" MAKEINFO=true
make install MAKEINFO=true

# ── GCC + libgcc ──────────────────────────────────────────────────────

echo "=== Building GCC ${GCC_VER} + libgcc ==="
mkdir -p "$BUILDDIR/gcc" && cd "$BUILDDIR/gcc"
"$SRCDIR/gcc-${GCC_VER}/configure" \
    --target=m68k-elf \
    --prefix="$PREFIX" \
    --enable-languages=c \
    --disable-threads \
    --disable-shared \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libgcj \
    --disable-gold \
    --disable-libmpx \
    --disable-libgomp \
    --disable-libatomic \
    --with-cpu=68000 \
    MAKEINFO=true
make -j"$JOBS" all-gcc MAKEINFO=true
make -j"$JOBS" all-target-libgcc MAKEINFO=true
make install-gcc MAKEINFO=true
make install-target-libgcc MAKEINFO=true

# ── GDB (optional) ───────────────────────────────────────────────────

if [ "$BUILD_GDB" = "1" ]; then
    echo "=== Building GDB ${GDB_VER} ==="
    mkdir -p "$BUILDDIR/gdb" && cd "$BUILDDIR/gdb"
    "$SRCDIR/gdb-${GDB_VER}/configure" \
        --target=m68k-elf \
        --prefix="$PREFIX" \
        MAKEINFO=true
    make -j"$JOBS" MAKEINFO=true
    make install MAKEINFO=true
fi

# ── Cleanup ───────────────────────────────────────────────────────────

echo "=== Cleaning up source and build dirs ==="
rm -rf "$SRCDIR" "$BUILDDIR"

# ── Done ──────────────────────────────────────────────────────────────

echo ""
echo "=== Done ==="
echo "Toolchain installed to $PREFIX"
echo ""
echo "Components:"
echo "  binutils ${BINUTILS_VER}"
echo "  GCC      ${GCC_VER} (--with-cpu=68000)"
[ "$BUILD_GDB" = "1" ] && echo "  GDB      ${GDB_VER}"
echo ""
echo "Add to PATH:"
echo "  export PATH=$PREFIX/bin:\$PATH"
echo ""
"$PREFIX/bin/m68k-elf-gcc" --version | head -1
