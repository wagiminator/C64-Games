; =====================================================================
;  Player: controls, physics, landing, items, camera
; =====================================================================

player_update
        jsr joyread
        sta joy
        lda DBGAI
        beq +
        jsr autopilot
+       lda joy
        eor joyprev
        and joy
        sta joynew
        lda joy
        sta joyprev
        lda psq
        beq +
        dec psq
+       lda pshoot
        beq +
        dec pshoot
+       lda ps
        cmp #PS_FALL
        bcc _alive
        beq _fall
        cmp #PS_HOLE
        bne _r
        jmp hole_pull
_fall   jmp fall_move
_alive  jsr steer
        jsr shoot
        lda ps
        bne _pow
        jsr gravity
        jsr move_y
        lda vyi
        bpl +
        jsr land_check
+       jsr item_check
        jmp death_check
_pow    ; propeller hat / jetpack: constant climb
        dec ptime
        bne +
        lda #PS_NORM
        sta ps
+       lda frame
        and #7
        bne _mv
        ldy #SFX_HAT
        lda ps
        cmp #PS_JET
        bne +
        ldy #SFX_JET
+       tya
        jsr sfx_start
_mv     jmp move_y
_r      rts

; ---------------------------------------------------- horizontal control
steer
        lda joy
        and #4
        beq _nl
        lda #1
        sta pface
        lda vxf
        sec
        sbc #<ACC
        sta vxf
        lda vxi
        sbc #>ACC
        sta vxi
        bmi _clamp
        lda vxf                 ; still moving right: turn faster
        sec
        sbc #<ACC
        sta vxf
        lda vxi
        sbc #>ACC
        sta vxi
        jmp _clamp
_nl     lda joy
        and #8
        beq _fric
        lda #0
        sta pface
        lda vxf
        clc
        adc #<ACC
        sta vxf
        lda vxi
        adc #>ACC
        sta vxi
        bpl _clamp
        lda vxf
        clc
        adc #<ACC
        sta vxf
        lda vxi
        adc #>ACC
        sta vxi
        jmp _clamp
_fric   lda vxi
        bmi _fn
        ora vxf
        beq _move
        lda vxf
        sec
        sbc #<FRICT
        sta vxf
        lda vxi
        sbc #>FRICT
        sta vxi
        bpl _move
        jmp _zero
_fn     lda vxf
        clc
        adc #<FRICT
        sta vxf
        lda vxi
        adc #>FRICT
        sta vxi
        bmi _move
_zero   lda #0
        sta vxf
        sta vxi
        jmp _move
_clamp  lda vxi
        bmi _cn
        cmp #>MAXVX
        bcc _move
        bne +
        lda vxf
        cmp #<MAXVX
        bcc _move
+       lda #<MAXVX
        sta vxf
        lda #>MAXVX
        sta vxi
        jmp _move
_cn     cmp #>-MAXVX
        bcc +
        bne _move
        lda vxf
        cmp #<-MAXVX
        bcs _move
+       lda #<-MAXVX
        sta vxf
        lda #>-MAXVX
        sta vxi
_move   ; x += vx, wrap around 0..159
        lda pxf
        clc
        adc vxf
        sta pxf
        lda pxi
        adc vxi
        ldx vxi
        bmi _wl
        cmp #160
        bcc +
        sbc #160
        jmp +
_wl     cmp #160
        bcc +
        adc #160-1              ; carry set: +160
+       sta pxi
        rts

; ---------------------------------------------------- vertical
gravity
        lda vyf
        sec
        sbc #<G
        sta vyf
        lda vyi
        sbc #>G
        sta vyi
        bpl +
        cmp #>MAXFALL
        bcs +
        lda #<MAXFALL
        sta vyf
        lda #>MAXFALL
        sta vyi
+       rts

move_y
        lda pyl
        sta yol
        lda pyh
        sta yoh
        lda pyf
        clc
        adc vyf
        sta pyf
        lda vyi
        and #$80
        beq +
        lda #$ff
+       sta tmp0
        lda pyl
        adc vyi
        sta pyl
        lda pyh
        adc tmp0
        sta pyh
        rts

; ---------------------------------------------------- object geometry
; landing height of object X -> restl/resth, carry clear; carry set if not a platform
obj_rest
        lda o_t,x
        cmp #T_PLAT
        bcc _no
        cmp #T_HAT
        bcc _ok
        cmp #T_MOON
        bne _no
        ; moon: top char row = row + MOON_H - 1, surface MOON_TOP pixels down
        lda o_rl,x
        clc
        adc #MOON_H-1
        sta restl
        lda o_rh,x
        adc #0
        sta resth
        lda #8-MOON_TOP
        jmp _mul
_ok     lda o_rl,x
        sta restl
        lda o_rh,x
        sta resth
        lda o_t,x
        cmp #T_SPRING
        lda #7
        bcc _mul
        lda #5
_mul    sta tmp0
        asl restl
        rol resth
        asl restl
        rol resth
        asl restl
        rol resth
        lda restl
        clc
        adc tmp0
        sta restl
        bcc +
        inc resth
+       clc
        rts
_no     sec
        rts

; horizontal span of object X (multicolour pixels) -> tmp5 .. tmp6
obj_span
        lda o_t,x
        cmp #T_MOVE
        bne +
        lda o_x,x
        clc
        adc #1
        sta tmp5
        adc #13
        sta tmp6
        rts
+       lda o_x,x
        asl
        asl
        sta tmp5
        lda o_t,x
        cmp #T_SPRING
        beq _sp
        cmp #T_MOON
        beq _mo
        cmp #T_HAT
        bcs _it
        inc tmp5
        lda tmp5
        clc
        adc #13
        sta tmp6
        rts
_sp     lda tmp5
        clc
        adc #3
        sta tmp6
        rts
_it     lda tmp5
        clc
        adc #7
        sta tmp6
        rts
_mo     lda tmp5
        clc
        adc #8
        sta tmp5
        adc #23
        sta tmp6
        rts

; does the player's feet span overlap tmp5..tmp6?  carry set = yes
feet_overlap
        lda pxi
        clc
        adc #2
        sta tmp2                ; left foot
        adc #7
        sta tmp3                ; right foot
        cmp tmp5
        bcc _wrap
        lda tmp6
        cmp tmp2
        bcc _wrap
        sec
        rts
_wrap   lda tmp3                ; the part wrapped around to the left edge
        cmp #160
        bcc _no
        sbc #160
        cmp tmp5
        bcc _no
        sec
        rts
_no     clc
        rts

; ---------------------------------------------------- landing on platforms (falling only)
land_check
        lda #$ff
        sta tmp4                ; best object
        ldx #NOBJ-1
_l      jsr obj_rest
        bcs _n
        ; yold >= rest ?
        lda yol
        cmp restl
        lda yoh
        sbc resth
        bmi _n
        ; ynew < rest ?
        lda pyl
        cmp restl
        lda pyh
        sbc resth
        bpl _n
        jsr obj_span
        jsr feet_overlap
        bcc _n
        lda o_t,x
        cmp #T_BREAK
        bne _cand
        lda #T_BROKE
        sta o_t,x
        lda #0
        sta o_tm,x
        lda #SFX_BREAK
        jsr sfx_start
        jmp _n
_cand   lda tmp4
        bmi _take
        ; higher than the best so far?
        lda restl
        cmp bestl
        lda resth
        sbc besth
        bmi _n
_take   stx tmp4
        lda restl
        sta bestl
        lda resth
        sta besth
_n      dex
        bpl _l
        ldx tmp4
        bmi _r
        ; land
        lda bestl
        sta pyl
        lda besth
        sta pyh
        lda #0
        sta pyf
        lda o_t,x
        cmp #T_SPRING
        beq _spring
        cmp #T_MOON
        beq _moon
        cmp #T_VAN
        bne +
        lda #T_POOF
        sta o_t,x
        lda #8
        sta o_tm,x
        lda #SFX_POOF
        jsr sfx_start
+       lda #<JUMPV
        sta vyf
        lda #>JUMPV
        sta vyi
        lda #6
        sta psq
        lda #SFX_JUMP
        jmp sfx_start
_spring lda #1
        sta o_st,x
        lda #<SPRINGV
        sta vyf
        lda #>SPRINGV
        sta vyi
        lda #8
        sta psq
        lda #SFX_SPRING
        jmp sfx_start
_moon   lda #0
        sta vyf
        sta vyi
        sta vxf
        sta vxi
        lda #PS_MOON
        sta ps
        lda #120
        sta dtimer
        lda #SFX_LAND
        jmp sfx_start
_r      rts

; ---------------------------------------------------- items: propeller hat, jetpack
item_check
        ldx #NOBJ-1
_i      lda o_t,x
        cmp #T_HAT
        beq +
        cmp #T_JET
        bne _n
+       ; item y range: row*8 .. row*8 + 8h - 1
        lda o_rl,x
        sta restl
        lda o_rh,x
        asl restl
        rol
        asl restl
        rol
        asl restl
        rol
        sta resth
        ; player top (py + 17) >= item bottom ?
        lda pyl
        clc
        adc #17
        sta tmp0
        lda pyh
        adc #0
        sta tmp1
        lda tmp0
        cmp restl
        lda tmp1
        sbc resth
        bmi _n
        ; py <= item top (bottom + 7 or + 15) ?
        lda o_t,x
        cmp #T_JET
        lda #7
        bcc +
        lda #15
+       clc
        adc restl
        sta tmp0
        lda resth
        adc #0
        sta tmp1
        lda tmp0
        cmp pyl
        lda tmp1
        sbc pyh
        bmi _n
        jsr obj_span
        jsr feet_overlap
        bcc _n
        ; got it
        lda o_t,x
        pha
        lda #T_DEAD
        sta o_t,x
        pla
        cmp #T_JET
        beq _jet
        lda #PS_HAT
        sta ps
        lda #HATTIME
        sta ptime
        lda #<HATV
        sta vyf
        lda #>HATV
        sta vyi
        jmp _snd
_jet    lda #PS_JET
        sta ps
        lda #JETTIME
        sta ptime
        lda #<JETV
        sta vyf
        lda #>JETV
        sta vyi
_snd    lda #SFX_PICKUP
        jmp sfx_start
_n      dex
        bpl _i
        rts

; ---------------------------------------------------- shooting
shoot
        lda ps
        bne _r
        lda joynew
        and #$10
        beq _r
        lda b_on
        bne _r
        lda #1
        sta b_on
        lda pxi
        clc
        adc #5
        cmp #160
        bcc +
        sbc #160
+       sta b_x
        lda pyl
        clc
        adc #20
        sta b_yl
        lda pyh
        adc #0
        sta b_yh
        lda #14
        sta pshoot
        lda #SFX_SHOOT
        jmp sfx_start
_r      rts

; ---------------------------------------------------- falling off the bottom
; below the screen: py < cam - 215
death_check
        lda pyl
        clc
        adc #215
        sta tmp0
        lda pyh
        adc #0
        sta tmp1
        lda tmp0
        cmp caml
        lda tmp1
        sbc camh
        bpl _r
        lda cheat
        beq _lost
        ; cheat: the safety net throws the hero back up
        lda #<SPRINGV
        sta vyf
        lda #>SPRINGV
        sta vyi
        lda #SFX_SPRING
        jmp sfx_start
_lost   lda #PS_FALL
        sta ps
        lda #40
        sta dtimer
        lda #SFX_FALL
        jmp sfx_start
_r      rts

; lost: keep falling, count down once below the screen
fall_move
        jsr gravity
        jsr move_y
        lda pyl
        clc
        adc #215
        sta tmp0
        lda pyh
        adc #0
        sta tmp1
        lda tmp0
        cmp caml
        lda tmp1
        sbc camh
        bpl +
        lda dtimer
        beq +
        dec dtimer
+       rts

; sucked into a black hole: move to its centre
hole_pull
        lda m_x
        cmp pxi
        beq +
        bcc _l
        inc pxi
        bne +
_l      dec pxi
+       ; y towards m_y + 4
        lda m_yl
        clc
        adc #2
        sta tmp0
        lda m_yh
        adc #0
        sta tmp1
        lda pyl
        cmp tmp0
        lda pyh
        sbc tmp1
        bcs _dn
        inc pyl
        bne +
        inc pyh
        jmp +
_dn     lda pyl
        bne *+4
        dec pyh
        dec pyl
+       lda dtimer
        beq +
        dec dtimer
+       rts

; ---------------------------------------------------- camera follows the hero upwards
camera_update
        lda ps
        cmp #PS_FALL
        bcs _r
        lda pyl
        clc
        adc #CAMLINE
        sta tmp0
        lda pyh
        adc #0
        sta tmp1
        lda tmp0
        sec
        sbc caml
        sta tmp2
        lda tmp1
        sbc camh
        bcc _r                  ; below the camera line
        beq +
        lda #255                ; (only at the start)
        sta tmp2
+       lda tmp2
        beq _r
        lda tmp0
        sta caml
        lda tmp1
        sta camh
        ; score += delta (binary -> BCD, one by one; at most a few per frame)
        lda tmp2
        jsr score_addbin
_r      lda caml
        sta trl
        lda camh
        lsr
        ror trl
        lsr
        ror trl
        lsr
        ror trl
        sta trh
        ; height and level
        lda caml
        sec
        sbc #<CAM0
        sta hgtl
        lda camh
        sbc #>CAM0
        sta hgth
        tay
        lda lvltab,y
        sta lvl
        rts

; ---------------------------------------------------- autopilot (testing only)
autopilot
        lda #0
        sta joy
        ; target: highest platform below the feet (+ 40 px while rising)
        lda pyl
        sta yol
        lda pyh
        sta yoh
        lda vyi
        bmi +
        lda yol
        clc
        adc #40
        sta yol
        bcc +
        inc yoh
+       lda #$ff
        sta tmp4
        ldx #NOBJ-1
_l      lda o_t,x
        cmp #T_BREAK
        beq _n
        jsr obj_rest
        bcs _n
        lda restl
        cmp yol
        lda resth
        sbc yoh
        bpl _n
        lda tmp4
        bmi _t
        lda restl
        cmp bestl
        lda resth
        sbc besth
        bmi _n
_t      stx tmp4
        lda restl
        sta bestl
        lda resth
        sta besth
_n      dex
        bpl _l
        ldx tmp4
        bmi _fire
        jsr obj_span
        lda tmp5
        clc
        adc tmp6
        ror
        sec
        sbc #6                  ; target pxi
        sec
        sbc pxi                 ; signed distance (mod 160)
        beq _fire
        bcs +
        adc #160
+       cmp #3
        bcc _fire
        cmp #80
        bcs _left
        lda #8
        sta joy
        jmp _fire
_left   cmp #158
        bcs _fire
        lda #4
        sta joy
_fire   ; shoot at a monster above
        lda m_t
        beq _r
        cmp #M_HOLE
        bcs _r
        lda m_x
        sec
        sbc pxi
        clc
        adc #6
        cmp #10
        bcs _r
        lda frame
        and #4
        beq _r
        lda joy
        ora #$10
        sta joy
_r      rts
