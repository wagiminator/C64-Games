# build a TAP (v1) image: KERNAL-format boot file + turbo block
import sys, struct
S, M, L = 0x30, 0x42, 0x56          # KERNAL short / medium / long pulses
T0, T1 = 0x1a, 0x2c                 # turbo: 208 / 352 cycles

def kbyte(b):
    out = [L, M]
    ones = 0
    for i in range(8):
        bit = (b >> i) & 1
        ones += bit
        out += [M, S] if bit else [S, M]
    chk = 1 if ones % 2 == 0 else 0  # odd parity
    out += [M, S] if chk else [S, M]
    return out

def kblock(payload, lead, repeat_lead=79):
    out = []
    for copy in (0, 1):
        out += [S] * (lead if copy == 0 else repeat_lead)
        cnt = range(0x89, 0x80, -1) if copy == 0 else range(0x09, 0x00, -1)
        for c in cnt: out += kbyte(c)
        x = 0
        for b in payload:
            out += kbyte(b); x ^= b
        out += kbyte(x)
        out += [L, S]                # end of data marker
    out += [S] * 78
    return out

def kernal_file(prg, name, ftype=1):
    start = prg[0] | prg[1] << 8
    data = prg[2:]
    end = start + len(data)
    hdr = bytes([ftype, start & 255, start >> 8, end & 255, end >> 8])
    nm = name.upper().encode('ascii')[:16].ljust(16, b' ')
    hdr += nm
    hdr = hdr.ljust(192, b' ')
    return kblock(hdr, 12000) + kblock(data, 5376)

def tbyte(b):
    return [T1 if (b >> (7 - i)) & 1 else T0 for i in range(8)]

def turbo_block(prg):
    addr = prg[0] | prg[1] << 8
    data = prg[2:]
    out = [S] * 4000                 # spacer after KERNAL part
    for i in range(1200): out += tbyte(0x40)
    out += tbyte(0x5a)
    for b in (addr & 255, addr >> 8, len(data) & 255, len(data) >> 8): out += tbyte(b)
    x = 0
    for b in data:
        out += tbyte(b); x ^= b
    out += tbyte(x)
    out += [T0] * 200
    return out

def build(boot, blob, name, out):
    pulses = kernal_file(boot, name) + turbo_block(blob)
    body = bytes(pulses)
    hdr = b'C64-TAPE-RAW' + bytes([1, 0, 0, 0]) + struct.pack('<I', len(body))
    open(out, 'wb').write(hdr + body)
    secs = sum(pulses) * 8 / 985248
    print(out, len(body), 'pulses, %.1f s total' % secs)

if __name__ == '__main__':
    build(open(sys.argv[1], 'rb').read(), open(sys.argv[2], 'rb').read(), sys.argv[3], sys.argv[4])
