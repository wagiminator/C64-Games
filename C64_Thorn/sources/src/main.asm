; =====================================================================
;  T H O R N  -  defend your garden against the undead (C64)
;  (tribute to Plants vs. Zombies)             assembler: 64tass
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

        .weak
PROFILE = 0
        .endweak
N_Z     = 20
N_SUN   = 6
NVS     = 40
SPLIT   = 250
HUDLINE = 81
LAWNROW = 4
LAWNCOL = 4
HUDBG   = 9

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
level   .byte ?                 ; 0..9
area    .byte ?                 ; 0 day, 1 dusk, 2 night
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
lawnbg  .byte ?
sun     .fill 2                 ; BCD
sunflag .byte ?
npack   .byte ?
pk_cd   .fill 7
pkflag  .byte ?
held    .byte ?
cur_r   .byte ?                 ; 0 = seed bar, 1..5 = lanes
cur_c   .byte ?
cur_lc  .byte ?                 ; last lawn column
cur_lr  .byte ?
rep_t   .byte ?
lvdone  .byte ?
lost    .byte ?
skysun_t .word ?
msg_t   .byte ?
lastdir .byte ?
firelast .byte ?
cur_bc  .byte ?
sp_ph   .byte ?
sp_all  .byte ?
lastlvl .byte ?
pcolor  .byte ?
pphase  .byte ?
stl     .byte ?
stn     .byte ?
; --- grid (lane*9+col)
g_type  .fill 45
g_hp    .fill 45
g_t     .fill 45
; --- peas (lane*8+k)
pe_x    .fill 40
pe_k    .fill 40
; --- zombies
z_t     .fill N_Z
z_lane  .fill N_Z
z_xl    .fill N_Z
z_xh    .fill N_Z
z_xf    .fill N_Z
z_hp    .fill N_Z
z_st    .fill N_Z
z_tm    .fill N_Z
z_slow  .fill N_Z
z_fl    .fill N_Z
z_y     .fill N_Z
lz_cnt  .fill 5
lz_idx  .fill 40
lz_max  .fill 5                 ; max x (hi byte flag) of zombies in lane: lo
lz_maxh .fill 5
nzomb   .byte ?
; --- director
sp_n    .byte ?
sp_tot  .byte ?
sp_t    .word ?
sp_burst .byte ?
sp_bt   .byte ?
sp_flag1 .byte ?
sp_r    .byte ?
; --- suns
su_on   .fill N_SUN
su_xl   .fill N_SUN
su_xh   .fill N_SUN
su_y    .fill N_SUN
su_ty   .fill N_SUN
su_t    .fill N_SUN
su_lane .fill N_SUN
su_col  .fill N_SUN
; --- mowers
mw_st   .fill 5
mw_xl   .fill 5
mw_xh   .fill 5
; --- explosion
ex_t    .byte ?
ex_xl   .byte ?
ex_xh   .byte ?
ex_y    .byte ?
; --- boss
bo_on   .byte ?
bo_xl   .byte ?
bo_xh   .byte ?
bo_xf   .byte ?
bo_lane .byte ?
bo_y    .byte ?
bo_hpl  .byte ?
bo_hph  .byte ?
bo_tm   .byte ?
bo_tl   .byte ?
bo_fl   .byte ?
bo_dead .byte ?
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
        lda #15
        sta $d026
        lda #$ff
        sta $d01c
        ldx #11
        lda #0
-       sta pacc_l,x
        dex
        bpl -
        jsr sid_init
        lda #$ff
        sta $dd04
        sta $dd05
        lda #$11
        sta $dd0e
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
        .include "lawn.asm"
        .include "zombies.asm"
        .include "game.asm"
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
        .include "hud.asm"
seg3_end
        .cerror * > $8000, "segment 3 overflow ", *

        * = $8000
        .include "screens.asm"
        .include "../build/gen_data.asm"
end_of_prg
        .cerror * > $c000, "data segment overflow ", *
