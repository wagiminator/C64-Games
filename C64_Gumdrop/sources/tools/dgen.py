# GUMDROP - build all generated data (charset, sprites, sweets, pictures, levels, tables, music)
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import gfx, dgfx, dmusic

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

SCRG, BITMAP, SPRBASE = 0x4C00, 0x6000, 0x5000
BX0, BY0 = 11, 8                  # board: byte column 11, line 8 (screen row 1)

def bl(label, data, per=16):
    out = [label]
    data = list(data)
    for i in range(0, len(data), per):
        out.append("  .byte " + ",".join("$%02x" % (b & 255) for b in data[i:i + per]))
    if not data: out.append("  .byte 0")
    return out

# ------------------------------------------------ charset ($4000): font, logo quads, heart
cs = bytearray(2048)
for ch, rows in gfx.FONT.items():
    code = gfx.screencode(ch)
    cs[code * 8:code * 8 + 8] = bytes(gfx.glyph_bytes(rows))
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
    cs[(CH_QUAD + q) * 8:(CH_QUAD + q) * 8 + 8] = d
CH_HEART = 80
cs[CH_HEART * 8:CH_HEART * 8 + 8] = bytes(dgfx.HEART_CHAR)
open(os.path.join(OUT, 'charset.bin'), 'wb').write(bytes(cs))

# ------------------------------------------------ sweets
shapes = dgfx.all_shapes()
NSHAPE = len(shapes)
shpA, shpB = [], []
for g in shapes:
    shpA += dgfx.bitmap_bytes(g, 0)
    shpB += dgfx.bitmap_bytes(g, 1)
ice = dgfx.bitmap_bytes(dgfx.ICE, 0) + dgfx.bitmap_bytes(dgfx.ICE2, 0)

# ------------------------------------------------ sprites
spr = bytearray()
SYM = {}
def add(name, data):
    SYM[name] = (SPRBASE - 0x4000) // 64 + len(spr) // 64
    spr.extend(data)
add('CURSOR0', dgfx.cursor(False))
add('CURSOR1', dgfx.cursor(True))
for i in range(25):
    add('SWEET%d' % i, dgfx.sweet_sprite(shapes[i]))
add('BLANK', bytes(64))
assert len(spr) <= 0x1000
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(spr))

# ------------------------------------------------ pictures
jbm, jscr, jcol = dgfx.cells_from_picture(dgfx.jar_picture(), 10, 20)
mbm, mscr, mcol = dgfx.cells_from_picture(dgfx.meter_picture(), 10, 20)
ftop, fside, fcorner = dgfx.frame_cells()

# ------------------------------------------------ logo
bm = dgfx.logo_bitmap()
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

# ------------------------------------------------ levels
def lay(rows):
    out = []
    for r in rows:
        assert len(r) == 9, r
        out += [int(c) if c != '.' else 0 for c in r]
    return out
LAYOUTS = {
    'none': lay(['.........'] * 9),
    'centre': lay(['.........', '.........', '.........', '...111...', '...111...', '...111...', '.........', '.........', '.........']),
    'border': lay(['111111111', '1.......1', '1.......1', '1.......1', '1.......1', '1.......1', '1.......1', '1.......1', '111111111']),
    'cross': lay(['....1....', '....1....', '....1....', '....1....', '111111111', '....1....', '....1....', '....1....', '....1....']),
    'checker': lay(['1.1.1.1.1', '.........', '1.1.1.1.1', '.........', '1.1.1.1.1', '.........', '1.1.1.1.1', '.........', '1.1.1.1.1']),
    'centre2': lay(['.........', '.........', '..11111..', '..12221..', '..12221..', '..12221..', '..11111..', '.........', '.........']),
    'x': lay(['1.......1', '.1.....1.', '..1...1..', '...1.1...', '....2....', '...1.1...', '..1...1..', '.1.....1.', '1.......1']),
    'rows': lay(['.........', '111111111', '.........', '.........', '222222222', '.........', '.........', '111111111', '.........']),
    'ring2': lay(['.........', '.2222222.', '.2.....2.', '.2.111.2.', '.2.111.2.', '.2.111.2.', '.2.....2.', '.2222222.', '.........']),
    'full': lay(['111111111'] * 9),
    'heart2': lay(['.........', '.22...22.', '2222.2222', '222222222', '222222222', '.2222222.', '..22222..', '...222...', '....2....']),
    'full2': lay(['222222222', '211111112', '211111112', '211111112', '211111112', '211111112', '211111112', '211111112', '222222222']),
    'corners': lay(['222...222', '22.....22', '2.......2', '.........', '.........', '.........', '2.......2', '22.....22', '222...222']),
}
LKEYS = list(LAYOUTS)
# (goal 0 = score / 1 = ice, target score, moves, colours, layout)
LEVELS = [
    (0, 2000, 15, 5, 'none'),
    (0, 4000, 18, 5, 'none'),
    (1, 0, 20, 5, 'centre'),
    (0, 8000, 20, 6, 'none'),
    (1, 0, 25, 5, 'border'),
    (0, 12000, 22, 6, 'none'),
    (1, 0, 22, 6, 'cross'),
    (1, 0, 25, 6, 'checker'),
    (0, 18000, 25, 6, 'none'),
    (1, 0, 25, 6, 'centre2'),
    (0, 22000, 22, 6, 'none'),
    (1, 0, 24, 6, 'x'),
    (1, 0, 26, 6, 'rows'),
    (0, 28000, 24, 6, 'none'),
    (1, 0, 28, 6, 'ring2'),
    (0, 32000, 25, 6, 'none'),
    (1, 0, 30, 6, 'corners'),
    (1, 0, 28, 6, 'heart2'),
    (0, 40000, 25, 6, 'none'),
    (1, 0, 34, 6, 'full2'),
]
def bcd(n): return int(str(n), 16)

# ------------------------------------------------ data tables
L = ["; generated data"]
rows = [i * 40 for i in range(25)]
L += bl("rowlo", [r & 255 for r in rows])
L += bl("rowhiA", [(0x4800 + r) >> 8 for r in rows])
L += bl("rowhiG", [(SCRG + r) >> 8 for r in rows])
L += bl("rowhiC", [(0xd800 + r) >> 8 for r in rows])
L += bl("logo_chars", logo)
L += bl("logo_grad", [10, 10, 2, 2, 4, 4, 14, 14, 3, 3, 7, 7, 1, 1, 7, 7])
fl, fh = [], []
for n in range(96):
    f = 440.0 * 2 ** ((n - 57) / 12.0)
    r = min(65535, int(round(f * 16777216 / 985248)))
    fl.append(r & 255); fh.append(r >> 8)
L += bl("freq_lo", fl)
L += bl("freq_hi", fh)
# board line addresses (board line 0..143 at byte column BX0)
la = [BITMAP + ((BY0 + l) >> 3) * 320 + ((BY0 + l) & 7) + BX0 * 8 for l in range(144)]
L += bl("blin_lo", [a & 255 for a in la])
L += bl("blin_hi", [a >> 8 for a in la])
# bitmap cell rows (row 0..24) at byte column 0
L += bl("bmrow_lo", [(BITMAP + r * 320) & 255 for r in range(25)])
L += bl("bmrow_hi", [(BITMAP + r * 320) >> 8 for r in range(25)])
L += bl("shapeA", shpA)
L += bl("shapeB", shpB)
L += bl("ice_bm", ice)
L += bl("jar_bm", jbm); L += bl("jar_scr", jscr); L += bl("jar_col", jcol)
L += bl("met_bm", mbm); L += bl("met_scr", mscr); L += bl("met_col", mcol)
L += bl("frm_top", ftop); L += bl("frm_side", fside); L += bl("frm_corner", fcorner)
L += bl("sweet_col", dgfx.COLOURS)
for k in LKEYS:
    L += bl("lay_%s" % k, LAYOUTS[k], 9)
L.append("lay_lo .byte " + ",".join("<lay_%s" % k for k in LKEYS))
L.append("lay_hi .byte " + ",".join(">lay_%s" % k for k in LKEYS))
L += bl("lv_goal", [l[0] for l in LEVELS])
L += bl("lv_t0", [bcd(l[1]) & 255 for l in LEVELS])
L += bl("lv_t1", [(bcd(l[1]) >> 8) & 255 for l in LEVELS])
L += bl("lv_t2", [(bcd(l[1]) >> 16) & 255 for l in LEVELS])
L += bl("lv_tbin", [l[1] // 200 for l in LEVELS])          # target / 200 (for the meter)
L += bl("lv_moves", [l[2] for l in LEVELS])
L += bl("lv_cols", [l[3] for l in LEVELS])
L += bl("lv_lay", [LKEYS.index(l[4]) for l in LEVELS])
L += bl("bittab", [1, 2, 4, 8, 16, 32, 64, 128])
# meter: fill height (lines) for progress p (0..64) -> 0..120
L += bl("meter_h", [min(120, (p * 120) // 64) for p in range(65)])
open(os.path.join(OUT, 'gen_data.asm'), 'w').write("\n".join(L) + "\n")

C = ["; generated constants"]
for k, v in SYM.items():
    C.append("SPR_%s = $%02x" % (k, v))
for k, v in dict(CH_QUAD=CH_QUAD, CH_HEART=CH_HEART, LOGOROWS=LOGOROWS, NSHAPE=NSHAPE, NLEVELS=len(LEVELS),
                 SH_RAINBOW=24, SH_POP0=25, SH_POP1=26, BX0=BX0, BY0=BY0,
                 MET_X0=30 + dgfx.METER_X0, MET_X1=30 + dgfx.METER_X1,
                 MET_TOP=dgfx.METER_TOP, MET_BOT=dgfx.METER_BOT).items():
    C.append("%s = %d" % (k, v))
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(C) + "\n")

masm, mbytes, npat = dmusic.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm)
print("shapes %d, sprites %d, music %d patterns %d bytes" % (NSHAPE, len(spr) // 64, npat, mbytes))
