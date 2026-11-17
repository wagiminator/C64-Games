; =====================================================================
;  S K Y H O P  -  bounce up to the moon!   A jumping game for the C64
;  (tribute to Doodle Jump)                     assembler: 64tass
; =====================================================================
        .cpu "6502i"

        .enc "game"
        .cdef "@_", 0
        .cdef " ?", 32

        .include "../build/gen_consts.inc"

; ---------------------------------------------------------- memory map
CHARSET = $4000                 ; font, logo quads, paper, platforms, items, moon
SCRA    = $4800                 ; screen A
SCRB    = $4c00                 ; screen B (double buffer)
SPRDATA = $5000                 ; sprites
COLRAM  = $d800
D018A   = $20                   ; screen A, charset $4000
D018B   = $30

; ---------------------------------------------------------- game constants
NOBJ    = 24                    ; object slots (platforms, springs, items, moon)
CAM0    = 191                   ; camera at the start: bottom line = world y 0
CAMLINE = 84                    ; the camera keeps the player this far below the top
SPRY    = 34                    ; sprite Y = SPRY + cam - y (y = bottom line)
G       = $004c                 ; gravity (8.8 px / frame^2)
JUMPV   = $0820                 ; jump speed  -> ~107 px
SPRINGV = $0e00                 ; spring      -> ~330 px
HATV    = $0500                 ; propeller hat climb speed
JETV    = $0800                 ; jetpack climb speed
HATTIME = 150
JETTIME = 170
MAXFALL = $f700                 ; -9 px / frame
ACC     = $001c                 ; horizontal (MC pixel units, 8.8)
FRICT   = $0012
MAXVX   = $0180
MOONROW = 6252                  ; world row of the moon (height ~50000)
MOONCOL = 15

; object types
T_PLAT  = 1
T_MOVE  = 2
T_BREAK = 3
T_VAN   = 4
T_SPRING = 5
T_HAT   = 6
T_JET   = 7
T_MOON  = 8
T_BROKE = 9
T_POOF  = 10
T_DEAD  = 11                    ; removed, still to be erased from the screens

; player states
PS_NORM = 0
PS_HAT  = 1
PS_JET  = 2
PS_FALL = 3                     ; lost: falling down
PS_HOLE = 4                     ; sucked into a black hole
PS_MOON = 5                     ; landed on the moon

; monster types
M_BLOB  = 1
M_BAT   = 2
M_HOLE  = 3
M_DIE   = 4
M_FLAG  = 5

KEY_P   = 41
KEY_M   = 36
KEY_STOP = 63
DBGAI   = $03fd

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
; player (world coordinates, y up)
pyf     .byte ?                 ; feet y (16.8)
pyl     .byte ?
pyh     .byte ?
vyf     .byte ?                 ; vertical speed (8.8 signed, up = positive)
vyi     .byte ?
pxf     .byte ?                 ; x in multicolour pixels 0..159 (8.8)
pxi     .byte ?
vxf     .byte ?
vxi     .byte ?
caml    .byte ?                 ; camera: world y shown on the top line of the playfield
camh    .byte ?
trl     .byte ?                 ; top row = cam / 8
trh     .byte ?
yol     .byte ?                 ; feet y before this frame's move
yoh     .byte ?
restl   .byte ?
resth   .byte ?
hid     .byte ?                 ; buffer being drawn (0 = A, 1 = B)
        .endv

; ---------------------------------------------------------- variables
        .virtual $c000
score   .fill 3                 ; BCD, lowest byte first
hiscores .fill 30               ; 5 x (3 initials, 3 BCD)
txtbuf  .fill 41
cheat   .byte ?
cheatidx .byte ?
startzone .byte ?
musicoff .byte ?
lastkey .byte ?
; player
ps      .byte ?
ptime   .byte ?
pface   .byte ?
psq     .byte ?
pshoot  .byte ?
dtimer  .byte ?
hgtl    .byte ?                 ; height = cam - CAM0
hgth    .byte ?
lvl     .byte ?
zone    .byte ?
bestl   .byte ?
besth   .byte ?
endflag .byte ?
; objects
o_t     .fill NOBJ
o_rl    .fill NOBJ              ; world row (bottom row of the shape)
o_rh    .fill NOBJ
o_x     .fill NOBJ              ; column (static) or multicolour x (moving)
o_dx    .fill NOBJ
o_st    .fill NOBJ
o_tm    .fill NOBJ
; what is drawn on screen A / B
d_s0    .fill NOBJ
d_r0    .fill NOBJ
d_c0    .fill NOBJ
d_s1    .fill NOBJ
d_r1    .fill NOBJ
d_c1    .fill NOBJ
; desired shape (set by obj_desire)
ds      .byte ?
dr      .byte ?
dc      .byte ?
dcol    .byte ?
; generator
g_rl    .byte ?                 ; row of the last main platform
g_rh    .byte ?
g_ml    .byte ?                 ; row of the last monster
g_mh    .byte ?
g_moon  .byte ?
g_cnt   .byte ?
gap     .byte ?
nrl     .byte ?
nrh     .byte ?
midused .byte ?
; monster
m_t     .byte ?
m_yl    .byte ?
m_yh    .byte ?
m_x     .byte ?
m_dx    .byte ?
m_an    .byte ?
m_kind  .byte ?
; bullet
b_on    .byte ?
b_yl    .byte ?
b_yh    .byte ?
b_x     .byte ?
; sprite shadow registers (applied by the IRQ together with the screen swap)
sx      .fill 8
sy      .fill 8
sc      .fill 8
sxh     .byte ?
sen     .byte ?
spend   .byte ?
nd018   .byte ?
nd011   .byte ?
nd020   .byte ?
nd021   .byte ?
nd022   .byte ?
nd023   .byte ?
sptr    .fill 8
scorechg .byte ?
lastsc  .fill 3
keytmp  .byte ?
sprtxt  .fill 6
ntsc    .byte ?
ntscc   .byte ?
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
        lda #8
        sta $d025
        lda #1
        sta $d026
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
        lda #0
        sta DBGJOY
        sta DBGAI
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
        .include "world.asm"
        .include "player.asm"
        .include "monster.asm"
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
seg2
        * = $6000
        .include "sound.asm"
        .include "screens.asm"
seg2_end
        .cerror * > $8000, "segment 2 overflow ", *

        * = $8000
        .include "../build/music.asm"
        .include "../build/gen_data.asm"
end_of_prg
        .cerror * > $c000, "data segment overflow ", *
