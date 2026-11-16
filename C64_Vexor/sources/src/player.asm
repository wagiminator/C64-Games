; =====================================================================
;  Player ship, energy, weapons
; =====================================================================
B_SHOT  = 1
B_LASER = 2
B_SIDE  = 3
B_REAR  = 4
B_MISS  = 5
B_BALL  = 6

ENERGYMAX = 32

player_place
        lda #160
        sta px_l
        lda #0
        sta px_h
        lda #180
        sta py
        lda #0
        sta pstate
        sta pframe
        sta firecool
        sta hitflash
        lda #100
        sta pinv
        lda #1
        sta hudflag
        rts

player_newlife
        jsr player_place
        lda #ENERGYMAX
        sta energy
        lda mainpow
        cmp #2
        bcc +
        dec mainpow
+       lda #0
        sta novatime
        rts

; A = damage
damage_player
        ldx cheat
        bne _r
        ldx pinv
        bne _r
        ldx pstate
        bne _r
        sta tmp0
        lda energy
        sec
        sbc tmp0
        bcs +
        lda #0
+       sta energy
        lda #6
        sta hitflash
        lda #20
        sta pinv
        lda #1
        sta hudflag
        lda energy
        bne +
        lda #1
        sta pstate
        lda #0
        sta ptimer
        lda #SFX_DEATH
        jmp sfx_start
+       lda #SFX_HIT
        jmp sfx_start
_r      rts

update_player
        lda pstate
        beq _alive
        cmp #1
        bne _wait
        inc ptimer
        lda ptimer
        cmp #50
        bne +
        lda #2
        sta pstate
        lda #70
        sta ptimer
        dec lives
        lda #1
        sta hudflag
+       rts
_wait   lda lives
        beq +
        dec ptimer
        bne +
        jsr player_newlife
+       rts
_alive  lda pinv
        beq +
        dec pinv
+       lda novatime
        beq +
        dec novasub
        bpl +
        lda #49
        sta novasub
        dec novatime
        lda #1
        sta hudflag
+       lda #0
        sta pframe
        ; ---- horizontal
        lda joy
        and #4
        beq _nl
        lda #2
        sta pframe
        lda px_l
        sec
        sbc pspeed
        sta tmp0
        lda px_h
        sbc #0
        sta tmp1
        bne _hx
        lda tmp0
        cmp #28
        bcc _nr
        bcs _hx
_nl     lda joy
        and #8
        beq _nr
        lda #3
        sta pframe
        lda px_l
        clc
        adc pspeed
        sta tmp0
        lda px_h
        adc #0
        sta tmp1
        beq _hx
        lda tmp0
        cmp #36                 ; max 256+36 = 292
        bcs _nr
_hx     lda tmp0
        sta tmp4
        lda tmp1
        sta tmp5
        lda py
        sta tmp6
        jsr ship_blocked
        bcs _nr
        lda tmp4
        sta px_l
        lda tmp5
        sta px_h
_nr     ; ---- vertical
        lda joy
        and #1
        beq _nu
        lda py
        sec
        sbc pspeed
        cmp #58
        bcc _vdone
        bcs _vy
_nu     lda joy
        and #2
        beq _vdone
        lda py
        clc
        adc pspeed
        cmp #194
        bcs _vdone
_vy     sta tmp6
        lda px_l
        sta tmp4
        lda px_h
        sta tmp5
        jsr ship_blocked
        bcs _vdone
        lda tmp6
        sta py
_vdone  ; ---- terrain pushes ship down when scrolling
        lda px_l
        sta tmp4
        lda px_h
        sta tmp5
        lda py
        sta tmp6
        jsr ship_blocked
        bcc _free
        lda scrolled
        beq _crush
        lda py
        cmp #194
        bcs _crush
        inc py
        jmp _free
_crush  lda frame
        and #3
        bne _free
        lda #2
        jsr damage_player
_free   ; ---- centre
        lda px_l
        clc
        adc #12
        sta tmp0
        lda px_h
        adc #0
        lsr
        lda tmp0
        ror
        sta pcx2
        lda py
        clc
        adc #11
        sta pcy
        jmp player_fire

; test ship at tmp4/tmp5 (x), tmp6 (y) -> C=1 if blocked
ship_blocked
        lda cheat
        bne _ok
        ldx #3
_lp     stx tmp7
        lda tmp4
        clc
        adc shipbx,x
        sta tmp0
        lda tmp5
        adc #0
        sta tmp1
        lda tmp6
        clc
        adc shipby,x
        jsr solid_at
        bcs _hit
        ldx tmp7
        dex
        bpl _lp
_ok     clc
        rts
_hit    sec
        rts
shipbx  .byte 12,4,20,12
shipby  .byte 5,14,14,18

; in tmp0/1 = x, A = y ; out C=1 if solid (slope aware)
solid_at
        jsr charat
        bmi +
        clc
        rts
+       and #$7f
        tay
        lda tmp2
        and #7
        sta tmp2                ; lx
        lda tmp3
        and #7
        sta tmp3                ; ly
        cpy #8
        beq _ul
        cpy #9
        beq _ll
        cpy #18
        beq _ur
        cpy #19
        beq _lr
        sec
        rts
_ul     lda tmp2                ; upper-left: lx+ly <= 7
        clc
        adc tmp3
        cmp #8
        bcc _s
        clc
        rts
_ll     lda tmp3                ; lower-left: lx <= ly
        cmp tmp2
        rts
_ur     lda tmp2                ; upper-right: lx >= ly
        cmp tmp3
        rts
_lr     lda tmp2                ; lower-right: lx+ly >= 7
        clc
        adc tmp3
        cmp #7
        rts
_s      sec
        rts

; ---------------------------------------------------- weapons
player_fire
        lda firecool
        beq +
        dec firecool
+       lda joy
        and #$10
        beq _r
        lda joyprev
        and #$10
        bne _held
        lda firecool            ; new press
        cmp #4
        bcs _r
        bcc _shoot
_held   lda firecool
        bne _r
_shoot  jsr fire_weapons
        lda #14
        ldx autofire
        bne +
        ldx novatime
        beq ++
+       lda #6
+       sta firecool
_r      rts

; tmp0 = type, tmp1 = x offset (signed, rel. to ship x+0), tmp2 = vx, tmp3 = vy, tmp4 = y offset (signed)
spawn_pb
        ldx #N_PB-1
-       lda pb_t,x
        beq +
        dex
        bpl -
        rts
+       lda tmp0
        sta pb_t,x
        ldy #0
        lda tmp1
        bpl +
        dey
+       clc
        adc px_l
        sta pb_xl,x
        tya
        adc px_h
        sta pb_xh,x
        lda py
        clc
        adc tmp4
        sta pb_y,x
        lda tmp2
        sta pb_vx,x
        lda tmp3
        sta pb_vy,x
        lda #$ff
        sta pb_hit,x
        ldy tmp0
        lda pbt_dmg,y
        sta pb_dmg,x
        lda pbt_spr,y
        sta pb_spr,x
        lda pbt_col,y
        sta pb_col,x
        rts
pbt_dmg .byte 0,1,2,1,1,2,1
pbt_spr .byte 0,SPR_SHOT,SPR_LASER,SPR_SIDE,SPR_SHOT,SPR_MISSILE,SPR_BALL
pbt_col .byte 0,7,3,13,15,10,7

; shot macro helper: type, xofs, vx, vy, yofs
SHOT    .macro t, xo, vx, vy, yo
        lda #\t
        sta tmp0
        lda #<\xo
        sta tmp1
        lda #<\vx
        sta tmp2
        lda #<\vy
        sta tmp3
        lda #<\yo
        sta tmp4
        jsr spawn_pb
        .endm

fire_weapons
        inc firectr
        lda mainpow
        ldx novatime
        beq +
        lda #4
+       cmp #2
        bcs +
        #SHOT B_SHOT, 0, 0, -7, -6
        jmp _extra
+       bne +
        #SHOT B_SHOT, -5, 0, -7, -6
        #SHOT B_SHOT, 5, 0, -7, -6
        jmp _extra
+       cmp #3
        bne +
        #SHOT B_SHOT, 0, 0, -7, -8
        #SHOT B_BALL, -4, -1, -6, -4
        #SHOT B_BALL, 4, 1, -6, -4
        jmp _extra
+       #SHOT B_SHOT, -5, 0, -7, -6
        #SHOT B_SHOT, 5, 0, -7, -6
        #SHOT B_BALL, -6, -2, -6, -2
        #SHOT B_BALL, 6, 2, -6, -2
_extra  lda sideshot
        ora novatime
        beq +
        lda firectr
        and #1
        bne +
        #SHOT B_SIDE, -10, -6, 0, 0
        #SHOT B_SIDE, 10, 6, 0, 0
        cpx #N_PB
        bcs +
        lda #SPR_SIDE+1
        sta pb_spr,x
+       lda rearshot
        ora novatime
        beq +
        lda firectr
        and #1
        beq +
        #SHOT B_REAR, 0, 0, 6, 8
+       lda laser
        ora novatime
        beq +
        lda firectr
        and #1
        bne +
        #SHOT B_LASER, 0, 0, -10, -18
+       lda homing
        beq +
        lda firectr
        and #3
        bne +
        #SHOT B_MISS, -8, 0, -4, 0
        #SHOT B_MISS, 8, 0, -4, 0
+       lda #SFX_SHOOT
        jmp sfx_start

; ---------------------------------------------------- bullets update
update_pbullets
        ldx #N_PB-1
_lp     lda pb_t,x
        bne +
        jmp _next
+       cmp #B_MISS
        bne _move
        ; homing: steer x toward target
        lda frame
        and #3
        bne _move
        jsr find_target
        bcc _move
        sec
        sbc pb_cx2,x
        beq _move
        bcc _left
        lda pb_vx,x
        bmi +
        cmp #3
        bcs _move
+       inc pb_vx,x
        jmp _move
_left   lda pb_vx,x
        bpl +
        cmp #$fd
        bcc _move
+       dec pb_vx,x
_move   ldy #0
        lda pb_vx,x
        bpl +
        dey
+       clc
        adc pb_xl,x
        sta pb_xl,x
        tya
        adc pb_xh,x
        sta pb_xh,x
        bpl +
        jmp _kill
+       beq +
        lda pb_xl,x
        cmp #88
        bcc +
        jmp _kill
+       lda pb_y,x
        clc
        adc pb_vy,x
        sta pb_y,x
        cmp #30
        bcc _kill
        cmp #214
        bcs _kill
        ; centre + box
        lda pb_xl,x
        clc
        adc #12
        sta tmp0
        lda pb_xh,x
        adc #0
        sta tmp1
        lsr
        lda tmp0
        ror
        sta pb_cx2,x
        lda pb_y,x
        clc
        adc #10
        sta pb_cy,x
        ldy pb_t,x
        lda pb_cx2,x
        sec
        sbc pbw_tab,y
        bcs +
        lda #1
+       sta pb_x0,x
        lda pb_cx2,x
        clc
        adc pbw_tab,y
        sta pb_x1,x
        lda pb_cy,x
        sec
        sbc pbh_tab,y
        sta pb_y0,x
        lda pb_cy,x
        clc
        adc pbh_tab,y
        sta pb_y1,x
        ; terrain (laser passes)
        lda pb_t,x
        cmp #B_LASER
        beq _next
        stx tmp6
        lda pb_cy,x
        jsr charat
        ldx tmp6
        cmp #0
        bpl _next
_kill   lda #0
        sta pb_t,x
        sta pb_x1,x
_next   dex
        bmi +
        jmp _lp
+       rts
pbw_tab .byte 0,3,3,6,3,3,3
pbh_tab .byte 0,6,10,3,6,4,3

; C=1 and A = target cx2 (boss or nearest live enemy)
find_target
        lda b_on
        beq +
        lda b_cx2
        sec
        rts
+       ldy #N_EN-1
-       lda en_t,y
        beq +
        cmp #E_BUBBLE
        bcs +
        lda en_cx2,y
        beq +
        sec
        rts
+       dey
        bpl -
        clc
        rts
