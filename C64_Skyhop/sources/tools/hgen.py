# SKYHOP - build all generated data (charset, sprites, tables, music)
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import gfx, hgfx, hmusic

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

SCRA, SCRB, SPRBASE = 0x4800, 0x4C00, 0x5000
CH_QUAD, CH_BG = 64, 80          # BG_EVEN = 80, BG_ODD = 81, shapes from 82
BGM = 80                         # marker in shape data: background cell

def bl(label, data, per=16):
    out = [label]
    data = list(data)
    for i in range(0, len(data), per):
        out.append("  .byte " + ",".join("$%02x" % (b & 255) for b in data[i:i + per]))
    if not data: out.append("  .byte 0")
    return out

# ------------------------------------------------ charset
cs = bytearray(2048)
def put(ch, d): cs[ch * 8:ch * 8 + 8] = d
for ch, rows in gfx.FONT.items():
    put(gfx.screencode(ch), bytes(gfx.glyph_bytes(rows)))
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
    put(CH_QUAD + q, d)
put(CH_BG, hgfx.BG_EVEN)
put(CH_BG + 1, hgfx.BG_ODD)
EMPTY = hgfx.BG_ODD              # a shape cell that is just paper (+ grid row) -> background

chars = {}
nextch = [82]
def charid(b):
    if b == EMPTY: return BGM
    if b not in chars:
        chars[b] = nextch[0]; put(nextch[0], b); nextch[0] += 1
    return chars[b]

SHAPES = []                      # (name, w, h, [char ids top-left .. bottom-right])
def add_shape(name, pix):
    rows = pix.chars()
    ids = [charid(b) for row in rows for b in row]
    SHAPES.append((name, len(rows[0]), len(rows), ids))

add_shape('PLAT', hgfx.platform_pix('plain'))
for p in range(4):
    add_shape('MOVE%d' % p, hgfx.shifted(hgfx.platform_pix('plain'), p))
add_shape('BREAK', hgfx.platform_pix('crack'))
add_shape('BROKEN', hgfx.platform_pix('broken'))
add_shape('POOF', hgfx.platform_pix('poof'))
add_shape('SPRING', hgfx.spring_pix(False))
add_shape('SPRING2', hgfx.spring_pix(True))
add_shape('HAT', hgfx.hat_pix())
add_shape('JET', hgfx.jet_pix())
add_shape('MOON', hgfx.moon_pix())
assert nextch[0] <= 256, nextch[0]
print("chars used:", nextch[0])
open(os.path.join(OUT, 'charset.bin'), 'wb').write(bytes(cs))

# ------------------------------------------------ sprites
spr = bytearray()
SYM = {}
def add(name, data):
    SYM[name] = SPRBASE // 64 - 0x40 * 1 + len(spr) // 64 if False else (SPRBASE - 0x4000) // 64 + len(spr) // 64
    spr.extend(data)

HERO = [('stand', lambda: hgfx.hero('stand')), ('squash', lambda: hgfx.hero('squash')),
        ('hat0', lambda: hgfx.hero_hat(0)), ('hat1', lambda: hgfx.hero_hat(1)),
        ('jet0', lambda: hgfx.hero_jet(0)), ('jet1', lambda: hgfx.hero_jet(1)),
        ('dead', lambda: hgfx.hero('dead')), ('shoot', lambda: hgfx.hero('shoot'))]
NHERO = len(HERO)
frames_r = [f() for _, f in HERO]
for i, (mc, hr) in enumerate(frames_r):            # facing right: overlay, body pairs
    add('HERO_R%d' % i, hr.tobytes()); spr.extend(mc.tobytes())
for i, (mc, hr) in enumerate(frames_r):            # facing left (mirrored)
    add('HERO_L%d' % i, hr.hflip().tobytes()); spr.extend(mc.hflip().tobytes())
for name, f in (('BLOB', hgfx.monster_blob), ('BAT', hgfx.monster_bat), ('HOLE', hgfx.monster_hole)):
    add(name, f(0).tobytes()); spr.extend(f(1).tobytes())
add('BULLET', hgfx.bullet().tobytes())
add('FLAG', hgfx.flag().tobytes())
add('BLANK', bytes(64))
add('SCORE', bytes(64 * 4))                       # 2 buffers x 2 sprites, drawn at run time
assert len(spr) <= 0x1000, len(spr)
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(spr))

# ------------------------------------------------ logo
bm = hgfx.logo_bitmap()
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
L += bl("logo_grad", [7, 7, 8, 8, 10, 10, 2, 2, 10, 10, 8, 8, 7, 7, 1, 1])
fl, fh = [], []
for n in range(96):
    f = 440.0 * 2 ** ((n - 57) / 12.0)
    r = min(65535, int(round(f * 16777216 / 985248)))
    fl.append(r & 255); fh.append(r >> 8)
L += bl("freq_lo", fl)
L += bl("freq_hi", fh)
# shapes
L += bl("shp_w", [s[1] for s in SHAPES])
L += bl("shp_h", [s[2] for s in SHAPES])
L.append("shp_lo .byte " + ",".join("<shp_%s" % s[0] for s in SHAPES))
L.append("shp_hi .byte " + ",".join(">shp_%s" % s[0] for s in SHAPES))
for name, w, h, ids in SHAPES:
    L += bl("shp_%s" % name, ids)

# difficulty per level (height / 3072 px, 0..15)
D = dict(
    gapmin=[3, 3, 3, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7],
    gapmax=[5, 6, 6, 7, 7, 8, 8, 9, 9, 9, 10, 10, 10, 10, 10, 10],
    pextra=[210, 180, 150, 120, 95, 75, 55, 45, 35, 25, 15, 8, 0, 0, 0, 0],
    pmove=[0, 12, 28, 45, 60, 72, 84, 96, 108, 118, 128, 136, 144, 152, 160, 168],
    pvan=[0, 0, 10, 18, 24, 30, 36, 42, 48, 52, 56, 60, 62, 64, 64, 64],
    pbreak=[0, 25, 45, 60, 70, 80, 90, 100, 110, 118, 124, 128, 128, 128, 128, 128],
    pspring=[26, 26, 24, 22, 22, 20, 20, 18, 18, 17, 16, 16, 15, 15, 15, 15],
    phat=[0, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6],
    pjet=[0, 0, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
    mgap=[0, 0, 90, 80, 70, 62, 56, 50, 46, 42, 40, 38, 36, 34, 32, 30],
    mtypes=[0, 0, 1, 1, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],      # 1 blob, 2 +bat, 3 +hole
    mspeed=[1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2],      # moving platform frames per step
)
for k, v in D.items():
    L += bl("d_" + k, v)
L += bl("lvltab", [min(15, i // 12) for i in range(256)])
# zones: height thresholds, colours (paper, grid, outline, score/bullet)
ZONES = [(0, 1, 14, 0, 0), (5000, 14, 15, 0, 0), (12000, 10, 15, 0, 0), (22000, 6, 14, 0, 1), (35000, 0, 11, 15, 1)]
L += bl("zone_lo", [z[0] & 255 for z in ZONES] + [255])
L += bl("zone_hi", [z[0] >> 8 for z in ZONES] + [255])
L += bl("zone_bg", [z[1] for z in ZONES])
L += bl("zone_grid", [z[2] for z in ZONES])
L += bl("zone_out", [z[3] for z in ZONES])
L += bl("zone_txt", [z[4] for z in ZONES])
open(os.path.join(OUT, 'gen_data.asm'), 'w').write("\n".join(L) + "\n")

# ------------------------------------------------ constants
C = ["; generated constants"]
for i, (name, w, h, ids) in enumerate(SHAPES):
    C.append("S_%s = %d" % (name, i))
for k, v in SYM.items():
    C.append("SPR_%s = $%02x" % (k, v))
C.append("NHERO = %d" % NHERO)
C.append("CH_QUAD = %d" % CH_QUAD)
C.append("CH_BG = %d" % CH_BG)
C.append("BGM = %d" % BGM)
C.append("LOGOROWS = %d" % LOGOROWS)
C.append("MOON_W = %d" % hgfx.MOON_W)
C.append("MOON_H = %d" % hgfx.MOON_H)
C.append("MOON_TOP = %d" % hgfx.moon_top_offset())   # pixel rows above the surface in the top char row(s)
C.append("NZONES = %d" % len(ZONES))
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(C) + "\n")

# ------------------------------------------------ music
masm, mbytes, npat = hmusic.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm)
print("music: %d patterns, %d bytes" % (npat, mbytes))
