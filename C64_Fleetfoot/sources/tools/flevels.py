# FLEETFOOT - obstacle patterns
# rows of three lanes (left, middle, right), one row every 32 depth units (1 lane length)
#  .  empty     h  hurdle (jump)   b  bar (slide)   X  block (change lane)
#  c  coin      1-4 coin in the air (height in quarter lanes)    p  power-up
CODES = {'.': 0, 'h': 1, 'b': 2, 'X': 3, 'c': 4, '1': 5, '2': 6, '3': 7, '4': 8, 'p': 9}

P = {}
P['coins_mid'] = [".c.", ".c.", ".c.", ".c.", ".c.", ".c."]
P['coins_left'] = ["c..", "c..", "c..", "c..", "c..", "c.."]
P['coins_zig'] = ["c..", "c..", ".c.", ".c.", "..c", "..c", ".c.", ".c."]
P['hurdle_mid'] = [".c.", ".1.", ".2.", ".h.", ".2.", ".1.", ".c."]
P['hurdle_side'] = ["h..", "...", "...", "...", "..h"]
P['block_mid'] = [".X.", "...", "c.c", "c.c", "c.c"]
P['block_pair'] = ["XX.", "..c", "..c", "..c"]
P['bar_mid'] = [".b.", "...", ".c.", ".c.", ".c."]
P['power'] = ["...", ".p.", "..."]
P['wall_left'] = ["X.c", "X.c", "..c", "..c"]
P['hurdles_all'] = ["...", "hhh", "...", "...", ".c.", ".c."]
P['bars_all'] = ["...", "bbb", "...", "c.c", "c.c"]
P['slalom'] = ["X..", "...", "...", "..X", "...", "...", "X..", "...", "...", "..X"]
P['corridor'] = ["X.X", "X.X", "XcX", "XcX", ".c.", ".c."]
P['mixed1'] = ["Xh.", "...", "...", "..b", "...", ".c.", ".c."]
P['mixed2'] = ["hXb", "...", "...", "c.c"]
P['mixed3'] = ["bXX", "...", "...", "...", "XXh", "...", "...", ".c."]
P['arc_left'] = ["c..", "1..", "2..", "h3.", "2..", "1..", "c.."]
P['zig_blocks'] = [".X.", "...", "...", "X.X", "...", "...", ".X.", "...", "c.c"]
P['tunnel'] = ["XbX", "...", "...", "XhX", "...", "...", "ccc"]
P['gauntlet'] = ["h.X", "...", "...", "X.b", "...", "...", "b.h", "...", "...", ".X.", "...", "c.c"]
P['triple'] = ["hbh", "...", "...", "bhb", "...", "...", ".c."]

ORDER = list(P.keys())
ZONE_SETS = [
    ['coins_mid', 'coins_left', 'hurdle_mid', 'hurdle_side', 'block_mid', 'bar_mid', 'block_pair', 'power', 'coins_zig'],
    ['coins_zig', 'hurdle_mid', 'block_mid', 'block_pair', 'bar_mid', 'wall_left', 'hurdles_all', 'power', 'arc_left', 'slalom'],
    ['hurdles_all', 'bars_all', 'slalom', 'corridor', 'mixed1', 'arc_left', 'wall_left', 'power', 'zig_blocks', 'block_pair'],
    ['mixed1', 'mixed2', 'corridor', 'zig_blocks', 'bars_all', 'hurdles_all', 'tunnel', 'power', 'slalom', 'arc_left'],
    ['mixed2', 'mixed3', 'tunnel', 'gauntlet', 'triple', 'zig_blocks', 'corridor', 'power', 'bars_all', 'hurdles_all'],
]
ZONE_GAP = [4, 4, 3, 3, 3]

def asm():
    L = ["; generated obstacle patterns"]
    for i, k in enumerate(ORDER):
        rows = P[k]
        for r in rows:
            assert len(r) == 3, (k, r)
        data = [len(rows)] + [CODES[c] for r in rows for c in r]
        L.append("pat%d  .byte %s   ; %s" % (i, ",".join(str(x) for x in data), k))
    L.append("pat_lo  .byte " + ",".join("<pat%d" % i for i in range(len(ORDER))))
    L.append("pat_hi  .byte " + ",".join(">pat%d" % i for i in range(len(ORDER))))
    for z, s in enumerate(ZONE_SETS):
        assert len(s) <= 16
        L.append("zset%d  .byte %s" % (z, ",".join(str(ORDER.index(k)) for k in s)))
    L.append("zset_lo .byte " + ",".join("<zset%d" % z for z in range(5)))
    L.append("zset_hi .byte " + ",".join(">zset%d" % z for z in range(5)))
    L.append("zset_n  .byte " + ",".join(str(len(s)) for s in ZONE_SETS))
    L.append("zone_gap .byte " + ",".join(str(g) for g in ZONE_GAP))
    return "\n".join(L) + "\n"
