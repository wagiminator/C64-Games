# ZYRON - level generator (terrain runs + enemy events)
import random

# enemy type ids (must match asm)
E_DRONE, E_DART, E_TURRET, E_ROCK, E_HOPPER, E_CARRIER, E_MINE, E_CHASER = 1, 2, 3, 4, 5, 6, 7, 8
# powerup kinds
P_LASER, P_SPREAD, P_HOMING, P_ORB, P_SPEED, P_BOMB = range(6)

PFROWS = 21
MINGAP = 9

LEVEL_LEN = [400, 440, 470, 500, 520, 540]
ARENA = 44

STYLE = [
    # (max height, run len range, slope prob, both-sides)
    dict(maxh=6, runs=(3, 10), slope=0.55, cave=0.4),
    dict(maxh=7, runs=(2, 6), slope=0.75, cave=0.8),
    dict(maxh=7, runs=(1, 4), slope=0.85, cave=0.6),
    dict(maxh=8, runs=(2, 8), slope=0.7, cave=0.5),
    dict(maxh=7, runs=(4, 12), slope=0.45, cave=0.7),
    dict(maxh=8, runs=(2, 6), slope=0.75, cave=0.9),
]

MIX = [
    [E_DRONE, E_DRONE, E_DART, E_ROCK, E_ROCK, E_DART],
    [E_DRONE, E_HOPPER, E_MINE, E_CHASER, E_DRONE, E_HOPPER],
    [E_DART, E_ROCK, E_MINE, E_DRONE, E_DART, E_CHASER],
    [E_HOPPER, E_CHASER, E_DART, E_MINE, E_DRONE, E_ROCK],
    [E_DRONE, E_DART, E_CHASER, E_MINE, E_DART, E_DRONE],
    [E_DRONE, E_DART, E_ROCK, E_HOPPER, E_MINE, E_CHASER],
]
POWERUPS = [
    [P_SPREAD, P_SPEED, P_LASER, P_ORB, P_BOMB],
    [P_SPEED, P_HOMING, P_ORB, P_LASER, P_BOMB],
    [P_SPEED, P_LASER, P_ORB, P_SPREAD, P_BOMB],
    [P_SPEED, P_SPREAD, P_ORB, P_HOMING, P_BOMB],
    [P_SPEED, P_LASER, P_ORB, P_SPREAD, P_BOMB],
    [P_SPEED, P_HOMING, P_ORB, P_LASER, P_BOMB, P_SPREAD],
]

def code(d):
    return {0: 0, 1: 1, -1: 2}[d]

def gen_level(li):
    rnd = random.Random(1000 + li * 77)
    st = STYLE[li]
    L = LEVEL_LEN[li]
    c, f = 1, 2
    startc, startf = c, f
    runs = []
    hc, hf = [c], [f]            # heights per column
    col = 0
    # intro: 40 flat columns
    def addrun(n, dc, df):
        nonlocal c, f
        runs.append((n, code(dc) | (code(df) << 2)))
        for _ in range(n):
            c += dc; f += df
            hc.append(c); hf.append(f)
    addrun(40, 0, 0)
    while len(hc) < L:
        n = rnd.randint(*st['runs'])
        dc = df = 0
        if rnd.random() < st['slope']:
            df = rnd.choice((-1, 1))
        if rnd.random() < st['slope'] * st['cave']:
            dc = rnd.choice((-1, 1))
        # clamp to constraints
        n2 = 0
        for k in range(n):
            nc, nf = c + dc, f + df
            if nc < 1 or nc > st['maxh'] or nf < 1 or nf > st['maxh'] or PFROWS - nc - nf < MINGAP:
                break
            n2 += 1
            c, f = nc, nf
            hc.append(c); hf.append(f)
        # revert local change and add properly
        for k in range(n2):
            hc.pop(); hf.pop()
        c -= dc * n2; f -= df * n2
        if n2 > 0:
            addrun(n2, dc, df)
        else:
            addrun(rnd.randint(2, 5), 0, 0)
    # flatten to arena: move towards c=1,f=2
    while c != 1 or f != 2:
        dc = -1 if c > 1 else 0
        df = -1 if f > 2 else (1 if f < 2 else 0)
        addrun(1, dc, df)
    addrun(ARENA + 60, 0, 0)
    stopcol = len(hc) - 60 + 38 - 10
    # ------------------------------------------------ events
    ev = []
    mix = MIX[li]
    pu = POWERUPS[li]
    def open_rows(x):
        x = min(max(x, 0), len(hc) - 1)
        lo = max(hc[max(0, x - 2):x + 3]) + 1
        hi = PFROWS - max(hf[max(0, x - 2):x + 3]) - 2
        return lo, hi
    x = 44
    k = 0
    pui = 0
    while x < stopcol - 46:
        lo, hi = open_rows(x + 6)
        mid = (lo + hi) // 2
        if k % 5 == 2 and pui < len(pu):
            ev.append((x, E_CARRIER, 1, 50 + mid * 8 - 6, pu[pui])); pui += 1
        else:
            t = mix[(k * 7 + rnd.randint(0, 2)) % len(mix)]
            if t == E_DRONE:
                y = 50 + rnd.randint(lo + 1, max(lo + 1, hi - 2)) * 8 - 8
                ev.append((x, E_DRONE, 5, y, rnd.randint(0, 1)))
            elif t == E_DART:
                ev.append((x, E_DART, 3 + li // 3, 50 + rnd.randint(lo, hi) * 8 - 8, 0))
            elif t == E_ROCK:
                ev.append((x, E_ROCK, 3 + li // 3, 0, 0))
            elif t == E_HOPPER:
                ev.append((x, E_HOPPER, 3, 0, 0))
            elif t == E_MINE:
                ev.append((x, E_MINE, 1 + (li >= 3), 50 + mid * 8 - 8, 0))
            elif t == E_CHASER:
                ev.append((x, E_CHASER, 3, 50 + rnd.randint(lo, hi) * 8 - 8, 0))
        # turrets on flat ground nearby
        if k % 2 == 1 or (li >= 4 and k % 3 != 0):
            for tx in range(x + 4, x + 14):
                if tx + 2 < len(hf) and hf[tx] == hf[tx + 1] == hf[tx + 2] and hf[tx] >= 1:
                    ev.append((tx, E_TURRET, 1, 0, 0)); break
        if li >= 2 and k % 3 == 0:
            for tx in range(x + 8, x + 18):
                if tx + 2 < len(hc) and hc[tx] == hc[tx + 1] == hc[tx + 2] and hc[tx] >= 1:
                    ev.append((tx, E_TURRET, 1, 0, 1)); break
        x += rnd.randint(21, 27) - li // 2
        k += 1
    ev.sort(key=lambda e: e[0])
    return dict(startc=startc, startf=startf, runs=runs, events=ev, stopcol=stopcol, hc=hc, hf=hf)

def level_asm():
    out = []
    out.append("; generated level data")
    out.append("level_tab_lo .byte " + ",".join("<level%d" % i for i in range(6)))
    out.append("level_tab_hi .byte " + ",".join(">level%d" % i for i in range(6)))
    for li in range(6):
        L = gen_level(li)
        out.append("level%d" % li)
        out.append("  .byte %d,%d" % (L['startc'], L['startf']))
        out.append("  .word level%d_runs, level%d_ev, %d" % (li, li, L['stopcol']))
        out.append("level%d_runs" % li)
        rs = L['runs']
        # split runs > 255
        rr = []
        for n, fl in rs:
            while n > 255:
                rr.append((255, fl)); n -= 255
            rr.append((n, fl))
        for i in range(0, len(rr), 8):
            out.append("  .byte " + ",".join("%d,%d" % r for r in rr[i:i + 8]))
        out.append("  .byte 0,0")
        out.append("level%d_ev" % li)
        for (x, t, n, y, p) in L['events']:
            out.append("  .byte %d,%d,%d,%d,%d,%d" % (x & 255, x >> 8, t, n, y, p))
        out.append("  .byte $ff,$ff")
    return "\n".join(out) + "\n"

if __name__ == '__main__':
    for li in range(6):
        L = gen_level(li)
        print(li, len(L['runs']), len(L['events']), L['stopcol'], len(L['hc']))
