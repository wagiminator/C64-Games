# SWARM - build all generated data
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import gfx, sgfx, smusic

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

def bytes_lines(label, data, per=16):
    out = [label]
    for i in range(0, len(data), per):
        out.append("  .byte " + ",".join("$%02x" % (b & 255) for b in data[i:i + per]))
    return out

cs = sgfx.build_charset()
open(os.path.join(OUT, 'charset.bin'), 'wb').write(bytes(cs))
spr, syms = sgfx.build_sprites()
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(spr))
sgfx.preview(os.path.join(OUT, 'preview.png'), cs, spr)

# ------------------------------------------------ logo "SWARM" (quadrant chars)
def logo_bitmap():
    W, H = 13, 14
    def glyph(ch):
        g = [[0] * W for _ in range(H)]
        def rect(x0, y0, x1, y1):
            for y in range(max(0, y0), min(H, y1 + 1)):
                for x in range(max(0, x0), min(W, x1 + 1)):
                    g[y][x] = 1
        def diag(x0, y0, x1, y1, t):
            n = 60
            for i in range(n + 1):
                xx = x0 + (x1 - x0) * i / n; yy = y0 + (y1 - y0) * i / n
                for dx in range(t):
                    xi = int(round(xx)) + dx; yi = int(round(yy))
                    if 0 <= xi < W and 0 <= yi < H: g[yi][xi] = 1
        if ch == 'S':
            rect(1, 0, 12, 3); rect(0, 1, 3, 6); rect(1, 5, 11, 8); rect(9, 7, 12, 12); rect(0, 10, 11, 13)
        elif ch == 'W':
            rect(0, 0, 3, 12); rect(9, 0, 12, 12); rect(5, 5, 7, 12); rect(1, 10, 11, 13)
            for x in (3, 4, 8, 9): g[13][x] = 1
        elif ch == 'A':
            rect(0, 2, 3, 13); rect(9, 2, 12, 13); rect(2, 0, 10, 3); rect(0, 6, 12, 8)
        elif ch == 'R':
            rect(0, 0, 3, 13); rect(0, 0, 10, 3); rect(0, 6, 10, 8); rect(9, 1, 12, 7)
            diag(6, 8, 10, 13, 3)
        elif ch == 'M':
            rect(0, 0, 3, 13); rect(9, 0, 12, 13); rect(2, 0, 10, 3); rect(5, 2, 7, 9)
        return g
    WT = 80; HT = 14
    bm = [[0] * WT for _ in range(HT)]
    x = 1
    for ch in "SWARM":
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
LOGOROWS = 7
LOGOROW = 1
logo = []
for r in range(LOGOROWS):
    for c in range(40):
        q = 0
        if bm[r * 2][c * 2]: q |= 1
        if bm[r * 2][c * 2 + 1]: q |= 2
        if bm[r * 2 + 1][c * 2]: q |= 4
        if bm[r * 2 + 1][c * 2 + 1]: q |= 8
        logo.append(gfx.CH_QUAD + q if q else 32)
logo += [32] * (400 - len(logo))

# ------------------------------------------------ tables
L = ["; generated tables"]
rows = [i * 40 for i in range(25)]
L += bytes_lines("rowlo", [r & 255 for r in rows])
L += bytes_lines("rowhiA", [(0x4800 + r) >> 8 for r in rows])
L += bytes_lines("rowhiC", [(0xd800 + r) >> 8 for r in rows])
L += bytes_lines("pat_speed", gfx.PAT_SPEED)
L += bytes_lines("pat_color", gfx.PAT_COLOR)
# star pattern per screen row (255 = empty)
trow = [255, 3, 255, 1, 0, 255, 2, 0, 255, 1, 3, 255, 0, 2, 255, 1, 0, 255, 255, 255, 2, 255, 255, 255, 255]
L += bytes_lines("gamerowpat", trow)
ttl = list(trow)
for r in range(LOGOROW, LOGOROW + LOGOROWS): ttl[r] = 255
ttl[0] = 2; ttl[8] = 1; ttl[18] = 3; ttl[19] = 0; ttl[23] = 2
L += bytes_lines("trowpat", ttl)
L += bytes_lines("logo_chars", logo)
L += bytes_lines("logo_grad", [6, 6, 4, 4, 5, 5, 3, 3, 1, 1, 3, 3, 5, 5, 4, 4])
L += bytes_lines("sintab", [int(round(48 * math.sin(i * 2 * math.pi / 256))) & 255 for i in range(256)])
L += bytes_lines("div10", [i // 10 for i in range(256)])
L += bytes_lines("mod10", [i % 10 for i in range(256)])
for sec in range(3):
    L += bytes_lines("alienset%d" % sec, sgfx.alien_chars(sec))
L.append("alienset_lo .byte <alienset0,<alienset1,<alienset2")
L.append("alienset_hi .byte >alienset0,>alienset1,>alienset2")
L += bytes_lines("bunker_orig", sgfx.bunker_chars())
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
for k in ['CH_QUAD', 'CH_BG', 'CH_BAR', 'CH_BARL', 'CH_BARR', 'CH_ALIEN', 'CH_BUNK', 'CH_GROUND', 'CH_LIFE']:
    C.append("%s = %d" % (k, getattr(sgfx, k)))
C.append("LOGOROW = %d" % LOGOROW)
C.append("LOGOROWS = %d" % LOGOROWS)
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(C) + "\n")

masm, mbytes, npat = smusic.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm)
print("sprites:", len(spr) // 64, "music patterns:", npat, "bytes:", mbytes)
if '-logo' in sys.argv:
    for r in bm: print("".join("#" if v else "." for v in r))
