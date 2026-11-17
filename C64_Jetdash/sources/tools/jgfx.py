# JETDASH - graphics generator: lab tiles, coins, zappers, lasers, sprites, logo
# all designs are original
import math

# ------------------------------------------------------------------ multicolour chars
# pixel values: 0 background ($d021), 1 structure ($d022), 2 light ($d023), 3 yellow (colour RAM)
def mc_bytes(rows):
    out = []
    for r in rows:
        v = 0
        for k in range(4): v |= (r[k] & 3) << (6 - 2 * k)
        out.append(v)
    return bytes(out)

def from_strings(lines):
    """8 strings of 4 chars ('.123') -> 8 bytes"""
    m = {'.': 0, '1': 1, '2': 2, '3': 3}
    return mc_bytes([[m[c] for c in s] for s in lines])

class Pix:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.p = [[0] * w for _ in range(h)]
    def set(self, x, y, v):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h: self.p[y][x] = v
    def get(self, x, y):
        return self.p[y][x] if 0 <= x < self.w and 0 <= y < self.h else 0
    def rect(self, x0, y0, x1, y1, v):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1): self.set(x, y, v)
    def frame(self, x0, y0, x1, y1, v):
        self.rect(x0, y0, x1, y0, v); self.rect(x0, y1, x1, y1, v)
        self.rect(x0, y0, x0, y1, v); self.rect(x1, y0, x1, y1, v)
    def ellipse(self, cx, cy, rx, ry, v):
        for y in range(self.h):
            for x in range(self.w):
                if ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 <= 1: self.p[y][x] = v
    def chars(self):
        out = []
        for cy in range(self.h // 8):
            row = []
            for cx in range(self.w // 4):
                row.append(mc_bytes([[self.p[cy * 8 + y][cx * 4 + x] for x in range(4)] for y in range(8)]))
            out.append(row)
        return out

# ------------------------------------------------------------------ lab tiles
TW, TH = 32, 184          # 8 chars x 23 rows (screen rows 2..24)
CEIL, FLOOR = 8, 168       # first wall line, first floor line (tile pixel rows)

def base(kind='lab'):
    p = Pix(TW, TH)
    if kind == 'sky':
        # grass and a sand path, no ceiling
        for x in range(TW):
            h = (2, 4, 3, 1)[x % 4]
            p.rect(x, FLOOR - h + 2, x, FLOOR + 1, 2)
        p.rect(0, FLOOR + 2, TW - 1, TH - 1, 3)
        for x in range(1, TW, 4):
            p.set(x, FLOOR + 6, 1); p.set(x + 2, FLOOR + 11, 1)
        return p
    # ceiling girder
    p.rect(0, 0, TW - 1, 4, 1)
    p.rect(0, 5, TW - 1, 5, 2)
    for x in range(3, TW, 8):
        p.set(x, 2, 2)
    for x in range(0, TW, 4):
        p.set(x, 6, 1)
    # wall: panel seam, rail, skirting
    p.rect(0, CEIL, 0, FLOOR - 1, 1)
    p.rect(1, 120, TW - 1, 120, 1)
    p.rect(1, 121, TW - 1, 121, 2)
    p.rect(0, 160, TW - 1, 160, 2)
    p.rect(0, 161, TW - 1, 167, 1)
    for x in range(4, TW, 8):
        p.rect(x, 163, x + 1, 164, 0)
    # floor: hazard stripes and plates
    p.rect(0, FLOOR, TW - 1, FLOOR, 2)
    for y in range(FLOOR + 1, FLOOR + 7):
        for x in range(TW):
            p.set(x, y, 3 if ((x + y) // 3) % 2 == 0 else 1)
    p.rect(0, FLOOR + 7, TW - 1, FLOOR + 7, 0)
    p.rect(0, FLOOR + 8, TW - 1, TH - 1, 1)
    for x in range(2, TW, 8):
        p.set(x, FLOOR + 11, 2); p.set(x + 4, FLOOR + 13, 2)
    return p

def lamp(p, x):
    """ceiling lamp, x on a char boundary (2 chars wide)"""
    p.rect(x, 6, x + 7, 7, 1)
    p.rect(x + 1, 8, x + 6, 8, 2)
    p.rect(x + 2, 9, x + 5, 9, 3)

def window(p):          # chars 1..6, rows 3..9 (tile rows)
    lamp(p, 12)
    p.frame(4, 24, 27, 79, 1)
    p.rect(4, 48, 27, 48, 1)
    p.rect(15, 24, 16, 79, 1)
    for y in range(28, 76, 8):
        p.set(6, y, 2); p.set(7, y + 1, 2)
    p.rect(4, 80, 27, 80, 2)

def pipes(p):
    for y0 in (40, 104):
        p.rect(1, y0, TW - 1, y0, 2)
        p.rect(1, y0 + 1, TW - 1, y0 + 4, 1)
        for x in (8, 24):
            p.rect(x, y0 - 2, x + 3, y0 + 6, 2)
            p.rect(x + 1, y0 - 1, x + 2, y0 + 5, 1)

def sign(p):            # arrow sign, chars 2..5, rows 7..8
    lamp(p, 4)
    p.rect(8, 56, 23, 71, 1)
    p.frame(8, 56, 23, 71, 2)
    p.rect(11, 62, 17, 65, 2)
    for y in range(59, 69):
        d = abs(y - 63.5)
        p.rect(18, y, 21 - int(d * 0.6), y, 2)

def shelf(p):           # lab: chemistry shelf with flasks
    lamp(p, 20)
    p.rect(0, 104, TW - 1, 105, 2)
    p.rect(0, 106, TW - 1, 106, 1)
    for x in (4, 12, 20, 28):
        p.rect(x + 1, 90, x + 2, 93, 2)
        p.rect(x, 94, x + 3, 103, 2)
        p.rect(x + 1, 98, x + 2, 102, 3)

def crates(p):          # storage: stacked crates (4 x 3 chars each)
    lamp(p, 12)
    def crate(x, y):
        p.rect(x, y, x + 15, y + 23, 1)
        p.frame(x, y, x + 15, y + 23, 2)
        p.rect(x + 1, y + 8, x + 14, y + 8, 0)
        p.rect(x + 1, y + 16, x + 14, y + 16, 0)
    crate(0, 136); crate(16, 136); crate(8, 112)

def plant(p):           # greenhouse: potted bush
    lamp(p, 0)
    p.rect(8, 144, 23, 159, 1)
    p.rect(8, 144, 23, 145, 2)
    p.rect(14, 128, 17, 143, 1)
    for y in range(96, 136):
        for x in range(4, 28):
            edge = (y < 104 and (x < 8 or x > 23)) or (y > 127 and (x < 8 or x > 23))
            if edge: continue
            p.set(x, y, 2 if (x % 4 == 1 and y % 8 in (2, 3)) or (x % 4 == 3 and y % 8 in (6, 7)) else 1)

def barrels(p):         # reactor: barrels (3 chars wide)
    lamp(p, 20)
    for x0 in (4, 16):
        p.rect(x0, 136, x0 + 11, 159, 3)
        p.rect(x0, 136, x0 + 11, 136, 2)
        for y in (144, 152):
            p.rect(x0, y, x0 + 11, y, 1)

def rack(p):            # server hall: cabinet with blinking lights
    p.rect(4, 24, 27, 159, 1)
    p.frame(4, 24, 27, 159, 2)
    for y in range(32, 152, 8):
        p.rect(8, y + 1, 23, y + 4, 0)
        p.set(9, y + 2, 3); p.set(13, y + 2, 2)
        p.rect(17, y + 3, 22, y + 3, 1)

CLOUD = ["....111111......",
         "..1111111111....",
         ".111111111111...",
         "1111111111111111",
         "1111111111111111",
         ".11111111111111.",
         "................",
         "................"]
def clouds(p, seed):
    pos = {'sky0': [(0, 32), (16, 96)], 'sky1': [(8, 56)], 'sky2': [(16, 24), (0, 120)]}[seed]
    for (x0, y0) in pos:
        for y, row in enumerate(CLOUD):
            for x, c in enumerate(row):
                if c == '1': p.set(x0 + x, y0 + y, 1)

def gate(p):            # bulkhead / exit door frame (2 chars wide)
    p.rect(0, 0, 7, TH - 1, 1)
    p.rect(0, 0, 0, TH - 1, 2)
    p.rect(7, 0, 7, TH - 1, 2)
    for y in range(0, TH, 16):
        p.rect(2, y + 2, 5, y + 5, 3)

def make_tile(kind):
    if kind.startswith('sky'):
        p = base('sky')
        clouds(p, kind)
        return p
    p = base()
    {'plain': lambda q: lamp(q, 12), 'window': window, 'pipes': pipes, 'sign': sign,
     'shelf': shelf, 'crates': crates, 'plant': plant, 'barrels': barrels, 'rack': rack,
     'gate': gate}[kind](p)
    return p

# zone tile sets: 8 entries each (picked by a random 3-bit value per 8 columns)
ZONE_NAMES = ['LAB', 'STORAGE', 'GREENHOUSE', 'REACTOR', 'SERVER HALL', 'OUTSIDE']
ZONE_TILES = [
    ['plain', 'window', 'pipes', 'shelf', 'shelf', 'window', 'sign', 'plain'],
    ['plain', 'crates', 'pipes', 'crates', 'crates', 'window', 'sign', 'plain'],
    ['plain', 'plant', 'window', 'plant', 'plant', 'pipes', 'sign', 'plant'],
    ['plain', 'barrels', 'pipes', 'barrels', 'barrels', 'sign', 'pipes', 'plain'],
    ['plain', 'rack', 'pipes', 'rack', 'window', 'rack', 'sign', 'rack'],
    ['sky0', 'sky1', 'sky2', 'sky0', 'sky1', 'sky2', 'sky0', 'sky1'],
]
TILE_KINDS = []
for zt in ZONE_TILES:
    for k in zt:
        if k not in TILE_KINDS: TILE_KINDS.append(k)
TILE_KINDS.append('gate')

# ------------------------------------------------------------------ objects in the playfield
COIN_FRAMES = [
    ["....", ".33.", "3323", "3323", "3333", "3313", ".33.", "...."],
    ["....", ".33.", ".32.", ".32.", ".33.", ".31.", ".33.", "...."],
    ["....", "..3.", "..2.", "..3.", "..3.", "..3.", "..3.", "...."],
    ["....", ".33.", ".23.", ".23.", ".33.", ".13.", ".33.", "...."],
]
# zapper beams (2 frames each): H, V, D (\), U (/), node
def zap_chars(f):
    H = ["....", "3.3." if f else ".3.3", "3333", "2222", "2222", "3333", ".3.3" if f else "3.3.", "...."]
    V = ["3223" if (y + f) % 3 else ".22." for y in range(8)]
    V = [s if (y + f) % 2 else s.replace('3', '.', 1) for y, s in enumerate(V)]
    D, U = [], []
    for y in range(8):
        x = y // 2
        r = ['.'] * 4
        r[x] = '2'
        if x + 1 < 4 and (y + f) % 2 == 0: r[x + 1] = '3'
        if x - 1 >= 0 and (y + f) % 2 == 1: r[x - 1] = '3'
        D.append(''.join(r))
        U.append(''.join(r[::-1]))
    N = ["....", ".22.", "2332", "3333" if f else "2332", "2332" if f else "3333", "2332", ".22.", "...."]
    return [from_strings(c) for c in (H, V, D, U, N)]

LASER_WARN = [from_strings(["....", "....", "....", "3...", "3...", "....", "....", "...."]),
              from_strings(["....", "....", "....", "..3.", "..3.", "....", "....", "...."])]
LASER_BEAM = [from_strings(["....", "3333", "2222", "2222", "2222", "2222", "3333", "...."]),
              from_strings(["....", "....", "3333", "2222", "2222", "3333", "....", "...."])]

# ------------------------------------------------------------------ sprites
class MCSpr:
    def __init__(self):
        self.p = [[0] * 12 for _ in range(21)]
    def set(self, x, y, v):
        x, y = int(x), int(y)
        if 0 <= x < 12 and 0 <= y < 21: self.p[y][x] = v
    def get(self, x, y):
        return self.p[y][x] if 0 <= x < 12 and 0 <= y < 21 else 0
    def rect(self, x0, y0, x1, y1, v):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1): self.set(x, y, v)
    def ellipse(self, cx, cy, rx, ry, v):
        for y in range(21):
            for x in range(12):
                if ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 <= 1: self.p[y][x] = v
    def tobytes(self):
        out = bytearray()
        for y in range(21):
            for b in range(3):
                v = 0
                for k in range(4): v |= self.p[y][b * 4 + k] << (6 - 2 * k)
                out.append(v)
        out.append(0)
        return bytes(out)
    def hflip(self):
        s = MCSpr(); s.p = [r[::-1] for r in self.p]; return s
    def vflip(self):
        s = MCSpr(); s.p = [r[:] for r in self.p[::-1]]; return s

class HSpr:
    def __init__(self):
        self.p = [[0] * 24 for _ in range(21)]
    def set(self, x, y, v=1):
        x, y = int(x), int(y)
        if 0 <= x < 24 and 0 <= y < 21: self.p[y][x] = v
    def tobytes(self):
        out = bytearray()
        for y in range(21):
            for b in range(3):
                v = 0
                for k in range(8): v |= self.p[y][b * 8 + k] << (7 - k)
                out.append(v)
        out.append(0)
        return bytes(out)
    def hflip(self):
        s = HSpr(); s.p = [r[::-1] for r in self.p]; return s
    def vflip(self):
        s = HSpr(); s.p = [r[:] for r in self.p[::-1]]; return s

def outline_of(mc, extra=()):
    mask = [[mc.p[y][x // 2] != 0 for x in range(24)] for y in range(21)]
    h = HSpr()
    for y in range(21):
        for x in range(24):
            if mask[y][x]: continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < 24 and 0 <= yy < 21 and mask[yy][xx]:
                    h.set(x, y); break
    for (x, y) in extra: h.set(x, y)
    return h

# shared sprite colours: 1 = $d025 orange, 3 = $d026 white, 2 = own colour
def hero(pose, phase=0):
    """the courier facing right: helmet (white), suit (own colour), jetpack (orange)"""
    s = MCSpr()
    # legs
    if pose == 'run':
        legs = [((4, 15, 4, 18), (7, 15, 8, 17)), ((5, 15, 5, 19), (7, 15, 7, 19)),
                ((5, 15, 5, 17), (6, 15, 7, 19)), ((4, 15, 5, 19), (7, 15, 8, 18))][phase]
    elif pose == 'fly':
        legs = ((4, 15, 4, 18), (6, 15, 7, 17))
    else:
        legs = ((5, 15, 5, 19), (7, 15, 7, 19))
    for (x0, y0, x1, y1) in legs:
        s.rect(x0, y0, x1, y1, 2)
        s.rect(x1, y1, x1 + 1, y1, 3)        # boots
    # torso
    s.rect(4, 8, 8, 15, 2)
    s.rect(5, 7, 7, 7, 2)
    # arm
    if pose == 'run':
        ax = [(9, 10), (8, 12), (9, 11), (9, 13)][phase]
        s.rect(8, 9, ax[0], ax[1], 2)
    else:
        s.rect(8, 9, 9, 10, 2); s.rect(9, 10, 10, 10, 2)
    # jetpack on the back
    s.rect(1, 7, 3, 14, 1)
    s.rect(2, 8, 2, 13, 3)
    s.rect(1, 15, 2, 15, 1)
    # helmet
    s.ellipse(6.6, 3.6, 3.3, 3.4, 3)
    # visor (hires overlay pixels), shine left white
    vis = [(x, y) for y in range(2, 6) for x in range(14, 19) if not (x == 14 and y in (2, 5))]
    h = outline_of(s, vis)
    h.set(15, 2, 0)
    if pose == 'dead':
        for (x, y) in vis: h.set(x, y, 0)
        for d in range(4):
            h.set(14 + d, 2 + d); h.set(17 - d, 2 + d)
    return s, h

def hero_frames():
    fr = [hero('run', i) for i in range(4)]
    fr.append(hero('fly'))
    fr.append(hero('dead'))
    # tumbling: rotated by 90 degrees (lying)
    s, h = hero('dead')
    s2, h2 = MCSpr(), HSpr()
    for y in range(21):
        for x in range(12):
            v = s.p[y][x]
            if v:
                X, Y = int(y * 12 / 21 + 0.5), 20 - int(x * 21 / 12 * 0.55) - 3
                s2.set(X, Y, v); s2.set(X, Y - 1, v)
    h2 = outline_of(s2)
    fr.append((s2, h2))
    return fr                 # 0..3 run, 4 fly, 5 dead (upright), 6 lying

def flame(phase):
    """jetpack exhaust with sparks: placed 15 lines below the hero top"""
    s = MCSpr()
    lens = [9, 12, 10][phase]
    for y in range(lens):
        w = 1.4 - y * 0.08
        cx = 2.0
        for x in range(12):
            if abs(x + .5 - cx) <= max(.6, w):
                s.set(x, y, 3 if y < 3 else (2 if y < lens - 3 else 1))
    import random
    r = random.Random(phase * 17 + 5)
    for k in range(5):
        x = r.randint(0, 5); y = r.randint(4, 20)
        s.set(x, y, 3); s.set(x, y + 1, 2)
    return s

def rotor(phase):
    """copter rotor: white blades (rows 14..16), mast (17..20) in the own colour"""
    s = MCSpr()
    s.rect(5, 16, 6, 20, 2)
    s.rect(4, 15, 7, 15, 2)
    if phase == 0:
        s.rect(0, 14, 11, 14, 3); s.rect(1, 13, 4, 13, 3); s.rect(7, 13, 10, 13, 3)
    else:
        s.rect(3, 14, 8, 14, 3); s.rect(4, 13, 7, 13, 3)
    return s

def belt_glow(phase):
    s = MCSpr()
    for k in range(6):
        x = (k * 2 + phase) % 11
        y = 1 + ((k * 5 + phase * 3) % 5)
        s.set(x, y, 3 if k % 2 else 2)
        s.set(x, y + 1, 2)
    s.rect(3, 0, 8, 0, 3)
    return s

def worker(kind, phase=0):
    """lab worker in a yellow hazmat suit (own colour), white mask, orange boots and gloves"""
    s = MCSpr()
    if kind == 'down':
        s.rect(0, 16, 9, 19, 2)
        s.ellipse(10, 17.5, 2.2, 2.2, 3)
        s.rect(0, 16, 1, 19, 1)
        s.set(11, 15, 3); s.set(9, 14, 3)
        h = outline_of(s, [(21, 16), (21, 18)])
        return s, h
    s.ellipse(6, 4.5, 3, 3.5, 2)              # hood
    s.rect(5, 3, 8, 6, 3)                     # mask window
    s.rect(3, 8, 8, 15, 2)                    # body
    if phase == 0:
        s.rect(3, 16, 4, 19, 2); s.rect(7, 16, 8, 19, 2)
        s.rect(2, 20, 4, 20, 1); s.rect(7, 20, 9, 20, 1)
        s.rect(2, 9, 2, 13, 2); s.set(2, 14, 1)
        s.rect(9, 9, 9, 13, 2); s.set(9, 14, 1)
    else:
        s.rect(5, 16, 6, 19, 2)
        s.rect(4, 20, 7, 20, 1)
        s.rect(2, 9, 2, 12, 2); s.set(1, 13, 1)
        s.rect(9, 9, 10, 11, 2); s.set(10, 12, 1)
    s.rect(3, 15, 8, 15, 1)                   # belt
    h = outline_of(s, [(14, 4), (15, 4)])     # goggles
    return s, h

def missile(phase):
    s = MCSpr()
    s.rect(2, 8, 9, 12, 2)
    s.ellipse(2, 10.5, 2, 2.5, 1)
    s.rect(8, 6, 9, 7, 3); s.rect(8, 13, 9, 14, 3)
    s.rect(4, 9, 6, 9, 3)
    if phase == 0:
        s.rect(10, 9, 11, 11, 1); s.set(11, 10, 3)
    else:
        s.rect(10, 9, 10, 11, 1); s.set(11, 10, 1)
    return s

def warning(phase):
    """missile warning: ring with an exclamation mark (multicolour)"""
    s = MCSpr()
    for y in range(21):
        for x in range(12):
            d = ((x + .5 - 6) / 5.6) ** 2 + ((y + .5 - 10.5) / 9.8) ** 2
            if d <= 1 and (phase or d >= 0.6): s.set(x, y, 2)
    for y in list(range(4, 13)) + [15, 16]:
        s.set(5, y, 3); s.set(6, y, 3)
    return s

def box(phase):
    s = MCSpr()
    s.rect(1, 5, 10, 17, 2)
    s.rect(1, 5, 10, 6, 1)
    s.rect(1, 16, 10, 17, 1)
    q = ["2222", "3..3", "...3", "..3.", ".3..", "....", ".3.."]
    q = ["3333", "3..3", "...3", "..33", ".33.", "....", ".33."]
    for y, row in enumerate(q):
        for x, c in enumerate(row):
            if c == '3': s.set(4 + x, 7 + y, 3)
    if phase:
        s.set(0, 3, 3); s.set(11, 19, 3); s.set(11, 2, 3)
    return s

def explosion(phase):
    s = MCSpr()
    import random
    r = random.Random(phase * 31 + 7)
    rad = [4, 6, 7.5][phase]
    s.ellipse(6, 10.5, rad * 0.55, rad, 1)
    s.ellipse(6, 10.5, rad * 0.4, rad * 0.7, 2)
    if phase < 2: s.ellipse(6, 10.5, rad * 0.22, rad * 0.4, 3)
    for k in range(10 if phase else 4):
        a = r.random() * 6.28; d = rad + r.random() * 3
        s.set(6 + math.cos(a) * d * 0.55, 10.5 + math.sin(a) * d, 3 if k % 2 else 1)
    return s

def emitter(phase):
    s = MCSpr()
    s.rect(0, 5, 5, 15, 2)
    s.rect(0, 5, 5, 5, 3)
    s.rect(6, 8, 8, 12, 2)
    s.rect(9, 9, 9, 11, 1 if phase == 0 else 3)
    if phase:
        s.rect(10, 9, 11, 11, 3)
    s.rect(1, 8, 2, 12, 1)
    return s

# ------------------------------------------------------------------ logo
def logo_bitmap():
    W, H = 10, 14
    def glyph(ch):
        g = [[0] * W for _ in range(H)]
        def rect(x0, y0, x1, y1):
            for y in range(max(0, y0), min(H, y1 + 1)):
                for x in range(max(0, x0), min(W, x1 + 1)): g[y][x] = 1
        if ch == 'J':
            rect(2, 0, 9, 2); rect(6, 0, 8, 12); rect(0, 9, 2, 12); rect(1, 11, 7, 13)
        elif ch == 'E':
            rect(0, 0, 2, 13); rect(0, 0, 9, 2); rect(0, 6, 7, 8); rect(0, 11, 9, 13)
        elif ch == 'T':
            rect(0, 0, 9, 2); rect(3, 0, 5, 13)
        elif ch == 'D':
            rect(0, 0, 2, 13); rect(0, 0, 7, 2); rect(0, 11, 7, 13); rect(7, 1, 9, 12)
        elif ch == 'A':
            rect(0, 2, 2, 13); rect(7, 2, 9, 13); rect(1, 0, 8, 2); rect(0, 7, 9, 9)
        elif ch == 'S':
            rect(1, 0, 9, 2); rect(0, 1, 2, 6); rect(1, 5, 8, 7); rect(7, 6, 9, 12); rect(0, 11, 8, 13)
        elif ch == 'H':
            rect(0, 0, 2, 13); rect(7, 0, 9, 13); rect(0, 5, 9, 8)
        return g
    WT = 80; bm = [[0] * WT for _ in range(H + 2)]
    x = 2
    for i, ch in enumerate("JETDASH"):
        g = glyph(ch)
        slant = 0
        for y in range(H):
            for xx in range(W):
                if g[y][xx]:
                    X = x + xx + (H - 1 - y) // 5      # italic: speed!
                    if 0 <= X < WT: bm[y + 1][X] = 1
        x += W + 1
    # speed lines left of the J
    return bm
