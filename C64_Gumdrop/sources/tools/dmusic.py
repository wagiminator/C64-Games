# GUMDROP - music and sound effects (original compositions, compiled by music.py)
import music
from music import Song, bass_bar, arp_bar, arp_rhythm, DRUMS, sweep

def L(s): return 'ilead ' + s
def T(s): return 'itri ' + s

def song_title():
    # bouncy waltz-like pop in F major
    s = Song('title', 6)
    s.bar(bass_bar('F', 'eighth'), 'r:16', arp_bar('F'))
    s.mark_loop()
    prog = ['F', 'Dm', 'Bb', 'C', 'F', 'Am', 'Bb', 'C']
    lead = ['a4:2 c5:2 f5:4 e5:2 f5:2 a5:4',
            'f5:2 d5:2 a4:4 d5:4 f5:4',
            'd5:4 f5:2 d5:2 bb4:4 d5:4',
            'c5:2 e5:2 g5:4 e5:2 c5:2 g4:4',
            'a4:2 c5:2 f5:4 a5:4 g5:2 f5:2',
            'e5:4 c5:2 e5:2 a5:8',
            'bb5:4 a5:2 g5:2 f5:4 d5:4',
            'e5:4 g5:4 c6:8']
    for i, (ch, ld) in enumerate(zip(prog, lead)):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_bar(ch) if i % 2 == 0 else arp_rhythm(ch, 4))
    prog2 = ['Bb', 'C', 'Am', 'Dm', 'Gm', 'C', 'F', 'F']
    lead2 = ['d6:4 c6:4 bb5:4 a5:4', 'g5:4 a5:4 bb5:4 c6:4', 'c6:6 a5:2 e5:4 a5:4', 'f5:8 d5:4 f5:4',
             'g5:2 bb5:2 d6:4 c6:2 bb5:2 g5:4', 'e5:2 g5:2 c6:4 bb5:2 g5:2 e5:4', 'f5:4 a5:4 c6:4 a5:4', 'f5:8 r:8']
    for i, (ch, ld) in enumerate(zip(prog2, lead2)):
        s.bar(bass_bar(ch, 'gallop'), L(ld), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_game():
    # relaxed puzzle groove in C major
    s = Song('game', 7)
    s.mark_loop()
    prog = ['C', 'Am', 'F', 'G', 'C', 'Am', 'Dm', 'G']
    lead = ['e5:4 g5:2 e5:2 c5:4 d5:4',
            'e5:2 c5:2 a4:4 r:4 c5:4',
            'f5:4 a5:2 f5:2 c5:4 a4:4',
            'b4:2 d5:2 g5:4 f5:2 d5:2 b4:4',
            'c5:2 e5:2 g5:4 c6:4 b5:2 a5:2',
            'a5:4 e5:4 c5:8',
            'd5:2 f5:2 a5:4 g5:2 f5:2 d5:4',
            'g5:8 f5:4 d5:4']
    for i, (ch, ld) in enumerate(zip(prog, lead)):
        s.bar(bass_bar(ch, 'eighth'), T(ld), DRUMS['half'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(['F', 'G', 'Em', 'Am', 'Dm', 'G', 'C', 'C']):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_over():
    s = Song('over', 7, loop=False)
    s.bar('ibass c3:8 g2:8', 'ilead g4:4 e4:4 c4:4 g3:4', 'iarpmaj c4:16')
    s.bar('ibass f2:8 c2:8', 'ilead a3:6 g3:2 c4:8', 'iarpmaj f3:16')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_end():
    s = Song('end', 6)
    prog = ['G', 'Em', 'C', 'D', 'G', 'Em', 'C', 'D']
    lead = ['b4:2 d5:2 g5:4 b5:4 a5:2 g5:2', 'g5:4 e5:4 b4:8', 'c5:2 e5:2 g5:4 c6:4 b5:2 a5:2', 'a5:8 f#5:4 d5:4',
            'd5:2 g5:2 b5:4 d6:4 c6:2 b5:2', 'b5:4 g5:4 e5:8', 'e5:2 g5:2 c6:4 e6:4 d6:2 c6:2', 'd6:8 a5:8']
    for ch, ld in zip(prog, lead):
        s.bar(bass_bar(ch, 'gallop'), L(ld), arp_bar(ch))
    for i, ch in enumerate(prog):
        s.bar(bass_bar(ch, 'eighth'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_clear():
    s = Song('clear', 4, loop=False)
    s.bar('ibass c3:4 e3:4 g3:4 c4:4', 'ilead c5:2 e5:2 g5:2 c6:4 g5:2 c6:4', 'iarpmaj c4:16')
    s.bar('r:16', 'r:16', 'r:16')
    return s

music.SONGS = [song_title, song_game, song_over, song_end, song_clear]

def tone(wave, notes, rep=2):
    return [(wave, n) for n in notes for _ in range(rep)]

music.SFX[:] = [
    ('select', 1, 0x00, 0x80, 0x08, [(0x41, 60), (0x41, 60), (0x40, 60)]),
    ('swap', 1, 0x00, 0x80, 0x08, sweep(0x11, 40, 70, 5) + [(0x10, 70)]),
    ('back', 2, 0x00, 0x80, 0x08, sweep(0x11, 70, 30, 6) + [(0x10, 30)]),
    ('pop', 2, 0x00, 0x90, 0x08, [(0x41, 90), (0x41, 120), (0x41, 150), (0x40, 150)]),
    ('pop2', 2, 0x00, 0x90, 0x08, [(0x41, 110), (0x41, 140), (0x41, 180), (0x40, 180)]),
    ('pop3', 2, 0x00, 0x90, 0x08, [(0x41, 130), (0x41, 170), (0x41, 210), (0x40, 210)]),
    ('special', 3, 0x00, 0xa0, 0x08, tone(0x41, [50, 63, 75, 100], 2) + [(0x40, 100)]),
    ('line', 4, 0x00, 0xa0, 0x08, sweep(0x81, 100, 30, 14) + [(0x80, 30)]),
    ('bomb', 4, 0x00, 0xd9, 0x08, sweep(0x81, 30, 3, 20) + [(0x80, 3)]),
    ('rainbow', 5, 0x00, 0xa0, 0x08, [(0x11, f) for f in (40, 60, 80, 100, 120, 140, 160, 180, 200, 220) for _ in range(2)] + [(0x10, 220)]),
    ('ice', 2, 0x00, 0x90, 0x08, [(0x81, 120), (0x81, 160), (0x81, 100), (0x80, 100)]),
    ('shuffle', 4, 0x00, 0xa0, 0x08, sweep(0x21, 20, 80, 10) + sweep(0x21, 80, 20, 10) + [(0x20, 20)]),
    ('bonus', 3, 0x00, 0x90, 0x08, [(0x41, 100), (0x41, 130), (0x40, 130)]),
    ('fail', 5, 0x00, 0xa0, 0x08, sweep(0x21, 60, 15, 30) + [(0x20, 15)]),
    ('menu', 2, 0x00, 0x90, 0x08, [(0x41, 60), (0x41, 80), (0x40, 80)]),
    ('cheat', 6, 0x00, 0xa0, 0x08, [(0x11, f) for f in (40, 50, 60, 80, 100, 120, 160, 200) for _ in range(3)] + [(0x10, 200)]),
]
music.SFXID.clear()
music.SFXID.update({s[0]: i for i, s in enumerate(music.SFX)})

def music_asm():
    return music.music_asm()
