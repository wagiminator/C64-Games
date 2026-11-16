; =====================================================================
;  Enemies, spawners, pickups, enemy bullets, collisions
; =====================================================================
E_FLYER   = 1
E_SWOOP   = 2
E_TURRET  = 3
E_ROCK    = 4
E_DIVER   = 5
E_SIDER   = 6
E_MINE    = 7
E_RISER   = 8
E_POD     = 9
E_BUBBLE  = 10
E_CAPSULE = 11
E_EXPLODE = 12
EV_SHOP   = 20

N_SP = 2

clear_objects
        ldx #N_EN-1
        lda #0
-       sta en_t,x
        sta en_x1,x
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
        sta sp_cnt
        sta sp_cnt+1
        sta b_on
        rts

; ---------------------------------------------------- event -> spawner
; tmp0 type, tmp1 count, tmp2 x lo, tmp3 param (bit7 = x hi)
spawn_event
        lda tmp0
        cmp #EV_SHOP
        bne +
        lda #1
        sta shoppend
        rts
+       cmp #E_TURRET
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
        sta sp_x,x
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
        lda sp_x,x
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
sp_interval .byte 0,14,16,0,40,24,24,0,30,0

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
        sta en_x1,x
        sta en_xh,x
        clc
        rts

; A = type, X = slot ; default position: top, x from tmp2/tmp3
init_type
        sta en_t,x
        tay
        lda et_hp,y
        sta en_hp,x
        lda et_col,y
        sta en_col,x
        lda et_spr,y
        sta en_spr,x
        lda tmp2
        sta en_xl,x
        lda tmp3
        and #$80
        beq +
        lda #1
+       sta en_xh,x
        lda #34
        sta en_y,x
        rts

; tmp0 type, tmp1 wave index, tmp2/tmp3 x / param
spawn_enemy
        jsr alloc_enemy
        bcc +
        rts
+       lda tmp0
        jsr init_type
        lda tmp0
        cmp #E_FLYER
        bne _swoop
        lda tmp2
        sta en_b,x              ; base x (lo)
        lda tmp1
        asl
        asl
        asl
        asl
        asl
        sta en_a,x              ; phase
        lda tmp3
        and #1
        sta en_c,x
        lda #1
        sta en_vyh,x
        lda #$40
        sta en_vyl,x
        rts
_swoop  cmp #E_SWOOP
        bne _rock
        lda tmp1
        asl
        asl
        asl
        asl
        clc
        adc tmp2
        sta en_xl,x
        lda #2
        sta en_vyh,x
        rts
_rock   cmp #E_ROCK
        bne _diver
        jsr rnd
        and #$7f
        clc
        adc #60
        asl
        sta en_xl,x
        lda #0
        rol
        sta en_xh,x
        jsr rnd
        ora #$40
        sta en_vyl,x
        lda #1
        sta en_vyh,x
        jsr rnd
        and #$7f
        sec
        sbc #$40
        sta en_vxl,x
        lda #0
        sbc #0
        sta en_vxh,x
        jsr rnd
        and #1
        clc
        adc #SPR_ROCK
        sta en_spr,x
        rts
_diver  cmp #E_DIVER
        bne _sider
        lda px_l
        sta en_xl,x
        lda px_h
        sta en_xh,x
        lda #3
        sta en_vyh,x
        lda #$80
        sta en_vyl,x
        rts
_sider  cmp #E_SIDER
        bne _mine
        lda tmp1
        asl
        asl
        asl
        asl
        clc
        adc #64
        sta en_y,x
        lda tmp3
        and #1
        bne _fromr
        lda #$ff
        sta en_xh,x
        lda #$f0
        sta en_xl,x
        lda #2
        sta en_vxh,x
        lda #$40
        sta en_vxl,x
        rts
_fromr  lda #1
        sta en_xh,x
        lda #80
        sta en_xl,x
        lda #$fd
        sta en_vxh,x
        lda #$c0
        sta en_vxl,x
        rts
_mine   cmp #E_MINE
        bne _riser
        lda #$c0
        sta en_vyl,x
        rts
_riser  cmp #E_RISER
        bne _pod
        lda #222
        sta en_y,x
        lda tmp1
        asl
        asl
        asl
        asl
        asl
        clc
        adc tmp2
        sta en_xl,x
        lda #$fd
        sta en_vyh,x
        lda #$c0
        sta en_vyl,x
        rts
_pod    cmp #E_POD
        bne _done
        lda #$a0
        sta en_vyl,x
        lda tmp2
        sta en_b,x
_done   rts

spawn_turret
        jsr alloc_enemy
        bcc +
        rts
+       lda #E_TURRET
        jsr init_type
        lda #1
        sta en_gnd,x
        lda #39
        sta en_y,x
        jsr rnd
        and #63
        adc #30
        sta en_tm,x
        rts

; ---------------------------------------------------- per frame update
update_enemies
        ldx #N_EN-1
_lp     lda en_t,x
        bne +
        jmp _next
+       ; ground scroll (terrain moves down)
        lda scrolled
        beq _beh
        lda en_gnd,x
        beq _beh
        inc en_y,x
_beh    lda en_t,x
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
        cmp #100
        bcc _xin
        jmp _kill
_xneg   lda en_xl,x
        cmp #$e0
        bcs _xin
        jmp _kill
_xin    clc
        lda en_yf,x
        adc en_vyl,x
        sta en_yf,x
        lda en_y,x
        adc en_vyh,x
        sta en_y,x
        cmp #20
        bcs +
        jmp _kill
+       cmp #228
        bcc +
        jmp _kill
+       txa
        eor frame
        and #1
        beq +
        jmp _next
+       ; ---- centre + box
        lda en_xh,x
        bmi _nobox
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
        lda en_y,x
        clc
        adc #10
        sta en_cy,x
        ldy en_t,x
        lda enw_tab,y
        beq _nobox
        lda en_cx2,x
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
        sta en_x1,x
_next   dex
        bmi +
        jmp _lp
+       rts
_call   jmp (jvec)

beh_tab .word beh_none, beh_flyer, beh_swoop, beh_turret, beh_anim2, beh_anim2, beh_sider
        .word beh_mine, beh_riser, beh_pod, beh_bubble, beh_none, beh_explode

beh_none
        rts

beh_anim2
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        lsr
        and #1
        ldy en_t,x
        clc
        adc et_spr,y
        sta en_spr,x
        rts

beh_flyer
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        and #3
        clc
        adc #SPR_FLYER
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
        sta en_xl,x
        lda #0
        sta en_xh,x
        ldy level
        beq +
        jsr rnd
        cmp flyer_fire,y
        bcs +
        jmp enemy_fire_down
+       rts
flyer_fire .byte 0,2,3,3,4

beh_swoop
        jsr beh_anim2
        lda en_y,x
        cmp #70
        bcc _r
        lda en_tm,x
        and #3
        bne _r
        lda pcx2
        sec
        sbc en_cx2,x
        beq _r
        bcc _l
        lda en_vxh,x
        bmi +
        cmp #2
        bcs _r
+       lda en_vxl,x
        clc
        adc #$30
        sta en_vxl,x
        bcc _r
        inc en_vxh,x
        rts
_l      lda en_vxh,x
        bpl +
        cmp #$fe
        bcc _r
+       lda en_vxl,x
        sec
        sbc #$30
        sta en_vxl,x
        bcs _r
        dec en_vxh,x
_r      rts

beh_turret
        lda en_y,x
        cmp #60
        bcc _r
        cmp #190
        bcs _r
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
turret_rate .byte 100,90,80,75,70

beh_sider
        jsr beh_anim2
        lda en_tm,x
        and #63
        cmp #20
        bne +
        lda en_xh,x
        bne +
        jmp enemy_fire_down
+       rts

beh_mine
        jsr beh_anim2
        lda en_tm,x
        cmp #110
        bne _r
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
        jmp destroy_silent
_r      rts

beh_riser
        jsr beh_anim2
        lda en_tm,x
        and #3
        bne _r
        lda pcx2
        cmp en_cx2,x
        beq _r
        bcc +
        inc en_xl,x
        rts
+       dec en_xl,x
_r      rts

beh_pod
        jsr beh_anim2
        lda en_tm,x
        tay
        lda sintab,y
        cmp #$80
        ror
        cmp #$80
        ror
        clc
        adc en_b,x
        sta en_xl,x
        rts

beh_bubble
        inc en_tm,x
        lda en_tm,x
        asl
        asl
        tay
        lda sintab,y
        sta en_vxl,x
        and #$80
        beq +
        lda #$ff
+       sta en_vxh,x
        rts

beh_explode
        inc en_tm,x
        lda en_tm,x
        lsr
        lsr
        cmp #6
        bcc +
        lda #0
        sta en_t,x
        sta en_x1,x
        rts
+       clc
        adc #SPR_EXPLODE
        sta en_spr,x
        rts

; ---------------------------------------------------- enemy fire
enemy_fire_down
        lda pstate
        bne +
        lda en_y,x
        cmp #170
        bcs +
        lda #16
        stx tmp7
        jsr fire_angle_from
        ldx tmp7
+       rts

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

; A = angle, X = enemy -> bullet at enemy centre
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
; A = angle, X = speed index, tmp0/1 = x, tmp2 = y
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
        tay
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
eb_speedidx .byte 0,1,1,2,2

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
        cmp #30
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
        jsr score_add
        ldx tmp7
        ; drop?
        ldy en_t,x
        lda et_drop,y
        beq _expl
        cmp #3
        beq _cap
        cmp #2
        beq _big
        jsr rnd
        cmp #110
        bcs _expl
        lda #0
        beq _bub
_big    lda #1
_bub    sta en_a,x
        lda #E_BUBBLE
        sta en_t,x
        clc
        adc #0
        lda en_a,x
        clc
        adc #SPR_BUBBLE
        sta en_spr,x
        lda #7
        sta en_col,x
        lda #$70
        sta en_vyl,x
        lda #0
        sta en_vyh,x
        sta en_vxh,x
        sta en_vxl,x
        sta en_gnd,x
        sta en_x1,x
        lda #SFX_EXPLO
        jmp sfx_start
_cap    jsr rnd
        cmp #120
        bcs _big
        lda #E_CAPSULE
        sta en_t,x
        lda #SPR_CAPSULE
        sta en_spr,x
        lda #10
        sta en_col,x
        lda #$60
        sta en_vyl,x
        lda #0
        sta en_vyh,x
        sta en_vxh,x
        sta en_vxl,x
        sta en_gnd,x
        sta en_x1,x
        lda #SFX_EXPLO
        jmp sfx_start
_expl   jsr make_explosion
        lda #SFX_EXPLO
        jmp sfx_start

destroy_silent
make_explosion
        lda #E_EXPLODE
        sta en_t,x
        lda #0
        sta en_tm,x
        sta en_vxl,x
        sta en_vxh,x
        sta en_vyl,x
        sta en_vyh,x
        sta en_fl,x
        sta en_x1,x
        lda #SPR_EXPLODE
        sta en_spr,x
        lda #7
        sta en_col,x
        rts

; spawn explosion at tmp0/tmp1 (x), tmp2 (y)
spawn_explosion
        jsr alloc_enemy
        bcs +
        jsr make_explosion
        lda tmp0
        sta en_xl,x
        lda tmp1
        sta en_xh,x
        lda tmp2
        sta en_y,x
+       rts

; spawn credit bubble at tmp0/tmp1/tmp2, A = size (0/1)
spawn_bubble
        pha
        jsr alloc_enemy
        pla
        bcs +
        sta en_a,x
        clc
        adc #SPR_BUBBLE
        sta en_spr,x
        lda #E_BUBBLE
        sta en_t,x
        lda #7
        sta en_col,x
        lda tmp0
        sta en_xl,x
        lda tmp1
        sta en_xh,x
        lda tmp2
        sta en_y,x
        lda #$80
        sta en_vyl,x
+       rts

; ---------------------------------------------------- collisions
absdiff
        sec
        sbc tmp0
        bcs +
        eor #$ff
        adc #1
+       rts

collisions
        ; ---- player bullets vs enemies
        ldx #N_EN-1
_el     lda en_t,x
        beq _en
        cmp #E_BUBBLE
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
        cmp #E_BUBBLE
        bcs _en
_bn     dey
        bpl _bl
_en     dex
        bpl _el
        ; ---- player box
        lda pcx2
        sec
        sbc #5
        sta cx0
        adc #9
        sta cx1
        lda pcy
        sec
        sbc #6
        sta cy0
        adc #11
        sta cy1
        lda pstate
        beq +
        jmp boss_collisions
+       ldx #N_EN-1
_pel    lda en_t,x
        bne +
        jmp _pen
+       cmp #E_BUBBLE
        bcc _hostile
        cmp #E_EXPLODE
        bne +
        jmp _pen
+       ; pickup: distance test
        lda en_cx2,x
        sta tmp0
        lda pcx2
        jsr absdiff
        cmp #10
        bcs _pen
        lda en_cy,x
        sta tmp0
        lda pcy
        jsr absdiff
        cmp #13
        bcs _pen
        jsr collect_item
        jmp _pen
_hostile
        lda en_x1,x
        beq _pen
        cmp cx0
        bcc _pen
        beq _pen
        lda cx1
        cmp en_x0,x
        bcc _pen
        beq _pen
        lda en_y1,x
        cmp cy0
        bcc _pen
        beq _pen
        lda cy1
        cmp en_y0,x
        bcc _pen
        beq _pen
        stx tmp7
        lda #8
        jsr damage_player
        ldx tmp7
        lda en_t,x
        cmp #E_TURRET
        beq _pen
        lda #4
        sta tmp5
        jsr damage_enemy
_pen    dex
        bmi +
        jmp _pel
+       ; ---- enemy bullets vs player
        ldx #N_EB-1
_ebl    lda eb_on,x
        beq _ebn
        lda eb_cx2,x
        cmp cx0
        bcc _ebn
        cmp cx1
        bcs _ebn
        lda eb_y,x
        clc
        adc #10
        cmp cy0
        bcc _ebn
        cmp cy1
        bcs _ebn
        lda #0
        sta eb_on,x
        stx tmp7
        lda #6
        jsr damage_player
        ldx tmp7
_ebn    dex
        bpl _ebl
        jmp boss_collisions

bullet_hits_enemy
        ldy tmp6
        lda pb_dmg,y
        sta tmp5
        lda pb_t,y
        cmp #B_LASER
        beq _pierce
        lda #0
        sta pb_t,y
        sta pb_x1,y
        jmp damage_enemy
_pierce txa
        sta pb_hit,y
damage_enemy
        lda en_hp,x
        sec
        sbc tmp5
        sta en_hp,x
        beq _dead
        bcc _dead
        lda #1
        sta en_fl,x
        lda #SFX_HIT
        jmp sfx_start
_dead   jmp destroy_enemy

collect_item
        lda en_t,x
        cmp #E_CAPSULE
        beq _cap
        ; bubble: credits
        lda en_a,x
        beq +
        lda #$01                ; 100
        ldy #$00
        beq ++
+       ldy #$25                ; 25
        lda #$00
+       sty tmp0
        sta tmp1
        jsr credits_add
        lda #SFX_MENU
        jsr sfx_start
        jmp _gone
_cap    lda energy
        clc
        adc #16
        cmp #ENERGYMAX
        bcc +
        lda #ENERGYMAX
+       sta energy
        lda #SFX_POWERUP
        jsr sfx_start
_gone   lda #0
        sta en_t,x
        sta en_x1,x
        lda #1
        sta hudflag
        rts

; enemy type tables
et_hp    .byte 0,1,2,4,5,2,2,3,2,9,0,0,0
et_col   .byte 0,5,10,12,9,15,4,2,13,8,7,10,7
et_spr   .byte 0,SPR_FLYER,SPR_SWOOP,SPR_TURRET,SPR_ROCK,SPR_DIVER,SPR_SIDER,SPR_MINE,SPR_RISER,SPR_POD,SPR_BUBBLE,SPR_CAPSULE,SPR_EXPLODE
et_score .byte 0,$10,$15,$30,$20,$15,$20,$25,$20,$50,0,0,0
et_drop  .byte 0,1,1,1,2,1,1,0,1,3,0,0,0
enw_tab  .byte 0,5,5,5,6,4,5,5,5,6,0,0,0
enh_tab  .byte 0,6,6,8,9,7,5,8,6,10,0,0,0
