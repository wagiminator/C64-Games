; =====================================================================
;  V E X O R  -  a vertical scrolling shoot'em up for the C64
;  (tribute to Xenon 2: Megablast)            assembler: 64tass
; =====================================================================
        .cpu "6502i"
        .weak
PROFILE = 0
        .endweak

        .enc "game"
        .cdef "@_", 0
        .cdef " ?", 32

; ---------------------------------------------------------- memory map
CHARSET = $4000
SCRA    = $4800
SCRB    = $4c00
SPRDATA = $5000
COLRAM  = $d800
CSHIFT  = $e000                 ; runtime generated colour-shift code
BACKUP  = $c800                 ; screen/colour backup during mid-level shop
D018A   = $20
D018B   = $30

PFROWS  = 21                    ; playfield rows 0..20, row 21 separator, 22-23 HUD
SPLITC  = 214                   ; sprites must end above this line
HUDLINE = 223                   ; first raster line of the HUD (badline)
SPLITL  = HUDLINE-1             ; HUD split irq line (fixed)
BLANKL  = 214                   ; last visible playfield line (fixed bottom edge)
TOPLINE = 30

N_PB    = 8
N_EN    = 10
N_EB    = 8
NV      = 40

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
mptr    .word ?
rndseed .byte ?
rndseed2 .byte ?
yfine   .byte ?
front   .byte ?
scrollpx .byte ?
scrolling .byte ?
scrolled .byte ?
cur_d011 .byte ?
cur_d018 .byte ?
cur_d015 .byte ?
cur_split .byte ?
cur_blank .byte ?               ; cur_d011 | $60 (invalid mode = black)
blank_mode .byte ?              ; 0: SCRA shown, 1: SCRB shown, 2: BLANKL is a badline
irqsx   .byte ?
split_bl .byte ?                ; 1 if SPLITL is a badline this frame
cur_scrollpx .byte ?
do_cshift .byte ?
nx_d011 .byte ?
nx_d018 .byte ?
nx_split .byte ?
nx_cshift .byte ?
nx_base .byte ?
nx_count .byte ?
gamemode .byte ?
jvec    .word ?
ijvec   .word ?
runptr  .word ?
evptr   .word ?
islptr  .word ?
pageptr .word ?
cx0     .byte ?
cx1     .byte ?
cy0     .byte ?
cy1     .byte ?
        .endv

        .virtual $0200
level   .byte ?
genrow  .word ?
stoprow .word ?
gL      .byte ?
gR      .byte ?
nL      .byte ?
nR      .byte ?
runleft .byte ?
rundl   .byte ?
rundr   .byte ?
is_col  .fill 3
is_w    .fill 3
is_h    .fill 3
is_k    .fill 3
rowchars .fill 40
rowcols .fill 40
pacc_l  .fill 4
pacc_h  .fill 4
prot    .fill 4
bgsave  .byte ?
bgold   .byte ?
bgnew   .byte ?
; --- player
px_l    .byte ?
px_h    .byte ?
py      .byte ?
pstate  .byte ?
ptimer  .byte ?
pinv    .byte ?
pspeed  .byte ?
energy  .byte ?
lives   .byte ?
score   .fill 3
credits .fill 2                 ; BCD lo,hi
nextext .fill 3
hudflag .byte ?
barflag .byte ?
r23state .byte ?
cheat   .byte ?
cheatidx .byte ?
paused  .byte ?
lastkey .byte ?
mainpow .byte ?
autofire .byte ?
sideshot .byte ?
rearshot .byte ?
laser   .byte ?
homing  .byte ?
novaitem .byte ?
novatime .byte ?
novasub .byte ?
firecool .byte ?
firectr .byte ?
pframe  .byte ?
pcx2    .byte ?
pcy     .byte ?
hitflash .byte ?
; --- spawners
sp_type .fill 2
sp_cnt  .fill 2
sp_x    .fill 2
sp_par  .fill 2
sp_tim  .fill 2
sp_idx  .fill 2
; --- flow
stagestate .byte ?
stagetimer .word ?
shoppend .byte ?
bombflash .byte ?
        .endv

        .virtual $c000
cy      .fill NV
cxl     .fill NV
cxh     .fill NV
cp      .fill NV
cc      .fill NV
bnext   .fill NV
bhead   .fill 16
nactive .byte ?
outy    .fill 80
outxl   .fill 80
outxh   .fill 80
outp    .fill 80
outc    .fill 80
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
pb_x0   .fill N_PB
pb_x1   .fill N_PB
pb_y0   .fill N_PB
pb_y1   .fill N_PB
en_t    .fill N_EN
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
en_tm   .fill N_EN
en_a    .fill N_EN
en_b    .fill N_EN
en_c    .fill N_EN
en_spr  .fill N_EN
en_col  .fill N_EN
en_fl   .fill N_EN
en_gnd  .fill N_EN
en_cx2  .fill N_EN
en_cy   .fill N_EN
en_x0   .fill N_EN
en_x1   .fill N_EN
en_y0   .fill N_EN
en_y1   .fill N_EN
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
b_on    .byte ?
b_xl    .byte ?
b_xh    .byte ?
b_y     .byte ?
b_hp    .byte ?
b_maxhp .byte ?
b_state .byte ?
b_t     .byte ?
b_t2    .byte ?
b_ang   .byte ?
b_fl    .byte ?
b_alt   .byte ?
b_cx2   .byte ?
b_dead  .byte ?
b_shots .byte ?
b_vx    .byte ?
hiscores .fill 5*6
txtbuf  .fill 16
        .endv
        .cerror cy > 0 && txtbuf > BACKUP, "bss overlaps backup"

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
        sta $7fff               ; idle byte for vertical scrolling gap
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

        * = CHARSET
        .binary "../build/charset.bin"
        * = SCRA
        .fill $800, 0
        * = SPRDATA
        .binary "../build/sprites.bin"
        .align 64
spr_empty .fill 64, 0           ; shown below the bottom edge
SPR_EMPTY = (spr_empty - CHARSET) / 64
        .fill $8000 - *, 0

        * = $8000
        .include "shop.asm"
        .include "screens.asm"
        .include "sound.asm"
        .include "../build/gen_data.asm"
        .include "../build/levels.asm"
        .include "../build/music.asm"
end_of_prg
        .cerror * > $c000, "data segment overflow ", *
