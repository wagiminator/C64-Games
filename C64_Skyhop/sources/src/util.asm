; =====================================================================
;  Utilities
; =====================================================================

print   .macro text, col, row, color
        lda #<\text
        sta ptr0
        lda #>\text
        sta ptr0+1
        lda #\col
        sta tmp0
        lda #\row
        sta tmp1
        lda #\color
        sta tmp2
        jsr print_at
        .endm

; ptr0 = zero terminated text, tmp0 = col, tmp1 = row, tmp2 = colour
print_at
        ldy tmp1
        lda rowlo,y
        clc
        adc tmp0
        sta ptr1
        sta ptr2
        lda rowhiA,y
        adc #0
        sta ptr1+1
        lda rowlo,y
        clc
        adc tmp0
        lda rowhiC,y
        adc #0
        sta ptr2+1
        ldy #0
-       lda (ptr0),y
        beq +
        sta (ptr1),y
        lda tmp2
        sta (ptr2),y
        iny
        bne -
+       rts

; print centred: ptr0 = text, tmp1 = row, tmp2 = colour
print_centre
        ldy #0
-       lda (ptr0),y
        beq +
        iny
        bne -
+       tya
        lsr
        sta tmp0
        lda #20
        sec
        sbc tmp0
        sta tmp0
        jmp print_at

; clear screen A (all 25 rows) with spaces, colour A
clear_screen
        ldx #0
-       sta COLRAM,x
        sta COLRAM+256,x
        sta COLRAM+512,x
        sta COLRAM+768-24,x
        pha
        lda #32
        sta SCRA,x
        sta SCRA+256,x
        sta SCRA+512,x
        sta SCRA+768-24,x
        pla
        inx
        bne -
        rts

; ---------------------------------------------------- joystick (port 2) -> A active high
DBGJOY = $03fe
joyread
        lda $dc00
        eor #$ff
        and #$1f
        ora DBGJOY
        rts

; ---------------------------------------------------- random (16 bit LFSR)
rnd     lda rndseed
        asl
        rol rndseed2
        bcc +
        eor #$2d
+       sta rndseed
        eor rndseed2
        rts

; ---------------------------------------------------- score (BCD)
; add A (binary, 0..255) points
score_addbin
        tax
        beq _r
        sed
-       lda score
        clc
        adc #1
        sta score
        lda score+1
        adc #0
        sta score+1
        lda score+2
        adc #0
        sta score+2
        dex
        bne -
        cld
_r      rts

; ---------------------------------------------------- 16/8 division
; tmp0/tmp1 = dividend, tmp2 = divisor -> tmp0/tmp1 = quotient
div16_8
        lda #0
        ldy #16
-       asl tmp0
        rol tmp1
        rol
        bcs +
        cmp tmp2
        bcc ++
+       sbc tmp2
        inc tmp0
+       dey
        bne -
        rts

; ---------------------------------------------------- keyboard
; A = keycode (col*8+row) -> A = 1 if pressed else 0  (preserves Y)
keytest
        sta keytmp
        lsr
        lsr
        lsr
        tax
        lda colsel,x
        sta $dc00
        lda keytmp
        and #7
        tax
        lda $dc01
        and bittab,x
        ldx #$ff
        stx $dc00
        cmp #1
        lda #0
        bcs +
        lda #1
+       rts
colsel  .byte $fe,$fd,$fb,$f7,$ef,$df,$bf,$7f

; full scan -> A = keycode of first pressed key or $ff
scan_key
        ldx #0
-       lda colsel,x
        sta $dc00
        lda $dc01
        cmp #$ff
        bne +
        inx
        cpx #8
        bne -
        lda #$ff
        sta $dc00
        rts
+       ldy #0
-       lsr
        bcc +
        iny
        bne -
+       sty tmp0
        txa
        asl
        asl
        asl
        ora tmp0
        ldx #$ff
        stx $dc00
        rts

; ---------------------------------------------------- hiscores
init_hiscores
        ldx #5*6-1
-       lda hs_default,x
        sta hiscores,x
        dex
        bpl -
        rts
hs_default
        .text "HOP"
        .byte $00,$00,$03
        .text "SKY"
        .byte $00,$00,$02
        .text "CLD"
        .byte $00,$00,$01
        .text "C64"
        .byte $00,$50,$00
        .text "UPS"
        .byte $00,$20,$00
bittab  .byte 1,2,4,8,16,32,64,128
