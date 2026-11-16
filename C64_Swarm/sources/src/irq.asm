; =====================================================================
;  IRQ: one raster interrupt per frame (line 250) - music, sfx, stars
; =====================================================================
irq_simple_on
        sei
        lda #<irq_simple
        sta $fffe
        lda #>irq_simple
        sta $ffff
        lda $d011
        and #$7f
        sta $d011
        lda #250
        sta $d012
        lda #1
        sta $d01a
        asl $d019
        cli
        rts

irq_simple
        pha
        txa
        pha
        tya
        pha
        cld
        asl $d019
        lda #$18
        sta $d016
        lda #D018A
        sta $d018
        lda starmove
        beq +
        jsr bg_rotate
+       inc frame
        cli
        jsr music_play
        jsr sfx_play
        pla
        tay
        pla
        tax
        pla
        rti

; wait for next frame
waitframe
        lda frame
-       cmp frame
        beq -
        rts

bittab  .byte 1,2,4,8,16,32,64,128
nbittab .byte $fe,$fd,$fb,$f7,$ef,$df,$bf,$7f

; ---------------------------------------------------- star pattern rotation
bg_rotate
        ldx #3
_lp     lda pacc_l,x
        clc
        adc pat_speed,x
        sta pacc_l,x
        lda pacc_h,x
        adc #0
        sta pacc_h,x
        lda #0
        sec
        sbc pacc_h,x
        and #15
        sec
        sbc prot,x
        and #15
        beq _next
        stx bgsave
        cmp #8
        bcs _left
        lda prot,x
        clc
        adc #1
        and #15
        sta prot,x
        lda rotr_lo,x
        sta ijvec
        lda rotr_hi,x
        sta ijvec+1
        jmp _go
_left   lda prot,x
        sec
        sbc #1
        and #15
        sta prot,x
        lda rotl_lo,x
        sta ijvec
        lda rotl_hi,x
        sta ijvec+1
_go     jsr _jmp
        ldx bgsave
_next   dex
        bpl _lp
        rts
_jmp    jmp (ijvec)

rotr_lo .byte <rotr0,<rotr1,<rotr2,<rotr3
rotr_hi .byte >rotr0,>rotr1,>rotr2,>rotr3
rotl_lo .byte <rotl0,<rotl1,<rotl2,<rotl3
rotl_hi .byte >rotl0,>rotl1,>rotl2,>rotl3

rotr    .macro base
        .for row := 0, row < 8, row += 1
        lda \base+8+row
        lsr
        ror \base+row
        ror \base+8+row
        .next
        rts
        .endm
rotl    .macro base
        .for row := 0, row < 8, row += 1
        lda \base+row
        asl
        rol \base+8+row
        rol \base+row
        .next
        rts
        .endm
PATC    = CHARSET + CH_BG*8
rotr0   #rotr PATC+0*16
rotr1   #rotr PATC+1*16
rotr2   #rotr PATC+2*16
rotr3   #rotr PATC+3*16
rotl0   #rotl PATC+0*16
rotl1   #rotl PATC+1*16
rotl2   #rotl PATC+2*16
rotl3   #rotl PATC+3*16
