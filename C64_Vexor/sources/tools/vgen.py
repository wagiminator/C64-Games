# VEXOR - build all generated data
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import vgfx, vlevels, vmusic, music

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

def bl(label, data, per=16):
    out = [label]
    for i in range(0, len(data), per):
        out.append("  .byte " + ",".join("$%02x" % (b & 255) for b in data[i:i + per]))
    return out

cs = vgfx.build_base_charset()
tsets, tcols = vgfx.terrain_sets()
cs[128 * 8:160 * 8] = tsets[0:256]
open(os.path.join(OUT, 'charset.bin'), 'wb').write(bytes(cs))
spr, syms = vgfx.build_sprites()
assert len(spr) <= 0x3000 - 64
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(spr))
vgfx.render_preview(os.path.join(OUT, 'preview.png'), spr, tsets, tcols)

# ---------------- logo "VEXOR"
def logo_bitmap():
    W, H = 13, 14
    def glyph(ch):
        g = [[0] * W for _ in range(H)]
        def rect(x0, y0, x1, y1):
            for y in range(max(0, y0), min(H, y1 + 1)):
                for x in range(max(0, x0), min(W, x1 + 1)): g[y][x] = 1
        def diag(x0, y0, x1, y1, t):
            for i in range(61):
                xx = x0 + (x1 - x0) * i / 60; yy = y0 + (y1 - y0) * i / 60
                for dx in range(t):
                    xi = int(round(xx)) + dx; yi = int(round(yy))
                    if 0 <= xi < W and 0 <= yi < H: g[yi][xi] = 1
        if ch == 'V':
            diag(0, 0, 4, 13, 4); diag(9, 0, 5, 13, 4)
        elif ch == 'E':
            rect(0, 0, 3, 13); rect(0, 0, 12, 3); rect(0, 6, 9, 8); rect(0, 10, 12, 13)
        elif ch == 'X':
            diag(0, 0, 9, 13, 4); diag(9, 0, 0, 13, 4)
        elif ch == 'O':
            rect(0, 1, 3, 12); rect(9, 1, 12, 12); rect(1, 0, 11, 3); rect(1, 10, 11, 13)
        elif ch == 'R':
            rect(0, 0, 3, 13); rect(0, 0, 10, 3); rect(0, 6, 10, 8); rect(9, 1, 12, 7)
            g[0][12] = 0; g[8][12] = 0; diag(6, 8, 10, 13, 3)
        return g
    WT, HT = 80, 14
    bm = [[0] * WT for _ in range(HT)]
    x = 2
    for ch in "VEXOR":
        g = glyph(ch)
        for y in range(H):
            sh = (H - 1 - y) // 4
            for xx in range(W):
                if g[y][xx] and 0 <= x + xx + sh < WT: bm[y][x + xx + sh] = 1
        x += W + 2
    return bm
bm = logo_bitmap(); LOGOROWS = 7; LOGOROW = 1
logo = []
for r in range(LOGOROWS):
    for c in range(40):
        q = (1 if bm[r*2][c*2] else 0) | (2 if bm[r*2][c*2+1] else 0) | (4 if bm[r*2+1][c*2] else 0) | (8 if bm[r*2+1][c*2+1] else 0)
        logo.append(vgfx.CH_QUAD + q if q else 32)
logo += [32] * (400 - len(logo))

L = ["; generated tables"]
rows = [i * 40 for i in range(25)]
L += bl("rowlo", [r & 255 for r in rows])
L += bl("rowhiA", [(0x4800 + r) >> 8 for r in rows])
L += bl("rowhiB", [(0x4c00 + r) >> 8 for r in rows])
L += bl("rowhiC", [(0xd800 + r) >> 8 for r in rows])
charcol = [1] * 256; charcol[32] = 0
for i in range(8):
    charcol[vgfx.LAY_F + i] = vgfx.F_COLS[i]; charcol[vgfx.LAY_M + i] = vgfx.M_COLS[i]
for i in range(8): charcol[vgfx.LAY_A + i] = vgfx.N_COLS[i]
for i in range(32): charcol[128 + i] = tcols[i]
L += bl("charcol", charcol)
def bgc(cp, t):
    if cp is None: return 32
    l, ph = cp
    return vgfx.LAY_COLBASE[l] + ((ph - t) & 7)
for t in range(8):
    L += bl("bgrow%d" % t, [bgc(cp, t) for cp in vgfx.COLPAT])
L.append("bgofs_lo .byte " + ",".join("<bgrow%d" % t for t in range(8)))
L.append("bgofs_hi .byte " + ",".join(">bgrow%d" % t for t in range(8)))
L += bl("tcolbase", [0 if cp is None else vgfx.LAY_COLBASE[cp[0]] for cp in vgfx.COLPAT])
L += bl("tcolph", [0 if cp is None else cp[1] for cp in vgfx.COLPAT])
_s, ents = vgfx.make_layers()
offs = []; cols = []; vals = []; firsts = []
for e in ents:
    firsts.append(len(offs))
    for (y, c, v) in e:
        offs.append(y); cols.append(c * 64); vals.append(v)
firsts.append(len(offs))
L += bl("e_off", offs); L += bl("e_col", cols); L += bl("e_val", vals)
for i, f in enumerate(firsts): L.append("E%d_FIRST = %d" % (i, f))
L += bl("pat_speed", vgfx.PAT_SPEED)
L += bl("pat_color", vgfx.PAT_COLOR)
# per screen row star pattern for menus: use column patterns (vertical stars) -> table per column

L.append("terr_ofs .word " + ",".join("terr_sets+%d" % (i * 256) for i in range(5)))
L += bl("terr_sets", tsets)
L += bl("terr_cols", tcols)
L += bl("lev_d022", [lv[1] for lv in vgfx.LEVELS])
L += bl("lev_d023", [lv[2] for lv in vgfx.LEVELS])
L.append("lvname_tab .word " + ",".join("lvname%d" % i for i in range(5)))
for i, lv in enumerate(vgfx.LEVELS):
    L.append('lvname%d .null "%s"' % (i, lv[5]))
L += bl("logo_chars", logo)
L += bl("logo_grad", [6, 6, 4, 4, 2, 2, 7, 7, 1, 1, 7, 7, 2, 2, 4, 4])
L += bl("sintab", [int(round(48 * math.sin(i * 2 * math.pi / 256))) & 255 for i in range(256)])
at = []
for y in range(16):
    for x in range(16):
        at.append(0 if x == 0 and y == 0 else min(16, int(round(math.atan2(y, x) / (math.pi / 2) * 16))))
L += bl("atan16", at)
vxl, vxh, vyl, vyh = [], [], [], []
for s in [1.25, 1.6, 2.0, 2.4]:
    for a in range(64):
        vx = int(round(math.cos(a * 2 * math.pi / 64) * s * 256)) & 0xffff
        vy = int(round(math.sin(a * 2 * math.pi / 64) * s * 256)) & 0xffff
        vxl.append(vx & 255); vxh.append(vx >> 8); vyl.append(vy & 255); vyh.append(vy >> 8)
L += bl("ebv_xl", vxl); L += bl("ebv_xh", vxh); L += bl("ebv_yl", vyl); L += bl("ebv_yh", vyh)
fl, fh = [], []
for n in range(96):
    r = min(65535, int(round(440.0 * 2 ** ((n - 57) / 12.0) * 16777216 / 985248)))
    fl.append(r & 255); fh.append(r >> 8)
L += bl("freq_lo", fl); L += bl("freq_hi", fh)
open(os.path.join(OUT, 'gen_data.asm'), 'w').write("\n".join(L) + "\n")

C = ["; generated constants"]
for k, v in syms.items(): C.append("SPR_%s = $%02x" % (k.upper(), v))
for k in ['CH_QUAD', 'CH_BG', 'CH_BAR', 'CH_BARL', 'CH_BARR', 'CH_SHIP', 'CH_CUR', 'CH_TERR', 'LAY_F', 'LAY_M', 'LAY_A']:
    C.append("%s = %d" % (k, getattr(vgfx, k)))
C.append("LOGOROW = %d" % LOGOROW); C.append("LOGOROWS = %d" % LOGOROWS)
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(C) + "\n")
open(os.path.join(OUT, 'levels.asm'), 'w').write(vlevels.level_asm())
masm, mb, npat = vmusic.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm)
print("sprites", len(spr) // 64, "music", npat, mb)
