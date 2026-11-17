# NIGHTHOLD - graphics generator: ground, creatures, gems, weapon effects, map, sprites, logo
# all designs are original
import math, random

# ------------------------------------------------------------------ multicolour chars
# values: 0 ground ($d021), 1 grey ($d022), 2 white ($d023), 3 night colour (colour RAM)
def mc(lines):
    m = {'.': 0, '1': 1, '2': 2, '3': 3}
    out = []
    for s in lines:
        assert len(s) == 4 and len(lines) == 8, lines
        v = 0
        for k in range(4): v |= m[s[k]] << (6 - 2 * k)
        out.append(v)
    return bytes(out)

def hires(lines):
    out = []
    for s in lines:
        v = 0
        for k in range(8):
            if s[k] != '.': v |= 0x80 >> k
        out.append(v)
    return bytes(out)

GROUND = {
    'grass1': ["....", "....", "....", ".3..", ".3.3", "..3.", "....", "...."],
    'grass2': ["....", "...3", "..3.", "3.3.", ".33.", "....", "....", "...."],
    'grass3': ["....", "....", "3...", "3..3", ".3.3", ".3..", "....", "...."],
    'flower': ["....", ".3..", "3.3.", ".3..", ".1..", ".1.3", "...1", "...."],
    'pebble': ["....", "....", "....", "..1.", ".11.", "....", "1...", "...."],
    'stone':  ["....", ".11.", "1111", "1111", ".11.", "....", "....", "...."],
    'bones':  ["....", "....", "1..1", ".11.", ".11.", "1..1", "....", "...."],
    'shroom': ["....", ".33.", "3333", ".1..", ".1..", "....", "....", "...."],
}
def grave():   # 2 x 2 chars
    g = ["..1111..",
         ".112211.",
         ".112211.",
         ".122221.",
         ".122221.",
         ".112211.",
         ".112211.",
         ".111111.",
         ".111111.",
         ".111111.",
         ".111111.",
         "11111111",
         "33333333",
         ".3....3.",
         "........",
         "........"]
    return g
def tree():    # 2 x 3 chars: dead tree
    t = ["...1..1.",
         "1..1.1..",
         ".1.1.1..",
         "..111..1",
         "...11.1.",
         "...111..",
         "...11...",
         "...11...",
         "...11...",
         "...11...",
         "...11...",
         "...11...",
         "..1111..",
         ".11..11.",
         "33.33.33",
         ".3...3..",
         "........",
         "........",
         "........",
         "........",
         "........",
         "........",
         "........",
         "........"]
    return t
def bush():    # 2 x 1
    return ["........",
            "..3333..",
            ".333333.",
            "33313333",
            "33333133",
            ".333333.",
            "..1..1..",
            "........"]

def split(pic, w, h):
    """picture of 4*w x 8*h fat pixels -> list of h rows of w char byte strings"""
    rows = []
    for cy in range(h):
        row = []
        for cx in range(w):
            row.append(mc([pic[cy * 8 + y][cx * 4:cx * 4 + 4] for y in range(8)]))
        rows.append(row)
    return rows

# ------------------------------------------------------------------ creatures (2 frames + white flash)
CREATURES = {
    'bat': [["1..1", "1221", ".11.", "1111", "1..1", "....", "....", "...."],
            ["....", "....", ".22.", "1111", "1111", "1..1", "....", "...."]],
    'zombie': [[".33.", "3223", ".33.", "1331", "1..1", ".11.", ".1.1", ".1.1"],
               [".33.", "3223", ".33.", "1331", "1..1", ".11.", "1..1", "1..1"]],
    'skeleton': [[".22.", "2112", ".22.", "2222", ".22.", ".2..", ".2.2", "2..2"],
                 [".22.", "2112", ".22.", "2222", ".22.", "..2.", "2.2.", "2..2"]],
    'ghost': [[".22.", "2112", "2222", "2222", "2222", "2222", "2.2.", "...."],
              [".22.", "2112", "2222", "2222", "2222", "2222", ".2.2", "...."]],
    'ghoul': [["3..3", "3333", "3223", "3333", "1331", "3333", "3..3", "1..1"],
              ["3..3", "3333", "3223", "3333", "3331", "1333", "3..3", "1..1"]],
    'wraith': [[".11.", "1221", "1111", "3113", "1111", "1111", "1.1.", ".1.1"],
               [".11.", "1221", "1111", "3113", "1111", "1111", ".1.1", "1.1."]],
}
CREATURE_ORDER = ['bat', 'zombie', 'skeleton', 'ghost', 'ghoul', 'wraith']
def flash_of(lines):
    return [''.join('2' if c != '.' else '.' for c in s) for s in lines]

GEMS = [
    ["....", "....", "..2.", ".232", "..2.", "....", "....", "...."],
    ["....", "..2.", ".232", "2333", ".232", "..2.", "....", "...."],
    ["..2.", ".232", "2332", "3333", "2332", ".232", "..2.", "...."],
]
HEART = ["....", "3.3.", "3333", "3333", ".33.", "..3.", "....", "...."]
CHEST = ["....", "1111", "1221", "2222", "1221", "1111", "....", "...."]
POOF = [["....", ".2..", "2.2.", ".2.2", "..2.", "....", "....", "...."],
        ["2..2", "....", ".1..", "...1", "1...", "..1.", "....", "2..2"]]
ORB = [["....", ".22.", "2112", "2112", ".22.", "....", "....", "...."],
       ["....", ".22.", "2222", "2112", ".22.", "....", "....", "...."]]
BOLT = [["..2.", "..2.", ".2..", ".2..", "..2.", "..2.", ".2..", ".2.."],
        [".2..", "..2.", "..2.", ".2..", ".2..", "..2.", "..2.", ".2.."],
        ["..2.", ".2..", "2.22", "2222", ".222", "2..2", "....", "...."]]
FIRE = [["....", "..2.", ".2..", ".22.", "2222", "2112", ".22.", "...."],
        ["..2.", ".2..", ".22.", "2222", "2122", "2112", ".22.", "...."],
        [".2..", "..2.", "2.2.", ".222", "2212", "2112", "2222", "...."]]

def knife(direction):
    """8 directions: 0 right, 1 down-right, 2 down, 3 down-left, 4 left, 5 up-left, 6 up, 7 up-right"""
    g = [[0] * 8 for _ in range(8)]   # hires-like 8x8, converted to fat pixels below
    ang = direction * math.pi / 4
    dx, dy = math.cos(ang), math.sin(ang)
    for t in range(-6, 7):
        x, y = 3.5 + dx * t * 0.5, 3.5 + dy * t * 0.5
        X, Y = int(round(x)), int(round(y))
        if 0 <= X < 8 and 0 <= Y < 8:
            g[Y][X] = 2 if t > -2 else 1
    lines = []
    for y in range(8):
        s = ''
        for x in range(4):
            v = max(g[y][2 * x], g[y][2 * x + 1])
            s += '.12'[v]
        lines.append(s)
    return lines

# UI chars (hires, white): box edges and an arrow
UI = {
    'tl': ["........", "........", "........", "...#####", "...#....", "...#.###", "...#.#..", "...#.#.."],
    'tr': ["........", "........", "........", "#####...", "....#...", "###.#...", "..#.#...", "..#.#..."],
    'bl': ["...#.#..", "...#.#..", "...#.###", "...#....", "...#####", "........", "........", "........"],
    'br': ["..#.#...", "..#.#...", "###.#...", "....#...", "#####...", "........", "........", "........"],
    'h':  ["........", "........", "........", "########", "........", "########", "........", "........"],
    'v':  ["...#.#..", "...#.#..", "...#.#..", "...#.#..", "...#.#..", "...#.#..", "...#.#..", "...#.#.."],
    'arrow': ["........", ".#......", ".##.....", ".###....", ".####...", ".###....", ".##.....", ".#......"],
    'full': ["########"] * 8,
}

# ------------------------------------------------------------------ the map (64 x 64 cells)
MAPW, MAPH = 64, 64
def make_map(ids):
    """ids: dict name -> char id (ground chars) and multi-cell shapes"""
    r = random.Random(1234)
    m = [[32] * MAPW for _ in range(MAPH)]
    used = [[False] * MAPW for _ in range(MAPH)]
    def free(x, y, w, h):
        for yy in range(y - 1, y + h + 1):
            for xx in range(x - 1, x + w + 1):
                if used[yy % MAPH][xx % MAPW]: return False
        return True
    def put(x, y, block):
        for dy, row in enumerate(block):
            for dx, ch in enumerate(row):
                m[(y + dy) % MAPH][(x + dx) % MAPW] = ch
                used[(y + dy) % MAPH][(x + dx) % MAPW] = True
    # graves in small clusters, trees, bushes
    for _ in range(26):
        x, y = r.randrange(MAPW), r.randrange(MAPH)
        if free(x, y, 2, 2): put(x, y, ids['grave'])
    for _ in range(14):
        x, y = r.randrange(MAPW), r.randrange(MAPH)
        if free(x, y, 2, 3): put(x, y, ids['tree'])
    for _ in range(20):
        x, y = r.randrange(MAPW), r.randrange(MAPH)
        if free(x, y, 2, 1): put(x, y, ids['bush'])
    small = ['grass1', 'grass2', 'grass3', 'grass1', 'grass2', 'flower', 'pebble', 'stone', 'bones', 'shroom']
    for _ in range(210):
        x, y = r.randrange(MAPW), r.randrange(MAPH)
        if not used[y][x]:
            m[y][x] = ids[r.choice(small)]
            used[y][x] = True
    return m

# ------------------------------------------------------------------ sprites
class MCSpr:
    def __init__(self):
        self.p = [[0] * 12 for _ in range(21)]
    def set(self, x, y, v):
        x, y = int(x), int(y)
        if 0 <= x < 12 and 0 <= y < 21: self.p[y][x] = v
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

def outline_of(mcs, extra=()):
    mask = [[mcs.p[y][x // 2] != 0 for x in range(24)] for y in range(21)]
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

# shared: 1 = $d025 red, 3 = $d026 yellow, 2 = own colour
HERO_ART = [
    "....CC......",
    "...CCCC.....",
    "..CCCCCC....",
    "..CCC..CC...",
    "..CC.Y.YC...",
    "..CCC..CC...",
    "..CCCCCC....",
    "..RRRRRR....",
    ".CCCCCCCC...",
    ".CCCCCCCCC..",
    ".CCCCCCC.C..",
    "CCCCCCCC..R.",
    "CCCCCCCC.YYY",
    "CCCCCCCC.YYY",
    ".CCCCCCC.YYY",
    ".CCCCCCC..R.",
    "..CCCCCC....",
]
LEGS = [["..C....C....", "..C....C...."],
        ["...C...C....", "..C.....C..."],
        ["..C....C....", "..C....C...."],
        ["..C...C.....", ".C.....C...."]]

def hero(phase, dead=False):
    """hooded wanderer with a lantern, facing right; rows 0..18 (19..20: health bar)"""
    s = MCSpr()
    m = {'.': 0, 'C': 2, 'R': 1, 'Y': 3}
    art = HERO_ART + LEGS[phase]
    for y, row in enumerate(art):
        for x, c in enumerate(row):
            s.set(x, y, m[c])
    # lantern swings a little
    if phase in (1, 3):
        for y in range(11, 16):
            for x in range(9, 12):
                v = s.p[y][x]
                s.p[y][x] = 0
                s.p[y][x] = v
    if dead:
        d = MCSpr()
        for y in range(21):
            for x in range(12):
                v = s.p[y][x]
                if v:
                    X = min(11, int(y * 11 / 19)); Y = 18 - int((11 - x) * 0.6)
                    d.set(X, Y, v); d.set(X, Y - 1, v)
        s = d
    h = outline_of(s)
    return s, h

def aura(phase):
    s = MCSpr()
    for k in range(28):
        a = k * 2 * math.pi / 28 + phase * 0.11
        x = 6 + 5.4 * math.cos(a)
        y = 10.5 + 9.6 * math.sin(a)
        if (k + phase) % 2 == 0:
            s.set(x, y, 2)
        else:
            s.set(x, y, 3)
    return s

def boss(kind, phase):
    s = MCSpr()
    if kind == 0:     # giant bat
        s.ellipse(6, 9, 2.6, 4.2, 2)
        wing = 1 if phase == 0 else -1
        for x in range(12):
            d = abs(x + .5 - 6)
            y0 = 7 - wing * int(d * 0.6)
            if d > 2: s.rect(x, max(0, y0), x, min(20, y0 + 3), 2)
        s.set(5, 8, 1); s.set(6, 8, 1)
        s.rect(5, 11, 6, 11, 3)
    elif kind == 1:   # ghoul king
        s.ellipse(6, 11, 4.6, 8.0, 2)
        s.rect(3, 1, 8, 3, 3)
        s.set(3, 0, 3); s.set(6, 0, 3); s.set(8, 0, 3)
        s.set(4, 7, 1); s.set(7, 7, 1)
        s.rect(4, 11, 7, 12, 1 if phase else 3)
        s.rect(0, 9, 1, 13 + phase, 2); s.rect(10, 9, 11, 13 + (1 - phase), 2)
    else:             # night lord
        for y in range(3, 21):
            w = 1.5 + (y - 3) * 0.28
            for x in range(12):
                if abs(x + .5 - 6) <= w: s.set(x, y, 2)
        s.ellipse(6, 4, 2.4, 3.0, 2)
        s.set(5, 4, 1); s.set(7, 4, 1)
        s.rect(1, 2, 2, 3 + phase, 3); s.rect(9, 2, 10, 3 + (1 - phase), 3)
        s.rect(4, 9, 7, 9, 1)
    return s

# ------------------------------------------------------------------ HUD digits (3 x 5)
DIG = {
    '0': ["###", "#.#", "#.#", "#.#", "###"], '1': [".#.", "##.", ".#.", ".#.", "###"],
    '2': ["###", "..#", "###", "#..", "###"], '3': ["###", "..#", ".##", "..#", "###"],
    '4': ["#.#", "#.#", "###", "..#", "..#"], '5': ["###", "#..", "###", "..#", "###"],
    '6': ["###", "#..", "###", "#.#", "###"], '7': ["###", "..#", ".#.", ".#.", ".#."],
    '8': ["###", "#.#", "###", "#.#", "###"], '9': ["###", "#.#", "###", "..#", "###"],
    ':': ["...", ".#.", "...", ".#.", "..."], 'L': ["#..", "#..", "#..", "#..", "###"],
    'V': ["#.#", "#.#", "#.#", "#.#", ".#."], ' ': ["...", "...", "...", "...", "..."],
    'K': ["#.#", "#.#", "##.", "#.#", "#.#"],
}
DIGORDER = "0123456789:LVK "

# ------------------------------------------------------------------ logo
def logo_bitmap():
    Wg, Hg = 7, 14
    def glyph(ch):
        g = [[0] * Wg for _ in range(Hg)]
        def rect(x0, y0, x1, y1):
            for y in range(max(0, y0), min(Hg, y1 + 1)):
                for x in range(max(0, x0), min(Wg, x1 + 1)): g[y][x] = 1
        if ch == 'N':
            rect(0, 0, 1, 13); rect(5, 0, 6, 13)
            for i in range(10): rect(1 + i // 3, 2 + i, 2 + i // 3, 3 + i)
        elif ch == 'I':
            rect(0, 0, 6, 1); rect(0, 12, 6, 13); rect(2, 0, 4, 13)
        elif ch == 'G':
            rect(1, 0, 6, 1); rect(0, 1, 1, 12); rect(1, 12, 6, 13); rect(5, 7, 6, 12); rect(3, 7, 6, 8)
        elif ch == 'H':
            rect(0, 0, 1, 13); rect(5, 0, 6, 13); rect(0, 6, 6, 7)
        elif ch == 'T':
            rect(0, 0, 6, 1); rect(2, 0, 4, 13)
        elif ch == 'O':
            rect(1, 0, 5, 1); rect(1, 12, 5, 13); rect(0, 1, 1, 12); rect(5, 1, 6, 12)
        elif ch == 'L':
            rect(0, 0, 1, 13); rect(0, 12, 6, 13)
        elif ch == 'D':
            rect(0, 0, 1, 13); rect(0, 0, 4, 1); rect(0, 12, 4, 13); rect(5, 1, 6, 12)
        return g
    WT = 80; bm = [[0] * WT for _ in range(Hg + 2)]
    x = 4
    for ch in "NIGHTHOLD":
        g = glyph(ch)
        for y in range(Hg):
            for xx in range(Wg):
                if g[y][xx]: bm[y + 1][x + xx] = 1
        x += Wg + 1
    return bm
