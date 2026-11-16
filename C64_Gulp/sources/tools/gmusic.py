# GULP! - original compositions (uses the ZYRON music compiler)
import music
from music import Song, bass_bar, arp_bar, arp_rhythm, DRUMS, L, nn, chord, sweep

def song_title():           # bouncy island tune in F
    s = Song('title', 6)
    p = ['F', 'Bb', 'C', 'F', 'Dm', 'Bb', 'C', 'C']
    lead = ['c5:2 f5:2 a5:3 g5:1 f5:2 a5:2 c6:4', 'bb5:3 a5:1 g5:2 f5:2 d5:4 f5:4', 'e5:2 g5:2 c6:3 bb5:1 a5:2 g5:2 e5:4',
            'f5:6 a5:2 c6:8', 'd6:2 c6:2 a5:3 f5:1 d5:4 f5:4', 'bb5:2 d6:2 bb5:2 f5:2 d5:4 bb4:4', 'c5:2 e5:2 g5:2 c6:2 bb5:2 g5:2 e5:2 g5:2', 'c6:8 r:4 c5:4']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'eighth'), 'r:16', arp_rhythm(ch, 5))
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'eighth'), L(ld), DRUMS['half'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_reef():            # sunny reef in C
    s = Song('reef', 5)
    p = ['C', 'Am', 'F', 'G', 'C', 'Am', 'Dm', 'G']
    lead = ['e5:2 g5:2 c6:2 g5:2 e5:4 c5:4', 'a5:2 e5:2 c5:2 e5:2 a5:4 g5:4', 'f5:2 a5:2 c6:4 a5:2 f5:2 a5:4',
            'g5:4 b5:4 d6:4 b5:4', 'c6:2 b5:2 g5:2 e5:2 c5:4 e5:4', 'e5:2 a5:2 c6:2 a5:2 e5:4 a5:4', 'd5:2 f5:2 a5:2 d6:2 c6:4 a5:4', 'g5:8 b5:4 d6:4']
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'eighth'), L(ld), DRUMS['half'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), DRUMS['half'] if i != 7 else DRUMS['fill'])
    return s

def song_kelp():            # swaying kelp forest in A minor
    s = Song('kelp', 6)
    p = ['Am', 'G', 'F', 'E', 'Am', 'G', 'F', 'E']
    lead = ['a4:6 c5:2 e5:4 d5:4', 'b4:6 d5:2 g5:4 f5:4', 'a5:6 g5:2 f5:4 e5:4', 'g#5:8 e5:8',
            'c6:6 b5:2 a5:4 e5:4', 'd5:6 e5:2 g5:4 b5:4', 'a5:4 f5:4 c6:4 a5:4', 'b5:8 g#5:8']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), arp_bar(ch, 4), 'r:16')
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'slow'), L(ld), arp_bar(ch, 4))
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'eighth'), arp_rhythm(ch, 4), DRUMS['half'] if i != 7 else DRUMS['fill'])
    return s

def song_deep():            # dark deep sea in E minor
    s = Song('deep', 7)
    p = ['Em', 'Em', 'C', 'B', 'Em', 'Em', 'Am', 'B']
    lead = ['e4:8 g4:4 b4:4', 'c5:8 b4:8', 'e5:6 d5:2 c5:8', 'd#5:8 b4:8',
            'g5:6 f#5:2 e5:8', 'b5:6 a5:2 g5:8', 'a5:4 c6:4 b5:4 a5:4', 'f#5:8 d#5:8']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), 'r:16', arp_bar(ch, 4))
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'slow'), 'ipad ' + ld, arp_bar(ch, 4))
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'eighth'), arp_rhythm(ch, 4), DRUMS['half'])
    return s

def song_boss():
    s = Song('boss', 4)
    p = ['Dm', 'Dm', 'Bb', 'A', 'Dm', 'Dm', 'G', 'A']
    riff = ['d5:2 d5:1 d5:1 f5:2 d5:2 a5:2 g5:2 f5:2 e5:2', 'd5:2 d5:1 d5:1 f5:2 d5:2 c6:2 a5:2 g5:2 a5:2',
            'bb5:4 a5:2 g5:2 f5:4 d5:4', 'c#5:4 e5:4 a5:8', 'd6:4 c6:2 bb5:2 a5:4 f5:4', 'g5:4 f5:2 e5:2 d5:8',
            'g5:2 bb5:2 d6:4 c6:2 bb5:2 g5:4', 'a5:8 c#6:8']
    s.mark_loop()
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
    s.bar('ibass a1:8 f2:8', 'ilead e5:4 d5:4 c5:4 a4:4', 'iarpmin a3:8 iarpmaj f3:8')
    s.bar('ibass e2:8 a1:8', 'ilead g#4:8 a4:8', 'iarpmaj e3:8 iarpmin a3:8')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_end():
    s = Song('end', 6)
    p = ['G', 'D', 'Em', 'C', 'G', 'D', 'C', 'D']
    lead = ['b5:4 d6:4 g6:6 f#6:2', 'f#6:4 e6:2 d6:2 a5:8', 'g5:4 b5:4 e6:6 d6:2', 'c6:4 e6:4 g6:8',
            'g6:4 f#6:2 e6:2 d6:4 b5:4', 'a5:4 d6:4 f#6:8', 'e6:4 d6:2 c6:2 g6:4 e6:4', 'd6:12 d5:4']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), 'ipad ' + nn(60 + chord(ch)[0]) + ':16', arp_bar(ch))
    s.mark_loop()
    for ch, ld in zip(p, lead):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_bar(ch))
    for ch in p:
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), arp_bar(ch))
    return s

music.SONGS = [song_title, song_reef, song_kelp, song_deep, song_boss, song_clear, song_over, song_end]

music.SFX.append(('gulp', 2, 0x00, 0x90, 0x08, sweep(0x11, 30, 70, 3) + sweep(0x11, 50, 12, 4) + [(0x10, 12)]))
music.SFX.append(('sting', 4, 0x00, 0xa0, 0x08, [(0x81, 90), (0x41, 70), (0x81, 85), (0x41, 60), (0x81, 80)] + sweep(0x41, 60, 20, 8) + [(0x40, 20)]))
music.SFX.append(('pearl', 5, 0x00, 0xa0, 0x08, [(0x11, f) for f in (64, 80, 96, 128, 96, 128, 160, 128, 160, 192)] + [(0x10, 192)]))
music.SFX.append(('grow', 5, 0x00, 0xa0, 0x08, sweep(0x21, 20, 80, 14) + [(0x21, 80)] * 4 + [(0x20, 80)]))
music.SFX.append(('bite', 4, 0x00, 0xb0, 0x08, [(0x81, 30), (0x81, 20), (0x41, 15), (0x81, 10), (0x80, 10)]))
music.SFXID = {s[0]: i for i, s in enumerate(music.SFX)}

def music_asm():
    return music.music_asm()

if __name__ == '__main__':
    a, t, n = music_asm()
    print('patterns', n, 'bytes', t)
