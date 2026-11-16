# VEXOR - vertical level generator
import random

E_FLYER, E_SWOOP, E_TURRET, E_ROCK, E_DIVER, E_SIDER, E_MINE, E_RISER, E_POD = 1, 2, 3, 4, 5, 6, 7, 8, 9
EV_SHOP = 20
COLS = 40
MINOPEN = 15
LEN = [400, 440, 470, 500, 530]
ARENA = 40

STYLE = [
    dict(maxw=10, runs=(3, 9), slope=0.6, isl=0.25),
    dict(maxw=11, runs=(2, 6), slope=0.7, isl=0.35),
    dict(maxw=10, runs=(4, 10), slope=0.5, isl=0.45),
    dict(maxw=12, runs=(2, 7), slope=0.75, isl=0.35),
    dict(maxw=12, runs=(2, 6), slope=0.75, isl=0.45),
]
MIX = [
    [E_FLYER, E_SWOOP, E_ROCK, E_FLYER, E_POD, E_DIVER],
    [E_FLYER, E_SIDER, E_SWOOP, E_MINE, E_POD, E_RISER],
    [E_SWOOP, E_DIVER, E_SIDER, E_FLYER, E_POD, E_MINE],
    [E_ROCK, E_RISER, E_FLYER, E_SWOOP, E_POD, E_SIDER],
    [E_FLYER, E_SWOOP, E_DIVER, E_RISER, E_MINE, E_POD, E_SIDER],
]

def code(d): return {0: 0, 1: 1, -1: 2}[d]

def gen_level(li):
    rnd = random.Random(500 + li * 31)
    st = STYLE[li]; L = LEN[li]
    l, r = 2, 2
    runs = []; hl = [l]; hr = [r]
    def addrun(n, dl, dr):
        nonlocal l, r
        runs.append((n, code(dl) | (code(dr) << 2)))
        for _ in range(n):
            l += dl; r += dr; hl.append(l); hr.append(r)
    addrun(30, 0, 0)
    while len(hl) < L:
        n = rnd.randint(*st['runs'])
        dl = rnd.choice((-1, 1)) if rnd.random() < st['slope'] else 0
        dr = rnd.choice((-1, 1)) if rnd.random() < st['slope'] else 0
        n2 = 0
        for k in range(n):
            nl, nr = l + dl, r + dr
            if nl < 1 or nl > st['maxw'] or nr < 1 or nr > st['maxw'] or COLS - nl - nr < MINOPEN: break
            n2 += 1; l, r = nl, nr; hl.append(l); hr.append(r)
        for k in range(n2): hl.pop(); hr.pop()
        l -= dl * n2; r -= dr * n2
        if n2: addrun(n2, dl, dr)
        else: addrun(rnd.randint(2, 4), 0, 0)
    while l != 2 or r != 2:
        addrun(1, -1 if l > 2 else (1 if l < 2 else 0), -1 if r > 2 else (1 if r < 2 else 0))
    addrun(ARENA + 40, 0, 0)
    stoprow = len(hl) - 40 - 2
    # ---- islands (row, col, w, h) ; keep passages
    isl = []
    row = 50
    while row < stoprow - 40:
        if rnd.random() < st['isl']:
            h = rnd.randint(3, 7); w = rnd.randint(2, 5)
            lo = max(hl[row:row + h + 1]) + 6; hi = COLS - max(hr[row:row + h + 1]) - 6 - w
            if hi > lo:
                isl.append((row, rnd.randint(lo, hi), w, h))
                row += h + rnd.randint(8, 16); continue
        row += rnd.randint(6, 14)
    # ---- events (row, type, count, x, param)
    ev = []
    def open_cols(rw):
        rw = min(max(rw, 0), len(hl) - 1)
        return max(hl[max(0, rw - 3):rw + 4]) + 1, COLS - max(hr[max(0, rw - 3):rw + 4]) - 2
    x = 36; k = 0
    mid = stoprow // 2
    shop_done = False
    while x < stoprow - 30:
        if not shop_done and x >= mid:
            ev.append((x, EV_SHOP, 0, 0, 0)); shop_done = True
            x += 24; continue
        lo, hi = open_cols(x + 8)
        t = MIX[li][(k * 5 + rnd.randint(0, 2)) % len(MIX[li])]
        px = 24 + rnd.randint(lo + 2, max(lo + 2, hi - 3)) * 8
        if t == E_FLYER: ev.append((x, t, 5, px, rnd.randint(0, 1)))
        elif t == E_SWOOP: ev.append((x, t, 3 + li // 3, px, 0))
        elif t == E_ROCK: ev.append((x, t, 3, 0, 0))
        elif t == E_DIVER: ev.append((x, t, 3, 0, 0))
        elif t == E_SIDER: ev.append((x, t, 3, 0, rnd.randint(0, 1)))
        elif t == E_MINE: ev.append((x, t, 1 + (li >= 3), px, 0))
        elif t == E_RISER: ev.append((x, t, 2 + li // 3, px, 0))
        elif t == E_POD: ev.append((x, t, 1, px, 0))
        # turrets on walls / islands
        if k % 2 == 1 or li >= 3:
            rw = x + rnd.randint(3, 10)
            if rw + 2 < len(hl) and hl[rw] == hl[rw + 1] == hl[rw - 1] and hl[rw] >= 2:
                ev.append((rw, E_TURRET, 1, 24 + (hl[rw] - 2) * 8, 0))
            elif rw + 2 < len(hr) and hr[rw] == hr[rw + 1] == hr[rw - 1] and hr[rw] >= 2:
                ev.append((rw, E_TURRET, 1, 24 + (COLS - hr[rw]) * 8 - 8, 0))
        x += rnd.randint(20, 27) - li // 2
        k += 1
    for (rw, c, w, h) in isl:
        if rnd.random() < 0.5 + li * 0.1:
            ev.append((rw + h // 2, E_TURRET, 1, 24 + (c + w // 2) * 8 - 8, 1))
    ev.sort(key=lambda e: e[0])
    return dict(runs=runs, isl=isl, ev=ev, stoprow=stoprow, hl=hl, hr=hr, mid=mid)

def level_asm():
    out = ["; generated level data (vertical)"]
    out.append("level_tab_lo .byte " + ",".join("<level%d" % i for i in range(5)))
    out.append("level_tab_hi .byte " + ",".join(">level%d" % i for i in range(5)))
    for li in range(5):
        Lv = gen_level(li)
        out.append("level%d" % li)
        out.append("  .byte 2,2")
        out.append("  .word level%d_runs, level%d_ev, %d, level%d_isl" % (li, li, Lv['stoprow'], li))
        out.append("level%d_runs" % li)
        rr = []
        for n, fl in Lv['runs']:
            while n > 255: rr.append((255, fl)); n -= 255
            rr.append((n, fl))
        for i in range(0, len(rr), 8):
            out.append("  .byte " + ",".join("%d,%d" % r for r in rr[i:i + 8]))
        out.append("  .byte 0,0")
        out.append("level%d_isl" % li)
        for (rw, c, w, h) in Lv['isl']:
            out.append("  .byte %d,%d,%d,%d,%d" % (rw & 255, rw >> 8, c, w, h))
        out.append("  .byte $ff,$ff")
        out.append("level%d_ev" % li)
        for (rw, t, n, x, p) in Lv['ev']:
            out.append("  .byte %d,%d,%d,%d,%d,%d" % (rw & 255, rw >> 8, t, n, x & 255, p | ((x >> 8) << 7)))
        out.append("  .byte $ff,$ff")
    return "\n".join(out) + "\n"

if __name__ == '__main__':
    for li in range(5):
        L = gen_level(li)
        print(li, len(L['runs']), len(L['isl']), len(L['ev']), L['stoprow'], L['mid'])
