# FLEETFOOT - build all generated data
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import gfx, fgfx as F, fgeo as G, fground, fmusic, flevels

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

CS1, CS2, SCR, SPRBASE = 0x4000, 0x4800, 0x5000, 0x5400
SPEED = 0xE000           # generated stripe code (RAM under the KERNAL)

def bl(label, data, per=16):
    out = [label]
    data = list(data)
    for i in range(0, len(data), per):
        out.append("  .byte " + ",".join("$%02x" % (b & 255) for b in data[i:i + per]))
    if not data: out.append("  .byte 0")
    return out

# ------------------------------------------------ charset 1: font, logo quads, HUD icons
cs1 = bytearray(2048)
for ch, rows in gfx.FONT.items():
    code = gfx.screencode(ch)
    cs1[code * 8:code * 8 + 8] = bytes(gfx.glyph_bytes(rows))
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
    cs1[(CH_QUAD + q) * 8:(CH_QUAD + q) * 8 + 8] = d
CONST = {}
icon_at = 240
for k, rows in F.ICONS.items():
    b = bytes(int(r.replace('#', '1').replace('.', '0'), 2) for r in rows)
    cs1[icon_at * 8:icon_at * 8 + 8] = b
    CONST['CH_' + k] = icon_at
    icon_at += 1
SCEN_MAX = 240 - 80        # scenery chars 80..239
open(os.path.join(OUT, 'charset1.bin'), 'wb').write(bytes(cs1))

# ------------------------------------------------ charset 2: ground
chars, scr, softinfo, animated = fground.build()
assert len(chars) <= 256
cs2 = bytearray(2048)
for i, (p, s) in enumerate(chars):
    cs2[i * 8:i * 8 + 8] = p
open(os.path.join(OUT, 'charset2.bin'), 'wb').write(bytes(cs2))
print("ground chars:", len(chars))
# stripe versions for the runtime code generator, and the per row char ranges
# rows 9..24: range of chars to examine (soft range, then the non-soft range)
rng = {}
for c, soft, r in animated:
    a, b = rng.get((r, soft), (999, -1))
    rng[(r, soft)] = (min(a, c), max(b, c))
# non-soft chars of a row: the full allocation range of that row (static ones are skipped automatically)
first_ns = {}
for r in range(G.ROW0, 25):
    ids = [scr[r][cx] for cx in range(40) if not (r in softinfo and softinfo[r][0] <= cx <= softinfo[r][1])]
    first_ns[r] = (min(ids), max(ids))
sc_s0, sc_s1, sc_n0, sc_n1 = [], [], [], []
for r in range(G.ROW0, 25):
    if r in softinfo:
        c0, c1, base = softinfo[r]
        sc_s0.append(base); sc_s1.append(base + c1 - c0 + 1)
    else:
        sc_s0.append(0); sc_s1.append(0)
    a, b = first_ns[r]
    sc_n0.append(a); sc_n1.append(b + 1)
# the non-soft ranges of different rows may overlap (shared chars): mark each char once (the row where it was allocated)
owner = {}
for c, soft, r in animated:
    owner[c] = r
stripe = bytearray()
for i in range(len(chars)):
    stripe += chars[i][1]

# ------------------------------------------------ sprites
spr = bytearray()
SYM = {}
def sadd(name, s):
    SYM[name] = (SPRBASE - 0x4000) // 64 + len(spr) // 64
    spr.extend(s.tobytes() if hasattr(s, 'tobytes') else s)
blank = F.Spr()
sadd('BLANK', blank)
rf = F.runner_frames()
for k in ('RUN0', 'RUN1', 'RUN2', 'RUN3', 'JUMP', 'SLIDE', 'FALL'):
    t, b = rf[k]
    sadd(k + 'T', t); sadd(k + 'B', b)
near = F.near_sprites()
NCLS = len(F.NEAR_DX)
for kind in ('BARR', 'BAR', 'BLK'):
    for c in range(NCLS):
        sadd('%s%d' % (kind, c), near['%s%d' % (kind, c)])
for ph in range(2):
    for c in range(NCLS):
        sadd('COIN%d_%d' % (c, ph), near['COIN%d_%d' % (c, ph)])
for k in range(4):
    for c in range(NCLS):
        sadd('PWR%d_%d' % (k, c), near['PWR%d_%d' % (k, c)])
for ph in range(3):
    l, r, lb, rb = F.boulder(ph * 2.0 / 3)
    sadd('BOUL%dL' % ph, l); sadd('BOUL%dR' % ph, r)
    sadd('BOUL%dLB' % ph, lb); sadd('BOUL%dRB' % ph, rb)
for ph in range(2):
    sadd('BALL%d' % ph, F.ball(ph * 1.0))
assert SPRBASE + len(spr) <= 0x8000
print("sprites:", len(spr) // 64)
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(spr))

# ------------------------------------------------ projection tables
def yb_of(z):
    if z <= 0: return 255
    y = G.HY + G.KZ / z
    return min(255, int(round(y)))
ytab_n = [yb_of(z) for z in range(256)]
ytab_f = [yb_of((i + 64) * 4 + 2) for i in range(256)]       # z = 256..1279
nofs, ncls, fofs, fcls, hstep = [], [], [], [], []
for yb in range(256):
    d = G.dxof(yb) if yb > G.HY else 0
    nofs.append(min(255, int(round(d))))
    c = 0
    while c < NCLS - 1 and d >= F.NEAR_LIM[c]:
        c += 1
    ncls.append(c)
    fofs.append(min(255, int(round(d / 2))))
    fcls.append(min(15, max(0, (yb - G.HY) // 5)))
    hstep.append(min(255, int(round(d / 4))))
# far rectangles per kind and class
far = []
far_lo, far_hi = [], []
FARDATA = 0           # offsets filled below
farblocks = []
for k, kind in enumerate(F.FAR_ORDER):
    for c in range(16):
        yb = G.HY + c * 5 + 3
        rects = F.far_rects(kind, yb)
        if c < 3:
            # tiny: one bright rectangle
            x0 = min(r[0] for r in rects); x1 = max(r[1] for r in rects)
            h0 = min(r[2] for r in rects); h1 = max(r[3] for r in rects)
            rects = [(x0, x1, h0, h1, rects[0][4])]
        blk = [len(rects)]
        for x0, x1, h0, h1, col in rects:
            blk += [x0 & 255, x1 & 255, h0, h1, [0x00, 0x55, 0xaa, 0xff][col]]
        farblocks.append(blk)
# soft line tables (y 72..151)
la_lo, la_hi, lx0, lx1 = [], [], [], []
for y in range(G.HY, G.NEAR_Y):
    r = y // 8
    c0, c1, base = softinfo[r]
    a = CS2 + (base - c0) * 8 + (y & 7)
    la_lo.append(a & 255); la_hi.append((a >> 8) & 255)
    lx0.append(c0 * 4); lx1.append(c1 * 4 + 3)
zline = [int(G.zof(y)) & 255 for y in range(G.HY, 200)]

# ------------------------------------------------ scenery
scen = []
for z in range(5):
    img = F.scenery(z)
    ch, m = F.scenery_chars(img)
    assert len(ch) <= SCEN_MAX, (z, len(ch))
    scen.append((ch, m))
    print("zone %d scenery chars: %d" % (z, len(ch)))

# ------------------------------------------------ logo
bm = F.logo_bitmap()
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

# ------------------------------------------------ write tables
L = ["; generated data"]
rows = [i * 40 for i in range(25)]
L += bl("rowlo", [r & 255 for r in rows])
L += bl("rowhi", [(SCR + r) >> 8 for r in rows])
L += bl("rowhiC", [(0xd800 + r) >> 8 for r in rows])
L += bl("logo_chars", logo)
L += bl("logo_grad", [9, 9, 8, 8, 7, 7, 1, 1, 7, 7, 8, 8, 9, 9, 2, 2])
fl, fh = [], []
for n in range(96):
    f = 440.0 * 2 ** ((n - 57) / 12.0)
    r = min(65535, int(round(f * 16777216 / 985248)))
    fl.append(r & 255); fh.append(r >> 8)
L += bl("freq_lo", fl)
L += bl("freq_hi", fh)
L += bl("bittab", [1, 2, 4, 8, 16, 32, 64, 128])
L += bl("nbittab", [255 ^ (1 << i) for i in range(8)])
L += bl("ytab_n", ytab_n)
L += bl("ytab_f", ytab_f)
L += bl("nofs", nofs)
L += bl("ncls", ncls)
L += bl("fofs", fofs)
L += bl("fcls", fcls)
L += bl("hstep", hstep)
# far rect blocks
L.append("far_lo")
L.append("  .byte " + ",".join("<far%d" % i for i in range(len(farblocks))))
L.append("far_hi")
L.append("  .byte " + ",".join(">far%d" % i for i in range(len(farblocks))))
for i, b in enumerate(farblocks):
    L += bl("far%d" % i, b)
L += bl("la_lo", la_lo)
L += bl("la_hi", la_hi)
L += bl("lx0", lx0)
L += bl("lx1", lx1)
L += bl("col8_lo", [(c * 8) & 255 for c in range(40)])
L += bl("col8_hi", [(c * 8) >> 8 for c in range(40)])
L += bl("zline", zline)
L += bl("lmask_x", [[0xff, 0x3f, 0x0f, 0x03][x & 3] for x in range(160)])
L += bl("rmask_x", [[0xc0, 0xf0, 0xfc, 0xff][x & 3] for x in range(160)])
gm = []
for r in range(G.ROW0, 25):
    gm += scr[r]
L += bl("ground_map", gm)
L += bl("sc_s0", sc_s0); L += bl("sc_s1", sc_s1); L += bl("sc_n0", sc_n0); L += bl("sc_n1", sc_n1)
L += bl("sc_owner", [owner.get(c, 0) for c in range(256)])
L += bl("stripe_data", stripe)
for z, (ch, m) in enumerate(scen):
    data = b''.join(ch)
    L += bl("scen%d_chars" % z, data)
    flat = []
    for row in m:
        flat += [80 + v for v in row]
    L += bl("scen%d_map" % z, flat)
L.append("scen_n  .byte " + ",".join(str(len(c)) for c, m in scen))
L.append("scen_clo .byte " + ",".join("<scen%d_chars" % z for z in range(5)))
L.append("scen_chi .byte " + ",".join(">scen%d_chars" % z for z in range(5)))
L.append("scen_mlo .byte " + ",".join("<scen%d_map" % z for z in range(5)))
L.append("scen_mhi .byte " + ",".join(">scen%d_map" % z for z in range(5)))
L.append("sky_bg .byte %s" % ",".join(str(zz[1][0]) for zz in F.ZONES))
L.append("sky_cr .byte %s" % ",".join(str(zz[1][3]) for zz in F.ZONES))
for i, nm in enumerate(('gnd_bg', 'gnd_22', 'gnd_23', 'gnd_cr')):
    L.append("%s .byte %s" % (nm, ",".join(str(zz[2][i]) for zz in F.ZONES)))
open(os.path.join(OUT, 'gen_data.asm'), 'w').write("\n".join(L) + "\n")

K = ["; generated constants"]
for k, v in SYM.items():
    K.append("SPR_%s = $%02x" % (k, v))
for k, v in CONST.items():
    K.append("%s = %d" % (k, v))
K.append("CH_QUAD = %d" % CH_QUAD)
K.append("LOGOROWS = %d" % LOGOROWS)
K.append("NGCHARS = %d" % len(chars))
K.append("HY = %d" % G.HY)
K.append("NEAR_Y = %d" % G.NEAR_Y)
K.append("STRIPE_TOP = %d" % G.STRIPE_TOP)
K.append("STRIPE_D = %d" % G.STRIPE_D)
K.append("STRIPE_P = %d" % G.STRIPE_P)
K.append("ZRUN = %d" % G.ZRUN)
K.append("NFARK = %d" % len(F.FAR_ORDER))
K.append("NCLS = %d" % NCLS)
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(K) + "\n")

masm, mbytes, npat = fmusic.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm)
print("music: %d patterns, %d bytes" % (npat, mbytes))
open(os.path.join(OUT, 'patterns.asm'), 'w').write(flevels.asm())
