# GULP! - original sea creature graphics (all procedurally drawn)
# sprite canvas values: 0 transparent, 1 outline ($d025 = black), 2 body (sprite colour), 3 white ($d026)
import math, random
from gfx import Spr, big_slices

def fill_poly(c, pts, v):
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    for y in range(int(min(ys)), int(max(ys)) + 2):
        for x in range(int(min(xs)), int(max(xs)) + 2):
            px, py = x + .5, y + .5
            ins = False; j = len(pts) - 1
            for i in range(len(pts)):
                xi, yi = pts[i]; xj, yj = pts[j]
                if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi + 1e-9) + xi: ins = not ins
                j = i
            if ins: c.set(x, y, v)

def ell(c, cx, cy, rx, ry, v):
    for y in range(c.h):
        for x in range(c.w):
            dx = (x + .5 - cx) / rx; dy = (y + .5 - cy) / ry
            if dx * dx + dy * dy <= 1.0: c.p[y][x] = v

def belly(c, cx, cy, rx, ry):
    # lower part of body lighter (white) where body exists
    for y in range(c.h):
        for x in range(c.w):
            dx = (x + .5 - cx) / rx; dy = (y + .5 - cy) / ry
            if dx * dx + dy * dy <= 1.0 and dy > 0.45 and c.p[y][x] == 2: c.p[y][x] = 3

def eye(c, x, y, big=False):
    if big:
        c.set(x, y, 3); c.set(x, y - 1, 3); c.set(x + 1, y - 1, 3); c.set(x + 1, y, 1)
    else:
        c.set(x, y, 3); c.set(x + 1, y, 1)

def tail(c, x, cy, size, phase, forked=True):
    # tail on the left side (fish faces right); x = joint
    d = 1 if phase else -1
    top = (x - size, cy - size - (d if phase else 0))
    bot = (x - size, cy + size + (0 if phase else -d))
    if forked:
        fill_poly(c, [(x + 0.5, cy - 0.5), top, (x - size * 0.4, cy + 0.5), bot, (x + 0.5, cy + 1.5)], 2)
    else:
        fill_poly(c, [(x + 0.5, cy - 0.5), top, bot, (x + 0.5, cy + 1.5)], 2)

def mouth_cut(c, xf, cy, size):
    # open mouth: wedge into the front
    for k in range(size + 1):
        for yy in range(-k // 2, k // 2 + 1):
            c.set(xf - size + k, cy + yy, 0)

def finish(c):
    c.outline()
    return c

# ------------------------------------------------------------- player "GULP"
def player(size, phase, mouth):
    c = Spr()
    cy = 10
    L = [3.4, 4.4, 5.6][size]; H = [3.0, 4.0, 5.2][size]
    cx = 7.2 if size < 2 else 6.6
    tail(c, int(cx - L) + 1, cy, [2, 2, 3][size], phase)
    ell(c, cx, cy + .5, L, H, 2)
    # dorsal fin
    fill_poly(c, [(cx - L * .3, cy - H + .6), (cx - L * .6, cy - H - [1, 2, 2][size]), (cx + L * .3, cy - H + .6)], 2)
    belly(c, cx, cy + .5, L, H)
    # pectoral fin
    c.set(cx - 1, cy + 1, 1); c.set(cx - 2, cy + 1 + phase, 1)
    eye(c, int(cx + L * .45), int(cy - H * .25), big=size > 0)
    if mouth:
        mouth_cut(c, int(cx + L + .5), cy + 1, [1, 2, 3][size])
    else:
        c.set(int(cx + L - .5), cy + 1, 1)
    return finish(c)

# ------------------------------------------------------------- edible species
def minnow(phase, mouth, col=None):
    c = Spr(); cy = 10
    tail(c, 3, cy, 2, phase)
    ell(c, 6.5, cy + .5, 3.2, 1.8, 2); belly(c, 6.5, cy + .5, 3.2, 1.8)
    eye(c, 8, cy)
    return finish(c)

def stripy(phase, mouth):
    c = Spr(); cy = 10
    tail(c, 3, cy, 2, phase)
    ell(c, 6.5, cy + .5, 3.6, 3.2, 2)
    for x in (5, 7):
        for y in range(cy - 2, cy + 4):
            if c.p[y][x] == 2: c.p[y][x] = 3
    fill_poly(c, [(5, cy - 2.5), (6, cy - 4.5), (8, cy - 2.5)], 2)
    eye(c, 8, cy - 1)
    return finish(c)

def puffer(phase, mouth):
    c = Spr(); cy = 10
    r = 4.2 if phase else 4.0
    tail(c, 2, cy, 2, phase, forked=False)
    ell(c, 6.5, cy + .5, r, r * 1.05, 2); belly(c, 6.5, cy + .5, r, r)
    for k in range(10):
        a = k * math.tau / 10 + 0.3
        c.set(6.5 + math.cos(a) * (r + 0.9), cy + .5 + math.sin(a) * (r + 0.9), 2)
    for k in range(3): c.set(4 + k * 2, cy - 1, 1)
    eye(c, 8, cy - 1, big=True)
    c.set(10, cy + 1, 1)
    return finish(c)

def sardine(phase, mouth):
    c = Spr(); cy = 10
    tail(c, 3, cy, 2, phase)
    ell(c, 7, cy + .5, 3.8, 1.6, 2); belly(c, 7, cy + .5, 3.8, 1.6)
    eye(c, 9, cy)
    return finish(c)

def angel(phase, mouth):
    c = Spr(); cy = 10
    fill_poly(c, [(2.5, cy + .5), (6.5, cy - 4.5), (10.5, cy + .5), (6.5, cy + 5.5)], 2)
    fill_poly(c, [(5, cy - 3), (3, cy - 6 - phase), (6.5, cy - 4)], 2)
    fill_poly(c, [(5, cy + 4), (3, cy + 7 + phase), (6.5, cy + 5)], 2)
    tail(c, 3, cy, 2, phase, forked=False)
    for y in range(cy - 4, cy + 6):
        for x in (5, 8):
            if c.p[y][x] == 2: c.p[y][x] = 1
    eye(c, 8, cy - 1)
    return finish(c)

def snapper(phase, mouth):
    c = Spr(); cy = 10
    tail(c, 2, cy, 3, phase)
    ell(c, 6.5, cy + .5, 4.6, 3.6, 2); belly(c, 6.5, cy + .5, 4.6, 3.6)
    for x in range(3, 9, 2): c.set(x, cy - 4, 1); c.set(x, cy - 5, 2)
    fill_poly(c, [(2.5, cy - 3), (8.5, cy - 3), (6, cy - 5)], 2)
    eye(c, 9, cy - 1, big=True)
    c.set(11, cy + 1, 1)
    return finish(c)

def glowfish(phase, mouth):
    c = Spr(); cy = 10
    tail(c, 3, cy, 2, phase)
    ell(c, 6.5, cy + .5, 3.4, 2.6, 2)
    for x in (4, 6, 8): c.set(x, cy + 2, 3)
    c.set(9 + phase, cy - 3, 3); c.line(8, cy - 2, 9 + phase, cy - 3, 1)
    eye(c, 8, cy)
    return finish(c)

def hatchet(phase, mouth):
    c = Spr(); cy = 10
    fill_poly(c, [(3, cy - 2), (9.5, cy - 3.5), (10.5, cy), (7, cy + 4.5), (3, cy + 1)], 2)
    tail(c, 3, cy - 1, 2, phase)
    for x in range(5, 10, 2): c.set(x, cy + 2, 3)
    eye(c, 8, cy - 2, big=True)
    return finish(c)

def viper(phase, mouth):
    c = Spr(); cy = 10
    tail(c, 1, cy, 2, phase)
    ell(c, 6, cy + .5, 5.4, 2.2, 2)
    c.set(10, cy + 2, 3); c.set(10, cy + 3, 3); c.set(8, cy + 2, 3); c.set(9, cy - 1, 3)
    for x in range(2, 8, 2): c.set(x, cy + 1, 3)
    eye(c, 8, cy - 1)
    c.line(9, cy + 1, 11, cy + 1, 1)
    return finish(c)

SPECIES = [[minnow, stripy, puffer], [sardine, angel, snapper], [glowfish, hatchet, viper]]

# ------------------------------------------------------------- predators (24 x 21 -> 2 sprites)
def barracuda(phase):
    c = Spr(24, 21); cy = 10
    tail(c, 4, cy, 3, phase)
    fill_poly(c, [(4, cy - 1.5), (19, cy - 2.5), (23.5, cy + .5), (19, cy + 3), (4, cy + 2)], 2)
    fill_poly(c, [(9, cy - 2), (11, cy - 4), (13, cy - 2)], 2)
    fill_poly(c, [(6, cy + 2), (7, cy + 4), (9, cy + 2)], 2)
    for x in range(6, 18, 3): c.set(x, cy, 1)
    for x in range(18, 23, 2): c.set(x, cy + 1, 3)
    c.line(18, cy + 1, 23, cy + 1, 1)
    for x in range(18, 23, 2): c.set(x, cy + 1, 3)
    eye(c, 19, cy - 1)
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] == 2 and y >= cy + 2: c.p[y][x] = 3
    return finish(c)

def shark(phase):
    c = Spr(24, 21); cy = 11
    # crescent tail
    fill_poly(c, [(5, cy), (1, cy - 6 - phase), (3, cy), (1, cy + 4 + phase)], 2)
    fill_poly(c, [(4, cy - 1), (16, cy - 4), (23.5, cy), (16, cy + 4), (4, cy + 1.5)], 2)
    fill_poly(c, [(11, cy - 3), (13, cy - 8), (16, cy - 3.5)], 2)
    fill_poly(c, [(13, cy + 3), (12, cy + 6), (16, cy + 3)], 2)
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] == 2 and y >= cy + 1 and x > 6: c.p[y][x] = 3
    for x in (16, 17): c.line(x, cy - 1, x, cy + 1, 1)
    eye(c, 20, cy - 1)
    c.line(19, cy + 2, 22, cy + 1, 1)
    return finish(c)

def gulper(phase):
    c = Spr(24, 21); cy = 10
    for x in range(1, 13):
        w = 0.6 + (x / 12.0) * 1.6
        c.line(x, cy - w + .5, x, cy + w, 2)
    c.set(0, cy - 1 + phase, 3); c.set(0, cy + phase, 3)
    # huge jaw
    fill_poly(c, [(12, cy - 2), (22, cy - 6), (23.5, cy - 4), (16, cy), (23.5, cy + 4), (22, cy + 7), (12, cy + 3)], 2)
    for x in range(16, 23, 2): c.set(x, cy - 3, 3); c.set(x, cy + 4, 3)
    eye(c, 18, cy - 5)
    return finish(c)

PREDATORS = [barracuda, shark, gulper]

# ------------------------------------------------------------- jellyfish
def jelly(phase):
    c = Spr(); cy = 7
    rx = 4.8 if phase else 4.2; ry = 3.4 if phase else 4.0
    ell(c, 6, cy, rx, ry, 2)
    for y in range(int(cy) + 1, c.h):
        for x in range(c.w): c.p[y][x] = 0
    c.rect(int(6 - rx) + 1, cy, int(6 + rx) - 1, cy, 2)
    c.set(4, cy - 2, 3); c.set(5, cy - 3, 3); c.set(4, cy - 1, 3)
    c.outline()
    for k, x in enumerate((3, 5, 7, 9)):
        for y in range(cy + 1, cy + 10 - (k % 2) * 2):
            c.set(x + (1 if ((y + k * 2 + phase * 2) // 3) % 2 else 0), y, 3)
    return c

# ------------------------------------------------------------- bosses (24 x 42 -> 2 x 2 sprites)
def grouper(phase):
    c = Spr(24, 42); cy = 21
    tail(c, 4, cy, 6, phase, forked=False)
    ell(c, 13.5, cy, 10, 13, 2)
    fill_poly(c, [(7, cy - 11), (12, cy - 17), (18, cy - 11)], 2)
    fill_poly(c, [(8, cy + 11), (11, cy + 17), (15, cy + 11)], 2)
    belly(c, 13.5, cy, 10, 13)
    rnd = random.Random(2)
    for k in range(22):
        x = rnd.uniform(6, 20); y = rnd.uniform(cy - 10, cy + 5)
        if c.get(int(x), int(y)) == 2: c.set(x, y, 1)
    # lips + mouth
    fill_poly(c, [(22, cy + 1), (24, cy - 1), (24, cy + 6), (21, cy + 6)], 0 if phase else 2)
    c.line(19, cy + 3, 23, cy + 2, 1)
    ell(c, 19, cy - 6, 2.2, 2.6, 3); c.set(20, cy - 6, 1); c.set(20, cy - 5, 1)
    for k in range(4): c.set(10 + k, cy + 2 + (k % 2), 1)
    return finish(c)

def octopus(phase):
    c = Spr(24, 42); cy = 13
    for k in range(5):
        x0 = 4 + k * 4
        for t in range(22):
            x = x0 + math.sin(t * 0.35 + phase * 1.6 + k) * (1 + t * 0.12) + (k - 2) * t * 0.15
            y = cy + 8 + t
            w = 1.6 - t * 0.05
            for dx in range(-1, 2):
                if abs(dx) <= w: c.set(x + dx, y, 2)
    ell(c, 12, cy, 9, 10.5, 2)
    for (ex, ey) in ((8, cy + 1), (16, cy + 1)):
        ell(c, ex, ey, 2.4, 2.8, 3); c.set(ex + (0 if phase else -1), ey, 1); c.set(ex + (0 if phase else -1), ey + 1, 1)
    c.set(6, cy - 6, 3); c.set(7, cy - 7, 3); c.set(8, cy - 7, 3)
    c.outline()
    for k in range(5):
        x0 = 4 + k * 4
        for t in range(3, 20, 4):
            x = x0 + math.sin(t * 0.35 + phase * 1.6 + k) * (1 + t * 0.12) + (k - 2) * t * 0.15
            c.set(x, cy + 8 + t, 3)
    return c

def angler(phase):
    c = Spr(24, 42); cy = 22
    tail(c, 4, cy, 5, phase)
    ell(c, 13, cy, 9.5, 11, 2)
    # lure
    c.line(13, cy - 10, 16, cy - 17, 1); c.line(16, cy - 17, 21, cy - 16, 1)
    ell(c, 21.5, cy - 14.5, 2, 2, 3)
    # jaw with teeth
    fill_poly(c, [(15, cy + 1), (24, cy - 4), (24, cy + 9), (15, cy + 6)], 0)
    for k in range(4):
        c.set(16 + k * 2, cy - 1 - k // 2 + (1 if phase else 0), 3)
        c.set(16 + k * 2, cy + 6 + k // 3, 3)
    ell(c, 15, cy - 5, 2, 2.4, 3); c.set(16, cy - 5, 1)
    for y in range(cy - 8, cy + 10, 3): c.set(8, y, 1)
    return finish(c)

BOSSES = [grouper, octopus, angler]

# ------------------------------------------------------------- misc
def bones(phase):
    c = Spr(); cy = 10
    c.line(2, cy, 9, cy, 3)
    for x in (4, 6, 8): c.line(x, cy - 2, x, cy + 2, 3)
    ell(c, 10, cy, 1.8, 2.2, 3); c.set(10, cy - 1, 1)
    c.line(1, cy - 2 + phase, 2, cy, 3); c.line(1, cy + 2 - phase, 2, cy, 3)
    return finish(c)

def burst(f):
    c = Spr(); r = 2 + f * 2.2
    rnd = random.Random(9)
    for k in range(9):
        a = rnd.uniform(0, math.tau); rr = r * rnd.uniform(0.6, 1.0)
        x = 6 + math.cos(a) * rr * 0.6; y = 10 + math.sin(a) * rr
        s = 1.2 - f * 0.3
        c.set(x, y, 3);
        if f < 2: c.set(x + 1, y, 3)
    return c

def bubble(big):
    c = Spr()
    if big:
        ell(c, 6, 10, 2.2, 3.4, 3); ell(c, 6, 10, 1.3, 2.2, 0); c.set(5, 9, 3)
    else:
        ell(c, 6, 10, 1.2, 1.8, 3)
    return c

def clam(f):
    # 0 closed, 1 half open, 2 open with pearl, 3 open empty
    c = Spr(); by = 18
    fill_poly(c, [(1, by), (6, by - 3), (11, by), (6, by + 2)], 2)
    for x in range(2, 11, 2): c.set(x, by, 1)
    if f >= 1:
        h = 2 if f == 1 else 5
        fill_poly(c, [(1, by - 1), (6, by - 1 - h - 2), (11, by - 1), (6, by - 1 - h + 1)], 2)
        for y in range(by - h, by):
            for x in range(3, 10):
                if c.p[y][x] == 0: c.p[y][x] = 0
        if f == 2:
            ell(c, 6, by - 2, 1.6, 1.8, 3)
    return finish(c)

def build_sprites():
    order = []
    P = []
    for size in range(3):
        for d in range(2):
            for f in range(3):
                s = player(size, f == 1, f == 2)
                P.append(s if d == 0 else s.hflip())
    order.append(('player', P))
    order.append(('bones', [bones(0), bones(1)]))
    order.append(('burst', [burst(f) for f in range(3)]))
    order.append(('bubble', [bubble(0), bubble(1)]))
    order.append(('jelly', [jelly(0), jelly(1)]))
    order.append(('clam', [clam(f) for f in range(4)]))
    F = []
    for z in range(3):
        for t in range(3):
            for d in range(2):
                for f in range(2):
                    s = SPECIES[z][t](f, False)
                    F.append(s if d == 0 else s.hflip())
    order.append(('fish', F))
    R = []
    for z in range(3):
        for d in range(2):
            for f in range(2):
                b = PREDATORS[z](f)
                if d: b = b.hflip()
                R += big_slices(b, 2, 1)
    order.append(('pred', R))
    B = []
    for z in range(3):
        for d in range(2):
            for f in range(2):
                b = BOSSES[z](f)
                if d: b = b.hflip()
                B += big_slices(b, 2, 2)
    order.append(('boss', B))
    data = bytearray(); syms = {}; ptr = 0x30
    for name, frames in order:
        syms[name] = ptr
        for fr in frames:
            data += fr.tobytes(); ptr += 1
    return data, syms

def preview(path, spr, cols=None):
    from PIL import Image
    pal = [None, (0, 0, 0), (255, 140, 60), (255, 255, 255)]
    n = len(spr) // 64
    W = 16
    im = Image.new('RGB', (W * 52, (n // W + 1) * 46), (60, 120, 220))
    for i in range(n):
        b = spr[i * 64:i * 64 + 64]; ox = (i % W) * 52; oy = (i // W) * 46
        for y in range(21):
            for x in range(12):
                v = (b[y * 3 + x // 4] >> (6 - 2 * (x % 4))) & 3
                if v:
                    for k in range(4):
                        for j in range(2): im.putpixel((ox + x * 4 + k, oy + y * 2 + j), pal[v])
    im.save(path)
