# SWARM - original compositions (uses the ZYRON music compiler)
import music
from music import Song, bass_bar, arp_bar, arp_rhythm, DRUMS, L, nn, chord

def song_title():
    s = Song('title', 6)
    p = ['Dm', 'Bb', 'F', 'C', 'Dm', 'Bb', 'Gm', 'A']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), 'ipad ' + nn(62 + chord(ch)[0] % 12 - 2) + ':16' if False else 'r:16', arp_bar(ch))
    s.mark_loop()
    lead = ['d5:4 f5:2 a5:2 d6:6 c6:2', 'bb5:4 a5:2 f5:2 d5:8', 'c5:2 f5:2 a5:4 c6:4 a5:4', 'g5:6 e5:2 c5:8',
            'a5:2 g5:2 f5:2 e5:2 d5:4 a4:4', 'bb4:4 d5:4 f5:8', 'g5:4 bb5:4 d6:4 bb5:4', 'a5:8 c#6:8']
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'eighth'), L(ld), DRUMS['half'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_boss():
    s = Song('boss', 4)
    p = ['Gm', 'Gm', 'Eb', 'F', 'Gm', 'Gm', 'Ab', 'D']
    s.mark_loop()
    riff = ['g4:2 g4:1 g4:1 bb4:2 g4:2 d5:2 c5:2 bb4:2 a4:2', 'g4:2 g4:1 g4:1 bb4:2 g4:2 f5:2 d5:2 c5:2 d5:2',
            'eb5:2 eb5:1 eb5:1 g5:2 eb5:2 bb5:2 g5:2 eb5:2 g5:2', 'f5:2 f5:1 f5:1 a5:2 f5:2 c6:2 a5:2 f5:2 a5:2',
            'd6:4 c6:2 bb5:2 a5:4 g5:4', 'bb5:4 a5:2 g5:2 f5:4 d5:4', 'ab5:4 g5:2 ab5:2 c6:4 eb6:4', 'd6:8 f#5:8']
    for i, (ch, ld) in enumerate(zip(p, riff)):
        s.bar(bass_bar(ch, 'drive'), 'isaw ' + ld, DRUMS['fast'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_clear():
    s = Song('clear', 5, loop=False)
    s.bar('ibass d3:4 a3:4 d4:4 f#3:4', 'ilead d5:2 f#5:2 a5:2 d6:6 c#6:2 d6:2', 'iarpmaj d4:16')
    s.bar('ibass g3:4 a3:4 d3:8', 'ilead b5:4 c#6:4 d6:8', 'iarpmaj g4:8 d4:8')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_over():
    s = Song('over', 7, loop=False)
    s.bar('ibass d2:8 bb1:8', 'ilead a4:4 g4:4 f4:4 d4:4', 'iarpmin d4:8 iarpmaj bb3:8')
    s.bar('ibass a1:8 d2:8', 'ilead c#4:8 d4:8', 'iarpmaj a3:8 iarpmin d4:8')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_end():
    s = Song('end', 6)
    p = ['F', 'C', 'Dm', 'Bb', 'F', 'C', 'Bb', 'C']
    lead = ['a5:4 c6:4 f6:6 e6:2', 'e6:4 d6:2 c6:2 g5:8', 'f5:4 a5:4 d6:6 c6:2', 'bb5:4 d6:4 f6:8',
            'f6:4 e6:2 d6:2 c6:4 a5:4', 'g5:4 c6:4 e6:8', 'd6:4 c6:2 bb5:2 f6:4 d6:4', 'c6:12 c5:4']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), 'ipad ' + nn(60 + chord(ch)[0]) + ':16', arp_bar(ch))
    s.mark_loop()
    for ch, ld in zip(p, lead):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_bar(ch))
    for ch in p:
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), arp_bar(ch))
    return s

music.SONGS = [song_title, song_boss, song_clear, song_over, song_end]

# extra sfx for SWARM (appended)
music.SFX.append(('ufo', 1, 0x00, 0xf0, 0x08, [(0x11, f) for f in (30, 34, 38, 42, 46, 42, 38, 34)] * 2 + [(0x10, 30)]))
music.SFX.append(('bunker', 1, 0x00, 0x70, 0x08, [(0x81, 60), (0x81, 30), (0x80, 20)]))
music.SFXID = {s[0]: i for i, s in enumerate(music.SFX)}

def music_asm():
    return music.music_asm()

if __name__ == '__main__':
    a, t, n = music_asm()
    print('patterns', n, 'bytes', t)
