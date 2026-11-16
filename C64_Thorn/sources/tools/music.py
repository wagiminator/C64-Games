# ZYRON - music & sfx compiler
import re

NOTES = {'c': 0, 'd': 2, 'e': 4, 'f': 5, 'g': 7, 'a': 9, 'b': 11}

def note_num(tok):
    m = re.match(r'^([a-g])([#b]?)(\d)$', tok)
    if not m: raise ValueError(tok)
    n = NOTES[m.group(1)] + (1 if m.group(2) == '#' else (-1 if m.group(2) == 'b' else 0))
    return int(m.group(3)) * 12 + n

# ---------------------------------------------------------------- instruments
# (AD, SR, wavetable list [(wave, note, abs)], pulse start (12bit), pulse speed, vib depth, vib delay)
WT = []         # global wavetable (wave, note) ; wave $FF = jump to note
def wt_add(steps, loop_to=None):
    start = len(WT)
    for (w, n, ab) in steps:
        if ab: WT.append((w, 0x80 | n))
        else: WT.append((w, n & 0x7f))
    lp = start + (loop_to if loop_to is not None else len(steps) - 1)
    WT.append((0xFF, lp))
    return start

INSTR = []
def instr(name, ad, sr, wt, pw=0x800, pws=0, vib=0, vibdel=0):
    INSTR.append(dict(name=name, ad=ad, sr=sr, wt=wt, pw=pw, pws=pws, vib=vib, vibdel=vibdel))
    return len(INSTR) - 1

I_BASS = instr('bass', 0x08, 0x88, wt_add([(0x41, 0, 0)]), 0x600, 0x28)
I_LEAD = instr('lead', 0x0a, 0xa9, wt_add([(0x41, 12, 0), (0x41, 0, 0)]), 0x300, 0x18, 3, 10)
I_ARPMIN = instr('arpmin', 0x04, 0x84, wt_add([(0x41, 0, 0), (0x41, 3, 0), (0x41, 7, 0), (0x41, 12, 0)], 0), 0x400, 0x30)
I_ARPMAJ = instr('arpmaj', 0x04, 0x84, wt_add([(0x41, 0, 0), (0x41, 4, 0), (0x41, 7, 0), (0x41, 12, 0)], 0), 0x400, 0x30)
I_KICK = instr('kick', 0x08, 0x00, wt_add([(0x81, 70, 1), (0x11, 38, 1), (0x11, 33, 1), (0x11, 28, 1), (0x11, 24, 1), (0x11, 20, 1), (0x10, 20, 1)]))
I_SNARE = instr('snare', 0x09, 0x00, wt_add([(0x81, 74, 1), (0x41, 44, 1), (0x81, 70, 1), (0x81, 68, 1), (0x81, 66, 1), (0x81, 64, 1), (0x80, 64, 1)]), 0x800)
I_HAT = instr('hat', 0x02, 0x00, wt_add([(0x81, 94, 1), (0x80, 94, 1)]))
I_SAW = instr('saw', 0x0a, 0x9a, wt_add([(0x21, 0, 0)]), 0x800, 0, 2, 14)
I_TRI = instr('tri', 0x06, 0x66, wt_add([(0x11, 0, 0)]), 0x800, 0, 2, 8)
I_ARPOCT = instr('arpoct', 0x04, 0x84, wt_add([(0x41, 0, 0), (0x41, 12, 0)], 0), 0x300, 0x20)
I_BASS2 = instr('bass2', 0x08, 0x98, wt_add([(0x21, 0, 0)]), 0x800)
I_PAD = instr('pad', 0x88, 0xab, wt_add([(0x41, 0, 0)]), 0x200, 0x10, 2, 20)
I_TOM = instr('tom', 0x08, 0x00, wt_add([(0x81, 60, 1), (0x11, 40, 1), (0x11, 38, 1), (0x11, 36, 1), (0x11, 34, 1), (0x11, 32, 1), (0x10, 32, 1)]))
I_ARPSUS = instr('arpsus', 0x04, 0x84, wt_add([(0x41, 0, 0), (0x41, 5, 0), (0x41, 7, 0), (0x41, 12, 0)], 0), 0x400, 0x30)
I_STAB = instr('stab', 0x05, 0x40, wt_add([(0x41, 0, 0), (0x41, 7, 0), (0x41, 12, 0), (0x41, 7, 0)], 0), 0x500, 0x40)

INAME = {d['name']: i for i, d in enumerate(INSTR)}

# ---------------------------------------------------------------- pattern compiler
def compile_pat(src):
    """tokens: i<name> | note[:len] | r[:len] | t[:len] (tie)"""
    out = []
    curlen = None
    for tok in src.split():
        if tok.startswith('i'):
            out.append(0xC0 + INAME[tok[1:]]); continue
        if ':' in tok:
            n, l = tok.split(':'); l = int(l)
        else:
            n, l = tok, None
        if l is not None and l != curlen:
            assert 1 <= l <= 64, tok
            out.append(0x80 + l - 1); curlen = l
        assert curlen is not None, src
        if n == 'r': out.append(0x60)
        elif n == 't': out.append(0x61)
        else:
            v = note_num(n); assert 0 <= v < 96, tok; out.append(v)
    out.append(0xFF)
    return bytes(out)

def patlen(src):
    tot = 0; cur = None
    for tok in src.split():
        if tok.startswith('i'): continue
        if ':' in tok: cur = int(tok.split(':')[1])
        tot += cur
    return tot

# ---------------------------------------------------------------- helpers to build parts
CH = {  # chord name -> (root, quality)
}
def chord(name):
    m = re.match(r'^([A-G])([#b]?)(m?)(7?)$', name)
    r = NOTES[m.group(1).lower()] + (1 if m.group(2) == '#' else (-1 if m.group(2) == 'b' else 0))
    return r % 12, ('min' if m.group(3) else 'maj'), bool(m.group(4))

NN = ['c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b']
def nn(n):
    return NN[n % 12] + str(n // 12)

def bass_bar(ch, style, octave=2):
    r, q, _ = chord(ch)
    root = octave * 12 + r
    if root < 2 * 12 + 4: root += 12
    fifth = root + 7
    octv = root + 12
    if style == 'drive':      # 16th octave bass
        seq = [root, root, octv, root, root, octv, root, fifth] * 2
        return 'ibass ' + ' '.join(nn(n) + ':1' if i == 0 else nn(n) for i, n in enumerate(seq))
    if style == 'eighth':
        seq = [root, octv, root, octv, root, octv, fifth, octv]
        return 'ibass ' + ' '.join(nn(n) + (':2' if i == 0 else '') for i, n in enumerate(seq))
    if style == 'gallop':
        seq = []
        for k in range(4):
            seq += [(root if k != 3 else fifth, 2), (root, 1), (octv, 1)]
        s = 'ibass '
        cur = None
        for n, l in seq:
            s += nn(n) + (':%d' % l if l != cur else '') + ' '; cur = l
        return s
    if style == 'long':
        return 'ibass2 %s:8 %s:4 %s:4' % (nn(root), nn(octv), nn(fifth))
    if style == 'slow':
        return 'ibass %s:12 %s:4' % (nn(root), nn(fifth))
    raise ValueError(style)

def arp_bar(ch, octave=4, length=16, step=2):
    r, q, sus = chord(ch)
    ins = 'iarpmin' if q == 'min' else 'iarpmaj'
    n = octave * 12 + r
    if n > 4 * 12 + 7: n -= 12
    return '%s %s:%d' % (ins, nn(n), length)

def arp_rhythm(ch, octave=4):
    r, q, sus = chord(ch)
    ins = 'iarpmin' if q == 'min' else 'iarpmaj'
    n = octave * 12 + r
    if n > 4 * 12 + 7: n -= 12
    return '%s %s:3 r:1 %s:2 %s:2 r:2 %s:2 %s:4' % (ins, nn(n), nn(n), nn(n), nn(n), nn(n))

DRUMS = {
    'rock': 'ikick c4:2 ihat c4 isnare c4 ihat c4 ikick c4 ikick c4 isnare c4 ihat c4',
    'rock2': 'ikick c4:2 ihat c4 isnare c4 ihat c4 ikick c4 ihat c4 isnare c4:1 isnare c4 itom c4:2',
    'fast': 'ikick c4:2 ihat c4 isnare c4 ikick c4 ikick c4 ihat c4 isnare c4 ihat c4',
    'fill': 'isnare c4:1 isnare c4 isnare c4:2 itom c4 itom c4:1 itom c4 isnare c4:2 isnare c4:1 isnare c4 isnare c4 isnare c4 ikick c4:2',
    'half': 'ikick c4:4 ihat c4 isnare c4:4 ihat c4',
    'march': 'ikick c4:2 isnare c4:1 isnare c4 ikick c4:2 ihat c4 ikick c4 isnare c4:1 isnare c4 isnare c4:2 ihat c4',
    'none': 'r:16',
}

class Song:
    def __init__(self, name, speed, loop=True):
        self.name, self.speed, self.loop = name, speed, loop
        self.v = [[], [], []]
        self.looppos = [0, 0, 0]
    def bar(self, v1, v2, v3):
        for i, s in enumerate((v1, v2, v3)):
            assert patlen(s) == 16 or patlen(s) % 16 == 0, (self.name, i, s, patlen(s))
            self.v[i].append(s)
    def mark_loop(self):
        self.looppos = [len(x) for x in self.v]

def L(s):
    return 'ilead ' + s

# ======================================================================= compositions
def song_title():
    s = Song('title', 6)
    prog = ['Am', 'F', 'C', 'G', 'Am', 'F', 'G', 'E']
    lead1 = ['a4:4 e4:2 a4:2 c5:4 b4:2 a4:2', 'f4:6 a4:2 c5:4 d5:2 c5:2', 'e5:6 d5:2 c5:4 g4:4',
             'b4:6 c5:2 d5:4 b4:4', 'a4:4 c5:4 e5:4 a5:4', 'g5:4 f5:2 e5:2 f5:4 a5:4',
             'g5:6 f5:2 e5:4 d5:4', 'e5:8 g#4:4 b4:4']
    prog2 = ['Dm', 'Am', 'G', 'C', 'F', 'Dm', 'E', 'E']
    lead2 = ['d5:4 f5:4 a5:6 g5:2', 'e5:8 c5:4 a4:4', 'b4:4 d5:4 g5:6 f5:2', 'e5:12 g5:4',
             'a5:4 g5:2 f5:2 e5:4 c5:4', 'd5:4 e5:2 f5:2 a5:8', 'g#5:8 b5:4 g#5:4', 'e5:16']
    # intro: arps only
    for ch in prog[:4]:
        s.bar(bass_bar(ch, 'slow'), 'r:16', arp_bar(ch))
    s.mark_loop()
    for ch, ld in zip(prog, lead1):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_bar(ch))
    for ch, ld in zip(prog2, lead2):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_bar(ch))
    for ch in prog:
        s.bar(bass_bar(ch, 'eighth'), arp_rhythm(ch, 5), arp_bar(ch))
    return s

def song_stage1():
    s = Song('stage1', 5)
    p = ['Am', 'Am', 'F', 'G', 'Am', 'Am', 'F', 'E']
    for i, ch in enumerate(p[:4]):
        s.bar(bass_bar(ch, 'drive'), arp_rhythm(ch), DRUMS['half'] if i < 3 else DRUMS['fill'])
    s.mark_loop()
    lead = ['a4:2 a4:2 c5:2 a4:2 e5:4 d5:2 c5:2', 'b4:2 c5:2 b4:2 a4:2 g4:4 a4:4',
            'f4:2 a4:2 c5:2 f5:4 e5:2 c5:2 a4:2', 'g4:2 b4:2 d5:2 g5:4 f5:2 d5:2 b4:2',
            'a4:2 a4:2 c5:2 a4:2 e5:4 g5:2 a5:2', 'g5:2 e5:2 d5:2 c5:2 d5:4 e5:4',
            'f5:4 e5:2 d5:2 c5:4 a4:4', 'b4:8 g#4:8']
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'drive'), L(ld), DRUMS['rock'] if i != 7 else DRUMS['rock2'])
    p2 = ['C', 'G', 'Am', 'F', 'Dm', 'Am', 'E', 'E']
    lead2 = ['e5:6 g5:2 e5:4 c5:4', 'd5:6 b4:2 g4:4 d5:4', 'c5:4 b4:2 a4:2 e5:8',
             'f5:4 e5:2 f5:2 a5:8', 'f5:2 e5:2 d5:2 e5:2 f5:4 a5:4', 'e5:4 c5:4 a4:8',
             'g#4:2 b4:2 e5:2 g#5:2 b5:4 g#5:4', 'e5:4 d5:2 c5:2 b4:4 g#4:4']
    for i, (ch, ld) in enumerate(zip(p2, lead2)):
        s.bar(bass_bar(ch, 'gallop'), L(ld), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'drive'), arp_rhythm(ch, 5) if i % 2 else arp_bar(ch, 5), DRUMS['fast'])
    return s

def song_stage2():
    s = Song('stage2', 5)
    p = ['Dm', 'Bb', 'C', 'A', 'Dm', 'Gm', 'A', 'A']
    for i, ch in enumerate(p[:4]):
        s.bar(bass_bar(ch, 'gallop'), arp_bar(ch), DRUMS['march'] if i < 3 else DRUMS['fill'])
    s.mark_loop()
    lead = ['d5:6 e5:2 f5:4 d5:4', 'f5:4 g5:2 f5:2 d5:8', 'e5:6 f5:2 g5:4 e5:4', 'c#5:8 e5:4 a5:4',
            'a5:6 g5:2 f5:4 e5:4', 'd5:4 g5:4 bb5:4 a5:2 g5:2', 'a5:6 g5:2 f5:2 e5:2 c#5:4', 'a4:16']
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'gallop'), L(ld), DRUMS['march'] if i != 7 else DRUMS['rock2'])
    p2 = ['Gm', 'Dm', 'Bb', 'A', 'Gm', 'Dm', 'E', 'A']
    for i, ch in enumerate(p2):
        s.bar(bass_bar(ch, 'drive'), arp_rhythm(ch, 5), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    lead2 = ['g5:4 f5:2 g5:2 bb5:8', 'a5:4 f5:4 d5:8', 'f5:4 g5:4 a5:2 bb5:2 a5:4', 'e5:8 c#5:8',
             'bb4:4 d5:4 g5:8', 'f5:2 e5:2 d5:4 a4:8', 'g#4:4 b4:4 e5:4 g#5:4', 'a5:16']
    for i, (ch, ld) in enumerate(zip(p2, lead2)):
        s.bar(bass_bar(ch, 'gallop'), L(ld), DRUMS['rock'])
    return s

def song_boss():
    s = Song('boss', 4)
    p = ['Em', 'Em', 'C', 'D', 'Em', 'Em', 'F', 'B']
    s.mark_loop()
    riff = ['e5:2 e5:1 e5:1 g5:2 e5:2 f#5:2 e5:2 d5:2 b4:2', 'e5:2 e5:1 e5:1 g5:2 e5:2 a5:2 g5:2 f#5:2 d5:2',
            'c5:2 c5:1 c5:1 e5:2 c5:2 g5:2 e5:2 c5:2 e5:2', 'd5:2 d5:1 d5:1 f#5:2 d5:2 a5:2 f#5:2 d5:2 f#5:2',
            'b5:4 a5:2 g5:2 f#5:4 e5:4', 'g5:4 f#5:2 e5:2 d5:4 b4:4', 'f5:4 e5:2 f5:2 a5:4 c6:4', 'b5:8 d#5:8']
    for i, (ch, ld) in enumerate(zip(p, riff)):
        s.bar(bass_bar(ch, 'drive'), 'isaw ' + ld, DRUMS['fast'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_clear():
    s = Song('clear', 5, loop=False)
    s.bar('ibass c3:4 g3:4 c4:4 e3:4', 'ilead c5:2 e5:2 g5:2 c6:6 b5:2 c6:2', 'iarpmaj c4:16')
    s.bar('ibass f3:4 g3:4 c3:8', 'ilead a5:4 b5:4 c6:8', 'iarpmaj f4:8 c4:8')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_over():
    s = Song('over', 7, loop=False)
    s.bar('ibass a2:8 f2:8', 'ilead e5:4 d5:4 c5:4 b4:4', 'iarpmin a4:8 iarpmaj f4:8')
    s.bar('ibass e2:8 a1:8', 'ilead g#4:8 a4:8', 'iarpmaj e4:8 iarpmin a3:8')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_end():
    s = Song('end', 6)
    p = ['C', 'G', 'Am', 'F', 'C', 'G', 'F', 'G']
    lead = ['e5:4 g5:4 c6:6 b5:2', 'b5:4 a5:2 g5:2 d5:8', 'c5:4 e5:4 a5:6 g5:2', 'f5:4 a5:4 c6:8',
            'c6:4 b5:2 a5:2 g5:4 e5:4', 'd5:4 g5:4 b5:8', 'a5:4 g5:2 f5:2 c6:4 a5:4', 'g5:12 g4:4']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), 'ipad ' + nn(60 + chord(ch)[0]) + ':16', arp_bar(ch))
    s.mark_loop()
    for ch, ld in zip(p, lead):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_bar(ch))
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), arp_bar(ch))
    return s

SONGS = [song_title, song_stage1, song_stage2, song_boss, song_clear, song_over, song_end]

# ======================================================================= sfx
# each sfx: (prio, AD, SR, PWhi, [(ctrl, freqhi), ...])
def sweep(wave, f0, f1, n, end_wave=None):
    fr = []
    for i in range(n):
        f = f0 + (f1 - f0) * i / max(1, n - 1)
        fr.append((wave, max(1, min(255, int(f)))))
    return fr

SFX = [
    ('shoot', 1, 0x00, 0xa0, 0x08, sweep(0x41, 60, 18, 5) + [(0x40, 10)]),
    ('laser', 1, 0x00, 0xa0, 0x04, sweep(0x21, 90, 40, 6) + [(0x20, 30)]),
    ('hit', 2, 0x00, 0x90, 0x08, [(0x81, 40), (0x41, 20), (0x80, 10)]),
    ('explo', 3, 0x00, 0xd9, 0x08, sweep(0x81, 30, 2, 22) + [(0x80, 2)]),
    ('bigexplo', 4, 0x0a, 0xfb, 0x08, sweep(0x81, 22, 1, 50) + [(0x80, 1)]),
    ('death', 5, 0x0a, 0xfb, 0x08, [(0x81, 50), (0x21, 30)] + sweep(0x81, 40, 1, 60) + [(0x80, 1)]),
    ('powerup', 4, 0x00, 0xa0, 0x08, [(0x11, f) for f in (20, 25, 30, 20, 25, 30, 40, 30, 40, 50, 40, 50, 64, 50, 64, 80)] + [(0x10, 80)]),
    ('charge', 3, 0x00, 0xa9, 0x06, sweep(0x21, 8, 70, 10) + sweep(0x81, 60, 10, 12) + [(0x80, 10)]),
    ('cheat', 6, 0x00, 0xa0, 0x08, [(0x11, f) for f in (40, 50, 60, 80, 100, 120, 160, 200) for _ in range(3)] + [(0x10, 200)]),
    ('menu', 2, 0x00, 0x90, 0x08, [(0x41, 60), (0x41, 80), (0x40, 80)]),
    ('eshot', 1, 0x00, 0x80, 0x08, sweep(0x81, 70, 50, 3) + [(0x80, 30)]),
    ('extra', 6, 0x00, 0xa0, 0x08, [(0x21, f) for f in (60, 60, 75, 75, 90, 90, 120, 120, 120, 120)] + [(0x20, 120)]),
]
SFXID = {s[0]: i for i, s in enumerate(SFX)}

# ======================================================================= emit
def music_asm():
    songs = [f() for f in SONGS]
    pats = []
    pidx = {}
    def pat_id(src):
        b = compile_pat(src)
        if b not in pidx:
            pidx[b] = len(pats); pats.append(b)
        return pidx[b]
    tracks = []
    for s in songs:
        tl = []
        for v in range(3):
            ids = [pat_id(x) for x in s.v[v]]
            assert all(i < 0xF0 for i in ids)
            if s.loop: ids += [0xFE, s.looppos[v]]
            else: ids += [0xFF]
            tl.append(ids)
        tracks.append((s, tl))
    out = ["; generated music data"]
    out.append("mus_npat = %d" % len(pats))
    out.append("mus_pat_lo .byte " + ",".join("<mpat%d" % i for i in range(len(pats))))
    out.append("mus_pat_hi .byte " + ",".join(">mpat%d" % i for i in range(len(pats))))
    for i, b in enumerate(pats):
        out.append("mpat%d .byte %s" % (i, ",".join("$%02x" % x for x in b)))
    out.append("mus_song_speed .byte " + ",".join(str(s.speed) for s, _ in tracks))
    for si, (s, tl) in enumerate(tracks):
        for v in range(3):
            out.append("mtrk%d_%d .byte %s" % (si, v, ",".join("$%02x" % x for x in tl[v])))
    for v in range(3):
        out.append("mus_trk%d_lo .byte %s" % (v, ",".join("<mtrk%d_%d" % (si, v) for si in range(len(tracks)))))
        out.append("mus_trk%d_hi .byte %s" % (v, ",".join(">mtrk%d_%d" % (si, v) for si in range(len(tracks)))))
    out.append("ins_ad .byte " + ",".join("$%02x" % d['ad'] for d in INSTR))
    out.append("ins_sr .byte " + ",".join("$%02x" % d['sr'] for d in INSTR))
    out.append("ins_wt .byte " + ",".join("%d" % d['wt'] for d in INSTR))
    out.append("ins_pwl .byte " + ",".join("$%02x" % (d['pw'] & 255) for d in INSTR))
    out.append("ins_pwh .byte " + ",".join("$%02x" % (d['pw'] >> 8) for d in INSTR))
    out.append("ins_pws .byte " + ",".join("$%02x" % (d['pws'] & 255) for d in INSTR))
    out.append("ins_vib .byte " + ",".join("%d" % d['vib'] for d in INSTR))
    out.append("ins_vdel .byte " + ",".join("%d" % d['vibdel'] for d in INSTR))
    out.append("wt_wave .byte " + ",".join("$%02x" % w for w, n in WT))
    out.append("wt_note .byte " + ",".join("$%02x" % n for w, n in WT))
    # sfx
    out.append("sfx_lo .byte " + ",".join("<sfx_%s" % s[0] for s in SFX))
    out.append("sfx_hi .byte " + ",".join(">sfx_%s" % s[0] for s in SFX))
    out.append("sfx_prio .byte " + ",".join("%d" % s[1] for s in SFX))
    for (name, prio, ad, sr, pw, frames) in SFX:
        b = [ad, sr, pw]
        for c, f in frames:
            b += [c if c else 0x08, f]
        b += [0x00]
        out.append("sfx_%s .byte %s" % (name, ",".join("$%02x" % x for x in b)))
    for name, i in SFXID.items():
        out.append("SFX_%s = %d" % (name.upper(), i))
    total = sum(len(b) for b in pats)
    return "\n".join(out) + "\n", total, len(pats)

if __name__ == '__main__':
    a, t, n = music_asm()
    print("patterns", n, "bytes", t, "wt", len(WT))
