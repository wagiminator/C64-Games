; =====================================================================
;  G U L P !  -  eat or be eaten.  An underwater feeding game for C64
;  (tribute to Feeding Frenzy)                 assembler: 64tass
; =====================================================================
        .cpu "6502i"

        .enc "game"
        .cdef "@_", 0
        .cdef " ?", 32

CHARSET = $4000
SCRA    = $4800
SPRDATA = $4c00
COLRAM  = $d800
D018A   = $20

        .include "../build/gen_consts.inc"

N_FISH  = 10
NVS     = 32                    ; max virtual sprites
SPLIT   = 250
HUDLINE = 65
YMIN    = 74
YMAX    = 208
XMIN    = 24
XMAX    = 320

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
ijvec   .word ?
rndseed .byte ?
rndseed2 .byte ?
pageptr .word ?
bgsave  .byte ?
mptr    .word ?
iptr    .word ?
itmp0   .byte ?
irqtmp  .byte ?
nactive .byte ?
fi      .byte ?                 ; current fish index
cdx     .byte ?
cdxh    .byte ?
cdy     .byte ?
exl     .byte ?
exh     .byte ?
ey      .byte ?
ep      .byte ?
ec      .byte ?
        .endv

        .virtual $c000
pacc_l  .fill 4
pacc_h  .fill 4
prot    .fill 4
pat_speed .fill 4
starmove .byte ?
; --- multiplexer
ready   .byte ?
nx_base .byte ?
nx_count .byte ?
mux_base .byte ?
mux_end .byte ?
mux_idx .byte ?
cur_d015 .byte ?
zbg     .byte ?
cy      .fill NVS
cxl     .fill NVS
cxh     .fill NVS
cp      .fill NVS
cc      .fill NVS
bnext   .fill NVS
bhead   .fill 16
outy    .fill 80
outxl   .fill 80
outxh   .fill 80
outp    .fill 80
outc    .fill 80
; --- game state
zone    .byte ?
lvl     .byte ?                 ; 0,1 = normal, 2 = boss
level   .byte ?                 ; zone (for intro screen)
lvidx   .byte ?                 ; zone*3+lvl
lives   .byte ?
score   .fill 3
nextext .fill 3
hudflag .byte ?
cheat   .byte ?
cheatidx .byte ?
startlevel .byte ?
skipflag .byte ?
lastkey .byte ?
keytmp  .byte ?
growth  .byte ?
g_t2    .byte ?
g_t3    .byte ?
g_goal  .byte ?
combo   .byte ?
combo_t .byte ?
mult    .byte ?
power   .byte ?
spawn_t .byte ?
nfish   .byte ?
lvdone  .byte ?
barflag .byte ?
msg_t   .byte ?
; --- player
pxl     .byte ?
pxh     .byte ?
pxf     .byte ?
py      .byte ?
pyf     .byte ?
pvxl    .byte ?
pvxh    .byte ?
pvyl    .byte ?
pvyh    .byte ?
pdir    .byte ?
psize   .byte ?
pstate  .byte ?                 ; 0 swim, 1 eaten, 2 stunned
ptimer  .byte ?
pinv    .byte ?
pmouth  .byte ?
pbx0    .byte ?
pbx1    .byte ?
pby0    .byte ?
pby1    .byte ?
; --- fish
f_k     .fill N_FISH
f_xl    .fill N_FISH
f_xh    .fill N_FISH
f_xf    .fill N_FISH
f_vl    .fill N_FISH
f_vh    .fill N_FISH
f_y     .fill N_FISH
f_yb    .fill N_FISH
f_ph    .fill N_FISH
f_dir   .fill N_FISH
f_spr   .fill N_FISH
f_col   .fill N_FISH
; --- boss
b_on    .byte ?
b_xl    .byte ?
b_xh    .byte ?
b_xf    .byte ?
b_y     .byte ?
b_dir   .byte ?
b_hp    .byte ?
b_t     .byte ?
b_flee  .byte ?
b_fl    .byte ?
b_dead  .byte ?
; --- effects
bu_t    .fill 2
bu_xl   .fill 2
bu_xh   .fill 2
bu_y    .fill 2
bu_i    .byte ?
cl_st   .byte ?
cl_t    .byte ?
cl_xl   .byte ?
cl_xh   .byte ?
; --- misc
hiscores .fill 5*6
txtbuf  .fill 16
lagf    .byte ?
bansave .fill 40
bancsave .fill 40
lagcnt  .byte ?
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
        ora #$02
        sta $dd00
        lda #0
        sta $d020
        sta $d021
        sta $d01b
        sta $d01d
        sta $d017
        sta $d025
        lda #1
        sta $d026
        lda #$ff
        sta $d01c
        ldx #11
        lda #0
-       sta pacc_l,x
        dex
        bpl -
        jsr sid_init
        jsr init_hiscores
        lda #0
        sta DBGJOY
        sta DBGAI
        sta cheat
        sta startlevel
        lda #$5a
        sta rndseed
        lda #$c3
        sta rndseed2
        jmp title_screen

nmi     rti

        .include "irq.asm"
        .include "player.asm"
        .include "fish.asm"
        .include "boss.asm"
        .include "game.asm"
        .include "hud.asm"
        .include "util.asm"
code1_end
        .cerror * > $4000, "code segment 1 overflow ", *

        * = CHARSET
        .binary "../build/charset.bin"
        * = SCRA
        .fill $400, 0
        * = SPRDATA
        .binary "../build/sprites.bin"
seg3
        .include "sound.asm"
        .include "../build/music.asm"
seg3_end
        .cerror * > $8000, "segment 3 overflow ", *

        * = $8000
        .include "screens.asm"
        .include "../build/gen_data.asm"
end_of_prg
        .cerror * > $c000, "data segment overflow ", *
