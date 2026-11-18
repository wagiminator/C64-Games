#!/bin/bash
# =====================================================================
#  FLEETFOOT - build script
#  Generates graphics/music/level data, assembles the game and creates
#  all distribution formats in build/release:
#    fleetfoot.d64  fleetfoot.crt  fleetfoot.bin  fleetfoot.prg  fleetfoot.tap
#  Requirements: python3, 64tass, TSCrunch (set TSCRUNCH=/path/to/tscrunch
#  if it is not in your PATH)
# =====================================================================
set -e
cd "$(dirname "$0")"
export TSCRUNCH=${TSCRUNCH:-tscrunch}
mkdir -p build/release

# 1. generated data (charset, sprites, tables, levels, music)
python3 tools/fgen.py build

# 2. the game itself (uncompressed, starts at $0810)
cd src
64tass -q -C -a --cbm-prg --long-branch $ASFLAGS -o ../build/fleetfoot.prg -L ../build/fleetfoot.lst --labels=../build/fleetfoot.lbl main.asm
cd ..

# 3. disk image with fastloader, Magic Desk cartridge (BIN + CRT)
python3 tools/package.py

# 4. single-file PRG (self-extracting, for SD2IEC, emulators, Ultimate ...)
"$TSCRUNCH" -x '$0810' build/fleetfoot.prg build/fleetfoot_single.prg

# 5. turbo tape image (KERNAL-loaded boot loader + turbo blocks)
cd src/loader
64tass -q -C -a --cbm-prg -o ../../build/tapeboot.prg tapeboot.asm
cd ../..
python3 tools/mktap.py build/tapeboot.prg build/fleetfoot_ip.prg fleetfoot build/fleetfoot.tap

cp build/fleetfoot.d64 build/fleetfoot.crt build/fleetfoot.bin build/fleetfoot.tap build/release/
cp build/fleetfoot_single.prg build/release/fleetfoot.prg
ls -l build/release
