; =====================================================================
;  Mothership boss: 2 sprites (6,7), X/Y expanded = 96 x 42 pixels
;  bullets use the alien bullet slots 3..5
; =====================================================================
b_hptab   .byte 30,45,60
b_rate    .byte 56,38,30
b_colors  .byte 4,10,14
b_bonus   .byte $05,$10,$15         ; mid BCD byte: 5000 / 10000 / 15000 pts

boss_start
        lda #1
        sta bossmode
        ldx sector
        lda b_hptab,x
        sta b_hp
        sta b_max
        lda #68
        sta b_x
        lda #0
        sta b_y
        sta b_dir
        sta b_fl
        sta b_dead
        sta b_ph
        sta b_cnt
        lda #60
        sta b_t
        lda #$c0
        sta spexp
        txa
        asl
        adc #SPR_BOSS1
        sta spp+6
        adc #1
        sta spp+7
        lda #1
        sta statflag
        sta hudflag
        rts

boss_update
        lda b_dead
        beq +
        jmp boss_dying
+       lda b_hp
        bne +
        rts
+       lda b_ph
        bne _fight
        ; fly in from the top
        inc b_y
        lda b_y
        cmp #72
        bcc _spr
        inc b_ph
        jmp _spr
_fight  ; horizontal patrol, faster when damaged
        jsr _hstep
        lda b_hp
        asl
        cmp b_max
        bcs +
        lda frame
        and #1
        beq +
        jsr _hstep
+       ; vertical bob
        lda frame
        asl
        tax
        lda sintab,x
        cmp #$80
        ror
        cmp #$80
        ror
        cmp #$80
        ror
        clc
        adc #72
        sta b_y
        ; attack
        dec b_t
        bne _spr
        jsr boss_attack
_spr    lda b_x
        sta spx+6
        clc
        adc #24
        sta spx+7
        lda b_y
        sta spy+6
        sta spy+7
        ldx sector
        lda b_colors,x
        ldy b_fl
        beq +
        dec b_fl
        lda #1
+       sta spc+6
        sta spc+7
        rts
_hstep  lda b_dir
        bne _l
        inc b_x
        lda b_x
        cmp #124
        bcc +
        inc b_dir
+       rts
_l      dec b_x
        lda b_x
        cmp #17
        bcs +
        dec b_dir
+       rts

boss_attack
        ldx sector
        lda b_rate,x
        sta b_t
        lda b_hp
        asl
        cmp b_max
        bcs +
        lda b_t
        sec
        sbc #12
        sta b_t
+       inc b_cnt
        lda sector
        beq _s0
        cmp #1
        beq _s1
        ; sector 3: spread, then aimed pair
        lda b_cnt
        and #1
        beq _spread
        jmp _aimed
_s1     lda b_cnt
        and #1
        beq _spread
        jmp _aimed
_s0     lda b_cnt
        and #3
        beq _spread
_aimed  jsr boss_slot
        bcc _r
        jsr aim_vx
        ldy sector
        lda ba_sp,y
        sta eb_sp,x
        lda ba_spf,y
        sta eb_spf,x
        lda #SFX_ESHOT
        jmp sfx_start
_spread lda #$a0
        sta tmp4
        jsr boss_slot
        bcc _r
        lda #$a0
        sta eb_vx,x
        jsr boss_slot
        bcc _r
        lda #0
        sta eb_vx,x
        jsr boss_slot
        bcc _r
        lda #$60
        sta eb_vx,x
        lda #SFX_LASER
        jmp sfx_start
_r      rts

; find free bullet slot, spawn under boss -> X = slot, C=1
boss_slot
        ldx #2
-       lda eb_on,x
        beq +
        dex
        bpl -
        clc
        rts
+       lda b_x
        clc
        adc #18
        sta eb_x,x
        lda b_y
        clc
        adc #34
        sta eb_y,x
        lda #0
        sta eb_vx,x
        sta eb_xf,x
        sta eb_yf,x
        ldy sector
        lda bs_sp,y
        sta eb_sp,x
        lda bs_spf,y
        sta eb_spf,x
        lda #SPR_ABULLET+2
        sta eb_fr,x
        lda #1
        sta eb_on,x
        sec
        rts

; tmp0 = screen x/2, tmp1 = screen y -> C=1 bullet absorbed
boss_hit
        lda b_hp
        beq _no
        lda b_dead
        bne _no
        lda tmp1
        clc
        adc #46
        sec
        sbc b_y
        cmp #32
        bcs _no
        lda tmp0
        clc
        adc #10
        sec
        sbc b_x
        cmp #44
        bcs _no
        lda #3
        sta b_fl
        lda #1
        sta statflag
        lda #SFX_HIT
        jsr sfx_start
        lda #1
        ldx #0
        jsr score_add
        dec b_hp
        bne +
        jsr boss_kill
+       sec
        rts
_no     clc
        rts

boss_kill
        lda #0
        sta b_hp
        lda #150
        sta b_dead
        jsr eb_clear
        lda #1
        sta statflag
        lda #SFX_BIGEXPLO
        jsr sfx_start
        ldx sector
        lda b_bonus,x
        tax
        lda #0
        jmp score_add

boss_dying
        dec b_dead
        bne +
        lda #0
        sta spy+6
        sta spy+7
        sta spy+3
        sta spy+4
        sta spy+5
        sta spexp
        rts
+       lda b_dead
        and #1
        beq +
        lda #1
        bne ++
+       ldx sector
        lda b_colors,x
+       sta spc+6
        sta spc+7
        lda b_dead
        and #31
        bne +
        lda #SFX_BIGEXPLO
        jsr sfx_start
+       lda b_dead
        and #7
        bne _anim
        ; new burst in slot 3..5
        lda b_dead
        lsr
        lsr
        lsr
        and #3
        cmp #3
        bcc +
        lda #0
+       tax
        jsr rnd
        and #31
        clc
        adc b_x
        adc #4
        sta spx+3,x
        jsr rnd
        and #31
        clc
        adc b_y
        sta spy+3,x
        lda #7
        sta spc+3,x
_anim   ldx #2
-       lda b_dead
        lsr
        lsr
        and #3
        clc
        adc #SPR_AEXPL
        sta spp+3,x
        dex
        bpl -
        rts
