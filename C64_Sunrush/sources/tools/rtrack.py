# SUNRUSH - stages: route pyramid, themes, procedural course layouts
import random

# legs: stage indices per leg; from leg l position j the fork leads to leg l+1 position j (left) or j+1 (right)
LEGS = [[0], [1, 2], [3, 4, 5], [6, 7, 8, 9]]
STAGE_LEN = 46000           # track units per stage (stripe = 64 units)

# colour constants (C64 palette)
BLACK, WHITE, RED, CYAN, PURPLE, GREEN, BLUE, YELLOW = 0, 1, 2, 3, 4, 5, 6, 7
ORANGE, BROWN, LRED, DGREY, GREY, LGREEN, LBLUE, LGREY = 8, 9, 10, 11, 12, 13, 14, 15

# theme fields:
#  name, scenery kind, sky, glow (8 lines above the horizon), scenery $d022/$d023, scenery colour RAM (5 rows, 0-7),
#  grass (light, dark), kerb (a, b), road (light, dark), lane mark (colour RAM 0-7),
#  object types (list of sprite names, weights), object spacing, traffic types, traffic density (0-3), difficulty
THEMES = [
    dict(name='PALM COAST', scn='sea', sky=LBLUE, glow=[LBLUE] * 4 + [CYAN] * 2 + [WHITE] * 2,
         s22=BLUE, s23=GREEN, srow=[WHITE] * 5, grass=(LGREEN, GREEN), kerb=(RED, WHITE), road=(GREY, DGREY),
         lane=WHITE, objs=['palm', 'palm', 'bush'], spacing=260, traffic=['sedan', 'van'], density=1, curve=2),
    dict(name='RED CANYON', scn='mesa', sky=YELLOW, glow=[YELLOW] * 4 + [ORANGE] * 4,
         s22=BROWN, s23=RED, srow=[YELLOW] * 5, grass=(ORANGE, BROWN), kerb=(RED, WHITE), road=(GREY, DGREY),
         lane=WHITE, objs=['cactus', 'rock', 'cactus'], spacing=300, traffic=['sedan', 'truck'], density=1, curve=3),
    dict(name='PINE VALLEY', scn='hills', sky=LBLUE, glow=[LBLUE] * 6 + [WHITE] * 2,
         s22=GREEN, s23=DGREY, srow=[WHITE] * 5, grass=(LGREEN, GREEN), kerb=(RED, WHITE), road=(GREY, DGREY),
         lane=WHITE, objs=['pine', 'pine', 'bush'], spacing=240, traffic=['van', 'truck'], density=2, curve=3),
    dict(name='OLD TOWN', scn='city', sky=LBLUE, glow=[LBLUE] * 5 + [LGREY] * 3,
         s22=DGREY, s23=GREEN, srow=[WHITE] * 5, grass=(LGREY, GREY), kerb=(RED, WHITE), road=(DGREY, GREY),
         lane=WHITE, objs=['house', 'lamp', 'house'], spacing=220, traffic=['sedan', 'van'], density=2, curve=3),
    dict(name='LAKESIDE', scn='sea', sky=CYAN, glow=[CYAN] * 5 + [LBLUE] * 3,
         s22=BLUE, s23=GREEN, srow=[WHITE] * 5, grass=(LGREEN, GREEN), kerb=(RED, WHITE), road=(GREY, DGREY),
         lane=WHITE, objs=['flowers', 'bush', 'palm'], spacing=230, traffic=['sedan', 'van'], density=2, curve=3),
    dict(name='SNOW PASS', scn='hills', sky=LGREY, glow=[LGREY] * 6 + [WHITE] * 2,
         s22=WHITE, s23=GREY, srow=[WHITE] * 5, grass=(WHITE, LGREY), kerb=(RED, BLUE), road=(GREY, DGREY),
         lane=YELLOW, objs=['snowpine', 'snowpine', 'rock'], spacing=240, traffic=['van', 'truck'], density=2, curve=4),
    dict(name='SUNSET BAY', scn='sea', sky=ORANGE, glow=[ORANGE] * 3 + [LRED] * 3 + [YELLOW] * 2,
         s22=PURPLE, s23=BROWN, srow=[YELLOW] * 5, grass=(BROWN, ORANGE), kerb=(RED, WHITE), road=(GREY, DGREY),
         lane=WHITE, objs=['palm', 'palm', 'rock'], spacing=250, traffic=['sedan', 'van'], density=2, curve=3),
    dict(name='TULIP PLAINS', scn='hills', sky=LBLUE, glow=[LBLUE] * 6 + [WHITE] * 2,
         s22=GREEN, s23=LGREY, srow=[WHITE] * 5, grass=(LRED, GREEN), kerb=(RED, WHITE), road=(GREY, DGREY),
         lane=WHITE, objs=['windmill', 'flowers', 'flowers'], spacing=230, traffic=['sedan', 'truck'], density=3, curve=3),
    dict(name='VOLCANO ROAD', scn='volcano', sky=DGREY, glow=[DGREY] * 4 + [BROWN] * 2 + [RED] * 2,
         s22=BLACK, s23=GREY, srow=[RED, RED, YELLOW, RED, RED], grass=(BROWN, BLACK), kerb=(RED, YELLOW),
         road=(GREY, DGREY), lane=YELLOW, objs=['rock', 'rock', 'bollard'], spacing=240, traffic=['truck', 'van'],
         density=3, curve=4),
    dict(name='NEON CITY', scn='city', sky=BLACK, glow=[BLACK] * 4 + [BLUE] * 2 + [PURPLE] * 2,
         s22=BLUE, s23=BLACK, srow=[YELLOW] * 5, grass=(DGREY, BLACK), kerb=(PURPLE, WHITE), road=(GREY, DGREY),
         lane=YELLOW, objs=['tower', 'lamp', 'lamp'], spacing=200, traffic=['sedan', 'van', 'truck'], density=3, curve=4),
]

GOALS = ['PALM COAST', 'RED CANYON', 'PINE VALLEY', 'OLD TOWN']   # placeholder, endings defined in screens

def course(stage, seed=None):
    """list of (length, curve) segments, total STAGE_LEN; curve signed (-7..7)"""
    th = THEMES[stage]
    rnd = random.Random(1000 + stage * 77 if seed is None else seed)
    cmax = th['curve']
    segs = [(2600, 0)]                       # start straight
    pos = 2600
    while pos < STAGE_LEN - 7000:
        kind = rnd.random()
        if kind < 0.25:
            ln = rnd.randrange(1500, 3500); c = 0
        elif kind < 0.7:
            ln = rnd.randrange(2000, 4500); c = rnd.choice((-1, 1)) * rnd.randrange(1, cmax + 1)
        else:                                 # S-bend
            ln = rnd.randrange(1600, 2600); c = rnd.choice((-1, 1)) * rnd.randrange(1, cmax + 1)
            segs.append((ln, c)); pos += ln
            ln = rnd.randrange(1600, 2600); c = -c
        # soften transitions: insert a half-strength lead-in
        if segs and segs[-1][1] != c and c != 0 and abs(c) > 1:
            segs.append((500, c // 2)); pos += 500
        segs.append((ln, c)); pos += ln
    segs.append((STAGE_LEN - pos + 4000, 0))   # long straight to the checkpoint and beyond
    return segs

if __name__ == '__main__':
    for s in range(10):
        c = course(s)
        print(s, THEMES[s]['name'], len(c), sum(l for l, _ in c))
