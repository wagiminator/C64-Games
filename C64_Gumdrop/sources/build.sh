#!/bin/bash
# =====================================================================
#  GUMDROP - build script
#  Generates graphics/music/level data, assembles the game and creates
#  all distribution formats in build/release:
#    gumdrop.d64  gumdrop.crt  gumdrop.bin  gumdrop.prg  gumdrop.tap
#  Requirements: python3, 64tass, TSCrunch (set TSCRUNCH=/path/to/tscrunch
#  if it is not in your PATH)
# =====================================================================
set -e
cd "$(dirname "$0")"
export TSCRUNCH=${TSCRUNCH:-tscrunch}
mkdir -p build/release

# 1. generated data (charset, sprites, tables, levels, music)
python3 tools/dgen.py build

# 2. the game itself (uncompressed, starts at $0810)
cd src
64tass -q -C -a --cbm-prg --long-branch $ASFLAGS -o ../build/gumdrop.prg -L ../build/gumdrop.lst --labels=../build/gumdrop.lbl main.asm
cd ..

# 3. disk image with fastloader, Magic Desk cartridge (BIN + CRT)
python3 tools/package.py

# 4. single-file PRG (self-extracting, for SD2IEC, emulators, Ultimate ...)
"$TSCRUNCH" -x '$0810' build/gumdrop.prg build/gumdrop_single.prg

# 5. turbo tape image (KERNAL-loaded boot loader + turbo blocks)
cd src/loader
64tass -q -C -a --cbm-prg -o ../../build/tapeboot.prg tapeboot.asm
cd ../..
python3 tools/mktap.py build/tapeboot.prg build/gumdrop_ip.prg gumdrop build/gumdrop.tap

cp build/gumdrop.d64 build/gumdrop.crt build/gumdrop.bin build/gumdrop.tap build/release/
cp build/gumdrop_single.prg build/release/gumdrop.prg
ls -l build/release
