; =====================================================================
;  HUD: rows 0..2 of both screens (hires text on black)
;  row 0: TIME  SCORE  STAGE    row 1: SPEED, course progress    row 2: messages
; =====================================================================
hud_init
        ; colours of rows 0..4 (rows 3..4 = empty sky)
        ldx #0
-       lda hudcol,x
        sta COLRAM,x
        inx
        cpx #120
        bne -
        lda #0
-       sta COLRAM,x
        inx
        cpx #200
        bne -
        ldx #39
-       lda hud_r0,x
        sta SCRA,x
        sta SCRB,x
        lda hud_r1,x
        sta SCRA+40,x
        sta SCRB+40,x
        lda #32
        sta SCRA+80,x
        sta SCRB+80,x
        dex
        bpl -
        jsr hud_static
        lda #1
        sta hudflag
        jmp hud_update_both

; stage number
hud_static
        lda leg
        clc
        adc #49
        sta SCRA+35
        sta SCRB+35
        rts

hud_r0  .text " TIME 00   SCORE 0000000     STAGE 1    "
hud_r1  .text " SPEED 000 KM/H  COURSE                 "
hudcol  ; row 0
        .fill 6, 7              ;  TIME
        .fill 2, 1              ; 00
        .fill 3, 0
        .fill 6, 7              ; SCORE
        .fill 7, 1              ; digits
        .fill 5, 0
        .fill 6, 7              ; STAGE
        .fill 5, 1              ; n
        ; row 1
        .fill 7, 7              ;  SPEED
        .fill 3, 1              ; 000
        .fill 5, 3              ;  KM/H
        .fill 2, 0
        .fill 6, 7              ; COURSE
        .fill 1, 0
        .fill 16, 5             ; progress
        ; row 2
        .fill 40, 1

; per frame update (only what changed)
hud_update
        jsr hud_speed
        lda hudflag
        beq +
        jsr hud_update_both
+       ; message timer
        lda msg_t
        beq _r
        cmp #$ff
        beq _r
        dec msg_t
        bne _r
        ldx #39
        lda #32
-       sta SCRA+80,x
        sta SCRB+80,x
        dex
        bpl -
_r      rts

hud_update_both
        lda #0
        sta hudflag
        ; time
        lda time_s
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRA+6
        sta SCRB+6
        lda time_s
        and #15
        ora #48
        sta SCRA+7
        sta SCRB+7
        ; score (6 BCD digits + 0)
        ldx #2
        ldy #17
-       lda score,x
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRA,y
        sta SCRB,y
        iny
        lda score,x
        and #15
        ora #48
        sta SCRA,y
        sta SCRB,y
        iny
        dex
        bpl -
        ; progress bar: posh / 12 (0..15)
        lda posh
        ldx #0
-       cmp #12
        bcc +
        sbc #12
        inx
        bne -
+       cpx #16
        bcc +
        ldx #15
+       stx tmp0
        ldy #0
-       lda #46                 ; '.'
        cpy tmp0
        bne +
        lda #CH_CAR
+       sta SCRA+64,y
        sta SCRB+64,y
        iny
        cpy #16
        bne -
        rts

; speed in km/h = v * 0.83
hud_speed
        lda vh
        sta tmp1
        lda vl
        sta tmp0
        ; v - v/8 - v/32
        lda tmp1
        sta tmp3
        lda tmp0
        lsr tmp3
        ror
        lsr tmp3
        ror
        lsr tmp3
        ror
        sta tmp2                ; v/8
        lda tmp0
        sec
        sbc tmp2
        sta tmp0
        lda tmp1
        sbc tmp3
        sta tmp1
        lda tmp3
        sta tmp5
        lda tmp2
        lsr tmp5
        ror
        lsr tmp5
        ror                     ; v/32
        sta tmp4
        lda tmp0
        sec
        sbc tmp4
        sta tmp0
        lda tmp1
        sbc tmp5
        sta tmp1
        ; 16 bit -> 3 digits
        ldx #48
-       lda tmp0
        sec
        sbc #100
        tay
        lda tmp1
        sbc #0
        bcc +
        sta tmp1
        sty tmp0
        inx
        bne -
+       stx SCRA+47
        stx SCRB+47
        ldx #48
        lda tmp0
-       cmp #10
        bcc +
        sbc #10
        inx
        bne -
+       stx SCRA+48
        stx SCRB+48
        ora #48
        sta SCRA+49
        sta SCRB+49
        rts

; show message A/Y (lo/hi) centred in row 2 for ~3 seconds
msg_set
        sta ptr0
        sty ptr0+1
        ldx #39
        lda #32
-       sta SCRA+80,x
        sta SCRB+80,x
        dex
        bpl -
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
        tax
        ldy #0
-       lda (ptr0),y
        beq +
        sta SCRA+80,x
        sta SCRB+80,x
        inx
        iny
        bne -
+       lda #60
        sta msg_t
        rts
