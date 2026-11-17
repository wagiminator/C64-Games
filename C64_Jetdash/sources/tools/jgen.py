# JETDASH - build all generated data (charsets, tiles, patterns, sprites, tables, music)
import sys, os, math, random
sys.path.insert(0, os.path.dirname(__file__))
import gfx, jgfx, jmusic

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

SCRA, SCRB, SPRBASE = 0x4800, 0x4C00, 0x5000

def bl(label, data, per=16):
    out = [label]
    data = list(data)
    for i in range(0, len(data), per):
        out.append("  .byte " + ",".join("$%02x" % (b & 255) for b in data[i:i + per]))
    if not data: out.append("  .byte 0")
    return out

def font_into(cs):
    for ch, rows in gfx.FONT.items():
        code = gfx.screencode(ch)
        cs[code * 8:code * 8 + 8] = bytes(gfx.glyph_bytes(rows))

# ------------------------------------------------ menu charset ($4000): font + logo quads + coin
mcs = bytearray(2048)
font_into(mcs)
CH_QUAD = 64
for q in range(16):
    d = bytearray(8)
    for y in range(8):
        v = 0
        if y < 4:
            if q & 1: v |= 0xF0
            if q & 2: v |= 0x0F
        else:
            if q & 4: v |= 0xF0
            if q & 8: v |= 0x0F
        d[y] = v
    mcs[(CH_QUAD + q) * 8:(CH_QUAD + q) * 8 + 8] = d
M_COIN = 80
mcs[M_COIN * 8:M_COIN * 8 + 8] = jgfx.from_strings(jgfx.COIN_FRAMES[0])
open(os.path.join(OUT, 'charset_menu.bin'), 'wb').write(bytes(mcs))

# ------------------------------------------------ game charset ($6000)
cs = bytearray(2048)
font_into(cs)
CH_COIN, CH_ZH, CH_ZV, CH_ZD, CH_ZU, CH_ZN, CH_LWARN, CH_LBEAM = range(64, 72)
put = lambda ch, d: cs.__setitem__(slice(ch * 8, ch * 8 + 8), d)
put(CH_COIN, jgfx.from_strings(jgfx.COIN_FRAMES[0]))
for i, d in enumerate(jgfx.zap_chars(0)): put(CH_ZH + i, d)
put(CH_LWARN, jgfx.LASER_WARN[0])
put(CH_LBEAM, jgfx.LASER_BEAM[0])
EMPTY = bytes(8)
chars = {EMPTY: 32}
nextch = [72]
def charid(b):
    if b not in chars:
        assert nextch[0] < 256, "charset full"
        chars[b] = nextch[0]; put(nextch[0], b); nextch[0] += 1
    return chars[b]

TILES = []
for kind in jgfx.TILE_KINDS:
    rows = jgfx.make_tile(kind).chars()       # 23 rows x 8 cols
    TILES.append([[charid(rows[r][c]) for r in range(23)] for c in range(8)])
print("game chars used:", nextch[0])
open(os.path.join(OUT, 'charset_game.bin'), 'wb').write(bytes(cs))
TIDX = {k: i for i, k in enumerate(jgfx.TILE_KINDS)}

# animation frames for chars rewritten at run time
anim = []
for f in jgfx.COIN_FRAMES: anim += list(jgfx.from_strings(f))
zf = [jgfx.zap_chars(0), jgfx.zap_chars(1)]
zap_anim = []
for f in range(2):
    for i in range(5): zap_anim += list(zf[f][i])
laser_anim = list(jgfx.LASER_WARN[0]) + list(jgfx.LASER_WARN[1]) + list(jgfx.LASER_BEAM[0]) + list(jgfx.LASER_BEAM[1])

# ------------------------------------------------ patterns (coins and zappers)
# playfield rows 3..22 (20 rows); pattern rows are relative to a random base row
def P_coins(lines):
    cells = []
    for y, s in enumerate(lines):
        for x, c in enumerate(s):
            if c == 'o': cells.append((x, y, CH_COIN))
    return cells
def P_h(n): return [(0, 0, CH_ZN)] + [(i, 0, CH_ZH) for i in range(1, n - 1)] + [(n - 1, 0, CH_ZN)]
def P_v(n): return [(0, 0, CH_ZN)] + [(0, i, CH_ZV) for i in range(1, n - 1)] + [(0, n - 1, CH_ZN)]
def P_d(n): return [(0, 0, CH_ZN)] + [(i, i, CH_ZD) for i in range(1, n - 1)] + [(n - 1, n - 1, CH_ZN)]
def P_u(n): return [(0, n - 1, CH_ZN)] + [(i, n - 1 - i, CH_ZU) for i in range(1, n - 1)] + [(n - 1, 0, CH_ZN)]
def comp(*parts):
    cells = {}
    for dx, dy, p in parts:
        for (x, y, c) in p: cells[(x + dx, y + dy)] = c
    return [(x, y, c) for (x, y), c in cells.items()]

COINS = [
    ["oooooooooooo"],
    ["oooooooooo", "oooooooooo"],
    ["oooooooo", "oooooooo", "oooooooo"],
    ["o.o.o.o.o.o.o", ".o.o.o.o.o.o."],
    ["...oo...", "..oooo..", ".oooooo.", "oooooooo", ".oooooo.", "..oooo..", "...oo..."],
    ["oo......oo", ".oo....oo.", "..oo..oo..", "...oooo...", "....oo...."],
    ["o.......", "oo......", "ooo.....", "oooo....", "ooo.....", "oo......", "o......."],
    [".oo..oo.", "oooooooo", "oooooooo", ".oooooo.", "..oooo..", "...oo..."],
    ["oooooo", "o....o", "o.oo.o", "o.oo.o", "o....o", "oooooo"],
    [".ooo..ooo..o.o", "o....o.....o.o", "o....oooo..ooo", "o....o..o....o", ".ooo..oo.....o"],   # C64
    ["o...o..ooo", "o...o...o.", "ooooo...o.", "o...o...o.", "o...o..ooo"],                       # HI
]
# sine wave of coins
wave = [['.'] * 16 for _ in range(7)]
for x in range(16):
    wave[3 + int(round(3 * math.sin(x / 2.5)))][x] = 'o'
COINS.append([''.join(r) for r in wave])
COIN_PATS = [P_coins(c) for c in COINS]

Z_EASY = [P_h(3), P_h(4), P_v(3), P_v(4), P_d(3), P_u(3),
          comp((0, 2, P_h(4)), (0, 0, P_coins(["oooo"]))),
          comp((0, 0, P_v(4)), (2, 0, P_coins(["oooo", "....", "....", "oooo"]))),
          comp((0, 0, P_d(3)), (3, 0, P_coins(["ooo"]))) ]
Z_MED = [P_h(5), P_h(6), P_v(5), P_v(6), P_d(4), P_u(4), P_d(5), P_u(5),
         comp((0, 0, P_h(5)), (0, 7, P_h(5))),
         comp((0, 0, P_v(5)), (6, 4, P_v(5))),
         comp((0, 0, P_d(4)), (6, 0, P_u(4))),
         comp((0, 3, P_h(6)), (0, 1, P_coins(["oooooo"])), (0, 5, P_coins(["oooooo"]))),
         comp((0, 0, P_u(5)), (1, 4, P_coins(["oooo"])))]
Z_HARD = [P_v(7), P_v(8), P_h(7), P_h(8), P_d(6), P_u(6),
          comp((0, 0, P_v(6)), (5, 6, P_v(6))),
          comp((0, 0, P_v(5)), (6, 7, P_v(5)), (12, 0, P_v(5))),
          comp((0, 0, P_h(6)), (0, 8, P_h(6)), (2, 3, P_coins(["oo", "oo", "oo"]))),
          comp((0, 0, P_d(5)), (5, 4, P_u(5))),
          comp((0, 4, P_u(5)), (5, 4, P_d(5))),
          comp((0, 0, P_v(9))),
          comp((0, 2, P_h(4)), (6, 0, P_v(7)), (10, 6, P_h(4)))]

def pat_bytes(cells):
    w = max(x for x, y, c in cells) + 1
    h = max(y for x, y, c in cells) + 1
    assert h <= 14
    out = [w, h]
    for x in range(w):
        col = sorted((y, c) for (xx, y, c) in cells if xx == x)
        out.append(len(col))
        for y, c in col: out += [y, c]
    return out

POOLS = [COIN_PATS, Z_EASY, Z_MED, Z_HARD]
PATS = []
pool_start, pool_n = [], []
for pool in POOLS:
    pool_start.append(len(PATS)); pool_n.append(len(pool))
    for cells in pool: PATS.append(pat_bytes(cells))

# laser sequences: steps (row1, row2, warn, fire, pause); rows 0 = none
LASERSEQ = [
    [(6, 18, 70, 50, 20)],
    [(12, 0, 70, 50, 10), (5, 19, 60, 50, 20)],
    [(4, 0, 60, 40, 0), (9, 0, 50, 40, 0), (14, 0, 50, 40, 0), (19, 0, 50, 40, 20)],
    [(5, 12, 70, 50, 10), (12, 19, 60, 50, 10), (8, 16, 60, 50, 20)],
    [(19, 0, 60, 40, 0), (14, 0, 50, 40, 0), (9, 0, 50, 40, 0), (4, 0, 50, 40, 20)],
    [(4, 20, 60, 160, 20)],
]

# ------------------------------------------------ sprites
spr = bytearray()
SYM = {}
def add(name, data):
    SYM[name] = (SPRBASE - 0x4000) // 64 + len(spr) // 64
    spr.extend(data)
hf = jgfx.hero_frames()
for i, (mc, hr) in enumerate(hf):
    add('HERO%d' % i, hr.tobytes()); spr.extend(mc.tobytes())
for i in (0, 1, 2, 3, 4):                         # upside down (gravity belt on the ceiling)
    mc, hr = hf[i]
    add('HEROU%d' % i, hr.vflip().tobytes()); spr.extend(mc.vflip().tobytes())
for i in range(3): add('FLAME%d' % i, jgfx.flame(i).tobytes())
for i in range(2): add('ROTOR%d' % i, jgfx.rotor(i).tobytes())
for i in range(2): add('GLOW%d' % i, jgfx.belt_glow(i).tobytes())
for i in range(2): add('GLOWU%d' % i, jgfx.belt_glow(i).vflip().tobytes())
for i, k in enumerate(('walk', 'walk', 'down')):
    s, h = jgfx.worker(k, i)
    add('WORK%d' % i, s.tobytes())
for i in range(2): add('MISS%d' % i, jgfx.missile(i).tobytes())
for i in range(2): add('WARN%d' % i, jgfx.warning(i).tobytes())
for i in range(2): add('BOX%d' % i, jgfx.box(i).tobytes())
for i in range(3): add('EXPL%d' % i, jgfx.explosion(i).tobytes())
for i in range(2): add('EMITL%d' % i, jgfx.emitter(i).tobytes())
for i in range(2): add('EMITR%d' % i, jgfx.emitter(i).hflip().tobytes())
add('BLANK', bytes(64))
assert len(spr) <= 0x1000, len(spr)
print("sprites:", len(spr) // 64)
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(spr))

# ------------------------------------------------ logo
bm = jgfx.logo_bitmap()
LOGOROWS = len(bm) // 2
logo = []
for r in range(LOGOROWS):
    for c in range(40):
        q = 0
        if bm[r * 2][c * 2]: q |= 1
        if bm[r * 2][c * 2 + 1]: q |= 2
        if bm[r * 2 + 1][c * 2]: q |= 4
        if bm[r * 2 + 1][c * 2 + 1]: q |= 8
        logo.append(CH_QUAD + q if q else 32)

# ------------------------------------------------ data tables
L = ["; generated data"]
rows = [i * 40 for i in range(25)]
L += bl("rowlo", [r & 255 for r in rows])
L += bl("rowhiA", [(SCRA + r) >> 8 for r in rows])
L += bl("rowhiB", [(SCRB + r) >> 8 for r in rows])
L += bl("rowhiC", [(0xd800 + r) >> 8 for r in rows])
L += bl("logo_chars", logo)
L += bl("logo_grad", [7, 7, 8, 8, 2, 2, 8, 8, 7, 7, 1, 1, 15, 15, 1, 1])
fl, fh = [], []
for n in range(96):
    f = 440.0 * 2 ** ((n - 57) / 12.0)
    r = min(65535, int(round(f * 16777216 / 985248)))
    fl.append(r & 255); fh.append(r >> 8)
L += bl("freq_lo", fl)
L += bl("freq_hi", fh)
L += bl("coin_anim", anim)
L += bl("zap_anim", zap_anim)
L += bl("laser_anim", laser_anim)
# tiles: per tile 8 columns x 23 rows
for i, t in enumerate(TILES):
    L += bl("tile%d" % i, [c for col in t for c in col], 23)
L.append("tile_lo .byte " + ",".join("<tile%d" % i for i in range(len(TILES))))
L.append("tile_hi .byte " + ",".join(">tile%d" % i for i in range(len(TILES))))
L += bl("tcol_off", [c * 23 for c in range(8)])
L += bl("zone_tiles", [TIDX[k] for zt in jgfx.ZONE_TILES for k in zt])
# patterns
for i, p in enumerate(PATS):
    L += bl("pat%d" % i, p)
L.append("pat_lo .byte " + ",".join("<pat%d" % i for i in range(len(PATS))))
L.append("pat_hi .byte " + ",".join(">pat%d" % i for i in range(len(PATS))))
L += bl("pool_start", pool_start)
L += bl("pool_n", pool_n)
# lasers
for i, sq in enumerate(LASERSEQ):
    b = [len(sq)]
    for st in sq: b += list(st)
    L += bl("lseq%d" % i, b)
L.append("lseq_lo .byte " + ",".join("<lseq%d" % i for i in range(len(LASERSEQ))))
L.append("lseq_hi .byte " + ",".join(">lseq%d" % i for i in range(len(LASERSEQ))))

# difficulty by level (metres / 320, 0..15)
D = dict(
    spdlo=[0x40, 0x50, 0x60, 0x70, 0x80, 0x90, 0xa0, 0xb0, 0xc0, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf8, 0x00],
    spdhi=[1] * 15 + [2],
    gapmin=[14, 13, 12, 11, 10, 10, 9, 9, 8, 8, 8, 7, 7, 7, 6, 6],
    gapmax=[22, 20, 19, 18, 17, 16, 15, 14, 14, 13, 13, 12, 12, 11, 11, 10],
    pcoin=[150, 120, 100, 90, 80, 72, 64, 60, 56, 52, 48, 44, 40, 40, 36, 36],      # of 256
    peasy=[256, 230, 200, 150, 110, 80, 60, 40, 30, 20, 10, 0, 0, 0, 0, 0],         # of the rest
    pmed=[256, 256, 256, 256, 240, 220, 190, 160, 140, 120, 110, 100, 90, 80, 70, 64],
    plaser=[0, 0, 6, 8, 10, 12, 12, 14, 14, 16, 16, 18, 18, 20, 20, 22],
    mtime=[0, 0, 0, 255, 220, 200, 180, 160, 150, 140, 130, 120, 110, 100, 90, 80],  # frames x2
    mdouble=[0, 0, 0, 0, 0, 40, 60, 80, 100, 110, 120, 130, 140, 150, 160, 170],
    pwork=[24, 24, 22, 20, 18, 16, 16, 14, 14, 12, 12, 10, 10, 10, 8, 8],
)
for k, v in D.items():
    L += bl("d_" + k, [min(255, x) if k not in ('peasy', 'pmed') else min(255, x) for x in v])
# zones: colours (bg, $d022, $d023)
ZCOL = [(11, 12, 15), (9, 8, 15), (5, 13, 1), (2, 10, 15), (6, 14, 3), (14, 1, 5)]
L += bl("zone_bg", [z[0] for z in ZCOL])
L += bl("zone_c1", [z[1] for z in ZCOL])
L += bl("zone_c2", [z[2] for z in ZCOL])
zn = []
for name in jgfx.ZONE_NAMES:
    zn.append(name.center(16))
L.append("zone_names")
for name in zn:
    L.append('  .text "%s"' % name)
L += bl("bittab", [1, 2, 4, 8, 16, 32, 64, 128])
L += bl("pairmask", [0xc0, 0x30, 0x0c, 0x03])
open(os.path.join(OUT, 'gen_data.asm'), 'w').write("\n".join(L) + "\n")

# ------------------------------------------------ constants
C = ["; generated constants"]
for k, v in SYM.items():
    C.append("SPR_%s = $%02x" % (k, v))
for k, v in dict(CH_QUAD=CH_QUAD, M_COIN=M_COIN, CH_COIN=CH_COIN, CH_ZH=CH_ZH, CH_ZV=CH_ZV, CH_ZD=CH_ZD,
                 CH_ZU=CH_ZU, CH_ZN=CH_ZN, CH_LWARN=CH_LWARN, CH_LBEAM=CH_LBEAM,
                 LOGOROWS=LOGOROWS, NZONES=len(ZCOL), NTILES=len(TILES), T_GATE=TIDX['gate'],
                 NLSEQ=len(LASERSEQ), NPATS=len(PATS)).items():
    C.append("%s = %d" % (k, v))
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(C) + "\n")

# ------------------------------------------------ music
masm, mbytes, npat = jmusic.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm)
print("music: %d patterns, %d bytes" % (npat, mbytes))
