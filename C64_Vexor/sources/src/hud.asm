; =====================================================================
;  HUD (rows 22..23 of screen A, shown with fixed yscroll below split)
; =====================================================================
HUD     = SCRA + 22*40
HUDC    = COLRAM + 22*40

draw_hud
        ldx #79
-       lda #32
        sta HUD,x
        lda #3
        sta HUDC,x
        dex
        bpl -
        ldx #39
        lda #32
-       sta SCRA+21*40,x
        sta SCRB+21*40,x
        dex
        bpl -
        #print t_score, 0, 22, 3
        #print t_cr, 15, 22, 7
        #print t_ships, 23, 22, 3
        #print t_stage, 32, 22, 3
        #print t_energy, 0, 23, 3
        #print t_pow, 18, 23, 3
        lda #CH_BARL
        sta HUD+40+7
        lda #CH_BARR
        sta HUD+40+16
        ldx #6
        lda #1
-       sta HUDC+6,x
        dex
        bpl -
        ldx #3
        lda #7
-       sta HUDC+17,x
        dex
        bpl -
        lda #7
        sta HUDC+29
        sta HUDC+38
        sta HUDC+40+22
        lda #$ff
        sta r23state
        lda #1
        sta barflag
        rts

t_score  .null "SCORE"
t_cr     .null "$"
t_ships  .null "SHIPS"
t_stage  .null "STAGE"
t_energy .null "ENERGY"
t_pow    .null "POWER"

hud_d2  pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta HUD,x
        inx
        pla
        and #15
        ora #48
        sta HUD,x
        inx
        rts

update_hud
        lda hudflag
        bne +
        jmp _r
+       lda #0
        sta hudflag
        ldx #6
        lda score+2
        jsr hud_d2
        lda score+1
        jsr hud_d2
        lda score
        jsr hud_d2
        lda #48
        sta HUD,x
        ldx #17
        lda credits+1
        jsr hud_d2
        lda credits
        jsr hud_d2
        lda lives
        cmp #10
        bcc +
        lda #9
+       ora #48
        sta HUD+29
        lda level
        clc
        adc #49
        sta HUD+38
        lda mainpow
        ldx novatime
        beq +
        lda #4
+       ora #48
        sta HUD+40+24
        lda #7
        sta HUDC+40+24
        ; ---- energy bar (8 chars, 32 steps)
        lda energy
        sta tmp0
        ldx #0
-       lda tmp0
        cmp #4
        bcc +
        lda #4
+       clc
        adc #CH_BAR
        sta HUD+40+8,x
        lda tmp0
        sec
        sbc #4
        bcs +
        lda #0
+       sta tmp0
        inx
        cpx #8
        bne -
        ldy #5
        lda energy
        cmp #9
        bcs +
        ldy #2
+       tya
        ldx #9
-       sta HUDC+40+7,x
        dex
        bpl -
        ; ---- right part of row 23
        ldx #1
        lda paused
        bne _st
        inx
        lda stagestate
        cmp #2
        beq _st
        inx
        lda b_on
        bne _st
        inx
        lda novatime
        bne _st
        inx
        lda cheat
        bne _st
        ldx #0
_st     cpx r23state
        bne _chg
        cpx #3
        beq +
        rts
+       jmp boss_bar
_chg    stx r23state
        ldx #12
        lda #32
-       sta HUD+40+27,x
        dex
        bpl -
        lda r23state
        bne +
        rts
+       cmp #1
        bne +
        #print t_paused, 28, 23, 1
        rts
+       cmp #2
        bne +
        #print t_clear, 28, 23, 7
        rts
+       cmp #3
        bne +
        #print t_boss, 27, 23, 2
        lda #CH_BARL
        sta HUD+40+31
        lda #CH_BARR
        sta HUD+40+39
        ldx #8
        lda #2
-       sta HUDC+40+31,x
        dex
        bpl -
        jmp boss_bar
+       cmp #4
        bne +
        #print t_nova, 28, 23, 7
        rts
+       #print t_cheat, 28, 23, 4
_r      rts

boss_bar
        ; hp*28/maxhp -> 7 chars * 4
        lda b_hp
        sta tmp0
        lda #0
        sta tmp1
        ldy #5
-       asl tmp0
        rol tmp1
        dey
        bne -
        lda b_maxhp
        sta tmp2
        jsr div16_8
        lda tmp0
        cmp #29
        bcc +
        lda #28
+       sta tmp0
        ldx #0
-       lda tmp0
        cmp #4
        bcc +
        lda #4
+       clc
        adc #CH_BAR
        sta HUD+40+32,x
        lda tmp0
        sec
        sbc #4
        bcs +
        lda #0
+       sta tmp0
        inx
        cpx #7
        bne -
        rts

t_paused .null "- PAUSED -"
t_clear  .null "STAGE CLEAR"
t_boss   .null "BOSS"
t_nova   .null "NOVA POWER!"
t_cheat  .null "INVINCIBLE"
