; =====================================================================
;  G U M D R O P  -  a sweet match-three puzzle for the C64
;  (tribute to Candy Crush Saga)                assembler: 64tass
; =====================================================================
        .cpu "6502i"

        .enc "game"
        .cdef "@_", 0
        .cdef " ?", 32

        .include "../build/gen_consts.inc"

; ---------------------------------------------------------- memory map
CHARSET = $4000                 ; font, logo quads, heart
SCRA    = $4800                 ; menu screen
SCRG    = $4c00                 ; game screen: bitmap colours (rows 0..19), text (rows 20..24)
SPRDATA = $5000                 ; sprites
BITMAP  = $6000                 ; multicolour bitmap
COLRAM  = $d800
D018A   = $20                   ; menu: screen $4800, charset $4000
D018BM  = $38                   ; game: screen $4c00, bitmap $6000
D018TX  = $30                   ; game text rows: screen $4c00, charset $4000

; ---------------------------------------------------------- game constants
EMPTY   = $ff
RAINBOW = 6
TEXTROW = 20                    ; first text row below the bitmap
BGCOL   = 0

KEY_P   = 41
KEY_M   = 36
KEY_STOP = 63
KEY_PLUS = 40
KEY_MINUS = 43
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
dptr    .word ?                 ; shape data
bptr    .word ?                 ; bitmap
sptr2   .word ?                 ; screen colours
cbl     .word ?                 ; column buffers
cbr     .word ?
        .endv

; ---------------------------------------------------------- variables
        .virtual $c000
score   .fill 3                 ; BCD, lowest byte first
hiscores .fill 30               ; 5 x (3 initials, 3 BCD)
txtbuf  .fill 41
cheat   .byte ?
cheatidx .byte ?
startzone .byte ?               ; start level (cheat)
musicoff .byte ?
lastkey .byte ?
keytmp  .byte ?
ntsc    .byte ?
endflag .byte ?
; board
board   .fill 81                ; sweet codes: bits 0-2 colour (6 = rainbow), bits 3-4 special, $ff empty
ice     .fill 81                ; ice layers 0..2
mark    .fill 81                ; bit 0 horizontal run, bit 1 vertical run, bit 2 blast, bit 6 activated
newcode .fill 81                ; sweets created by matches
dcode   .fill 81                ; display list per column (index column*9 + row)
dyl     .fill 81                ; display y (16 bit, board lines)
dyh     .fill 81
colmov  .fill 9
cre_cell .fill 16
cre_code .fill 16
ncre    .byte ?
; game state
level   .byte ?
lives   .byte ?
moves   .byte ?
goal    .byte ?
ncol    .byte ?
lscore  .fill 3                 ; level score (BCD)
target  .fill 3
pts20   .word ?                 ; level score / 20
tbin    .byte ?                 ; target / 200
iceleft .byte ?
icetotal .byte ?
cascade .byte ?
cr      .byte ?                 ; cursor row / column
cc      .byte ?
selected .byte ?
reptime .byte ?
idle    .word ?
hint_a  .byte ?
hint_b  .byte ?
sa      .byte ?                 ; swapped cells
sb      .byte ?
swspec  .byte ?
rbcol   .byte ?
rbtime  .byte ?
msgtime .byte ?
meterh  .byte ?
fallv   .byte ?
anyfall .byte ?
pfill   .byte ?
ntscc   .byte ?
aitime  .byte ?
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
        lda #1
        sta $d025
        lda #0
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
        .include "render.asm"
        .include "board.asm"
        .include "game.asm"
        .include "util.asm"
code1_end
        .cerror * > $4000, "code segment 1 overflow ", *

        * = CHARSET
        .binary "../build/charset.bin"
        * = SCRA
        .fill $800, 0
        * = SPRDATA
        .binary "../build/sprites.bin"

        * = $8000
        .include "sound.asm"
        .include "screens.asm"
        .include "../build/music.asm"
        .include "../build/gen_data.asm"
end_of_prg
        .cerror * > $c000, "data segment overflow ", *
        .cerror aitime >= CBL, "variables overlap the column buffers"
