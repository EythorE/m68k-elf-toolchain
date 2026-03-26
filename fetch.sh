#!/bin/bash
# Fetch pre-built m68k-elf toolchain from GitHub Releases.
# Idempotent: skips if already installed.
#
# Usage:
#   bash fetch.sh                        # Install to ~/m68k-elf-toolchain
#   bash fetch.sh /opt/m68k-elf          # Install to custom prefix
set -euo pipefail

PREFIX="${1:-$HOME/m68k-elf-toolchain}"
REPO="EythorE/m68k-elf-toolchain"
TAG="toolchain-latest"
ASSET="m68k-elf-toolchain-x86_64-linux.tar.gz"
URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET}"

if [ -x "$PREFIX/bin/m68k-elf-gcc" ]; then
    echo "Toolchain already installed at $PREFIX"
    "$PREFIX/bin/m68k-elf-gcc" --version | head -1
    exit 0
fi

echo "Fetching pre-built m68k-elf toolchain from ${REPO}..."
echo "URL: $URL"

mkdir -p "$PREFIX"
curl -fSL "$URL" | tar xz --strip-components=1 -C "$PREFIX"

echo ""
echo "Installed to $PREFIX"
echo ""
echo "Add to PATH:"
echo "  export PATH=$PREFIX/bin:\$PATH"
echo ""
"$PREFIX/bin/m68k-elf-gcc" --version | head -1
