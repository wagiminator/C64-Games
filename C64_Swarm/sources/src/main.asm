; =====================================================================
;  S W A R M  -  a fixed-screen alien invasion shooter for the C64
;  (tribute to Space Invaders)               assembler: 64tass
; =====================================================================
        .cpu "6502i"

        .enc "game"
        .cdef "@_", 0
        .cdef " ?", 32

; ---------------------------------------------------------- memory map
CHARSET = $4000
SCRA    = $4800
SPRDATA = $5000
COLRAM  = $d800
D018A   = $20

        .include "../build/gen_consts.inc"

; ---------------------------------------------------------- screen layout
ROW_HUD   = 0
ROW_BUNK  = 18
ROW_GND   = 23
ROW_STAT  = 24
PLAYER_SY = 213                 ; sprite y of player (art rows 13..20 -> screen 176..183)
INVADE_ROW = 21

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
ftmp0   .byte ?
ftmp1   .byte ?
ftmp2   .byte ?
ftmp3   .byte ?
fptr    .word ?
fcptr   .word ?
frow    .byte ?
fcol    .byte ?
fch     .byte ?
fclr    .byte ?
fidx    .byte ?
ftype   .byte ?
bptr    .word ?
bmask   .byte ?
pbi     .byte ?
ebi     .byte ?
edir    .byte ?
ex0     .byte ?
ey0     .byte ?
eidx    .byte ?
firebase .byte ?
mptr    .word ?
iptr    .word ?
wsen    .byte ?
wsmsb   .byte ?
bantim  .byte ?
fsalt   .byte ?
starmove .byte ?
        .endv

        .virtual $c000
; --- star rotation
pacc_l  .fill 4
pacc_h  .fill 4
prot    .fill 4
; --- sprite shadow registers
spx     .fill 8                 ; x / 2
spy     .fill 8                 ; y (0 = off)
spp     .fill 8                 ; pointer
spc     .fill 8                 ; colour
spexp   .byte ?                 ; expand mask (x and y)
; --- game state
sector  .byte ?
wave    .byte ?
lives   .byte ?
score   .fill 3                 ; BCD, units of 10 points (lo,mid,hi)
nextext .fill 3
hudflag .byte ?
cheat   .byte ?
cheatidx .byte ?
startlevel .byte ?
level   .byte ?
skipflag .byte ?
lastkey .byte ?
keytmp  .byte ?
invaded .byte ?
bossmode .byte ?
statflag .byte ?
; --- player
px      .byte ?                 ; sprite x/2
pstate  .byte ?                 ; 0 alive, 1 dying
ptimer  .byte ?
firecool .byte ?
power   .byte ?                 ; 0 none, 1 rapid, 2 double
powtime .word ?
; --- player bullets (2)
pb_on   .fill 2
pb_x    .fill 2
pb_y    .fill 2
pb_sp   .byte ?
; --- alien bullets (3)
eb_on   .fill 3
eb_x    .fill 3
eb_xf   .fill 3
eb_vx   .fill 3
eb_y    .fill 3
eb_sp   .fill 3
eb_spf  .fill 3
eb_yf   .fill 3
eb_fr   .fill 3
firetimer .byte ?
maxeb   .byte ?
shotalt .byte ?
; --- formation
alive   .fill 55
colcnt  .fill 11
rowcnt  .fill 5
colx    .fill 11                ; screen x/2 of each column
nalive  .byte ?
fxo     .byte ?                 ; formation x (screen x/2 of column 0) + 100
fy      .byte ?                 ; char row of formation row 0
fdir    .byte ?                 ; 0 right, 1 left
fframe  .byte ?
ftimer  .byte ?
lc      .byte ?
rc      .byte ?
br      .byte ?
spanl   .byte ?
spanr   .byte ?
marchi  .byte ?
marchcool .byte ?
; --- ufo / capsule / explosion / score popup
ufo_on  .byte ?
ufo_dir .byte ?
ufo_tim .word ?
cap_on  .byte ?
cap_t   .byte ?
ex_t    .byte ?
pop_t   .byte ?
pop_col .byte ?
; --- boss
b_hp    .byte ?
b_max   .byte ?
b_x     .byte ?
b_y     .byte ?
b_dir   .byte ?
b_fl    .byte ?
b_t     .byte ?
b_cnt   .byte ?
b_dead  .byte ?
b_ph    .byte ?
; --- misc
hiscores .fill 5*6              ; 3 name chars + 3 BCD bytes (lo,mid,hi)
txtbuf  .fill 16
lagf    .byte ?
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
        ora #$02                ; VIC bank 1 ($4000)
        sta $dd00
        lda #0
        sta $d020
        sta $d021
        sta $d01b
        sta $d01d
        sta $d017
        lda #11
        sta $d025
        lda #1
        sta $d026
        lda #$ff
        sta $d01c               ; all sprites multicolour
        ldx #11
        lda #0
-       sta pacc_l,x
        dex
        bpl -
        jsr sid_init
        jsr init_hiscores
        lda #0
        sta DBGJOY
        sta cheat
        sta startlevel
        lda #$5a
        sta rndseed
        lda #$c3
        sta rndseed2
        jmp title_screen

nmi     rti

        .include "irq.asm"
        .include "formation.asm"
        .include "objects.asm"
        .include "boss.asm"
        .include "game.asm"
        .include "util.asm"
code1_end
        .cerror * > $4000, "code segment 1 overflow ", *

; ---------------------------------------------------------- graphics
        * = CHARSET
        .binary "../build/charset.bin"
        * = SCRA
        .fill $800, 0
        * = SPRDATA
        .binary "../build/sprites.bin"

; ---------------------------------------------------------- code/data 2
        * = $8000
        .include "screens.asm"
        .include "sound.asm"
        .include "../build/gen_data.asm"
        .include "../build/music.asm"
end_of_prg
        .cerror * > $c000, "data segment overflow ", *
