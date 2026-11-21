; =====================================================================
;  Player ship, weapons, orb satellite
; =====================================================================
W_PULSE = 0
W_LASER = 1
W_SPREAD = 2
W_HOMING = 3

B_PULSE = 1
B_LASER = 2
B_SPREAD = 3
B_MISSILE = 4
B_CHARGE = 5

CHARGEMAX = 48

player_reset
        jsr find_gap
        sta py
        lda #40
        sta px_l
        lda #0
        sta px_h
        sta pstate
        sta weapon
        sta orbon
        sta charge
        sta firecool
        sta pframe
        lda #1
        sta wlevel
        sta pspeed
        lda #120
        sta pinv
        lda py
        sta oy
        lda #1
        sta hudflag
        rts

; find vertical centre of the largest free gap in screen column 6 -> A = sprite y
find_gap
        lda gamemode
        bne +
        lda #120
        rts
+       lda #0
        sta tmp4                ; best len
        sta tmp5                ; best start
        sta tmp2                ; current len
        ldx #0
_lp     lda rowlo,x
        clc
        adc #2
        sta ptr3
        lda front
        bne +
        lda rowhiA,x
        bne ++
+       lda rowhiB,x
+       adc #0
        sta ptr3+1
        ldy #4
-       lda (ptr3),y
        bmi _solid
        dey
        bpl -
        inc tmp2
        lda tmp2
        cmp tmp4
        bcc _nx
        sta tmp4
        txa
        sec
        sbc tmp2
        clc
        adc #1
        sta tmp5
        jmp _nx
_solid  lda #0
        sta tmp2
_nx     inx
        cpx #PFROWS
        bne _lp
        ; y = 50 + (start + len/2)*8 - 9
        lda tmp4
        lsr
        clc
        adc tmp5
        asl
        asl
        asl
        clc
        adc #41
        cmp #52
        bcs +
        lda #52
+       cmp #198
        bcc +
        lda #198
+       rts

kill_player
        lda cheat
        bne +
        lda pinv
        bne +
        lda pstate
        bne +
        lda #1
        sta pstate
        lda #0
        sta ptimer
        sta charge
        lda #SFX_DEATH
        jsr sfx_start
+       rts

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
        jsr player_reset
+       rts
_alive  lda pinv
        beq +
        dec pinv
+       ; ---- movement
        lda #0
        sta pframe
        lda joy
        and #1
        beq _nup
        lda #1
        sta pframe
        lda py
        sec
        sbc pspeed
        cmp #52
        bcs +
        lda #52
+       sta py
_nup    lda joy
        and #2
        beq _ndn
        lda #2
        sta pframe
        lda py
        clc
        adc pspeed
        cmp #198
        bcc +
        lda #198
+       sta py
_ndn    lda joy
        and #4
        beq _nlf
        lda px_l
        sec
        sbc pspeed
        sta px_l
        lda px_h
        sbc #0
        sta px_h
        bne _nlf
        lda px_l
        cmp #28
        bcs _nlf
        lda #28
        sta px_l
_nlf    lda joy
        and #8
        beq _nrt
        lda px_l
        clc
        adc pspeed
        sta px_l
        lda px_h
        adc #0
        sta px_h
        beq _nrt
        lda px_l
        cmp #30                 ; max x = 256+30 = 286
        bcc _nrt
        lda #30
        sta px_l
_nrt    ; ---- collision box centre
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
        adc #9
        sta pcy
        ; ---- terrain collision
        jsr player_terrain
        ; ---- fire
        jsr player_fire
        ; ---- orb
        jmp update_orb

player_terrain
        lda cheat
        bne _ok
        lda pinv
        bne _ok
        ldx #3
_pt     stx tmp6
        lda px_l
        clc
        adc ptx_ofs,x
        sta tmp0
        lda px_h
        adc #0
        sta tmp1
        lda py
        clc
        adc pty_ofs,x
        jsr solid_at
        bcs _hit
        ldx tmp6
        dex
        bpl _pt
_ok     rts
_hit    jmp kill_player
ptx_ofs .byte 20,4,12,12
pty_ofs .byte 9,8,5,13

; in tmp0/1 = x, A = y ; out C=1 if solid (with slope test)
solid_at
        sta tmp4
        jsr charat
        bmi +
        clc
        rts
+       and #$7f
        cmp #8
        beq _su
        cmp #9
        beq _sd
        cmp #18
        beq _cd
        cmp #19
        beq _cu
        sec
        rts
_su     jsr _local              ; floor slope up: solid if ly >= 7-lx
        lda #7
        sec
        sbc tmp2
        cmp tmp3                ; 7-lx <= ly ?
        beq +
        bcc +
        clc
        rts
+       sec
        rts
_sd     jsr _local              ; floor slope down: solid if ly >= lx
        lda tmp3
        cmp tmp2
        rts
_cd     jsr _local              ; ceiling down: solid if ly <= lx
        lda tmp2
        cmp tmp3
        rts
_cu     jsr _local              ; ceiling up: solid if ly <= 7-lx
        lda #7
        sec
        sbc tmp2
        cmp tmp3
        rts
_local  lda tmp2
        and #7
        sta tmp2                ; lx
        lda tmp4
        sec
        sbc #50
        and #7
        sta tmp3                ; ly
        rts

; ---------------------------------------------------- weapons
player_fire
        lda firecool
        beq +
        dec firecool
+       lda joy
        and #$10
        beq _rel
        lda joyprev
        and #$10
        bne +
        lda #0
        sta charge
+       lda charge
        cmp #CHARGEMAX
        bcs +
        inc charge
        lda charge
        cmp #CHARGEMAX
        bne +
        lda #1
        sta barflag
+       lda firecool
        bne _r
        lda #0
        sta skipfire
        jsr fire_weapon
        lda skipfire            ; not enough free slots: retry next frame
        bne _r
        ldx weapon
        lda fire_rate,x
        sta firecool
_r      lda frame
        and #3
        bne +
        lda #1
        sta barflag
+       rts
_rel    lda joyprev
        and #$10
        beq _r2
        lda charge
        cmp #CHARGEMAX
        bne +
        jsr fire_charge
+       lda #0
        sta charge
        lda #1
        sta barflag
_r2     rts
fire_rate .byte 7,9,9,11

; tmp0 = type, tmp1 = yofs (signed), tmp2 = vx, tmp3 = vy, tmp4 = xofs
; uses orb position if tmp5 != 0
spawn_pb
        ldx #N_PB-1
-       lda pb_t,x
        beq +
        dex
        bpl -
        rts
+       lda tmp0
        sta pb_t,x
        ldy tmp5
        bne _fromorb
        lda px_l
        clc
        adc tmp4
        sta pb_xl,x
        lda px_h
        adc #0
        sta pb_xh,x
        lda py
        jmp _sety
_fromorb
        lda ox_l
        clc
        adc tmp4
        sta pb_xl,x
        lda ox_h
        adc #0
        sta pb_xh,x
        lda oy
_sety   clc
        adc tmp1
        sta pb_y,x
        lda tmp2
        sta pb_vx,x
        lda tmp3
        sta pb_vy,x
        lda #$ff
        sta pb_hit,x
        lda #0
        sta pb_age,x
        ldy tmp0
        lda pbt_dmg,y
        sta pb_dmg,x
        lda pbt_spr,y
        sta pb_spr,x
        lda pbt_col,y
        sta pb_col,x
        cpy #B_MISSILE
        bcs _rts
        ; ---- shots drawn as chars: cell of the shot's centre in the playfield grid
        lda #0
        sta pb_dhi,x
        lda pb_y,x
        clc
        adc #256+10-50
        bcc _off
        lsr
        lsr
        lsr
        cmp #PFROWS
        bcs _off
        sta pb_gr,x
        lda pb_xl,x             ; centre x - 24 - xfine
        sec
        sbc #12
        sta ptr2
        lda pb_xh,x
        sbc #0
        sta ptr2+1
        lda ptr2
        sec
        sbc xfine
        sta ptr2
        lda ptr2+1
        sbc #0
        bmi _off
        lsr
        lda ptr2
        ror
        lsr
        lsr
        cmp #39
        bcs _off
        sta pb_gc,x
        lda pb_vy,x             ; rows per frame: half the old pixel speed
        cmp #$80
        ror
        sta pb_vy,x
_rts    rts
_off    lda #0
        sta pb_t,x
        rts
pbt_dmg .byte 0,1,2,1,2,12
pbt_spr .byte 0,SPR_PULSE,SPR_LASER,SPR_SPREAD,SPR_MISSILE,SPR_CHARGE
pbt_col .byte 0,7,3,13,10,7

fire_weapon
        lda #0
        sta tmp5
        lda #12
        sta tmp4
        lda weapon
        cmp #W_LASER
        beq _laser
        cmp #W_SPREAD
        beq _spread
        cmp #W_HOMING
        bne +
        jmp _homing
+       ; pulse
        lda #B_PULSE
        sta tmp0
        lda #7
        sta tmp2
        lda #0
        sta tmp3
        lda wlevel
        cmp #2
        beq +
        lda #0
        sta tmp1
        jsr spawn_pb
        jmp _orb
+       lda #$fc               ; (one char row above and below)
        sta tmp1
        jsr spawn_pb
        lda #4
        sta tmp1
        jsr spawn_pb
        jmp _orb
_laser  lda #B_LASER
        sta tmp0
        lda #10
        sta tmp2
        lda #0
        sta tmp3
        lda #16
        sta tmp4
        lda wlevel
        cmp #2
        beq +
        lda #0
        sta tmp1
        jsr spawn_pb
        jmp _orbl
+       lda #$fc
        sta tmp1
        jsr spawn_pb
        lda #4
        sta tmp1
        jsr spawn_pb
_orbl   lda #SFX_LASER
        jsr sfx_start
        jmp _orb2
_spread ldy #0                  ; count free bullet slots
        ldx #N_PB-1
-       lda pb_t,x
        bne +
        iny
+       dex
        bpl -
        lda wlevel
        cmp #2
        bne +
        cpy #5
        bcs _spgo
        bcc _spno
+       cpy #3
        bcs _spgo
_spno   lda #1                  ; fire the full fan or nothing
        sta skipfire
        rts
_spgo   lda #B_SPREAD
        sta tmp0
        lda #6
        sta tmp2
        lda #0
        sta tmp1
        sta tmp3
        jsr spawn_pb
        lda #$fe
        sta tmp3
        jsr spawn_pb
        lda #2
        sta tmp3
        jsr spawn_pb
        lda wlevel
        cmp #2
        bne _orb
        lda #5
        sta tmp2
        lda #$fc
        sta tmp3
        jsr spawn_pb
        lda #4
        sta tmp3
        jsr spawn_pb
        jmp _orb
_homing lda #B_MISSILE
        sta tmp0
        lda #5
        sta tmp2
        lda #$fc
        sta tmp1
        lda #$ff
        sta tmp3
        jsr spawn_pb
        lda #4
        sta tmp1
        lda #1
        sta tmp3
        jsr spawn_pb
        lda wlevel
        cmp #2
        bne _orb
        lda #0
        sta tmp1
        sta tmp3
        lda #6
        sta tmp2
        jsr spawn_pb
_orb    lda #SFX_SHOOT
        jsr sfx_start
_orb2   lda orbon
        beq +
        lda #1
        sta tmp5
        lda #B_PULSE
        sta tmp0
        lda #7
        sta tmp2
        lda #0
        sta tmp1
        sta tmp3
        lda #8
        sta tmp4
        jsr spawn_pb
+       rts

fire_charge
        lda #B_CHARGE
        sta tmp0
        lda #8
        sta tmp2
        lda #0
        sta tmp1
        sta tmp3
        sta tmp5
        lda #14
        sta tmp4
        jsr spawn_pb
        lda #38
        sta tmp4
        jsr spawn_pb
        cpx #N_PB
        bcs +
        lda #SPR_CHARGE+1
        sta pb_spr,x
+       lda #SFX_CHARGE
        jmp sfx_start

; ---------------------------------------------------- bullets update
update_pbullets
        ldx #N_PB-1
_lp     lda pb_t,x
        bne +
        jmp _next
+       inc pb_age,x
        cmp #B_MISSILE
        bcs +
        jmp _char
+       ; homing steering
        bne _move
        lda pb_age,x
        and #3
        bne _move
        jsr find_target         ; A = target y or $ff
        cmp #$ff
        beq _move
        sec
        sbc pb_y,x
        beq _move
        bcc _up
        lda pb_vy,x
        bmi +
        cmp #3
        bcs _move
+       inc pb_vy,x
        jmp _move
_up     lda pb_vy,x
        bpl +
        cmp #$fd
        bcc _move
+       dec pb_vy,x
_move   lda pb_xl,x
        clc
        adc pb_vx,x
        sta pb_xl,x
        lda pb_xh,x
        adc #0
        sta pb_xh,x
        beq +
        lda pb_xl,x
        cmp #88
        bcc +
        jmp _kill
+       lda pb_y,x
        clc
        adc pb_vy,x
        sta pb_y,x
        cmp #36
        bcc _kill
        cmp #212
        bcs _kill
        ; centre
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
        ; collision box
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
        ; terrain (not for charge beam)
        lda pb_t,x
        cmp #B_CHARGE
        beq _next
        lda tmp0
        clc
        adc #4
        sta tmp0
        bcc +
        inc tmp1
+       stx tmp6
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

        ; ---- shots drawn as chars: two columns per frame, 0..2 rows up or down
_char   lda pb_age,x
        cmp #1
        beq _cpos               ; first frame: at the nose of the ship
        lda nx_cshift           ; the grid moved one column on a coarse step
        beq +
        dec pb_gc,x
+       lda pb_gc,x
        clc
        adc #2
        cmp #39
        bcs _kill
        sta pb_gc,x
        lda pb_gr,x
        clc
        adc pb_vy,x
        cmp #PFROWS
        bcs _kill
        sta pb_gr,x
_cpos   ldy pb_gr,x             ; its cell in the screen shown next
        lda rowlo,y
        clc
        adc pb_gc,x
        sta pb_alo,x
        lda rowhiA,y
        adc #0
        ldy front
        beq +
        clc
        adc #(SCRB-SCRA)>>8
+       sta pb_ahi,x
        lda pb_alo,x            ; ptr2 = cell - 41
        sec
        sbc #41
        sta ptr2
        lda pb_ahi,x
        sbc #0
        sta ptr2+1
        ldy #41
        lda (ptr2),y
        bmi _ckill              ; terrain
        lda pb_age,x
        cmp #1
        beq _cbox
        lda pb_vy,x             ; the cell it passed
        clc
        adc #2
        tay
        lda pass_ofs,y
        tay
        lda (ptr2),y
        bmi _ckill
_cbox   lda pb_gc,x             ; box: the cell passed and the cell (cx2 units)
        asl
        asl
        sta tmp0
        lda xfine
        lsr
        sec                     ; + 8
        adc #7
        adc tmp0
        sta pb_x0,x
        adc #8
        sta pb_x1,x
        lda pb_gr,x             ; y of the row: 50 + 8 row
        asl
        asl
        asl
        adc #50
        sta tmp0
        lda pb_vy,x
        clc
        adc #2
        tay
        lda tmp0
        clc
        adc pass_y0,y
        sta pb_y0,x
        lda tmp0
        clc
        adc pass_y1,y
        sta pb_y1,x
        jmp _next
_ckill  jmp _kill
pass_ofs .byte 41+39, 41-1, 41-1, 41-1, 41-41     ; by rows per frame -2..2
pass_y0  .byte 1, 1, 1, 1, $f9
pass_y1  .byte 14, 6, 6, 6, 6

; returns A = y of a target (boss or first live enemy), $ff if none
find_target
        lda b_on
        beq +
        lda b_y
        clc
        adc #22
        rts
+       ldy #N_EN-1
-       lda en_t,y
        beq +
        cmp #E_POWERUP
        bcs +
        lda en_y,y
        rts
+       dey
        bpl -
        lda #$ff
        rts

; ---------------------------------------------------- orb satellite
update_orb
        lda orbon
        beq _r
        ; target = player + 26
        lda px_l
        clc
        adc #26
        sta tmp0
        lda px_h
        adc #0
        sta tmp1
        ; dx = target - ox (16 bit), ox += dx/4
        lda tmp0
        sec
        sbc ox_l
        sta tmp2
        lda tmp1
        sbc ox_h
        sta tmp3
        ldy #2
-       lda tmp3
        cmp #$80
        ror tmp3
        ror tmp2
        dey
        bne -
        lda ox_l
        clc
        adc tmp2
        sta ox_l
        lda ox_h
        adc tmp3
        sta ox_h
        ; y
        lda py
        sec
        sbc oy
        cmp #$80
        ror
        cmp #$80
        ror
        clc
        adc oy
        sta oy
        ; centre
        lda ox_l
        clc
        adc #12
        sta tmp0
        lda ox_h
        adc #0
        lsr
        lda tmp0
        ror
        sta ocx2
        lda oy
        clc
        adc #10
        sta ocy
_r      rts

; ---------------------------------------------------- shots drawn as chars
; Called before scroll_update: takes the shots of the last frame out of the
; screen. On a coarse scroll step the old screen is still shown this frame and
; gets overwritten later by the screen shift, so the chars stay; only their
; colour RAM cells are repaired in the next frame, after the colour shift.
shots_erase
        ldx nfix                ; colour cells left from the last coarse step
        beq _nofix
-       dex
        lda fix_lo,x
        sta ptr2
        lda fix_hi,x
        sta ptr2+1
        lda fix_c,x
        ldy #0
        sta (ptr2),y
        txa
        bne -
        stx nfix
_nofix  lda scrolling
        beq _erase
        lda xfine
        bne _erase
        ; ---- coarse step this frame
        ldx #N_PB-1
_cl     lda pb_dhi,x
        beq _cn
        ldy nfix
        lda pb_dlo,x            ; colour cell one column left (after the shift)
        sec
        sbc #1
        sta fix_lo,y
        lda pb_dhi,x
        and #3
        ora #$d8
        sbc #0
        sta fix_hi,y
        lda pb_bg,x
        tay
        lda charcol,y
        ldy nfix
        sta fix_c,y
        inc nfix
        lda #0
        sta pb_dhi,x
_cn     dex
        bpl _cl
        rts
_erase  ldx #N_PB-1
_el     lda pb_dhi,x
        beq _en
        sta ptr2+1
        and #3
        ora #$d8
        sta ptr3+1
        lda pb_dlo,x
        sta ptr2
        sta ptr3
        ldy pb_bg,x
        lda charcol,y
        ldy #0
        sta (ptr3),y
        lda pb_bg,x
        sta (ptr2),y
        tya
        sta pb_dhi,x
_en     dex
        bpl _el
        rts

; Called after update_pbullets: draws the shots into the screen shown next.
shots_draw
        ldx #N_PB-1
_lp     lda pb_t,x
        beq _nx
        cmp #B_MISSILE
        bcs _nx
        tay
        lda shot_gly-1,y
        sta tmp0
        lda shot_col-1,y
        sta tmp1
        lda pb_alo,x
        sta ptr2
        sta ptr3
        lda pb_ahi,x
        sta ptr2+1
        and #3
        ora #$d8
        sta ptr3+1
        ldy #0
        lda (ptr2),y
        cmp #CH_SHOT
        bcc +
        cmp #CH_SHOT+3
        bcc _nx                 ; another shot is drawn there already
+       sta pb_bg,x
        lda tmp0
        sta (ptr2),y
        lda nx_cshift           ; coarse step: the colour RAM moves one column
        beq +                   ; left at the end of this frame
        iny
+       lda tmp1
        sta (ptr3),y
        lda ptr2
        sta pb_dlo,x
        lda ptr2+1
        sta pb_dhi,x
_nx     dex
        bpl _lp
        rts
shot_gly .byte CH_SHOT, CH_SHOT+1, CH_SHOT+2           ; pulse, laser, spread
shot_col .byte 7, 3, 1
