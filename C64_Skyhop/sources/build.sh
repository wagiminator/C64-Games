#!/bin/bash
# =====================================================================
#  SKYHOP - build script
#  Generates graphics/music/level data, assembles the game and creates
#  all distribution formats in build/release:
#    skyhop.d64  skyhop.crt  skyhop.bin  skyhop.prg  skyhop.tap
#  Requirements: python3, 64tass, TSCrunch (set TSCRUNCH=/path/to/tscrunch
#  if it is not in your PATH)
# =====================================================================
set -e
cd "$(dirname "$0")"
export TSCRUNCH=${TSCRUNCH:-tscrunch}
mkdir -p build/release

# 1. generated data (charset, sprites, tables, levels, music)
python3 tools/hgen.py build

# 2. the game itself (uncompressed, starts at $0810)
cd src
64tass -q -C -a --cbm-prg --long-branch $ASFLAGS -o ../build/skyhop.prg -L ../build/skyhop.lst --labels=../build/skyhop.lbl main.asm
cd ..

# 3. disk image with fastloader, Magic Desk cartridge (BIN + CRT)
python3 tools/package.py

# 4. single-file PRG (self-extracting, for SD2IEC, emulators, Ultimate ...)
"$TSCRUNCH" -x '$0810' build/skyhop.prg build/skyhop_single.prg

# 5. turbo tape image (KERNAL-loaded boot loader + turbo blocks)
cd src/loader
64tass -q -C -a --cbm-prg -o ../../build/tapeboot.prg tapeboot.asm
cd ../..
python3 tools/mktap.py build/tapeboot.prg build/skyhop_ip.prg skyhop build/skyhop.tap

cp build/skyhop.d64 build/skyhop.crt build/skyhop.bin build/skyhop.tap build/release/
cp build/skyhop_single.prg build/release/skyhop.prg
ls -l build/release
