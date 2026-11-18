; =====================================================================
;  The runner: lanes, jumping, sliding, animation, sprites, boulder
; =====================================================================

lane_x  .byte 112, 160, 208

reset_runner
        lda #1
        sta plane
        lda #160
        sta px
        lda #0
        sta pjh
        sta pjh+1
        sta pvy
        sta pvy+1
        sta pjump
        sta pslide
        sta panim
        sta pdead
        sta stumble
        sta pflash
        rts

; ---------------------------------------------------- input and movement (once per update)
runner_update
        jsr read_input
        ; ---- lane change
        lda joynew
        and #4                  ; left
        beq +
        lda plane
        beq +
        sec
        sbc #1
        jsr try_lane
+       lda joynew
        and #8                  ; right
        beq +
        lda plane
        cmp #2
        beq +
        clc
        adc #1
        jsr try_lane
+       ; ---- jump (up or fire)
        lda joynew
        and #$11
        beq +
        lda pjump
        bne +
        jsr start_jump
+       ; ---- slide (down)
        lda joynew
        and #2
        beq _noslide
        lda pjump
        beq +
        ; in the air: drop fast
        lda #$f8
        sta pvy+1
        lda #0
        sta pvy
+       lda #16
        sta pslide
        lda #SFX_SLIDE
        jsr sfx_start
_noslide
        ; ---- move towards the lane
        ldx plane
        lda lane_x,x
        sec
        sbc px
        beq _xok
        bcc _left
        cmp #12
        bcc +
        lda #12
+       clc
        adc px
        sta px
        jmp _xok
_left   eor #$ff
        adc #1
        cmp #12
        bcc +
        lda #12
+       sta tmp0
        lda px
        sec
        sbc tmp0
        sta px
_xok    ; ---- jump physics
        lda pjump
        beq _ground
        lda pjh
        clc
        adc pvy
        sta pjh
        lda pjh+1
        adc pvy+1
        sta pjh+1
        bmi _land
        ; gravity
        lda pvy
        sec
        sbc grav
        sta pvy
        lda pvy+1
        sbc #0
        sta pvy+1
        jmp _anim
_land   lda #0
        sta pjh
        sta pjh+1
        sta pjump
        lda pslide
        beq _anim
        lda #SFX_SLIDE
        jsr sfx_start
        jmp _anim
_ground lda pslide
        beq _anim
        dec pslide
_anim   inc panim
        rts

grav    .byte $9a

start_jump
        lda #1
        sta pjump
        lda #0
        sta pslide
        sta pvy
        lda #6
        ldx pw_t+1              ; boots: higher jumps
        beq +
        lda #9
+       sta pvy+1
        lda #SFX_JUMP
        jmp sfx_start

; A = new lane: blocked -> stumble
try_lane
        sta tmp4
        jsr lane_blocked
        bcs _bump
        lda tmp4
        sta plane
        lda #SFX_LANE
        jmp sfx_start
_bump   jmp do_stumble

do_stumble
        lda cheat
        bne +
        lda stumble
        beq _first
        lda #2                  ; second stumble: the boulder gets you
        sta pdead
+       rts
_first  lda #120
        sta stumble
        lda #SFX_BUMP
        jmp sfx_start

; joystick + autopilot
read_input
        jsr joyread
        sta joy
        lda DBGAI
        beq +
        jsr autopilot
        lda joy
        cmp joyprev
        bne +
        lda #0                  ; release, so the next press counts again
        sta joy
+       lda joy
        eor joyprev
        and joy
        sta joynew
        lda joy
        sta joyprev
        rts

; ---------------------------------------------------- runner sprite shadows
runner_sprites
        lda px
        clc
        adc #12
        sta ps_x
        lda #0
        sta ps_xh
        ; colours (flash when the amulet saved you)
        lda #8
        sta ps_c0
        lda #6
        sta ps_c1
        lda pflash
        beq +
        dec pflash
        and #2
        beq +
        lda #1
        sta ps_c0
        sta ps_c1
+       lda pdead
        bne _fall
        lda pslide
        beq +
        lda pjump
        beq _slide
+       lda pjump
        bne _jump
        ; running: 4 frames
        lda panim
        lsr
        and #3
        asl
        clc
        adc #SPR_RUN0T
        sta ps_p0
        adc #1
        sta ps_p1
        lda #0
        jmp _ypos
_jump   lda #SPR_JUMPT
        sta ps_p0
        lda #SPR_JUMPB
        sta ps_p1
        lda pjh+1
        jmp _ypos
_slide  lda #SPR_BLANK
        sta ps_p0
        lda #SPR_SLIDEB
        sta ps_p1
        lda #50+RUNY-19
        sta ps_y1
        sta ps_y0
        rts
_fall   lda #SPR_BLANK
        sta ps_p0
        lda #SPR_FALLB
        ldx bouly
        cpx #36
        bcc +
        lda #SPR_BLANK          ; under the boulder
+       sta ps_p1
        lda #50+RUNY-19
        sta ps_y1
        sta ps_y0
        rts
_ypos   sta tmp0
        lda #50+RUNY-12
        sec
        sbc tmp0
        sta ps_y1
        sec
        sbc #21
        sta ps_y0
        rts

; ---------------------------------------------------- boulder (behind the runner)
; bouly = lines of the boulder visible above the screen bottom (0 = gone)
boulder_update
        lda pdead
        bne _r
        ldx #0
        lda stumble
        beq +
        dec stumble
        ldx #26
+       stx tmp0
        lda bouly
        cmp tmp0
        beq _r
        bcc _up
        dec bouly
_r      rts
_up     inc bouly
        inc bouly
        rts

; add the two boulder sprites to the candidates
boulder_sprites
        lda bouly
        bne +
        rts
+       ; animation phase 0..2 -> first sprite of the phase (4 sprites each)
        lda frame
        lsr
        lsr
        and #3
        cmp #3
        bne +
        lda #0
+       asl
        asl
        clc
        adc #SPR_BOUL0L
        sta tmp0
        ; upper half
        lda #250
        sec
        sbc bouly
        sta tmp1
        jsr boulder_pair
        ; lower half when the boulder is higher than one sprite
        lda bouly
        cmp #43
        bcc +
        lda tmp1
        clc
        adc #42
        sta tmp1
        lda tmp0
        clc
        adc #2
        sta tmp0
        jsr boulder_pair
+       rts

; two expanded sprites side by side: top line tmp1, pointer tmp0 / tmp0+1
boulder_pair
        ldx cv_n
        cpx #NV-1
        bcs _r
        lda tmp1
        sta cv_y,x
        sta cv_y+1,x
        lda #136
        sta cv_x,x
        lda #184
        sta cv_x+1,x
        lda #0
        sta cv_xh,x
        sta cv_xh+1,x
        lda tmp0
        sta cv_p,x
        clc
        adc #1
        sta cv_p+1,x
        lda #12
        sta cv_c,x
        sta cv_c+1,x
        lda #3
        sta cv_e,x
        sta cv_e+1,x
        lda #42
        sta cv_h,x
        sta cv_h+1,x
        inc cv_n
        inc cv_n
_r      rts

; ---------------------------------------------------- sort the candidates and fill the sprite list
build_sprites
        jsr boulder_sprites
        ; insertion sort of indices by y
        ldx #0
-       cpx cv_n
        beq _sorted
        txa
        sta cv_ord,x
        ; move down while the previous is lower on the screen
        stx tmp0
        ldy tmp0
_ins    cpy #0
        beq _nx
        lda cv_ord-1,y
        tax
        lda cv_y,x
        ldx cv_ord,y
        cmp cv_y,x
        bcc _nx
        beq _nx
        ; swap
        lda cv_ord-1,y
        pha
        lda cv_ord,y
        sta cv_ord-1,y
        pla
        sta cv_ord,y
        dey
        jmp _ins
_nx     ldx tmp0
        inx
        jmp -
_sorted ; accept into the list being built
        lda vbuf
        sta tmp1                ; first entry
        tax
        ldy #0
_acc    cpy cv_n
        beq _end
        sty tmp2
        lda cv_ord,y
        tay                     ; candidate
        txa
        sec
        sbc tmp1
        cmp #6
        bcc _ok
        ; needs the sprite of entry X-6 to be finished
        lda vs_y-6,x
        clc
        adc vs_h-6,x
        adc #3
        cmp cv_y,y
        bcs _skip
_ok     lda cv_y,y
        sta vs_y,x
        lda cv_x,y
        sta vs_x,x
        lda cv_xh,y
        sta vs_xh,x
        lda cv_p,y
        sta vs_p,x
        lda cv_c,y
        sta vs_c,x
        lda cv_e,y
        sta vs_e,x
        lda cv_h,y
        sta vs_h,x
        inx
_skip   ldy tmp2
        iny
        jmp _acc
_end    txa
        sec
        sbc tmp1
        ldx tmp1
        sta vs_cnt,x
        rts

; ---------------------------------------------------- autopilot (testing): dodge what comes
; per lane: distance and type of the nearest obstacle ahead
autopilot
        lda #0
        sta joy
        ldx #2
-       lda #255
        sta ai_d,x
        lda #0
        sta ai_t,x
        dex
        bpl -
        ldx ohead
_l      cpx otail
        beq _scan
        lda o_t,x
        beq _n
        cmp #OB_COIN
        bcs _n
        lda o_zh,x
        bne _n
        lda o_zl,x
        sec
        sbc #ZRUN-10
        bcc _n
        cmp #150
        bcs _n
        ldy o_ln,x
        cmp ai_d,y
        bcs _n
        sta ai_d,y
        lda o_t,x
        sta ai_t,y
_n      inx
        txa
        and #NO-1
        tax
        jmp _l
_scan   jsr runner_lane
        tay
        lda ai_d,y
        cmp #90
        bcs _r
        lda ai_t,y
        cmp #OB_BAR
        beq _slide
        cmp #OB_BARR
        beq _jump
        ; block: go to a neighbour lane that is safer
        lda #255
        sta tmp2
        sta tmp3
        cpy #0
        beq +
        lda ai_d-1,y
        jsr ai_cost
        sta tmp2                ; left
+       cpy #2
        beq +
        lda ai_d+1,y
        jsr ai_cost
        sta tmp3                ; right
+       lda tmp2
        cmp tmp3
        bcc _left
        beq +
        jmp _right
+       lda aiturn
        eor #1
        sta aiturn
        beq _left
_right  lda tmp3
        cmp #255
        beq _r
        lda #8
        sta joy
        rts
_left   lda tmp2
        cmp #255
        beq _r
        lda #4
        sta joy
        rts
_jump   lda ai_d,y
        cmp #75
        bcs _r
        lda #1
        sta joy
        rts
_slide  lda ai_d,y
        cmp #40
        bcs _r
        lda #2
        sta joy
_r      rts

; A = distance of the nearest obstacle in a lane (X = lane+-1 via Y) -> cost (low = good)
ai_cost
        cmp #40
        bcs +
        lda #255                ; too close: blocked
        rts
+       eor #$ff
        rts
