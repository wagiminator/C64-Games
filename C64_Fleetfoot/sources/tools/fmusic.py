# FLEETFOOT - music and sound effects (original compositions, compiled by music.py)
import music
from music import Song, bass_bar, arp_bar, arp_rhythm, DRUMS, sweep

def L(s): return 'ilead ' + s
def S(s): return 'isaw ' + s

def song_title():
    # adventure fanfare in D minor with tom drums
    s = Song('title', 6)
    s.bar(bass_bar('Dm', 'gallop'), 'r:16', 'itom c4:2 c4:2 c4:4 itom c4:2 c4:2 c4:4')
    s.mark_loop()
    prog = ['Dm', 'Bb', 'C', 'Dm', 'Dm', 'F', 'C', 'A']
    lead = ['d5:2 d5:2 a5:4 g5:2 f5:2 e5:4', 'f5:4 d5:4 bb4:8', 'c5:2 e5:2 g5:4 c6:4 bb5:4', 'a5:12 r:4',
            'd6:4 c6:2 a5:2 f5:4 a5:4', 'c6:6 a5:2 f5:8', 'e5:4 g5:4 c6:4 e6:4', 'c#6:8 a5:8']
    for i, (ch, ld) in enumerate(zip(prog, lead)):
        s.bar(bass_bar(ch, 'gallop'), L(ld), DRUMS['march'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(['Bb', 'C', 'Dm', 'Dm', 'Bb', 'C', 'A', 'A']):
        s.bar(bass_bar(ch, 'eighth'), arp_rhythm(ch, 4), arp_bar(ch, 5) if i % 2 else DRUMS['half'])
    return s

def song_game():
    # the chase: fast E minor run
    s = Song('game', 5)
    s.bar(bass_bar('Em', 'drive'), 'r:16', DRUMS['fast'])
    s.mark_loop()
    prog = ['Em', 'Em', 'C', 'D', 'Em', 'Em', 'Am', 'B']
    lead = ['e5:2 g5:2 b5:2 g5:2 e5:4 f#5:4', 'g5:2 a5:2 b5:4 e6:8', 'c6:4 b5:2 a5:2 g5:4 e5:4', 'f#5:4 a5:4 d6:8',
            'e6:2 d6:2 b5:2 g5:2 e5:4 g5:4', 'b5:8 e5:8', 'a5:2 c6:2 e6:4 d6:2 c6:2 a5:4', 'b5:4 d#5:4 f#5:4 b5:4']
    for i, (ch, ld) in enumerate(zip(prog, lead)):
        s.bar(bass_bar(ch, 'drive'), L(ld), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(['C', 'D', 'Bm', 'Em', 'C', 'D', 'B', 'B']):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    lead3 = ['g5:4 e5:4 c5:4 e5:4', 'f#5:4 a5:4 d6:4 a5:4', 'b5:6 f#5:2 d5:4 b4:4', 'e5:8 g5:8',
             'c6:4 g5:4 e5:4 g5:4', 'd6:4 a5:4 f#5:4 a5:4', 'd#6:6 b5:2 f#5:4 d#5:4', 'b5:8 f#5:8']
    for i, (ch, ld) in enumerate(zip(['C', 'D', 'Bm', 'Em', 'C', 'D', 'B', 'B'], lead3)):
        s.bar(bass_bar(ch, 'drive'), S(ld), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    return s

def song_over():
    s = Song('over', 8, loop=False)
    s.bar('ibass e2:8 c2:8', 'ilead b4:4 g4:4 e4:4 c4:4', 'iarpmin e3:16')
    s.bar('ibass a1:8 b1:8', 'ilead c4:6 b3:2 a3:4 b3:4', 'iarpmaj b2:16')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_end():
    # escape: bright D major
    s = Song('end', 6)
    prog = ['D', 'A', 'Bm', 'G', 'D', 'A', 'G', 'A']
    lead = ['f#5:4 a5:4 d6:6 c#6:2', 'c#6:4 e6:4 a5:8', 'b5:4 d6:4 f#6:6 e6:2', 'd6:4 b5:4 g5:8',
            'a5:4 d6:4 f#6:4 a6:4', 'a6:4 g6:2 f#6:2 e6:8', 'd6:4 b5:4 g5:4 b5:4', 'a5:8 c#6:8']
    for ch, ld in zip(prog, lead):
        s.bar(bass_bar(ch, 'gallop'), L(ld), arp_bar(ch))
    for i, ch in enumerate(prog):
        s.bar(bass_bar(ch, 'eighth'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

music.SONGS = [song_title, song_game, song_over, song_end]

def tone(wave, notes, rep=2):
    return [(wave, n) for n in notes for _ in range(rep)]

music.SFX[:] = [
    ('jump', 2, 0x00, 0x80, 0x08, sweep(0x41, 30, 80, 8) + [(0x40, 80)]),
    ('slide', 2, 0x00, 0x90, 0x08, [(0x81, 40), (0x81, 34), (0x81, 30), (0x81, 26), (0x81, 22), (0x80, 22)]),
    ('lane', 1, 0x00, 0x60, 0x08, [(0x81, 70), (0x81, 60), (0x80, 60)]),
    ('coin', 1, 0x00, 0x70, 0x08, [(0x11, 120), (0x11, 160), (0x11, 160), (0x10, 160)]),
    ('power', 4, 0x00, 0xa0, 0x08, tone(0x11, [60, 80, 100, 120, 150, 180], 2) + [(0x10, 180)]),
    ('shield', 5, 0x00, 0xb0, 0x08, tone(0x41, [120, 90, 120, 90, 120], 2) + [(0x40, 90)]),
    ('bump', 4, 0x00, 0x90, 0x08, [(0x81, 14), (0x41, 20), (0x41, 16), (0x41, 12), (0x40, 12)]),
    ('crash', 6, 0x00, 0xf9, 0x08, [(0x81, 20), (0x81, 12)] + sweep(0x81, 10, 2, 30) + [(0x80, 2)]),
    ('whoosh', 1, 0x00, 0x60, 0x08, [(0x81, 90), (0x81, 110), (0x80, 110)]),
    ('zone', 5, 0x00, 0xa0, 0x08, tone(0x41, [50, 63, 75, 100, 75, 100, 126], 3) + [(0x40, 126)]),
    ('rumble', 3, 0x0a, 0xfb, 0x08, [(0x81, 6), (0x81, 5), (0x81, 7), (0x81, 5)] * 4 + [(0x80, 5)]),
    ('menu', 2, 0x00, 0x90, 0x08, [(0x41, 60), (0x41, 80), (0x40, 80)]),
    ('cheat', 6, 0x00, 0xa0, 0x08, [(0x11, f) for f in (40, 50, 60, 80, 100, 120, 160, 200) for _ in range(3)] + [(0x10, 200)]),
]
music.SFXID.clear()
music.SFXID.update({s[0]: i for i, s in enumerate(music.SFX)})

def music_asm():
    return music.music_asm()
