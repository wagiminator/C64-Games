; =====================================================================
;  J E T D A S H  -  fly through the lab!   A jetpack game for the C64
;  (tribute to Jetpack Joyride)                 assembler: 64tass
; =====================================================================
        .cpu "6502i"

        .enc "game"
        .cdef "@_", 0
        .cdef " ?", 32

        .include "../build/gen_consts.inc"

; ---------------------------------------------------------- memory map
CHARMENU = $4000                ; font, logo quads (title and menus)
SCRA    = $4800                 ; screen A
SCRB    = $4c00                 ; screen B (double buffer)
SPRDATA = $5000                 ; sprites
CHARGAME = $6000                ; font, coins, zappers, lasers, lab tiles
COLRAM  = $d800
D018A   = $20                   ; screen A, menu charset
D018GA  = $28                   ; screen A, game charset
D018GB  = $38                   ; screen B, game charset
SPDA    = $e000                 ; generated copy code A -> B (shifted by one column)
SPDB    = $a800                 ; generated copy code B -> A

; ---------------------------------------------------------- game constants
HEROX   = 64                    ; hero screen x (sprite x = 24 + HEROX)
YMIN    = 24                    ; highest sprite top (below the ceiling)
YMAX    = 163                   ; sprite top when standing on the floor (feet at 184)
YMAXU   = 24                    ; sprite top when standing on the ceiling (gravity belt)
SPRY0   = 50                    ; sprite y register = SPRY0 + screen y
THRUST  = $0058                 ; jetpack acceleration (8.8 px / frame^2)
GRAV    = $0036                 ; gravity
MAXUP   = $fd60                 ; -2.6 px / frame
MAXDOWN = $0380                 ; 3.5 px / frame
FLAPV   = $fdc0                 ; copter flap speed
CGRAV   = $0026                 ; copter gravity
CMAXD   = $0200
BGRAV   = $0070                 ; gravity belt
BMAXV   = $0480
INVTIME = 100                   ; invulnerable after losing a vehicle
WORKY   = 163                   ; worker sprite top
ZONECOLS = 500                  ; world columns per zone (1000 m)

; hero modes
PM_JET  = 0
PM_COPTER = 1
PM_GRAV = 2
PM_DEAD = 3
PM_EXIT = 4                     ; flying out of the lab (ending)

KEY_P   = 41
KEY_M   = 36
KEY_STOP = 63
DBGAI   = $03fd
DBGRAST = $03fc                 ; raster time bars in the border (debugging)

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
gptr    .word ?                 ; pattern read pointer
scrp    .word ?                 ; screen pointer (displayed buffer)
scrq    .word ?                 ; screen pointer (other buffer)
hyf     .byte ?                 ; hero sprite top y (8.8)
hyi     .byte ?
vyf     .byte ?                 ; vertical speed (8.8 signed, down = positive)
vyi     .byte ?
xs      .byte ?                 ; fine scroll 7..0 of the state being built
disp    .byte ?                 ; displayed buffer of the state being built (0 = A, 1 = B)
l_ptr   .word ?                 ; laser sequence pointer
wcl     .byte ?                 ; world column shown in screen column 0
wch     .byte ?
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
keytmp  .byte ?
ntsc    .byte ?
ntscc   .byte ?
endflag .byte ?
; distance and coins
metres  .fill 3                 ; BCD
mbl     .byte ?                 ; metres binary
mbh     .byte ?
mquart  .byte ?                 ; pixels towards the next metre (4 px = 1 m)
coins   .fill 2                 ; BCD
best    .fill 3                 ; best distance (BCD)
lvl     .byte ?
zone    .byte ?                 ; displayed zone
hudchg  .byte ?
msgtime .byte ?
; scrolling
spdf    .byte ?                 ; scroll speed (8.8 px / frame)
spdi    .byte ?
subpx   .byte ?
moved   .byte ?                 ; pixels scrolled this frame
prep    .byte ?                 ; preparation of the hidden buffer: 0, 1 = copying, 2 = ready
swapnow .byte ?                 ; a swap was scheduled this frame
stall   .byte ?
; generator
gcl     .byte ?                 ; next world column to generate
gch     .byte ?
gtile   .byte ?                 ; current tile
gzone   .byte ?                 ; zone of the generator
gatel   .byte ?                 ; world column of the last gate
gateh   .byte ?
gplen   .byte ?                 ; columns left in the current pattern (0 = none)
gprow   .byte ?                 ; base row of the current pattern
gap     .byte ?                 ; empty columns before the next pattern
lwait   .byte ?                 ; columns to wait before a laser sequence (0 = none)
ldone   .byte ?                 ; columns after a laser sequence before new patterns
gnopat  .byte ?                 ; no patterns (laser, exit)
boxcnt  .word ?
colbuf  .fill 23
ctile   .fill 64                ; tile of every world column (ring)
; hero
pmode   .byte ?
thrust  .byte ?                 ; jetpack fires this frame
ground  .byte ?                 ; standing on the floor (1) / ceiling (2)
gdir    .byte ?                 ; gravity belt: 0 down, 1 up
panim   .byte ?
invuln  .byte ?
dtimer  .byte ?
flash   .byte ?
exittime .byte ?
herox   .byte ?
; missiles
NMIS    = 2
ms_st   .fill NMIS              ; 0 off, 1 delay, 2 track, 3 lock, 4 fly
ms_t    .fill NMIS
ms_y    .fill NMIS
ms_xl   .fill NMIS
ms_xh   .fill NMIS
mtimer  .word ?
; lasers
l_steps .byte ?
l_ph    .byte ?                 ; 0 none, 1 warn, 2 fire, 3 pause
l_t     .byte ?
l_r1    .byte ?
l_r2    .byte ?
l_fire  .byte ?
l_pause .byte ?
lactive .byte ?
; workers
NWRK    = 2
wk_st   .fill NWRK              ; 0 off, 1 walking, 2 knocked over
wk_xl   .fill NWRK
wk_xh   .fill NWRK
wk_dir  .fill NWRK
wk_sub  .fill NWRK
; gadget box / explosion (sprite 7)
bx_st   .byte ?                 ; 0 off, 1 box, 2 explosion
bx_xl   .byte ?
bx_xh   .byte ?
bx_y    .byte ?
bx_t    .byte ?
; sprite shadow registers (applied by the IRQ together with the screen swap)
sx      .fill 8
sy      .fill 8
sc      .fill 8
sptr    .fill 8
sxh     .byte ?
sen     .byte ?
spend   .byte ?
nd018   .byte ?
nxs     .byte ?
curxs   .byte ?
zbg     .byte ?
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
        jsr gen_speedcode
        lda #0
        sta DBGJOY
        sta DBGAI
        sta DBGRAST             ; page 3 is not cleared when booting from the cartridge
        sta cheat
        sta startzone
        sta musicoff
        sta best
        sta best+1
        sta best+2
        lda #$5a
        sta rndseed
        lda #$c3
        sta rndseed2
        jmp title_screen

nmi     rti

        .include "irq.asm"
        .include "scroll.asm"
        .include "gen.asm"
        .include "player.asm"
        .include "hazards.asm"
        .include "game.asm"
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

        * = $8000
        .include "../build/music.asm"
        .include "../build/gen_data.asm"
end_of_prg
        .cerror * > SPDB, "data segment overflow ", *
