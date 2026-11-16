# GULP! - seabed scenery per zone (multicolour chars, deduplicated)
import math, random

TOP = 3          # first screen row of the scenery map
ROWS = 22        # rows 3..24
W = 160          # MC pixels
H = ROWS * 8

# zone: bg, d022, d023, material -> (role, colour for role 3)
ZONES = [
    dict(bg=3, d022=4, d023=10, plank=1,
         mat={'sand': (3, 7), 'sdot': (2, 0), 'coA': (1, 0), 'coB': (2, 0), 'weed': (3, 5), 'rock': (2, 0), 'rhi': (1, 0)}),
    dict(bg=14, d022=12, d023=11, plank=3,
         mat={'sand': (3, 7), 'sdot': (2, 0), 'rock': (1, 0), 'rhi': (2, 0), 'kelp': (3, 5), 'weed': (3, 5), 'coA': (1, 0), 'coB': (2, 0)}),
    dict(bg=0, d022=6, d023=14, plank=4,
         mat={'sand': (1, 0), 'sdot': (2, 0), 'rock': (2, 0), 'rhi': (1, 0), 'tube': (3, 2), 'glow': (2, 0), 'chest': (3, 7), 'cdk': (1, 0), 'weed': (3, 4)}),
]

PRIO = ['chest', 'tube', 'sand', 'kelp', 'weed', 'rock']    # which role-3 colour wins in a cell

class Img:
    def __init__(self):
        self.p = [[None] * W for _ in range(H)]
    def set(self, x, y, m):
        x = int(x); y = int(y)
        if 0 <= x < W and 0 <= y < H: self.p[y][x] = m
    def get(self, x, y):
        if 0 <= x < W and 0 <= y < H: return self.p[y][x]
        return None

def sand(im, base):
    wave = [0, 0, 0, 1, 1, 1, 1, 0, 0, 0, -1, -1, -1, -1, 0, 0]
    for x in range(W):
        top = base + wave[x % 16]
        for y in range(top, H):
            im.set(x, y, 'sand')
        if (x % 32) in (5, 19): im.set(x, top + 3, 'sdot')
        if (x % 32) in (11, 27): im.set(x, top + 6, 'sdot')
        if (x % 32) == 13: im.set(x, top + 10, 'sdot')

def rock(im, cx, base, rx, ry):
    for y in range(base - ry, base + 1):
        for x in range(cx - rx, cx + rx + 1):
            dx = (x - cx) / rx; dy = (y - base) / ry
            wob = 0.12 * math.sin(x * 1.3 + y * 0.7)
            if dx * dx + dy * dy <= 1 + wob:
                m = 'rock'
                if dx * dx + dy * dy > 0.5 and dy < -0.25 and dx < 0.4: m = 'rhi'
                elif (x * 7 + y * 3) % 11 == 0: m = 'rhi'
                im.set(x, y, m)

def coral(im, x, base, h, rnd):
    # branching staghorn coral, 2-3 px thick
    def branch(x0, y0, ang, L, th):
        for i in range(int(L)):
            xx = x0 + math.cos(ang) * i * 0.5; yy = y0 - math.sin(ang) * i
            for t in range(th): im.set(xx + t, yy, 'coA')
        tx = x0 + math.cos(ang) * L * 0.5; ty = y0 - math.sin(ang) * L
        im.set(tx, ty, 'coB'); im.set(tx + 1, ty, 'coB')
        return tx, ty
    branch(x, base, math.pi / 2, h, 3)
    for k in range(4):
        y0 = base - h * (0.25 + 0.18 * k)
        d = 1 if k % 2 else -1
        tx, ty = branch(x + 1, y0, math.pi / 2 - d * 0.7, h * 0.45, 2)
        branch(tx, ty, math.pi / 2, h * 0.2, 2)

def brain(im, cx, base, rx, ry):
    for y in range(base - ry, base + 1):
        for x in range(cx - rx, cx + rx + 1):
            dx = (x - cx) / rx; dy = (y - base) / ry
            if dx * dx + dy * dy <= 1:
                im.set(x, y, 'coB' if (y + (x // 3)) % 3 == 0 else 'coA')

def weed(im, x, base, h, ph):
    for y in range(base - h, base + 1):
        t = base - y
        xx = x + math.sin((t + ph) * 0.45) * 1.2
        im.set(xx, y, 'weed')
        if t % 5 == 2: im.set(xx + 1, y, 'weed')

def kelp(im, x, base, h):
    # tall stalk with leaves every 8 lines (periodic -> few unique chars)
    for y in range(base - h, base + 1):
        im.set(x, y, 'kelp')
        t = (base - y) % 16
        if t in (3, 4, 5): im.set(x + 1 + (t - 3), y, 'kelp')
        if t in (11, 12, 13): im.set(x - 1 - (t - 11), y, 'kelp')

def tube(im, x, base, h):
    for y in range(base - h, base + 1):
        im.set(x, y, 'tube'); im.set(x + 1, y, 'tube')
    im.set(x, base - h - 1, 'glow'); im.set(x + 1, base - h - 1, 'glow'); im.set(x, base - h - 2, 'glow')

def chest(im, x, base):
    for y in range(base - 9, base + 1):
        for xx in range(x, x + 12):
            m = 'chest'
            if y in (base - 9, base - 5, base) or xx in (x, x + 11): m = 'cdk'
            im.set(xx, y, m)
    im.set(x + 6, base - 4, 'glow'); im.set(x + 5, base - 4, 'glow')

def build(zone):
    im = Img(); rnd = random.Random(10 + zone)
    sbase = H - 16              # sand top (screen row 22)
    if zone == 0:
        for cx, rx, ry in ((14, 9, 14), (98, 11, 16), (150, 8, 10)):
            rock(im, cx, sbase + 1, rx, ry)
        for cx, rx, ry in ((42, 8, 8),):
            brain(im, cx, sbase + 1, rx, ry)
        for x, h in ((26, 34), (60, 44), (118, 38), (136, 26)):
            coral(im, x, sbase, h, rnd)
        for x, h, ph in ((4, 14, 0), (44, 18, 3), (66, 12, 5), (88, 16, 1), (110, 13, 2)):
            weed(im, x, sbase, h, ph)
    elif zone == 1:
        for cx, rx, ry in ((20, 12, 16), (84, 14, 14), (136, 11, 18)):
            rock(im, cx, sbase + 1, rx, ry)
        for x, h in ((8, 120), (40, 140), (60, 96), (104, 150), (148, 112)):
            kelp(im, x, sbase, h)
        for x, h, ph in ((30, 12, 0), (72, 16, 2), (120, 10, 4)):
            weed(im, x, sbase, h, ph)
    else:
        for cx, rx, ry in ((10, 12, 22), (60, 9, 12), (112, 14, 26), (154, 9, 16)):
            rock(im, cx, sbase + 1, rx, ry)
        for x, h in ((26, 22), (32, 30), (38, 16), (86, 26), (92, 18), (132, 24), (138, 34)):
            tube(im, x, sbase, h)
        chest(im, 66, sbase + 4)
        for x, h, ph in ((48, 10, 1), (100, 12, 3), (144, 9, 0)):
            weed(im, x, sbase, h, ph)
    sand(im, sbase)
    return im

def encode(zone):
    Z = ZONES[zone]; im = build(zone)
    chars = []; index = {}
    cmap = []; colmap = []
    for r in range(ROWS):
        row = []; crow = []
        for c in range(40):
            mats = set()
            for y in range(8):
                for x in range(4):
                    m = im.p[r * 8 + y][c * 4 + x]
                    if m: mats.add(m)
            if not mats:
                row.append(None); crow.append(None); continue
            col = 0
            for m in PRIO:
                if m in mats and Z['mat'][m][0] == 3:
                    col = Z['mat'][m][1]; break
            data = bytearray(8)
            for y in range(8):
                b = 0
                for x in range(4):
                    m = im.p[r * 8 + y][c * 4 + x]
                    role = Z['mat'][m][0] if m else 0
                    b |= role << (6 - 2 * x)
                data[y] = b
            key = (bytes(data), col)
            if key not in index:
                index[key] = len(chars); chars.append(key)
            row.append(index[key]); crow.append(col | 8)
        cmap.append(row); colmap.append(crow)
    return chars, cmap, colmap

if __name__ == '__main__':
    for z in range(3):
        ch, m, c = encode(z)
        print('zone', z, 'unique chars', len(ch))
