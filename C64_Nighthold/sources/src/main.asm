; =====================================================================
;  N I G H T H O L D  -  survive the night!   A horde survival game
;  for the C64 (tribute to Vampire Survivors)   assembler: 64tass
; =====================================================================
        .cpu "6502i"

        .enc "game"
        .cdef "@_", 0
        .cdef " ?", 32

        .include "../build/gen_consts.inc"

; ---------------------------------------------------------- memory map
CHARMENU = $4000                ; font, logo quads (menus)
SCRA    = $4800                 ; screen A (also the menu screen)
SCRB    = $4c00                 ; screen B
SPRDATA = $5000                 ; sprites
CHARGAME = $6000                ; font, ui, ground, creatures, weapons
MAP     = $8000                 ; 64 x 64 cells, rows of 104 bytes
GRID    = $e000                 ; 64 x 64 occupancy (enemy index + 1), under the KERNAL
COLRAM  = $d800
D018A   = $20                   ; screen A, menu charset
D018GA  = $28                   ; screen A, game charset
D018GB  = $38                   ; screen B, game charset

; ---------------------------------------------------------- game constants
NE      = 80                    ; enemies
NG      = 40                    ; gems / pickups
NK      = 12                    ; knives
NFX     = 12                    ; effects (bolts, fire, poofs)
HEROSX  = 171                   ; hero sprite x (screen centre)
HEROSY  = 140                   ; hero sprite y
CAMDX   = 140                   ; camera = hero - (CAMDX, CAMDY)
CAMDY   = 86
ENDMIN  = 10                    ; minutes until dawn

KEY_P   = 41
KEY_M   = 36
KEY_STOP = 63
DBGAI   = $03fd
DBGRAST = $03fc                 ; raster time bars in the border (testing)

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
src     .word ?                 ; background copy
dst     .word ?
optr    .word ?                 ; object on the hidden screen
gptr    .word ?                 ; grid cell
hidhi   .byte ?                 ; high byte of the hidden screen ($48 / $4c)
; hero
pxl     .byte ?                 ; world pixel position of the hero sprite
pxh     .byte ?
pyl     .byte ?
pyh     .byte ?
pcxl    .byte ?                 ; hero cell (centre)
pcxh    .byte ?
pcyl    .byte ?
pcyh    .byte ?
bcxl    .byte ?                 ; world cell of the hidden screen's top left corner
bcxh    .byte ?
bcyl    .byte ?
bcyh    .byte ?
        .endv

; ---------------------------------------------------------- variables
        .virtual $c000
score   .fill 3                 ; BCD
hiscores .fill 30
txtbuf  .fill 41
cheat   .byte ?
cheatidx .byte ?
startzone .byte ?               ; start minute (cheat)
musicoff .byte ?
lastkey .byte ?
keytmp  .byte ?
ntsc    .byte ?
endflag .byte ?
; hero
hp      .byte ?
maxhp   .byte ?
iframes .byte ?
pdir    .byte ?                 ; 0..7 (0 = right, 2 = down, 4 = left, 6 = up)
pface   .byte ?                 ; 0 right, 1 left
panim   .byte ?
moving  .byte ?
spdf    .byte ?                 ; speed (8.8 px per update)
spdi    .byte ?
subx    .byte ?
suby    .byte ?
xp      .word ?
xpnext  .word ?
plevel  .byte ?
lvpend  .byte ?                 ; level ups waiting
kills   .fill 3                 ; BCD
dead    .byte ?
; camera
camxl   .byte ?
camxh   .byte ?
camyl   .byte ?
camyh   .byte ?
; time
tfr     .byte ?                 ; frames in the current second
secs    .byte ?
mins    .byte ?
tsecs   .word ?                 ; seconds since the start
phase   .byte ?                 ; colour phase
; enemies
e_t     .fill NE                ; type + 1 (0 = free)
e_xl    .fill NE
e_xh    .fill NE
e_yl    .fill NE
e_yh    .fill NE
e_hp    .fill NE
e_tm    .fill NE                ; move timer
e_fl    .fill NE                ; hit flash
e_hc    .fill NE                ; hit cooldown (orbs, fire)
ecount  .byte ?
spawnt  .byte ?
; gems
g_t     .fill NG                ; 0 free, 1..3 gem size, 4 heart
g_xl    .fill NG
g_xh    .fill NG
g_yl    .fill NG
g_yh    .fill NG
; knives
k_on    .fill NK
k_xl    .fill NK
k_xh    .fill NK
k_yl    .fill NK
k_yh    .fill NK
k_d     .fill NK
k_r     .fill NK
; effects
fx_t    .fill NFX               ; 0 free, 1 bolt, 2 fire, 3 poof
fx_xl   .fill NFX
fx_xh   .fill NFX
fx_yl   .fill NFX
fx_yh   .fill NFX
fx_tm   .fill NFX
; weapons and items: 0 knives 1 glow 2 bell 3 orbs 4 flask 5 boots 6 hourglass 7 lodestone 8 heart
NITEMS  = 9
w_lvl   .fill NITEMS
w_cd    .fill 5
orbang  .byte ?
auratm  .byte ?
; boss
b_on    .byte ?
b_kind  .byte ?
b_xl    .byte ?                 ; world pixels
b_xh    .byte ?
b_yl    .byte ?
b_yh    .byte ?
b_hpl   .byte ?
b_hph   .byte ?
b_fl    .byte ?
bossdone .byte ?
; level up menu
lu_opt  .fill 3
lu_sel  .byte ?
; sprite shadows (applied by the IRQ with the screen swap)
sx      .fill 8
sy      .fill 8
sc      .fill 8
sptr    .fill 8
sxh     .byte ?
sen     .byte ?
spend   .byte ?
nd018   .byte ?
nd016   .byte ?
nd011   .byte ?
disp    .byte ?
lastfr  .byte ?
ntscc   .byte ?
hudchg  .byte ?
aiturn  .byte ?
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
        .include "draw.asm"
        .include "enemy.asm"
        .include "util.asm"
code1_end
        .cerror * > $4000, "code segment 1 overflow ", *

        * = CHARMENU
        .binary "../build/charset_menu.bin"
        * = SCRA
        .fill $800, 0
        * = SPRDATA
        .binary "../build/sprites.bin"
        * = CHARGAME
        .binary "../build/charset_game.bin"
seg2
        * = $6800
        .include "sound.asm"
        .include "screens.asm"
seg2_end
        .cerror * > $8000, "segment 2 overflow ", *

        * = MAP
        .binary "../build/map.bin"
        .include "../build/music.asm"
        .include "../build/gen_data.asm"
        .include "weapon.asm"
        .include "game.asm"
end_of_prg
        .cerror * > $c000, "data segment overflow ", *
