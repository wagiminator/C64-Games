# NIGHTHOLD - build all generated data (charsets, map, sprites, tables, music)
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import gfx, ngfx, nmusic

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

SCRA, SCRB, SPRBASE = 0x4800, 0x4C00, 0x5000
MAPROW = 104                     # 64 cells + 40 repeated

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

# ------------------------------------------------ menu charset ($4000)
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
open(os.path.join(OUT, 'charset_menu.bin'), 'wb').write(bytes(mcs))

# ------------------------------------------------ game charset ($6000)
cs = bytearray(2048)
font_into(cs)
nxt = [64]
C = {}
def add(name, data):
    C[name] = nxt[0]
    cs[nxt[0] * 8:nxt[0] * 8 + 8] = data
    nxt[0] += 1
for k in ('tl', 'tr', 'bl', 'br', 'h', 'v', 'arrow', 'full'):
    add('UI_' + k.upper(), ngfx.hires(ngfx.UI[k]))
for k, v in ngfx.GROUND.items():
    add(k, ngfx.mc(v))
ids = {k: C[k] for k in ngfx.GROUND}
def add_block(name, pic, w, h):
    rows = ngfx.split(pic, w, h)
    blk = []
    for cy in range(h):
        r = []
        for cx in range(w):
            if rows[cy][cx] == bytes(8):
                r.append(32)
            else:
                add('%s_%d_%d' % (name, cx, cy), rows[cy][cx])
                r.append(C['%s_%d_%d' % (name, cx, cy)])
        blk.append(r)
    ids[name] = blk
add_block('grave', ngfx.grave(), 2, 2)
add_block('tree', ngfx.tree(), 2, 3)
add_block('bush', ngfx.bush(), 2, 1)
C['CREATURE0'] = nxt[0]
for k in ngfx.CREATURE_ORDER:
    f = ngfx.CREATURES[k]
    add(k + '0', ngfx.mc(f[0])); add(k + '1', ngfx.mc(f[1])); add(k + 'F', ngfx.mc(ngfx.flash_of(f[0])))
for i, g in enumerate(ngfx.GEMS): add('GEM%d' % i, ngfx.mc(g))
add('HEART', ngfx.mc(ngfx.HEART)); add('CHEST', ngfx.mc(ngfx.CHEST))
for i, g in enumerate(ngfx.POOF): add('POOF%d' % i, ngfx.mc(g))
for i, g in enumerate(ngfx.ORB): add('ORB%d' % i, ngfx.mc(g))
for i, g in enumerate(ngfx.BOLT): add('BOLT%d' % i, ngfx.mc(g))
for i, g in enumerate(ngfx.FIRE): add('FIRE%d' % i, ngfx.mc(g))
for d in range(8): add('KNIFE%d' % d, ngfx.mc(ngfx.knife(d)))
assert nxt[0] <= 256
print("game chars used:", nxt[0])
open(os.path.join(OUT, 'charset_game.bin'), 'wb').write(bytes(cs))

# ------------------------------------------------ map
m = ngfx.make_map(ids)
mp = []
for row in m:
    mp += row + row[:MAPROW - 64]
assert len(mp) == 64 * MAPROW

# ------------------------------------------------ sprites
spr = bytearray()
SYM = {}
def sadd(name, data):
    SYM[name] = (SPRBASE - 0x4000) // 64 + len(spr) // 64
    spr.extend(data)
frames = [ngfx.hero(i) for i in range(4)]
for i, (s, h) in enumerate(frames):
    sadd('HEROR%d' % i, h.tobytes()); spr.extend(s.tobytes())
for i, (s, h) in enumerate(frames):
    sadd('HEROL%d' % i, h.hflip().tobytes()); spr.extend(s.hflip().tobytes())
s, h = ngfx.hero(0, dead=True)
sadd('HEROD', h.tobytes()); spr.extend(s.tobytes())
for i in range(2): sadd('AURA%d' % i, ngfx.aura(i).tobytes())
for k in range(3):
    for i in range(2): sadd('BOSS%d_%d' % (k, i), ngfx.boss(k, i).tobytes())
for n in ('HUDT', 'HUDL', 'XPL', 'XPR', 'BODY'):
    sadd(n, bytes(64))
assert len(spr) <= 0x1000
print("sprites:", len(spr) // 64)
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(spr))

# HUD digit font: per glyph 5 rows of 3 bits (left aligned in a nibble)
dig = []
for ch in ngfx.DIGORDER:
    for row in ngfx.DIG[ch]:
        v = 0
        for k, c in enumerate(row):
            if c == '#': v |= 0x80 >> k
        dig.append(v)

# ------------------------------------------------ logo
bm = ngfx.logo_bitmap()
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

# ------------------------------------------------ tables
L = ["; generated data"]
rows = [i * 40 for i in range(25)]
L += bl("rowlo", [r & 255 for r in rows])
L += bl("rowhiA", [(SCRA + r) >> 8 for r in rows])
L += bl("rowhiB", [(SCRB + r) >> 8 for r in rows])
L += bl("rowhiC", [(0xd800 + r) >> 8 for r in rows])
L += bl("logo_chars", logo)
L += bl("logo_grad", [6, 6, 4, 4, 14, 14, 3, 3, 1, 1, 3, 3, 14, 14, 4, 4])
fl, fh = [], []
for n in range(96):
    f = 440.0 * 2 ** ((n - 57) / 12.0)
    r = min(65535, int(round(f * 16777216 / 985248)))
    fl.append(r & 255); fh.append(r >> 8)
L += bl("freq_lo", fl)
L += bl("freq_hi", fh)
L += bl("maprow_lo", [(0x8000 + i * MAPROW) & 255 for i in range(64)])
L += bl("maprow_hi", [(0x8000 + i * MAPROW) >> 8 for i in range(64)])
L += bl("hud_font", dig)
# orbit positions: 32 steps, radius 3 cells (x stretched)
L += bl("orb_dx", [int(round(3.4 * math.cos(i * 2 * math.pi / 32))) & 255 for i in range(32)])
L += bl("orb_dy", [int(round(3.0 * math.sin(i * 2 * math.pi / 32))) & 255 for i in range(32)])
L += bl("bittab", [1, 2, 4, 8, 16, 32, 64, 128])
L += bl("grid_lo", [(y & 3) << 6 for y in range(64)])
L += bl("grid_hi", [0xE0 + (y >> 2) for y in range(64)])
open(os.path.join(OUT, 'gen_data.asm'), 'w').write("\n".join(L) + "\n")
open(os.path.join(OUT, 'map.bin'), 'wb').write(bytes(mp))

K = ["; generated constants"]
for k, v in SYM.items():
    K.append("SPR_%s = $%02x" % (k, v))
for k, v in C.items():
    if k[0].isupper(): K.append("CH_%s = %d" % (k, v))
K.append("CH_QUAD = %d" % CH_QUAD)
K.append("LOGOROWS = %d" % LOGOROWS)
K.append("MAPROW = %d" % MAPROW)
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(K) + "\n")

masm, mbytes, npat = nmusic.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm)
print("music: %d patterns, %d bytes" % (npat, mbytes))
