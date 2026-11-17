; =====================================================================
;  S U N R U S H  -  a pseudo 3D racing game for the Commodore 64
;  (tribute to the arcade racing classics)       assembler: 64tass
; =====================================================================
        .cpu "6502i"

        .enc "game"
        .cdef "@_", 0
        .cdef " ?", 32

CHARSET = $4000                 ; font, logo, HUD, scenery (sky part)
ROADCS  = $4800                 ; road template characters
SCRA    = $5000
SCRB    = $5400
SPRDATA = $5800
COLRAM  = $d800
gtab    = $c800                 ; colour tables (256 bytes each) indexed by the $d016 value,
ktab    = $c900                 ; bit 6 = stripe phase
rtab    = $ca00
RCCODE  = $e000                 ; generated row copy code (under the KERNAL)
D18A    = $40                   ; screen A + charset 1
D18B    = $50
D18RA   = $42                   ; screen A + road charset
D18RB   = $52

        .include "../build/gen_consts.inc"

        .weak
PROFILE = 0
        .endweak

ROADROW = 10                    ; first road character row (raster 131)
SCNROW  = 5                     ; scenery rows 5..9
CARY    = 206                   ; sprite Y of the player car (top row)
CARX    = 160                   ; sprite X of the left car half
UPPER_MAX = 44                  ; objects in slots 4-7 must end above line HOR+46 = 177 (see the line program)
NCAND   = 16
NTR     = 4                     ; traffic cars
VMAX    = 352                   ; top speed (1/16 units per frame) ~ 290 km/h
VGRASS  = 150

; ---------------------------------------------------------- zero page
        .virtual $02
tmp0    .byte ?
tmp1    .byte ?
tmp2    .byte ?
tmp3    .byte ?
tmp4    .byte ?
tmp5    .byte ?
tmp6    .byte ?
tmp7    .byte ?
ptr0    .word ?
ptr1    .word ?
ptr2    .word ?
ptr3    .word ?
frame   .byte ?
joy     .byte ?
joyprev .byte ?
joynew  .byte ?
rndseed .byte ?
rndseed2 .byte ?
pageptr .word ?
mptr    .word ?
iptr    .word ?
itmp0   .byte ?
irqtmp  .byte ?
; road projection
yl      .byte ?
ym      .byte ?
yh      .byte ?
dxl     .byte ?
dxh     .byte ?
dxs     .byte ?
cvl     .byte ?
cvh     .byte ?
nextb   .byte ?
segp    .byte ?
crsl    .word ?                 ; course pointers (end lo / end hi / curve)
crsh    .word ?
crsc    .word ?
lposl   .byte ?                 ; posl for the line program
mula    .byte ?
mulb    .byte ?
mulr    .word ?
c8l     .byte ?
c8h     .byte ?
c36l    .byte ?
c36m    .byte ?
c36h    .byte ?
        .endv

        .virtual $c000
; --- staging for the line program (written by the main loop)
stP     .fill NL
stF     .fill NL
st_d18  .byte ?
hk_y    .fill 4
hk_x    .fill 4
hk_p    .fill 4
hk_c    .fill 4
hk_m    .byte ?
hk_e    .byte ?
hk_xx   .byte ?
hk_yy   .byte ?
; first 8 sprites: staging (s8) and live (l8)
s8_y    .fill 8
s8_x    .fill 8
s8_p    .fill 8
s8_c    .fill 8
s8_m    .byte ?
s8_e    .byte ?
s8_xx   .byte ?
s8_yy   .byte ?
l8_y    .fill 8
l8_x    .fill 8
l8_p    .fill 8
l8_c    .fill 8
l8_m    .byte ?
l8_e    .byte ?
l8_xx   .byte ?
l8_yy   .byte ?
ready   .byte ?
dispscr .byte ?                 ; 0 = screen A shown, 1 = B
gamemode .byte ?
scn_fine .byte ?                ; live $d016 for the sky part
st_scnf .byte ?
skycol  .byte ?
scn22   .byte ?
scn23   .byte ?
; road projection results
WL      .fill 16
WH      .fill 16
rowxA   .fill 15                ; template offset drawn per screen row
rowxB   .fill 15
rowx    .fill 15                ; wanted offset
crow    .fill 15                ; coarse offset per row (signed)
rvar    .fill 15                ; template variant per row (0, 1 = +, 2 = -)
scnxA   .byte ?
scnxB   .byte ?
rc_lo   .fill 30
rc_hi   .fill 30
bnd_line .fill 6
bnd_cl  .fill 6
bnd_ch  .fill 6
nbnd    .byte ?
; --- game state
stage   .byte ?
leg     .byte ?
legpos  .byte ?
theme   .byte ?
posl    .byte ?
posh    .byte ?
posf    .byte ?
vl      .byte ?                 ; speed (1/16 units per frame), 16 bit
vh      .byte ?
pxl     .byte ?                 ; lateral position (hires px at the bottom), signed 16 bit
pxh     .byte ?
pseg    .byte ?                 ; segment of the player position
pcurve  .byte ?
scnpl   .byte ?                 ; scenery pan position (1/16 hires px), 16 bit
scnph   .byte ?
time_s  .byte ?                 ; BCD seconds
time_f  .byte ?
score   .fill 3
nextext .fill 3
lives   .byte ?
hudflag .byte ?
cheat   .byte ?
cheatidx .byte ?
startstage .byte ?
lastkey .byte ?
keytmp  .byte ?
station .byte ?
crash_t .byte ?
bump_t  .byte ?
cnt_t   .byte ?                 ; countdown
state   .byte ?                 ; 0 countdown, 1 race, 2 time up, 3 goal
msg_t   .byte ?
fps1    .byte ?
lastfr  .byte ?
dt      .byte ?
steer   .byte ?
sbounce .byte ?
dfrac   .byte ?                 ; fraction of the centrifugal drift
offroad .byte ?
forkmsg .byte ?
skipflag .byte ?
goalnum .byte ?
endwait .byte ?
lagf    .byte ?
kmh     .fill 3
bonus   .byte ?
spdacc  .byte ?
hsave   .byte ?
; --- traffic
tr_on   .fill NTR
tr_pl   .fill NTR
tr_ph   .fill NTR
tr_pf   .fill NTR
tr_x    .fill NTR               ; lateral position / 2 (signed)
tr_v    .fill NTR               ; speed (1/16 units per frame)
tr_s    .fill NTR               ; sprite base
tr_c    .fill NTR
tr_dz   .fill NTR               ; last dz/4 (for crossing test)
tr_hit  .fill NTR
; --- sprite candidates
nc      .byte ?
c_i     .fill NCAND
c_xl    .fill NCAND
c_xh    .fill NCAND
c_y     .fill NCAND
c_p     .fill NCAND
c_c     .fill NCAND
c_e     .fill NCAND
c_ord   .fill NCAND
ob_lastk .byte ?
ob_hitk .byte ?
; --- misc
hiscores .fill 5*6
txtbuf  .fill 40
bansave .fill 40
        .endv

; ---------------------------------------------------------- BASIC stub
        * = $0801
        .word (+), 2026
        .null $9e, format("%d", start)
+       .word 0

        * = $0810
start
        sei
        cld
        ldx #$ff
        txs
        lda #$35
        sta $01
        lda #$7f
        sta $dc0d
        sta $dd0d
        lda $dc0d
        lda $dd0d
        lda #0
        sta $d01a
        sta $d015
        lda #<nmi
        sta $fffa
        lda #>nmi
        sta $fffb
        lda #<nmi
        sta $fffc
        lda #>nmi
        sta $fffd
        lda #$ff
        sta $dc02
        lda #$00
        sta $dc03
        lda #$3f
        sta $dd02
        lda $dd00
        and #$fc
        ora #$02                ; VIC bank 1 ($4000-$7fff)
        sta $dd00
        lda #0
        sta $d020
        sta $d021
        sta $d01b
        sta $d01d
        sta $d017
        sta $d025
        lda #15
        sta $d026
        lda #$ff
        sta $d01c
        ; PAL / NTSC: highest raster line low byte ($37 PAL, $06/$05 NTSC)
-       lda $d011
        bpl -
        lda #0
        sta tmp0
-       lda $d012
        cmp tmp0
        bcc +
        sta tmp0
+       lda $d011
        bmi -
        ldx #49
        lda tmp0
        cmp #$20
        bcs +
        ldx #59
+       stx fps1
        jsr sid_init
        jsr gen_rowcopy
        jsr init_hiscores
        lda #0
        sta DBGJOY
        sta DBGAI
        sta cheat
        sta startstage
        sta station
        sta gamemode
        lda #$5a
        sta rndseed
        lda #$c3
        sta rndseed2
        jmp title_screen

nmi     rti

        .include "irq.asm"
        .include "road.asm"
        .include "objects.asm"
        .include "player.asm"
        .include "game.asm"
        .include "util.asm"
        .include "../build/lineprog.asm"
        .include "../build/gen_tables2.asm"
code1_end
        .cerror * > $4000, "code segment 1 overflow ", *

        * = CHARSET
        .binary "../build/charset1.bin"
        * = ROADCS
        .binary "../build/charset2.bin"
        .cerror * > SCRA, "road charset area overflow", *
        * = SCRA
        .fill $800, 0
        * = SPRDATA
        .binary "../build/sprites.bin"
seg3
        .include "sound.asm"
        .include "hud.asm"
        .include "../build/gen_tpl3.asm"
seg3_end
        .cerror * > $8000, "segment 3 overflow ", *

        * = $8000
        .include "screens.asm"
        .include "../build/music.asm"
        .include "../build/gen_data.asm"
end_of_prg
        .cerror * > $c000, "data segment overflow ", *
