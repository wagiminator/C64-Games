#!/bin/bash
# =====================================================================
#  VEXOR - build script
#  Generates graphics/music/level data, assembles the game and creates
#  all distribution formats in build/release:
#    vexor.d64  vexor.crt  vexor.bin  vexor.prg  vexor.tap
#  Requirements: python3, 64tass, TSCrunch (set TSCRUNCH=/path/to/tscrunch
#  if it is not in your PATH)
# =====================================================================
set -e
cd "$(dirname "$0")"
export TSCRUNCH=${TSCRUNCH:-tscrunch}
mkdir -p build/release

# 1. generated data (charset, sprites, tables, levels, music)
python3 tools/vgen.py build

# 2. the game itself (uncompressed, starts at $0810)
cd src
64tass -q -C -a --cbm-prg $ASFLAGS -o ../build/vexor.prg -L ../build/vexor.lst --labels=../build/vexor.lbl main.asm
cd ..

# 3. disk image with fastloader, Magic Desk cartridge (BIN + CRT)
python3 tools/package.py

# 4. single-file PRG (self-extracting, for SD2IEC, emulators, Ultimate ...)
"$TSCRUNCH" -x '$0810' build/vexor.prg build/vexor_single.prg

# 5. turbo tape image (KERNAL-loaded boot loader + turbo blocks)
cd src/loader
64tass -q -C -a --cbm-prg -o ../../build/tapeboot.prg tapeboot.asm
cd ../..
python3 tools/mktap.py build/tapeboot.prg build/vexor_ip.prg vexor build/vexor.tap

cp build/vexor.d64 build/vexor.crt build/vexor.bin build/vexor.tap build/release/
cp build/vexor_single.prg build/release/vexor.prg
ls -l build/release
