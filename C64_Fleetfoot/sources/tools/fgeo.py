# FLEETFOOT - track geometry
# Screen: rows 0-1 HUD, rows 2-8 scenery, rows 9-24 ground (pixel lines 72..199).
# Depth z in units of 1/32 lane; the runner stands at z = 96 (3 lanes from the camera).
# Pixel line of depth z:  y = HY + KZ / z ;  pixels per lane at depth z: LPX * 96 / z
HY = 72
KZ = 11136                 # (188 - 72) * 96
LPX = 48                   # pixels per lane at the runner
ZRUN = 96
VPX = 160
ROW0 = 9                   # first ground row
SOFT_ROWS = range(9, 18)   # far rows: objects drawn into unique characters
NEAR_Y = 144              # objects with a base line below this become sprites
STRIPE_TOP = 98            # no stripes above this line (too fine)
STRIPE_P = 64              # stripe period (depth units, power of two)
STRIPE_D = 14              # dark part of the period

def zof(y):
    return KZ / (y - HY) if y > HY else 1e9

def dxof(y):
    """pixels per lane on pixel line y"""
    return (y - HY) * LPX / (KZ / ZRUN)

LINES = [-1.5, -0.5, 0.5, 1.5]

def classify(px, y):
    """colour index of hires pixel column px (centre) on line y: 1 ground, 2 track, 3 line"""
    d = dxof(y)
    if d <= 0:
        return 1
    u = (px - VPX) / d
    for i, o in enumerate(LINES):
        outer = i in (0, 3)
        w = max(1.0, (0.10 if outer else 0.06) * d)     # pixels
        if abs(px - (VPX + o * d)) <= w / 2 + (0.5 if outer else 0.0):
            return 3
    if abs(u) < 1.5:
        return 2
    return 1

def mc_byte(cx, y, stripe):
    b = 0
    for i in range(4):
        px = cx * 8 + i * 2 + 1
        v = classify(px, y)
        if stripe and v != 3:
            v = 0
        b = (b << 2) | v
    return b

def stripe_on(y, scroll):
    if y < STRIPE_TOP:
        return 0
    z = int(zof(y)) + scroll
    return 1 if (z % STRIPE_P) < STRIPE_D else 0

# ---------------------------------------------------- object extents (for the soft region)
# objects: half width up to 0.45 lane, height up to 0.95 lane (coins in jump arcs up to 1.1)
def soft_cells():
    cells = {}
    for yb in range(HY + 2, NEAR_Y):
        d = dxof(yb)
        for lane in (-1, 0, 1):
            x0 = VPX + (lane - 0.47) * d
            x1 = VPX + (lane + 0.47) * d
            ytop = yb - 1.15 * d
            for y in range(int(ytop), yb + 1):
                r = y // 8
                if r < ROW0 or r not in SOFT_ROWS:
                    continue
                for cx in range(int(x0) // 8, int(x1) // 8 + 1):
                    lo, hi = cells.get(r, (99, -1))
                    cells[r] = (min(lo, cx), max(hi, cx))
    # always include the whole track width of the row
    for r in SOFT_ROWS:
        y = r * 8 + 7
        d = dxof(y)
        a = int(VPX - 1.6 * d) // 8
        b = int(VPX + 1.6 * d) // 8
        lo, hi = cells.get(r, (99, -1))
        cells[r] = (max(0, min(lo, a)), min(39, max(hi, b)))
    return cells
