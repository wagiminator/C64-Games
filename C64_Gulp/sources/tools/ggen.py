# GULP! - build all generated data
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import gfx, ggfx, gscene, gmusic

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

CH_QUAD, CH_BG, CH_BAR, CH_BARL, CH_BARR = 64, 80, 112, 117, 118
CH_LIFE, CH_PLK, CH_SCEN = 119, 120, 128

def bytes_lines(label, data, per=16):
    out = [label]
    for i in range(0, len(data), per):
        out.append("  .byte " + ",".join("$%02x" % (b & 255) for b in data[i:i + per]))
    return out

# ------------------------------------------------ patterns (bubbles, plankton, surface waves)
def patterns():
    P = []
    b = [[0] * 16 for _ in range(8)]                       # 0: bubble ring
    for (x, y) in ((4, 2), (5, 2), (3, 3), (6, 3), (3, 4), (6, 4), (4, 5), (5, 5), (12, 6)):
        b[y][x] = 1
    P.append(b)
    b = [[0] * 16 for _ in range(8)]                       # 1: two specks
    b[2][3] = 1; b[5][11] = 1; b[5][12] = 1; P.append(b)
    b = [[0] * 16 for _ in range(8)]                       # 2: single speck
    b[4][7] = 1; P.append(b)
    b = [[0] * 16 for _ in range(8)]                       # 3: surface wave
    for x in range(16):
        y = 3 + int(round(1.6 * math.sin(x * 2 * math.pi / 16)))
        b[y][x] = 1
        if x % 16 in (2, 3, 4, 5): b[y - 1][x] = 1
        for yy in range(y + 2, 8, 2):
            if (x + yy) % 4 == 0: b[yy][x] = 1
    P.append(b)
    return P

cs = bytearray(2048)
for ch, rows in gfx.FONT.items():
    sc = gfx.screencode(ch); cs[sc * 8:sc * 8 + 8] = bytes(gfx.glyph_bytes(rows))
for q in range(16):
    for y in range(8):
        v = 0
        if y < 4:
            if q & 1: v |= 0xF0
            if q & 2: v |= 0x0F
        else:
            if q & 4: v |= 0xF0
            if q & 8: v |= 0x0F
        cs[(CH_QUAD + q) * 8 + y] = v
for p, bm in enumerate(patterns()):
    for k in range(2):
        for y in range(8):
            v = 0
            for i in range(8):
                if bm[y][k * 8 + i]: v |= 0x80 >> i
            cs[(CH_BG + p * 2 + k) * 8 + y] = v
for n in range(5):
    for y in range(8):
        if y in (0, 7): v = 0xFF
        elif y in (1, 6): v = 0
        else: v = (0xFF << (8 - n * 2)) & 0xFF
        cs[(CH_BAR + n) * 8 + y] = v
cs[CH_BARL * 8:CH_BARL * 8 + 8] = bytes([0x07, 0x08, 0x10, 0x10, 0x10, 0x10, 0x08, 0x07])
cs[CH_BARR * 8:CH_BARR * 8 + 8] = bytes([0xE0, 0x10, 0x08, 0x08, 0x08, 0x08, 0x10, 0xE0])
cs[CH_LIFE * 8:CH_LIFE * 8 + 8] = bytes([0x00, 0x1c, 0x9e, 0xfb, 0xff, 0x9e, 0x1c, 0x00])
cs[CH_PLK * 8:CH_PLK * 8 + 8] = bytes([0, 0, 0x20, 0, 0, 0, 0, 0])
cs[(CH_PLK + 1) * 8:(CH_PLK + 1) * 8 + 8] = bytes([0, 0, 0, 0, 0, 0x04, 0, 0])
ch0, _, _ = gscene.encode(0)
for i, (d, c) in enumerate(ch0):
    cs[(CH_SCEN + i) * 8:(CH_SCEN + i) * 8 + 8] = d
open(os.path.join(OUT, 'charset.bin'), 'wb').write(bytes(cs))

spr, syms = ggfx.build_sprites()
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(spr))

# ------------------------------------------------ logo "GULP!"
def logo_bitmap():
    W, H = 13, 14
    def glyph(ch):
        w = 6 if ch == '!' else W
        g = [[0] * w for _ in range(H)]
        def rect(x0, y0, x1, y1):
            for y in range(max(0, y0), min(H, y1 + 1)):
                for x in range(max(0, x0), min(w, x1 + 1)): g[y][x] = 1
        if ch == 'G':
            rect(2, 0, 12, 3); rect(0, 1, 3, 12); rect(2, 10, 11, 13); rect(9, 6, 12, 12); rect(6, 6, 12, 8)
        elif ch == 'U':
            rect(0, 0, 3, 11); rect(9, 0, 12, 11); rect(1, 10, 11, 13)
        elif ch == 'L':
            rect(0, 0, 3, 13); rect(0, 10, 12, 13)
        elif ch == 'P':
            rect(0, 0, 3, 13); rect(0, 0, 10, 3); rect(0, 6, 10, 9); rect(9, 1, 12, 8)
        elif ch == '!':
            rect(1, 0, 4, 9); rect(1, 11, 4, 13)
        return g
    WT = 80; bm = [[0] * WT for _ in range(H)]
    x = 6
    for ch in "GULP!":
        g = glyph(ch); w = len(g[0])
        for y in range(H):
            sh = (H - 1 - y) // 4
            for xx in range(w):
                if g[y][xx]:
                    X = x + xx + sh
                    if 0 <= X < WT: bm[y][X] = 1
        x += w + 3
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
        logo.append(CH_QUAD + q if q else 32)
logo += [32] * (400 - len(logo))

# ------------------------------------------------ tables
L = ["; generated tables"]
rows = [i * 40 for i in range(25)]
L += bytes_lines("rowlo", [r & 255 for r in rows])
L += bytes_lines("rowhiA", [(0x4800 + r) >> 8 for r in rows])
L += bytes_lines("rowhiC", [(0xd800 + r) >> 8 for r in rows])
L += bytes_lines("pat_speed_title", [40, 70, 100, 50])
L += bytes_lines("pat_speed_game", [0, 0, 0, 60])
L += bytes_lines("pat_color", [1, 3, 7, 1])
ttl = [2, 255, 255, 255, 255, 255, 255, 255, 255, 1, 255, 0, 255, 2, 255, 255, 1, 255, 0, 255, 255, 255, 2, 255, 3]
L += bytes_lines("trowpat", ttl)
L += bytes_lines("logo_chars", logo)
L += bytes_lines("logo_grad", [6, 6, 3, 3, 5, 5, 7, 7, 1, 1, 7, 7, 5, 5, 3, 3])
L += bytes_lines("sintab", [int(round(127 * math.sin(i * 2 * math.pi / 256))) & 255 for i in range(256)])
sparse = [1 if ((i * 37) % 64) < 7 else 0 for i in range(64)]
L += bytes_lines("sparse", sparse)
for z in range(3):
    ch, m, c = gscene.encode(z)
    data = bytearray()
    for d, col in ch: data += d
    L += bytes_lines("scen%d_chars" % z, data)
    L += bytes_lines("scen%d_col" % z, [(col | 8) for d, col in ch])
    L.append("scen%d_cnt = %d" % (z, len(ch)))
    rle = []
    flat = [v for row in m for v in row]
    i = 0
    while i < len(flat):
        if flat[i] is None:
            n = 0
            while i < len(flat) and flat[i] is None and n < 127: n += 1; i += 1
            rle.append(0x80 | n)
        else:
            rle.append(flat[i]); i += 1
    L += bytes_lines("scen%d_map" % z, rle)
L.append("scen_chars_lo .byte <scen0_chars,<scen1_chars,<scen2_chars")
L.append("scen_chars_hi .byte >scen0_chars,>scen1_chars,>scen2_chars")
L.append("scen_col_lo .byte <scen0_col,<scen1_col,<scen2_col")
L.append("scen_col_hi .byte >scen0_col,>scen1_col,>scen2_col")
L.append("scen_map_lo .byte <scen0_map,<scen1_map,<scen2_map")
L.append("scen_map_hi .byte >scen0_map,>scen1_map,>scen2_map")
L.append("scen_cnt .byte scen0_cnt,scen1_cnt,scen2_cnt")
for k in ('bg', 'd022', 'd023', 'plank'):
    L.append("zone_%s .byte %s" % (k, ",".join(str(gscene.ZONES[z][k]) for z in range(3))))
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
for k in ('CH_QUAD', 'CH_BG', 'CH_BAR', 'CH_BARL', 'CH_BARR', 'CH_LIFE', 'CH_PLK', 'CH_SCEN', 'LOGOROW', 'LOGOROWS'):
    C.append("%s = %d" % (k, globals()[k]))
C.append("SPR_END = $%02x" % (0x30 + len(spr) // 64))
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(C) + "\n")

masm, mbytes, npat = gmusic.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm)
print("sprites:", len(spr) // 64, "music patterns:", npat)
if '-logo' in sys.argv:
    for r in bm: print("".join("#" if v else "." for v in r))
