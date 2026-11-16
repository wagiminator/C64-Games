; =====================================================================
;  Enemies, spawners, enemy bullets, collisions
; =====================================================================
E_DRONE   = 1
E_DART    = 2
E_TURRET  = 3
E_ROCK    = 4
E_HOPPER  = 5
E_CARRIER = 6
E_MINE    = 7
E_CHASER  = 8
E_POWERUP = 9
E_EXPLODE = 10

N_SP = 2

clear_objects
        ldx #N_EN-1
        lda #0
-       sta en_t,x
        dex
        bpl -
        ldx #N_PB-1
-       sta pb_t,x
        sta pb_x1,x
        dex
        bpl -
        ldx #N_EB-1
-       sta eb_on,x
        dex
        bpl -
        ldx #N_SP-1
-       sta sp_cnt,x
        dex
        bpl -
        sta b_on
        rts

; ---------------------------------------------------- event -> spawner
spawn_event
        lda tmp0
        cmp #E_TURRET
        bne +
        jmp spawn_turret
+       ldx #0
        lda sp_cnt
        beq +
        ldx #1
        lda sp_cnt+1
        beq +
        ldx #0
+       lda tmp0
        sta sp_type,x
        lda tmp1
        sta sp_cnt,x
        lda tmp2
        sta sp_y,x
        lda tmp3
        sta sp_par,x
        lda #1
        sta sp_tim,x
        lda #0
        sta sp_idx,x
        rts

update_spawners
        ldx #N_SP-1
_lp     lda sp_cnt,x
        beq _nx
        dec sp_tim,x
        bne _nx
        stx tmp7
        lda sp_type,x
        sta tmp0
        lda sp_y,x
        sta tmp2
        lda sp_par,x
        sta tmp3
        lda sp_idx,x
        sta tmp1
        jsr spawn_enemy
        ldx tmp7
        inc sp_idx,x
        dec sp_cnt,x
        ldy sp_type,x
        lda sp_interval,y
        sta sp_tim,x
_nx     dex
        bpl _lp
        rts
sp_interval .byte 0,14,18,0,40,24,0,50,20

; alloc enemy slot -> X, C=1 if none
alloc_enemy
        ldx #N_EN-1
-       lda en_t,x
        beq +
        dex
        bpl -
        sec
        rts
+       lda #0
        sta en_xf,x
        sta en_yf,x
        sta en_vxl,x
        sta en_vxh,x
        sta en_vyl,x
        sta en_vyh,x
        sta en_tm,x
        sta en_a,x
        sta en_b,x
        sta en_c,x
        sta en_fl,x
        sta en_gnd,x
        sta en_cx2,x
        clc
        rts

; common init: A = type, X = slot
init_type
        sta en_t,x
        tay
        lda et_hp,y
        sta en_hp,x
        lda et_col,y
        sta en_col,x
        lda et_spr,y
        sta en_spr,x
        lda #1
        sta en_xh,x
        lda #88
        sta en_xl,x
        rts

; tmp0 type, tmp1 index in wave, tmp2 y, tmp3 param
spawn_enemy
        jsr alloc_enemy
        bcc +
        rts
+       lda tmp0
        jsr init_type
        lda tmp2
        sta en_y,x
        lda tmp0
        cmp #E_DRONE
        bne _dart
        lda tmp2
        sta en_b,x
        lda tmp1
        asl
        asl
        asl
        asl
        asl
        sta en_a,x
        lda tmp3
        sta en_c,x
        lda #$fe
        sta en_vxh,x
        lda #$80
        sta en_vxl,x
        rts
_dart   cmp #E_DART
        bne _rock
        lda #$fd
        sta en_vxh,x
        lda level
        asl
        asl
        asl
        asl
        eor #$ff
        sta en_vxl,x
        rts
_rock   cmp #E_ROCK
        bne _hop
        jsr rnd
        and #$7f
        clc
        adc #68
        sta en_y,x
        jsr rnd
        ora #$80
        sta en_vxl,x
        lda #$fe
        sta en_vxh,x
        jsr rnd
        and #$7f
        sec
        sbc #$40
        sta en_vyl,x
        lda #0
        sbc #0
        sta en_vyh,x
        jsr rnd
        and #1
        clc
        adc #SPR_ROCK
        sta en_spr,x
        rts
_hop    cmp #E_HOPPER
        bne _carr
        lda #1
        sta en_gnd,x
        lda gF
        asl
        asl
        asl
        sta tmp4
        lda #197
        sec
        sbc tmp4
        sta en_y,x
        lda #$ff
        sta en_vxh,x
        lda #$80
        sta en_vxl,x
        lda #$fd
        sta en_vyh,x
        rts
_carr   cmp #E_CARRIER
        bne _mine
        lda tmp3
        sta en_a,x
        lda tmp2
        sta en_b,x
        lda #$ff
        sta en_vxh,x
        lda #$40
        sta en_vxl,x
        rts
_mine   cmp #E_MINE
        bne _chas
        lda #$fe
        sta en_vxh,x
        rts
_chas   cmp #E_CHASER
        bne _done
        lda #$ff
        sta en_xh,x
        lda #$e8
        sta en_xl,x
        lda tmp1
        asl
        asl
        asl
        clc
        adc tmp2
        sta en_y,x
        lda #2
        sta en_vxh,x
        lda #$80
        sta en_vxl,x
_done   rts

spawn_turret
        jsr alloc_enemy
        bcc +
        rts
+       lda #E_TURRET
        jsr init_type
        lda #79
        sta en_xl,x
        lda #1
        sta en_gnd,x
        jsr rnd
        and #63
        adc #40
        sta en_tm,x
        lda tmp3
        bne _ceil
        lda gF
        asl
        asl
        asl
        sta tmp4
        lda #197
        sec
        sbc tmp4
        sta en_y,x
        rts
_ceil   lda gC
        asl
        asl
        asl
        clc
        adc #50
        sta en_y,x
        lda #SPR_TURRETC
        sta en_spr,x
        lda #1
        sta en_c,x
        rts

; ---------------------------------------------------- per frame update
update_enemies
        ldx #N_EN-1
_lp     lda en_t,x
        bne +
        jmp _next
+       ; ground scroll
        lda scrolled
        beq _beh
        lda en_gnd,x
        beq _beh
        lda en_xl,x
        bne +
        dec en_xh,x
+       dec en_xl,x
_beh
        lda en_t,x
        asl
        tay
        lda beh_tab,y
        sta jvec
        lda beh_tab+1,y
        sta jvec+1
        jsr _call
        lda en_t,x
        bne +
        jmp _next
+       ; ---- inline movement
        ldy #0
        lda en_vxh,x
        bpl +
        dey
+       clc
        lda en_xf,x
        adc en_vxl,x
        sta en_xf,x
        lda en_xl,x
        adc en_vxh,x
        sta en_xl,x
        tya
        adc en_xh,x
        sta en_xh,x
        beq _xin
        bmi _xneg
        lda en_xl,x
        cmp #104
        bcc _xin
        jmp _kill
_xneg   lda en_xl,x
        cmp #$d8
        bcs _xin
        jmp _kill
_xin    lda en_vyl,x
        ora en_vyh,x
        beq _ny
        clc
        lda en_yf,x
        adc en_vyl,x
        sta en_yf,x
        lda en_y,x
        adc en_vyh,x
        sta en_y,x
_ny     lda en_y,x
        cmp #20
        bcs +
        jmp _kill
+       cmp #226
        bcc +
        jmp _kill
+       ; centre + box only every other frame per slot
        txa
        eor frame
        and #1
        beq +
        jmp _next
+       ; centre
        lda en_xh,x
        bmi _neg
        lda en_xl,x
        clc
        adc #12
        sta tmp0
        lda en_xh,x
        adc #0
        lsr
        lda tmp0
        ror
        sta en_cx2,x
        jmp +
_neg    lda #0
        sta en_cx2,x
+       lda en_y,x
        clc
        adc #10
        sta en_cy,x
        ; collision box
        ldy en_t,x
        lda enw_tab,y
        beq _nobox
        lda en_cx2,x
        beq _nobox
        sec
        sbc enw_tab,y
        bcs +
        lda #1
+       sta en_x0,x
        lda en_cx2,x
        clc
        adc enw_tab,y
        sta en_x1,x
        lda en_cy,x
        sec
        sbc enh_tab,y
        sta en_y0,x
        lda en_cy,x
        clc
        adc enh_tab,y
        sta en_y1,x
        jmp _next
_nobox  lda #0
        sta en_x1,x
        jmp _next
_kill   lda #0
        sta en_t,x
_next   dex
        bmi +
        jmp _lp
+       rts
_call   jmp (jvec)

beh_tab .word beh_none, beh_drone, beh_dart, beh_turret, beh_none, beh_hopper
        .word beh_carrier, beh_mine, beh_chaser, beh_powerup, beh_explode

; movement + offscreen test -> C=1 if gone
move_enemy
        ldy #0
        lda en_vxh,x
        bpl +
        dey
+       sty tmp0
        lda en_xf,x
        clc
        adc en_vxl,x
        sta en_xf,x
        lda en_xl,x
        adc en_vxh,x
        sta en_xl,x
        lda en_xh,x
        adc tmp0
        sta en_xh,x
        lda en_yf,x
        clc
        adc en_vyl,x
        sta en_yf,x
        lda en_y,x
        adc en_vyh,x
        sta en_y,x
        cmp #20
        bcc _gone
        cmp #226
        bcs _gone
        lda en_xh,x
        beq _in
        bmi _left
        lda en_xl,x
        cmp #104
        bcs _gone
_in     clc
        rts
_left   lda en_xl,x
        cmp #$d8
        bcc _gone
        clc
        rts
_gone   sec
        rts

beh_none
        rts

beh_drone
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        and #3
        clc
        adc #SPR_DRONE
        sta en_spr,x
        lda en_tm,x
        ldy en_c,x
        beq +
        asl
+       asl
        clc
        adc en_a,x
        tay
        lda sintab,y
        cmp #$80
        ror
        clc
        adc en_b,x
        sta en_y,x
        ; occasional shot (level 2+)
        ldy level
        beq +
        jsr rnd
        cmp drone_fire,y
        bcs +
        jmp enemy_fire
+       rts

beh_dart
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        and #1
        clc
        adc #SPR_DART
        sta en_spr,x
        lda en_xh,x
        bne _r
        lda en_tm,x
        and #1
        bne _r
        lda pcy
        sec
        sbc #10
        cmp en_y,x
        beq _r
        bcc +
        inc en_y,x
        rts
+       dec en_y,x
_r      rts

beh_turret
        lda en_xh,x
        bne _r
        lda en_xl,x
        cmp #36
        bcc _r
        dec en_tm,x
        bne _r
        ldy level
        lda turret_rate,y
        sta en_tm,x
        jsr rnd
        and #31
        clc
        adc en_tm,x
        sta en_tm,x
        jmp enemy_fire
_r      rts
turret_rate .byte 110,100,90,85,80,75
drone_fire .byte 0,2,3,4,4,5

beh_hopper
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        lsr
        and #1
        clc
        adc #SPR_HOPPER
        sta en_spr,x
        ; gravity
        lda en_vyl,x
        clc
        adc #$18
        sta en_vyl,x
        lda en_vyh,x
        adc #0
        sta en_vyh,x
        bmi _r
        ; falling: check floor below feet
        lda en_xl,x
        clc
        adc #12
        sta tmp0
        lda en_xh,x
        adc #0
        sta tmp1
        bmi _r
        stx tmp7
        lda en_y,x
        clc
        adc #21
        jsr charat
        ldx tmp7
        cmp #0
        bpl _r
        ; land: snap & jump
        lda en_y,x
        sec
        sbc #29
        and #$f8
        clc
        adc #50-21
        sta en_y,x
        lda #$fd
        sta en_vyh,x
        lda #$20
        sta en_vyl,x
_r      rts

beh_carrier
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        lsr
        and #1
        clc
        adc #SPR_CARRIER
        sta en_spr,x
        lda en_tm,x
        asl
        asl
        tay
        lda sintab,y
        cmp #$80
        ror
        cmp #$80
        ror
        clc
        adc en_b,x
        sta en_y,x
        rts

beh_mine
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        and #1
        clc
        adc #SPR_MINE
        sta en_spr,x
        lda en_a,x
        bne _s1
        lda en_xh,x
        bne _r
        lda en_xl,x
        cmp #232
        bcs _r
        lda #1
        sta en_a,x
        lda #0
        sta en_vxl,x
        sta en_vxh,x
        lda #40
        sta en_c,x
        rts
_s1     cmp #1
        bne _r
        dec en_c,x
        bne _r
        lda #2
        sta en_a,x
        lda #$fd
        sta en_vxh,x
        ; ring of 8
        lda #0
        sta tmp6
-       stx tmp7
        lda tmp6
        jsr fire_angle_from
        ldx tmp7
        lda tmp6
        clc
        adc #8
        sta tmp6
        cmp #64
        bne -
_r      rts

beh_chaser
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        and #1
        clc
        adc #SPR_CHASER
        sta en_spr,x
        lda en_tm,x
        and #3
        bne _r
        lda en_vxl,x
        clc
        adc #$10
        sta en_vxl,x
        bcc +
        inc en_vxh,x
+       lda pcy
        sec
        sbc #10
        cmp en_y,x
        beq _r
        bcc +
        inc en_y,x
        inc en_y,x
        rts
+       dec en_y,x
        dec en_y,x
_r      rts

beh_powerup
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        and #7
        tay
        lda pu_cols,y
        sta en_col,x
        lda en_tm,x
        asl
        asl
        tay
        lda sintab,y
        cmp #$80
        ror
        cmp #$80
        ror
        cmp #$80
        ror
        clc
        adc en_b,x
        sta en_y,x
        rts
pu_cols .byte 2,8,7,1,7,8,2,10

beh_explode
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        cmp #6
        bcc +
        lda #0
        sta en_t,x
        rts
+       clc
        adc #SPR_EXPLODE
        sta en_spr,x
        rts

; ---------------------------------------------------- enemy fire
; aimed shot from enemy X
enemy_fire
        lda pstate
        bne _r
        stx tmp7
        lda en_cx2,x
        sta tmp0
        lda en_cy,x
        sta tmp1
        jsr aim
        ldx tmp7
        jsr fire_angle_from
        ldx tmp7
_r      rts

; A = angle, X = enemy -> spawn bullet at enemy centre
fire_angle_from
        sta tmp5
        lda en_xl,x
        sta tmp0
        lda en_xh,x
        sta tmp1
        lda en_y,x
        sta tmp2
        lda tmp5
        ldy level
        ldx eb_speedidx,y
        ; fallthrough
; A = angle (0..63), X = speed index, tmp0/1 = x, tmp2 = y (sprite coords)
spawn_eb
        sta tmp3
        txa
        asl
        asl
        asl
        asl
        asl
        asl
        clc
        adc tmp3
        tay                     ; table index speed*64+angle
        ldx #N_EB-1
-       lda eb_on,x
        beq +
        dex
        bpl -
        rts
+       lda tmp1
        bmi _r
        lda #1
        sta eb_on,x
        lda #0
        sta eb_xf,x
        sta eb_yf,x
        lda tmp0
        sta eb_xl,x
        lda tmp1
        sta eb_xh,x
        lda tmp2
        sta eb_y,x
        lda ebv_xl,y
        sta eb_vxl,x
        lda ebv_xh,y
        sta eb_vxh,x
        lda ebv_yl,y
        sta eb_vyl,x
        lda ebv_yh,y
        sta eb_vyh,x
        lda #SFX_ESHOT
        jsr sfx_start
_r      rts
eb_speedidx .byte 0,0,1,1,2,2

update_ebullets
        ldx #N_EB-1
_lp     lda eb_on,x
        beq _nx
        ldy #0
        lda eb_vxh,x
        bpl +
        dey
+       sty tmp0
        lda eb_xf,x
        clc
        adc eb_vxl,x
        sta eb_xf,x
        lda eb_xl,x
        adc eb_vxh,x
        sta eb_xl,x
        lda eb_xh,x
        adc tmp0
        sta eb_xh,x
        bmi _kill
        beq +
        lda eb_xl,x
        cmp #88
        bcs _kill
        bcc ++
+       lda eb_xl,x
        cmp #8
        bcc _kill
+       lda eb_yf,x
        clc
        adc eb_vyl,x
        sta eb_yf,x
        lda eb_y,x
        adc eb_vyh,x
        sta eb_y,x
        cmp #32
        bcc _kill
        cmp #212
        bcs _kill
        lda eb_xl,x
        clc
        adc #12
        sta tmp0
        lda eb_xh,x
        adc #0
        lsr
        lda tmp0
        ror
        sta eb_cx2,x
        jmp _nx
_kill   lda #0
        sta eb_on,x
_nx     dex
        bpl _lp
        rts

; ---------------------------------------------------- destroy enemy X
destroy_enemy
        ldy en_t,x
        lda et_score,y
        stx tmp7
        ldx #0
        cpy #E_CARRIER
        bne +
        lda #$50
+       jsr score_add
        ldx tmp7
        lda en_t,x
        cmp #E_CARRIER
        bne _expl
        ; becomes power-up
        lda #E_POWERUP
        sta en_t,x
        lda en_a,x
        clc
        adc #SPR_POWERUP
        sta en_spr,x
        lda #$ff
        sta en_vxh,x
        lda #$40
        sta en_vxl,x
        lda #0
        sta en_vyl,x
        sta en_vyh,x
        sta en_gnd,x
        sta en_tm,x
        lda en_y,x
        sta en_b,x
        lda #SFX_EXPLO
        jmp sfx_start
_expl   lda #E_EXPLODE
        sta en_t,x
        lda #0
        sta en_tm,x
        sta en_vxl,x
        sta en_vyl,x
        sta en_vyh,x
        sta en_fl,x
        lda #$ff
        ldy en_gnd,x
        beq +
        lda #0
+       sta en_vxh,x
        lda #SPR_EXPLODE
        sta en_spr,x
        lda #7
        sta en_col,x
        lda #SFX_EXPLO
        jmp sfx_start

; spawn explosion at tmp0/tmp1 (x), tmp2 (y)
spawn_explosion
        jsr alloc_enemy
        bcs +
        lda #E_EXPLODE
        sta en_t,x
        lda tmp0
        sta en_xl,x
        lda tmp1
        sta en_xh,x
        lda tmp2
        sta en_y,x
        lda #SPR_EXPLODE
        sta en_spr,x
        lda #7
        sta en_col,x
+       rts

; ---------------------------------------------------- collisions
; |A - tmp0| -> A
absdiff
        sec
        sbc tmp0
        bcs +
        eor #$ff
        adc #1
+       rts

collisions
        ; ---- player bullets vs enemies (box overlap)
        ldx #N_EN-1
_el     lda en_t,x
        beq _en
        cmp #E_POWERUP
        bcs _en
        lda en_x1,x
        beq _en
        sta cx1
        lda en_x0,x
        sta cx0
        lda en_y0,x
        sta cy0
        lda en_y1,x
        sta cy1
        ldy #N_PB-1
_bl     lda pb_x1,y
        cmp cx0
        bcc _bn
        beq _bn
        lda cx1
        cmp pb_x0,y
        bcc _bn
        beq _bn
        lda pb_y1,y
        cmp cy0
        bcc _bn
        beq _bn
        lda cy1
        cmp pb_y0,y
        bcc _bn
        beq _bn
        txa
        cmp pb_hit,y
        beq _bn
        sty tmp6
        jsr bullet_hits_enemy
        ldy tmp6
        lda en_t,x
        cmp #E_POWERUP
        bcs _en
_bn     dey
        bpl _bl
_en     dex
        bpl _el
+       ; ---- player / orb boxes
        lda pcx2
        sec
        sbc #4
        sta cx0
        adc #7                  ; carry set -> +8
        sta cx1
        lda pcy
        sec
        sbc #4
        sta cy0
        adc #7
        sta cy1
        lda ocx2
        sec
        sbc #6
        sta ox0
        adc #11
        sta ox1
        lda ocy
        sec
        sbc #9
        sta oy0
        adc #17
        sta oy1
        lda pstate
        beq +
        jmp _ebs
+       ldx #N_EN-1
_pel    lda en_t,x
        bne +
        jmp _pen
+       cmp #E_POWERUP
        bne +
        jmp _pu
+       bcc +
        jmp _pen
+       lda en_x1,x
        bne +
        jmp _pen
+       ; player box overlap
        cmp cx0
        bcc _orbt
        beq _orbt
        lda cx1
        cmp en_x0,x
        bcc _orbt
        beq _orbt
        lda en_y1,x
        cmp cy0
        bcc _orbt
        beq _orbt
        lda cy1
        cmp en_y0,x
        bcc _orbt
        beq _orbt
        lda cheat
        ora pinv
        bne _orbt
        jsr kill_player
        lda en_t,x
        cmp #E_TURRET
        beq _pen
        jsr destroy_enemy
        jmp _pen
_pu     lda en_cx2,x
        sta tmp0
        lda pcx2
        jsr absdiff
        cmp #10
        bcs _pen
        lda en_cy,x
        sta tmp0
        lda pcy
        jsr absdiff
        cmp #11
        bcs _pen
        jsr collect_powerup
        jmp _pen
_orbt   lda orbon
        beq _pen
        lda frame
        and #3
        bne _pen
        lda en_x1,x
        cmp ox0
        bcc _pen
        beq _pen
        lda ox1
        cmp en_x0,x
        bcc _pen
        beq _pen
        lda en_y1,x
        cmp oy0
        bcc _pen
        beq _pen
        lda oy1
        cmp en_y0,x
        bcc _pen
        beq _pen
        lda #1
        sta tmp5
        jsr damage_enemy
_pen    dex
        bmi _ebs
        jmp _pel
_ebs    ; ---- enemy bullets vs orb / player (point in box)
        lda pstate
        bne _ebdone
        ldx #N_EB-1
_ebl    lda eb_on,x
        beq _ebn
        lda eb_y,x
        clc
        adc #10
        sta tmp2
        lda orbon
        beq _ebp
        lda eb_cx2,x
        cmp ox0
        bcc _ebp
        cmp ox1
        bcs _ebp
        lda tmp2
        cmp oy0
        bcc _ebp
        cmp oy1
        bcs _ebp
        lda #0
        sta eb_on,x
        beq _ebn
_ebp    lda eb_cx2,x
        cmp cx0
        bcc _ebn
        cmp cx1
        bcs _ebn
        lda tmp2
        cmp cy0
        bcc _ebn
        cmp cy1
        bcs _ebn
        lda cheat
        ora pinv
        bne _ebn
        lda #0
        sta eb_on,x
        stx tmp7
        jsr kill_player
        ldx tmp7
_ebn    dex
        bpl _ebl
_ebdone
        jmp boss_collisions

pbw_tab .byte 0,4,10,3,4,6
pbh_tab .byte 0,3,2,3,3,9
enw_tab .byte 0,5,5,5,6,5,6,5,5,0,0
enh_tab .byte 0,7,5,6,9,7,7,8,5,0,0

; bullet Y(tmp6) hits enemy X
bullet_hits_enemy
        ldy tmp6
        lda pb_dmg,y
        sta tmp5
        lda pb_t,y
        cmp #B_LASER
        beq _pierce
        cmp #B_CHARGE
        beq _pierce
        lda #0
        sta pb_t,y
        sta pb_x1,y
        jmp damage_enemy
_pierce txa
        sta pb_hit,y
; damage enemy X by tmp5
damage_enemy
        lda en_hp,x
        sec
        sbc tmp5
        sta en_hp,x
        beq _dead
        bcc _dead
        lda #2
        sta en_fl,x
        lda #SFX_HIT
        jmp sfx_start
_dead   jmp destroy_enemy

collect_powerup
        txa
        pha
        jsr _cp
        pla
        tax
        rts
_cp     lda #0
        sta en_t,x
        stx tmp7
        lda #SFX_POWERUP
        jsr sfx_start
        lda #$50
        ldx #0
        jsr score_add
        ldx tmp7
        lda en_spr,x
        sec
        sbc #SPR_POWERUP
        cmp #P_ORB
        beq _orb
        cmp #P_SPEED
        beq _spd
        cmp #P_BOMB
        beq _bomb
        ; weapon (laser=0 -> W_LASER .. homing=2 -> W_HOMING)
        clc
        adc #1
        cmp weapon
        bne +
        lda #2
        sta wlevel
        bne _hud
+       sta weapon
        lda #1
        sta wlevel
_hud    lda #1
        sta hudflag
        rts
_orb    lda orbon
        bne _hud
        lda #1
        sta orbon
        lda px_l
        sta ox_l
        lda px_h
        sta ox_h
        lda py
        sta oy
        jmp _hud
_spd    lda pspeed
        cmp #3
        bcs _hud
        inc pspeed
        jmp _hud
_bomb   lda #8
        sta bombflash
        ldx #N_EN-1
-       lda en_t,x
        beq +
        cmp #E_POWERUP
        bcs +
        stx tmp7
        jsr destroy_enemy
        ldx tmp7
+       dex
        bpl -
        ldx #N_EB-1
        lda #0
-       sta eb_on,x
        dex
        bpl -
        lda b_on
        beq +
        lda #10
        jsr boss_damage
+       jmp _hud

P_LASER = 0
P_SPREAD = 1
P_HOMING = 2
P_ORB = 3
P_SPEED = 4
P_BOMB = 5

; enemy type tables (index = type)
et_hp   .byte 0,1,1,3,4,2,4,3,1,0,0
et_col  .byte 0,5,10,12,9,13,4,2,15,1,7
et_spr  .byte 0,SPR_DRONE,SPR_DART,SPR_TURRET,SPR_ROCK,SPR_HOPPER,SPR_CARRIER,SPR_MINE,SPR_CHASER,SPR_POWERUP,SPR_EXPLODE
et_score .byte 0,$10,$15,$30,$20,$25,$50,$30,$20,0,0
