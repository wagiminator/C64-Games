# VEXOR - original compositions (uses the ZYRON music compiler)
import music
from music import Song, bass_bar, arp_bar, arp_rhythm, DRUMS, L, nn, chord

def funk_bass(ch):
    r, q, _ = chord(ch)
    root = 2 * 12 + r
    if root < 2 * 12 + 4: root += 12
    seq = [(root, 2), (root, 1), (root + 12, 1), (r + 36 if False else root, 2), (root + 10 if q == 'min' else root + 7, 2),
           (root, 1), (root, 1), (root + 12, 2), (root + 7, 2), (root + 10 if q == 'min' else root + 12, 2)]
    s = 'ibass '; cur = None
    for n, l in seq:
        s += nn(n) + (':%d' % l if l != cur else '') + ' '; cur = l
    return s

BREAK = 'ikick c4:2 ihat c4:1 ihat c4 isnare c4:2 ihat c4 ikick c4:1 ikick c4 ihat c4:2 isnare c4 ihat c4:1 isnare c4'

def song_title():
    s = Song('title', 6)
    p = ['Em', 'C', 'D', 'Bm', 'Em', 'C', 'Am', 'B']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), 'r:16', arp_bar(ch))
    s.mark_loop()
    lead = ['b4:4 e5:4 g5:6 f#5:2', 'e5:4 c5:4 g4:8', 'a4:4 d5:4 f#5:4 a5:4', 'f#5:8 d5:4 b4:4',
            'e5:2 g5:2 b5:4 a5:2 g5:2 e5:4', 'g5:4 e5:4 c5:8', 'c5:4 e5:4 a5:6 g5:2', 'f#5:8 d#5:8']
    for ch, ld in zip(p, lead):
        s.bar(funk_bass(ch), L(ld), arp_bar(ch))
    for ch in p:
        s.bar(funk_bass(ch), arp_rhythm(ch, 5), BREAK)
    return s

def song_stage1():
    s = Song('stage1', 5)
    p = ['Am', 'Am', 'G', 'F', 'Am', 'Am', 'G', 'E']
    for i, ch in enumerate(p[:4]):
        s.bar(funk_bass(ch), arp_rhythm(ch), DRUMS['half'] if i < 3 else DRUMS['fill'])
    s.mark_loop()
    lead = ['e5:2 e5:2 a5:2 e5:2 g5:4 e5:4', 'c5:2 d5:2 e5:2 a4:2 c5:8', 'd5:2 d5:2 g5:2 d5:2 f5:4 d5:4', 'c5:4 a4:4 f4:8',
            'a4:2 c5:2 e5:2 a5:2 g5:2 e5:2 c5:4', 'e5:4 d5:2 c5:2 a4:8', 'b4:4 d5:4 g5:4 b5:4', 'g#5:8 e5:8']
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(funk_bass(ch), L(ld), BREAK if i != 7 else DRUMS['fill'])
    p2 = ['F', 'G', 'Am', 'Am', 'F', 'G', 'E', 'E']
    for i, ch in enumerate(p2):
        s.bar(bass_bar(ch, 'drive'), arp_rhythm(ch, 5), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    return s

def song_stage2():
    s = Song('stage2', 5)
    p = ['Cm', 'Cm', 'Ab', 'Bb', 'Cm', 'Fm', 'G', 'G']
    for i, ch in enumerate(p[:4]):
        s.bar(bass_bar(ch, 'gallop'), arp_bar(ch), DRUMS['march'])
    s.mark_loop()
    lead = ['c5:4 eb5:4 g5:4 c6:4', 'bb5:4 g5:4 eb5:8', 'c5:4 eb5:2 f5:2 ab5:8', 'bb5:4 f5:4 d5:8',
            'g5:2 f5:2 eb5:2 d5:2 c5:4 g4:4', 'ab4:4 c5:4 f5:8', 'g5:4 b4:4 d5:4 f5:4', 'g5:16']
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'gallop'), L(ld), DRUMS['march'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(funk_bass(ch), arp_rhythm(ch, 5), BREAK)
    return s

def song_boss():
    s = Song('boss', 4)
    p = ['Dm', 'Dm', 'Bb', 'C', 'Dm', 'Dm', 'Eb', 'A']
    s.mark_loop()
    riff = ['d5:2 d5:1 d5:1 f5:2 d5:2 a5:2 g5:2 f5:2 e5:2', 'd5:2 d5:1 d5:1 f5:2 d5:2 c6:2 a5:2 g5:2 a5:2',
            'bb4:2 bb4:1 bb4:1 d5:2 bb4:2 f5:2 d5:2 bb4:2 d5:2', 'c5:2 c5:1 c5:1 e5:2 c5:2 g5:2 e5:2 c5:2 e5:2',
            'a5:4 g5:2 f5:2 e5:4 d5:4', 'f5:4 e5:2 d5:2 c5:4 a4:4', 'eb5:4 d5:2 eb5:2 g5:4 bb5:4', 'a5:8 c#5:8']
    for i, (ch, ld) in enumerate(zip(p, riff)):
        s.bar(bass_bar(ch, 'drive'), 'isaw ' + ld, DRUMS['fast'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 5), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_clear():
    s = Song('clear', 5, loop=False)
    s.bar('ibass g2:4 d3:4 g3:4 b2:4', 'ilead g5:2 b5:2 d6:2 g6:6 f#6:2 g6:2', 'iarpmaj g4:16')
    s.bar('ibass c3:4 d3:4 g2:8', 'ilead e6:4 f#6:4 g6:8', 'iarpmaj c4:8 g4:8')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_over():
    s = Song('over', 7, loop=False)
    s.bar('ibass e2:8 c2:8', 'ilead b4:4 a4:4 g4:4 e4:4', 'iarpmin e4:8 iarpmaj c4:8')
    s.bar('ibass b1:8 e2:8', 'ilead d#4:8 e4:8', 'iarpmaj b3:8 iarpmin e4:8')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_end():
    s = Song('end', 6)
    p = ['D', 'A', 'Bm', 'G', 'D', 'A', 'G', 'A']
    lead = ['f#5:4 a5:4 d6:6 c#6:2', 'c#6:4 b5:2 a5:2 e5:8', 'd5:4 f#5:4 b5:6 a5:2', 'g5:4 b5:4 d6:8',
            'd6:4 c#6:2 b5:2 a5:4 f#5:4', 'e5:4 a5:4 c#6:8', 'b5:4 a5:2 g5:2 d6:4 b5:4', 'a5:12 a4:4']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), 'ipad ' + nn(60 + chord(ch)[0]) + ':16', arp_bar(ch))
    s.mark_loop()
    for ch, ld in zip(p, lead):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_bar(ch))
    for ch in p:
        s.bar(funk_bass(ch), arp_rhythm(ch, 5), arp_bar(ch))
    return s

def song_shop():
    s = Song('shop', 6)
    p = ['F', 'Dm', 'Bb', 'C', 'F', 'Dm', 'Gm', 'C']
    s.mark_loop()
    lead = ['a5:3 r:1 c6:2 a5:2 f5:4 r:4', 'd5:2 f5:2 a5:4 r:8', 'bb5:3 r:1 a5:2 g5:2 f5:4 d5:4', 'e5:8 g5:4 r:4',
            'c6:2 a5:2 f5:2 a5:2 c6:4 r:4', 'a5:2 f5:2 d5:2 f5:2 a5:8', 'g5:2 a5:2 bb5:2 d6:2 c6:4 bb5:4', 'g5:4 e5:4 c5:8']
    for ch, ld in zip(p, lead):
        s.bar('ibass ' + nn(36 + chord(ch)[0]) + ':4 ' + nn(43 + chord(ch)[0]) + ' ' + nn(36 + chord(ch)[0]) + ' ' + nn(43 + chord(ch)[0]),
              'itri ' + ld, 'ikick c4:4 ihat c4 isnare c4 ihat c4')
    return s

music.SONGS = [song_title, song_stage1, song_stage2, song_boss, song_clear, song_over, song_end, song_shop]

def music_asm():
    return music.music_asm()

if __name__ == '__main__':
    a, t, n = music_asm()
    print('patterns', n, 'bytes', t)
