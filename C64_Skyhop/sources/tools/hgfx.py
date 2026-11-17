# SKYHOP - graphics generator: background, platforms, items, moon, sprites, logo
import math

# ------------------------------------------------------------------ multicolour chars
# pixel values: 0 paper ($d021), 1 grid ($d022), 2 outline ($d023), 3 fill (colour RAM)
def mc_bytes(rows):
    """rows: 8 lists of 4 values -> 8 bytes"""
    out = []
    for r in rows:
        v = 0
        for k in range(4): v |= (r[k] & 3) << (6 - 2 * k)
        out.append(v)
    return bytes(out)

BG_EVEN = mc_bytes([[1, 0, 0, 0]] * 7 + [[1, 1, 1, 1]])     # vertical line every 16 px
BG_ODD = mc_bytes([[0, 0, 0, 0]] * 7 + [[1, 1, 1, 1]])      # horizontal line every 8 px

class Pix:
    """MC pixel canvas (w x h MC pixels), cut into chars"""
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.p = [[0] * w for _ in range(h)]
    def set(self, x, y, v):
        if 0 <= x < self.w and 0 <= y < self.h: self.p[y][x] = v
    def get(self, x, y):
        return self.p[y][x] if 0 <= x < self.w and 0 <= y < self.h else 0
    def rect(self, x0, y0, x1, y1, v):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1): self.set(x, y, v)
    def chars(self, grid_rows=True):
        """-> list of rows of char byte strings; empty pixels in char row 7 get the grid line"""
        out = []
        for cy in range(self.h // 8):
            row = []
            for cx in range(self.w // 4):
                rows = []
                for y in range(8):
                    r = []
                    for x in range(4):
                        v = self.p[cy * 8 + y][cx * 4 + x]
                        if v == 0 and y == 7 and grid_rows: v = 1
                        r.append(v)
                    rows.append(r)
                row.append(mc_bytes(rows))
            out.append(row)
        return out

def platform_pix(kind='plain'):
    """16 x 8 MC pixel platform, char rows 1..6"""
    p = Pix(16, 8)
    shape = ["..OOOOOOOOOOOO..",
             ".OFFFFFFFFFFFFO.",
             "OFFFFFFFFFFFFFFO",
             "OFFFFFFFFFFFFFFO",
             ".OFFFFFFFFFFFFO.",
             "..OOOOOOOOOOOO.."]
    for y, s in enumerate(shape):
        for x, c in enumerate(s):
            if c == 'O': p.set(x, y + 1, 2)
            elif c == 'F': p.set(x, y + 1, 3)
    if kind == 'plain':
        for x in range(3, 13, 3): p.set(x, 3, 1)          # little shine dots (grid colour)
    if kind == 'crack':
        for (x, y) in ((8, 1), (7, 2), (8, 3), (7, 4), (8, 5), (7, 6), (4, 3), (5, 4), (11, 2), (12, 3)):
            p.set(x, y, 2)
    if kind == 'broken':
        q = Pix(16, 8)
        for y in range(8):
            for x in range(16):
                v = p.get(x, y)
                if v == 0: continue
                if x < 7: q.set(x, min(7, y + (1 if x < 3 else 0)), v)
                elif x > 8: q.set(x, min(7, y + (1 if x > 12 else 0)), v)
        for y in range(1, 7):
            q.set(6, y + 1 if y < 6 else 7, 2); q.set(9, y + 1 if y < 6 else 7, 2)
        p = q
    if kind == 'poof':
        q = Pix(16, 8)
        for y in range(8):
            for x in range(16):
                if p.get(x, y) == 2 and (x + y) % 2 == 0: q.set(x, y, 2)
                if p.get(x, y) == 3 and (x * 3 + y) % 5 == 0: q.set(x, y, 3)
        p = q
    return p

def shifted(p, s, w=20):
    q = Pix(w, p.h)
    for y in range(p.h):
        for x in range(p.w):
            if p.p[y][x]: q.set(x + s, y, p.p[y][x])
    return q

def spring_pix(extended):
    if not extended:
        p = Pix(4, 8)
        rows = ["....", "....", "....", "OOOO", ".FF.", "OOOO", ".FF.", "OOOO"]
    else:
        p = Pix(4, 16)
        rows = ["....", "....", "OOOO", "OFFO", "OOOO", ".F..", "..F.", ".F..",
                "..F.", ".F..", "..F.", ".F..", "..F.", ".F..", "..F.", "OOOO"]
    for y, s in enumerate(rows):
        for x, c in enumerate(s):
            p.set(x, y, {'O': 2, 'F': 3}.get(c, 0))
    return p

def hat_pix():
    p = Pix(8, 8)
    rows = ["OOOOOOOO",
            "...OO...",
            "...OO...",
            "..OFFO..",
            ".OFFFFO.",
            "OFFFFFFO",
            "OOOOOOOO",
            "........"]
    for y, s in enumerate(rows):
        for x, c in enumerate(s): p.set(x, y, {'O': 2, 'F': 3}.get(c, 0))
    return p

def jet_pix():
    p = Pix(8, 16)
    rows = ["........",
            "........",
            ".OO..OO.",
            "OFFOOFFO",
            "OFFOOFFO",
            "OFFOOFFO",
            "OFFFFFFO",
            "OFFOOFFO",
            "OFFOOFFO",
            "OFFOOFFO",
            "OFFOOFFO",
            ".OO..OO.",
            ".OO..OO.",
            "........",
            "........",
            "........"]
    for y, s in enumerate(rows):
        for x, c in enumerate(s): p.set(x, y, {'O': 2, 'F': 3}.get(c, 0))
    return p

MOON_W, MOON_H = 10, 9          # chars

def moon_pix():
    W, H = MOON_W * 4, MOON_H * 8
    p = Pix(W, H)
    cx, cy, r = W / 2, H / 2 + 1, 19.0       # MC px are 2 hires px wide: x radius in MC px
    ry = r * 1.85
    for y in range(H):
        for x in range(W):
            d = ((x + .5 - cx) / r) ** 2 + ((y + .5 - cy) / ry) ** 2
            if d <= 1.0:
                p.set(x, y, 2 if d > 0.86 else 3)
    craters = [(14, 22, 3.0), (25, 30, 4.0), (12, 44, 2.5), (27, 52, 3.0), (19, 60, 2.0), (22, 14, 2.0), (8, 32, 2.0)]
    for (x0, y0, rr) in craters:
        for y in range(H):
            for x in range(W):
                d = ((x + .5 - x0) / rr) ** 2 + ((y + .5 - y0) / (rr * 1.8)) ** 2
                if d <= 1.0 and p.get(x, y) == 3:
                    p.set(x, y, 1 if d > 0.45 else 3)
    return p

def moon_top_offset():
    """y (MC pixel row inside the moon block) of the top surface in the centre"""
    p = moon_pix()
    for y in range(p.h):
        if p.get(p.w // 2, y): return y
    return 0

# ------------------------------------------------------------------ sprites
class MCSpr:
    """12 x 21 multicolour sprite: 0 transparent, 1 $d025 (dark), 2 sprite colour, 3 $d026 (white)"""
    def __init__(self):
        self.p = [[0] * 12 for _ in range(21)]
    def set(self, x, y, v):
        x, y = int(x), int(y)
        if 0 <= x < 12 and 0 <= y < 21: self.p[y][x] = v
    def get(self, x, y):
        return self.p[y][x] if 0 <= x < 12 and 0 <= y < 21 else 0
    def ellipse(self, cx, cy, rx, ry, v, only=None):
        for y in range(21):
            for x in range(12):
                if ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 <= 1:
                    if only is None or self.p[y][x] in only: self.p[y][x] = v
    def rect(self, x0, y0, x1, y1, v):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1): self.set(x, y, v)
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
    """24 x 21 hires sprite"""
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

def outline_of(mc, extra=()):
    """hires outline around the multicolour silhouette plus extra pixels"""
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

def hero(kind='stand'):
    """the hero facing right: (multicolour body, hires overlay)"""
    s = MCSpr()
    if kind == 'squash':
        cy, ry, rx = 12.8, 5.2, 5.2
    else:
        cy, ry, rx = 10.6, 6.0, 4.8
    cx = 5.9
    feet = 20
    ly0 = int(cy + ry) - 1
    for lx in (4, 7):
        s.rect(lx, ly0, lx, feet - 1, 1)
        s.rect(lx, feet, lx + 1, feet, 1)
    s.ellipse(cx, cy, rx, ry, 2)
    # dark rim on the lower left
    for y in range(21):
        for x in range(12):
            if s.p[y][x] != 2: continue
            edge = s.get(x - 1, y) == 0 or s.get(x, y + 1) in (0, 1)
            if edge and (x < cx - 1 or y > cy + 2): s.p[y][x] = 1
    extra = []
    top = min(y for y in range(21) for x in range(12) if s.p[y][x] == 2)
    if kind in ('stand', 'squash', 'shoot', 'dead'):
        s.set(5, top - 1, 1); s.set(5, top - 2, 1); s.set(4, top - 3, 3); s.set(5, top - 3, 3)
    if kind == 'shoot':
        s.ellipse(6.2, cy - 2.4, 1.9, 2.2, 3)
        extra += [(12, int(cy - 4)), (13, int(cy - 4)), (12, int(cy - 3)), (13, int(cy - 3))]
        s.rect(5, int(cy + 2), 6, int(cy + 3), 1)
    else:
        ex, ey = 7.6, cy - 1.6
        s.ellipse(ex, ey, 1.9, 2.4, 3)
        px, py = int(ex * 2) + 1, int(ey)
        if kind == 'dead':
            for d in range(-2, 3):
                extra += [(px + d, py + d), (px + d, py - d)]
        else:
            extra += [(px, py), (px + 1, py), (px, py + 1), (px + 1, py + 1)]
        my = int(cy + 2.4)
        s.set(7, my, 1); s.set(8, my + 1, 1); s.set(9, my, 1)
    h = outline_of(s, extra)
    return s, h

def hero_hat(phase):
    s, h = hero('stand')
    # propeller cap replaces the antenna
    top = min(y for y in range(21) for x in range(12) if s.p[y][x] == 2)
    for y in range(0, top):
        for x in range(12):
            if s.p[y][x] == 3 or s.p[y][x] == 1: s.p[y][x] = 0
    cap = top - 2
    s.rect(3, cap, 8, cap + 1, 3)
    s.rect(4, cap - 1, 7, cap - 1, 3)
    h = outline_of(s, [])
    # propeller blades (hires, black)
    by = cap - 3
    h.set(11, by + 1); h.set(12, by + 1)
    for d in range(2, 9 if phase == 0 else 4):
        h.set(11 - d, by); h.set(12 + d, by)
    return s, h

def hero_jet(phase):
    s, h0 = hero('stand')
    # tanks on the back (left)
    s.rect(0, 7, 1, 13, 1)
    s.rect(0, 8, 0, 12, 3)
    # flames
    fl = [(0, 14), (1, 14), (0, 15), (1, 15), (0, 16), (1, 17)] if phase == 0 else [(0, 14), (1, 14), (1, 15), (0, 16), (0, 17), (1, 18)]
    for (x, y) in fl: s.set(x, y, 3 if y < 16 else 2)
    eyes = []
    for y in range(21):
        for x in range(24):
            if h0.p[y][x] and s.p[y][x // 2] != 0:
                eyes.append((x, y))           # keep pupils etc. that lie inside the body
    h = outline_of(s, eyes)
    return s, h

def monster_blob(phase):
    s = MCSpr()
    w = 0.4 if phase else 0.0
    s.ellipse(6.0, 11.5, 5.8 + w, 7.0 - w, 2)
    for x in range(1, 11, 2):            # wobbly feet
        s.set(x, int(18.5 - w), 2)
    # dark rim
    for y in range(21):
        for x in range(12):
            if s.p[y][x] == 2:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if s.get(x + dx, y + dy) == 0:
                        s.p[y][x] = 1; break
    s.ellipse(4.0, 8.5, 1.4, 2.0, 3); s.ellipse(8.0, 8.5, 1.4, 2.0, 3)
    s.set(4, 9, 1); s.set(8, 9, 1)
    s.rect(3, 13, 8, 14, 1)
    for x in (3, 5, 7):
        s.set(x, 13, 3)
    s.set(5, 3 if phase else 4, 1); s.set(6, 2 if phase else 3, 1); s.set(7, 3 if phase else 4, 1)   # horns
    return s

def monster_bat(phase):
    s = MCSpr()
    s.ellipse(6.0, 10.5, 3.0, 4.6, 2)
    # wings as fans of rows
    for i in range(1, 6):
        if phase == 0:
            y0, y1 = 6 + i // 2, 12 - (i + 1) // 3
        else:
            y0, y1 = 10, 14 + i // 2
        s.rect(3 - i + 1, y0, 3 - i + 1, y1, 2)
        s.rect(8 + i - 1, y0, 8 + i - 1, y1, 2)
    for y in range(21):                      # dark edge
        for x in range(12):
            if s.p[y][x] == 2:
                for dx, dy in ((0, 1), (0, -1)):
                    if s.get(x + dx, y + dy) == 0:
                        s.p[y][x] = 1; break
    s.set(5, 9, 3); s.set(7, 9, 3)
    s.set(5, 5, 2); s.set(7, 5, 2)
    s.set(6, 12, 1)
    return s

def monster_hole(phase):
    s = MCSpr()
    for y in range(21):
        for x in range(12):
            dx, dy = (x + .5 - 6.0) / 6.0, (y + .5 - 10.5) / 10.5
            d = math.hypot(dx, dy)
            if d > 1.0: continue
            a = math.atan2(dy, dx) + (0.5 if phase else 0.0)
            band = (d * 5.0 + a * 0.8) % 2.0
            if d < 0.28: v = 2
            elif band < 0.7: v = 3 if d > 0.6 else 1
            else: v = 2
            s.set(x, y, v)
    return s

def bullet():
    h = HSpr()
    for (x, y) in ((1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2), (1, 3), (2, 3)):
        h.set(x, y)
    return h

def flag():
    """moon flag (multicolour): pole and a little banner"""
    s = MCSpr()
    s.rect(3, 4, 3, 20, 1)
    s.rect(4, 4, 9, 9, 2)
    s.rect(5, 6, 8, 7, 3)
    return s

# ------------------------------------------------------------------ logo "SKYHOP"
def logo_bitmap():
    W, H = 11, 14
    def glyph(ch):
        g = [[0] * W for _ in range(H)]
        def rect(x0, y0, x1, y1):
            for y in range(max(0, y0), min(H, y1 + 1)):
                for x in range(max(0, x0), min(W, x1 + 1)): g[y][x] = 1
        if ch == 'S':
            rect(1, 0, 10, 2); rect(0, 1, 2, 6); rect(1, 5, 9, 7); rect(8, 6, 10, 12); rect(0, 11, 9, 13)
        elif ch == 'K':
            rect(0, 0, 2, 13)
            for i in range(7):
                rect(3 + i, 6 - i, 5 + i, 6 - i); rect(3 + i, 7 + i, 5 + i, 7 + i)
            rect(3, 6, 5, 7)
        elif ch == 'Y':
            for i in range(6):
                rect(i, i, i + 2, i); rect(10 - i - 2, i, 10 - i, i)
            rect(4, 6, 6, 13)
        elif ch == 'H':
            rect(0, 0, 2, 13); rect(8, 0, 10, 13); rect(0, 5, 10, 8)
        elif ch == 'O':
            rect(1, 0, 9, 2); rect(1, 11, 9, 13); rect(0, 1, 2, 12); rect(8, 1, 10, 12)
        elif ch == 'P':
            rect(0, 0, 2, 13); rect(0, 0, 9, 2); rect(0, 6, 9, 8); rect(8, 1, 10, 7)
        return g
    WT = 80; bm = [[0] * WT for _ in range(H + 2)]
    x = 4
    for i, ch in enumerate("SKYHOP"):
        g = glyph(ch)
        lift = [0, 1, 0, 1, 0, 1][i]          # bouncy letters
        for y in range(H):
            for xx in range(W):
                if g[y][xx]:
                    Y = y + lift
                    X = x + xx
                    if 0 <= X < WT: bm[Y][X] = 1
        x += W + 1
    return bm
