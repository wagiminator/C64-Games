# FLEETFOOT - original graphics (runner, obstacles, coins, power-ups, boulder, scenery, logo)
import math, random
import fgeo as G

# ------------------------------------------------------------------ multicolour sprite canvas
# values: 0 transparent, 1 = $D025 (black), 2 = own colour, 3 = $D026 (white)
class Spr:
    def __init__(self):
        self.p = [[0] * 12 for _ in range(21)]
    def set(self, x, y, v):
        if 0 <= x < 12 and 0 <= y < 21:
            self.p[y][x] = v
    def get(self, x, y):
        return self.p[y][x] if 0 <= x < 12 and 0 <= y < 21 else 0
    def ascii(self, rows, oy=0):
        m = {'.': 0, 'k': 1, 'o': 2, 'w': 3}
        for y, r in enumerate(rows):
            for x, ch in enumerate(r):
                self.set(x, y + oy, m[ch])
        return self
    def tobytes(self):
        out = []
        for y in range(21):
            for b in range(3):
                v = 0
                for i in range(4):
                    v = (v << 2) | self.p[y][b * 4 + i]
                out.append(v)
        return bytes(out) + b'\0'

def outline_inner(s):
    """shape pixels touching transparency become black (1), keeping white highlights inside"""
    q = [r[:] for r in s.p]
    for y in range(21):
        for x in range(12):
            if s.p[y][x] == 2:
                for ax, ay in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if s.get(x + ax, y + ay) == 0:
                        q[y][x] = 1
                        break
    s.p = q
    return s

# ------------------------------------------------------------------ the runner (seen from behind)
TOP_A = [   # left arm swung back (visible low), right arm forward (hidden)
    "....kkkk....",
    "...kooook...",
    "...kooook...",
    ".kkkkkkkkkk.",
    "kooooooooook",
    ".kkkkkkkkkk.",
    "...kkkkkk...",
    "...kkkkkk...",
    "..kkkookkk..",
    ".kooooooook.",
    ".kokwwwwkok.",
    "kokwwwwwwkok",
    "kokwwwwwwkk.",
    "kokwwwwwwk..",
    "kkkwwwwwwk..",
    "kwkkwwwwkk..",
    "kk.kkkkkk...",
    "...kooook...",
    "...kkkkkk...",
    "...kooook...",
    "...kooook...",
]
TOP_RUN = [TOP_A, [r[::-1] for r in TOP_A]]

BOT_A = [   # left foot kicked up behind, right leg down
    "...kooook...",
    "..koooooook.",
    "..kooookook.",
    "..kook.kook.",
    "..kook..kok.",
    "..kkkk..kok.",
    "..kwwk..kok.",
    "..kkkk..kok.",
    "........kok.",
    "........kok.",
    ".......kkkk.",
    ".......kwwk.",
    ".......kkkk.",
] + ["............"] * 8
BOT_B = [   # legs passing
    "...kooook...",
    "..koooooook.",
    "..kooookook.",
    "..kook.kook.",
    "..kook.kook.",
    "...kok.kok..",
    "...kok.kok..",
    "...kok.kok..",
    "...kok.kok..",
    "...kok.kkk..",
    "..kkkk.kwk..",
    "..kwwk.kkk..",
    "..kkkk......",
] + ["............"] * 8
def mirror(rows):
    return [r[::-1] for r in rows]
BOT_RUN = [BOT_A, BOT_B, mirror(BOT_A), mirror(BOT_B)]

TOP_JUMP = [
    "....kkkk....",
    "...kooook...",
    "...kooook...",
    ".kkkkkkkkkk.",
    "kooooooooook",
    ".kkkkkkkkkk.",
    "k..kkkkkk..k",
    "ok.kkkkkk.ko",
    "kokkkookkkok",
    ".kooooooook.",
    "..kwwwwwwk..",
    "..kwwwwwwk..",
    "..kwwwwwwk..",
    "..kwwwwwwk..",
    "...kwwwwk...",
    "...kkkkkk...",
    "...kooook...",
    "...kkkkkk...",
    "...kooook...",
    "...kooook...",
    "...kooook...",
]
BOT_JUMP = [
    "..kooooook..",
    ".koooooooook",
    ".kook..kook.",
    "kook....kook",
    "kkkk....kkkk",
    "kwwk....kwwk",
    "kkkk....kkkk",
] + ["............"] * 14

# sliding: the whole runner fits into the lower sprite
BOT_SLIDE = ["............"] * 6 + [
    "....kkkk....",
    "...kooook...",
    ".kkkkkkkkkk.",
    "kooooooooook",
    ".kkkkkkkkkk.",
    ".kokwwwwkok.",
    "kokwwwwwwkok",
    "kokwwwwwwkok",
    "kkkkkkkkkkkk",
    "kooooooooook",
    "kooooooooook",
    ".kkkkkkkkkk.",
    "kwwk....kwwk",
    "kkkk....kkkk",
    "............",
]

# fallen runner
BOT_FALL = ["............"] * 9 + [
    ".kkkk.......",
    "kooook......",
    "kkkkkkkkkkk.",
    "kooookwwwwkk",
    "kkkkkwwwwwwk",
    ".kkkkkkkkkkk",
    "kooooooookwk",
    "kooooooookkk",
    ".kkkkkkkk...",
    "............",
    "............",
    "............",
]

def runner_frames():
    """returns dict name -> (top Spr, bottom Spr)"""
    blank = Spr()
    f = {}
    for i in range(4):
        f['RUN%d' % i] = (Spr().ascii(TOP_RUN[0 if i < 2 else 1]), Spr().ascii(BOT_RUN[i]))
    f['JUMP'] = (Spr().ascii(TOP_JUMP), Spr().ascii(BOT_JUMP))
    f['SLIDE'] = (blank, Spr().ascii(BOT_SLIDE))
    f['FALL'] = (blank, Spr().ascii(BOT_FALL))
    return f

# ------------------------------------------------------------------ scaled obstacle sprites
# shape functions: (u, v) in lanes (u across, v up from the ground) -> 0 / 2 / 3 (inside colours)
def barrier_fn(u, v):
    au = abs(u)
    if 0.20 <= v <= 0.36 and au <= 0.42:
        # warning stripes
        return 3 if int((u + 1) * 7 + v * 6) % 2 else 2
    if v <= 0.21 and 0.30 <= au <= 0.38:
        return 2
    return 0

def bar_fn(u, v):
    au = abs(u)
    if 0.58 <= v <= 0.86 and au <= 0.46:
        return 3 if v > 0.80 else 2
    if v <= 0.60 and 0.36 <= au <= 0.45:
        return 2
    return 0

def block_fn(u, v):
    au = abs(u)
    if v <= 0.72 and au <= 0.42:
        if v > 0.64:
            return 3
        if abs(v - 0.34) < 0.03 or (abs(u - 0.12) < 0.025 and v < 0.34) or (abs(u + 0.22) < 0.025 and v > 0.34):
            return 1
        return 2
    return 0

def coin_fn(phase):
    def f(u, v):
        rx = 0.16 if phase == 0 else 0.07
        dy = (v - 0.18) / 0.16
        dx = u / rx
        r = dx * dx + dy * dy
        if r <= 1.0:
            if r < 0.35 and phase == 0:
                return 3 if (dx < -0.1 and dy > 0.1) else 2
            return 2
        return 0
    return f

def power_fn(kind):
    # kind 0 magnet, 1 boots, 2 x2, 3 amulet
    def f(u, v):
        cy = 0.24
        x, y = u / 0.2, (v - cy) / 0.2
        if kind == 0:   # horseshoe magnet
            r = math.hypot(x, y - 0.1)
            if y >= 0.1 and 0.45 <= r <= 1.0:
                return 2
            if y < 0.1 and y > -0.9 and 0.45 <= abs(x) <= 1.0:
                return 3 if y < -0.5 else 2
            return 0
        if kind == 1:   # winged boot
            if -0.9 < y < 0.8 and -0.6 < x < 0.1:
                return 2
            if -0.9 < y < -0.4 and 0.1 <= x < 0.9:
                return 2
            if 0.1 < y < 0.9 and 0.15 < x < 1.0 and (y - 0.1) > (x - 0.15) * 0.4:
                return 3
            return 0
        if kind == 2:   # star
            a = math.atan2(y, x)
            r = math.hypot(x, y)
            lim = 0.55 + 0.45 * abs(math.cos(2.5 * a))
            if r <= lim:
                return 3 if r < 0.35 else 2
            return 0
        # amulet: ring with gem
        r = math.hypot(x, y)
        if r <= 0.45:
            return 3
        if r <= 1.0:
            return 2
        return 0
    return f

def render_scaled(fn, dx, xexp, yexp, base_row=20, h_lanes=0.0):
    """rasterise fn at dx pixels per lane into a 12x21 multicolour sprite.
    MC pixel width = 2 hires px (x4 when x-expanded), line height 1 (2 when y-expanded)."""
    s = Spr()
    pw = 4 if xexp else 2
    ph = 2 if yexp else 1
    for py in range(21):
        for px in range(12):
            vals = []
            for sy in (0.25, 0.75):
                for sx in (0.25, 0.75):
                    hx = (px + sx) * pw - 12 * pw / 2
                    hy = (base_row + 1 - (py + sy)) * ph
                    u = hx / dx
                    v = hy / dx - h_lanes
                    vals.append(fn(u, v))
            nz = [x for x in vals if x]
            if len(nz) >= 2:
                s.p[py][px] = max(set(nz), key=nz.count)
    return outline_inner(s)

# size classes for near sprites (pixels per lane)
NEAR_DX = [31, 36, 42, 48, 54, 60]
NEAR_LIM = [34, 39, 45, 51, 57, 255]          # dx < limit -> class

def near_sprites():
    out = {}
    for c, dx in enumerate(NEAR_DX):
        out['BARR%d' % c] = render_scaled(barrier_fn, dx, True, False)
        out['BAR%d' % c] = render_scaled(bar_fn, dx, True, True)
        out['BLK%d' % c] = render_scaled(block_fn, dx, True, True)
        for ph in range(2):
            out['COIN%d_%d' % (c, ph)] = render_scaled(coin_fn(ph), dx, False, False)
        for k in range(4):
            out['PWR%d_%d' % (k, c)] = render_scaled(power_fn(k), dx, False, False)
    return out

# ------------------------------------------------------------------ boulder (two x/y expanded sprites side by side)
def _rock(x, y, r, phase):
    """colour of a rolling rock at hires offset (x, y) from its centre, radius r"""
    d = math.hypot(x, y)
    if d > r:
        return 0
    if d > r - 3:
        return 1
    # rolling towards the viewer: bands of cracks move down
    t = (math.asin(max(-1.0, min(1.0, y / r))) * 3.0 + phase) % 2.0
    if t < 0.18 and abs(x) < r * 0.9:
        return 1
    if x < -r * 0.25 and y < -r * 0.25 and d < r * 0.8:
        return 3
    if (int((x + 64) / 9) + int((y + 64) / 7)) % 5 == 0 and d < r - 6:
        return 1
    return 2

def boulder(phase):
    """huge boulder of four x/y expanded sprites (96 x 84 pixels):
    top left, top right, bottom left, bottom right"""
    out = [Spr() for _ in range(4)]
    for py in range(42):
        for px in range(24):
            v = _rock(px * 4 + 2 - 48, py * 2 + 1 - 52, 50, phase)
            out[(py // 21) * 2 + px // 12].set(px % 12, py % 21, v)
    return out

def ball(phase):
    """a whole boulder in one x/y expanded sprite (title screen), at the bottom of the sprite:
    round rock with a highlight and two dents that roll around"""
    s = Spr()
    cx, cy, r = 24, 27, 15
    dents = [(math.cos(phase * 1.6 + k * 3.1) * 5 + 1, math.sin(phase * 1.6 + k * 3.1) * 4 + 2) for k in range(2)]
    for py in range(21):
        for px in range(12):
            x, y = px * 4 + 2 - cx, py * 2 + 1 - cy
            d = math.hypot(x, y)
            if d > r:
                continue
            v = 2
            if d > r - 3:
                v = 1
            elif x < -3 and y < -3 and d < r - 5:
                v = 3
            for dx, dy in dents:
                if math.hypot(x - dx, (y - dy) * 1.2) < 3.0:
                    v = 1
            s.set(px, py, v)
    return s

# ------------------------------------------------------------------ far objects: rectangles (colour 0 = dark, 3 = bright)
FAR_SHAPES = {
    # (u0, u1, v0, v1, colour)  - one rectangle each (obstacles in the ground colour, coins bright)
    'barrier': [(-0.42, 0.42, 0.12, 0.34, 1)],
    'bar':     [(-0.46, 0.46, 0.60, 0.84, 1)],
    'block':   [(-0.40, 0.40, 0.0, 0.70, 1)],
    'coin':    [(-0.10, 0.10, 0.06, 0.30, 3)],
    'power':   [(-0.18, 0.18, 0.06, 0.42, 3)],
}
FAR_ORDER = ['barrier', 'bar', 'block', 'coin', 'power']

def far_rects(kind, yb):
    """rectangles for an object with its base on line yb: list of (x0, x1, h0, h1, col) in
    MC pixels relative to the lane centre and lines above the base (inclusive)"""
    d = G.dxof(yb)
    out = []
    for u0, u1, v0, v1, col in FAR_SHAPES[kind]:
        x0 = int(math.floor(u0 * d / 2 + 0.5))
        x1 = int(math.floor(u1 * d / 2 - 0.5))
        if x1 < x0:
            x0 = x1 = int(round((u0 + u1) * d / 4))
        h0 = int(round(v0 * d))
        h1 = int(round(v1 * d)) - 1
        if h1 < h0:
            h1 = h0
        out.append((x0, x1, h0, h1, col))
    return out

# ------------------------------------------------------------------ scenery (rows 2-8: 160 x 56 multicolour pixels)
# colour slots: 0 sky ($D021), 1 = $D022, 2 = $D023, 3 = colour RAM
def scenery(zone):
    W, H = 160, 56
    img = [[0] * W for _ in range(H)]
    rnd = random.Random(zone * 17 + 3)
    def put(x, y, v):
        if 0 <= x < W and 0 <= y < H:
            img[y][x] = v
    def fill_col(x, y0, v):
        for y in range(max(0, y0), H):
            put(x, y, v)
    if zone == 0:       # temple halls: stepped temple, columns, distant hills
        for x in range(W):
            h = 44 + int(3 * math.sin(x / 9.0) + 2 * math.sin(x / 4.0))
            fill_col(x, h, 1)
        # stepped pyramid
        for step in range(6):
            w = 34 - step * 5
            y = 50 - step * 5
            for x in range(80 - w, 80 + w):
                for yy in range(y, y + 5):
                    put(x, yy, 2)
                put(x, y, 3)
        for x in range(74, 86):
            for y in range(14, 20):
                put(x, y, 2)
        for x in range(77, 83):
            for y in range(16, 20):
                put(x, y, 0)
        # columns left and right
        for cx in (12, 30, 130, 148):
            for x in range(cx - 3, cx + 4):
                fill_col(x, 22, 2)
                put(x, 22, 3)
                put(x, 23, 3)
            for x in range(cx - 1, cx + 1):
                for y in range(25, H):
                    if y % 6 < 4:
                        put(x, y, 1)
    elif zone == 1:     # jungle: palms over green hills
        for x in range(W):
            h = 40 + int(5 * math.sin(x / 13.0 + 1) + 3 * math.sin(x / 5.0))
            fill_col(x, h, 1)
            h2 = 47 + int(3 * math.sin(x / 7.0))
            for y in range(h2, H, 3):
                put(x, y, 3)
        for px in (14, 40, 66, 98, 126, 150):
            top = 14 + rnd.randint(0, 8)
            for y in range(top, 52):
                put(px + (y - top) // 12, y, 2)
            for a in range(6):
                ang = a * math.pi / 3 + 0.3
                for t in range(12):
                    x = px + int(t * math.cos(ang))
                    y = top + int(t * 0.5 * math.sin(ang) + t * t * 0.03)
                    put(x, y, 3)
                    put(x, y + 1, 3)
    elif zone == 2:     # canyon: mesas and rock spires
        for x in range(W):
            h = 46 + int(2 * math.sin(x / 6.0))
            fill_col(x, h, 2)
        for cx, w, top in ((22, 18, 16), (70, 10, 28), (110, 24, 12), (150, 8, 24)):
            for x in range(cx - w, cx + w):
                t = top + abs(x - cx) // 6
                fill_col(x, t, 1)
                put(x, t, 3)
                for y in range(t + 2, H, 7):
                    put(x, y, 2)
        for x in range(W):
            if x % 23 == 5:
                for y in range(30, 46):
                    put(x, y, 2)
    elif zone == 3:     # crystal mine: cave ceiling, stalactites, crystals
        for x in range(W):
            c = 6 + int(4 * math.sin(x / 7.0) + 3 * math.sin(x / 3.0))
            for y in range(0, c):
                put(x, y, 1)
            if x % 11 == 3:
                for y in range(c, c + 10 + (x % 5)):
                    if abs((y - c) * 0.25) < 3:
                        put(x, y, 1)
                        put(x + 1, y, 1)
            h = 46 + int(4 * math.sin(x / 9.0))
            fill_col(x, h, 1)
        for cx, h in ((20, 18), (52, 12), (90, 22), (128, 14), (150, 9)):
            for y in range(h):
                w = (h - y) // 3
                for x in range(cx - w, cx + w + 1):
                    put(x, 52 - y, 3 if x <= cx else 2)
    else:               # volcano with smoke
        for x in range(W):
            h = 48 + int(2 * math.sin(x / 5.0))
            fill_col(x, h, 1)
        for x in range(20, 140):
            t = 10 + abs(x - 80) * 38 // 60
            if abs(x - 80) < 7:
                t = 10 + (2 if abs(x - 80) < 4 else 0)
            fill_col(x, t, 1)
            if abs(x - 80) < 7:
                put(x, t, 3)
                put(x, t + 1, 3)
            if (x - 80) % 11 == 0 and 0 < abs(x - 80) < 40:
                for y in range(t + 1, 50):
                    put(x + (y - t) // 9, y, 3)
        rnd2 = random.Random(5)
        for i in range(26):
            cx = 80 + int(6 * math.sin(i * 0.6)) + i * 2
            cy = 8 - i // 3
            r = 2 + i // 6
            for dx in range(-r * 2, r * 2 + 1):
                for dy in range(-r, r + 1):
                    if (dx / 2.0) ** 2 + dy * dy <= r * r and rnd2.random() < 0.9:
                        put(cx + dx, cy + dy, 2)
    # last line (row 8, line 7) stays neutral: the colour split happens there
    for x in range(W):
        img[H - 1][x] = img[H - 2][x]
    return img

def scenery_chars(img):
    """cut 160x56 into 40x7 MC chars -> (list of 8-byte chars, map[7][40])"""
    chars = []
    ids = {}
    m = []
    for cy in range(7):
        row = []
        for cx in range(40):
            b = []
            for y in range(8):
                v = 0
                for i in range(4):
                    v = (v << 2) | img[cy * 8 + y][cx * 4 + i]
                b.append(v)
            b = bytes(b)
            if b not in ids:
                ids[b] = len(chars)
                chars.append(b)
            row.append(ids[b])
        m.append(row)
    return chars, m

# ------------------------------------------------------------------ zone palettes
# sky region: $D021, $D022, $D023, colour RAM (MC)   ground: $D021 (stripes), $D022, $D023, lines
ZONES = [
    # name,           sky: bg  -   -   cr      ground: bg(stripes) d22 d23 line
    # (the scenery uses $D022/$D023 of the ground: 01 = ground colour, 10 = track colour)
    ("TEMPLE HALLS",  (6, 11, 8, 7),           (9, 11, 8, 7)),
    ("JUNGLE PATH",   (14, 13, 8, 5),          (9, 13, 8, 7)),
    ("RED CANYON",    (8, 10, 9, 7),           (2, 10, 9, 7)),
    ("CRYSTAL MINE",  (0, 11, 6, 3),           (0, 11, 6, 3)),
    ("FIRE MOUNTAIN", (0, 9, 11, 2),           (2, 9, 11, 7)),
]

# ------------------------------------------------------------------ logo (slanted, speedy)
def logo_bitmap():
    Wg, Hg = 7, 14
    def glyph(ch):
        g = [[0] * Wg for _ in range(Hg)]
        def rect(x0, y0, x1, y1):
            for y in range(max(0, y0), min(Hg, y1 + 1)):
                for x in range(max(0, x0), min(Wg, x1 + 1)): g[y][x] = 1
        if ch == 'F':
            rect(0, 0, 1, 13); rect(0, 0, 6, 1); rect(0, 6, 4, 7)
        elif ch == 'L':
            rect(0, 0, 1, 13); rect(0, 12, 6, 13)
        elif ch == 'E':
            rect(0, 0, 1, 13); rect(0, 0, 6, 1); rect(0, 6, 4, 7); rect(0, 12, 6, 13)
        elif ch == 'T':
            rect(0, 0, 6, 1); rect(2, 0, 4, 13)
        elif ch == 'O':
            rect(1, 0, 5, 1); rect(1, 12, 5, 13); rect(0, 1, 1, 12); rect(5, 1, 6, 12)
        return g
    WT = 80; bm = [[0] * WT for _ in range(Hg + 2)]
    x = 2
    for ch in "FLEETFOOT":
        g = glyph(ch)
        for y in range(Hg):
            sl = (Hg - 1 - y) // 4          # italic slant
            for xx in range(Wg):
                if g[y][xx]: bm[y + 1][x + xx + sl] = 1
        x += Wg + 1
    return bm

# HUD icons (hires 8x8): magnet, boots, star, amulet, coin
ICONS = {
    'MAGNET': ["........", ".##..##.", ".##..##.", ".##..##.", ".##..##.", ".######.", "..####..", "........"],
    'BOOTS':  ["...##...", "...##.#.", "...####.", "...##.#.", "...##...", ".#####..", ".######.", "........"],
    'STAR':   ["...#....", "...#....", "#######.", ".#####..", "..###...", ".##.##..", ".#...#..", "........"],
    'AMULET': ["..###...", ".#...#..", ".#...#..", "..###...", ".#####..", ".##.##..", "..###...", "...#...."],
    'COIN':   "..####..|.#....#.|#..##..#|#.#....#|#.#....#|#..##..#|.#....#.|..####..".split('|'),
    'BAR0':   ["........"] * 2 + ["########"] * 4 + ["........"] * 2,
    'BAR1':   ["........"] * 2 + ["#......."] + ["#......."] * 2 + ["#......."] + ["........"] * 2,
}
