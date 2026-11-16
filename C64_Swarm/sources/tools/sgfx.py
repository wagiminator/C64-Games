# SWARM - graphics (original alien designs, bunkers, sprites, bosses)
import math, random
from gfx import (FONT, screencode, glyph_bytes, Spr, big_slices, make_patterns,
                 CH_QUAD, CH_BG, CH_BAR, CH_BARL, CH_BARR, CH_SHIP, NPAT)

CH_ALIEN = 128      # 3 types * 2 frames * 4 offsets * 3 chars = 72 -> 128..199
CH_BUNK = 200       # 4 bunkers * 6 chars = 24 -> 200..223
CH_GROUND = 224
CH_LIFE = 225

# 12x8 alien art, 3 sectors x 3 types x 2 frames ('X' = pixel)
ALIENS = [
  [
    [
      ["....XXXX....", "..XXX..XXX..", ".XX.X..X.XX.", "XXXXX..XXXXX", "XXXXX..XXXXX", ".XXXX..XXXX.", "X.X.X..X.X.X", "X..........X"],
      ["....XXXX....", "..XXX..XXX..", ".XX.X..X.XX.", "XXXXX..XXXXX", "XXXXX..XXXXX", ".XXXX..XXXX.", ".X.X.XX.X.X.", "..X......X.."],
    ],
    [
      ["XX........XX", "XXX..XX..XXX", ".XXXXXXXXXX.", "...X.XX.X...", "....XXXX....", "....X..X....", ".....XX.....", "............"],
      ["............", "XX...XX...XX", "XXXXXXXXXXXX", "...X.XX.X...", "....XXXX....", "....X..X....", ".....XX.....", ".....XX....."],
    ],
    [
      ["....XXXX....", "...XX..XX...", "X.XXXXXXXX.X", ".X.XXXXXX.X.", "X.X.XXXX.X.X", "...X....X...", "..X......X..", "............"],
      ["....XXXX....", "...XX..XX...", "..XXXXXXXX..", "XX.XXXXXX.XX", "..X.XXXX.X..", ".X..X..X..X.", "X..........X", "............"],
    ],
  ],
  [
    [
      ["....XXXX....", "..XXXXXXXX..", ".XXX.XX.XXX.", "XXX..XX..XXX", ".XXX.XX.XXX.", "..XXXXXXXX..", "...X.XX.X...", "..X......X.."],
      ["....XXXX....", "..XXXXXXXX..", ".XXXX..XXXX.", "XXXX.XX.XXXX", ".XXXX..XXXX.", "..XXXXXXXX..", "...X.XX.X...", "...X....X..."],
    ],
    [
      [".XXXXXXXXXX.", ".X..XXXX..X.", ".XXXXXXXXXX.", ".X.X.XX.X.X.", ".XXXXXXXXXX.", "...XX..XX...", "..XXX..XXX..", "............"],
      [".XXXXXXXXXX.", ".XX..XX..XX.", ".XXXXXXXXXX.", ".X.X.XX.X.X.", ".XXXXXXXXXX.", "..XX....XX..", ".XXX....XXX.", "............"],
    ],
    [
      [".X........X.", "..X......X..", "...XXXXXX...", "..XX.XX.XX..", "..XXXXXXXX..", "XXXXXXXXXXXX", "X..X....X..X", "...XX..XX..."],
      ["X..........X", ".X........X.", "...XXXXXX...", "..XX.XX.XX..", "..XXXXXXXX..", "XXXXXXXXXXXX", "...X....X...", "..XX....XX.."],
    ],
  ],
  [
    [
      [".....XX.....", "....XXXX....", "...XX..XX...", "..XXX..XXX..", ".XXXXXXXXXX.", "..XX.XX.XX..", "...X....X...", "....X..X...."],
      [".....XX.....", "....X..X....", "...XXXXXX...", "..XX.XX.XX..", ".XXXXXXXXXX.", "..XXX..XXX..", "...X....X...", "...X....X..."],
    ],
    [
      ["X.X......X.X", ".XXX.XX.XXX.", "XXXXXXXXXXXX", "XX.XX..XX.XX", ".XXX.XX.XXX.", "..X..XX..X..", ".....XX.....", "............"],
      ["............", "X.X..XX..X.X", "XXXX.XX.XXXX", "XXXXXXXXXXXX", "XX.XX..XX.XX", ".X...XX...X.", ".....XX.....", "............"],
    ],
    [
      ["...XXXXXX...", "..XXXXXXXX..", ".XX.XXXX.XX.", ".XXXXXXXXXX.", "..X.X..X.X..", "..X..X.X..X.", ".X..X...X.X.", "....X....X.."],
      ["...XXXXXX...", "..XXXXXXXX..", ".XX.XXXX.XX.", ".XXXXXXXXXX.", "..X.X..X.X..", ".X..X..X..X.", "..X..X..X..X", "..X..X......"],
    ],
  ],
]

BUNKER = [
    "...XXXXXXXXXXXXXXXXXX...",
    "..XXXXXXXXXXXXXXXXXXXX..",
    ".XXXXXXXXXXXXXXXXXXXXXX.",
    "XXXXXXXXXXXXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXXXXXXXXXXXX",
    "XXXXXXX..........XXXXXXX",
    "XXXXXX............XXXXXX",
    "XXXXX..............XXXXX",
    "XXXXX..............XXXXX",
    "XXXXX..............XXXXX",
    "XXXXX..............XXXXX",
]

def alien_chars(sector):
    out = bytearray()
    for t in range(3):
        for f in range(2):
            art = ALIENS[sector][t][f]
            for o in range(4):
                sh = o * 2
                for k in range(3):
                    for y in range(8):
                        b = 0
                        for i in range(8):
                            x = k * 8 + i - sh
                            if 0 <= x < 12 and art[y][x] == 'X': b |= 0x80 >> i
                        out.append(b)
    assert len(out) == 72 * 8
    return out

def bunker_chars():
    out = bytearray()
    for bk in range(4):
        for j in range(2):
            for i in range(3):
                for y in range(8):
                    b = 0
                    for x in range(8):
                        if BUNKER[j * 8 + y][i * 8 + x] == 'X': b |= 0x80 >> x
                    out.append(b)
    return out

def build_charset():
    cs = bytearray(2048)
    for ch, rows in FONT.items():
        sc = screencode(ch); cs[sc * 8:sc * 8 + 8] = bytes(glyph_bytes(rows))
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
    for p, bm in enumerate(make_patterns()):
        for k in range(2):
            for y in range(8):
                b = 0
                for i in range(8):
                    if bm[y][k * 8 + i]: b |= 0x80 >> i
                cs[(CH_BG + p * 2 + k) * 8 + y] = b
    for n in range(5):
        for y in range(8):
            if y in (0, 7): b = 0xFF
            elif y in (1, 6): b = 0
            else: b = (0xFF << (8 - n * 2)) & 0xFF
            cs[(CH_BAR + n) * 8 + y] = b
    cs[CH_BARL * 8:CH_BARL * 8 + 8] = bytes([0x07, 0x08, 0x10, 0x10, 0x10, 0x10, 0x08, 0x07])
    cs[CH_BARR * 8:CH_BARR * 8 + 8] = bytes([0xE0, 0x10, 0x08, 0x08, 0x08, 0x08, 0x10, 0xE0])
    cs[CH_ALIEN * 8:(CH_ALIEN + 72) * 8] = alien_chars(0)
    cs[CH_BUNK * 8:(CH_BUNK + 24) * 8] = bunker_chars()
    cs[CH_GROUND * 8:CH_GROUND * 8 + 8] = bytes([0xFF, 0xAA, 0x55, 0, 0, 0, 0, 0])
    cs[CH_LIFE * 8:CH_LIFE * 8 + 8] = bytes([0x18, 0x18, 0x3C, 0x7E, 0xFF, 0xFF, 0x00, 0x00])
    return cs

# ---------------------------------------------------------------- sprites
def make_sprites():
    S = {}
    # player: hover tank (bottom rows of sprite)
    base = [
        ".....33.....",
        ".....22.....",
        "....1221....",
        "...122221...",
        ".1222332221.",
        "122222222221",
        "131313131311",
        ".1........1.",
    ]
    p = Spr(); p.ascii(base, 0, 13)
    S['player'] = [p]
    # player explosion (4)
    ex = []
    rr = random.Random(3)
    parts = [(rr.uniform(math.pi, 2 * math.pi), rr.uniform(0.4, 1.0)) for _ in range(18)]
    for f in range(4):
        s = Spr()
        for (a, sp) in parts:
            r = 1 + f * 2.2 * sp
            x = 6 + math.cos(a) * r * 0.9; y = 18 + math.sin(a) * r * 1.4
            s.set(x, y, 3 if f < 2 else 2)
        s.ellipse(6, 18, 3 - f * 0.6, 2.5 - f * 0.5, 2 if f < 2 else 1) if f < 3 else None
        ex.append(s)
    S['pdie'] = ex
    # player bullet
    s = Spr(); s.rect(5, 6, 5, 13, 3); s.rect(6, 6, 6, 13, 2); S['bullet'] = [s]
    # alien bullets: zigzag + plasma
    ab = []
    for f in range(2):
        s = Spr()
        for y in range(4, 16):
            x = 5 + ((y // 2 + f) % 2)
            s.set(x, y, 3 if y % 3 else 2)
        ab.append(s)
    for f in range(2):
        s = Spr(); s.ellipse(6, 10 + f, 1.6, 3.2, 0, shade=True); s.set(6, 9 + f, 3); ab.append(s)
    S['abullet'] = ab
    # explosion (alien) 4 frames
    ae = []
    for f in range(4):
        s = Spr()
        for k in range(10):
            a = k * math.tau / 10 + f * 0.2
            r = 2 + f * 1.6
            s.set(6 + math.cos(a) * r * 0.55, 10 + math.sin(a) * r, 3 if f < 2 else 2)
            if f < 3: s.set(6 + math.cos(a) * (r - 1.5) * 0.55, 10 + math.sin(a) * (r - 1.5), 2)
        ae.append(s)
    S['aexpl'] = ae
    # UFO (original saucer with dome) 2 frames
    uf = []
    for f in range(2):
        s = Spr()
        s.ellipse(6, 7, 2.5, 3.5, 3)
        s.ellipse(6, 11, 6, 3.2, 2)
        s.rect(0, 11, 11, 11, 1)
        for k in range(4):
            s.set(1 + ((k * 3 + f) % 11), 12, 3)
        s.rect(3, 14, 8, 14, 1)
        uf.append(s)
    S['ufo'] = uf
    # capsules R D S +
    LET = {'R': ["333.", "3..3", "333.", "3.3.", "3..3"], 'D': ["333.", "3..3", "3..3", "3..3", "333."],
           'S': [".33.", "3...", ".33.", "...3", "333."], '+': ["....", ".3..", "333.", ".3..", "...."]}
    cp = []
    for l in "RDS+":
        s = Spr(); s.ellipse(6, 10.5, 5.8, 7.8, 2); s.outline()
        for y in range(21):
            for x in range(12):
                if s.p[y][x] == 2 and (x <= 2 or y <= 5): s.p[y][x] = 1 if (x + y) % 2 else 2
        s.ascii(LET[l], 4, 8); cp.append(s)
    S['capsule'] = cp
    return S

def shade_ellipse(c, cx, cy, rx, ry, rim=1, mid=2, hi=3):
    for y in range(c.h):
        for x in range(c.w):
            dx = (x + .5 - cx) / rx; dy = (y + .5 - cy) / ry
            d = dx * dx + dy * dy
            if d <= 1:
                l = -dx * 0.6 - dy * 0.8
                c.p[y][x] = rim if d > 0.8 else (hi if l > 0.5 and d < 0.6 else mid)

def make_bosses():
    # 24 x 21 MC canvas -> 2 sprites side by side, shown X/Y expanded (96 x 42 pixels)
    B = []
    rnd = random.Random(5)
    # 1: hive carrier - wide saucer with dome and hangar bays
    c = Spr(24, 21)
    shade_ellipse(c, 12, 6.5, 5, 5.5, 1, 3, 3); c.ellipse(12, 7, 2, 2, 1); c.set(12, 6, 3)
    shade_ellipse(c, 12, 12, 12, 4.5)
    c.rect(0, 12, 23, 12, 1)
    for x in range(2, 22, 4): c.rect(x, 13, x + 1, 14, 1); c.set(x, 13, 3)
    for x in (4, 12, 19): c.rect(x, 16, x, 19, 1); c.set(x, 20, 3)
    B.append(c)
    # 2: battle station - angular wedge with cannons
    c = Spr(24, 21)
    for y in range(2, 17):
        w = 3 + (y - 2) * 9 // 14
        for x in range(12 - w, 12 + w):
            c.p[y][x] = 1 if (y in (2, 16) or x in (12 - w, 11 + w)) else (2 if (x + y) % 6 else 1)
    for y in (6, 10, 14): c.rect(12 - (3 + (y - 2) * 9 // 14) + 1, y, 12 + (3 + (y - 2) * 9 // 14) - 2, y, 1)
    shade_ellipse(c, 12, 9, 3, 3.5, 1, 3, 3); c.ellipse(12, 9.5, 1, 1.5, 1)
    for x in (4, 19):
        c.rect(x, 15, x, 20, 3); c.rect(x + 1, 15, x + 1, 19, 1)
    c.rect(11, 17, 12, 20, 3)
    B.append(c)
    # 3: swarm queen - organic body with eyes and legs
    c = Spr(24, 21)
    for k in range(6):
        a = 0.35 + k * (math.pi - 0.7) / 5
        for t in range(13):
            c.set(12 + math.cos(a) * t, 9 + math.sin(a) * t * 0.9, 1 if t % 3 else 2)
    shade_ellipse(c, 12, 8.5, 10, 7.5)
    for k in range(8):
        a = rnd.uniform(0, math.tau)
        c.line(12 + math.cos(a) * 3, 8.5 + math.sin(a) * 2, 12 + math.cos(a) * 9, 8.5 + math.sin(a) * 7, 1)
    shade_ellipse(c, 8, 10, 2.5, 3, 1, 3, 3); shade_ellipse(c, 16, 10, 2.5, 3, 1, 3, 3)
    c.set(8, 11, 1); c.set(16, 11, 1)
    B.append(c)
    return B

def build_sprites():
    S = make_sprites()
    order = [(k, S[k]) for k in ['player', 'pdie', 'bullet', 'abullet', 'aexpl', 'ufo', 'capsule']]
    for i, b in enumerate(make_bosses()):
        order.append(('boss%d' % (i + 1), big_slices(b, 2, 1)))
    data = bytearray(); syms = {}; ptr = 0x40
    for name, frames in order:
        syms[name] = ptr
        for f in frames:
            data += f.tobytes(); ptr += 1
    return data, syms

def preview(path, cs, spr):
    from PIL import Image
    im = Image.new('RGB', (640, 300), (20, 20, 30))
    for sec in range(3):
        a = alien_chars(sec)
        for t in range(3):
            for f in range(2):
                art = ALIENS[sec][t][f]
                ox = sec * 200 + t * 60 + f * 28; oy = 10
                for y in range(8):
                    for x in range(12):
                        if art[y][x] == 'X':
                            for k in range(2):
                                for j in range(2): im.putpixel((ox + x * 2 + k, oy + y * 2 + j), (120, 255, 120))
    n = len(spr) // 64
    for i in range(n):
        b = spr[i * 64:i * 64 + 64]; ox = (i % 12) * 52; oy = 40 + (i // 12) * 46
        for y in range(21):
            for x in range(12):
                v = (b[y * 3 + x // 4] >> (6 - 2 * (x % 4))) & 3
                col = [None, (80, 80, 80), (191, 206, 114), (255, 255, 255)][v]
                if col:
                    for k in range(4):
                        for j in range(2): im.putpixel((ox + x * 4 + k, oy + y * 2 + j), col)
    im.save(path)
