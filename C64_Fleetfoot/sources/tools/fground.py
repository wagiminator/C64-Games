# FLEETFOOT - ground characters, screen map and the stripe speedcode
import fgeo as G

def build():
    soft = G.soft_cells()
    chars = []            # list of (plain8, stripe8)
    ids = {}
    scr = [[0] * 40 for _ in range(25)]
    softinfo = {}
    animated = []         # (char, is_soft)
    # char 0: blank (plain ground of the sky never uses it); reserve 0 = empty
    chars.append((bytes(8), bytes(8)))
    # soft cells first (unique), row by row
    for r in G.SOFT_ROWS:
        c0, c1 = soft[r]
        softinfo[r] = (c0, c1, len(chars))
        for cx in range(c0, c1 + 1):
            p = bytes(G.mc_byte(cx, r * 8 + l, 0) for l in range(8))
            s = bytes(G.mc_byte(cx, r * 8 + l, 1) for l in range(8))
            scr[r][cx] = len(chars)
            animated.append((len(chars), True, r))
            chars.append((p, s))
    for r in range(G.ROW0, 25):
        for cx in range(40):
            if r in softinfo and softinfo[r][0] <= cx <= softinfo[r][1]:
                continue
            p = bytes(G.mc_byte(cx, r * 8 + l, 0) for l in range(8))
            s = bytes(G.mc_byte(cx, r * 8 + l, 1) for l in range(8))
            # stripes only matter on lines >= STRIPE_TOP
            s = bytes(s[l] if r * 8 + l >= G.STRIPE_TOP else p[l] for l in range(8))
            key = (r, p, s) if p != s else (p, p)
            if key not in ids:
                ids[key] = len(chars)
                if p != s:
                    animated.append((len(chars), False, r))
                chars.append((p, s))
            scr[r][cx] = ids[key]
    return chars, scr, softinfo, animated

def speedcode(chars, animated, csbase, stbase, srclabel):
    """assembler source: restore soft chars and set stripes. st table at stbase holds 0/1 per line (y-72)."""
    src = []          # (plain, stripe) pairs for lda abs,y
    out = ['stripe_code']
    byrow = {}
    for c, soft, r in animated:
        byrow.setdefault(r, []).append((c, soft))
    cyc = 0
    for r in sorted(byrow):
        for l in range(8):
            y = r * 8 + l
            imm = []
            tab = []
            for c, soft in byrow[r]:
                p, s = chars[c][0][l], chars[c][1][l]
                if y < G.STRIPE_TOP:
                    s = p
                if p == s:
                    if soft:
                        imm.append((p, c))
                else:
                    tab.append((p, s, c))
            if tab:
                out.append('        ldy %s+%d' % (stbase, y - G.HY)); cyc += 4
                for p, s, c in tab:
                    k = len(src)
                    src.append((p, s))
                    out.append('        lda %s+%d,y' % (srclabel, 2 * k))
                    out.append('        sta $%04x' % (csbase + c * 8 + l)); cyc += 9
            last = None
            for p, c in sorted(imm):
                if p != last:
                    out.append('        lda #$%02x' % p); cyc += 2
                    last = p
                out.append('        sta $%04x' % (csbase + c * 8 + l)); cyc += 4
    out.append('        rts')
    data = []
    for p, s in src:
        data += [p, s]
    return out, data, cyc
