# JETDASH - music and sound effects (original compositions, compiled by music.py)
import music
from music import Song, bass_bar, arp_bar, arp_rhythm, DRUMS, sweep

def L(s): return 'ilead ' + s
def S(s): return 'isaw ' + s

def song_title():
    # upbeat synth-pop in D minor / F major
    s = Song('title', 6)
    s.bar(bass_bar('Dm', 'drive'), 'r:16', arp_bar('Dm'))
    s.bar(bass_bar('Bb', 'drive'), 'r:16', arp_bar('Bb'))
    s.mark_loop()
    prog = ['Dm', 'Bb', 'F', 'C', 'Dm', 'Bb', 'C', 'A']
    lead = ['d5:2 f5:2 a5:4 g5:2 f5:2 e5:2 f5:2',
            'd5:4 r:2 d5:2 f5:2 g5:2 f5:4',
            'c5:2 f5:2 a5:4 c6:4 a5:2 g5:2',
            'g5:6 e5:2 c5:4 e5:4',
            'd5:2 f5:2 a5:4 d6:4 c6:2 a5:2',
            'bb5:4 a5:2 g5:2 f5:4 d5:4',
            'e5:2 g5:2 c6:4 bb5:2 a5:2 g5:4',
            'a5:8 c#5:4 e5:4']
    for i, (ch, ld) in enumerate(zip(prog, lead)):
        s.bar(bass_bar(ch, 'drive'), L(ld), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    prog2 = ['Bb', 'C', 'Am', 'Dm', 'Bb', 'C', 'A', 'A']
    lead2 = ['f5:4 d5:4 bb4:4 d5:4', 'e5:4 g5:4 c6:8', 'a5:4 e5:4 c5:4 e5:4', 'f5:8 d5:4 a4:4',
             'd5:2 f5:2 bb5:4 a5:2 g5:2 f5:4', 'g5:2 e5:2 c5:4 e5:2 g5:2 c6:4', 'c#6:6 a5:2 e5:4 c#5:4', 'e5:4 g5:4 a5:8']
    for i, (ch, ld) in enumerate(zip(prog2, lead2)):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_rhythm(ch, 4) if i != 7 else DRUMS['fill'])
    return s

def song_game():
    # driving lab chase in A minor
    s = Song('game', 6)
    s.bar(bass_bar('Am', 'drive'), 'r:16', DRUMS['fast'])
    s.mark_loop()
    prog = ['Am', 'F', 'G', 'Em', 'Am', 'F', 'G', 'E']
    lead = ['a4:2 c5:2 e5:2 a5:4 g5:2 e5:4',
            'f5:4 e5:2 c5:2 a4:4 c5:4',
            'd5:2 g5:2 b5:4 a5:2 g5:2 d5:4',
            'e5:8 b4:4 e5:4',
            'a5:2 g5:2 e5:2 c5:4 d5:2 e5:4',
            'f5:2 a5:2 c6:4 a5:2 f5:2 c5:4',
            'b4:2 d5:2 g5:4 f5:2 d5:2 b4:4',
            'g#4:4 b4:4 e5:4 g#5:4']
    for i, (ch, ld) in enumerate(zip(prog, lead)):
        s.bar(bass_bar(ch, 'drive'), L(ld), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    prog2 = ['F', 'G', 'Am', 'Am', 'F', 'G', 'E', 'E']
    for i, ch in enumerate(prog2):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    lead3 = ['c6:4 b5:4 a5:4 e5:4', 'd5:4 e5:4 f5:4 g5:4', 'e5:6 c5:2 a4:8', 'a4:2 c5:2 e5:2 a5:2 e5:2 c5:2 a4:4',
             'f5:4 a5:4 c6:4 a5:4', 'g5:4 b5:4 d6:4 b5:4', 'g#5:6 e5:2 b4:4 e5:4', 'b5:8 g#5:8']
    for i, (ch, ld) in enumerate(zip(prog2, lead3)):
        s.bar(bass_bar(ch, 'drive'), S(ld), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    return s

def song_over():
    s = Song('over', 7, loop=False)
    s.bar('ibass a2:8 e2:8', 'ilead e5:4 c5:4 a4:4 e4:4', 'iarpmin a3:16')
    s.bar('ibass f2:8 e2:8', 'ilead f4:6 e4:2 d#4:4 e4:4', 'iarpmaj e3:16')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_end():
    # outside: bright and wide in C major
    s = Song('end', 6)
    prog = ['C', 'G', 'Am', 'F', 'C', 'G', 'F', 'G']
    lead = ['e5:4 g5:4 c6:6 b5:2', 'd6:4 b5:4 g5:8', 'a5:4 c6:4 e6:6 d6:2', 'c6:4 a5:4 f5:8',
            'g5:4 c6:4 e6:4 g6:4', 'f6:4 d6:4 b5:8', 'a5:4 c6:4 f6:4 e6:2 d6:2', 'd6:8 g5:8']
    for ch, ld in zip(prog, lead):
        s.bar(bass_bar(ch, 'gallop'), L(ld), arp_bar(ch))
    for i, ch in enumerate(prog):
        s.bar(bass_bar(ch, 'eighth'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_jingle():
    s = Song('jingle', 4, loop=False)
    s.bar('ibass a2:4 c3:4 e3:4 a3:4', 'ilead a4:2 c5:2 e5:2 a5:4 e5:2 a5:4', 'iarpmin a3:16')
    s.bar('r:16', 'r:16', 'r:16')
    return s

music.SONGS = [song_title, song_game, song_over, song_end, song_jingle]

def tone(wave, notes, rep=2):
    return [(wave, n) for n in notes for _ in range(rep)]

music.SFX[:] = [
    ('jet', 0, 0x00, 0x60, 0x08, [(0x81, 6), (0x81, 9), (0x81, 5), (0x80, 5)]),
    ('coin', 1, 0x00, 0x90, 0x08, [(0x41, 90), (0x41, 90), (0x41, 120), (0x41, 120), (0x41, 120), (0x40, 120)]),
    ('flap', 1, 0x00, 0x80, 0x08, sweep(0x81, 20, 40, 4) + [(0x80, 40)]),
    ('flip', 2, 0x00, 0x90, 0x04, sweep(0x41, 30, 90, 6) + [(0x40, 90)]),
    ('bump', 2, 0x00, 0x90, 0x08, [(0x81, 14), (0x81, 10), (0x11, 8), (0x10, 8)]),
    ('oops', 2, 0x00, 0x80, 0x08, sweep(0x21, 50, 20, 6) + [(0x20, 20)]),
    ('warn', 3, 0x00, 0x90, 0x08, [(0x41, 80)] * 4 + [(0x40, 80)] * 3 + [(0x41, 80)] * 4 + [(0x40, 80)]),
    ('launch', 3, 0x00, 0xa0, 0x08, sweep(0x81, 60, 20, 12) + [(0x80, 20)]),
    ('charge', 3, 0x00, 0x90, 0x08, sweep(0x21, 10, 60, 16) + [(0x20, 60)]),
    ('laser', 4, 0x00, 0xa0, 0x04, sweep(0x41, 100, 70, 10) + sweep(0x81, 70, 50, 6) + [(0x80, 50)]),
    ('boom', 5, 0x00, 0xd9, 0x08, sweep(0x81, 30, 2, 24) + [(0x80, 2)]),
    ('zap', 6, 0x00, 0xf9, 0x08, [(0x81, 90), (0x41, 120), (0x81, 70), (0x41, 100), (0x81, 60)] + sweep(0x21, 60, 4, 40) + [(0x20, 4)]),
    ('gadget', 4, 0x00, 0xa0, 0x08, tone(0x41, [40, 50, 60, 80, 100, 120, 160], 2) + [(0x40, 160)]),
    ('zone', 4, 0x00, 0xa0, 0x08, tone(0x11, [64, 80, 96, 128, 96, 128], 3) + [(0x10, 128)]),
    ('menu', 2, 0x00, 0x90, 0x08, [(0x41, 60), (0x41, 80), (0x40, 80)]),
    ('cheat', 6, 0x00, 0xa0, 0x08, [(0x11, f) for f in (40, 50, 60, 80, 100, 120, 160, 200) for _ in range(3)] + [(0x10, 200)]),
]
music.SFXID.clear()
music.SFXID.update({s[0]: i for i, s in enumerate(music.SFX)})

def music_asm():
    return music.music_asm()
