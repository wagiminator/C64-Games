# NIGHTHOLD - music and sound effects (original compositions, compiled by music.py)
import music
from music import Song, bass_bar, arp_bar, arp_rhythm, DRUMS, sweep

def L(s): return 'ilead ' + s
def S(s): return 'isaw ' + s

def song_title():
    # gothic waltz feel in E minor
    s = Song('title', 7)
    s.bar(bass_bar('Em', 'slow'), 'r:16', arp_bar('Em'))
    s.mark_loop()
    prog = ['Em', 'C', 'Am', 'B', 'Em', 'C', 'D', 'B']
    lead = ['e5:6 g5:2 b5:4 a5:4', 'g5:4 e5:4 c5:8', 'a4:2 c5:2 e5:4 a5:4 g5:4', 'f#5:8 d#5:8',
            'e5:2 f#5:2 g5:4 b5:4 e6:4', 'e6:4 d6:2 c6:2 g5:8', 'f#5:4 a5:4 d6:4 c6:4', 'b5:8 d#5:8']
    for i, (ch, ld) in enumerate(zip(prog, lead)):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_bar(ch) if i % 2 == 0 else arp_rhythm(ch, 4))
    return s

def song_game():
    # driving night chase in A minor
    s = Song('game', 6)
    s.bar(bass_bar('Am', 'drive'), 'r:16', DRUMS['fast'])
    s.mark_loop()
    prog = ['Am', 'Am', 'F', 'G', 'Am', 'Am', 'Dm', 'E']
    lead = ['a4:2 a4:2 e5:4 d5:2 c5:2 b4:4', 'c5:4 b4:2 a4:2 e4:8',
            'f4:2 a4:2 c5:4 f5:4 e5:4', 'd5:4 b4:4 g4:8',
            'a4:2 c5:2 e5:4 a5:4 g5:2 e5:2', 'e5:8 c5:4 a4:4',
            'd5:2 f5:2 a5:4 g5:2 f5:2 d5:4', 'e5:4 g#4:4 b4:4 e5:4']
    for i, (ch, ld) in enumerate(zip(prog, lead)):
        s.bar(bass_bar(ch, 'drive'), L(ld), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(['F', 'G', 'Em', 'Am', 'Dm', 'G', 'E', 'E']):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    lead3 = ['c6:4 a5:4 f5:4 c5:4', 'd5:4 g5:4 b5:4 d6:4', 'e6:6 b5:2 g5:4 e5:4', 'a5:8 e5:8',
             'f5:4 a5:4 d6:4 a5:4', 'g5:4 b5:4 d6:4 g6:4', 'g#5:6 e5:2 b4:4 e5:4', 'b5:8 g#5:8']
    for i, (ch, ld) in enumerate(zip(['F', 'G', 'Em', 'Am', 'Dm', 'G', 'E', 'E'], lead3)):
        s.bar(bass_bar(ch, 'drive'), S(ld), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    return s

def song_over():
    s = Song('over', 8, loop=False)
    s.bar('ibass e2:8 b1:8', 'ilead b4:4 g4:4 e4:4 b3:4', 'iarpmin e3:16')
    s.bar('ibass c2:8 b1:8', 'ilead c4:6 b3:2 d#4:4 e4:4', 'iarpmaj b2:16')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_dawn():
    # sunrise in G major
    s = Song('dawn', 6)
    prog = ['G', 'D', 'Em', 'C', 'G', 'D', 'C', 'D']
    lead = ['b4:4 d5:4 g5:6 f#5:2', 'f#5:4 a5:4 d5:8', 'e5:4 g5:4 b5:6 a5:2', 'g5:4 e5:4 c5:8',
            'd5:4 g5:4 b5:4 d6:4', 'd6:4 c6:2 b5:2 a5:8', 'g5:4 e5:4 c5:4 e5:4', 'd5:8 f#5:8']
    for ch, ld in zip(prog, lead):
        s.bar(bass_bar(ch, 'gallop'), L(ld), arp_bar(ch))
    for i, ch in enumerate(prog):
        s.bar(bass_bar(ch, 'eighth'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_boss():
    s = Song('boss', 5)
    s.mark_loop()
    for i, ch in enumerate(['Em', 'Em', 'C', 'B', 'Em', 'Em', 'C', 'B']):
        s.bar(bass_bar(ch, 'drive'), S(['e5:2 e5:2 g5:2 e5:2 b5:4 a5:4', 'g5:2 f#5:2 e5:4 b4:8',
                                       'c6:4 b5:4 g5:4 e5:4', 'd#5:8 f#5:8'][i % 4]),
              DRUMS['fast'] if i != 7 else DRUMS['fill'])
    return s

music.SONGS = [song_title, song_game, song_over, song_dawn, song_boss]

def tone(wave, notes, rep=2):
    return [(wave, n) for n in notes for _ in range(rep)]

music.SFX[:] = [
    ('knife', 0, 0x00, 0x60, 0x08, sweep(0x81, 90, 60, 3) + [(0x80, 60)]),
    ('hit', 1, 0x00, 0x70, 0x08, [(0x81, 30), (0x81, 20), (0x80, 20)]),
    ('kill', 1, 0x00, 0x80, 0x08, [(0x81, 50), (0x41, 30), (0x41, 22), (0x40, 22)]),
    ('gem', 1, 0x00, 0x70, 0x08, [(0x11, 100), (0x11, 130), (0x10, 130)]),
    ('hurt', 3, 0x00, 0x90, 0x08, [(0x81, 12), (0x41, 18), (0x41, 14), (0x40, 14)]),
    ('bolt', 3, 0x00, 0xb0, 0x08, [(0x81, 120), (0x81, 90), (0x81, 110)] + sweep(0x81, 70, 20, 8) + [(0x80, 20)]),
    ('fire', 2, 0x00, 0xa0, 0x08, sweep(0x81, 20, 6, 14) + [(0x80, 6)]),
    ('levelup', 5, 0x00, 0xa0, 0x08, tone(0x41, [50, 63, 75, 100, 75, 100, 126], 3) + [(0x40, 126)]),
    ('choose', 4, 0x00, 0xa0, 0x08, tone(0x11, [60, 80, 100, 120], 2) + [(0x10, 120)]),
    ('heal', 4, 0x00, 0x90, 0x08, tone(0x11, [80, 100, 80, 100, 120], 2) + [(0x10, 120)]),
    ('boss', 5, 0x0a, 0xfb, 0x08, sweep(0x21, 8, 30, 20) + sweep(0x21, 30, 6, 20) + [(0x20, 6)]),
    ('bossdie', 6, 0x0a, 0xfb, 0x08, sweep(0x81, 40, 1, 50) + [(0x80, 1)]),
    ('die', 6, 0x00, 0xf9, 0x08, sweep(0x21, 60, 4, 50) + [(0x20, 4)]),
    ('menu', 2, 0x00, 0x90, 0x08, [(0x41, 60), (0x41, 80), (0x40, 80)]),
    ('cheat', 6, 0x00, 0xa0, 0x08, [(0x11, f) for f in (40, 50, 60, 80, 100, 120, 160, 200) for _ in range(3)] + [(0x10, 200)]),
    ('move', 2, 0x00, 0x80, 0x08, [(0x41, 70), (0x40, 70)]),
]
music.SFXID.clear()
music.SFXID.update({s[0]: i for i, s in enumerate(music.SFX)})

def music_asm():
    return music.music_asm()
