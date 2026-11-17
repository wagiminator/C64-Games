# SUNRUSH - graphics generator: road template, scenery, sprites, logo
# all designs are original and drawn procedurally
import math, random
from gfx import FONT, screencode, glyph_bytes, Spr

# ---------------------------------------------------------------- road geometry
NL = 120            # road raster lines (131..250)
HORIZON = 131
C_GEO = 3.0         # perspective constant of the road width
CS = 40.0           # stylised depth mapping for stripes / objects
ZS = 51200.0        # depth scale (stripe length 64 units)
HWB, KWB, MWB = 64.0, 7.0, 2.4      # half width, kerb, lane mark at the bottom (MC px)
M = 24              # template margin (chars) on each side
TW = 40 + 2 * M     # template width in chars
CX = TW * 4 / 2

def scale(i):
    return (i + C_GEO) / (NL - 1 + C_GEO)

def road_class(i, x):
    s = scale(i)
    hw, kw, mw = HWB * s, KWB * s, MWB * s
    d = abs(x - CX)
    if d >= hw + kw: return 0           # grass  ($d021)
    if d >= hw: return 1                # kerb   ($d022)
    if abs(d - hw / 3.0) < mw / 2: return 3   # lane mark (colour RAM)
    return 2                            # asphalt ($d023)

# shear per template row (hires px per character row): sheared variants let the fine scroll
# follow steep road edges (sharp curves, car far off-centre) without clamping
SROW = [16] * 6 + [8] * 4 + [0] * 5

def shear_shift(S, v):
    """MC pixel shift of the 8 char lines for shear S (hires px / row), direction v"""
    if S == 16: sh = [-3, -2, -1, 0, 0, 1, 2, 3]
    elif S == 8: sh = [-2, -1, -1, 0, 0, 1, 1, 2]
    else: sh = [0] * 8
    return [v * x for x in sh]

def road_template():
    """-> (list of 8-byte MC chars, rows: 15 x (TW * variants) char indices; variants [0, +1, -1])"""
    uniq = {}; chars = []; rows = []
    blank = tuple(tuple([0] * 4) for _ in range(8))
    uniq[blank] = 0; chars.append(bytes(8))
    for r in range(NL // 8):
        row = []
        for v in ((0, 1, -1) if SROW[r] else (0,)):
            sh = shear_shift(SROW[r], v)
            for c in range(TW):
                cell = tuple(tuple(road_class(r * 8 + l, c * 4 + k + 0.5 - sh[l]) for k in range(4)) for l in range(8))
                if cell not in uniq:
                    uniq[cell] = len(chars)
                    d = bytearray(8)
                    for l in range(8):
                        w = 0
                        for k in range(4): w |= cell[l][k] << (6 - 2 * k)
                        d[l] = w
                    chars.append(bytes(d))
                row.append(uniq[cell])
        rows.append(row)
    assert len(chars) <= 256, len(chars)
    return chars, rows

def depth_tables():
    """zs[i] (16 bit) per road line; inverse table: line for depth (dz >> 2)"""
    zs = [int(round(ZS / (i + CS))) for i in range(NL)]
    inv = []
    for q in range(0, 1300 // 4 + 1):
        dz = q * 4
        best = 255
        if dz >= zs[NL - 1]:
            # largest i with zs[i] >= dz
            for i in range(NL):
                if zs[i] >= dz: best = i
        inv.append(best)
    return zs, inv

# ---------------------------------------------------------------- MC char helpers
def mc_cells(canvas, w_chars, h_rows):
    """canvas[y][x] values 0..3 (MC px) -> list of rows of 8-byte char data"""
    out = []
    for r in range(h_rows):
        row = []
        for c in range(w_chars):
            d = bytearray(8)
            for l in range(8):
                v = 0
                for k in range(4):
                    v |= (canvas[r * 8 + l][c * 4 + k] & 3) << (6 - 2 * k)
                d[l] = v
            row.append(bytes(d))
        out.append(row)
    return out

# ---------------------------------------------------------------- scenery (5 sets)
# canvas: 64 chars wide (256 MC px), 5 rows (40 lines); 0 = sky ($d021), 1 = $d022, 2 = $d023, 3 = colour RAM (per row)
SCN_W = 64
SCN_ROWS = 5

def scenery(kind, seed=1):
    rnd = random.Random(seed)
    W, H = SCN_W * 4, SCN_ROWS * 8
    cv = [[0] * W for _ in range(H)]
    def ridge(base, amp, freq, phase, val, rough=0.0):
        for x in range(W):
            h = base + amp * (0.6 * math.sin(2 * math.pi * freq * x / W + phase) +
                              0.4 * math.sin(2 * math.pi * (freq * 2 + 1) * x / W + phase * 1.7))
            h += rough * (rnd.random() - 0.5)
            top = int(round(H - h))
            for y in range(max(0, top), H):
                if cv[y][x] == 0: cv[y][x] = val
    if kind == 'sea':           # far islands + sea with glitter
        for y in range(H - 10, H):
            for x in range(W): cv[y][x] = 1
        for (cx, w, h) in ((40, 34, 9), (150, 50, 13), (215, 22, 6)):
            for x in range(cx - w // 2, cx + w // 2):
                t = (x - cx) / (w / 2)
                hh = int(h * (1 - t * t) ** 0.6)
                for y in range(H - 10 - hh, H - 10):
                    cv[y][x % W] = 2
        for k in range(60):
            x = rnd.randrange(W); y = rnd.randrange(H - 9, H)
            if (x + y) % 2 == 0: cv[y][x] = 3
        # sun
        for y in range(0, H - 10):
            for x in range(96, 120):
                if (x - 108) ** 2 / 1.0 + ((y - 14) * 2) ** 2 / 4.0 < 70: cv[y][x] = 3
    elif kind == 'mesa':        # red-brown table mountains
        x = 0
        while x < W:
            w = rnd.randrange(18, 46); h = rnd.randrange(12, 30)
            for xx in range(x, min(W, x + w)):
                e = min(xx - x, x + w - 1 - xx)
                hh = h if e > 3 else h - (4 - e) * 3
                for y in range(H - hh, H): cv[y][xx] = 2
                if hh > 6:
                    for y in range(H - hh, H - hh + 2): cv[y][xx] = 3
            x += w + rnd.randrange(4, 20)
        ridge(6, 2, 3, 0.3, 1)
    elif kind == 'hills':       # snowy peaks behind green hills
        for x in range(W):
            t = x / W * 2 * math.pi
            h = 20 + 12 * abs(math.sin(t * 2 + 0.4)) * (0.6 + 0.4 * math.sin(t * 5))
            top = int(H - h)
            for y in range(top, H):
                cv[y][x] = 3 if y < top + 4 else 2
        ridge(10, 4, 4, 1.2, 1)
    elif kind == 'city':        # skyline with windows (char aligned to save characters)
        x = 0
        while x < W:
            wc = rnd.randrange(1, 4); h = rnd.choice((12, 16, 20, 24, 28, 32, 36))
            lit = rnd.randrange(3)
            for xx in range(x, min(W, x + wc * 4)):
                for y in range(H - h, H):
                    cv[y][xx] = 1
                    if (y % 4) == 2 and (xx % 4) in (1, 2) and y > H - h + 1 and ((xx // 4 + y // 4 + lit) % 3): cv[y][xx] = 3
            x += wc * 4 + 4 * rnd.randrange(0, 2)
        ridge(4, 1, 2, 0, 2)
    elif kind == 'volcano':
        for x in range(W):
            d = abs(x - 128)
            h = max(0, 36 - d * 0.45) if d > 6 else 33
            h = max(h, 6 + 3 * math.sin(x / 9.0))
            for y in range(int(H - h), H): cv[y][x] = 1
        for y in range(H - 34, H - 22):           # lava flows
            for x in range(116, 140):
                if abs(x - 128 + (y % 5) - 2) < 2 + (y - (H - 34)) // 3 and (x * 7 + y) % 3: cv[y][x] = 3
        for y in range(0, 6):                     # smoke
            for x in range(118, 150):
                if (x - 130 - y * 2) ** 2 + (y - 3) ** 2 * 6 < 50: cv[y][x] = 2
        ridge(5, 2, 3, 0.5, 2)
    return cv

SCENERY_KINDS = ['sea', 'mesa', 'hills', 'city', 'volcano']

def scenery_set(kind):
    """-> (chars list (<=96), map rows (5 x (64+40)) char indices)"""
    cv = scenery(kind, seed=SCENERY_KINDS.index(kind) + 11)
    cells = mc_cells(cv, SCN_W, SCN_ROWS)
    uniq = {bytes(8): 0}; chars = [bytes(8)]; mp = []
    for r in range(SCN_ROWS):
        row = []
        for c in range(SCN_W):
            d = cells[r][c]
            if d not in uniq:
                uniq[d] = len(chars); chars.append(d)
            row.append(uniq[d])
        mp.append(row + row[:40])
    assert len(chars) <= 96, (kind, len(chars))
    return chars, mp

# ---------------------------------------------------------------- sprites
# canvas values: 0 transparent, 1 black ($d025), 2 sprite colour, 3 light grey ($d026)
class Big:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.p = [[0] * w for _ in range(h)]
    def set(self, x, y, v):
        x = int(math.floor(x)); y = int(math.floor(y))
        if 0 <= x < self.w and 0 <= y < self.h: self.p[y][x] = v
    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h: return self.p[y][x]
        return 0
    def rect(self, x0, y0, x1, y1, v):
        for y in range(max(0, int(y0)), min(self.h, int(y1) + 1)):
            for x in range(max(0, int(x0)), min(self.w, int(x1) + 1)):
                self.p[y][x] = v
    def ellipse(self, cx, cy, rx, ry, v):
        for y in range(self.h):
            for x in range(self.w):
                if ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 <= 1: self.p[y][x] = v
    def line(self, x0, y0, x1, y1, v, th=1):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            t = i / n
            x = x0 + (x1 - x0) * t; y = y0 + (y1 - y0) * t
            for d in range(th): self.set(x + d - th // 2, y, v)
    def outline(self):
        q = [r[:] for r in self.p]
        for y in range(self.h):
            for x in range(self.w):
                if self.p[y][x] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        if self.get(x + dx, y + dy) in (2, 3):
                            q[y][x] = 1; break
        self.p = q
        return self
    def hflip(self):
        b = Big(self.w, self.h); b.p = [r[::-1] for r in self.p]; return b

def downscale(big, f, w=12, h=21):
    """scale a big canvas by factor f into a w x h sprite canvas, bottom centred"""
    s = Spr(w, h)
    tw = max(1, int(round(big.w * f))); th = max(1, int(round(big.h * f)))
    ox = (w - tw) // 2; oy = h - th
    for y in range(th):
        for x in range(tw):
            # sample block, priority: body/grey over outline over empty
            x0 = int(x / f); x1 = max(x0 + 1, int((x + 1) / f))
            y0 = int(y / f); y1 = max(y0 + 1, int((y + 1) / f))
            cnt = [0, 0, 0, 0]
            for yy in range(y0, min(big.h, y1)):
                for xx in range(x0, min(big.w, x1)):
                    cnt[big.p[yy][xx]] += 1
            tot = sum(cnt)
            if tot == 0: continue
            if cnt[0] * 2 > tot and f < 0.5:
                v = 0
            else:
                v = max((1, 2, 3), key=lambda k: (cnt[k], k))
                if cnt[v] == 0: v = 0
            s.set(ox + x, oy + y, v)
    return s

SIZE_F = [0.12, 0.2, 0.3, 0.4, 0.5]        # big canvas 24x42 -> sprite sizes 0..4

def sized(big):
    return [downscale(big, f) for f in SIZE_F]

# ---- roadside objects (big canvas 24 x 42 MC px, base at the bottom)
def palm():
    b = Big(24, 42)
    for y in range(12, 42):                 # curved trunk
        x = 11 + 3 * math.sin((y - 12) / 30 * 1.6)
        b.rect(x - 1, y, x + 1, y, 3)
        if y % 3 == 0: b.set(x - 1, y, 1)
    for k, (dx, dy) in enumerate(((-11, 4), (-8, 9), (10, 3), (8, 9), (-3, -1), (4, -1), (0, 6))):
        for t in range(14):
            u = t / 13
            x = 12 + dx * u; y = 12 + dy * u - 6 * math.sin(u * math.pi) * (1 if abs(dx) > 5 else 0.3)
            b.rect(x - 1, y, x, y + 1, 2)
    b.ellipse(12, 12, 2.5, 2, 1)
    return b.outline()

def bush():
    b = Big(24, 42)
    for (cx, cy, rx, ry) in ((8, 34, 7, 7), (16, 33, 7, 8), (12, 29, 7, 6)):
        b.ellipse(cx, cy, rx, ry, 2)
    for k in range(18):
        x = 4 + (k * 7) % 16; y = 26 + (k * 5) % 14
        b.set(x, y, 3)
    b.rect(5, 40, 19, 41, 1)
    return b.outline()

def cactus():
    b = Big(24, 42)
    b.rect(10, 6, 14, 41, 2)
    b.rect(3, 16, 7, 26, 2); b.rect(3, 24, 10, 28, 2)
    b.rect(17, 12, 21, 22, 2); b.rect(14, 20, 21, 24, 2)
    for y in range(8, 40, 3): b.set(12, y, 3)
    return b.outline()

def rock():
    b = Big(24, 42)
    b.ellipse(12, 36, 11, 8, 2)
    b.ellipse(8, 33, 5, 4, 3)
    b.line(4, 38, 18, 36, 1)
    return b.outline()

def pine(snow=False):
    b = Big(24, 42)
    b.rect(11, 34, 13, 41, 3)
    for k in range(5):
        y0 = 4 + k * 6; w = 3 + k * 2
        for y in range(y0, y0 + 9):
            ww = int(w * (y - y0 + 1) / 9) + 1
            b.rect(12 - ww, y, 12 + ww - 1, y, 2)
            if snow and y == y0 + 2: b.rect(12 - ww, y, 12 + ww - 1, y, 3)
    b.set(12, 3, 2)
    return b.outline()

def house():
    b = Big(24, 42)
    b.rect(3, 24, 20, 41, 2)
    for y in range(14, 24):
        w = (y - 14) + 2
        b.rect(12 - w, y, 11 + w, y, 1)
    b.rect(6, 28, 9, 32, 3); b.rect(14, 28, 17, 32, 3)
    b.rect(10, 34, 13, 41, 1)
    return b.outline()

def tower():
    b = Big(24, 42)
    b.rect(5, 2, 18, 41, 2)
    for y in range(4, 40, 4):
        for x in range(7, 17, 3): b.rect(x, y, x + 1, y + 1, 3)
    return b.outline()

def lamp():
    b = Big(24, 42)
    b.rect(11, 6, 12, 41, 3)
    b.rect(12, 5, 19, 6, 3)
    b.rect(17, 7, 20, 8, 2)
    b.rect(9, 39, 14, 41, 1)
    return b.outline()

def windmill():
    b = Big(24, 42)
    for y in range(18, 42):
        w = 3 + (y - 18) // 5
        b.rect(12 - w, y, 11 + w, y, 2)
    b.rect(10, 34, 13, 41, 1)
    for a in (0.5, 2.07, 3.64, 5.21):
        b.line(12, 15, 12 + 11 * math.cos(a), 15 + 11 * math.sin(a), 3, 2)
    b.ellipse(12, 15, 1.5, 1.5, 1)
    return b.outline()

def flowers():
    b = Big(24, 42)
    for k in range(26):
        x = 2 + (k * 9) % 20; y = 30 + (k * 7) % 11
        b.rect(x, y, x + 1, y + 1, 2 if k % 3 else 3)
    for x in range(2, 22, 2): b.set(x, 41, 1)
    return b

def sign(direction):
    b = Big(24, 42)
    b.rect(11, 20, 12, 41, 1)
    b.rect(1, 4, 22, 20, 3)
    if direction < 0:
        for k in range(7): b.rect(5 + k, 12 - k // 1.4, 5 + k, 12 + k // 1.4, 1)
        b.rect(10, 11, 18, 13, 1)
    else:
        for k in range(7): b.rect(18 - k, 12 - k // 1.4, 18 - k, 12 + k // 1.4, 1)
        b.rect(5, 11, 13, 13, 1)
    return b.outline()

def gatepost():
    b = Big(24, 42)
    for y in range(0, 42):
        b.rect(10, y, 13, y, 2 if (y // 4) % 2 else 3)
    b.rect(13, 1, 22, 9, 2)
    for y in range(1, 10, 2):
        for x in range(13 + (y // 2) % 2, 23, 2): b.set(x, y, 3)
    return b.outline()

def bollard():
    b = Big(24, 42)
    for y in range(20, 42):
        w = 2 + (y - 20) // 8
        b.rect(12 - w, y, 11 + w, y, 3 if (y // 4) % 2 else 2)
    b.rect(8, 40, 15, 41, 1)
    return b.outline()

# ---- traffic (rear views)
def sedan():
    b = Big(24, 42)
    b.rect(2, 26, 21, 38, 2)                # body
    b.rect(4, 20, 19, 26, 2)                # cabin
    b.rect(6, 21, 17, 25, 1)                # rear window
    b.rect(3, 28, 6, 30, 3); b.rect(17, 28, 20, 30, 3)   # lights
    b.rect(9, 31, 14, 33, 3)                # plate
    b.rect(2, 35, 21, 36, 3)                # bumper
    b.rect(2, 37, 5, 41, 1); b.rect(18, 37, 21, 41, 1)   # wheels
    return b.outline()

def van():
    b = Big(24, 42)
    b.rect(2, 12, 21, 38, 2)
    b.rect(5, 15, 18, 22, 1)
    b.rect(3, 30, 5, 33, 3); b.rect(18, 30, 20, 33, 3)
    b.line(12, 23, 12, 36, 1)
    b.rect(2, 36, 21, 37, 3)
    b.rect(2, 37, 5, 41, 1); b.rect(18, 37, 21, 41, 1)
    return b.outline()

def truck():
    b = Big(24, 42)
    b.rect(1, 4, 22, 35, 3)                 # container
    for y in range(6, 34, 5): b.rect(2, y, 21, y, 1)
    b.rect(1, 35, 22, 37, 2)
    b.rect(2, 37, 6, 41, 1); b.rect(17, 37, 21, 41, 1)
    return b.outline()

# ---- player car (24 x 42 MC px = 2 x 2 sprites), original roadster design
def player_car(steer=0, brake=False):
    b = Big(24, 42)
    sh = steer      # cockpit shifted for steering
    # wide tyres
    for (x0, x1) in ((0, 4), (19, 23)):
        b.rect(x0, 25, x1, 41, 1)
        for y in range(27, 41, 3): b.rect(x0 + 1, y, x1 - 1, y, 3)
    # flared fenders over the tyres, low wide body
    b.rect(0, 21, 5, 25, 2); b.rect(18, 21, 23, 25, 2)
    b.rect(2, 19, 21, 34, 2)
    b.rect(4, 17, 19, 19, 2)
    # open cockpit: thin windscreen frame, driver with head rest
    b.rect(5 + sh, 11, 18 + sh, 11, 3)
    b.rect(5 + sh, 11, 5 + sh, 17, 3); b.rect(18 + sh, 11, 18 + sh, 17, 3)
    b.rect(6 + sh, 14, 17 + sh, 17, 1)
    b.ellipse(9.5 + sh, 11.5, 2.6, 3.2, 1)
    b.rect(13 + sh, 13, 15 + sh, 17, 3)
    # rear spoiler lip and deck vents
    b.rect(3, 19, 20, 19, 1)
    for x in range(8, 16, 2): b.set(x, 21, 1)
    # wide tail light strips, plate, bumper, twin exhausts
    lc = 3 if brake else 1
    b.rect(3, 24, 9, 27, 1); b.rect(4, 25, 8, 26, lc)
    b.rect(14, 24, 20, 27, 1); b.rect(15, 25, 19, 26, lc)
    b.rect(9, 28, 14, 31, 3); b.set(10, 29, 1); b.set(12, 29, 1); b.set(13, 30, 1)
    b.rect(2, 33, 21, 34, 3)
    b.rect(6, 35, 7, 36, 3); b.rect(16, 35, 17, 36, 3)
    b.rect(5, 37, 18, 38, 1)
    b.outline()
    return b

def car_sprites(b):
    out = []
    for r in range(2):
        for c in range(2):
            s = Spr()
            for y in range(21):
                for x in range(12):
                    s.p[y][x] = b.get(c * 12 + x, r * 21 + y)
            out.append(s)
    return out

def smoke(k):
    s = Spr()
    for (cx, cy, r) in ((6, 15, 3 + k), (4 + k, 12 - k, 2 + k), (8, 11 - k, 2 + k // 2)):
        for y in range(21):
            for x in range(12):
                if ((x - cx) * 2) ** 2 + (y - cy) ** 2 <= (r * 2) ** 2 // 1.5:
                    s.p[y][x] = 3 if (x + y + k) % 3 else 2
    return s

OBJ_TYPES = [('palm', palm), ('bush', bush), ('cactus', cactus), ('rock', rock), ('pine', pine),
             ('snowpine', lambda: pine(True)), ('house', house), ('tower', tower), ('lamp', lamp),
             ('windmill', windmill), ('flowers', flowers), ('signl', lambda: sign(-1)),
             ('signr', lambda: sign(1)), ('gate', gatepost), ('bollard', bollard),
             ('sedan', sedan), ('van', van), ('truck', truck)]

def build_sprites(base=0x60):
    order = []
    cars = []
    for st, br in ((0, False), (-1, False), (1, False), (0, True)):
        cars += car_sprites(player_car(st, br))
    order.append(('car', cars))
    for name, f in OBJ_TYPES:
        order.append((name, sized(f())))
    order.append(('smoke', [smoke(k) for k in range(3)]))
    blank = Spr()
    order.append(('blank', [blank]))
    data = bytearray(); syms = {}; ptr = base
    for name, frames in order:
        syms[name] = ptr
        for fr in frames:
            data += fr.tobytes(); ptr += 1
    assert ptr <= 0x100, hex(ptr)
    return data, syms

# ---------------------------------------------------------------- logo "SUNRUSH"
def logo_bitmap():
    W, H = 10, 14
    def glyph(ch):
        g = [[0] * W for _ in range(H)]
        def rect(x0, y0, x1, y1):
            for y in range(max(0, y0), min(H, y1 + 1)):
                for x in range(max(0, x0), min(W, x1 + 1)): g[y][x] = 1
        if ch == 'S':
            rect(1, 0, 9, 2); rect(0, 1, 2, 6); rect(1, 5, 8, 7); rect(7, 6, 9, 12); rect(0, 11, 8, 13)
        elif ch == 'U':
            rect(0, 0, 2, 12); rect(7, 0, 9, 12); rect(1, 11, 8, 13)
        elif ch == 'N':
            rect(0, 0, 2, 13); rect(7, 0, 9, 13)
            for i in range(14):
                x = 1 + int(i * 6 / 13)
                rect(x, i, x + 2, i)
        elif ch == 'R':
            rect(0, 0, 2, 13); rect(0, 0, 8, 2); rect(0, 6, 8, 8); rect(7, 1, 9, 7)
            for i in range(6): rect(4 + i // 1, 8 + i, 6 + i // 1, 8 + i)
        elif ch == 'H':
            rect(0, 0, 2, 13); rect(7, 0, 9, 13); rect(0, 5, 9, 8)
        return g
    WT = 80; bm = [[0] * WT for _ in range(H)]
    x = 2
    for ch in "SUNRUSH":
        g = glyph(ch)
        for y in range(H):
            sh = (H - 1 - y) // 4
            for xx in range(W):
                if g[y][xx]:
                    X = x + xx + sh
                    if 0 <= X < WT: bm[y][X] = 1
        x += W + 1
    return bm
