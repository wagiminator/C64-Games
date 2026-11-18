; =====================================================================
;  F L E E T F O O T  -  run for your life!   An endless runner for the
;  C64 (tribute to Subway Surfers and Temple Run)   assembler: 64tass
; =====================================================================
        .cpu "6502i"

        .enc "game"
        .cdef "@_", 0
        .cdef " ?", 32

        .include "../build/gen_consts.inc"

; ---------------------------------------------------------- memory map
CS1     = $4000                 ; font, logo quads, scenery, HUD icons
CS2     = $4800                 ; ground characters
SCR     = $5000                 ; screen
SPRDATA = $5400                 ; sprites
SPEED   = $e000                 ; generated stripe code (RAM under the KERNAL)
STLCAM  = $c600                 ; stripe phase table (64 bytes, 0 / 1)
STTAB   = STLCAM
STSRC   = $c680                 ; plain/stripe byte pairs for the stripe code
COLRAM  = $d800
D018S   = $40                   ; screen, charset 1
D018G   = $42                   ; screen, charset 2

; ---------------------------------------------------------- constants
NO      = 64                    ; objects (ring buffer)
NV      = 16                    ; virtual sprites per list
ZSPAWN  = 900                   ; depth of new objects
ZOUT    = 56                    ; objects behind this are removed
SLOT    = 32                    ; depth between pattern rows
ZONELEN = 800                   ; metres per zone
NZONES  = 5
RUNY    = 188                   ; base line of the runner
SPLIT   = 121                   ; raster line of the charset split
DOT_Y   = 94                    ; far objects above this line are drawn as one pixel

OB_BARR = 1                     ; object types
OB_BAR  = 2
OB_BLK  = 3
OB_COIN = 4
OB_PWR  = 5                     ; 5..8 power-ups

KEY_P   = 41
KEY_M   = 36
KEY_STOP = 63
DBGAI   = $03fd
DBGRAST = $03fc

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
gptr    .word ?                 ; code generator output
cptr    .word ?                 ; soft drawing
irqtmp  .byte ?
gen_k   .word ?
pat_ptr .word ?
        .endv

; ---------------------------------------------------------- variables
        .virtual $c000
score   .fill 3                 ; BCD
hiscores .fill 30
txtbuf  .fill 41
cheat   .byte ?
cheatidx .byte ?
startzone .byte ?
musicoff .byte ?
lastkey .byte ?
keytmp  .byte ?
ntsc    .byte ?
endflag .byte ?
; run
camz    .word ?                 ; travelled depth units (low word)
camf    .byte ?                 ; fraction
spd     .word ?                 ; speed (8.8 units per update)
step    .byte ?                 ; units this update
slotacc .byte ?                 ; depth since the last pattern row
metacc  .byte ?                 ; units since the last metre
metres  .word ?                 ; metres in the current zone
dist    .fill 2                 ; total metres (BCD)
coins   .fill 2                 ; BCD
zone    .byte ?
mult    .byte ?
elapsed .byte ?
lastfr  .byte ?
; runner
plane   .byte ?                 ; target lane 0..2
px      .byte ?                 ; screen x of the runner (hires, centre)
pjh     .word ?                 ; jump height (8.8 pixels)
pvy     .word ?                 ; vertical speed (8.8)
pjump   .byte ?
pslide  .byte ?                 ; slide timer
panim   .byte ?
pdead   .byte ?
stumble .byte ?                 ; boulder close timer
pflash  .byte ?
bouly   .byte ?                 ; boulder: lines visible above the bottom
pw_t    .fill 4                 ; power-up timers (magnet, boots, x2, amulet)
pw_f    .fill 4                 ; fraction counters
; pattern generator
pat_n   .byte ?
pat_mir .byte ?
pat_gap .byte ?
; objects (ring buffer)
o_t     .fill NO
o_zl    .fill NO
o_zh    .fill NO
o_ln    .fill NO
o_h     .fill NO                ; height level (coins)
ohead   .byte ?
otail   .byte ?
; per update projection
o_yb    .fill NO
; soft draw list
sd_n    .byte ?
sd_k    .fill NO
sd_c    .fill NO
sd_x    .fill NO
sd_y    .fill NO
; virtual sprites (two lists, flipped by the IRQ)
vs_cnt  .fill NV*2               ; entries 0 and NV: number of sprites in the list
vs_y    .fill NV*2
vs_x    .fill NV*2
vs_xh   .fill NV*2
vs_p    .fill NV*2
vs_c    .fill NV*2
vs_e    .fill NV*2              ; bit 0 x-expand, bit 1 y-expand
vs_h    .fill NV*2              ; height in lines
vbuf    .byte ?                 ; list being built (0 / NV)
vshow   .byte ?                 ; list shown
spend   .byte ?
mux_i   .byte ?
mux_tmpe .byte ?
mux_tmpx .byte ?
mux_tmpy .byte ?
mux_end .byte ?
; candidates before sorting
cv_y    .fill NV
cv_x    .fill NV
cv_xh   .fill NV
cv_p    .fill NV
cv_c    .fill NV
cv_e    .fill NV
cv_h    .fill NV
cv_n    .byte ?
cv_ord  .fill NV
; player sprite shadows
ps_y0   .byte ?
ps_y1   .byte ?
ps_x    .byte ?
ps_xh   .byte ?
ps_p0   .byte ?
ps_p1   .byte ?
ps_c0   .byte ?
ps_c1   .byte ?
; colours of the zone
z_bg    .byte ?
z_sky   .byte ?
hudmsg  .byte ?
deadt   .byte ?
pwtick  .byte ?
m100    .byte ?
nticks  .byte ?
tickacc .byte ?
glane   .byte ?
ai_d    .fill 3
ai_t    .fill 3                 ; timer of the zone message
ntscc   .byte ?
aiturn  .byte ?
gen_n   .byte ?                 ; code generator temporaries
gen_y   .byte ?
gen_r   .byte ?
gen_l   .byte ?
gen_last .byte ?
gen_ldy .byte ?
gen_lastf .byte ?
gen_i   .byte ?
nearpend .byte ?
gen_sy  .byte ?
cd_p    .fill 32                ; candidates of one line (generator)
cd_s    .fill 32
cd_lo   .fill 32
cd_hi   .fill 32
cd_done .fill 32
rx0     .byte ?                 ; soft rectangle
rx1     .byte ?
ry0     .byte ?
ry1     .byte ?
rpat    .byte ?
rptr    .byte ?
fx0     .byte ?
fx1     .byte ?
fcol    .byte ?
fcol1   .byte ?
fmask   .byte ?
fmask2  .byte ?
fseg1   .byte ?
flines  .byte ?
fbase   .word ?
vars_end
        .endv

; ---------------------------------------------------------- code segment 1
        * = $0801
        .word +, 2026
        .byte $9e
        .text "2064"
        .byte 0
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
        ldx #0
        lda tmp0
        cmp #$20
        bcs +
        inx
+       stx ntsc
        jsr sid_init
        jsr init_hiscores
        jsr gen_stripe_code
        lda #0
        sta DBGJOY
        sta DBGAI
        sta DBGRAST
        sta cheat
        sta startzone
        sta musicoff
        lda #$5a
        sta rndseed
        lda #$c3
        sta rndseed2
        jmp title_screen

nmi     rti

        .include "irq.asm"
        .include "render.asm"
        .include "objects.asm"
        .include "player.asm"
        .include "util.asm"
code1_end
        .cerror * > $4000, "code segment 1 overflow ", *

        * = CS1
        .binary "../build/charset1.bin"
        * = CS2
        .binary "../build/charset2.bin"
        * = SCR
        .fill $400, 32
        * = SPRDATA
        .binary "../build/sprites.bin"
spr_end
        .include "screens.asm"
        .include "sound.asm"
seg2_end
        .cerror * > $8000, "segment 2 overflow ", *

        * = $8000
        .include "game.asm"
        .include "../build/music.asm"
        .include "../build/gen_data.asm"
        .include "../build/patterns.asm"
end_of_prg
        .cerror * > $c000, "data segment overflow ", *
        .cerror STSRC + 2400 > $d000, "stripe source overflow"
        .cerror vars_end > STTAB, "variables overflow"
