# GUMDROP - graphics generator: sweets, specials, ice, frame, jar, meter, sprites, logo
# all designs are original
import math

# ------------------------------------------------------------------ sweets on a 8 x 16 multicolour grid
# values: 0 empty (background), 1 body (colour slot), 2 white
W, H = 8, 16

def blank():
    return [[0] * W for _ in range(H)]

def inside(fn):
    g = blank()
    for y in range(H):
        for x in range(W):
            # sample the centre of the fat pixel in a 16 x 16 space
            X, Y = x * 2 + 1.0, y + 0.5
            g[y][x] = fn(X, Y)
    return g

def heart(X, Y):
    x, y = (X - 8) / 6.4, (7.6 - Y) / 6.4
    v = (x * x + y * y - 1) ** 3 - x * x * y ** 3
    return 1 if v <= 0 else 0

def star(X, Y):
    x, y = X - 8, Y - 8.3
    r = math.hypot(x, y)
    a = math.atan2(y, x) + math.pi / 2
    k = (math.cos(5 * a) + 1) / 2
    return 1 if r <= 4.0 + 3.6 * k else 0

def diamond(X, Y):
    return 1 if abs(X - 8) / 6.6 + abs(Y - 8) / 7.2 <= 1 else 0

def gumdrop(X, Y):
    # dome on a flat base
    if Y > 14.2 or Y < 2: return 0
    w = 6.8 * math.sqrt(max(0, 1 - ((14.2 - Y) / 12.4) ** 2.2))
    return 1 if abs(X - 8) <= w else 0

def ball(X, Y):
    return 1 if (X - 8) ** 2 + (Y - 8) ** 2 <= 6.8 ** 2 else 0

def caramel(X, Y):
    x, y = abs(X - 8), abs(Y - 8)
    if x > 6.4 or y > 6.4: return 0
    if x > 4.4 and y > 4.4 and (x - 4.4) ** 2 + (y - 4.4) ** 2 > 4: return 0
    return 1

SHAPES = [heart, star, diamond, gumdrop, ball, caramel]
NAMES = ['heart', 'star', 'diamond', 'gumdrop', 'ball', 'caramel']
COLOURS = [2, 8, 7, 5, 14, 4]        # red, orange, yellow, green, light blue, purple

def shine(g, kind):
    """white highlights per kind"""
    def s(x, y):
        if 0 <= x < W and 0 <= y < H and g[y][x]: g[y][x] = 2
    if kind == 0:   # heart: two dots upper left
        s(2, 4); s(2, 5); s(3, 3)
    elif kind == 1: # star: centre sparkle
        s(3, 7); s(4, 8); s(3, 9)
    elif kind == 2: # diamond: facet line
        for y in range(3, 9): s(2 + (8 - y) // 3 - 0, y) if False else s(3, y)
        s(2, 6); s(2, 7)
    elif kind == 3: # gumdrop: sugar crystals
        for (x, y) in ((2, 8), (5, 6), (4, 11), (1, 12), (6, 11), (3, 5)): s(x, y)
    elif kind == 4: # ball: swirl
        for t in range(14):
            a = t * 0.55
            r = 1.0 + t * 0.32
            s(int(round(3.6 + r * math.cos(a) * 0.5)), int(round(8 + r * math.sin(a))))
    elif kind == 5: # caramel: shine corner and a line
        s(1, 4); s(1, 5); s(2, 3); s(2, 4)
        for x in range(2, 6): s(x, 11)
    return g

def sweet(kind, special=0):
    g = inside(SHAPES[kind])
    # carve a dark outline ring for definition (empty pixels at the shape edge stay empty)
    g = shine(g, kind)
    if special == 1:      # line, horizontal stripes (clears its row)
        for y in (5, 8, 11):
            for x in range(W):
                if g[y][x]: g[y][x] = 2
    elif special == 2:    # line, vertical stripes (clears its column)
        for y in range(H):
            for x in (2, 5):
                if g[y][x]: g[y][x] = 2
    elif special == 3:    # bomb: the sweet shrunk inside a glowing white ring
        f = SHAPES[kind]
        h = inside(lambda X, Y: f(8 + (X - 8) / 0.62, 8 + (Y - 8) / 0.62))
        h = shine(h, kind) if kind not in (1, 4) else h
        g = [r[:] for r in h]
        for y in range(H):
            for x in range(W):
                if h[y][x]: continue
                near = any(0 <= x + dx < W and 0 <= y + dy < H and h[y + dy][x + dx]
                           for dx in (-1, 0, 1) for dy in (-1, 0, 1))
                if near: g[y][x] = 2
    return g

def rainbow():
    g = inside(ball)
    import random
    r = random.Random(42)
    for y in range(H):
        for x in range(W):
            if g[y][x] and r.random() < 0.28: g[y][x] = 2
    return g

def pop(phase):
    g = blank()
    if phase == 0:
        for (x, y) in ((3, 7), (4, 7), (3, 8), (4, 8), (3, 9), (4, 9)): g[y][x] = 2
        for d in range(2, 6):
            for (dx, dy) in ((0, -1), (0, 1), (1, 0), (-1, 0)):
                x, y = (3.5 + dx * d * 0.6), (8 + dy * d * 1.2)
                if 0 <= int(x) < W and 0 <= int(y) < H: g[int(y)][int(x)] = 1
        for (x, y) in ((1, 4), (6, 4), (1, 12), (6, 12)): g[y][x] = 2
    else:
        for (x, y) in ((0, 1), (7, 2), (1, 14), (6, 13), (3, 3), (5, 12), (2, 8), (6, 8)):
            g[y][x] = 2 if (x + y) % 2 else 1
    return g

ICE = blank()
for x in range(W):
    if x % 2 == 0: ICE[0][x] = 2
    if x % 2 == 1: ICE[15][x] = 2
for y in range(H):
    if y % 3 == 0: ICE[y][0] = 2
    if y % 3 == 1: ICE[y][7] = 2
ICE2 = [r[:] for r in ICE]
for x in range(W): ICE2[0][x] = 2; ICE2[15][x] = 2
for y in range(H): ICE2[y][0] = 2; ICE2[y][7] = 2

def bitmap_bytes(g, parity):
    """32 bytes: line by line, left byte then right byte; body -> %01 (parity 0) or %10 (parity 1), white -> %11"""
    out = []
    for y in range(H):
        for half in range(2):
            v = 0
            for k in range(4):
                p = g[y][half * 4 + k]
                bits = 0 if p == 0 else (3 if p == 2 else (1 if parity == 0 else 2))
                v |= bits << (6 - 2 * k)
            out.append(v)
    return out

# shape table: 6 kinds x (normal, lineH, lineV, bomb) = 24, rainbow 24, pop 25, 26
def all_shapes():
    s = []
    for k in range(6):
        for sp in range(4):
            s.append(sweet(k, sp))
    s.append(rainbow())
    s.append(pop(0)); s.append(pop(1))
    return s

# ------------------------------------------------------------------ multicolour sprites (12 x 21)
class MCSpr:
    def __init__(self):
        self.p = [[0] * 12 for _ in range(21)]
    def tobytes(self):
        out = bytearray()
        for y in range(21):
            for b in range(3):
                v = 0
                for k in range(4): v |= self.p[y][b * 4 + k] << (6 - 2 * k)
                out.append(v)
        out.append(0)
        return bytes(out)

def sweet_sprite(g):
    """body -> sprite colour (%10), white -> $d025 (%01)"""
    s = MCSpr()
    for y in range(H):
        for x in range(W):
            v = g[y][x]
            if v: s.p[y][x] = 2 if v == 1 else 1
    return s.tobytes()

def cursor(thick):
    out = bytearray(64)
    def setp(x, y):
        out[y * 3 + x // 8] |= 0x80 >> (x % 8)
    for i in range(18):
        for t in range(2 if thick else 1):
            setp(i, t); setp(i, 17 - t); setp(t, i); setp(17 - t, i)
    # corner ticks
    if not thick:
        for i in range(4):
            setp(i, 1); setp(1, i); setp(16 - i + 0, 1); setp(16, i); setp(i, 16); setp(1, 17 - i); setp(16 - i, 16); setp(16, 17 - i)
    return bytes(out)

# ------------------------------------------------------------------ picture parts (multicolour bitmap)
# pictures are given as fat-pixel grids with colour indices; each 4 x 8 cell may use bg + 3 colours.
def cells_from_picture(pic, w_cells, h_cells, bg=0):
    """pic: list of rows of colour numbers (or None = bg), size (w_cells*4) x (h_cells*8)
    -> bitmap bytes (cell by cell, 8 each), screen bytes (hi/lo nibble), colour RAM"""
    bm, scr, col = [], [], []
    for cy in range(h_cells):
        for cx in range(w_cells):
            cols = []
            for y in range(8):
                for x in range(4):
                    c = pic[cy * 8 + y][cx * 4 + x]
                    if c is not None and c != bg and c not in cols: cols.append(c)
            assert len(cols) <= 3, (cx, cy, cols)
            cols += [0] * (3 - len(cols))
            # slot 01 = hi nibble, 10 = lo nibble, 11 = colour RAM
            for y in range(8):
                v = 0
                for x in range(4):
                    c = pic[cy * 8 + y][cx * 4 + x]
                    bits = 0 if (c is None or c == bg) else cols.index(c) + 1
                    v |= bits << (6 - 2 * x)
                bm.append(v)
            scr.append((cols[0] << 4) | cols[1])
            col.append(cols[2])
    return bm, scr, col

def jar_picture():
    """left panel: a glass jar full of sweets (80 x 160 px -> 40 x 160 fat pixels; 10 x 20 cells)"""
    import random
    r = random.Random(7)
    Wd, Hd = 40, 160
    pic = [[None] * Wd for _ in range(Hd)]
    def setp(x, y, c):
        if 0 <= x < Wd and 0 <= y < Hd: pic[y][x] = c
    # jar glass outline (light grey 15) and lid (red 2 with white stripes)
    top, bot = 40, 150
    for y in range(top, bot + 1):
        t = (y - top) / (bot - top)
        w = 15 if y > top + 8 else 12
        if y >= bot - 4: w = 15 - (y - (bot - 4))
        setp(20 - w, y, 15); setp(19 + w, y, 15)
    for x in range(6, 34):
        setp(x, bot, 15)
    for y in range(26, 40):
        for x in range(8, 32):
            setp(x, y, 2 if ((x // 2 + y // 4) % 2 == 0) else 1)
    for x in range(8, 32): setp(x, 26, 1); setp(x, 39, 1)
    # sweets inside: coloured blobs, arranged by cells so each cell has few colours
    palette = [2, 8, 7, 5, 14, 4]
    yy = bot - 8
    row = 0
    while yy > top + 12:
        x = 7 + (row % 2) * 3
        while x < 32:
            c = palette[r.randrange(6)]
            for dy in range(-3, 4):
                for dx in range(-2, 3):
                    if dx * dx * 2.2 + dy * dy <= 9: setp(x + dx, yy + dy, c)
            setp(x - 1, yy - 2, 1)
            x += 6
        yy -= 8
        row += 1
    # reduce to at most 3 colours per cell (keep the most frequent)
    for cy in range(20):
        for cx in range(10):
            cnt = {}
            for y in range(8):
                for x in range(4):
                    c = pic[cy * 8 + y][cx * 4 + x]
                    if c is not None: cnt[c] = cnt.get(c, 0) + 1
            keep = sorted(cnt, key=lambda c: -cnt[c])[:3]
            for y in range(8):
                for x in range(4):
                    c = pic[cy * 8 + y][cx * 4 + x]
                    if c is not None and c not in keep:
                        pic[cy * 8 + y][cx * 4 + x] = keep[0] if c != 15 else (15 if 15 in keep else keep[0])
    # title text "GUMDROP" written vertically is too big; a small label on the jar instead
    return pic

def meter_picture():
    """right panel: a candy cane tube for the goal (10 x 20 cells)"""
    Wd, Hd = 40, 160
    pic = [[None] * Wd for _ in range(Hd)]
    def setp(x, y, c):
        if 0 <= x < Wd and 0 <= y < Hd: pic[y][x] = c
    # tube: inner x 12..27 (cells 3..6), lines 24..143 ; frame white with red stripes
    for y in range(18, 150):
        for x in (10, 11, 28, 29):
            setp(x, y, 1 if ((y // 4) % 2 == 0) else 2)
    for x in range(10, 30):
        for y in (18, 19, 20, 21, 146, 147, 148, 149):
            setp(x, y, 1 if (((x // 2) + y // 4) % 2 == 0) else 2)
    # star on top
    for y in range(4, 16):
        for x in range(12, 28):
            X, Y = x * 2 + 1 - 40, y + 0.5 - 10
            a = math.atan2(Y, X) + math.pi / 2
            rr = math.hypot(X, Y)
            if rr <= 3.0 + 3.2 * (math.cos(5 * a) + 1) / 2: setp(x, y, 7)
    return pic

METER_X0, METER_X1 = 3, 6          # interior cells (byte columns within the panel)
METER_TOP, METER_BOT = 24, 143     # interior lines

# ------------------------------------------------------------------ board frame (candy cane), one cell row / column
def frame_cells():
    """bitmap bytes for the frame cells: top (8 bytes), side (8), corner (8); colours red / white via
    slot 01 (red, screen hi nibble) and %11 (white, colour RAM)"""
    top = []
    for y in range(8):
        v = 0
        for x in range(4):
            if 2 <= y <= 5:
                p = 1 if ((x + y) // 2) % 2 == 0 else 3
            else:
                p = 0
            v |= p << (6 - 2 * x)
        top.append(v)
    side = []
    for y in range(8):
        v = 0
        for x in range(4):
            p = (1 if ((y + x) // 2) % 2 == 0 else 3) if 1 <= x <= 2 else 0
            v |= p << (6 - 2 * x)
        side.append(v)
    corner = []
    for y in range(8):
        v = 0
        for x in range(4):
            p = 3 if (1 <= x <= 2 and 2 <= y <= 5) else 0
            v |= p << (6 - 2 * x)
        corner.append(v)
    return top, side, corner

# ------------------------------------------------------------------ logo
def logo_bitmap():
    Wg, Hg = 10, 14
    def glyph(ch):
        g = [[0] * Wg for _ in range(Hg)]
        def rect(x0, y0, x1, y1):
            for y in range(max(0, y0), min(Hg, y1 + 1)):
                for x in range(max(0, x0), min(Wg, x1 + 1)): g[y][x] = 1
        def disc(cx, cy, r):
            for y in range(Hg):
                for x in range(Wg):
                    if (x - cx) ** 2 + (y - cy) ** 2 <= r * r: g[y][x] = 1
        if ch == 'G':
            rect(1, 0, 9, 2); rect(0, 1, 2, 12); rect(1, 11, 9, 13); rect(7, 7, 9, 12); rect(5, 7, 9, 8)
        elif ch == 'U':
            rect(0, 0, 2, 12); rect(7, 0, 9, 12); rect(1, 11, 8, 13)
        elif ch == 'M':
            rect(0, 0, 2, 13); rect(7, 0, 9, 13)
            for i in range(5): rect(2 + i // 2, 1 + i, 3 + i // 2, 2 + i); rect(7 - i // 2, 1 + i, 6 - i // 2 + 1, 2 + i)
        elif ch == 'D':
            rect(0, 0, 2, 13); rect(0, 0, 7, 2); rect(0, 11, 7, 13); rect(7, 1, 9, 12)
        elif ch == 'R':
            rect(0, 0, 2, 13); rect(0, 0, 8, 2); rect(0, 6, 8, 8); rect(7, 1, 9, 7)
            for i in range(6): rect(4 + i, 8 + i, 6 + i // 2 + 1, 8 + i)
        elif ch == 'O':
            rect(1, 0, 8, 2); rect(1, 11, 8, 13); rect(0, 1, 2, 12); rect(7, 1, 9, 12)
        elif ch == 'P':
            rect(0, 0, 2, 13); rect(0, 0, 8, 2); rect(0, 6, 8, 8); rect(7, 1, 9, 7)
        return g
    WT = 80; bm = [[0] * WT for _ in range(Hg + 2)]
    x = 2
    for i, ch in enumerate("GUMDROP"):
        g = glyph(ch)
        lift = [0, 1, 0, 1, 0, 1, 0][i]
        for y in range(Hg):
            for xx in range(Wg):
                if g[y][xx]:
                    bm[y + lift][x + xx] = 1
        x += Wg + 1
    return bm

HEART_CHAR = [0b00000000, 0b01101100, 0b11111110, 0b11111110, 0b01111100, 0b00111000, 0b00010000, 0b00000000]
