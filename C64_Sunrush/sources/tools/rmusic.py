# SUNRUSH - original compositions (uses the ZYRON music compiler)
import music
import re
from music import Song, bass_bar, arp_bar, arp_rhythm, DRUMS, nn, chord, sweep

def down(s):
    """one octave lower: the melodies sit in octave 4-5, not 5-6 (too shrill on the SID)"""
    return re.sub(r'\b([a-g](?:#|b)?)(\d)(?=:)', lambda m: m.group(1) + str(int(m.group(2)) - 1), s)

def L(s):
    return 'ilead ' + down(s)

def song_title():           # sunny synth-pop opener in E major
    s = Song('title', 5)
    p = ['E', 'C#m', 'A', 'B', 'E', 'C#m', 'F#m', 'B']
    lead = ['g#5:2 b5:2 e6:4 d#6:2 b5:2 g#5:4', 'c#6:4 b5:2 g#5:2 e5:4 g#5:4', 'a5:2 c#6:2 e6:4 c#6:2 a5:2 e5:4',
            'f#5:4 a5:2 b5:2 d#6:8', 'e6:2 d#6:2 b5:2 g#5:2 b5:4 e6:4', 'c#6:4 e6:2 c#6:2 g#5:8',
            'a5:2 b5:2 c#6:2 a5:2 f#5:4 a5:4', 'b5:8 d#6:4 f#6:4']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), 'r:16', arp_bar(ch, 4))
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'eighth'), L(ld), DRUMS['half'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'drive'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_breeze():          # station 1: laid-back latin groove in A minor
    s = Song('breeze', 5)
    p = ['Am', 'D', 'G', 'C', 'Am', 'D', 'F', 'E']
    lead = ['e5:3 a5:3 c6:2 b5:4 a5:4', 'f#5:3 a5:3 d6:2 c6:4 a5:4', 'g5:2 b5:2 d6:4 c6:2 b5:2 g5:4',
            'e5:6 g5:2 c6:8', 'a5:2 c6:2 e6:3 d6:1 c6:4 a5:4', 'd6:3 c6:1 a5:4 f#5:4 a5:4',
            'f5:2 a5:2 c6:2 f6:2 e6:4 c6:4', 'b5:6 g#5:2 e5:8']
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'gallop'), L(ld), DRUMS['rock2'] if i % 4 == 3 else DRUMS['rock'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'eighth'), 'isaw ' + down(ld), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    return s

def song_highway():         # station 2: driving synth rock in D minor
    s = Song('highway', 4)
    p = ['Dm', 'Bb', 'C', 'Dm', 'Dm', 'Bb', 'Gm', 'A']
    riff = ['d5:2 f5:2 a5:2 d6:2 c6:2 a5:2 f5:4', 'bb5:4 a5:2 f5:2 d5:4 f5:4', 'c6:2 e6:2 g5:2 c6:2 bb5:4 g5:4',
            'a5:8 d6:8', 'f6:2 e6:2 d6:2 a5:2 f5:4 a5:4', 'bb5:2 d6:2 f6:4 e6:2 d6:2 bb5:4',
            'g5:2 bb5:2 d6:2 g6:2 f6:4 d6:4', 'c#6:8 e6:4 a5:4']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'drive'), 'r:16', DRUMS['fast'])
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, riff)):
        s.bar(bass_bar(ch, 'drive'), 'isaw ' + down(ld), DRUMS['fast'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'drive'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_skies():           # station 3: bright pop in C major
    s = Song('skies', 5)
    p = ['C', 'Am', 'F', 'G', 'C', 'Em', 'F', 'G']
    lead = ['e5:2 g5:2 c6:2 e6:2 d6:4 c6:4', 'a5:4 c6:2 e6:2 d6:4 c6:4', 'a5:2 c6:2 f6:4 e6:2 c6:2 a5:4',
            'g5:4 b5:4 d6:8', 'c6:2 d6:2 e6:2 g6:2 e6:4 c6:4', 'b5:4 g5:2 e5:2 g5:4 b5:4',
            'c6:2 a5:2 f5:2 a5:2 c6:4 f6:4', 'd6:8 b5:4 g5:4']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'eighth'), 'r:16', arp_bar(ch, 4))
    s.mark_loop()
    for i, (ch, ld) in enumerate(zip(p, lead)):
        s.bar(bass_bar(ch, 'eighth'), L(ld), DRUMS['half'] if i != 7 else DRUMS['fill'])
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 4), DRUMS['rock'] if i != 7 else DRUMS['fill'])
    return s

def song_goal():            # finale / ending anthem in G major
    s = Song('goal', 6)
    p = ['G', 'D', 'Em', 'C', 'G', 'D', 'C', 'D']
    lead = ['d5:4 g5:4 b5:6 a5:2', 'a5:4 f#5:2 d5:2 a5:8', 'b5:4 g5:4 e5:6 g5:2', 'e5:4 g5:4 c6:8',
            'd6:4 b5:2 g5:2 d6:4 g6:4', 'f#6:4 e6:2 d6:2 a5:8', 'e6:4 c6:2 g5:2 e6:4 g6:4', 'f#6:12 d6:4']
    for ch in p[:4]:
        s.bar(bass_bar(ch, 'slow'), 'ipad ' + nn(60 + chord(ch)[0]) + ':16', arp_bar(ch))
    s.mark_loop()
    for ch, ld in zip(p, lead):
        s.bar(bass_bar(ch, 'eighth'), L(ld), arp_bar(ch))
    for i, ch in enumerate(p):
        s.bar(bass_bar(ch, 'gallop'), arp_rhythm(ch, 4), DRUMS['half'] if i != 7 else DRUMS['fill'])
    return s

def song_over():
    s = Song('over', 7, loop=False)
    s.bar('ibass a1:8 f1:8', 'ilead e5:4 c5:4 a4:4 e4:4', 'iarpmin a3:8 iarpmaj f3:8')
    s.bar('ibass d2:8 e2:8', 'ilead f4:6 e4:2 e4:8', 'iarpmin d4:8 iarpmaj e3:8')
    s.bar('r:16', 'r:16', 'r:16')
    return s

def song_check():           # short checkpoint jingle
    s = Song('check', 4, loop=False)
    s.bar('ibass c3:4 e3:4 g3:4 c4:4', 'ilead c5:2 e5:2 g5:2 c6:4 g5:2 c6:4', 'iarpmaj c4:16')
    s.bar('r:16', 'r:16', 'r:16')
    return s

music.SONGS = [song_title, song_breeze, song_highway, song_skies, song_goal, song_over, song_check]

music.SFX.append(('beep', 3, 0x00, 0x90, 0x08, [(0x11, 50)] * 6 + [(0x10, 50)]))
music.SFX.append(('go', 4, 0x00, 0xa0, 0x08, [(0x11, 100)] * 14 + [(0x10, 100)]))
music.SFX.append(('crash', 6, 0x0a, 0xfb, 0x08, [(0x81, 40), (0x81, 30)] + sweep(0x81, 25, 2, 40) + [(0x80, 2)]))
music.SFX.append(('bump', 4, 0x00, 0xb0, 0x08, [(0x81, 20), (0x81, 14), (0x41, 6), (0x80, 6)]))
music.SFX.append(('screech', 2, 0x00, 0xa0, 0x02, [(0x41, 110 + (i % 3) * 6) for i in range(10)] + [(0x40, 100)]))
music.SFX.append(('timeup', 5, 0x00, 0xa0, 0x08, sweep(0x21, 60, 20, 30) + [(0x20, 20)]))
music.SFX.append(('extend', 5, 0x00, 0xa0, 0x08, [(0x11, f) for f in (60, 60, 80, 80, 100, 100, 120, 120, 160, 160)] + [(0x10, 160)]))
music.SFX.append(('tick', 2, 0x00, 0x60, 0x08, [(0x11, 90), (0x10, 90)]))
music.SFXID = {s[0]: i for i, s in enumerate(music.SFX)}

def music_asm():
    return music.music_asm()

if __name__ == '__main__':
    a, t, n = music_asm()
    print('patterns', n, 'bytes', t)
