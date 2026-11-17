; =====================================================================
;  Monsters (one at a time, sprite 6) and the bullet (sprite 7)
; =====================================================================

mon_update
        jsr bullet_update
        lda m_t
        bne +
        rts
+       inc m_an
        cmp #M_BLOB
        bne _bat
        lda frame
        and #15
        bne +
        inc m_x
+       cmp #8
        bne _cull
        dec m_x
        jmp _cull
_bat    cmp #M_BAT
        bne _die
        lda m_dx
        bmi _bl
        inc m_x
        lda m_x
        cmp #148
        bcc _cull
        lda #$ff
        sta m_dx
        jmp _cull
_bl     dec m_x
        bne _cull
        lda #1
        sta m_dx
        jmp _cull
_die    cmp #M_DIE
        bne _cull
        lda m_yl
        sec
        sbc #4
        sta m_yl
        bcs _cull
        dec m_yh
_cull   ; below the screen: m_y < cam - 230
        lda m_yl
        clc
        adc #230
        sta tmp0
        lda m_yh
        adc #0
        sta tmp1
        lda tmp0
        cmp caml
        lda tmp1
        sbc camh
        bpl +
        lda #0
        sta m_t
        rts
+       ; ---- the hero
        lda m_t
        cmp #M_DIE
        bcs _r
        lda ps
        cmp #PS_FALL
        bcs _r
        jsr mon_touch
        bcc _r
        lda m_t
        cmp #M_HOLE
        bne _beast
        lda ps
        bne _r                  ; flying past
        lda cheat
        bne _r
        lda #PS_HOLE
        sta ps
        lda #70
        sta dtimer
        lda #SFX_HOLE
        jmp sfx_start
_beast  lda ps
        bne _kill               ; rams it while flying
        lda vyi
        bpl _hurt
        ; stomp if the feet were above the upper part of the monster
        lda m_yl
        clc
        adc #10
        sta tmp0
        lda m_yh
        adc #0
        sta tmp1
        lda yol
        cmp tmp0
        lda yoh
        sbc tmp1
        bmi _hurt
        lda #<JUMPV
        sta vyf
        lda #>JUMPV
        sta vyi
        lda #6
        sta psq
        lda #M_DIE
        sta m_t
        lda #SFX_STOMP
        jmp sfx_start
_hurt   lda cheat
        bne _r
        lda #PS_FALL
        sta ps
        lda #40
        sta dtimer
        lda #0
        sta vyf
        sta vyi
        lda #SFX_FALL
        jmp sfx_start
_kill   lda #M_DIE
        sta m_t
        lda #SFX_KILL
        jmp sfx_start
_r      rts

; does the hero touch the monster?  carry set = yes
mon_touch
        ; x: hero [pxi+2, pxi+9], monster [m_x+1, m_x+10] (hole: +3..+8)
        ldy #1
        lda m_t
        cmp #M_HOLE
        bne +
        ldy #3
+       sty tmp7
        tya
        clc
        adc m_x
        sta tmp5                ; monster left
        lda #11
        sec
        sbc tmp7
        sbc tmp7
        clc
        adc tmp5
        sta tmp6                ; monster right
        jsr feet_overlap
        bcc _no
        ; y: hero [py, py+17], monster [m_y + 1 .. m_y + 18] (hole +5 .. +15)
        lda tmp7
        asl
        clc
        adc m_yl
        sta tmp0
        lda m_yh
        adc #0
        sta tmp1                ; monster bottom
        lda pyl
        clc
        adc #17
        sta tmp3
        lda pyh
        adc #0
        sta tmp4
        lda tmp3
        cmp tmp0
        lda tmp4
        sbc tmp1
        bmi _no
        ; monster top = m_y + 19 - 2*tmp7 ... >= py ?
        lda #19
        sec
        sbc tmp7
        sbc tmp7
        clc
        adc m_yl
        sta tmp0
        lda m_yh
        adc #0
        sta tmp1
        lda tmp0
        cmp pyl
        lda tmp1
        sbc pyh
        bmi _no
        sec
        rts
_no     clc
        rts

bullet_update
        lda b_on
        beq _r
        lda b_yl
        clc
        adc #7
        sta b_yl
        bcc +
        inc b_yh
+       ; above the screen: b_y > cam + 4
        lda caml
        clc
        adc #4
        sta tmp0
        lda camh
        adc #0
        sta tmp1
        lda tmp0
        cmp b_yl
        lda tmp1
        sbc b_yh
        bpl +
        lda #0
        sta b_on
        rts
+       ; hits the monster?
        lda m_t
        beq _r
        cmp #M_DIE
        bcs _r
        lda b_x
        sec
        sbc m_x
        cmp #12
        bcs _r
        ; b_y - m_y in 0..20 ?
        lda b_yl
        sec
        sbc m_yl
        sta tmp0
        lda b_yh
        sbc m_yh
        bne _r
        lda tmp0
        cmp #21
        bcs _r
        lda #0
        sta b_on
        lda m_t
        cmp #M_HOLE
        beq _r                  ; swallowed
        lda #M_DIE
        sta m_t
        lda #SFX_KILL
        jmp sfx_start
_r      rts
