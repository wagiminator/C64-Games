; =====================================================================
;  Weapons and items
;  0 silver knives  1 lantern glow  2 storm bell  3 spirit orbs  4 fire flask
;  5 swift boots    6 hourglass     7 lodestone   8 iron heart
; =====================================================================

dir_dx  .byte 1, 1, 0, $ff, $ff, $ff, 0, 1
dir_dy  .byte 0, 1, 1, 1, 0, $ff, $ff, $ff
orbn    .byte 0, 1, 2, 2, 3, 4
cd_base .byte 15, 10, 56, 0, 64       ; updates between shots
spd_lo  .byte $00, $50, $a0, $00
spd_hi  .byte 2, 2, 2, 3

; cooldown of weapon X with the hourglass: base - base * level / 8
cooldown
        lda cd_base,x
        sta tmp7
        lsr
        lsr
        lsr
        sta tmp6
        ldy w_lvl+6
        beq +
-       lda tmp7
        sec
        sbc tmp6
        sta tmp7
        dey
        bne -
+       ; weapon level: -2 per level above 1 (at least 6)
        ldy w_lvl,x
-       dey
        beq +
        lda tmp7
        sec
        sbc #2
        sta tmp7
        jmp -
+       lda tmp7
        cmp #6
        bcs +
        lda #6
+       sta w_cd,x
        rts

weapons_update
        lda dead
        beq +
        rts
+       jsr knives_update
        jsr glow_update
        jsr bell_update
        jsr orbs_update
        jmp flask_update

; ---------------------------------------------------- silver knives
knives_update
        lda w_lvl
        beq _move
        dec w_cd
        bne _move
        ldx #0
        jsr cooldown
        ; aim at the nearest creature (else where the hero walks)
        jsr nearest_dir
        sta wu_aim
        ; throw level many knives: aim, +1, -1, +2, -2
        lda w_lvl
        sta wu_n
        lda #0
        sta wu_i
-       ldx wu_i
        lda wu_aim
        clc
        adc spread,x
        and #7
        jsr throw_knife
        inc wu_i
        dec wu_n
        bne -
        lda #SFX_KNIFE
        jsr sfx_start
_move   ldx #NK-1
_k      stx wu_k
        lda k_on,x
        beq _n
        ldy k_d,x
        lda k_xl,x
        clc
        adc dir_dx,y
        sta k_xl,x
        sta tmp0
        lda dir_dx,y
        bpl +
        lda #$ff
        .byte $2c
+       lda #0
        adc k_xh,x
        sta k_xh,x
        sta tmp1
        lda k_yl,x
        clc
        adc dir_dy,y
        sta k_yl,x
        sta tmp2
        lda dir_dy,y
        bpl +
        lda #$ff
        .byte $2c
+       lda #0
        adc k_yh,x
        sta k_yh,x
        sta tmp3
        dec k_r,x
        beq _off
        ; hit?
        jsr grid_at
        lda (gptr),y
        beq _boss
        tax
        dex
        lda w_lvl
        clc
        adc #3
        jsr hit_enemy
        ldx wu_k
        lda w_lvl
        cmp #5
        bcc _off                ; level 5 knives pierce
        jmp _n
_boss   jsr boss_cell
        bcc _n
        lda w_lvl
        clc
        adc #3
        jsr hit_boss
_off    ldx wu_k
        lda #0
        sta k_on,x
_n      ldx wu_k
        dex
        bpl _k
        rts
spread  .byte 0, 1, 7, 2, 6

; direction (0..7) to the nearest creature within 14 cells, else pdir
nearest_dir
        lda #30
        sta nd_best
        lda pdir
        sta nd_dir
        ldx #NE-1
_e      lda e_t,x
        beq _n
        lda e_xl,x
        sec
        sbc pcxl
        sta tmp4
        lda e_xh,x
        sbc pcxh
        jsr abs_small
        bcs _n
        cmp #15
        bcs _n
        sta tmp6
        lda e_yl,x
        sec
        sbc pcyl
        sta tmp4
        lda e_yh,x
        sbc pcyh
        jsr abs_small
        bcs _n
        cmp #15
        bcs _n
        clc
        adc tmp6
        cmp nd_best
        bcs _n
        sta nd_best
        ; direction from the signs
        lda e_xl,x
        sec
        sbc pcxl
        beq _x0
        bmi _xn
        ldy #2
        bne _xs
_xn     ldy #0
        beq _xs
_x0     ldy #1
_xs     sty tmp6
        lda e_yl,x
        sec
        sbc pcyl
        beq _y0
        bmi _yn
        ldy #6
        bne _ys
_yn     ldy #0
        beq _ys
_y0     ldy #3
_ys     tya
        clc
        adc tmp6
        tay
        lda dir_of,y
        sta nd_dir
_n      dex
        bpl _e
        lda nd_dir
        rts
nd_best .byte 0
nd_dir  .byte 0

throw_knife
        sta tmp7
        ldx #NK-1
-       lda k_on,x
        beq +
        dex
        bpl -
        rts
+       lda #1
        sta k_on,x
        lda tmp7
        sta k_d,x
        lda #13
        sta k_r,x
        lda pcxl
        sta k_xl,x
        lda pcxh
        sta k_xh,x
        lda pcyl
        sta k_yl,x
        lda pcyh
        sta k_yh,x
        rts

; ---------------------------------------------------- lantern glow: damages everything close
glow_update
        lda w_lvl+1
        beq _r
        dec auratm
        bne _r
        lda #10
        sta auratm
        lda w_lvl+1
        lsr
        clc
        adc #1
        sta wu_r                ; radius 1..3
        sta wu_d                ; damage 1..3
        ldx #NE-1
_e      lda e_t,x
        beq _n
        stx wu_k
        lda pcxl
        sec
        sbc e_xl,x
        sta tmp4
        lda pcxh
        sbc e_xh,x
        jsr abs_small
        bcs _n2
        cmp wu_r
        beq +
        bcs _n2
+       lda pcyl
        sec
        sbc e_yl,x
        sta tmp4
        lda pcyh
        sbc e_yh,x
        jsr abs_small
        bcs _n2
        cmp wu_r
        beq +
        bcs _n2
+       lda wu_d
        jsr hit_enemy
_n2     ldx wu_k
_n      dex
        bpl _e
        ; the boss
        lda b_on
        beq _r
        jsr boss_near
        bcs _r
        lda wu_d
        jmp hit_boss
_r      rts

; ---------------------------------------------------- storm bell: lightning on random creatures
bell_update
        lda w_lvl+2
        beq _r
        dec w_cd+2
        bne _r
        ldx #2
        jsr cooldown
        lda w_lvl+2
        sta wu_n
_strike lda #12
        sta wu_i                ; attempts
-       dec wu_i
        beq _boss
        lda #NE
        jsr rndmod
        tax
        lda e_t,x
        beq -
        jsr on_screen
        bcs -
        stx wu_k
        lda e_xl,x
        sta tmp0
        lda e_xh,x
        sta tmp1
        lda e_yl,x
        sta tmp2
        lda e_yh,x
        sta tmp3
        lda #1
        jsr add_fx
        ldx wu_k
        lda w_lvl+2
        asl
        clc
        adc #8
        jsr hit_enemy
        jmp _next
_boss   lda b_on
        beq _next
        lda w_lvl+2
        asl
        clc
        adc #8
        jsr hit_boss
_next   dec wu_n
        bne _strike
        lda #SFX_BOLT
        jmp sfx_start
_r      rts

; creature X within the visible area? C = 0 yes
on_screen
        lda pcxl
        sec
        sbc e_xl,x
        sta tmp4
        lda pcxh
        sbc e_xh,x
        jsr abs_small
        bcs _no
        cmp #19
        bcs _no
        lda pcyl
        sec
        sbc e_yl,x
        sta tmp4
        lda pcyh
        sbc e_yh,x
        jsr abs_small
        bcs _no
        cmp #12
        bcs _no
        clc
        rts
_no     sec
        rts

; ---------------------------------------------------- spirit orbs circling the hero
orb_count
        ldx w_lvl+3
        lda orbn,x
        rts
; cell of orb A -> tmp0..3
orb_cell
        sta tmp7
        jsr orb_count
        tax
        lda #0
        ; angle offset = orb * 32 / count
        cpx #2
        bcc _a
        ldy tmp7
        beq _a
-       clc
        adc orb_step,x
        dey
        bne -
_a      clc
        adc orbang
        and #31
        tax
        lda orb_dx,x
        jsr addx2
        lda orb_dy,x
        jmp addy2
orb_step .byte 0, 0, 16, 11, 8
addx2  sta tmp0
        lda #0
        bit tmp0
        bpl +
        lda #$ff
+       sta tmp1
        lda pcxl
        clc
        adc tmp0
        sta tmp0
        lda pcxh
        adc tmp1
        sta tmp1
        rts
addy2  sta tmp2
        lda #0
        bit tmp2
        bpl +
        lda #$ff
+       sta tmp3
        lda pcyl
        clc
        adc tmp2
        sta tmp2
        lda pcyh
        adc tmp3
        sta tmp3
        rts

orbs_update
        lda w_lvl+3
        beq _r
        inc orbang
        jsr orb_count
        sta wu_n
-       dec wu_n
        bmi _r
        lda wu_n
        jsr orb_cell
        jsr grid_at
        lda (gptr),y
        beq _boss
        tax
        dex
        lda e_hc,x
        bne -
        lda #6
        sta e_hc,x
        lda w_lvl+3
        clc
        adc #2
        jsr hit_enemy
        jmp -
_boss   jsr boss_cell
        bcc -
        lda b_fl
        bne -
        lda w_lvl+3
        clc
        adc #2
        jsr hit_boss
        jmp -
_r      rts

; ---------------------------------------------------- fire flask: explodes at a creature
flask_update
        lda w_lvl+4
        beq _r
        dec w_cd+4
        bne _r
        ldx #4
        jsr cooldown
        ; target: a creature on screen, else a spot near the hero
        lda #10
        sta wu_i
-       dec wu_i
        beq _spot
        lda #NE
        jsr rndmod
        tax
        lda e_t,x
        beq -
        jsr on_screen
        bcs -
        lda e_xl,x
        sta tmp0
        lda e_xh,x
        sta tmp1
        lda e_yl,x
        sta tmp2
        lda e_yh,x
        sta tmp3
        jmp _boom
_spot   lda #10
        jsr rndmod
        sec
        sbc #5
        jsr addx2
        lda #8
        jsr rndmod
        sec
        sbc #4
        jsr addy2
_boom   ; fire effect and damage in a square of radius 1 (2 from level 4)
        lda tmp0
        sta wu_x
        lda tmp1
        sta wu_x+1
        lda tmp2
        sta wu_y
        lda tmp3
        sta wu_y+1
        lda #1
        ldx w_lvl+4
        cpx #4
        bcc +
        lda #2
+       sta wu_r
        ; cells from -r to +r
        lda wu_r
        eor #$ff
        clc
        adc #1
        sta wu_dy
_ry     lda wu_r
        eor #$ff
        clc
        adc #1
        sta wu_dx
_rx     lda wu_x
        clc
        adc wu_dx
        sta tmp0
        lda wu_dx
        bpl +
        lda #$ff
        .byte $2c
+       lda #0
        adc wu_x+1
        sta tmp1
        lda wu_y
        clc
        adc wu_dy
        sta tmp2
        lda wu_dy
        bpl +
        lda #$ff
        .byte $2c
+       lda #0
        adc wu_y+1
        sta tmp3
        ; fire on the centre cross
        lda wu_dx
        beq +
        lda wu_dy
        bne ++
+       lda #2
        jsr add_fx
+       jsr grid_at
        lda (gptr),y
        beq _nb
        tax
        dex
        lda w_lvl+4
        clc
        adc #5
        jsr hit_enemy
        jmp _nx
_nb     jsr boss_cell
        bcc _nx
        lda w_lvl+4
        clc
        adc #5
        jsr hit_boss
_nx     inc wu_dx
        lda wu_dx
        bmi _rx
        cmp wu_r
        beq _rx
        bcc _rx
        inc wu_dy
        lda wu_dy
        bmi _ry
        cmp wu_r
        beq _ry
        bcc _ry
        lda #SFX_FIRE
        jmp sfx_start
_r      rts

wu_n    .byte 0
wu_aim  .byte 0
wu_i    .byte 0
wu_k    .byte 0
wu_r    .byte 0
wu_d    .byte 0
wu_x    .word 0
wu_y    .word 0
wu_dx   .byte 0
wu_dy   .byte 0

; ---------------------------------------------------- items from the level up menu
take_item
        tax
        lda w_lvl,x
        clc
        adc #1
        sta w_lvl,x
        cpx #5
        bcs _pass
        cmp #1
        bne _r
        ; a new weapon starts soon
        lda #8
        sta w_cd,x
        cpx #1
        bne _r
        lda #10
        sta auratm
_r      rts
_pass   cpx #5
        bne +
        tax
        lda spd_lo,x
        sta spdf
        lda spd_hi,x
        sta spdi
        rts
+       cpx #8
        bne _r
        lda maxhp
        clc
        adc #20
        sta maxhp
        lda hp
        clc
        adc #20
        cmp maxhp
        bcc +
        lda maxhp
+       sta hp
        rts

; max level of item X
item_max
        cpx #5
        lda #5
        bcc +
        lda #3
+       rts

; ---------------------------------------------------- boss: hit tests and damage
; cell tmp0..3 inside the boss (6 x 5 cells)? C = 1 yes
boss_cell
        lda b_on
        beq _no
        ; boss cell = b >> 3
        lda b_xh
        sta tmp5
        lda b_xl
        lsr tmp5
        ror
        lsr tmp5
        ror
        lsr tmp5
        ror
        sta tmp4                ; boss cell x (low byte, high in tmp5)
        lda tmp0
        sec
        sbc tmp4
        tax
        lda tmp1
        sbc tmp5
        bne _no
        cpx #6
        bcs _no
        lda b_yh
        sta tmp5
        lda b_yl
        lsr tmp5
        ror
        lsr tmp5
        ror
        lsr tmp5
        ror
        sta tmp4
        lda tmp2
        sec
        sbc tmp4
        tax
        lda tmp3
        sbc tmp5
        bne _no
        cpx #5
        bcs _no
        sec
        rts
_no     clc
        rts

; boss within the glow radius + 3? C = 0 yes
boss_near
        lda b_xl
        clc
        adc #24
        sta tmp4
        lda b_xh
        adc #0
        sta tmp5
        lda tmp4
        sec
        sbc pxl
        sta tmp4
        lda tmp5
        sbc pxh
        jsr abs_small
        bcs _r
        sta tmp6
        lda wu_r
        asl
        asl
        asl
        adc #28
        cmp tmp6
        bcc _far
        lda b_yl
        clc
        adc #21
        sta tmp4
        lda b_yh
        adc #0
        sta tmp5
        lda tmp4
        sec
        sbc pyl
        sta tmp4
        lda tmp5
        sbc pyh
        jsr abs_small
        bcs _r
        sta tmp6
        lda wu_r
        asl
        asl
        asl
        adc #26
        cmp tmp6
        bcc _far
        clc
        rts
_far    sec
_r      rts

hit_boss
        sta tmp7
        lda b_on
        beq _r
        lda #2
        sta b_fl
        lda b_hpl
        sec
        sbc tmp7
        sta b_hpl
        lda b_hph
        sbc #0
        sta b_hph
        bcc _kill
        ora b_hpl
        beq _kill
        lda #SFX_HIT
        jmp sfx_start
_kill   jmp boss_die
_r      rts
