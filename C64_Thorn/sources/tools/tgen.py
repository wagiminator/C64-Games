# THORN - build all generated data
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import gfx, tgfx, tmusic

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

CH = dict(CH_QUAD=64, CH_BG=80, CH_GRASS=88, CH_PEA=90, CH_MOWER=106, CH_BAR=112, CH_BARL=117, CH_BARR=118,
          CH_WALL=119, CH_STONE=120, CH_SUNI=121, CH_SOLID=125, CH_LIFE=126, CH_PLANT=132, CH_ICON=204, CH_SHOV=228)

def bytes_lines(label, data, per=16):
    out = [label]
    for i in range(0, len(data), per):
        out.append("  .byte " + ",".join("$%02x" % (b & 255) for b in data[i:i + per]))
    return out

cs = bytearray(2048)
def put(ch, data): cs[ch * 8:ch * 8 + 8] = data
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
    put(CH['CH_QUAD'] + q, d)
# title patterns: little flowers / leaves / dots (hires 16x8)
pats = []
for p in range(4):
    bm = [[0] * 16 for _ in range(8)]
    if p == 0:
        for (x, y) in ((4, 2), (3, 3), (5, 3), (4, 4), (12, 6)): bm[y][x] = 1
    elif p == 1:
        for (x, y) in ((2, 5), (3, 4), (4, 4), (10, 2)): bm[y][x] = 1
    elif p == 2:
        bm[3][7] = 1
    else:
        bm[5][2] = 1; bm[2][11] = 1
    pats.append(bm)
for p, bm in enumerate(pats):
    for k in range(2):
        d = bytearray(8)
        for y in range(8):
            v = 0
            for i in range(8):
                if bm[y][k * 8 + i]: v |= 0x80 >> i
            d[y] = v
        put(CH['CH_BG'] + p * 2 + k, d)
# lawn
put(CH['CH_GRASS'], tgfx.grass(0).chars()[0][0])
put(CH['CH_GRASS'] + 1, tgfx.grass(1).chars()[0][0])
pc = tgfx.pea_chars(0) + tgfx.pea_chars(1)
for i, (d, c) in enumerate(pc): put(CH['CH_PEA'] + i, d)
mw = tgfx.mower().chars()
for i, (d, c) in enumerate(mw): put(CH['CH_MOWER'] + i, d)
for n in range(5):
    d = bytearray(8)
    for y in range(8):
        if y in (0, 7): v = 0xFF
        elif y in (1, 6): v = 0
        else: v = (0xFF << (8 - n * 2)) & 0xFF
        d[y] = v
    put(CH['CH_BAR'] + n, d)
put(CH['CH_BARL'], bytes([0x07, 0x08, 0x10, 0x10, 0x10, 0x10, 0x08, 0x07]))
put(CH['CH_BARR'], bytes([0xE0, 0x10, 0x08, 0x08, 0x08, 0x08, 0x10, 0xE0]))
wall = tgfx.patio(0).chars()[0]; stone = tgfx.patio(1).chars()[0]
put(CH['CH_WALL'], wall[0]); put(CH['CH_STONE'], stone[0])
si = tgfx.sun_icon().chars()
for i, (d, c) in enumerate(si): put(CH['CH_SUNI'] + i, d)
put(CH['CH_SOLID'], bytes([0xff] * 8))
put(CH['CH_LIFE'], bytes([0x00, 0x66, 0xff, 0xff, 0x7e, 0x3c, 0x18, 0x00]))
# plants (frame 0 resident; both frames as data for animation)
plant_frames = []
plant_cols = []
for i, f in enumerate(tgfx.PLANTS):
    fr = [f(0).chars(), f(1).chars()]
    plant_frames.append(fr)
    plant_cols.append([c for d, c in fr[0]])
    for k, (d, c) in enumerate(fr[0]): put(CH['CH_PLANT'] + i * 12 + k, d)
icon_cols = []
for i in range(6):
    ic = tgfx.icon(i).chars()
    icon_cols.append([c for d, c in ic])
    for k, (d, c) in enumerate(ic): put(CH['CH_ICON'] + i * 4 + k, d)
sh = tgfx.shovel_icon().chars()
for k, (d, c) in enumerate(sh): put(CH['CH_SHOV'] + k, d)
open(os.path.join(OUT, 'charset.bin'), 'wb').write(bytes(cs))

spr, syms = tgfx.build_sprites()
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(spr))

# ------------------------------------------------ logo "THORN"
def logo_bitmap():
    W, H = 13, 14
    def glyph(ch):
        g = [[0] * W for _ in range(H)]
        def rect(x0, y0, x1, y1):
            for y in range(max(0, y0), min(H, y1 + 1)):
                for x in range(max(0, x0), min(W, x1 + 1)): g[y][x] = 1
        if ch == 'T':
            rect(0, 0, 12, 3); rect(5, 0, 8, 13)
        elif ch == 'H':
            rect(0, 0, 3, 13); rect(9, 0, 12, 13); rect(0, 5, 12, 8)
        elif ch == 'O':
            rect(2, 0, 10, 3); rect(2, 10, 10, 13); rect(0, 2, 3, 11); rect(9, 2, 12, 11)
        elif ch == 'R':
            rect(0, 0, 3, 13); rect(0, 0, 10, 3); rect(0, 6, 10, 8); rect(9, 1, 12, 7)
            for i in range(7):
                for t in range(3):
                    x = 6 + i // 2 + t + (i % 2); y = 8 + i
                    if x < W and y < H: g[y][x] = 1
        elif ch == 'N':
            rect(0, 0, 3, 13); rect(9, 0, 12, 13)
            for i in range(14):
                for t in range(3):
                    x = 2 + int(i * 7 / 13) + t
                    if x < W: g[i][x] = 1
        return g
    WT = 80; bm = [[0] * WT for _ in range(H)]
    x = 1
    for ch in "THORN":
        g = glyph(ch)
        for y in range(H):
            sh = (H - 1 - y) // 4
            for xx in range(W):
                if g[y][xx]:
                    X = x + xx + sh
                    if 0 <= X < WT: bm[y][X] = 1
        x += W + 2
    return bm

bm = logo_bitmap()
LOGOROW, LOGOROWS = 1, 7
logo = []
for r in range(LOGOROWS):
    for c in range(40):
        q = 0
        if bm[r * 2][c * 2]: q |= 1
        if bm[r * 2][c * 2 + 1]: q |= 2
        if bm[r * 2 + 1][c * 2]: q |= 4
        if bm[r * 2 + 1][c * 2 + 1]: q |= 8
        logo.append(CH['CH_QUAD'] + q if q else 32)
logo += [32] * (400 - len(logo))

L = ["; generated tables"]
rows = [i * 40 for i in range(25)]
L += bytes_lines("rowlo", [r & 255 for r in rows])
L += bytes_lines("rowhiA", [(0x4800 + r) >> 8 for r in rows])
L += bytes_lines("rowhiC", [(0xd800 + r) >> 8 for r in rows])
L += bytes_lines("pat_speed_title", [40, 70, 100, 130])
L += bytes_lines("pat_color", [7, 5, 3, 1])
ttl = [2, 255, 255, 255, 255, 255, 255, 255, 255, 1, 255, 0, 255, 2, 255, 255, 1, 255, 0, 255, 255, 255, 2, 255, 3]
L += bytes_lines("trowpat", ttl)
L += bytes_lines("logo_chars", logo)
L += bytes_lines("logo_grad", [5, 5, 5, 5, 7, 7, 2, 2, 7, 7, 5, 5, 3, 3, 5, 5])
L += bytes_lines("sintab", [int(round(127 * math.sin(i * 2 * math.pi / 256))) & 255 for i in range(256)])
# plant colours (12 per type, colour RAM = colour | 8) and animation frames
L += bytes_lines("plant_col", [c | 8 for cols in plant_cols for c in cols])
L += bytes_lines("icon_col", [c | 8 for cols in icon_cols for c in cols])
fdat = bytearray()
for fr in plant_frames:
    for f in range(2):
        for d, c in fr[f]: fdat += d
L += bytes_lines("plant_anim", fdat)
L += bytes_lines("mower_col", [c | 8 for d, c in mw])
L.append("wall_col = %d" % (wall[1] | 8))
L.append("stone_col = %d" % (stone[1] | 8))
L += bytes_lines("suni_col", [c | 8 for d, c in si])
L += bytes_lines("shov_col", [c | 8 for d, c in sh])
fl, fh = [], []
for n in range(96):
    f = 440.0 * 2 ** ((n - 57) / 12.0)
    r = min(65535, int(round(f * 16777216 / 985248)))
    fl.append(r & 255); fh.append(r >> 8)
L += bytes_lines("freq_lo", fl)
L += bytes_lines("freq_hi", fh)
open(os.path.join(OUT, 'gen_data.asm'), 'w').write("\n".join(L) + "\n")

C = ["; generated constants"]
for k, v in syms.items():
    C.append("SPR_%s = $%02x" % (k.upper(), v))
for k, v in CH.items():
    C.append("%s = %d" % (k, v))
C.append("LOGOROW = %d" % LOGOROW)
C.append("LOGOROWS = %d" % LOGOROWS)
C.append("SPR_END = $%02x" % (0x30 + len(spr) // 64))
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(C) + "\n")

masm, mbytes, npat = tmusic.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm)
print("sprites:", len(spr) // 64, syms)
if '-logo' in sys.argv:
    for r in bm: print("".join("#" if v else "." for v in r))
