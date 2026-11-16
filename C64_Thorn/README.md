# THORN - Defend your Garden on the Commodore C64
THORN is a garden defence game for the Commodore C64, written from scratch in 6502 assembler. The undead are marching across your lawn towards your house in five lanes. Collect sunlight, plant flowers that shoot, freeze, block and explode, and stop the horde before it reaches your door. Ten levels from bright day to dark night end with the GRAVE KING himself. The game is a tribute to the tower defence classic of 2009, all plants, zombies, graphics and music are original.

- Ten levels: day, dusk and night with less and less sunlight
- Six plants that are unlocked level by level, four kinds of zombies and a boss
- Big attack waves announced by a siren, lawn mowers as the last line of defence
- Animated multicolour plants, seeds flying past the plants, sprite multiplexer for the zombies
- Own SID music player with eight songs and sound effects
- Ending sequence and hiscore table
- Disk version with fastloader, Magic Desk cartridge, single PRG and turbo tape

![thorn_title.png](documentation/thorn_title.png)

# How to Play
## Controls
Plug a joystick into **port 2**. The joystick moves the cursor (an arrow) across the lawn.

| Input | Action |
|:-|:-|
| Up beyond the first lane | go to the seed bar; left/right selects a seed packet, fire picks it up |
| Fire on the lawn | plant the selected seed packet on this field |
| `DIG` (right end of the seed bar) | pick up the shovel to remove a plant |
| Touching a sun with the cursor | collects the sun |
| `P` | pause |
| `RUN/STOP` (during pause) | quit the game and return to the title screen |

## The Game
The undead walk from the right towards your house on the left. Put plants in their way. Every plant costs sunlight. After planting, a seed packet needs some time to recharge (shown as a black symbol). When a zombie reaches the house, the lawn mower of that lane drives off once and clears the whole lane. If another zombie gets through in this lane, the level is lost: you lose a life and the level starts again. You have three lives, an extra life is awarded every 10000 points.

| Plant | Cost | Effect |
|:-|-:|:-|
| SUNBLOOM | 50 | produces sunlight at regular intervals |
| SPITTER | 100 | spits seeds at the zombies in its lane |
| ROCKNUT | 50 | a very tough wall |
| BOOMBERRY | 150 | explodes and clears a 3 x 3 area |
| FROSTPOD | 175 | ice seeds slow down the zombies |
| TWINSPIT | 200 | spits two seeds at once |

The zombies are the walker, the helmet zombie, the bucket knight (very tough) and the runner (fast).

| Levels | Time of day | Sunlight |
|:-:|:-|:-|
| 1-4 | day | lots of sunlight falls from the sky |
| 5-7 | dusk | less sunlight |
| 8-10 | night | only the sunlight of your Sunblooms |

In level 10 the boss appears: THE GRAVE KING changes lanes, tramples plants and calls reinforcements. After defeating him the ending follows. Points are given for zombies, as level bonus and for every unused lawn mower. Good scores are entered into the hall of fame with your initials; the table is kept until the computer is switched off.

## Hidden Cheat
Type `COMPOST` on the title screen. A red message confirms the cheat mode. You now have unlimited sunlight, no recharge times and the house is invulnerable. The keys `1` to `9` and `0` on the title screen select the start level 1 to 10 and `N` during the game skips the current level.

![thorn_level4.png](documentation/thorn_level4.png)

# How it Works
## Memory Map
| Address | Content |
|:-|:-|
| `$0810-$3FFF` | game code |
| `$4000-$47FF` | multicolour charset: lawn, plants, seeds, house, HUD (VIC bank 1) |
| `$4800-$4BFF` | screen |
| `$4C00-$7FFF` | sprite data |
| `$8000-$BFFF` | title/ending screens, music player, generated tables, music |

## The Lawn
The lawn is a grid of 5 lanes x 9 fields, each field is 4 x 4 characters in multicolour mode. The plants are characters as well: they are animated by changing their character definitions (charset animation), so all plants of one kind move in sync without any CPU cost per plant. The seeds are pre-shifted characters that move in steps of two pixels and fly behind the plants. The suns, the zombies and the boss are sprites.

## Zombies and Sprite Multiplexer
Up to 20 zombies plus the suns, the driving lawn mowers and the boss are collected in a list of up to 40 virtual sprites per frame, sorted by their Y coordinate and displayed by a chain of raster interrupts. Every zombie has its own health, speed (halved while frozen) and walk animation and stops to eat when it reaches a plant. A raster interrupt at the top switches the background colour for the brown seed bar.

## Wave Director
The order of the zombies is not random but follows a script per level in `game.asm`: a quiet start, growing groups and big attack waves announced by a siren. The amount of falling sunlight depends on the time of day.

## Loaders
All three loaders share the same crunched game image. The game is packed with [TSCrunch](https://github.com/tonysavon/TSCrunch) into an image that can be decrunched in place, i.e. it is loaded directly below its final position and unpacked onto itself.

- **Disk:** the boot file transfers its drive code into the 1541 via `M-W` commands and starts it. The drive reads the sectors of the data file and sends every byte as four 2-bit pairs over the CLK and DATA lines of the serial bus. Each byte starts with a handshake, the four pairs follow with cycle-exact timing. The screen is switched off while loading, so that no badlines can disturb the timing. The loader works on PAL and NTSC machines. Both files are written with a sector interleave matched to the transfer speed.
- **Cartridge:** the boot code in bank 0 is started via the `CBM80` signature, copies the crunched image bank by bank from `$8000-$9FFF` into RAM, disables the cartridge by setting bit 7 of `$DE00` and jumps into the decruncher.
- **Tape:** a small boot program in standard KERNAL format is loaded first. It contains the turbo loader, which distinguishes short and long pulses with a CIA timer (threshold 280 cycles), assembles the bytes and verifies the loaded data with an XOR checksum. If the checksum does not match, the motor is stopped and the border turns red.

![thorn_level10b.png](documentation/thorn_level10b.png)

# Source Code
## Assembler Sources
The game is written in 6502 assembler for [64tass](https://sourceforge.net/projects/tass64/). `main.asm` includes all other files.

| File | Lines | Content |
|:-|-:|:-|
| `src/main.asm` | 309 | memory map, constants, variables, segment layout, includes |
| `src/game.asm` | 738 | game flow: levels, wave director, banners, win and lose, pause, cheat keys |
| `src/lawn.asm` | 1058 | lawn: fields, plants, pre-shifted seeds, suns, cursor |
| `src/zombies.asm` | 840 | zombies, lawn mowers, the boss and the sprite list |
| `src/hud.asm` | 375 | seed bar, cursor marker and status line |
| `src/irq.asm` | 441 | menu IRQ, game IRQ with sprite multiplexer and seed bar split |
| `src/screens.asm` | 996 | title screen, stage intro, game over, ending, credits, hiscore entry |
| `src/sound.asm` | 495 | SID music player (3 voices, instruments, arpeggios, vibrato) and sound effects on voice 3 |
| `src/util.asm` | 227 | text output, BCD score handling, random numbers, keyboard scan, joystick |

## Python Tools
The Python scripts generate all data of the game and package the distribution formats.

| File | Content |
|:-|:-|
| `tools/tgen.py` | build script for all generated data: charset, sprites, tables |
| `tools/gfx.py` | shared graphics helpers and font |
| `tools/tgfx.py` | original garden and undead graphics: lawn, plants, seeds, zombies, boss, house, title logo |
| `tools/music.py` | music and sound effect compiler |
| `tools/tmusic.py` | all compositions of THORN |
| `tools/package.py` | crunches the game and builds D64, BIN and CRT |
| `tools/d64.py` | minimal D64 image writer with custom sector interleave |
| `tools/crt.py` | writes the VICE CRT container for the Magic Desk ROM |
| `tools/mktap.py` | TAP v1 writer: KERNAL boot file plus turbo data block |

# Compiling the Source Code
## Requirements
- [64tass](https://sourceforge.net/projects/tass64/) cross assembler (version 1.59 or newer)
- [Python 3](https://www.python.org/) (only the standard library is needed for the build)
- [TSCrunch](https://github.com/tonysavon/TSCrunch) by Antonio Savona for crunching the game

## Building
All graphics, sprites, level data and music are generated by Python scripts at build time, there are no binary assets in the repository. A single script creates the game and all five distribution formats:
```
cd sources
./build.sh
```
If `tscrunch` is not in your `PATH`, pass its location: `TSCRUNCH=/path/to/tscrunch ./build.sh`. The finished files are placed in `sources/build/release`. Intermediate files (listings, label files, generated data) remain in `sources/build`, the label file `thorn.lbl` is handy for debugging with the VICE monitor.

The build runs the following steps:
1. `tools/tgen.py` generates the charset, the sprites, all tables, the level data and the music into `build/`.
2. `64tass` assembles `src/main.asm` into the uncompressed game `build/thorn.prg` (start address `$0810`).
3. `tools/package.py` crunches the game with TSCrunch into an in-place decrunching image and builds the D64 (with boot loader), the BIN and the CRT.
4. TSCrunch creates the self-extracting single file PRG.
5. The tape boot loader is assembled and `tools/mktap.py` writes the TAP image.

## Folder Structure
```
sources/
├── build.sh            build script for all formats
├── src/                6502 assembler sources (64tass)
│   ├── main.asm        memory map, includes
│   ├── game.asm        game flow
│   ├── lawn.asm        lawn and plants
│   ├── zombies.asm     zombies and boss
│   ├── ...             see table above
│   └── loader/
│       ├── boot.asm    disk boot program + 1541 drive code (2-bit fastloader)
│       ├── cart.asm    Magic Desk cartridge boot code
│       ├── tapeboot.asm turbo tape boot loader
│       └── decrunch.asm TSCrunch in-place decruncher
└── tools/              Python build tools
    ├── tgen.py         generates all game data
    ├── tgfx.py         graphics
    ├── tmusic.py       music
    ├── gfx.py          graphics helpers
    ├── music.py        music compiler
    ├── package.py      crunching, D64, BIN and CRT creation
    ├── d64.py          minimal D64 writer with custom sector interleave
    ├── crt.py          Magic Desk CRT file writer
    └── mktap.py        TAP image writer (KERNAL boot file + turbo blocks)
```

# Using the Binaries
The [binaries](binaries/) folder contains the game in five ready-to-use formats. All of them start the same game; they only differ in the medium and the loader.

| File | Format | Loader | Typical use |
|:-|:-|:-|:-|
| `thorn.d64` | 1541 disk image | own 2-bit fastloader (~5 s) | emulators, real 1541 floppy, Ultimate 64/II |
| `thorn.crt` | Magic Desk cartridge (VICE CRT) | copies from ROM, starts in ~1 s | emulators, Ultimate 64/II, Kung Fu Flash |
| `thorn.bin` | raw 64 KB Magic Desk ROM | as above | burning an (E)EPROM for a real cartridge |
| `thorn.prg` | single self-extracting PRG | standard KERNAL loader | emulators, SD2IEC, any file based device |
| `thorn.tap` | tape image (TAP v1) | own turbo loader (~0:58 min) | emulators, Tapuino, real datasette |

## D64 - Disk Image with Fastloader
Load and start the game with:
```
LOAD"*",8,1
RUN
```
The first file is a tiny boot program. It uploads its own drive code into the 1541, which then sends the crunched game file (the second directory entry, `thorn data`) with a 2-bit protocol to the C64. The game is decrunched in place and starts automatically. Loading takes about five seconds instead of about 45 seconds with the standard loader.

Because the fastloader runs code inside the floppy drive, it needs a real 1541/1541-II/1571 or an accurate drive emulation (VICE with "True Drive Emulation", Ultimate 64/II, Pi1541). Pure file-based devices like the [SD2IEC](https://github.com/wagiminator/C64-Collection/tree/master/C64_SD2IEC_LP) cannot run drive code; please use the PRG file there.

**In an emulator:** drag and drop the D64 onto [VICE](https://vice-emu.sourceforge.io/) or open it in the [C64 Emulator Web App](https://wagiminator.github.io/apps/c64-emulator/) directly in your browser.

**On a real floppy disk:** write the D64 to a disk with a [DiskBuddy64](https://github.com/wagiminator/C64-Collection/tree/master/C64_DiskBuddy64), [DiskMaster64](https://github.com/wagiminator/C64-Collection/tree/master/C64_DiskMaster64) or [DumpMaster64](https://github.com/wagiminator/C64-Collection/tree/master/C64_DumpMaster64) adapter, either with the Python tools of the respective adapter or directly from the browser with the [C64 Disk Transfer Web App](https://wagiminator.github.io/apps/d64-transfer/). Alternatively, an [xu1541](https://github.com/wagiminator/C64-Collection/tree/master/C64_xu1541) with OpenCBM can be used. If you want to have a look at the disk structure or add the game to your own disk image, use the [C64 Disk Viewer](https://wagiminator.github.io/apps/d64-viewer/) and the [C64 Disk Editor](https://wagiminator.github.io/apps/d64-editor/).

## CRT and BIN - Magic Desk Cartridge
The game is also available as a 64 KB cartridge in Magic Desk format (eight 8 KB banks, bank register at `$DE00`). After switching on, the boot code in bank 0 copies the crunched game into RAM, switches the cartridge off and decrunches the game. It is ready about one second after power-on.

**In an emulator or on modern hardware:** the CRT file can be attached in VICE (`File` -> `Attach cartridge image`), in the [C64 Emulator Web App](https://wagiminator.github.io/apps/c64-emulator/), on an Ultimate 64/II or a Kung Fu Flash.

**As a real cartridge:** the BIN file is the raw 64 KB ROM image. Burn it into a 27C512/28C512 (E)EPROM and plug it into the [C64 64k/256k Cartridge](https://github.com/wagiminator/C64-Collection/tree/master/C64_Cartridge_64k_256k). For programming the (E)EPROM, a TL866/T48 programmer can be used together with the [XGecu Memory Programmer Web App](https://wagiminator.github.io/apps/tinypro/) or the Python tool [tinypro](https://pypi.org/project/tinypro/). If you want to combine several games on one cartridge with a selection menu, put the PRG files into the [C64 Cartridge Builder Web App](https://wagiminator.github.io/apps/cart-builder/).

## PRG - Single File
The PRG is the complete game as one self-extracting file. Load it with:
```
LOAD"THORN",8
RUN
```
It works with every device that can load files with the standard KERNAL routines, e.g. an [SD2IEC](https://github.com/wagiminator/C64-Collection/tree/master/C64_SD2IEC_LP), an Ultimate 64/II, a Kung Fu Flash or a real floppy disk (copy it onto a disk with the [C64 Disk Editor](https://wagiminator.github.io/apps/d64-editor/) and the [C64 Disk Transfer Web App](https://wagiminator.github.io/apps/d64-transfer/)). Since the standard loader is slow, loading from a real 1541 takes considerably longer than the D64 version. A fastload cartridge like the [C64 FreeLoad Cartridge](https://github.com/wagiminator/C64-Collection/tree/master/C64_Cartridge_FreeLoad) speeds this up nicely. In emulators the PRG can simply be autostarted.

## TAP - Tape Image with Turbo Loader
Insert the tape (or attach the TAP file in your emulator), then press `SHIFT` + `RUN/STOP` (or type `LOAD` and later `RUN`) and press PLAY on the datasette. The KERNAL first loads a small boot loader. This turbo loader then switches the datasette motor on again and reads the crunched game in its own pulse format (bit 0 = 208 cycles, bit 1 = 352 cycles). Coloured stripes in the border show the loading progress, a red border indicates a loading error. The whole process takes about 0:58 minutes instead of about seven minutes with the standard KERNAL loader.

**In an emulator:** attach the TAP file to the datasette in VICE or load it into the [C64 Emulator Web App](https://wagiminator.github.io/apps/c64-emulator/).

**With a datasette emulator:** copy the TAP file onto the SD card of a [Tapuino](https://github.com/wagiminator/C64-Collection/tree/master/C64_Tapuino).

**On a real cassette:** record the TAP file onto a tape with a [TapeBuddy64](https://github.com/wagiminator/C64-Collection/tree/master/C64_TapeBuddy64), [TapeDump64](https://github.com/wagiminator/C64-Collection/tree/master/C64_TapeDump64) or [DumpMaster64](https://github.com/wagiminator/C64-Collection/tree/master/C64_DumpMaster64), either with the Python tools of the respective adapter or directly from the browser with the [C64 Tape Transfer Web App](https://wagiminator.github.io/apps/tap-transfer/).

# References, Links and Notes
1. [64tass Cross Assembler](https://sourceforge.net/projects/tass64/)
2. [TSCrunch by Antonio Savona](https://github.com/tonysavon/TSCrunch)
3. [VICE - the Versatile Commodore Emulator](https://vice-emu.sourceforge.io/)
4. [C64 Emulator Web App](https://wagiminator.github.io/apps/c64-emulator/)
5. [C64 Disk Transfer Web App](https://wagiminator.github.io/apps/d64-transfer/)
6. [C64 Tape Transfer Web App](https://wagiminator.github.io/apps/tap-transfer/)
7. [C64 Cartridge Builder Web App](https://wagiminator.github.io/apps/cart-builder/)
8. [XGecu Memory Programmer Web App](https://wagiminator.github.io/apps/tinypro/)
9. [C64 Collection (adapters and cartridges)](https://github.com/wagiminator/C64-Collection)
10. [Christian Bauer: The MOS 6567/6569 video controller (VIC-II)](https://www.zimmers.net/cbmpics/cbm/c64/vic-ii.txt)
11. [Codebase64 Wiki](https://codebase64.org/)

![thorn_level9.png](documentation/thorn_level9.png)
![thorn_level10a.png](documentation/thorn_level10a.png)

# License
![license.png](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)

This work is licensed under Creative Commons Attribution-ShareAlike 3.0 Unported License.
(http://creativecommons.org/licenses/by-sa/3.0/)
