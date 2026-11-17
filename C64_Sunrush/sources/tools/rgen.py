# SUNRUSH - build all generated data
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import gfx, rgfx, rtrack, rmusic

OUT = sys.argv[1] if len(sys.argv) > 1 else '../build'
os.makedirs(OUT, exist_ok=True)

CH = dict(CH_QUAD=64, CH_BAR=80, CH_BARL=85, CH_BARR=86, CH_SOLID=87, CH_CAR=88, CH_SCN=128)
NL = rgfx.NL
HOR = rgfx.HORIZON

def bl(label, data, per=16):
    out = [label]
    data = list(data)
    for i in range(0, len(data), per):
        out.append("  .byte " + ",".join("$%02x" % (b & 255) for b in data[i:i + per]))
    if not data: out.append("  .byte 0")
    return out

# ------------------------------------------------ charset 1 (font, logo quads, HUD)
cs1 = bytearray(2048)
def put(ch, d): cs1[ch * 8:ch * 8 + 8] = d
for ch, rows in gfx.FONT.items():
    put(gfx.screencode(ch), bytes(gfx.glyph_bytes(rows)))
for q in range(16):
    d = bytearray(8)
    for y in range(8):
        v = 0
        if y < 4:
            if q & 1: v |= 0xF0
            if q & 2: v |= 0x0F
        else:
            if q & 4: v |= 0xF0
            if q & 8: v |= 0x0F
        d[y] = v
    put(CH['CH_QUAD'] + q, d)
for n in range(5):
    d = bytearray(8)
    for y in range(8):
        if y in (0, 7): v = 0xFF
        elif y in (1, 6): v = 0
        else: v = (0xFF << (8 - n * 2)) & 0xFF
        d[y] = v
    put(CH['CH_BAR'] + n, d)
put(CH['CH_BARL'], bytes([0x07, 0x08, 0x10, 0x10, 0x10, 0x10, 0x08, 0x07]))
put(CH['CH_BARR'], bytes([0xE0, 0x10, 0x08, 0x08, 0x08, 0x08, 0x10, 0xE0]))
put(CH['CH_SOLID'], bytes([0xff] * 8))
put(CH['CH_CAR'], bytes([0x00, 0x18, 0x3c, 0x7e, 0xff, 0x66, 0x00, 0x00]))   # progress marker
open(os.path.join(OUT, 'charset1.bin'), 'wb').write(bytes(cs1))

# ------------------------------------------------ charset 2 (road template)
rchars, trows = rgfx.road_template()
cs2 = bytearray(2048)
for i, d in enumerate(rchars): cs2[i * 8:i * 8 + 8] = d
open(os.path.join(OUT, 'charset2.bin'), 'wb').write(bytes(cs2[:len(rchars) * 8]))

# ------------------------------------------------ sprites
spr, syms = rgfx.build_sprites(0x60)
open(os.path.join(OUT, 'sprites.bin'), 'wb').write(bytes(spr))

# ------------------------------------------------ logo
bm = rgfx.logo_bitmap()
LOGOROW, LOGOROWS = 1, 7
logo = []
for r in range(LOGOROWS):
    for c in range(40):
        q = 0
        if bm[r * 2][c * 2]: q |= 1
        if bm[r * 2][c * 2 + 1]: q |= 2
        if bm[r * 2 + 1][c * 2]: q |= 4
        if bm[r * 2 + 1][c * 2 + 1]: q |= 8
        logo.append(CH['CH_QUAD'] + q if q else 32)
logo += [32] * (400 - len(logo))

L = ["; generated tables"]
rows = [i * 40 for i in range(25)]
L += bl("rowlo", [r & 255 for r in rows])
L += bl("rowhiA", [(0x5000 + r) >> 8 for r in rows])
L += bl("rowhiB", [(0x5400 + r) >> 8 for r in rows])
L += bl("rowhiC", [(0xd800 + r) >> 8 for r in rows])
L += bl("logo_chars", logo)
L += bl("logo_grad", [7, 7, 8, 8, 10, 10, 2, 2, 10, 10, 8, 8, 7, 7, 1, 1])
L += bl("sintab", [int(round(127 * math.sin(i * 2 * math.pi / 256))) & 255 for i in range(256)])
fl, fh = [], []
for n in range(96):
    f = 440.0 * 2 ** ((n - 57) / 12.0)
    r = min(65535, int(round(f * 16777216 / 985248)))
    fl.append(r & 255); fh.append(r >> 8)
L += bl("freq_lo", fl)
L += bl("freq_hi", fh)

# ---- road template (15 rows, sheared rows with 3 variants of TW chars each)
SEG3_ROWS = 8                       # rows from here on go to segment 3
L3 = ["; road template rows (segment 3)"]
for r, row in enumerate(trows):
    (L if r < SEG3_ROWS else L3).extend(bl("tplr%d" % r, row))
L3.append("tplrow_lo .byte " + ", ".join("<tplr%d" % r for r in range(15)))
L3.append("tplrow_hi .byte " + ", ".join(">tplr%d" % r for r in range(15)))
# shear kinds: 0 none, 1/2 = +/-16, 3/4 = +/-8 -> fine scroll correction 2*shift (hires px) per line
shk = [rgfx.shear_shift(0, 1), rgfx.shear_shift(16, 1), rgfx.shear_shift(16, -1), rgfx.shear_shift(8, 1), rgfx.shear_shift(8, -1)]
L3 += bl("shtab", [(2 * x) & 255 for k in shk for x in k])
L3 += bl("srowk", [{16: 8, 8: 24, 0: 0}[S] for S in rgfx.SROW])      # kind*8 of the + variant
L3 += bl("srowt", [S // 2 + 1 for S in rgfx.SROW])                  # |delta| to switch a variant on
L3 += bl("srowh", [max(1, S // 2 - 2) for S in rgfx.SROW])          # |delta| to keep it (hysteresis)

# ---- depth / perspective tables
zs, inv = rgfx.depth_tables()
L += bl("zs_lo", [z & 255 for z in zs])
L += bl("zs_hi", [z >> 8 for z in zs])
L += bl("inv_line", inv)
sc8 = [min(255, int(round(rgfx.scale(i) * 256))) for i in range(NL)]
L += bl("sc8", sc8)
# size class per line: target width 48 * s (hires px)
def cls_of(w):
    for k, lim in enumerate((8, 12, 16.5, 21.5, 31, 43)):
        if w < lim: return k
    return 6
szc = [cls_of(48 * rgfx.scale(i)) for i in range(NL)]
L += bl("szcls", szc)
# for each size class: frame offset, expansion flag, sprite height
L += bl("cls_frame", [0, 1, 2, 3, 4, 3, 4])
L += bl("cls_exp", [0, 0, 0, 0, 0, 1, 1])
L += bl("cls_half", [12, 12, 12, 12, 12, 24, 24])   # half width (hires) for centring
L += bl("cls_h", [21, 21, 21, 21, 21, 42, 42])

# ---- themes
T = rtrack.THEMES
def col8(v): return v & 15
L += bl("th_sky", [t['sky'] for t in T])
L += bl("th_glow", [g for t in T for g in t['glow']])
L += bl("th_s22", [t['s22'] for t in T])
L += bl("th_s23", [t['s23'] for t in T])
L += bl("th_srow", [8 | (c & 7) for t in T for c in t['srow']])
L += bl("th_grass", [c for t in T for c in t['grass']])
L += bl("th_kerb", [c for t in T for c in t['kerb']])
L += bl("th_road", [c for t in T for c in t['road']])
L += bl("th_lane", [8 | (t['lane'] & 7) for t in T])
L += bl("th_scn", [rgfx.SCENERY_KINDS.index(t['scn']) for t in T])
OBJCOL = dict(palm=5, bush=5, cactus=5, rock=9, pine=5, snowpine=5, house=10, tower=11, lamp=11, windmill=8,
              flowers=10, signl=7, signr=7, gate=2, bollard=8, sedan=2, van=6, truck=14)
L += bl("th_obj", [syms[o] for t in T for o in t['objs']])
def objcol(t, o):
    c = OBJCOL[o]
    if o != 'palm' and c in t['grass']:      # would vanish against the grass stripes
        c = {5: 11, 13: 11, 9: 8, 10: 8, 8: 9, 11: 12}.get(c, 0)
    return c
L += bl("th_objc", [objcol(t, o) for t in T for o in t['objs']])
L += bl("th_spacing", [t['spacing'] // 4 for t in T])
L += bl("th_traffic", [syms[t['traffic'][k % len(t['traffic'])]] for t in T for k in range(4)])
L += bl("th_density", [t['density'] for t in T])
for k, t in enumerate(T):
    L.append("thname%d .null \"%s\"" % (k, t['name']))
L.append("th_name_lo .byte " + ",".join("<thname%d" % k for k in range(len(T))))
L.append("th_name_hi .byte " + ",".join(">thname%d" % k for k in range(len(T))))
L += bl("traffic_cols", [2, 6, 5, 7, 14, 10, 3, 15])

# ---- scenery sets
for k, kind in enumerate(rgfx.SCENERY_KINDS):
    ch, mp = rgfx.scenery_set(kind)
    L += bl("scnch%d" % k, b''.join(ch))
    L += bl("scnmap%d" % k, [v + CH['CH_SCN'] for row in mp for v in row])
    L.append("SCNN%d = %d" % (k, len(ch)))
L.append("scn_ch_lo .byte " + ",".join("<scnch%d" % k for k in range(5)))
L.append("scn_ch_hi .byte " + ",".join(">scnch%d" % k for k in range(5)))
L.append("scn_map_lo .byte " + ",".join("<scnmap%d" % k for k in range(5)))
L.append("scn_map_hi .byte " + ",".join(">scnmap%d" % k for k in range(5)))
L.append("scn_n .byte " + ",".join("SCNN%d" % k for k in range(5)))

# ---- courses: per segment end position (16 bit) and curve
for s in range(10):
    segs = rtrack.course(s)
    ends = []; p = 0
    for ln, c in segs:
        p += ln; ends.append((min(p, 65535), c))
    L += bl("crs%d_lo" % s, [e & 255 for e, c in ends])
    L += bl("crs%d_hi" % s, [e >> 8 for e, c in ends])
    L += bl("crs%d_c" % s, [c & 255 for e, c in ends])
for part in ('lo', 'hi', 'c'):
    L.append("crs_%s_lo .byte " % part + ",".join("<crs%d_%s" % (s, part) for s in range(10)))
    L.append("crs_%s_hi .byte " % part + ",".join(">crs%d_%s" % (s, part) for s in range(10)))
legtab = []
for leg in rtrack.LEGS: legtab += leg + [255] * (4 - len(leg))
L += bl("leg_stage", legtab)
qs = [n * n // 4 for n in range(512)]
L2 = ["; tables placed in the free part of the road charset"]
L2 += bl("qsq_lo", [q & 255 for q in qs])
L2 += bl("qsq_hi", [q >> 8 for q in qs])
open(os.path.join(OUT, 'gen_tables2.asm'), 'w').write("\n".join(L2) + "\n")
open(os.path.join(OUT, 'gen_data.asm'), 'w').write("\n".join(L) + "\n")
open(os.path.join(OUT, 'gen_tpl3.asm'), 'w').write("\n".join(L3) + "\n")

# ------------------------------------------------ line program + commit (generated code)
P = ["; generated raster line program (lines 123..250) and commit routine",
     "lineprog"]
for k in range(8):
    R = 123 + k
    P += ["lpG%d   ldx #0" % k, "        lda #%d" % (R - 1), "-       cmp $d012", "        bcs -", "        stx $d021"]
# Every road line: "ldy lpF+1 / ldx gtab,y" (the $d016 value carries the stripe phase in bit 6,
# the colour tables have 256 entries), poll, then the
# time critical writes ($d016, $d021) and the kerb/asphalt colours. The sprite registers of
# slots 4-7 are switched from the far objects to the player car between lines 178 and 206,
# one store per line (two in the delay slot before a badline) so that no line overruns.
CARZONE = 206                       # lines >= this: sprites 4-7 (car) are fetched at line start
UPPER_END = HOR + 46                # objects in slots 4-7 end above this line (see UPPER_MAX)
HOOKS = []                          # (label, target) in execution order
for k in range(4):
    HOOKS += [("lpHpA%d" % k, "SCRA+$3fc+%d" % k), ("lpHpB%d" % k, "SCRB+$3fc+%d" % k)]
for k in range(4):
    HOOKS += [("lpHc%d" % k, "$d%03x" % (0x02b + k))]
for k in range(4):
    HOOKS += [("lpHx%d" % k, "$d%03x" % (0x008 + 2 * k))]
HOOKS += [("lpHm", "$d010"), ("lpHxx", "$d01d"), ("lpHyy", "$d017"), ("lpHe", "$d015")]
for k in range(4):
    HOOKS += [("lpHy%d" % k, "$d%03x" % (0x009 + 2 * k))]
HOOKSRC = dict([("lpHpA%d" % k, "hk_p+%d" % k) for k in range(4)] + [("lpHpB%d" % k, "hk_p+%d" % k) for k in range(4)] +
               [("lpHc%d" % k, "hk_c+%d" % k) for k in range(4)] + [("lpHx%d" % k, "hk_x+%d" % k) for k in range(4)] +
               [("lpHy%d" % k, "hk_y+%d" % k) for k in range(4)] +
               [("lpHm", "hk_m"), ("lpHxx", "hk_xx"), ("lpHyy", "hk_yy"), ("lpHe", "hk_e")])
hookq = list(HOOKS)
def hook(n):
    out = []
    for _ in range(n):
        if hookq:
            lab, tgt = hookq.pop(0)
            out += ["%-7s lda #0" % lab, "        sta %s" % tgt]
        else:
            out += ["        nop", "        nop", "        nop"]     # 6 cycles like lda #/sta abs
    return out
def isbad(R): return R % 8 == 3
PHASE = []                          # lines whose stripe phase is put into stF by the main loop
i = 0
while i < NL:
    R = HOR + i
    if isbad(R) and i + 1 < NL:
        # badline: the CPU is halted from cycle 12 to ~55 of line R. The values for line R are
        # written at the end of line R-1 (after its visible part) with a fixed delay behind the
        # poll of line R-1; the values for line R+1 follow right after the halt.
        PHASE.extend([i, i + 1])
        P += ["        ldy lpF%d+1" % i, "        ldx gtab,y"]
        if i == 0:
            P += ["        nop"] * 18                     # after the glow line block (poll + 4 cycles)
            P += ["lpD18   lda #$42", "        sta $d018"]
        elif R - 1 >= CARZONE:
            P += ["        nop"] * 3                      # poll exit ~cycle 11 behind the car sprite DMA
        elif R - 1 >= UPPER_END:
            P += hook(2)                                 # 12 cycles: two hook stores
        else:
            P += ["        nop"] * 6                      # write at poll exit + 52 cycles
        P += ["lpF%d   lda #$10" % i, "        sta $d016", "        stx $d021",
              "        ldy lpF%d+1" % (i + 1), "        ldx gtab,y",
              "lpF%d   lda #$10" % (i + 1), "        sta $d016", "        stx $d021",
              "        lda ktab,y", "        sta $d022", "        lda rtab,y", "        sta $d023"]
        i += 2
        continue
    hk = UPPER_END <= R <= CARZONE and not isbad(R + 1) and not isbad(R - 1) and hookq
    if hk:      # short preparation: stripe phase from bit 6 of the $d016 value (main loop)
        PHASE.append(i)
        P += ["        ldy lpF%d+1" % i, "        ldx gtab,y"]
    else:       # the line program computes the stripe phase itself while it has time
        P += ["        lda #<%d" % zs[i], "        adc lposl", "        and #$40", "        tay", "        ldx gtab,y"]
    P += ["        lda #%d" % (R - 1), "-       cmp $d012", "        bcs -",
          "lpF%d   lda #$10" % i, "        sta $d016", "        stx $d021",
          "        lda ktab,y", "        sta $d022", "        lda rtab,y", "        sta $d023"]
    if hk:
        P += hook(1)
    i += 1
assert not hookq, hookq
P += ["        rts", "", "commit"]
for i in range(NL):
    P += ["        lda stF+%d" % i, "        sta lpF%d+1" % i]
P += ["        lda st_d18", "        sta lpD18+1", "        lda posl", "        sta lposl"]
for lab, tgt in HOOKS:
    P += ["        lda %s" % HOOKSRC[lab], "        sta %s+1" % lab]
P += ["        rts", "",
      "; stripe phase (bit 6) of the lines with a short preparation in the line program",
      "phase_fix"]
for i in PHASE:
    P += ["        lda #<%d" % zs[i], "        clc", "        adc posl", "        and #$40", "        ora stF+%d" % i, "        sta stF+%d" % i]
P += ["        rts", "",
      "; set the 8 glow colours (A = theme * 8 in X)",
      "set_glow"]
for k in range(8):
    P += ["        lda th_glow+%d,x" % k, "        sta lpG%d+1" % k]
P += ["        rts"]
open(os.path.join(OUT, 'lineprog.asm'), 'w').write("\n".join(P) + "\n")

# ------------------------------------------------ constants
C = ["; generated constants"]
for k, v in syms.items():
    C.append("SPR_%s = $%02x" % (k.upper(), v))
for k, v in CH.items():
    C.append("%s = %d" % (k, v))
C += ["LOGOROW = %d" % LOGOROW, "LOGOROWS = %d" % LOGOROWS, "NL = %d" % NL, "HOR = %d" % HOR,
      "TW = %d" % rgfx.TW, "TMARGIN = %d" % rgfx.M, "NROADCH = %d" % len(rchars),
      "STAGE_LEN = %d" % rtrack.STAGE_LEN, "ZNEAR = %d" % zs[NL - 1], "ZFAR = %d" % zs[0],
      "SPR_END = $%02x" % (0x60 + len(spr) // 64)]
open(os.path.join(OUT, 'gen_consts.inc'), 'w').write("\n".join(C) + "\n")

masm, mbytes, npat = rmusic.music_asm()
open(os.path.join(OUT, 'music.asm'), 'w').write(masm.replace("SFX_", "SFXD_") if False else masm)
print("road chars", len(rchars), "sprites", len(spr) // 64, "music", mbytes)
