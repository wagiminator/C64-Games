#!/bin/bash
# =====================================================================
#  SUNRUSH - build script
#  Generates graphics/music/level data, assembles the game and creates
#  all distribution formats in build/release:
#    sunrush.d64  sunrush.crt  sunrush.bin  sunrush.prg  sunrush.tap
#  Requirements: python3, 64tass, TSCrunch (set TSCRUNCH=/path/to/tscrunch
#  if it is not in your PATH)
# =====================================================================
set -e
cd "$(dirname "$0")"
export TSCRUNCH=${TSCRUNCH:-tscrunch}
mkdir -p build/release

# 1. generated data (charset, sprites, tables, levels, music)
python3 tools/rgen.py build

# 2. the game itself (uncompressed, starts at $0810)
cd src
64tass -q -C -a --cbm-prg $ASFLAGS -o ../build/sunrush.prg -L ../build/sunrush.lst --labels=../build/sunrush.lbl main.asm
cd ..

# 3. disk image with fastloader, Magic Desk cartridge (BIN + CRT)
python3 tools/package.py

# 4. single-file PRG (self-extracting, for SD2IEC, emulators, Ultimate ...)
"$TSCRUNCH" -x '$0810' build/sunrush.prg build/sunrush_single.prg

# 5. turbo tape image (KERNAL-loaded boot loader + turbo blocks)
cd src/loader
64tass -q -C -a --cbm-prg -o ../../build/tapeboot.prg tapeboot.asm
cd ../..
python3 tools/mktap.py build/tapeboot.prg build/sunrush_ip.prg sunrush build/sunrush.tap

cp build/sunrush.d64 build/sunrush.crt build/sunrush.bin build/sunrush.tap build/release/
cp build/sunrush_single.prg build/release/sunrush.prg
ls -l build/release
