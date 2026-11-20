; =====================================================================
;  Z Y R O N  -  a horizontal scrolling shoot'em up for the C64
;  (tribute to Katakis / R-Type)        assembler: 64tass
; =====================================================================
        .cpu "6502i"
        .weak
PROFILE = 0
        .endweak

        .enc "game"
        .cdef "@_", 0
        .cdef " ?", 32
        .edef "{", 255          ; string terminator marker not used

; ---------------------------------------------------------- memory map
CHARSET = $4000
SCRA    = $4800
SCRB    = $4c00
SPRDATA = $5000
COLRAM  = $d800
CSHIFT  = $e000                 ; runtime generated colour-shift code
D018A   = $20
D018B   = $30

PFROWS  = 21                    ; playfield rows (0..20), row 21 separator
SPLIT   = 221                   ; raster line of HUD split (inside row 21)
TOPLINE = 42

NV      = 40                    ; virtual sprites
MUXGAP  = 3                     ; lines between rewriting a hardware sprite and its new top line
N_PB    = 8                     ; player bullets
N_EN    = 10                    ; enemies / explosions / items
N_EB    = 8                     ; enemy bullets

VS_PLAYER = 0
VS_ORB    = 1
VS_PB     = 2
VS_EN     = 10
VS_EB     = 22
VS_BOSS   = 30

        .include "../build/gen_consts.inc"

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
ready   .byte ?
mux_idx .byte ?
mux_end .byte ?
mux_base .byte ?
joy     .byte ?
joyprev .byte ?
joynew  .byte ?
irqtmp  .byte ?
itmp0   .byte ?
itmp1   .byte ?
iptr    .word ?
mptr    .word ?                 ; music pointer
rndseed .byte ?
rndseed2 .byte ?
xfine   .byte ?
front   .byte ?
scrollpx .byte ?
scrolling .byte ?
scrolled .byte ?                ; 1 if terrain moved this frame
key     .byte ?
cur_d016 .byte ?
cur_d018 .byte ?
cur_d015 .byte ?
cur_scrollpx .byte ?
do_cshift .byte ?
nx_d016 .byte ?
nx_d018 .byte ?
nx_cshift .byte ?
nx_base .byte ?
nx_count .byte ?
gamemode .byte ?                ; 0 = simple irq, 1 = game irq
jvec    .word ?
ijvec   .word ?
runptr  .word ?
evptr   .word ?
pageptr .word ?
cx0     .byte ?
cx1     .byte ?
cy0     .byte ?
cy1     .byte ?
ox0     .byte ?
ox1     .byte ?
oy0     .byte ?
oy1     .byte ?
        .endv

        .virtual $0200
; --- level / terrain state
level   .byte ?
rightcol .word ?
stopcol .word ?
genx    .word ?
gC      .byte ?
gF      .byte ?
nC      .byte ?
nF      .byte ?
runleft .byte ?
rundc   .byte ?
rundf   .byte ?
colchars .fill PFROWS
colbuf  .fill PFROWS
; --- bg pattern rotation
pacc_l  .fill 8
pacc_h  .fill 8
bglast  .byte ?
skipfire .byte ?
prot    .fill 8
bgsave  .byte ?
; --- player
px_l    .byte ?
px_h    .byte ?
py      .byte ?
pstate  .byte ?                 ; 0 alive 1 dying 2 waiting
ptimer  .byte ?
pinv    .byte ?
pspeed  .byte ?
weapon  .byte ?
wlevel  .byte ?
orbon   .byte ?
ox_l    .byte ?
ox_h    .byte ?
oy      .byte ?
charge  .byte ?
firecool .byte ?
pframe  .byte ?
pcx2    .byte ?
pcy     .byte ?
lives   .byte ?
score   .fill 3                 ; BCD, units of 10 points (lo,mid,hi)
nextext .fill 3
hudflag .byte ?
barflag .byte ?
r24state .byte ?
cheat   .byte ?
cheatidx .byte ?
paused  .byte ?
lastkey .byte ?
bombflash .byte ?
orbhit  .byte ?
ocx2    .byte ?
ocy     .byte ?
; --- spawners
sp_type .fill 2
sp_cnt  .fill 2
sp_y    .fill 2
sp_par  .fill 2
sp_tim  .fill 2
sp_idx  .fill 2
; --- game flow
stagestate .byte ?              ; 0 play, 1 boss, 2 clear, 3 gameover-wait
stagetimer .word ?
clearflag .byte ?
skipflag .byte ?
        .endv

        .virtual $c000
; --- virtual sprites
cy      .fill NV
cxl     .fill NV
cxh     .fill NV
cp      .fill NV
cc      .fill NV
bnext   .fill NV
bhead   .fill 16
nactive .byte ?
; --- mux output (double buffered: 0..39 / 40..79)
outy    .fill 80
outxl   .fill 80
outxh   .fill 80
outp    .fill 80
outc    .fill 80
; --- player bullets
pb_t    .fill N_PB
pb_xl   .fill N_PB
pb_xh   .fill N_PB
pb_y    .fill N_PB
pb_vx   .fill N_PB
pb_vy   .fill N_PB
pb_dmg  .fill N_PB
pb_hit  .fill N_PB
pb_spr  .fill N_PB
pb_col  .fill N_PB
pb_cx2  .fill N_PB
pb_cy   .fill N_PB
pb_age  .fill N_PB
pb_x0   .fill N_PB
pb_x1   .fill N_PB
pb_y0   .fill N_PB
pb_y1   .fill N_PB
; --- enemies
en_t    .fill N_EN              ; type (0 free)
en_xf   .fill N_EN
en_xl   .fill N_EN
en_xh   .fill N_EN
en_yf   .fill N_EN
en_y    .fill N_EN
en_vxl  .fill N_EN
en_vxh  .fill N_EN
en_vyl  .fill N_EN
en_vyh  .fill N_EN
en_hp   .fill N_EN
en_tm   .fill N_EN              ; timer
en_a    .fill N_EN
en_b    .fill N_EN
en_c    .fill N_EN
en_spr  .fill N_EN
en_col  .fill N_EN
en_fl   .fill N_EN              ; hit flash
en_gnd  .fill N_EN
en_cx2  .fill N_EN
en_cy   .fill N_EN
en_x0   .fill N_EN
en_x1   .fill N_EN
en_y0   .fill N_EN
en_y1   .fill N_EN
; --- enemy bullets
eb_on   .fill N_EB
eb_xf   .fill N_EB
eb_xl   .fill N_EB
eb_xh   .fill N_EB
eb_yf   .fill N_EB
eb_y    .fill N_EB
eb_vxl  .fill N_EB
eb_vxh  .fill N_EB
eb_vyl  .fill N_EB
eb_vyh  .fill N_EB
eb_cx2  .fill N_EB
; --- boss
b_on    .byte ?
b_xl    .byte ?
b_xh    .byte ?
b_y     .byte ?
b_yf    .byte ?
b_hp    .byte ?
b_maxhp .byte ?
b_state .byte ?
b_t     .byte ?
b_t2    .byte ?
b_ang   .byte ?
b_fl    .byte ?
b_alt   .byte ?
b_ty    .byte ?
b_cx2   .byte ?
b_dead  .byte ?
b_shots .byte ?
; --- misc
hiscores .fill 5*6              ; 3 name chars + 3 BCD bytes (lo,mid,hi)
hientry .byte ?
txtbuf  .fill 16
; --- multiplexer: hardware sprite allocation
sl_ring .fill 8                 ; hardware sprites in the order of their last use
sl_head .byte ?                 ; ring position of the one free first
sl_free .fill 8                 ; per hardware sprite: line where it gets free
sl_last .fill 8                 ; ... output entry of its last sprite
outslot .fill 80                ; hardware sprite of an output entry
outfree .fill 80                ; raster line for the write (0 = in the split IRQ)
outpri  .fill 80                ; 1 = must not be dropped
bstart  .byte ?                 ; first candidate of the boss
shipin  .byte ?                 ; 1 = candidate 0 is the ship
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
        jsr gen_cshift
        jsr sid_init
        jsr init_hiscores
        lda #0
        sta DBGJOY
        sta cheat
        sta startlevel
        sta gamemode
        lda #$5a
        sta rndseed
        lda #$c3
        sta rndseed2
        jmp title_screen

nmi     rti

        .include "irq.asm"
        .include "scroll.asm"
        .include "sprites.asm"
        .include "player.asm"
        .include "enemies.asm"
        .include "boss.asm"
        .include "game.asm"
        .include "hud.asm"
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
        .fill $8000 - *, 0

; ---------------------------------------------------------- code/data 2
        * = $8000
        .include "screens.asm"
        .include "sound.asm"
        .include "tables.asm"
        .include "../build/gen_data.asm"
        .include "../build/levels.asm"
        .include "../build/music.asm"
end_of_prg
        .cerror * > $cf00, "data segment overflow ", *
