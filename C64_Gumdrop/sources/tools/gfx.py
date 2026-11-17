# ZYRON - graphics generator (charset + sprites)
import math, random

# ---------------------------------------------------------------- font
FONT = {
'A':[" XXXXX  ","XX   XX ","XX   XX ","XXXXXXX ","XX   XX ","XX   XX ","XX   XX "],
'B':["XXXXXX  ","XX   XX ","XX   XX ","XXXXXX  ","XX   XX ","XX   XX ","XXXXXX  "],
'C':[" XXXXX  ","XX   XX ","XX      ","XX      ","XX      ","XX   XX "," XXXXX  "],
'D':["XXXXX   ","XX  XX  ","XX   XX ","XX   XX ","XX   XX ","XX  XX  ","XXXXX   "],
'E':["XXXXXXX ","XX      ","XX      ","XXXXXX  ","XX      ","XX      ","XXXXXXX "],
'F':["XXXXXXX ","XX      ","XX      ","XXXXXX  ","XX      ","XX      ","XX      "],
'G':[" XXXXX  ","XX   XX ","XX      ","XX XXXX ","XX   XX ","XX   XX "," XXXXX  "],
'H':["XX   XX ","XX   XX ","XX   XX ","XXXXXXX ","XX   XX ","XX   XX ","XX   XX "],
'I':[" XXXX   ","  XX    ","  XX    ","  XX    ","  XX    ","  XX    "," XXXX   "],
'J':["   XXXX ","    XX  ","    XX  ","    XX  ","XX  XX  ","XX  XX  "," XXXX   "],
'K':["XX   XX ","XX  XX  ","XX XX   ","XXXX    ","XX XX   ","XX  XX  ","XX   XX "],
'L':["XX      ","XX      ","XX      ","XX      ","XX      ","XX      ","XXXXXXX "],
'M':["XX   XX ","XXX XXX ","XXXXXXX ","XX X XX ","XX   XX ","XX   XX ","XX   XX "],
'N':["XX   XX ","XXX  XX ","XXXX XX ","XX XXXX ","XX  XXX ","XX   XX ","XX   XX "],
'O':[" XXXXX  ","XX   XX ","XX   XX ","XX   XX ","XX   XX ","XX   XX "," XXXXX  "],
'P':["XXXXXX  ","XX   XX ","XX   XX ","XXXXXX  ","XX      ","XX      ","XX      "],
'Q':[" XXXXX  ","XX   XX ","XX   XX ","XX   XX ","XX X XX ","XX  XX  "," XXX XX "],
'R':["XXXXXX  ","XX   XX ","XX   XX ","XXXXXX  ","XX XX   ","XX  XX  ","XX   XX "],
'S':[" XXXXX  ","XX   XX ","XX      "," XXXXX  ","     XX ","XX   XX "," XXXXX  "],
'T':["XXXXXX  ","  XX    ","  XX    ","  XX    ","  XX    ","  XX    ","  XX    "],
'U':["XX   XX ","XX   XX ","XX   XX ","XX   XX ","XX   XX ","XX   XX "," XXXXX  "],
'V':["XX   XX ","XX   XX ","XX   XX ","XX   XX ","XX   XX "," XX XX  ","  XXX   "],
'W':["XX   XX ","XX   XX ","XX   XX ","XX X XX ","XXXXXXX ","XXX XXX ","XX   XX "],
'X':["XX   XX ","XX   XX "," XX XX  ","  XXX   "," XX XX  ","XX   XX ","XX   XX "],
'Y':["XX  XX  ","XX  XX  ","XX  XX  "," XXXX   ","  XX    ","  XX    ","  XX    "],
'Z':["XXXXXXX ","     XX ","    XX  ","  XXX   "," XX     ","XX      ","XXXXXXX "],
'0':[" XXXXX  ","XX  XXX ","XX XXXX ","XXXX XX ","XXX  XX ","XX   XX "," XXXXX  "],
'1':["  XX    "," XXX    ","XXXX    ","  XX    ","  XX    ","  XX    ","XXXXXX  "],
'2':[" XXXXX  ","XX   XX ","     XX ","   XXX  "," XXX    ","XX      ","XXXXXXX "],
'3':[" XXXXX  ","XX   XX ","     XX ","  XXXX  ","     XX ","XX   XX "," XXXXX  "],
'4':["   XXX  ","  XXXX  "," XX XX  ","XX  XX  ","XXXXXXX ","    XX  ","    XX  "],
'5':["XXXXXXX ","XX      ","XXXXXX  ","     XX ","     XX ","XX   XX "," XXXXX  "],
'6':[" XXXXX  ","XX      ","XX      ","XXXXXX  ","XX   XX ","XX   XX "," XXXXX  "],
'7':["XXXXXXX ","     XX ","    XX  ","   XX   ","  XX    ","  XX    ","  XX    "],
'8':[" XXXXX  ","XX   XX ","XX   XX "," XXXXX  ","XX   XX ","XX   XX "," XXXXX  "],
'9':[" XXXXX  ","XX   XX ","XX   XX "," XXXXXX ","     XX ","     XX "," XXXXX  "],
'!':["  XX    ","  XX    ","  XX    ","  XX    ","  XX    ","        ","  XX    "],
'.':["        ","        ","        ","        ","        ","  XX    ","  XX    "],
',':["        ","        ","        ","        ","  XX    ","  XX    "," XX     "],
':':["        ","  XX    ","  XX    ","        ","  XX    ","  XX    ","        "],
'-':["        ","        ","        "," XXXXX  ","        ","        ","        "],
'/':["     XX ","    XX  ","   XX   ","  XX    "," XX     ","XX      ","        "],
'?':[" XXXXX  ","XX   XX ","    XX  ","   XX   ","   XX   ","        ","   XX   "],
'(':["   XX   ","  XX    "," XX     "," XX     "," XX     ","  XX    ","   XX   "],
')':[" XX     ","  XX    ","   XX   ","   XX   ","   XX   ","  XX    "," XX     "],
"'":["  XX    ","  XX    "," XX     ","        ","        ","        ","        "],
'"':[" XX XX  "," XX XX  ","        ","        ","        ","        ","        "],
'=':["        ","        ","XXXXXX  ","        ","XXXXXX  ","        ","        "],
'+':["        ","  XX    ","  XX    ","XXXXXX  ","  XX    ","  XX    ","        "],
'*':["        "," X  X   ","  XX    ","XXXXXX  ","  XX    "," X  X   ","        "],
'#':[" XX XX  ","XXXXXXX "," XX XX  "," XX XX  ","XXXXXXX "," XX XX  ","        "],
'<':["    XX  ","   XX   ","  XX    "," XX     ","  XX    ","   XX   ","    XX  "],
'>':[" XX     ","  XX    ","   XX   ","    XX  ","   XX   ","  XX    "," XX     "],
'&':[" XXX    ","XX XX   "," XXX    ","XXX XX X","XX  XXX ","XX  XX  "," XXX XX "],
'@':[" XXXXX  ","XX   XX ","XX XXXX ","XX XXXX ","XX XXX  ","XX      "," XXXXX  "],
}

def screencode(ch):
    o = ord(ch)
    if 64 <= o <= 95: return o - 64
    if 32 <= o <= 63: return o
    raise ValueError(ch)

def glyph_bytes(rows):
    out = []
    for r in rows + ["        "] * (8 - len(rows)):
        b = 0
        for i, c in enumerate(r[:8]):
            if c != ' ': b |= 0x80 >> i
        out.append(b)
    return out

# ---------------------------------------------------------------- charset layout
CH_QUAD = 64      # 16 quadrant chars
CH_BG = 80        # 8 patterns * 4 chars
CH_BAR = 112      # 5 bar chars (0..4 quarters)
CH_BARL = 117
CH_BARR = 118
CH_SHIP = 119
CH_LINE = 120
CH_TERR = 128     # terrain chars 128..159

NPAT = 4
# pattern speeds (1/256 px per frame) and star colors (hires: 0-7)
PAT_SPEED = [32, 72, 128, 184]
PAT_COLOR = [6, 4, 3, 1]
# which pattern each playfield row uses (255 = empty)
ROWPAT = [0, 255, 2, 1, 255, 3, 0, 255, 1, 2, 255, 0, 3, 255, 1, 2, 255, 0, 3, 255, 1]

def make_patterns(seed=7):
    rnd = random.Random(seed)
    pats = []
    for p in range(NPAT):
        bm = [[0] * 16 for _ in range(8)]
        nstars = 2 if p < 2 else 1
        used = []
        for s in range(nstars):
            for _ in range(50):
                x = rnd.randrange(16); y = rnd.randrange(1, 7)
                if all(abs(x - a) > 5 for a, b in used): break
            used.append((x, y))
            bm[y][x] = 1
            if p >= 3:            # near stars: little streak
                bm[y][(x + 1) % 16] = 1
            if p >= 2 and s == 0:
                bm[y][(x + 1) % 16] = 1
        pats.append(bm)
    return pats

def build_base_charset():
    cs = bytearray(2048)
    for ch, rows in FONT.items():
        sc = screencode(ch)
        cs[sc * 8: sc * 8 + 8] = bytes(glyph_bytes(rows))
    # quadrant chars: bit0=TL bit1=TR bit2=BL bit3=BR
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
    pats = make_patterns()
    for p, bm in enumerate(pats):
        for k in range(2):
            for y in range(8):
                b = 0
                for i in range(8):
                    if bm[y][k * 8 + i]: b |= 0x80 >> i
                cs[(CH_BG + p * 2 + k) * 8 + y] = b
    # bar chars (hires): frame top/bottom lines + fill of n*2 px
    for n in range(5):
        for y in range(8):
            if y in (0, 7): b = 0xFF
            elif y in (1, 6): b = 0x00
            else:
                b = (0xFF << (8 - n * 2)) & 0xFF
            cs[(CH_BAR + n) * 8 + y] = b
    cs[CH_BARL * 8: CH_BARL * 8 + 8] = bytes([0x07, 0x08, 0x10, 0x10, 0x10, 0x10, 0x08, 0x07])
    cs[CH_BARR * 8: CH_BARR * 8 + 8] = bytes([0xE0, 0x10, 0x08, 0x08, 0x08, 0x08, 0x10, 0xE0])
    cs[CH_SHIP * 8: CH_SHIP * 8 + 8] = bytes([0x00, 0x30, 0x7C, 0xFF, 0x7E, 0x30, 0x00, 0x00])
    cs[CH_LINE * 8: CH_LINE * 8 + 8] = bytes([0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00])
    return cs

# ---------------------------------------------------------------- terrain textures
# MC chars: 4x8 pixels values 0..3. Floor tile set:
# E0 E1 (surface), S0 S1 (sub), D0..D3 (deep 2x2), SU (slope up), SD (slope down)
# order in charset (relative): floor 0..9, ceiling 10..19, extras 20..
T_FE0, T_FE1, T_FS0, T_FS1, T_FD0, T_FD1, T_FD2, T_FD3, T_FSU, T_FSD = range(10)
T_CE0 = 10

def texfunc(style, rnd):
    """returns f(x,y) giving 0..3 for a 8x32 floor tile (x 0..7 MC px, y 0..31) y=0 is surface."""
    if style == 'rock':
        pts = [(rnd.uniform(0, 8), rnd.uniform(0, 32)) for _ in range(9)]
        def f(x, y):
            ds = []
            for (px, py) in pts:
                for ox in (-8, 0, 8):
                    for oy in (-32, 0, 32):
                        dx = (x + .5 - px - ox) * 2.0; dy = (y + .5 - py - oy)
                        ds.append(math.hypot(dx, dy))
            ds.sort()
            if ds[1] - ds[0] < 1.6: return 0 if y > 6 else 1
            if ds[0] < 2.5: return 3 if (x + y) % 3 == 0 else 2
            return 2 if ds[0] < 5 else 1
        return f
    if style == 'bio':
        def f(x, y):
            v = math.sin(x * 0.9 + y * 0.35) + math.sin(y * 0.45 - x * 0.6) * 0.8 + math.sin((x + y) * 0.25)
            if abs(v) < 0.25: return 3
            if v > 0.9: return 2
            if v > -0.6: return 1
            return 2 if (x + y) % 2 else 1
        return f
    if style == 'ice':
        def f(x, y):
            a = (x * 2 + y) % 12; b = (y - x * 2) % 12
            if a == 0 or b == 0: return 3
            if a < 4 and b < 6: return 2
            if (a + b) % 7 == 1: return 0 if y > 8 else 1
            return 1 if a > 6 else 2
        return f
    if style == 'lava':
        pts = [(rnd.uniform(0, 8), rnd.uniform(0, 32)) for _ in range(7)]
        def f(x, y):
            ds = []
            for (px, py) in pts:
                for ox in (-8, 0, 8):
                    for oy in (-32, 0, 32):
                        ds.append(math.hypot((x + .5 - px - ox) * 2, y + .5 - py - oy))
            ds.sort()
            if ds[1] - ds[0] < 1.4: return 3
            return 1 if ds[0] > 3.5 else 2
        return f
    if style == 'tech':
        def f(x, y):
            yy = y % 16
            if yy == 0 or x == 0: return 3 if (x == 0 and yy == 0) else 1
            if yy == 15 or x == 7: return 0
            if (yy in (3, 12)) and x in (2, 5): return 3
            if 6 <= yy <= 9 and 1 < x < 7: return 1 if yy % 2 else 0
            return 2
        return f
    if style == 'hive':
        def f(x, y):
            # hex cells
            hx = x * 2.0; hy = y * 1.0
            best = []
            for cx in range(-1, 3):
                for cy in range(-1, 5):
                    ox = cx * 8 + (4 if cy % 2 else 0); oy = cy * 8
                    best.append(math.hypot(hx - ox, (hy - oy) * 1.1))
            best.sort()
            d = best[1] - best[0]
            if d < 1.2: return 1
            if best[0] < 2.2: return 3
            return 2
        return f
    raise ValueError(style)

def make_terrain(style, seed):
    rnd = random.Random(seed)
    f = texfunc(style, rnd)
    T = [[f(x, y) for x in range(8)] for y in range(32)]
    # surface shaping: rows 0..1 highlight
    for x in range(8):
        T[0][x] = 3
        T[1][x] = 2 if T[1][x] != 3 else 3
        if T[2][x] == 0: T[2][x] = 1
    chars = {}
    def cut(cx, cy):          # 4x8 block from tile at char coords
        return [[T[cy * 8 + y][cx * 4 + x] for x in range(4)] for y in range(8)]
    chars[T_FE0] = cut(0, 0); chars[T_FE1] = cut(1, 0)
    chars[T_FS0] = cut(0, 1); chars[T_FS1] = cut(1, 1)
    chars[T_FD0] = cut(0, 2); chars[T_FD1] = cut(1, 2)
    chars[T_FD2] = cut(0, 3); chars[T_FD3] = cut(1, 3)
    # slopes: use sub texture masked by diagonal, highlight on diagonal
    sub = cut(0, 1)
    su = [[0] * 4 for _ in range(8)]; sd = [[0] * 4 for _ in range(8)]
    for y in range(8):
        for x in range(4):
            hx = x * 2 + 1
            # slope up (rising to right): solid where y >= 7 - hx
            e = y - (7 - hx)
            if e >= 0: su[y][x] = 3 if e < 2 else (2 if e < 3 else sub[y][x])
            e2 = y - hx
            if e2 >= 0: sd[y][x] = 3 if e2 < 2 else (2 if e2 < 3 else sub[y][x])
    chars[T_FSU] = su; chars[T_FSD] = sd
    # ceiling = vertical mirror, slopes: CSU (ceiling rising to right) & CSD
    def vflip(c): return [row[:] for row in c[::-1]]
    for i in range(10):
        chars[T_CE0 + i] = vflip(chars[i])
    # vflip of floor slope-up (solid lower-right) gives solid upper-right = ceiling going down to right (CSD)
    # vflip of floor slope-down (solid lower-left) gives solid upper-left = ceiling rising to right (CSU)
    # we keep indices: 18 = vflip(FSU) -> ceiling descending ; 19 = vflip(FSD) -> ceiling rising
    return chars

def mc_char_bytes(c):
    out = []
    for y in range(8):
        b = 0
        for x in range(4):
            b |= (c[y][x] & 3) << (6 - 2 * x)
        out.append(b)
    return out

# level styles and palettes: (style, d022, d023, edge%11, deep%11, name)
LEVELS = [
    ('rock', 9, 8, 7, 0, "ASTEROID OUTPOST"),
    ('bio', 4, 10, 1, 2, "BIOMECH CAVERNS"),
    ('ice', 6, 14, 1, 3, "CRYSTAL FIELDS"),
    ('lava', 9, 2, 7, 7, "MAGMA REACTOR"),
    ('tech', 11, 12, 1, 3, "IRON FORTRESS"),
    ('hive', 5, 13, 7, 4, "THE HIVE CORE"),
]

def terrain_sets():
    data = bytearray()
    colors = bytearray()
    for li, (style, d22, d23, ce, cd, name) in enumerate(LEVELS):
        ch = make_terrain(style, 100 + li)
        for i in range(32):
            if i in ch: data += bytes(mc_char_bytes(ch[i]))
            else: data += bytes(8)
        for i in range(32):
            j = i % 10
            if j in (0, 1, 8, 9): colors.append(8 + ce)
            else: colors.append(8 + cd)
    return data, colors

# ---------------------------------------------------------------- sprites
class Spr:
    """multicolor sprite canvas 12x21, values 0..3"""
    def __init__(self, w=12, h=21):
        self.w, self.h = w, h
        self.p = [[0] * w for _ in range(h)]
    def set(self, x, y, v):
        x = int(round(x)); y = int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h: self.p[y][x] = v
    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h: return self.p[y][x]
        return 0
    def ellipse(self, cx, cy, rx, ry, v, shade=False):
        for y in range(self.h):
            for x in range(self.w):
                dx = (x + .5 - cx) / rx; dy = (y + .5 - cy) / ry
                d = dx * dx + dy * dy
                if d <= 1.0:
                    if shade:
                        l = -dx * 0.6 - dy * 0.8
                        if d > 0.72: vv = 1
                        elif l > 0.55: vv = 3
                        else: vv = 2
                        self.p[y][x] = vv
                    else:
                        self.p[y][x] = v
    def rect(self, x0, y0, x1, y1, v):
        for y in range(max(0, y0), min(self.h, y1 + 1)):
            for x in range(max(0, x0), min(self.w, x1 + 1)):
                self.p[y][x] = v
    def line(self, x0, y0, x1, y1, v):
        n = int(max(abs(x1 - x0) * 2, abs(y1 - y0))) + 1
        for i in range(n + 1):
            t = i / n
            self.set(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, v)
    def ascii(self, rows, ox=0, oy=0):
        m = {'.': 0, ' ': 0, '1': 1, '2': 2, '3': 3}
        for y, r in enumerate(rows):
            for x, c in enumerate(r):
                if c in m and m[c]: self.set(ox + x, oy + y, m[c])
                elif c == '0': self.set(ox + x, oy + y, 0)
    def hflip(self):
        s = Spr(self.w, self.h); s.p = [r[::-1] for r in self.p]; return s
    def vflip(self):
        s = Spr(self.w, self.h); s.p = [r[:] for r in self.p[::-1]]; return s
    def outline(self):
        # add dark outline (1) around shapes
        q = [r[:] for r in self.p]
        for y in range(self.h):
            for x in range(self.w):
                if self.p[y][x] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        if self.get(x + dx, y + dy) in (2, 3):
                            q[y][x] = 1; break
        self.p = q
        return self
    def tobytes(self):
        out = bytearray(64)
        for y in range(21):
            for bx in range(3):
                b = 0
                for x in range(4):
                    b |= (self.p[y][bx * 4 + x] & 3) << (6 - 2 * x)
                out[y * 3 + bx] = b
        return out

def big_slices(big, cols, rows):
    out = []
    for r in range(rows):
        for c in range(cols):
            s = Spr()
            for y in range(21):
                for x in range(12):
                    s.p[y][x] = big.get(c * 12 + x, r * 21 + y)
            out.append(s)
    return out

SHIP = [""]*5 + [
"11..........",
"1221........",
"12221111....",
"1222223331..",
"012222222223",
"1122222221..",
"12221111....",
"1221........",
"11..........",
]
SHIP_UP = [""]*5 + [
"............",
"11..........",
"12221111....",
"1222223331..",
"012222222223",
"1122222221..",
"122221111...",
"122221......",
"11111.......",
]
SHIP_DN = [""]*5 + [
"11111.......",
"122221......",
"122221111...",
"1222223331..",
"012222222223",
"1122222221..",
"12221111....",
"11..........",
"............",
]

def make_sprites():
    S = {}        # name -> list of Spr
    # player (3 frames) + flame variants
    def ship(rows, flame):
        s = Spr(); s.ascii(rows)
        s.set(0, 9, 3 if flame else 1)
        return s
    S['ship'] = [ship(SHIP, 0), ship(SHIP_UP, 0), ship(SHIP_DN, 0), ship(SHIP, 1)]
    # orb (4 frames)
    orbs = []
    for f in range(4):
        s = Spr(); s.ellipse(6, 10, 4.2, 7.5, 0, shade=True)
        a = f * math.pi / 2
        for k in range(4):
            ang = a + k * math.pi / 2
            s.set(6 + math.cos(ang) * 5.2, 10 + math.sin(ang) * 9.5, 3)
        s.set(5, 7, 3)
        orbs.append(s)
    S['orb'] = orbs
    # player shots
    s = Spr(); s.ascii(["..1233333..."], 0, 10); s.ascii(["...12222...."], 0, 9); S['pulse'] = [s]
    s = Spr(); s.ascii(["122333333333", "113333333332"], 0, 9); S['laser'] = [s]
    s = Spr(); s.ellipse(6, 10.5, 1.8, 3.2, 0, shade=True); s.set(6, 9, 3); S['spread'] = [s]
    s = Spr(); s.ascii(["...1122223..", "....1111...."], 0, 9); s.set(2, 9, 3); S['missile'] = [s]
    big = Spr(24, 21)
    for y in range(21):
        dy = abs(y - 10)
        for x in range(24):
            # crescent wave: outer arc minus inner arc
            ox = (x - 4) - (10 - dy) * 0.0
            r_out = 19 - dy * dy * 0.16
            r_in = 13 - dy * dy * 0.16
            d = x - (dy * dy) * 0.12
            if d < r_out and d > r_in - 9 and r_out > 0:
                if d > r_out - 2: v = 3
                elif d > r_in: v = 2
                elif d > r_in - 4: v = 1
                else: v = 0
                if v: big.p[y][x] = v
    for y in range(8, 13):
        for x in range(0, 8):
            if big.p[y][x] == 0 and (x + y) % 2 == 0: big.p[y][x] = 1
    cw = big_slices(big, 2, 1)
    S['charge'] = cw
    # enemy bullet
    eb = []
    for f in range(2):
        s = Spr(); s.ellipse(6, 10.5, 1.6 + f * 0.3, 3.0 + f * 0.5, 0, shade=True)
        s.set(6, 10, 3); eb.append(s)
    S['ebullet'] = eb
    # drone: saucer with spinning lights (4)
    dr = []
    for f in range(4):
        s = Spr()
        s.ellipse(6, 9, 3, 4, 0, shade=True)
        s.ellipse(6, 12, 6, 3, 2)
        for x in range(12):
            if s.p[12][x]: s.p[13][x] = 1 if s.p[13][x] else s.p[13][x]
        s.rect(1, 13, 10, 13, 1)
        for k in range(3):
            xx = 2 + ((k * 3 + f) % 8)
            s.set(xx, 12, 3)
        s.outline(); dr.append(s)
    S['drone'] = dr
    # dart: fighter pointing left (2)
    da = []
    for f in range(2):
        s = Spr(); s.ascii([
            "............",
            ".......1....",
            "......12....",
            ".....1221...",
            "...1122221..",
            "3122223222" + ("13" if f else "11"),
            "...1122221..",
            ".....1221...",
            "......12....",
            ".......1....",
        ], 0, 5)
        da.append(s)
    S['dart'] = da
    # turret (floor): dome with barrel pointing up-left ; ceiling = vflip
    tu = []
    for f in range(2):
        s = Spr()
        s.ellipse(6, 17, 4.5, 5, 0, shade=True)
        s.rect(1, 18, 10, 20, 1); s.rect(2, 19, 9, 19, 2)
        if f == 0: s.line(4, 13, 1, 9, 3); s.line(5, 13, 2, 9, 1)
        else: s.line(6, 12, 6, 7, 3); s.line(5, 12, 5, 7, 1)
        tu.append(s)
    S['turret'] = tu
    S['turretc'] = [t.vflip() for t in tu]
    # rock (2)
    rk = []
    rr = random.Random(5)
    base = Spr()
    for y in range(21):
        for x in range(12):
            ang = math.atan2((y - 10) / 2.0, (x - 5.5) * 1.0)
            rad = 1.0 + 0.18 * math.sin(ang * 3 + 1) + 0.1 * math.sin(ang * 5)
            dx = (x + .5 - 6) / 5.6; dy = (y + .5 - 10.5) / 10
            d = math.hypot(dx, dy)
            if d < rad * 0.95:
                l = -dx * 0.7 - dy * 0.7
                v = 3 if l > 0.55 and d > 0.4 else (1 if d > rad * 0.78 or l < -0.45 else 2)
                if rr.random() < 0.08: v = 1
                base.p[y][x] = v
    rk.append(base); rk.append(base.hflip().vflip())
    S['rock'] = rk
    # hopper (2) - crawler
    ho = []
    for f in range(2):
        s = Spr()
        s.ellipse(6, 12, 5, 6, 0, shade=True)
        s.set(3, 10, 3); s.set(3, 11, 1); s.set(5, 10, 3)
        if f == 0:
            s.line(2, 17, 0, 20, 1); s.line(9, 17, 11, 20, 1); s.line(6, 18, 6, 20, 1)
        else:
            s.line(2, 17, 1, 19, 1); s.line(9, 17, 10, 19, 1); s.line(5, 18, 4, 20, 1); s.line(7, 18, 8, 20, 1)
        ho.append(s)
    S['hopper'] = ho
    # carrier (2): pod with window
    ca = []
    for f in range(2):
        s = Spr(); s.ellipse(6, 10.5, 6, 6.5, 0, shade=True)
        s.rect(0, 9, 11, 11, 1); s.rect(1, 10, 10, 10, 2)
        s.set(2 + f * 7, 10, 3); s.set(4 + f * 3, 10, 3)
        s.ellipse(6, 6, 2, 2.5, 3)
        ca.append(s)
    S['carrier'] = ca
    # mine: spiky ball (2)
    mi = []
    for f in range(2):
        s = Spr(); s.ellipse(6, 10.5, 3.6, 6.5, 0, shade=True)
        for k in range(8):
            ang = k * math.pi / 4 + f * math.pi / 8
            s.line(6 + math.cos(ang) * 3.5, 10.5 + math.sin(ang) * 6.5, 6 + math.cos(ang) * 5.6, 10.5 + math.sin(ang) * 10, 1)
        s.ellipse(6, 10.5, 1.2, 2.2, 3)
        mi.append(s)
    S['mine'] = mi
    # chaser: claw ship pointing right (2)
    ch = []
    for f in range(2):
        s = Spr(); s.ascii([
            "1222........",
            ".11222......",
            "...12222....",
            "..1122233...",
            ("31" if f else "11") + "222222223",
            "..1122233...",
            "...12222....",
            ".11222......",
            "1222........",
        ], 0, 6)
        ch.append(s)
    S['chaser'] = ch
    # explosion (6)
    ex = []
    rr = random.Random(11)
    parts = [(rr.uniform(0, math.tau), rr.uniform(0.5, 1.0)) for _ in range(22)]
    for f in range(6):
        s = Spr()
        R = 1.5 + f * 1.15
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
    # power-up capsules with letters
    pu = []
    LET = {
        'L': ["3...", "3...", "3...", "3...", "333."],
        'S': [".33.", "3...", ".33.", "...3", "333."],
        'H': ["3..3", "3..3", "3333", "3..3", "3..3"],
        'O': [".33.", "3..3", "3..3", "3..3", ".33."],
        '+': ["....", ".3..", "333.", ".3..", "...."],
        'B': ["333.", "3..3", "333.", "3..3", "333."],
    }
    for l in "LSHO+B":
        s = Spr(); s.ellipse(6, 10.5, 5.8, 7.8, 2)
        for y in range(21):
            for x in range(12):
                if s.p[y][x]:
                    s.p[y][x] = 2
        s.outline()
        for y in range(21):
            for x in range(12):
                if s.p[y][x] == 2 and (x <= 2 or y <= 5): s.p[y][x] = 1 if (x + y) % 2 else 2
        s.ascii(LET[l], 4, 8)
        pu.append(s)
    S['powerup'] = pu
    return S

# --------------------------------------------------------------- bosses (36x63 MC)
def boss_canvas():
    return Spr(36, 63)

def shade_ellipse(c, cx, cy, rx, ry, rim=1, mid=2, hi=3, light=(-0.6, -0.8)):
    for y in range(c.h):
        for x in range(c.w):
            dx = (x + .5 - cx) / rx; dy = (y + .5 - cy) / ry
            d = dx * dx + dy * dy
            if d <= 1:
                l = dx * light[0] + dy * light[1]
                if d > 0.8: v = rim
                elif l > 0.5 and d < 0.6: v = hi
                else: v = mid
                c.p[y][x] = v

def make_bosses():
    bosses = []
    rnd = random.Random(42)
    # 1 GORGAX - armored crab
    c = boss_canvas()
    shade_ellipse(c, 20, 31, 15, 22)
    for k in range(5):          # armor plates
        y = 14 + k * 8
        for x in range(8, 34):
            if c.p[y][x]: c.p[y][x] = 1
    for side in (-1, 1):        # claws
        cy = 31 + side * 18
        shade_ellipse(c, 7, cy, 7, 7)
        for x in range(0, 6): c.set(x, cy + side * 1, 0)
        c.line(10, cy, 16, 31 + side * 8, 1)
    shade_ellipse(c, 16, 31, 5, 7, rim=1, mid=3, hi=3)      # eye core
    c.ellipse(15, 31, 2, 3, 1)
    for x in range(30, 36): c.set(x, 31, 1); c.set(x, 30, 2)
    bosses.append(c)
    # 2 OCULUS - biomech eye
    c = boss_canvas()
    for k in range(6):          # tentacles
        a = (k - 2.5) * 0.45
        x0, y0 = 22, 31
        for t in range(40):
            tt = t / 40.0
            x = x0 + math.cos(a + math.pi * 0.0) * 0 + 14 * tt
            y = y0 + (k - 2.5) * 10 * tt + math.sin(tt * 7 + k) * 3
            c.set(x, y, 1 if t % 3 else 2)
            c.set(x, y + 1, 2)
    shade_ellipse(c, 17, 31, 15, 27)
    shade_ellipse(c, 13, 31, 9, 15, rim=1, mid=3, hi=3)
    shade_ellipse(c, 10, 31, 5, 9, rim=2, mid=2, hi=2)
    c.ellipse(9, 31, 2.5, 4.5, 1)
    c.set(8, 28, 3); c.set(8, 27, 3)
    for k in range(12):                 # veins
        a = rnd.uniform(0, math.tau)
        c.line(17 + math.cos(a) * 9, 31 + math.sin(a) * 15, 17 + math.cos(a) * 14, 31 + math.sin(a) * 25, 1)
    bosses.append(c)
    # 3 CRYOSTAR - crystal
    c = boss_canvas()
    def diamond(cx, cy, rx, ry, v1, v2, v3):
        for y in range(c.h):
            for x in range(c.w):
                dx = (x + .5 - cx) / rx; dy = (y + .5 - cy) / ry
                if abs(dx) + abs(dy) <= 1:
                    if abs(dx) + abs(dy) > 0.82: v = v1
                    elif dx < 0 and dy < 0: v = v3
                    elif dx < 0: v = v2
                    elif dy < 0: v = v2
                    else: v = v1
                    c.p[y][x] = v
    diamond(18, 31, 17, 31, 1, 2, 3)
    diamond(9, 14, 7, 12, 1, 2, 3)
    diamond(9, 48, 7, 12, 1, 2, 3)
    diamond(27, 20, 7, 12, 1, 2, 3)
    diamond(27, 44, 7, 12, 1, 2, 3)
    diamond(16, 31, 7, 12, 1, 3, 3)
    c.ellipse(15, 31, 2, 3.5, 1)
    bosses.append(c)
    # 4 MAGMAWYRM - fiery skull head
    c = boss_canvas()
    shade_ellipse(c, 20, 26, 15, 22)
    shade_ellipse(c, 14, 46, 13, 11)       # jaw
    for x in range(2, 30):
        c.set(x, 40, 0); c.set(x, 41, 0)
    for k in range(6):                      # teeth
        x = 4 + k * 4
        c.set(x, 39, 3); c.set(x, 42, 3); c.set(x + 1, 39, 3)
    shade_ellipse(c, 12, 22, 4, 6, rim=1, mid=3, hi=3)   # eye
    c.ellipse(11, 22, 1.5, 3, 1)
    for k in range(5):                      # horns / flames
        x0 = 18 + k * 3
        c.line(x0, 6, x0 + 3, 0, 2); c.line(x0 + 1, 6, x0 + 4, 1, 3)
    for k in range(10):
        a = rnd.uniform(0, math.tau)
        c.line(22 + math.cos(a) * 5, 26 + math.sin(a) * 8, 22 + math.cos(a) * 12, 26 + math.sin(a) * 18, 1)
    bosses.append(c)
    # 5 DREADNOUGHT - battleship
    c = boss_canvas()
    c.rect(8, 10, 35, 52, 2)
    for y in range(10, 53, 6): c.rect(8, y, 35, y, 1)
    for x in range(8, 36, 7): c.rect(x, 10, x, 52, 1)
    for y in range(12, 52, 6):
        for x in range(10, 36, 7): c.set(x, y + 1, 3)
    c.rect(12, 4, 30, 9, 1); c.rect(13, 5, 29, 8, 2); c.rect(12, 53, 30, 58, 1); c.rect(13, 54, 29, 57, 2)
    for (cy, ln) in ((16, 8), (31, 10), (46, 8)):      # cannons
        c.rect(8 - ln, cy - 1, 8, cy + 1, 1); c.rect(8 - ln, cy, 8, cy, 3)
        c.rect(4, cy - 3, 9, cy + 3, 1); c.rect(5, cy - 2, 8, cy + 2, 2)
    shade_ellipse(c, 21, 31, 6, 9, rim=1, mid=3, hi=3)
    c.ellipse(20, 31, 2.5, 4, 1)
    bosses.append(c)
    # 6 HIVE MOTHER - brain with tentacles
    c = boss_canvas()
    for k in range(5):
        y0 = 12 + k * 10
        for t in range(30):
            x = 20 + t * 0.55
            y = y0 + math.sin(t * 0.5 + k) * 3
            c.set(x, y, 1); c.set(x, y + 1, 2)
    shade_ellipse(c, 18, 31, 16, 30)
    for k in range(14):                # brain folds
        a0 = rnd.uniform(0, math.tau)
        for t in range(14):
            a = a0 + t * 0.25
            r = 0.45 + 0.4 * math.sin(t * 0.7 + k)
            c.set(18 + math.cos(a) * 16 * r, 31 + math.sin(a) * 30 * r, 1)
    shade_ellipse(c, 12, 31, 6, 9, rim=1, mid=3, hi=3)
    c.ellipse(11, 31, 3, 5, 2); c.ellipse(10, 31, 1.5, 2.5, 1)
    bosses.append(c)
    # alt frame (core flash) = center slice with core changed
    alts = []
    for bi, c in enumerate(bosses):
        a = Spr(36, 63); a.p = [r[:] for r in c.p]
        for y in range(63):
            for x in range(36):
                if a.p[y][x] == 3: a.p[y][x] = 2
                elif a.p[y][x] == 2 and (x + y) % 4 == 0: a.p[y][x] = 3
        alts.append(a)
    return bosses, alts

BOSS_COLORS = [8, 4, 3, 2, 12, 5]
BOSS_NAMES = ["GORGAX", "OCULUS", "CRYOSTAR", "MAGMAWYRM", "DREADNOUGHT", "HIVE MOTHER"]

def build_sprites():
    S = make_sprites()
    bosses, alts = make_bosses()
    order = []
    def add(name, frames):
        order.append((name, frames))
    for k in ['ship', 'orb', 'pulse', 'laser', 'spread', 'missile', 'charge', 'ebullet',
              'drone', 'dart', 'turret', 'turretc', 'rock', 'hopper', 'carrier', 'mine',
              'chaser', 'explode', 'powerup']:
        add(k, S[k])
    for i, b in enumerate(bosses):
        add('boss%d' % (i + 1), big_slices(b, 3, 3))
    for i, b in enumerate(alts):
        sl = big_slices(b, 3, 3)
        add('bossalt%d' % (i + 1), [sl[3], sl[4]])      # middle-left & center alternates
    data = bytearray()
    syms = {}
    ptr = 0x40
    for name, frames in order:
        syms[name] = ptr
        for f in frames:
            data += f.tobytes()
            ptr += 1
    assert ptr <= 256, ptr
    return data, syms, S, bosses

def render_preview(path, charset, sprdata, tsets, tcols):
    from PIL import Image
    PAL = [(0,0,0),(255,255,255),(136,57,50),(103,182,189),(139,63,150),(85,160,73),(64,49,141),(191,206,114),
           (139,84,41),(87,66,0),(184,105,98),(80,80,80),(120,120,120),(148,224,137),(120,105,196),(159,159,159)]
    n = len(sprdata) // 64
    cols = 16
    rows = (n + cols - 1) // cols
    im = Image.new('RGB', (cols * 52, rows * 46 + 6 * 40 + 20), (30, 30, 40))
    for i in range(n):
        b = sprdata[i * 64: i * 64 + 64]
        ox = (i % cols) * 52; oy = (i // cols) * 46
        for y in range(21):
            for x in range(12):
                v = (b[y * 3 + x // 4] >> (6 - 2 * (x % 4))) & 3
                c = [None, PAL[11], PAL[7], PAL[1]][v]
                if c:
                    for k in range(4):
                        for j in range(2):
                            im.putpixel((ox + x * 4 + k, oy + y * 2 + j), c)
    # terrain sets
    for li in range(6):
        d22, d23 = LEVELS[li][1], LEVELS[li][2]
        oy = rows * 46 + 10 + li * 40
        for i in range(20):
            cb = tsets[li * 256 + i * 8: li * 256 + i * 8 + 8]
            cr = tcols[li * 32 + i] & 7
            for y in range(8):
                for x in range(4):
                    v = (cb[y] >> (6 - 2 * x)) & 3
                    c = [PAL[0], PAL[d22], PAL[d23], PAL[cr]][v]
                    for k in range(4):
                        for j in range(3):
                            im.putpixel((i * 18 + x * 4 + k, oy + y * 3 + j), c)
    im.save(path)
