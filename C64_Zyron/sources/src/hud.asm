; =====================================================================
;  HUD (rows 22..24 of screen A)
; =====================================================================
HUDROW = 22
HUD     = SCRA + HUDROW*40
HUDC    = COLRAM + HUDROW*40

draw_hud
        ldx #119
-       lda #32
        sta HUD,x
        lda #3
        sta HUDC,x
        dex
        bpl -
        #print t_score, 1, 22, 3
        #print t_hi, 18, 22, 3
        #print t_stage, 31, 22, 3
        #print t_ships, 1, 23, 3
        #print t_spd, 10, 23, 3
        #print t_beam, 27, 23, 3
        lda #CH_BARL
        sta HUD+40+32
        lda #CH_BARR
        sta HUD+40+39
        ; colours for values
        ldx #6
        lda #1
-       sta HUDC+7,x
        sta HUDC+21,x
        dex
        bpl -
        lda #7
        sta HUDC+37
        sta HUDC+40+7
        sta HUDC+40+14
        ldx #8
-       sta HUDC+40+17,x
        dex
        bpl -
        ; hiscore digits
        ldx #21
        jsr hud_bcd3h
        lda #$ff
        sta r24state
        lda #1
        sta barflag
        rts

t_score .null "SCORE"
t_hi    .null "HI"
t_stage .null "STAGE"
t_ships .null "SHIPS"
t_spd   .null "SPEED"
t_beam  .null "BEAM"

; print BCD score from hiscores[0] at col X (row 22)
hud_bcd3h
        lda hiscores+5
        jsr hud_d2
        lda hiscores+4
        jsr hud_d2
        lda hiscores+3
        jsr hud_d2
        lda #48
        sta HUD,x
        rts
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
        jmp _bar
+       lda #0
        sta hudflag
        ; score
        ldx #7
        lda score+2
        jsr hud_d2
        lda score+1
        jsr hud_d2
        lda score
        jsr hud_d2
        lda #48
        sta HUD,x
        ; stage
        lda level
        clc
        adc #49
        sta HUD+37
        ; ships
        lda lives
        cmp #10
        bcc +
        lda #9
+       ora #48
        sta HUD+40+7
        ; speed
        lda pspeed
        ora #48
        sta HUD+40+16
        lda #7
        sta HUDC+40+16
        ; weapon name
        lda weapon
        asl
        asl
        asl
        tay
        ldx #0
-       lda wnames,y
        sta HUD+40+19,x
        iny
        inx
        cpx #6
        bne -
        lda #32
        ldx wlevel
        cpx #2
        bne +
        lda #43                 ; '+'
+       sta HUD+40+25
        lda #7
        ldx #6
-       sta HUDC+40+19,x
        dex
        bpl -
        ; ---- row 24 state
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
        lda cheat
        bne _st
        ldx #0
_st     cpx r24state
        bne _chg
        cpx #3
        beq +
        jmp _bar
+       jsr boss_bar
        jmp _bar
_chg    stx r24state
        ldx #39
        lda #32
-       sta HUD+80,x
        dex
        bpl -
        lda r24state
        bne +
        jmp _bar
+       cmp #1
        bne +
        #print t_paused, 15, 24, 1
        jmp _bar
+       cmp #2
        bne +
        #print t_clear, 13, 24, 7
        jmp _bar
+       cmp #3
        bne +
        #print t_boss, 1, 24, 2
        lda #CH_BARL
        sta HUD+80+6
        lda #CH_BARR
        sta HUD+80+39
        ldx #33
        lda #2
-       sta HUDC+80+6,x
        dex
        bpl -
        jsr boss_bar
        jmp _bar
+       #print t_cheat, 1, 24, 2
_bar    lda barflag
        beq _r
        lda #0
        sta barflag
        ; charge bar (6 chars, 24 steps)
        lda charge
        lsr
        sta tmp0
        ldx #0
-       lda tmp0
        cmp #4
        bcc +
        lda #4
+       clc
        adc #CH_BAR
        sta HUD+40+33,x
        lda tmp0
        sec
        sbc #4
        bcs +
        lda #0
+       sta tmp0
        inx
        cpx #6
        bne -
        lda #7
        ldy charge
        cpy #CHARGEMAX
        bne +
        lda frame
        and #4
        lsr
        lsr
        tay
        lda flashcol,y
+       ldx #7
-       sta HUDC+40+32,x
        dex
        bpl -
_r      rts

boss_bar
        ; value = hp*128/maxhp -> 32 chars * 4
        lda b_hp
        sta tmp0
        lda #0
        sta tmp1
        ldy #7
-       asl tmp0
        rol tmp1
        dey
        bne -
        lda b_maxhp
        sta tmp2
        jsr div16_8
        ldx #0
-       lda tmp0
        cmp #4
        bcc +
        lda #4
+       clc
        adc #CH_BAR
        sta HUD+80+7,x
        lda tmp0
        sec
        sbc #4
        bcs +
        lda #0
+       sta tmp0
        inx
        cpx #32
        bne -
        rts

flashcol .byte 1,2
wnames  .text "PULSE   LASER   SPREAD  HOMING  "
t_paused .null "- PAUSED -"
t_clear .null "STAGE CLEAR !"
t_cheat .null "INVINCIBLE   (N = NEXT STAGE)"
t_boss  .null "BOSS "
