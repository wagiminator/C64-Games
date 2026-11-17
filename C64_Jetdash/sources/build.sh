#!/bin/bash
# =====================================================================
#  JETDASH - build script
#  Generates graphics/music/level data, assembles the game and creates
#  all distribution formats in build/release:
#    jetdash.d64  jetdash.crt  jetdash.bin  jetdash.prg  jetdash.tap
#  Requirements: python3, 64tass, TSCrunch (set TSCRUNCH=/path/to/tscrunch
#  if it is not in your PATH)
# =====================================================================
set -e
cd "$(dirname "$0")"
export TSCRUNCH=${TSCRUNCH:-tscrunch}
mkdir -p build/release

# 1. generated data (charset, sprites, tables, levels, music)
python3 tools/jgen.py build

# 2. the game itself (uncompressed, starts at $0810)
cd src
64tass -q -C -a --cbm-prg --long-branch $ASFLAGS -o ../build/jetdash.prg -L ../build/jetdash.lst --labels=../build/jetdash.lbl main.asm
cd ..

# 3. disk image with fastloader, Magic Desk cartridge (BIN + CRT)
python3 tools/package.py

# 4. single-file PRG (self-extracting, for SD2IEC, emulators, Ultimate ...)
"$TSCRUNCH" -x '$0810' build/jetdash.prg build/jetdash_single.prg

# 5. turbo tape image (KERNAL-loaded boot loader + turbo blocks)
cd src/loader
64tass -q -C -a --cbm-prg -o ../../build/tapeboot.prg tapeboot.asm
cd ../..
python3 tools/mktap.py build/tapeboot.prg build/jetdash_ip.prg jetdash build/jetdash.tap

cp build/jetdash.d64 build/jetdash.crt build/jetdash.bin build/jetdash.tap build/release/
cp build/jetdash_single.prg build/release/jetdash.prg
ls -l build/release
