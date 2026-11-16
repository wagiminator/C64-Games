# THORN - original garden & undead graphics
# chars: multicolour, roles 0=bg ($d021), 1=$d022 light green, 2=$d023 black, 3=colour RAM (0..7)
import math, random
from gfx import Spr, big_slices

COL = {'y': 7, 'G': 5, 'r': 2, 'c': 3, 'w': 1, 'p': 4, 'b': 6, 'K': 0}

class MC:
    """multicolour char image; pixels: 0, 1, 2 or a colour letter (role 3)"""
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.p = [[0] * w for _ in range(h)]
    def set(self, x, y, v):
        x = int(round(x)); y = int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h: self.p[y][x] = v
    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h: return self.p[y][x]
        return 0
    def ell(self, cx, cy, rx, ry, v):
        for y in range(self.h):
            for x in range(self.w):
                dx = (x + .5 - cx) / rx; dy = (y + .5 - cy) / ry
                if dx * dx + dy * dy <= 1: self.p[y][x] = v
    def rect(self, x0, y0, x1, y1, v):
        for y in range(max(0, y0), min(self.h, y1 + 1)):
            for x in range(max(0, x0), min(self.w, x1 + 1)): self.p[y][x] = v
    def line(self, x0, y0, x1, y1, v):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            t = i / n; self.set(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, v)
    def outline(self):
        q = [r[:] for r in self.p]
        for y in range(self.h):
            for x in range(self.w):
                if self.p[y][x] in (0, 1):
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        v = self.get(x + dx, y + dy)
                        if v not in (0, 1, 2):
                            q[y][x] = 2; break
        self.p = q
        return self
    def chars(self):
        """-> list of (8 bytes, colour) row-major per 4x8 cell"""
        out = []
        for cy in range(self.h // 8):
            for cx in range(self.w // 4):
                cols = {}
                for y in range(8):
                    for x in range(4):
                        v = self.p[cy * 8 + y][cx * 4 + x]
                        if isinstance(v, str): cols[v] = cols.get(v, 0) + 1
                main = max(cols, key=cols.get) if cols else 'G'
                data = bytearray(8)
                for y in range(8):
                    b = 0
                    for x in range(4):
                        v = self.p[cy * 8 + y][cx * 4 + x]
                        if isinstance(v, str): role = 3 if v == main else 2
                        else: role = v
                        b |= role << (6 - 2 * x)
                    data[y] = b
                out.append((bytes(data), COL[main]))
        return out

# ------------------------------------------------------------- plants (16 x 24 MC pixels = 4 x 3 chars)
def leaves(c, ph):
    for (x0, d) in ((7, -1), (8, 1)):
        for i in range(5):
            c.set(x0 + d * i, 22 - i // 2 - (ph if d > 0 else 0), 'G')
            c.set(x0 + d * i, 23 - i // 2, 1)
    c.rect(5, 23, 10, 23, 'G')

def sunbloom(ph):
    c = MC(16, 24)
    c.rect(7, 12, 8, 22, 'G'); leaves(c, ph)
    cx, cy = 7.5 + (0.5 if ph else -0.5), 7
    for k in range(10):
        a = k * math.tau / 10 + (0.3 if ph else 0)
        c.ell(cx + math.cos(a) * 4.6, cy + math.sin(a) * 4.6, 1.9, 1.9, 'y')
    c.ell(cx, cy, 3.8, 3.8, 'y')
    c.outline()
    c.set(cx - 1.5, cy - 1, 2); c.set(cx + 1.5, cy - 1, 2)
    c.line(cx - 1.5, cy + 1.5, cx + 1.5, cy + 1.5, 2)
    return c

def spitter(ph, col='G', twin=False):
    c = MC(16, 24)
    c.rect(5, 15, 6, 22, 'G'); leaves(c, ph)
    hx = 6 - (1 if ph else 0)
    if twin:
        c.ell(hx, 6, 4.2, 3.8, col); c.rect(hx + 2, 4, 14 - ph, 7, col); c.ell(14.5 - ph, 5.5, 1.2, 2.2, col)
    c.ell(hx, 12, 5, 4.6, col)
    c.rect(hx + 3, 10, 14 - ph, 13, col)
    c.ell(14.5 - ph, 11.5, 1.4, 2.6, col)
    c.outline()
    c.set(15 - ph, 11, 2); c.set(15 - ph, 12, 2)
    c.set(hx + 1, 10, 2); c.set(hx + 2, 10, 2); c.set(hx + 1, 9, 1)
    if twin:
        c.set(15 - ph, 5, 2); c.set(15 - ph, 6, 2); c.set(hx + 1, 5, 2)
    c.set(hx - 3, 9, 1); c.set(hx - 2, 8, 1)
    if col == 'c':
        for (x, y) in ((hx - 2, 7), (hx, 6), (hx + 2, 7)): c.set(x, y, 1)
    return c

def rocknut(ph):
    c = MC(16, 24)
    c.ell(8, 13, 6.6, 10.4, 'y')
    c.outline()
    for (x, y) in ((4, 8), (5, 10), (11, 16), (12, 18), (9, 20)): c.set(x, y, 2)
    if ph:
        c.line(5, 11, 7, 11, 2); c.line(9, 11, 11, 11, 2)
    else:
        for ex in (6, 10):
            c.set(ex, 10, 2); c.set(ex, 11, 2); c.set(ex - 1, 10, 1)
    c.line(6, 16, 10, 16, 2)
    return c

def boomberry(ph):
    c = MC(16, 24)
    o = 1 if ph else 0
    c.line(5 + o, 12, 8, 3, 'G'); c.line(11 - o, 12, 8, 3, 'G')
    c.ell(8, 2.5, 3, 1.4, 'G')
    for (cx, cy) in ((4.5 + o, 16), (11.5 - o, 17)):
        c.ell(cx, cy, 4.2, 4.6, 'r')
    c.outline()
    for (cx, cy) in ((4.5 + o, 16), (11.5 - o, 17)):
        c.set(cx - 1, cy - 1, 2); c.set(cx + 1, cy - 1, 2); c.line(cx - 1, cy + 1.5, cx + 1, cy + 1.5, 2)
        c.set(cx - 2, cy - 3, 1)
    return c

PLANTS = [sunbloom, lambda ph: spitter(ph), rocknut, boomberry, lambda ph: spitter(ph, 'c'), lambda ph: spitter(ph, 'G', True)]
PLANT_NAMES = ['SUNBLOOM', 'SPITTER', 'ROCKNUT', 'BOOMBERRY', 'FROSTPOD', 'TWINSPIT']

def icon(i):
    """2x2 chars mini picture of plant i"""
    c = MC(8, 16)
    if i == 0:
        for k in range(8):
            a = k * math.tau / 8
            c.ell(4 + math.cos(a) * 2.6, 6 + math.sin(a) * 2.6, 1.2, 1.4, 'y')
        c.ell(4, 6, 2.2, 2.4, 'y'); c.rect(3, 10, 4, 15, 'G')
        c.outline(); c.set(3, 6, 2); c.set(5, 6, 2)
    elif i in (1, 4, 5):
        col = 'c' if i == 4 else 'G'
        c.rect(2, 11, 3, 15, 'G')
        if i == 5: c.ell(3, 3.5, 2.2, 2.2, col); c.rect(4, 2, 7, 4, col)
        c.ell(3, 8, 2.8, 2.8, col); c.rect(4, 7, 7, 9, col)
        c.outline(); c.set(7, 8, 2); c.set(3, 7, 2)
    elif i == 2:
        c.ell(4, 8.5, 3.4, 6.5, 'y'); c.outline(); c.set(3, 7, 2); c.set(5, 7, 2)
    elif i == 3:
        c.line(2, 9, 4, 3, 'G'); c.line(6, 9, 4, 3, 'G')
        c.ell(2.5, 11, 2.2, 2.6, 'r'); c.ell(6, 12, 2.2, 2.6, 'r'); c.outline()
    return c

def sun_icon():
    c = MC(8, 16)
    for k in range(8):
        a = k * math.tau / 8
        c.line(4 + math.cos(a) * 2, 8 + math.sin(a) * 4, 4 + math.cos(a) * 3.6, 8 + math.sin(a) * 7, 'y')
    c.ell(4, 8, 2.4, 4.6, 'y')
    return c

def shovel_icon():
    c = MC(8, 16)
    c.rect(3, 1, 4, 8, 'w'); c.rect(2, 1, 5, 2, 'w')
    c.ell(3.8, 11.5, 2.6, 4, 'w'); c.outline()
    return c

def grass(shade):
    c = MC(4, 8)
    rnd = random.Random(3 + shade)
    n = 9 if shade == 0 else 4
    for k in range(n):
        x = rnd.randrange(4); y = rnd.randrange(8)
        c.set(x, y, 1)
        if shade == 0 and k % 2: c.set(x, (y + 1) % 8, 1)
    return c

def pea_chars(shade):
    """8 chars: 4 shifts x (left, right); pea = role 3 with black rim"""
    g = grass(shade)
    out = []
    for s in range(4):
        big = MC(8, 8)
        for y in range(8):
            for x in range(8): big.p[y][x] = g.p[y][x % 4]
        shape = [".k.", "kXk", "XXX", "XXX", "kXk", ".k."]
        for yy, row in enumerate(shape):
            for xx, ch in enumerate(row):
                if ch == 'X': big.set(s + xx, 1 + yy, 'G')
                elif ch == 'k': big.set(s + xx, 1 + yy, 2)
        for half in range(2):
            sub = MC(4, 8)
            for y in range(8):
                for x in range(4): sub.p[y][x] = big.p[y][half * 4 + x]
            out.append(sub.chars()[0])
    return out

def mower():
    c = MC(12, 16)
    c.line(0, 1, 4, 8, 'w'); c.set(0, 0, 'w'); c.set(1, 0, 'w')
    c.rect(3, 8, 11, 12, 'r'); c.rect(5, 7, 10, 7, 'r')
    c.ell(4, 14, 1.8, 2, 'K'); c.ell(10, 14, 1.8, 2, 'K')
    c.outline()
    return c

def patio(kind):
    c = MC(4, 8)
    if kind == 0:     # house wall
        for y in range(8):
            for x in range(4): c.p[y][x] = 'r'
        for x in range(4): c.p[3][x] = 2; c.p[7][x] = 2
        c.p[1][1] = 2; c.p[5][3] = 2
    else:             # stone path
        for y in range(8):
            for x in range(4): c.p[y][x] = 'w' if (x + y) % 5 else 2
        c.p[7] = [2, 2, 2, 2]
    return c

# ------------------------------------------------------------- sprites (values 1 black, 2 sprite colour, 3 light grey)
def zombie(kind, frame):
    """kind 0 walker, 1 helmet, 2 knight, 3 sprinter; frame 0/1 walk, 2/3 eat"""
    s = Spr()
    eat = frame >= 2; ph = frame & 1
    lean = 1 if kind == 3 else 0
    hx = 5 - lean - (1 if eat else 0)
    # legs
    if kind == 3:
        legs = [((6, 14), (3 + ph * 3, 20)), ((7, 14), (9 - ph * 3, 20))]
    else:
        legs = [((6, 14), (5 - ph, 20)), ((8, 14), (8 + ph, 20))]
    for (a, b) in legs:
        s.line(a[0], a[1], b[0], b[1], 1); s.line(a[0] + 1, a[1], b[0] + 1, b[1], 1)
        s.set(b[0] - 1, 20, 1)
    # torso
    s.rect(5 - lean, 8, 9 - lean, 14, 3)
    s.rect(7 - lean, 9, 7 - lean, 13, 1)
    s.rect(9 - lean, 8, 9 - lean, 14, 1)
    # arms reaching left
    ay = 9 + (1 if eat and ph else 0)
    s.line(5 - lean, ay, 0 + (1 if eat else 0), ay + (0 if not eat else -1), 2)
    s.line(5 - lean, ay + 1, 0 + (1 if eat else 0), ay + 1, 2)
    # head
    s.ellipse(hx + 2, 4.5, 3.2, 3.6, 2)
    s.rect(hx + 1, 0, hx + 4, 1, 1)
    s.set(hx + 1, 4, 3); s.set(hx + 1, 3, 3); s.set(hx, 4, 1)
    if eat and ph:
        s.rect(hx - 1, 6, hx + 1, 7, 1)
    else:
        s.line(hx - 0.5, 6.5, hx + 1.5, 6.5, 1)
    if kind == 1:          # helmet
        s.ellipse(hx + 2.4, 2.2, 3.8, 2.6, 3); s.rect(hx - 1, 2, hx + 6, 2, 3)
    if kind == 2:          # bucket / knight helm
        s.rect(hx - 0, 0, hx + 5, 5, 3); s.rect(hx - 1, 5, hx + 6, 5, 3); s.rect(hx, 3, hx + 2, 3, 1)
    return s.outline()

def zombie_down(f):
    s = Spr()
    if f == 0:
        s.rect(4, 8, 9, 14, 3); s.ellipse(7, 5, 3, 3.4, 2); s.rect(5, 14, 8, 20, 1)
    elif f == 1:
        s.rect(2, 13, 9, 17, 3); s.ellipse(2, 15, 2.6, 2.4, 2); s.rect(9, 15, 11, 18, 1)
    else:
        s.rect(1, 17, 10, 19, 3); s.ellipse(1.5, 18, 1.8, 1.8, 2); s.rect(10, 18, 11, 20, 1)
    return s.outline()

def sun(f):
    s = Spr()
    for k in range(8):
        a = k * math.tau / 8 + (math.pi / 8 if f else 0)
        s.line(6 + math.cos(a) * 3.2, 10 + math.sin(a) * 6.4, 6 + math.cos(a) * 5.2, 10 + math.sin(a) * 9.8, 2)
    s.ellipse(6, 10, 3.6, 6.6, 2)
    s.ellipse(5, 8, 1.4, 2.4, 3)
    return s.outline()

def mower_spr():
    s = Spr()
    s.line(0, 6, 3, 12, 3); s.rect(2, 12, 11, 16, 2); s.rect(4, 11, 10, 11, 2)
    s.ellipse(3, 18.5, 1.8, 2.4, 1); s.ellipse(10, 18.5, 1.8, 2.4, 1)
    return s.outline()

def explosion(f):
    s = Spr(); rnd = random.Random(7)
    r = 3 + f * 2.6
    for k in range(40):
        a = rnd.uniform(0, math.tau); d = r * math.sqrt(rnd.random())
        s.ellipse(6 + math.cos(a) * d * 0.55, 10.5 + math.sin(a) * d, 1.6, 2.6, 2 if k % 3 else 3)
    return s

def boss(ph):
    c = Spr(24, 42)
    # legs
    for (x0, x1) in ((9, 7 - ph * 2), (15, 17 + ph * 2)):
        for t in range(3): c.line(x0 + t, 30, x1 + t, 40, 1)
    c.rect(5, 40, 9, 41, 1); c.rect(15, 40, 20, 41, 1)
    # body (robe)
    c.ellipse(13, 24, 9, 8, 3)
    for x in range(7, 20, 3): c.line(x, 18, x - 1, 31, 1)
    # arms
    for t in range(3):
        c.line(6, 19 + t, 0, 24 + t - ph * 2, 2)
        c.line(20, 19 + t, 23, 26 + t, 2)
    # head
    c.ellipse(12, 11, 7.5, 7.5, 2)
    c.rect(6, 15, 17, 18, 2)
    c.rect(6, 16, 15, 17, 1)
    for x in range(7, 15, 2): c.set(x, 16, 3)
    c.ellipse(9, 9, 1.8, 2, 3); c.ellipse(15, 9, 1.8, 2, 3); c.set(9, 9, 1); c.set(15, 9, 1)
    # crown
    c.rect(6, 2, 18, 4, 3)
    for x in (6, 10, 14, 18): c.rect(x, 0, x, 2, 3)
    c.set(12, 3, 1)
    return c.outline()

def cursor(kind):
    s = Spr()
    # arrow pointing down into the cell
    for y in range(9):
        w = 4 - abs(y - 4) * 0 if y < 5 else 0
    s.rect(5, 0, 6, 6, 2)
    for i in range(5): s.rect(6 - i - 1, 6 + i, 6 + i, 6 + i, 2)
    if kind == 1:
        s.ellipse(9.5, 2.5, 2, 2.5, 3); s.set(9, 1, 1)
    elif kind == 2:
        s.rect(9, 0, 9, 4, 3); s.ellipse(9.5, 5.5, 1.6, 2, 3)
    return s.outline()

def build_sprites():
    order = []
    Z = []
    for k in range(4):
        for f in range(4): Z.append(zombie(k, f))
    order.append(('zombie', Z))
    order.append(('zdown', [zombie_down(f) for f in range(3)]))
    order.append(('sun', [sun(0), sun(1)]))
    order.append(('mower', [mower_spr()]))
    order.append(('expl', [explosion(f) for f in range(3)]))
    B = []
    for ph in range(2): B += big_slices(boss(ph), 2, 2)
    order.append(('boss', B))
    order.append(('cursor', [cursor(k) for k in range(3)]))
    data = bytearray(); syms = {}; ptr = 0x30
    for name, frames in order:
        syms[name] = ptr
        for fr in frames:
            data += fr.tobytes(); ptr += 1
    return data, syms
