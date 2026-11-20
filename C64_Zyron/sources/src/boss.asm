; =====================================================================
;  End-of-level bosses
; =====================================================================

boss_trigger
        lda #1
        sta stagestate
        lda #70
        sta stagetimer
        lda #0
        sta stagetimer+1
        lda #TUNE_BOSS
        jsr music_start
        rts

boss_spawn
        lda #1
        sta b_on
        sta hudflag
        lda #1
        sta b_xh
        lda #88
        sta b_xl
        lda #66
        sta b_y
        lda #0
        sta b_state
        sta b_t
        sta b_t2
        sta b_fl
        sta b_alt
        sta b_dead
        sta b_ang
        ldx level
        lda boss_hp,x
        sta b_hp
        sta b_maxhp
        rts

boss_hp   .byte 60,80,100,120,140,180
boss_col  .byte 8,4,3,2,12,5
boss_base .byte SPR_BOSS1,SPR_BOSS2,SPR_BOSS3,SPR_BOSS4,SPR_BOSS5,SPR_BOSS6
boss_alt  .byte SPR_BOSSALT1,SPR_BOSSALT2,SPR_BOSSALT3,SPR_BOSSALT4,SPR_BOSSALT5,SPR_BOSSALT6

update_boss
        lda b_on
        bne +
        rts
+       inc b_t
        lda b_fl
        beq +
        dec b_fl
+       lda b_dead
        beq _alive
        ; ---- dying
        inc b_dead
        lda b_dead
        and #3
        bne +
        jsr rnd
        and #63
        clc
        adc b_xl
        sta tmp0
        lda b_xh
        adc #0
        sta tmp1
        jsr rnd
        and #63
        clc
        adc b_y
        sta tmp2
        jsr spawn_explosion
        lda b_dead
        and #15
        bne +
        lda #SFX_BIGEXPLO
        jsr sfx_start
+       lda b_dead
        cmp #120
        bne +
        lda #0
        sta b_on
        jsr stage_clear
+       rts
_alive  lda b_state
        bne _act
        ; ---- entering
        lda b_xl
        sec
        sbc #1
        sta b_xl
        lda b_xh
        sbc #0
        sta b_xh
        bne _ctr
        lda b_xl
        cmp #224
        bne _ctr
        lda #1
        sta b_state
        lda #0
        sta b_t
        jmp _ctr
_act    lda level
        asl
        tax
        lda boss_beh,x
        sta jvec
        lda boss_beh+1,x
        sta jvec+1
        jsr _call
_ctr    lda b_xl
        lsr
        ldx b_xh
        beq +
        ora #$80
+       clc
        adc #18
        sta b_cx2
        rts
_call   jmp (jvec)

boss_beh .word boss1, boss2, boss3, boss4, boss5, boss6

; y = 66 + sin(A) * 0.75  (range ~ 30..102 for top)
boss_sine_y
        tay
        lda sintab,y
        cmp #$80
        ror
        sta tmp0
        cmp #$80
        ror
        clc
        adc tmp0
        clc
        adc #74
        sta b_y
        rts

; spawn boss bullet with angle A (aim if A=$ff), y offset tmp3
boss_shot
        sta tmp6
        lda b_xl
        clc
        adc #4
        sta tmp0
        lda b_xh
        adc #0
        sta tmp1
        lda b_y
        clc
        adc b_shots
        sta tmp2
        lda tmp6
        cmp #$ff
        bne +
        lda tmp0
        pha
        lda tmp1
        pha
        lda tmp2
        pha
        lda b_cx2
        sec
        sbc #16
        sta tmp0
        lda b_y
        clc
        adc b_shots
        adc #10
        sta tmp1
        jsr aim
        sta tmp6
        pla
        sta tmp2
        pla
        sta tmp1
        pla
        sta tmp0
        lda tmp6
+       ldy level
        ldx boss_speed,y
        jmp spawn_eb
boss_speed .byte 1,1,2,2,3,3

boss_ring
        lda #21
        sta b_shots
        lda #0
        sta tmp7
-       lda tmp7
        clc
        adc b_ang
        and #63
        jsr boss_shot
        lda tmp7
        clc
        adc #8
        sta tmp7
        cmp #64
        bne -
        lda b_ang
        clc
        adc #3
        sta b_ang
        rts

; ---- GORGAX: vertical sine, 3-way spread
boss1
        lda b_t
        jsr boss_sine_y
        lda b_t
        and #63
        bne _r
        lda #21
        sta b_shots
        lda #$ff
        jsr boss_shot
        lda tmp6
        sec
        sbc #4
        and #63
        pha
        jsr boss_shot
        pla
        clc
        adc #8
        and #63
        jsr boss_shot
_r      rts

; ---- OCULUS: figure eight, aimed bursts, blinking eye
boss2
        lda b_t
        tay
        lda sintab,y
        cmp #$80
        ror
        clc
        adc #216
        sta b_xl
        lda b_t
        asl
        jsr boss_sine_y
        lda b_t
        and #127
        cmp #110
        lda #0
        bcc +
        lda #1
+       sta b_alt
        lda b_t
        and #63
        cmp #24
        bcs _r
        and #7
        bne _r
        lda #21
        sta b_shots
        lda #$ff
        jmp boss_shot
_r      rts

; ---- CRYOSTAR: slow sine, rotating rings
boss3
        lda b_t
        lsr
        jsr boss_sine_y
        lda b_t
        and #127
        cmp #64
        lda #0
        bcs +
        lda #1
+       sta b_alt
        lda b_t
        and #63
        bne +
        jmp boss_ring
+       cmp #32
        bne _r
        lda #21
        sta b_shots
        lda #$ff
        jmp boss_shot
_r      rts

; ---- MAGMAWYRM: tracks player, dashes forward
boss4
        lda b_state
        cmp #2
        beq _dash
        cmp #3
        beq _back
        lda pcy
        sec
        sbc #31
        cmp #30
        bcs +
        lda #30
+       cmp #104
        bcc +
        lda #104
+       cmp b_y
        beq _f
        bcc +
        inc b_y
        jmp _f
+       dec b_y
_f      lda b_t
        and #31
        bne +
        lda #14
        sta b_shots
        lda #$ff
        jsr boss_shot
        lda #28
        sta b_shots
        lda #$ff
        jsr boss_shot
+       lda b_t
        bne _r
        lda #2
        sta b_state
        lda #1
        sta b_alt
_r      rts
_dash   lda b_xl
        sec
        sbc #3
        sta b_xl
        cmp #110
        bcs _r
        lda #3
        sta b_state
        rts
_back   lda b_xl
        clc
        adc #2
        sta b_xl
        cmp #224
        bcc _r
        lda #224
        sta b_xl
        lda #1
        sta b_state
        lda #0
        sta b_alt
        rts

; ---- DREADNOUGHT: three cannons + drone launcher
boss5
        lda b_t
        lsr
        jsr boss_sine_y
        lda b_t
        and #15
        bne _nc
        inc b_t2
        lda b_t2
        cmp #3
        bcc +
        lda #0
        sta b_t2
+       tax
        lda cannon_y,x
        sta b_shots
        lda #32
        jsr boss_shot
_nc     lda b_t
        and #127
        bne +
        lda b_t
        bne +
        lda #E_DRONE
        sta tmp0
        lda #3
        sta tmp1
        lda #80
        sta tmp2
        lda #1
        sta tmp3
        jsr spawn_event
+       lda b_t
        cmp #200
        lda #0
        bcc +
        lda #1
+       sta b_alt
        rts
cannon_y .byte 6,21,36

; ---- HIVE MOTHER: rings, aimed shots, chasers
boss6
        lda b_t
        jsr boss_sine_y
        lda b_t
        and #127
        bne +
        jsr boss_ring
        jmp _c
+       and #31
        bne _c
        lda #21
        sta b_shots
        lda #$ff
        jsr boss_shot
_c      lda b_t
        bne +
        lda #E_CHASER
        sta tmp0
        lda #2
        sta tmp1
        lda #90
        sta tmp2
        lda #0
        sta tmp3
        jsr spawn_event
+       lda b_t
        and #64
        beq +
        lda #1
+       sta b_alt
        rts

; ---------------------------------------------------- damage / collisions
boss_damage
        ldy b_dead
        bne _r
        ldy b_state
        beq _r
        sta tmp0
        lda b_hp
        sec
        sbc tmp0
        sta b_hp
        beq _die
        bcc _die
        lda #2
        sta b_fl
        lda frame
        and #7
        bne +
        lda #1
        sta hudflag
+       lda #SFX_HIT
        jmp sfx_start
_die    lda #0
        sta b_hp
        lda #1
        sta b_dead
        sta hudflag
        ldx #N_EB-1
        lda #0
-       sta eb_on,x
        dex
        bpl -
        lda #$00
        ldx level
        lda boss_score,x
        tax
        lda #0
        jsr score_add
        lda #SFX_BIGEXPLO
        jmp sfx_start
_r      rts
boss_score .byte $10,$15,$20,$25,$30,$50

boss_collisions
        lda b_on
        bne +
        rts
+       lda b_dead
        beq +
        rts
+       lda b_y
        clc
        adc #31
        sta tmp4
        lda b_cx2
        sec
        sbc #16
        sta cx0
        clc
        adc #32
        sta cx1
        lda b_y
        clc
        adc #3
        sta cy0
        adc #56
        sta cy1
        ldy #N_PB-1
_pl     lda pb_x1,y
        cmp cx0
        bcc _pn
        beq _pn
        lda cx1
        cmp pb_x0,y
        bcc _pn
        beq _pn
        lda pb_y1,y
        cmp cy0
        bcc _pn
        beq _pn
        lda cy1
        cmp pb_y0,y
        bcc _pn
        beq _pn
        ; hit
        lda pb_t,y
        cmp #B_CHARGE
        beq _ch
        lda #0
        sta pb_t,y
        sta pb_x1,y
        lda pb_dmg,y
        sty tmp6
        jsr boss_damage
        ldy tmp6
        jmp _pn
_ch     lda frame
        and #3
        bne _pn
        sty tmp6
        lda #3
        jsr boss_damage
        ldy tmp6
_pn     dey
        bpl _pl
        ; player contact
        lda pstate
        bne _r
        lda pcx2
        sta tmp0
        lda b_cx2
        jsr absdiff
        cmp #17
        bcs _r
        lda pcy
        sta tmp0
        lda tmp4
        jsr absdiff
        cmp #28
        bcs _r
        jmp kill_player
_r      rts

boss_sprites                    ; X = cbase + ID_BOSS: the 9 parts (Y $ff = not shown)
        lda b_on
        beq _off
        lda b_dead
        beq +
        lda frame
        and #2
        bne _off
+       ldy level
        lda boss_base,y
        sta tmp0
        lda boss_col,y
        ldy b_fl
        beq +
        lda #1
+       sta tmp1
        ldy #0
_lp     lda b_xl
        clc
        adc boss_rx,y
        sta cxl,x
        lda b_xh
        adc #0
        sta cxh,x
        beq +
        lda cxl,x
        cmp #88
        bcs _skip
+       lda b_y
        clc
        adc boss_ry,y
        sta cy,x
        tya
        adc tmp0                ; (C = 0)
        sta cp,x
        lda tmp1
        sta cc,x
        inx
        iny
        cpy #9
        bne _lp
        beq _alt
_skip   lda #$ff
        sta cy,x
        inx
        iny
        cpy #9
        bne _lp
_alt    lda b_alt               ; alternative frames for parts 3 and 4
        beq +
        ldy level
        lda boss_alt,y
        sta cp-6,x
        clc
        adc #1
        sta cp-5,x
+       rts
_off    lda #$ff
        .for i := 0, i < 9, i += 1
        sta cy+i,x
        .next
        rts
boss_rx .byte 0,24,48,0,24,48,0,24,48
boss_ry .byte 0,0,0,21,21,21,42,42,42
