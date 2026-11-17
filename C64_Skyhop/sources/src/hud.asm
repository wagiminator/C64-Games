; =====================================================================
;  Score sprites and the sprite shadow registers
; =====================================================================

; render the score into the two score sprites of the hidden buffer
score_render
        ; digits -> sprtxt (screen codes), leading zeros blank
        ldx #0
        lda score+2
        jsr bcd_two
        lda score+1
        jsr bcd_two
        lda score
        jsr bcd_two
        ldx #0
-       lda sprtxt,x
        bne +
        lda #(32-48)&255
        sta sprtxt,x
        inx
        cpx #5
        bne -
+       ldx #5
-       lda sprtxt,x
        clc
        adc #48
        sta sprtxt,x
        dex
        bpl -
        ; fall through
; render the 6 screen codes in sprtxt into the score sprites of the hidden buffer
text_sprites
        ; target sprite memory: SPRDATA + n * 64
        lda hid
        asl
        clc
        adc #SPR_SCORE-$40
        sta tmp0
        lsr
        lsr
        clc
        adc #>SPRDATA
        sta ptr0+1
        lda tmp0
        and #3
        asl
        asl
        asl
        asl
        asl
        asl
        sta ptr0
        ; 6 digits: sprite 0 holds 0..2, sprite 1 holds 3..5 (at +64)
        ldx #0
_d      lda sprtxt,x
        sta tmp3
        asl
        asl
        asl
        sta ptr1
        lda tmp3
        lsr
        lsr
        lsr
        lsr
        lsr
        clc
        adc #>CHARSET           ; glyph = CHARSET + code * 8
        sta ptr1+1
        ; byte offset: (x mod 3) + 64 * (x / 3)
        txa
        cmp #3
        bcc +
        sbc #3
        clc
        adc #64
+       tay
        sty tmp1
        stx tmp2
        ldx #0
-       txa
        tay
        lda (ptr1),y
        ldy tmp1
        sta (ptr0),y
        lda tmp1
        clc
        adc #3
        sta tmp1
        inx
        cpx #8
        bne -
        ldx tmp2
        inx
        cpx #6
        bne _d
        rts
bcd_two pha
        lsr
        lsr
        lsr
        lsr
        sta sprtxt,x
        inx
        pla
        and #15
        sta sprtxt,x
        inx
        rts

; ---------------------------------------------------- build the sprite shadow for the hidden buffer
mon_ptr  .byte SPR_BLANK, SPR_BLOB, SPR_BAT, SPR_HOLE, SPR_BLANK, SPR_FLAG
mon_col  .byte 0, 4, 11, 0, 0, 2

sprites_build
        lda #0
        sta sxh
        lda #%00000011
        sta sen
        ; score
        lda #28
        sta sx
        lda #52
        sta sx+1
        lda #56
        sta sy
        sta sy+1
        ldy zone
        lda zone_txt,y
        sta sc
        sta sc+1
        sta sc+7
        lda hid
        asl
        clc
        adc #SPR_SCORE
        sta sptr
        adc #1
        sta sptr+1
        ; ---- hero: frame
        lda ps
        cmp #PS_MOON
        beq _stand
        cmp #PS_FALL
        bcs _dead
        cmp #PS_HAT
        beq _hat
        cmp #PS_JET
        beq _jet
        lda pshoot
        beq +
        lda #SPR_HERO_R7        ; shooting faces the viewer
        jmp _ptr
+
_stand  ldx #0
        lda psq
        beq +
        ldx #1
+       txa
        jmp _dir
_hat    lda frame
        lsr
        and #1
        clc
        adc #2
        jmp _dir
_jet    lda frame
        lsr
        and #1
        clc
        adc #4
        jmp _dir
_dead   lda #6
_dir    asl
        clc
        adc #SPR_HERO_R0
        ldx pface
        beq _ptr
        clc
        adc #SPR_HERO_L0-SPR_HERO_R0
_ptr    sta sptr+2
        clc
        adc #1
        sta sptr+3
        sta sptr+5
        lda sptr+2
        sta sptr+4
        lda #0
        sta sc+2
        sta sc+4
        lda #7
        sta sc+3
        sta sc+5
        ; y = SPRY + cam - py
        lda #SPRY
        clc
        adc caml
        sta tmp0
        lda camh
        adc #0
        sta tmp1
        lda tmp0
        sec
        sbc pyl
        sta tmp0
        lda tmp1
        sbc pyh
        bne _nohero
        lda tmp0
        sta sy+2
        sta sy+3
        sta sy+4
        sta sy+5
        ; x = pxi * 2 + 24
        lda pxi
        asl
        sta tmp0
        lda #0
        rol
        sta tmp1
        lda tmp0
        clc
        adc #24
        sta sx+2
        sta sx+3
        lda tmp1
        adc #0
        beq +
        lda sxh
        ora #%00001100
        sta sxh
+       lda sen
        ora #%00001100
        sta sen
        ; ghost on the left edge while wrapping around
        lda pxi
        cmp #149
        bcc _nohero
        asl
        sec
        sbc #<296
        sta sx+4
        sta sx+5
        lda sen
        ora #%00110000
        sta sen
_nohero
        ; ---- monster
        lda m_t
        bne +
        jmp _nomon
+       ldy m_kind
        cmp #M_FLAG
        bne +
        tay
+       lda mon_ptr,y
        cpy #M_FLAG
        beq _mp
        sta tmp0
        lda m_an
        cpy #M_HOLE
        bne +
        asl
+       and #8
        beq +
        inc tmp0
+       lda tmp0
_mp     sta sptr+6
        lda mon_col,y
        sta sc+6
        lda #SPRY
        clc
        adc caml
        sta tmp0
        lda camh
        adc #0
        sta tmp1
        lda tmp0
        sec
        sbc m_yl
        sta tmp0
        lda tmp1
        sbc m_yh
        bne _nomon
        lda tmp0
        sta sy+6
        lda m_x
        asl
        sta tmp0
        lda #0
        rol
        sta tmp1
        lda tmp0
        clc
        adc #24
        sta sx+6
        lda tmp1
        adc #0
        beq +
        lda sxh
        ora #%01000000
        sta sxh
+       lda sen
        ora #%01000000
        sta sen
_nomon
        ; ---- bullet: y = cam + 54 - b_y
        lda b_on
        beq _nob
        lda #SPR_BULLET
        sta sptr+7
        lda caml
        clc
        adc #54
        sta tmp0
        lda camh
        adc #0
        sta tmp1
        lda tmp0
        sec
        sbc b_yl
        sta tmp0
        lda tmp1
        sbc b_yh
        bne _nob
        lda tmp0
        sta sy+7
        lda b_x
        asl
        sta tmp0
        lda #0
        rol
        sta tmp1
        lda tmp0
        clc
        adc #24
        sta sx+7
        lda tmp1
        adc #0
        beq +
        lda sxh
        ora #%10000000
        sta sxh
+       lda sen
        ora #%10000000
        sta sen
_nob
        ; ---- pointers into the hidden screen
        lda hid
        bne +
        ldx #7
-       lda sptr,x
        sta SCRA+$3f8,x
        dex
        bpl -
        rts
+       ldx #7
-       lda sptr,x
        sta SCRB+$3f8,x
        dex
        bpl -
        rts
