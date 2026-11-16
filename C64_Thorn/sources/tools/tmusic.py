# THORN - original compositions (uses the ZYRON music compiler)
import music
from music import Song, bass_bar, arp_bar, arp_rhythm, DRUMS, L, nn, chord, sweep

def song_title():           # quirky waltz-ish garden tune in G minor
    s = Song('title', 6)
    p = ['Gm', 'Eb', 'Cm', 'D', 'Gm', 'Eb', 'Cm', 'D']
    lead = ['g4:2 bb4:2 d5:2 g5:4 f#5:2 g5:4', 'eb5:4 d5:2 c5:2 bb4:4 g4:4', 'c5:2 eb5:2 g5:2 c6:4 bb5:2 a5:4', 'a5:4 f#5:4 d5:8',
            'g5:2 a5:2 bb5:2 d6:4 c6:2 bb5:4', 'eb6:4 d6:2 c6:2 bb5:4 g5:4', 'c6:2 bb5:2 a5:2 g5:4 eb5:2 c5:4', 'd5:8 f#5:4 a5:4']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'eighth'), 'r:16', arp_bar(ch, 4))
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'eighth'), L(ld), DRUMS['half'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_day():             # sunny, bouncy in D
    s = Song('day', 5)
    p = ['D', 'Bm', 'G', 'A', 'D', 'Bm', 'Em', 'A']
    lead = ['f#5:2 a5:2 d6:2 a5:2 f#5:4 d5:4', 'b4:2 d5:2 f#5:2 b5:2 a5:4 f#5:4', 'g5:4 b5:2 g5:2 d5:4 g5:4', 'a5:6 c#6:2 e6:8',
            'd6:2 c#6:2 a5:2 f#5:2 d5:4 f#5:4', 'b5:2 f#5:2 d5:2 f#5:2 b5:4 a5:4', 'g5:2 e5:2 b4:2 e5:2 g5:4 b5:4', 'a5:8 c#6:4 e6:4']
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'eighth'), L(ld), DRUMS['half'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_dusk():            # wistful in A minor
    s = Song('dusk', 6)
    p = ['Am', 'F', 'C', 'G', 'Am', 'F', 'Dm', 'E']
    lead = ['e5:6 d5:2 c5:4 a4:4', 'f5:6 e5:2 c5:8', 'g5:4 e5:4 c5:4 e5:4', 'd5:8 b4:8',
            'a5:6 g5:2 e5:4 c5:4', 'c6:6 a5:2 f5:8', 'd5:4 f5:4 a5:4 d6:4', 'b5:8 g#5:8']
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'slow'), L(ld), arp_bar(ch, 4))
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'eighth'), arp_rhythm(ch, 4), DRUMS['half'] if i != 7 else DRUMS['fill'])
    return s

def song_night():           # creepy in C minor
    s = Song('night', 6)
    p = ['Cm', 'Cm', 'Ab', 'G', 'Cm', 'Fm', 'Ab', 'G']
    lead = ['c5:3 eb5:1 g5:4 f#5:4 g5:4', 'c6:6 b5:2 g5:8', 'ab5:3 g5:1 f5:4 eb5:4 c5:4', 'b4:8 d5:8',
            'g5:3 ab5:1 g5:4 eb5:4 c5:4', 'f5:3 g5:1 ab5:4 c6:8', 'eb6:4 d6:2 c6:2 ab5:8', 'b5:8 g5:8']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), 'r:16', arp_bar(ch, 4))
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'eighth'), 'ipad ' + ld, arp_bar(ch, 4))
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 4), DRUMS['half'] if i != 7 else DRUMS['fill'])
    return s

def song_boss():
    s = Song('boss', 4)
    p = ['Em', 'Em', 'C', 'B', 'Em', 'Em', 'Am', 'B']
    riff = ['e5:2 e5:1 e5:1 g5:2 e5:2 b5:2 a5:2 g5:2 f#5:2', 'e5:2 e5:1 e5:1 g5:2 e5:2 d6:2 b5:2 a5:2 b5:2',
            'c6:4 b5:2 a5:2 g5:4 e5:4', 'd#5:4 f#5:4 b5:8', 'e6:4 d6:2 c6:2 b5:4 g5:4', 'a5:4 g5:2 f#5:2 e5:8',
            'a5:2 c6:2 e6:4 d6:2 c6:2 a5:4', 'b5:8 d#6:8']
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, riff)):
        s.bar(bass_bar(ch, 'drive'), 'isaw ' + ld, DRUMS['fast'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_clear():
    s = Song('clear', 5, loop=False)
    s.bar('ibass g3:4 d4:4 g4:4 b3:4', 'ilead g5:2 b5:2 d6:2 g6:6 f#6:2 g6:2', 'iarpmaj g4:16')
    s.bar('ibass c4:4 d4:4 g3:8', 'ilead e6:4 f#6:4 g6:8', 'iarpmaj c4:8 g4:8')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_over():
    s = Song('over', 7, loop=False)
    s.bar('ibass c2:8 ab1:8', 'ilead g4:4 f4:4 eb4:4 c4:4', 'iarpmin c4:8 iarpmaj ab3:8')
    s.bar('ibass g1:8 c2:8', 'ilead b3:8 c4:8', 'iarpmaj g3:8 iarpmin c4:8')
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
    for ch in p:
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), arp_bar(ch))
    return s

music.SONGS = [song_title, song_day, song_dusk, song_night, song_boss, song_clear, song_over, song_end]

music.SFX.append(('plant', 3, 0x00, 0x90, 0x08, [(0x81, 20), (0x41, 14), (0x41, 10), (0x40, 10)]))
music.SFX.append(('pop', 1, 0x00, 0x70, 0x08, sweep(0x41, 50, 30, 3) + [(0x40, 30)]))
music.SFX.append(('splat', 2, 0x00, 0x80, 0x08, [(0x81, 60), (0x81, 40), (0x80, 40)]))
music.SFX.append(('chomp', 2, 0x00, 0x90, 0x08, [(0x81, 12), (0x41, 8), (0x81, 10), (0x80, 10)]))
music.SFX.append(('sun', 3, 0x00, 0xa0, 0x08, [(0x11, f) for f in (80, 100, 120, 160, 120, 160, 200)] + [(0x10, 200)]))
music.SFX.append(('mower', 5, 0x00, 0xf0, 0x08, [(0x41, 8 + (i % 3) * 2) for i in range(40)] + [(0x40, 8)]))
music.SFX.append(('siren', 6, 0x00, 0xf0, 0x08, (sweep(0x21, 30, 60, 12) + sweep(0x21, 60, 30, 12)) * 2 + [(0x20, 30)]))
music.SFX.append(('groan', 1, 0x0a, 0x80, 0x08, sweep(0x41, 6, 4, 20) + [(0x40, 4)]))
music.SFXID = {s[0]: i for i, s in enumerate(music.SFX)}

def music_asm():
    return music.music_asm()

if __name__ == '__main__':
    a, t, n = music_asm()
    print('patterns', n, 'bytes', t)
