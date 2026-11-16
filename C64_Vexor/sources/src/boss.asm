; =====================================================================
;  End-of-level bosses (vertical: boss hovers at the top)
; =====================================================================

boss_trigger
        lda #1
        sta stagestate
        lda #70
        sta stagetimer
        lda #0
        sta stagetimer+1
        lda #TUNE_BOSS
        jmp music_start

boss_spawn
        lda #1
        sta b_on
        sta hudflag
        sta b_vx
        lda #0
        sta b_xh
        lda #136
        sta b_xl
        lda #0
        sta b_y
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

boss_hp   .byte 70,90,110,130,170
boss_col  .byte 9,4,12,2,5
boss_base .byte SPR_BOSS1,SPR_BOSS2,SPR_BOSS3,SPR_BOSS4,SPR_BOSS5
boss_alt  .byte SPR_BOSSALT1,SPR_BOSSALT2,SPR_BOSSALT3,SPR_BOSSALT4,SPR_BOSSALT5

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
        inc b_dead
        lda b_dead
        and #3
        bne _nx
        jsr rnd
        and #63
        clc
        adc b_xl
        sta tmp0
        lda #0
        adc #0
        sta tmp1
        jsr rnd
        and #63
        clc
        adc b_y
        sta tmp2
        lda b_dead
        and #4
        beq +
        jsr spawn_explosion
        jmp _nx
+       lda #1
        jsr spawn_bubble
_nx     lda b_dead
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
        ; entering from the top
        inc b_y
        lda b_y
        cmp #58
        bne _ctr
        lda #1
        sta b_state
        lda #0
        sta b_t
        beq _ctr
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
        clc
        adc #18
        sta b_cx2
        rts
_call   jmp (jvec)

boss_beh .word boss1, boss2, boss3, boss4, boss5

; x = 136 + sin(A) * 1.5 (range ~64..208)
boss_sine_x
        tay
        lda sintab,y
        sta tmp0
        cmp #$80
        ror
        clc
        adc tmp0
        clc
        adc #136
        sta b_xl
        rts

; y = 58 + sin(A)/4
boss_bob_y
        tay
        lda sintab,y
        cmp #$80
        ror
        cmp #$80
        ror
        clc
        adc #58
        sta b_y
        rts

; boss bullet, angle A ($ff = aimed), x offset in b_shots (from boss x)
boss_shot
        sta tmp6
        lda b_xl
        clc
        adc b_shots
        sta tmp0
        lda #0
        adc #0
        sta tmp1
        lda b_y
        clc
        adc #48
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
        lda tmp0
        lsr
        clc
        adc #6
        sta tmp0
        lda b_y
        clc
        adc #58
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
boss_speed .byte 1,1,2,2,3

boss_ring
        lda #24
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

; ---- GORLOX: wide sweep, 3-way spread
boss1
        lda b_t
        jsr boss_sine_x
        lda b_t
        and #63
        bne _r
        lda #24
        sta b_shots
        lda #16
        jsr boss_shot
        lda #12
        jsr boss_shot
        lda #20
        jsr boss_shot
_r      rts

; ---- MEDUSOID: sweep + bob, aimed bursts
boss2
        lda b_t
        asl
        jsr boss_sine_x
        lda b_t
        asl
        asl
        jsr boss_bob_y
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
        lda #24
        sta b_shots
        lda #$ff
        jmp boss_shot
_r      rts

; ---- SKULLMECH: tracks the player, triple cannons
boss3
        lda pcx2
        asl
        sec
        sbc #36
        bcs +
        lda #0
+       cmp #208
        bcc +
        lda #208
+       cmp b_xl
        beq _f
        bcc +
        inc b_xl
        jmp _f
+       dec b_xl
_f      lda b_t
        and #15
        bne _r
        inc b_t2
        lda b_t2
        cmp #3
        bcc +
        lda #0
        sta b_t2
+       tax
        lda cannon_x,x
        sta b_shots
        lda #16
        jsr boss_shot
        lda b_t
        and #127
        bne _r
        lda #E_SWOOP
        sta tmp0
        lda #3
        sta tmp1
        lda #100
        sta tmp2
        lda #0
        sta tmp3
        jmp spawn_event
_r      rts
cannon_x .byte 6,24,42

; ---- PLASMA EYE: figure eight, rotating rings
boss4
        lda b_t
        jsr boss_sine_x
        lda b_t
        asl
        jsr boss_bob_y
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
        lda #24
        sta b_shots
        lda #$ff
        jmp boss_shot
_r      rts

; ---- MOTHER WORM: rings, aimed shots, summons risers
boss5
        lda b_t
        jsr boss_sine_x
        lda b_t
        and #127
        bne +
        jsr boss_ring
        jmp _c
+       and #31
        bne _c
        lda #24
        sta b_shots
        lda #$ff
        jsr boss_shot
_c      lda b_t
        bne +
        lda #E_RISER
        sta tmp0
        lda #2
        sta tmp1
        lda #100
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
        ldx level
        lda boss_score,x
        tax
        lda #0
        jsr score_add
        lda #SFX_BIGEXPLO
        jmp sfx_start
_r      rts
boss_score .byte $10,$15,$20,$30,$50

boss_collisions
        lda b_on
        bne +
        rts
+       lda b_dead
        beq +
        rts
+       lda b_cx2
        sec
        sbc #16
        sta cx0
        clc
        adc #32
        sta cx1
        lda b_y
        clc
        adc #4
        sta cy0
        adc #54
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
        lda pb_t,y
        cmp #B_LASER
        beq _las
        lda #0
        sta pb_t,y
        sta pb_x1,y
        lda pb_dmg,y
        sty tmp6
        jsr boss_damage
        ldy tmp6
        jmp _pn
_las    lda frame
        and #3
        bne _pn
        sty tmp6
        lda #2
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
        lda b_y
        clc
        adc #31
        jsr absdiff
        cmp #28
        bcs _r
        lda #4
        jmp damage_player
_r      rts

boss_sprites
        lda b_on
        bne +
        rts
+       lda b_dead
        beq +
        lda frame
        and #2
        beq +
        rts
+       ldy level
        lda boss_base,y
        sta tmp0
        lda boss_alt,y
        sta tmp3
        lda boss_col,y
        ldx b_fl
        beq +
        lda #1
+       sta tmp1
        ldx nactive
        ldy #0
_lp     lda b_y
        clc
        adc boss_ry,y
        cmp #34
        bcc _skip
        sta cy,x
        lda b_xl
        clc
        adc boss_rx,y
        sta cxl,x
        lda #0
        adc #0
        sta cxh,x
        tya
        clc
        adc tmp0
        sta tmp2
        lda b_alt
        beq _np
        cpy #3
        bcc _np
        cpy #6
        bcs _np
        tya
        sec
        sbc #3
        clc
        adc tmp3
        sta tmp2
_np     lda tmp2
        sta cp,x
        lda tmp1
        sta cc,x
        inx
_skip   iny
        cpy #9
        bne _lp
        stx nactive
        rts
boss_rx .byte 0,24,48,0,24,48,0,24,48
boss_ry .byte 0,0,0,21,21,21,42,42,42
