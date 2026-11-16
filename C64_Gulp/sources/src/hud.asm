; =====================================================================
;  HUD: row 0 score / lives / level, row 1 growth bar + messages
; =====================================================================
barcol  .byte 5,7,2

hud_static
        #print t_hscore, 0, 0, 3
        #print t_hlevel, 29, 0, 3
        #print t_hsize, 0, 1, 3
        lda #CH_LIFE
        sta SCRA+16
        lda #7
        sta COLRAM+16
        lda #24                 ; 'X'
        sta SCRA+17
        lda #1
        sta COLRAM+17
        sta hudflag
        sta barflag
        rts
t_hscore .null "SCORE"
t_hlevel .null "LEVEL"
t_hsize .null "SIZE"

put_bcd pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRA,y
        lda #1
        sta COLRAM,y
        iny
        pla
        and #15
        ora #48
        sta SCRA,y
        lda #1
        sta COLRAM,y
        iny
        rts

hud_update
        lda hudflag
        beq _bar
        lda #0
        sta hudflag
        ldy #6
        lda score+2
        jsr put_bcd
        lda score+1
        jsr put_bcd
        lda score
        jsr put_bcd
        lda #48
        sta SCRA,y
        lda #1
        sta COLRAM,y
        lda lives
        ora #48
        sta SCRA+18
        lda #1
        sta COLRAM+18
        lda zone
        clc
        adc #49
        sta SCRA+35
        lda #45
        sta SCRA+36
        lda lvl
        clc
        adc #49
        cmp #51
        bne +
        lda #2                  ; 'B'
+       sta SCRA+37
        lda #1
        sta COLRAM+35
        sta COLRAM+36
        sta COLRAM+37
_bar    lda power
        beq +
        lda frame
        and #7
        bne +
        lda #1
        sta barflag
+       lda barflag
        bne +
        rts
+       lda #0
        sta barflag
        ; ---- quarters 0..80
        lda power
        beq _g
        lsr
        lsr
        sta tmp0
        lsr
        lsr
        clc
        adc tmp0                ; power * 5/16 (0..62)
        adc #18
        jmp _q
_g      lda lvl
        cmp #2
        bne _n
        ; boss level: progress from t3 to goal
        lda growth
        sec
        sbc g_t3
        bcs +
        lda #0
+       sta tmp0
        lda g_goal
        sec
        sbc g_t3
        sta tmp2
        jmp _div
_n      lda growth
        sta tmp0
        lda g_goal
        sta tmp2
_div    lda #0
        sta tmp1
        lda tmp0
        asl
        rol tmp1
        asl
        rol tmp1
        asl
        rol tmp1
        asl
        rol tmp1
        sta tmp0                ; *16
        ldx tmp1
        asl
        rol tmp1
        asl
        rol tmp1
        clc
        adc tmp0
        sta tmp0
        txa
        adc tmp1
        sta tmp1                ; *80
        jsr div16_8
        lda tmp1
        beq +
        lda #80
        bne _q
+       lda tmp0
        cmp #80
        bcc _q
        lda #80
_q      sta tmp0
        ldy psize
        lda barcol,y
        ldy power
        beq +
        lda #7
+       sta tmp1
        ldx #0
-       lda tmp0
        cmp #4
        bcc _p
        sbc #4
        sta tmp0
        lda #CH_BAR+4
        jmp _s
_p      clc
        adc #CH_BAR
        ldy #0
        sty tmp0
_s      sta SCRA+40+5,x
        lda tmp1
        sta COLRAM+40+5,x
        inx
        cpx #20
        bne -
        ; ---- message / frenzy area (cols 26..39)
        lda msg_t
        bne _r
        ldx #13
        lda #32
-       sta SCRA+40+26,x
        dex
        bpl -
        lda mult
        cmp #2
        bcc _r
        #print t_frenzy, 27, 1, 7
        lda mult
        ora #48
        sta SCRA+40+36
_r      rts
t_frenzy .null "FRENZY X"

; A/X = text -> message in row 1 for 2 seconds
show_msg
        sta ptr0
        stx ptr0+1
        ldx #13
        lda #32
-       sta SCRA+40+26,x
        dex
        bpl -
        lda #27
        sta tmp0
        lda #1
        sta tmp1
        lda #7
        sta tmp2
        jsr print_at
        lda #100
        sta msg_t
        rts
