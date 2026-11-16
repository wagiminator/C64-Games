# ZYRON - build all generated data
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import gfx, levels, music

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

def bytes_lines(label, data, per=16):
    out = [label]
    for i in range(0, len(data), per):
        out.append("  .byte " + ",".join("$%02x" % (b & 255) for b in data[i:i + per]))
    return out

# ------------------------------------------------ charset
cs = gfx.build_base_charset()
tsets, tcols = gfx.terrain_sets()
# level 1 terrain preloaded (chars 128..159)
cs[128 * 8:160 * 8] = tsets[0:256]
open(os.path.join(OUT, 'charset.bin'), 'wb').write(bytes(cs))

# ------------------------------------------------ sprites
sprdata, syms, S, bosses = gfx.build_sprites()
assert len(sprdata) <= 0x3000
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(sprdata))
gfx.render_preview(os.path.join(OUT, 'preview.png'), cs, sprdata, tsets, tcols)

# ------------------------------------------------ logo (quadrant chars)
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
                    xi = int(round(xx)) + dx
                    yi = int(round(yy))
                    if 0 <= xi < W and 0 <= yi < H: g[yi][xi] = 1
        if ch == 'Z':
            rect(0, 0, 12, 3); rect(0, 10, 12, 13); diag(9, 3, 0, 10, 4)
        elif ch == 'Y':
            diag(0, 0, 4, 6, 4); diag(12 - 3, 0, 5, 6, 4); rect(4, 6, 8, 13)
        elif ch == 'R':
            rect(0, 0, 3, 13); rect(0, 0, 10, 3); rect(0, 6, 10, 8); rect(9, 1, 12, 7)
            g[0][11] = 1; g[0][12] = 0; g[8][12] = 0; g[0][12] = 0
            diag(6, 8, 10, 13, 3)
        elif ch == 'O':
            rect(0, 1, 3, 12); rect(9, 1, 12, 12); rect(1, 0, 11, 3); rect(1, 10, 11, 13)
        elif ch == 'N':
            rect(0, 0, 3, 13); rect(9, 0, 12, 13); diag(3, 0, 8, 13, 3)
        return g
    word = "ZYRON"
    WT = 80; HT = 14
    bm = [[0] * WT for _ in range(HT)]
    x = 2
    for ch in word:
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
LOGOROW = 1

# ------------------------------------------------ tables
L = []
L.append("; generated tables")
rows = [i * 40 for i in range(25)]
L += bytes_lines("rowlo", [r & 255 for r in rows])
L += bytes_lines("rowhiA", [(0x4800 + r) >> 8 for r in rows])
L += bytes_lines("rowhiB", [(0x4c00 + r) >> 8 for r in rows])
L += bytes_lines("rowhiC", [(0xd800 + r) >> 8 for r in rows])
charcol = [1] * 256
charcol[32] = 0
for i in range(8): charcol[gfx.LAY_F + i] = gfx.F_COLS[i]
for i in range(8): charcol[gfx.LAY_M + i] = gfx.M_COLS[i]
for i in range(8): charcol[gfx.LAY_H + i] = 6
for i in range(4): charcol[gfx.CH_FILL + i] = 6
for i in range(32):
    charcol[128 + i] = tcols[i]
L += bytes_lines("charcol", charcol)
def bgchar(rp, k):
    if rp is None: return 32
    l, ph = rp
    if l == 3: return gfx.CH_FILL + ph
    return gfx.LAY_BASE[l] + (k + ph) % gfx.LAY_W[l]
for k in range(8):
    L += bytes_lines("bgcol%d" % k, [bgchar(rp, k) for rp in gfx.ROWPAT])
L.append("bgofs_lo .byte " + ",".join("<bgcol%d" % k for k in range(8)))
L.append("bgofs_hi .byte " + ",".join(">bgcol%d" % k for k in range(8)))
L.append("lay_base .byte %s" % ",".join(str(b) for b in gfx.LAY_BASE))
L.append("lay_wm .byte %s" % ",".join(str(w - 1) for w in gfx.LAY_W))
L.append("lay_pm .byte %s" % ",".join(str(w * 8 - 1) for w in gfx.LAY_W))
L.append("lay_half .byte %s" % ",".join(str(w * 4) for w in gfx.LAY_W))
L.append("lev_hcol .byte 6,4,6,2,4,6")
L += bytes_lines("pat_speed", gfx.PAT_SPEED)
L += bytes_lines("pat_color", gfx.PAT_COLOR)
trow = [1, 255, 255, 255, 255, 255, 255, 255, 0, 255, 1, 0, 0, 255, 0, 255, 1, 0, 255, 1, 255, 255, 0, 255, 0]
trow = [p if p != 255 else 0xff for p in trow]
for r in range(LOGOROW, LOGOROW + LOGOROWS): trow[r] = 0xff
trow[0] = 0; trow[8] = 1
L += bytes_lines("trowpat", trow)
L.append("terr_ofs .word " + ",".join("terr_sets+%d" % (i * 256) for i in range(6)))
L += bytes_lines("terr_sets", tsets)
L += bytes_lines("terr_cols", tcols)
L += bytes_lines("lev_d022", [lv[1] for lv in gfx.LEVELS])
L += bytes_lines("lev_d023", [lv[2] for lv in gfx.LEVELS])
L.append("lvname_tab .word " + ",".join("lvname%d" % i for i in range(6)))
for i, lv in enumerate(gfx.LEVELS):
    L.append('lvname%d .null "%s"' % (i, lv[5]))
L += bytes_lines("logo_chars", logo)
L += bytes_lines("logo_grad", [6, 6, 4, 4, 2, 2, 7, 7, 1, 1, 7, 7, 2, 2, 4, 4])
sint = [int(round(48 * math.sin(i * 2 * math.pi / 256))) & 255 for i in range(256)]
L += bytes_lines("sintab", sint)
at = []
for y in range(16):
    for x in range(16):
        if x == 0 and y == 0: at.append(0)
        else: at.append(min(16, int(round(math.atan2(y, x) / (math.pi / 2) * 16))))
L += bytes_lines("atan16", at)
SPEEDS = [1.25, 1.6, 2.0, 2.4]
vxl, vxh, vyl, vyh = [], [], [], []
for s in SPEEDS:
    for a in range(64):
        vx = int(round(math.cos(a * 2 * math.pi / 64) * s * 256)) & 0xffff
        vy = int(round(math.sin(a * 2 * math.pi / 64) * s * 256)) & 0xffff
        vxl.append(vx & 255); vxh.append(vx >> 8); vyl.append(vy & 255); vyh.append(vy >> 8)
L += bytes_lines("ebv_xl", vxl)
L += bytes_lines("ebv_xh", vxh)
L += bytes_lines("ebv_yl", vyl)
L += bytes_lines("ebv_yh", vyh)
fl, fh = [], []
for n in range(96):
    f = 440.0 * 2 ** ((n - 57) / 12.0)
    r = min(65535, int(round(f * 16777216 / 985248)))
    fl.append(r & 255); fh.append(r >> 8)
L += bytes_lines("freq_lo", fl)
L += bytes_lines("freq_hi", fh)
open(os.path.join(OUT, 'gen_data.asm'), 'w').write("\n".join(L) + "\n")

# ------------------------------------------------ constants
C = ["; generated constants"]
for k, v in syms.items():
    C.append("SPR_%s = $%02x" % (k.upper(), v))
for k in ['CH_QUAD', 'CH_BG', 'CH_BAR', 'CH_BARL', 'CH_BARR', 'CH_SHIP', 'CH_LINE', 'CH_TERR', 'LAY_F', 'LAY_M', 'LAY_H', 'CH_FILL']:
    C.append("%s = %d" % (k, getattr(gfx, k)))
C.append("LOGOROW = %d" % LOGOROW)
C.append("LOGOROWS = %d" % LOGOROWS)
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(C) + "\n")

# ------------------------------------------------ levels & music
open(os.path.join(OUT, 'levels.asm'), 'w').write(levels.level_asm())
masm, mbytes, npat = music.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm)
print("sprites:", len(sprdata) // 64, "music patterns:", npat, "bytes:", mbytes)
