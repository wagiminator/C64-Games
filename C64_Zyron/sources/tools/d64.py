# minimal D64 tools: read chains, build image with custom interleave
SPT = [0] + [21]*17 + [19]*7 + [18]*6 + [17]*5
def offs(t, s):
    o = 0
    for tt in range(1, t): o += SPT[tt]
    return (o + s) * 256
def chain(img, t, s):
    out = []
    while t:
        out.append((t, s))
        b = img[offs(t, s):offs(t, s) + 256]
        t, s = b[0], b[1]
    return out

def petscii(name):
    return bytes(ord(c.upper()) if c != ' ' else 0x20 for c in name)

def build(files, diskname, diskid, interleave=10, dir_interleave=3):
    """files: list of (name, data_bytes_with_loadaddr, interleave or None)"""
    img = bytearray(174848)
    used = {t: set() for t in range(1, 36)}
    dirents = []
    # allocate tracks: start at 17 going down, then 19 up (like DOS)
    order = list(range(17, 0, -1)) + list(range(19, 36))
    def alloc_file(data, il):
        blocks = [data[i:i + 254] for i in range(0, len(data), 254)] or [b'']
        secs = []
        ti = 0; t = order[ti]; s = 0
        for _ in blocks:
            # find free sector on track t starting at s
            while True:
                found = None
                for k in range(SPT[t]):
                    ss = (s + k) % SPT[t]
                    if ss not in used[t]: found = ss; break
                if found is not None: break
                ti += 1; t = order[ti]; s = 0
            used[t].add(found); secs.append((t, found))
            s = (found + il) % SPT[t]
        for i, (blk, (t, s)) in enumerate(zip(blocks, secs)):
            o = offs(t, s)
            if i + 1 < len(secs):
                img[o] = secs[i + 1][0]; img[o + 1] = secs[i + 1][1]
            else:
                img[o] = 0; img[o + 1] = len(blk) + 1
            img[o + 2:o + 2 + len(blk)] = blk
        return secs
    for name, data, il in files:
        secs = alloc_file(data, il or interleave)
        dirents.append((name, secs[0], len(secs)))
    # directory sector 18/1
    d = bytearray(256)
    d[0] = 0; d[1] = 0xff
    for i, (name, (t, s), n) in enumerate(dirents):
        e = i * 32
        d[e + 2] = 0x82
        d[e + 3] = t; d[e + 4] = s
        nm = petscii(name)[:16]
        d[e + 5:e + 21] = nm + b'\xa0' * (16 - len(nm))
        d[e + 30] = n & 255; d[e + 31] = n >> 8
    img[offs(18, 1):offs(18, 1) + 256] = d
    used[18].update({0, 1})
    # BAM
    b = bytearray(256)
    b[0] = 18; b[1] = 1; b[2] = 0x41; b[3] = 0
    for t in range(1, 36):
        free = [s for s in range(SPT[t]) if s not in used[t]]
        bits = 0
        for s in free: bits |= 1 << s
        b[4 * t] = len(free)
        b[4 * t + 1] = bits & 255; b[4 * t + 2] = (bits >> 8) & 255; b[4 * t + 3] = (bits >> 16) & 255
    nm = petscii(diskname)[:16]
    b[0x90:0xa0] = nm + b'\xa0' * (16 - len(nm))
    b[0xa0] = 0xa0; b[0xa1] = 0xa0
    b[0xa2:0xa4] = petscii(diskid)[:2]
    b[0xa4] = 0xa0; b[0xa5] = 0x32; b[0xa6] = 0x41
    b[0xa7:0xab] = b'\xa0' * 4
    img[offs(18, 0):offs(18, 0) + 256] = b
    return bytes(img)

if __name__ == '__main__':
    import sys
    img = open(sys.argv[1], 'rb').read()
    d = img[offs(18, 1):offs(18, 1) + 256]
    for i in range(8):
        e = i * 32
        if d[e + 2]:
            c = chain(img, d[e + 3], d[e + 4])
            print(d[e + 5:e + 21], len(c), c[:12])
