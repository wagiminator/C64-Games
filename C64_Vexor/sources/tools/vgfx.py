# VEXOR - graphics generator (charset, terrain, sprites, bosses, trader)
import math, random
from gfx import FONT, screencode, glyph_bytes, Spr, big_slices, mc_char_bytes

CH_QUAD = 64
CH_BG = 80          # parallax strips (1 char wide, 8 tall): far 80-87, mid 88-95, near 96-103
LAY_F = 80
LAY_M = 88
LAY_A = 96
CH_BAR = 112
CH_BARL = 117
CH_BARR = 118
CH_SHIP = 119
CH_CUR = 120        # shop cursor arrow
CH_TERR = 128

NPAT = 3
PAT_SPEED = [64, 104, 168]
PAT_COLOR = [6, 3, 4]
F_COLS = [6, 6, 4, 6, 6, 4, 6, 6]
M_COLS = [1, 3, 7, 3, 1, 7, 3, 3]
N_COLS = [1, 7, 1, 15, 1, 13, 1, 7]
# per screen column: (layer, phase); layer 0 far, 1 mid, 2 near stars; None = empty
COLPAT = [(0, 0), (1, 3), None, (0, 5), (2, 2), None, (0, 1), None, (1, 6), (0, 3), None, (0, 7),
          (1, 1), (2, 6), (0, 4), (1, 5), (0, 2), None, (0, 2), (1, 4), (0, 6), (2, 3), (0, 0), (1, 2),
          None, None, (2, 0), (0, 5), None, (1, 7), (0, 3), None, (0, 1), (1, 5), (0, 7), (2, 5),
          (0, 6), None, (1, 0), (0, 4)]
LAY_COLBASE = [LAY_F, LAY_M, LAY_A]

def make_layers(seed=21):
    """-> (strip bytes dict, entries list per layer); entries = (line, col, value)"""
    rnd = random.Random(seed)
    def stars(n, bright):
        ent = []; used = set()
        for i in range(n):
            for _ in range(200):
                y = rnd.randrange(64); x = rnd.randrange(1, 7)
                if all(abs(y - u) > 3 for u in used): break
            used.add(y)
            if bright and i == 0:
                ent += [((y - 1) % 64, 0, 0x80 >> x), (y, 0, (0xe0 >> (x - 1)) & 0xff), ((y + 1) % 64, 0, 0x80 >> x)]
            elif bright and i == 2:
                ent += [(y, 0, (0xc0 >> x) & 0xff)]
            else:
                ent += [(y, 0, 0x80 >> x)]
        return ent
    def rocks():
        ent = []
        for (y0, w, h, sd) in ((20, 13, 11, 3),):
            rr = random.Random(sd)
            cx = 8; cy = h / 2
            rad = [rr.uniform(0.75, 1.0) for _ in range(12)]
            for yy in range(h):
                for half in range(2):
                    v = 0
                    for b in range(8):
                        x = half * 8 + b
                        dx = (x + .5 - cx) / (w / 2); dy = (yy + .5 - cy) / (h / 2)
                        a = math.atan2(dy, dx); k = int((a + math.pi) / (2 * math.pi) * 12) % 12
                        d = math.hypot(dx, dy)
                        if d <= rad[k]:
                            # shading: lit upper-left rim solid, crater dots and dark lower right dithered
                            if dx + dy > 0.6 and (x + yy) % 2: continue
                            if (x, yy) in ((6, 3), (7, 3), (9, 6), (5, 7)): continue
                            v |= 0x80 >> b
                    if v: ent.append(((y0 + yy) % 64, half, v))
        return ent
    def near(n):
        # bright near stars, drawn 2 lines tall (motion streak)
        ent = []; used = set()
        for i in range(n):
            for _ in range(200):
                y = rnd.randrange(64); x = rnd.randrange(1, 7)
                if all(min(abs(y - u), 64 - abs(y - u)) > 9 for u in used): break
            used.add(y)
            ent += [(y, 0, 0x80 >> x), ((y + 1) % 64, 0, 0x80 >> x)]
            if i == 1:
                ent += [((y + 2) % 64, 0, 0x80 >> x)]
        return ent
    ents = [stars(6, False), stars(5, True), near(4)]
    strips = {}
    for l, e in enumerate(ents):
        cols = 1
        data = bytearray(64 * cols)
        for (y, c, v) in e: data[c * 64 + y] |= v
        strips[l] = data
    return strips, ents

def make_patterns(seed=9):
    rnd = random.Random(seed)
    pats = []
    for p in range(NPAT):
        bm = [[0] * 8 for _ in range(16)]
        n = 2 if p < 2 else 1
        used = []
        for s in range(n):
            for _ in range(50):
                x = rnd.randrange(1, 7); y = rnd.randrange(16)
                if all(abs(y - b) > 5 for a, b in used): break
            used.append((x, y))
            bm[y][x] = 1
            if p >= 2:
                bm[(y + 1) % 16][x] = 1      # near stars: streak (moving)
            if p == 3:
                bm[(y + 2) % 16][x] = 1
        pats.append(bm)
    return pats

def build_base_charset():
    cs = bytearray(2048)
    for ch, rows in FONT.items():
        sc = screencode(ch)
        cs[sc * 8: sc * 8 + 8] = bytes(glyph_bytes(rows))
    # '$' glyph at '#' slot? keep '#', add '$' (36)
    cs[36 * 8:36 * 8 + 8] = bytes(glyph_bytes(["  XX    ", " XXXXX  ", "XX      ", " XXXX   ", "    XX  ", "XXXXX   ", "  XX    "]))
    for q in range(16):
        for y in range(8):
            b = 0
            if y < 4:
                if q & 1: b |= 0xF0
                if q & 2: b |= 0x0F
            else:
                if q & 4: b |= 0xF0
                if q & 8: b |= 0x0F
            cs[(CH_QUAD + q) * 8 + y] = b
    strips, ents = make_layers()
    cs[LAY_F * 8:LAY_F * 8 + 64] = strips[0]
    cs[LAY_M * 8:LAY_M * 8 + 64] = strips[1]
    cs[LAY_A * 8:LAY_A * 8 + 64] = strips[2]
    for n in range(5):
        for y in range(8):
            if y in (0, 7): b = 0xFF
            elif y in (1, 6): b = 0
            else: b = (0xFF << (8 - n * 2)) & 0xFF
            cs[(CH_BAR + n) * 8 + y] = b
    cs[CH_BARL * 8:CH_BARL * 8 + 8] = bytes([0x07, 0x08, 0x10, 0x10, 0x10, 0x10, 0x08, 0x07])
    cs[CH_BARR * 8:CH_BARR * 8 + 8] = bytes([0xE0, 0x10, 0x08, 0x08, 0x08, 0x08, 0x10, 0xE0])
    cs[CH_SHIP * 8:CH_SHIP * 8 + 8] = bytes([0x18, 0x18, 0x3C, 0x7E, 0xFF, 0xDB, 0x18, 0x00])
    cs[CH_CUR * 8:CH_CUR * 8 + 8] = bytes([0x40, 0x60, 0x70, 0x78, 0x70, 0x60, 0x40, 0x00])
    return cs

# ---------------------------------------------------------------- terrain
# relative char indices (+128):
#  0,1 left edge (variants) 2,3 left sub 4..7 left deep 8 left-up slope 9 left-down slope
#  10..19 right wall (mirrors)   20..28 island TL T TR L F R BL B BR
def wall_tex(style, rnd):
    """f(x,y): x = MC px into the wall from its edge (0..15), y 0..15 -> 0..3"""
    if style == 'bio':
        def f(x, y):
            v = math.sin(x * 0.8 + y * 0.5) + math.sin(y * 0.9 - x * 0.4) * 0.7
            if abs(v) < 0.22: return 3
            return 2 if v > 0.3 else 1
    elif style == 'crystal':
        def f(x, y):
            a = (x * 2 + y) % 10; b = (y - x * 2) % 10
            if a == 0 or b == 0: return 3
            return 2 if a < 5 else 1
    elif style == 'mech':
        def f(x, y):
            yy = y % 8
            if yy == 0: return 3 if x % 4 == 0 else 1
            if x % 8 == 7: return 0
            if yy == 4 and x % 4 == 2: return 3
            return 2 if (x // 4 + y // 8) % 2 else 1
    elif style == 'lava':
        pts = [(rnd.uniform(0, 16), rnd.uniform(0, 16)) for _ in range(6)]
        def f(x, y):
            ds = sorted(math.hypot((x - px - ox) * 2, y - py - oy) for px, py in pts for ox in (-16, 0, 16) for oy in (-16, 0, 16))
            if ds[1] - ds[0] < 1.4: return 3
            return 1 if ds[0] > 3.5 else 2
    else:  # hive
        def f(x, y):
            best = sorted(math.hypot(x * 2 - (cx * 8 + (4 if cy % 2 else 0)), (y - cy * 7) * 1.1)
                          for cx in range(-1, 4) for cy in range(-1, 4))
            if best[1] - best[0] < 1.2: return 1
            return 3 if best[0] < 2 else 2
    return f

def make_terrain(style, seed):
    rnd = random.Random(seed)
    f = wall_tex(style, rnd)
    def cut(x0, y0, edge=False):
        c = [[f(x0 + x, y0 + y) for x in range(4)] for y in range(8)]
        if edge:
            for y in range(8):
                c[y][0] = 3; c[y][1] = 2 if c[y][1] != 3 else 3
        return c
    ch = {}
    # right-wall orientation (edge at left x=0)
    R = {}
    R[0] = cut(0, 0, True); R[1] = cut(0, 8, True)
    R[2] = cut(4, 0); R[3] = cut(4, 8)
    R[4] = cut(8, 0); R[5] = cut(12, 0); R[6] = cut(8, 8); R[7] = cut(12, 8)
    sub = cut(4, 0)
    # slopes for right wall: up = solid lower-right? define in left terms and mirror
    def hflip(c): return [row[::-1] for row in c]
    L = {k: hflip(v) for k, v in R.items()}
    # left wall slopes: 8 = upper-left solid triangle, 9 = lower-left solid triangle
    lu = [[0] * 4 for _ in range(8)]; ld = [[0] * 4 for _ in range(8)]
    for y in range(8):
        for x in range(4):
            hx = x * 2 + 1
            e = (7 - y) - hx          # upper-left: solid where hx <= 7-y
            if e >= 0: lu[y][x] = 3 if e < 2 else (2 if e < 3 else sub[y][x])
            e2 = y - hx               # lower-left: solid where hx <= y
            if e2 >= 0: ld[y][x] = 3 if e2 < 2 else (2 if e2 < 3 else sub[y][x])
    L[8] = lu; L[9] = ld
    for k in range(10):
        ch[k] = L[k]
    ch[10] = R[0]; ch[11] = R[1]
    for k in range(2, 8): ch[10 + k] = R[k]
    ch[18] = hflip(lu); ch[19] = hflip(ld)
    # island 3x3 tiles
    fill = [[f(16 - 1 - x, y) for x in range(4)] for y in range(8)]
    def isl(top, bot, left, right):
        c = [r[:] for r in fill]
        for y in range(8):
            for x in range(4):
                if (top and y < 2) or (bot and y > 5) or (left and x < 1) or (right and x > 2):
                    c[y][x] = 3 if (top and y == 0) or (left and x == 0) else 1
        # round corners
        if top and left: c[0][0] = 0
        if top and right: c[0][3] = 0
        if bot and left: c[7][0] = 0
        if bot and right: c[7][3] = 0
        return c
    k = 20
    for t, b in ((1, 0), (0, 0), (0, 1)):
        for l, r in ((1, 0), (0, 0), (0, 1)):
            ch[k] = isl(t, b, l, r); k += 1
    return ch

# style, d022, d023, edge%11, deep%11, name
LEVELS = [
    ('bio', 9, 5, 7, 0, "BIO CAVERNS"),
    ('crystal', 6, 14, 1, 3, "CRYSTAL REEF"),
    ('mech', 11, 12, 1, 6, "MECHA DOCKS"),
    ('lava', 2, 8, 7, 0, "LAVA CORE"),
    ('hive', 4, 10, 1, 5, "ALIEN HIVE"),
]

def terrain_sets():
    data = bytearray(); colors = bytearray()
    for li, (style, d22, d23, ce, cd, name) in enumerate(LEVELS):
        ch = make_terrain(style, 300 + li)
        for i in range(32):
            data += bytes(mc_char_bytes(ch[i])) if i in ch else bytes(8)
        for i in range(32):
            if i in (0, 1, 8, 9, 10, 11, 18, 19) or 20 <= i <= 28 and i != 24: colors.append(8 + ce)
            else: colors.append(8 + cd)
    return data, colors

# ---------------------------------------------------------------- sprites
SHIP = [
"....3.......",
"....3.......",
"...323......",
"...222......",
"..12221.....",
"..12321.....",
".1223221....",
"11222221.1..",
"122212221...",
"2221.1222...",
"221...122...",
"21.....12...",
"1.......1...",
]

def shifted(rows, dx):
    out = []
    for r in rows:
        r = ('.' * dx + r)[:12]
        out.append(r + '.' * (12 - len(r)))
    return out

def mirror_ship():
    # build symmetric ship from left half description (6 px wide)
    half = [
        "....33",
        "....32",
        "...122",
        "...122",
        "..1222",
        "..1223",
        ".12223",
        "112222",
        "122212",
        "2221.1",
        "221..1",
        "21....",
        "1.....",
    ]
    rows = []
    for h in half:
        rows.append(h + h[::-1])
    return rows

def make_sprites():
    S = {}
    base = mirror_ship()
    def ship(rows, flame, tilt=0):
        s = Spr()
        for y, r in enumerate(rows):
            for x, c in enumerate(r):
                if c in '123':
                    xx = x
                    if tilt and y > 6: xx = x + tilt
                    s.set(xx, y + 3, int(c))
        if flame:
            s.set(5, 17, 3); s.set(6, 17, 3); s.set(5, 18, 2); s.set(6, 18, 2)
        else:
            s.set(5, 17, 2); s.set(6, 17, 2)
        return s
    S['ship'] = [ship(base, 0), ship(base, 1), ship(base, 0, -1), ship(base, 0, 1)]
    # player shots
    s = Spr(); s.ascii(["....3.......", "....3.......", "...323......", "....2.......", "....1......."], 1, 4); S['shot'] = [s]
    s = Spr(); s.ascii(["..3..3......", "..3..3......", ".323323.....", "..2..2......"], 2, 5); S['shot2'] = [s]
    s = Spr()
    for y in range(0, 21): s.set(5, y, 3 if y % 3 else 2); s.set(6, y, 3)
    S['laser'] = [s]
    s = Spr(); s.ellipse(6, 10.5, 1.6, 3.0, 0, shade=True); S['ball'] = [s]
    s = Spr(); s.ascii(["..3...", ".323..", ".222..", ".121..", ".1.1..", ".3.3.."], 3, 6); S['missile'] = [s]
    s = Spr(); s.ascii(["............", "333322222111"], 0, 9); S['side'] = [s, s.hflip()]
    eb = []
    for f in range(2):
        s = Spr(); s.ellipse(6, 10.5, 1.6 + f * 0.3, 3.0 + f * 0.5, 0, shade=True); s.set(6, 10, 3); eb.append(s)
    S['ebullet'] = eb
    # flyer: alien bug (4 frames wing flap)
    fl = []
    for f in range(4):
        s = Spr()
        s.ellipse(6, 9, 2.6, 6, 0, shade=True)
        w = [3, 4, 5, 4][f]
        for side in (-1, 1):
            for k in range(w):
                s.set(6 + side * (3 + k * 0.6), 6 + k, 1)
                s.set(6 + side * (3 + k * 0.6), 7 + k, 2)
        s.set(5, 13, 3); s.set(6, 13, 3)
        fl.append(s)
    S['flyer'] = fl
    # swoop: arrow fighter pointing down
    sw = []
    for f in range(2):
        s = Spr(); s.ascii([
            "1..........1",
            "21........12",
            "221......122",
            ".2221..1222.",
            "..22233222..",
            "...222222...",
            "....2332....",
            ".....22.....",
            ".....33....." if f else ".....11.....",
        ], 0, 5)
        sw.append(s)
    S['swoop'] = sw
    # turret (round base with barrel pointing down)
    tu = []
    for f in range(2):
        s = Spr(); s.ellipse(6, 9, 5, 8, 0, shade=True)
        s.ellipse(6, 9, 2, 3.5, 1); s.set(6, 9, 3)
        if f == 0: s.rect(5, 14, 6, 19, 1); s.rect(5, 18, 6, 19, 3)
        else: s.rect(5, 14, 6, 17, 1); s.rect(5, 16, 6, 17, 3)
        tu.append(s.outline())
    S['turret'] = tu
    # rock
    rr = random.Random(7); r0 = Spr()
    for y in range(21):
        for x in range(12):
            ang = math.atan2((y - 10) / 2.0, x - 5.5)
            rad = 1.0 + 0.16 * math.sin(ang * 3 + 2) + 0.1 * math.sin(ang * 5)
            dx = (x + .5 - 6) / 5.6; dy = (y + .5 - 10.5) / 10
            d = math.hypot(dx, dy)
            if d < rad * 0.95:
                l = -dx * 0.7 - dy * 0.7
                v = 3 if l > 0.55 and d > 0.4 else (1 if d > rad * 0.78 or l < -0.45 else 2)
                if rr.random() < 0.08: v = 1
                r0.p[y][x] = v
    S['rock'] = [r0, r0.hflip().vflip()]
    # diver: spike pod
    dv = []
    for f in range(2):
        s = Spr(); s.ellipse(6, 8, 3.5, 7, 0, shade=True)
        s.line(6, 15, 6, 20, 3 if f else 1); s.line(5, 15, 5, 19, 1)
        s.set(4, 6, 3); s.set(7, 6, 3)
        dv.append(s.outline())
    S['diver'] = dv
    # sider: saucer
    sd = []
    for f in range(2):
        s = Spr(); s.ellipse(6, 9, 3, 4, 0, shade=True); s.ellipse(6, 12, 6, 3, 2)
        s.rect(0, 13, 11, 13, 1)
        for k in range(3): s.set(2 + ((k * 3 + f * 2) % 8), 12, 3)
        sd.append(s.outline())
    S['sider'] = sd
    # mine
    mi = []
    for f in range(2):
        s = Spr(); s.ellipse(6, 10.5, 3.6, 6.5, 0, shade=True)
        for k in range(8):
            a = k * math.pi / 4 + f * math.pi / 8
            s.line(6 + math.cos(a) * 3.5, 10.5 + math.sin(a) * 6.5, 6 + math.cos(a) * 5.6, 10.5 + math.sin(a) * 10, 1)
        s.ellipse(6, 10.5, 1.2, 2.2, 3); mi.append(s)
    S['mine'] = mi
    # riser: claw ship pointing up
    S['riser'] = [x.vflip() for x in sw]
    # pod (big slow)
    po = []
    for f in range(2):
        s = Spr(); s.ellipse(6, 10.5, 6, 10, 0, shade=True)
        for y in range(3, 19, 4):
            for x in range(12):
                if s.p[y][x]: s.p[y][x] = 1
        s.ellipse(6, 10.5, 2, 3, 3 if f else 2)
        po.append(s)
    S['pod'] = po
    # bubbles: small / big (credit)
    b1 = Spr(); b1.ellipse(6, 10.5, 2.6, 4.6, 2); b1.set(5, 8, 3); b1.set(5, 9, 3); b1.outline()
    b2 = Spr(); b2.ellipse(6, 10.5, 4.6, 8.6, 2); b2.ellipse(6, 10.5, 3.2, 6.2, 0)
    for y in range(21):
        for x in range(12):
            if b2.p[y][x] == 0 and b1.p[y][x] == 0:
                pass
    b2.ellipse(6, 10.5, 4.6, 8.6, 2); b2.ascii(["..3..", ".333.", "33.3.", ".333.", ".3.33", ".333.", "..3.."], 4, 7)
    S['bubble'] = [b1, b2.outline()]
    # energy capsule (E) and speed capsule
    caps = []
    for letter in ("E", "S"):
        s = Spr(); s.ellipse(6, 10.5, 5.8, 7.8, 2); s.outline()
        for y in range(21):
            for x in range(12):
                if s.p[y][x] == 2 and (x <= 2 or y <= 5): s.p[y][x] = 1 if (x + y) % 2 else 2
        if letter == "E": s.ascii(["333.", "3...", "33..", "3...", "333."], 4, 8)
        else: s.ascii([".33.", "3...", ".33.", "...3", "333."], 4, 8)
        caps.append(s)
    S['capsule'] = caps
    # explosion (6)
    ex = []
    rr = random.Random(11)
    parts = [(rr.uniform(0, math.tau), rr.uniform(0.5, 1.0)) for _ in range(22)]
    for f in range(6):
        s = Spr(); R = 1.5 + f * 1.15
        if f < 3:
            s.ellipse(6, 10.5, R * 0.55 + 0.5, R + 1, 3 if f == 0 else 2)
            if f > 0: s.ellipse(6, 10.5, R * 0.3, R * 0.55, 3)
        for (a, sp) in parts:
            rad = R * sp + 1
            x = 6 + math.cos(a) * rad * 0.55; y = 10.5 + math.sin(a) * rad
            v = 3 if f < 2 else (2 if f < 4 else 1)
            s.set(x, y, v)
            if f < 4: s.set(x + 0.5, y, v)
        ex.append(s)
    S['explode'] = ex
    return S

# ---------------------------------------------------------------- bosses 36x63
def shade_ellipse(c, cx, cy, rx, ry, rim=1, mid=2, hi=3):
    for y in range(c.h):
        for x in range(c.w):
            dx = (x + .5 - cx) / rx; dy = (y + .5 - cy) / ry
            d = dx * dx + dy * dy
            if d <= 1:
                l = -dx * 0.6 - dy * 0.8
                c.p[y][x] = rim if d > 0.8 else (hi if l > 0.5 and d < 0.6 else mid)

def make_bosses():
    rnd = random.Random(77)
    B = []
    # 1 GORLOX: armored beetle, mandibles pointing down
    c = Spr(36, 63)
    shade_ellipse(c, 18, 26, 16, 24)
    for k in range(4):
        y = 10 + k * 9
        for x in range(36):
            if c.p[y][x]: c.p[y][x] = 1
    c.rect(17, 2, 18, 50, 1)
    for side in (-1, 1):
        for t in range(14):
            c.set(18 + side * (6 + t * 0.35), 48 + t, 2); c.set(18 + side * (7 + t * 0.35), 48 + t, 1)
    shade_ellipse(c, 11, 40, 3, 4, 1, 3, 3); shade_ellipse(c, 25, 40, 3, 4, 1, 3, 3)
    B.append(c)
    # 2 MEDUSOID: jellyfish
    c = Spr(36, 63)
    for k in range(7):
        x0 = 4 + k * 4.6
        for t in range(36):
            c.set(x0 + math.sin(t * 0.35 + k) * 1.5, 26 + t, 1 if t % 3 else 2)
    shade_ellipse(c, 18, 18, 17, 17)
    for k in range(5):
        shade_ellipse(c, 8 + k * 5, 26, 2, 3, 1, 3, 3)
    shade_ellipse(c, 18, 14, 5, 6, 1, 3, 3); c.ellipse(18, 15, 2, 3, 1)
    B.append(c)
    # 3 SKULLMECH
    c = Spr(36, 63)
    c.rect(4, 6, 31, 44, 2)
    for y in range(6, 45, 7): c.rect(4, y, 31, y, 1)
    for x in range(4, 32, 9): c.rect(x, 6, x, 44, 1)
    for (cx) in (8, 18, 27):
        c.rect(cx - 1, 44, cx + 1, 58, 1); c.rect(cx, 45, cx, 60, 3)
    shade_ellipse(c, 12, 22, 4, 6, 1, 3, 3); shade_ellipse(c, 24, 22, 4, 6, 1, 3, 3)
    c.ellipse(12, 23, 1.5, 2.5, 1); c.ellipse(24, 23, 1.5, 2.5, 1)
    c.rect(10, 34, 26, 38, 1)
    for x in range(11, 26, 3): c.rect(x, 34, x, 38, 3)
    B.append(c)
    # 4 PLASMA EYE
    c = Spr(36, 63)
    for k in range(12):
        a = k * math.tau / 12
        c.line(18 + math.cos(a) * 10, 31 + math.sin(a) * 20, 18 + math.cos(a) * 17, 31 + math.sin(a) * 30, 1)
    shade_ellipse(c, 18, 31, 14, 26)
    shade_ellipse(c, 18, 34, 9, 15, 1, 3, 3)
    shade_ellipse(c, 18, 38, 5, 8, 2, 2, 2)
    c.ellipse(18, 40, 2.5, 4, 1)
    B.append(c)
    # 5 MOTHER WORM head
    c = Spr(36, 63)
    for k in range(5):
        shade_ellipse(c, 18, 8 + k * 6, 15 - k, 6)
    shade_ellipse(c, 18, 40, 16, 16)
    c.rect(6, 48, 29, 51, 0)
    for x in range(7, 29, 3): c.set(x, 47, 3); c.set(x + 1, 52, 3)
    shade_ellipse(c, 10, 36, 3, 5, 1, 3, 3); shade_ellipse(c, 26, 36, 3, 5, 1, 3, 3)
    for k in range(10):
        a = rnd.uniform(0, math.tau)
        c.line(18 + math.cos(a) * 6, 40 + math.sin(a) * 8, 18 + math.cos(a) * 14, 40 + math.sin(a) * 15, 1)
    B.append(c)
    alts = []
    for c in B:
        a = Spr(36, 63); a.p = [r[:] for r in c.p]
        for y in range(63):
            for x in range(36):
                if a.p[y][x] == 3: a.p[y][x] = 2
                elif a.p[y][x] == 2 and (x + y) % 4 == 0: a.p[y][x] = 3
        alts.append(a)
    return B, alts

BOSS_COLORS = [9, 4, 12, 2, 5]

# ---------------------------------------------------------------- trader portrait (3x2 sprites = 72x42 hires)
def make_trader():
    c = Spr(36, 42)
    shade_ellipse(c, 18, 24, 15, 17)                    # head
    for side in (-1, 1):                                  # antennae
        c.line(18 + side * 6, 8, 18 + side * 10, 1, 1)
        c.ellipse(18 + side * 10, 1.5, 1.5, 2, 3)
    c.ellipse(18, 19, 7, 8, 3); c.ellipse(18, 19, 5, 6, 2)   # big eye
    c.ellipse(19, 20, 2.5, 4, 1); c.set(17, 17, 3)
    c.rect(10, 32, 26, 34, 1)                             # grin
    for x in range(11, 26, 3): c.set(x, 33, 3)
    c.rect(4, 38, 31, 41, 1); c.rect(5, 39, 30, 40, 2)    # collar
    c.set(18, 39, 3)
    return big_slices(c, 3, 2)

def build_sprites():
    S = make_sprites()
    bosses, alts = make_bosses()
    order = [(k, S[k]) for k in ['ship', 'shot', 'shot2', 'laser', 'ball', 'missile', 'side', 'ebullet',
                                 'flyer', 'swoop', 'turret', 'rock', 'diver', 'sider', 'mine', 'riser', 'pod',
                                 'bubble', 'capsule', 'explode']]
    for i, b in enumerate(bosses):
        order.append(('boss%d' % (i + 1), big_slices(b, 3, 3)))
    for i, b in enumerate(alts):
        sl = big_slices(b, 3, 3)
        order.append(('bossalt%d' % (i + 1), [sl[3], sl[4], sl[5]]))
    order.append(('trader', make_trader()))
    data = bytearray(); syms = {}; ptr = 0x40
    for name, frames in order:
        syms[name] = ptr
        for f in frames:
            data += f.tobytes(); ptr += 1
    assert ptr <= 255, ptr
    return data, syms

def render_preview(path, sprdata, tsets, tcols):
    from PIL import Image
    PAL = [(0,0,0),(255,255,255),(136,57,50),(103,182,189),(139,63,150),(85,160,73),(64,49,141),(191,206,114),
           (139,84,41),(87,66,0),(184,105,98),(80,80,80),(120,120,120),(148,224,137),(120,105,196),(159,159,159)]
    n = len(sprdata) // 64; cols = 16; rows = (n + cols - 1) // cols
    im = Image.new('RGB', (cols * 52, rows * 46 + 5 * 40 + 20), (30, 30, 40))
    for i in range(n):
        b = sprdata[i * 64:i * 64 + 64]; ox = (i % cols) * 52; oy = (i // cols) * 46
        for y in range(21):
            for x in range(12):
                v = (b[y * 3 + x // 4] >> (6 - 2 * (x % 4))) & 3
                c = [None, PAL[11], PAL[7], PAL[1]][v]
                if c:
                    for k in range(4):
                        for j in range(2): im.putpixel((ox + x * 4 + k, oy + y * 2 + j), c)
    for li in range(5):
        d22, d23 = LEVELS[li][1], LEVELS[li][2]; oy = rows * 46 + 10 + li * 40
        for i in range(29):
            cb = tsets[li * 256 + i * 8: li * 256 + i * 8 + 8]; cr = tcols[li * 32 + i] & 7
            for y in range(8):
                for x in range(4):
                    v = (cb[y] >> (6 - 2 * x)) & 3
                    c = [PAL[0], PAL[d22], PAL[d23], PAL[cr]][v]
                    for k in range(4):
                        for j in range(3): im.putpixel((i * 18 + x * 4 + k, oy + y * 3 + j), c)
    im.save(path)
