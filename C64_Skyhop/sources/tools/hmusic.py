# SKYHOP - music and sound effects (compiled by music.py)
import music
from music import Song, bass_bar, arp_bar, arp_rhythm, DRUMS, sweep

def L(s):
    return 'ilead ' + s

def song_title():
    s = Song('title', 6)
    s.bar(bass_bar('C', 'eighth'), 'r:16', arp_bar('C'))
    s.bar(bass_bar('G', 'eighth'), 'r:16', arp_bar('G'))
    s.mark_loop()
    prog = ['C', 'G', 'Am', 'F', 'C', 'G', 'F', 'G']
    lead = ['c4:2 e4:2 g4:2 c5:4 g4:2 e4:2 g4:2',
            'b4:2 d5:2 b4:2 g4:4 b4:2 d5:4',
            'c5:2 a4:2 e4:2 a4:4 c5:2 e5:4',
            'f4:2 a4:2 c5:2 f5:4 e5:2 d5:2 c5:2',
            'e5:2 d5:2 c5:2 g4:4 e4:2 g4:4',
            'd5:4 b4:2 g4:2 d5:4 g5:4',
            'a4:2 c5:2 f5:2 e5:2 d5:2 c5:2 a4:4',
            'b4:4 d5:4 g5:4 f5:2 d5:2']
    for ch, ld in zip(prog, lead):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_bar(ch))
    prog2 = ['Am', 'F', 'C', 'G', 'Am', 'F', 'C', 'G']
    lead2 = ['e5:6 d5:2 c5:4 a4:4', 'f5:6 e5:2 d5:4 c5:4', 'e5:4 g5:4 e5:4 c5:4', 'd5:8 b4:4 g4:4',
             'c5:6 b4:2 a4:4 c5:4', 'a4:6 g4:2 f4:4 a4:4', 'g4:4 c5:4 e5:4 g5:4', 'g5:8 f5:4 d5:4']
    for i, (ch, ld) in enumerate(zip(prog2, lead2)):
        s.bar(bass_bar(ch, 'gallop'), L(ld), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_game():
    s = Song('game', 7)
    prog = ['G', 'Em', 'C', 'D', 'G', 'Em', 'C', 'D']
    lead = ['g4:2 b4:2 d5:4 b4:2 g4:2 d5:4',
            'e5:4 d5:2 b4:2 g4:8',
            'e4:2 g4:2 c5:4 e5:4 d5:2 c5:2',
            'd5:8 a4:4 f#4:4',
            'g4:2 b4:2 d5:4 g5:4 f#5:2 e5:2',
            'e5:4 g5:2 e5:2 b4:8',
            'c5:2 e5:2 g5:4 e5:2 c5:2 g4:4',
            'a4:4 c5:4 d5:4 f#5:4']
    for ch, ld in zip(prog, lead):
        s.bar(bass_bar(ch, 'eighth'), L(ld), DRUMS['half'])
    prog2 = ['Em', 'C', 'G', 'D', 'Em', 'C', 'D', 'D']
    lead2 = ['b4:4 r:2 b4:2 c5:2 b4:2 g4:4', 'c5:4 r:2 c5:2 e5:2 d5:2 c5:4', 'b4:4 d5:4 g5:4 d5:4', 'a4:8 f#4:8',
             'g4:2 b4:2 e5:4 d5:2 b4:2 g4:4', 'e4:2 g4:2 c5:4 b4:2 g4:2 e4:4', 'f#4:4 a4:4 d5:4 a4:4', 'd5:4 c5:4 b4:4 a4:4']
    for i, (ch, ld) in enumerate(zip(prog2, lead2)):
        s.bar(bass_bar(ch, 'gallop'), L(ld), arp_rhythm(ch, 4) if i != 7 else DRUMS['fill'])
    return s

def song_over():
    s = Song('over', 7, loop=False)
    s.bar('ibass c3:8 g2:8', 'ilead g4:4 e4:4 c4:4 g3:4', 'iarpmaj c4:8 iarpmin a3:8')
    s.bar('ibass f2:8 g2:8', 'ilead a3:6 b3:2 c4:8', 'iarpmaj f3:8 c4:8')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_moon():
    s = Song('moon', 6)
    prog = ['C', 'F', 'G', 'C', 'Am', 'F', 'G', 'G']
    lead = ['c5:4 e5:4 g5:6 e5:2', 'f5:4 a4:4 c5:4 f5:4', 'g5:6 f5:2 e5:4 d5:4', 'e5:8 c5:8',
            'a4:4 c5:4 e5:4 a5:4', 'f5:6 e5:2 d5:4 c5:4', 'd5:4 g4:4 b4:4 d5:4', 'g5:8 g4:8']
    for ch, ld in zip(prog, lead):
        s.bar(bass_bar(ch, 'gallop'), L(ld), arp_bar(ch))
    for i, ch in enumerate(prog):
        s.bar(bass_bar(ch, 'eighth'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_jingle():
    s = Song('jingle', 4, loop=False)
    s.bar('ibass c3:4 e3:4 g3:4 c4:4', 'ilead c5:2 e5:2 g5:2 c5:4 g4:2 c5:4', 'iarpmaj c4:16')
    s.bar('r:16', 'r:16', 'r:16')
    return s

music.SONGS = [song_title, song_game, song_over, song_moon, song_jingle]

def tone(wave, notes, rep=2):
    return [(wave, n) for n in notes for _ in range(rep)]

music.SFX[:] = [
    ('jump', 1, 0x00, 0x80, 0x04, sweep(0x41, 18, 44, 6) + [(0x40, 44)]),
    ('spring', 3, 0x00, 0xa0, 0x08, sweep(0x11, 14, 70, 8) + sweep(0x11, 60, 30, 5) + sweep(0x11, 34, 64, 5) + [(0x10, 64)]),
    ('break', 2, 0x00, 0x90, 0x08, sweep(0x81, 50, 8, 9) + [(0x80, 8)]),
    ('poof', 2, 0x00, 0x80, 0x08, [(0x81, 90), (0x81, 70), (0x81, 100), (0x80, 100)]),
    ('shoot', 1, 0x00, 0x80, 0x08, sweep(0x41, 80, 30, 5) + [(0x40, 30)]),
    ('stomp', 3, 0x00, 0x90, 0x08, [(0x21, 30), (0x21, 22), (0x81, 18), (0x21, 12), (0x80, 12)]),
    ('kill', 3, 0x00, 0xa0, 0x08, [(0x81, 60)] + sweep(0x21, 40, 6, 10) + [(0x20, 6)]),
    ('fall', 5, 0x00, 0xf0, 0x08, sweep(0x11, 90, 6, 70) + [(0x10, 6)]),
    ('hat', 1, 0x00, 0x70, 0x04, [(0x41, 26), (0x41, 26), (0x40, 26), (0x41, 30), (0x41, 30), (0x40, 30)]),
    ('jet', 1, 0x00, 0x90, 0x08, [(0x81, 14), (0x81, 10), (0x81, 16), (0x81, 12), (0x81, 15), (0x81, 11), (0x80, 11)]),
    ('pickup', 4, 0x00, 0xa0, 0x08, tone(0x41, [40, 50, 60, 80, 100, 120], 2) + [(0x40, 120)]),
    ('hole', 5, 0x00, 0xf0, 0x08, sweep(0x21, 70, 2, 60) + [(0x20, 2)]),
    ('zone', 4, 0x00, 0xa0, 0x08, tone(0x11, [64, 80, 96, 128, 96, 128], 3) + [(0x10, 128)]),
    ('menu', 2, 0x00, 0x90, 0x08, [(0x41, 60), (0x41, 80), (0x40, 80)]),
    ('cheat', 6, 0x00, 0xa0, 0x08, [(0x11, f) for f in (40, 50, 60, 80, 100, 120, 160, 200) for _ in range(3)] + [(0x10, 200)]),
    ('land', 4, 0x00, 0xa0, 0x08, tone(0x11, [50, 64, 76, 100, 76, 100, 128], 3) + [(0x10, 128)]),
]
music.SFXID.clear()
music.SFXID.update({s[0]: i for i, s in enumerate(music.SFX)})

def music_asm():
    return music.music_asm()
