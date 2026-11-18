; =====================================================================
;  Objects: ring buffer, pattern generator, movement, projection,
;  collisions with the runner
; =====================================================================

clear_objects
        lda #0
        sta ohead
        sta otail
        ldx #NO-1
-       sta o_t,x
        dex
        bpl -
        rts

; spawn: A = type, X = lane, Y = height level, depth = ZSPAWN - slotacc
spawn
        sta tmp0
        stx tmp1
        sty tmp2
        lda otail
        clc
        adc #1
        and #NO-1
        cmp ohead
        bne +
        rts                     ; full
+       ldx otail
        sta otail
        lda tmp0
        sta o_t,x
        lda tmp1
        sta o_ln,x
        lda tmp2
        sta o_h,x
        lda #<ZSPAWN
        sec
        sbc slotacc
        sta o_zl,x
        lda #>ZSPAWN
        sbc #0
        sta o_zh,x
        rts

; ---------------------------------------------------- pattern generator
gen_update
        lda slotacc
        clc
        adc step
        sta slotacc
gen_rows
        lda slotacc
        cmp #SLOT
        bcs +
        rts
+       sbc #SLOT
        sta slotacc
        ; one row
        lda pat_gap
        beq _pat
        dec pat_gap
        jmp gen_rows
_pat    lda pat_n
        bne _row
        ; new pattern
        ldx zone
        lda zone_gap,x
        sta pat_gap
        lda zset_lo,x
        sta ptr0
        lda zset_hi,x
        sta ptr0+1
        lda zset_n,x
        jsr rndmod
        tay
        lda (ptr0),y
        tax
        lda pat_lo,x
        sta pat_ptr
        lda pat_hi,x
        sta pat_ptr+1
        ldy #0
        lda (pat_ptr),y
        sta pat_n
        inc pat_ptr
        bne +
        inc pat_ptr+1
+       jsr rnd
        and #1
        sta pat_mir
_row    ; three cells
        lda #0
        sta glane
-       ldy glane
        lda pat_mir
        beq +
        lda #2
        sec
        sbc glane
        tay
+       lda (pat_ptr),y
        beq _next
        jsr cell
_next   inc glane
        lda glane
        cmp #3
        bne -
        lda pat_ptr
        clc
        adc #3
        sta pat_ptr
        bcc +
        inc pat_ptr+1
+       dec pat_n
        jmp gen_rows

; A = cell code, lane glane
cell
        cmp #4
        bcs +
        ldx glane
        ldy #0
        jmp spawn               ; hurdle, bar, block
+       cmp #9
        bcs _pwr
        sbc #3                  ; C clear: A - 4 = height level
        tay
        ldx glane
        lda #OB_COIN
        jmp spawn
_pwr    lda #4
        jsr rndmod
        clc
        adc #OB_PWR
        ldx glane
        ldy #1
        jmp spawn

; ---------------------------------------------------- move all objects, find crossings
move_objects
        ldx ohead
_loop   cpx otail
        beq _done
        lda o_t,x
        beq _next
        lda o_zl,x
        sta tmp0
        lda o_zh,x
        sta tmp1
        lda o_zl,x
        sec
        sbc step
        sta o_zl,x
        lda o_zh,x
        sbc #0
        sta o_zh,x
        bmi _gone
        bne _keep
        lda o_zl,x
        cmp #ZOUT
        bcc _gone
        ; crossing the runner's depth?
        cmp #ZRUN
        bcs _keep
        lda tmp1
        bne _cross
        lda tmp0
        cmp #ZRUN
        bcc _keep
_cross  stx tmp5
        jsr cross
        ldx tmp5
        jmp _next
_gone   lda #0
        sta o_t,x
        jmp _next
_keep   ; magnet pulls coins into the runner's lane
        lda pw_t
        beq _next
        lda o_t,x
        cmp #OB_COIN
        bne _next
        lda o_zh,x
        bne _next
        lda plane
        sta o_ln,x
_next   inx
        txa
        and #NO-1
        tax
        jmp _loop
_done   ; drop finished objects at the head
-       ldx ohead
        cpx otail
        beq +
        lda o_t,x
        bne +
        inx
        txa
        and #NO-1
        sta ohead
        jmp -
+       rts

; lane of the runner on the screen (nearest lane to px)
runner_lane
        lda px
        cmp #136
        bcc _l0
        cmp #184
        bcc _l1
        lda #2
        rts
_l0     lda #0
        rts
_l1     lda #1
        rts

; object X crosses the runner's depth
cross
        lda o_t,x
        cmp #OB_COIN
        bcc _obst
        beq _coin
        ; power-up: taken when the runner is in the lane and not high in the air
        jsr runner_lane
        cmp o_ln,x
        bne _r
        lda pjh+1
        cmp #30
        bcs _r
        lda o_t,x
        sec
        sbc #OB_PWR
        tay
        lda #0
        sta o_t,x
        jmp take_power
_coin   lda pw_t                ; magnet: every coin
        bne _take
        jsr runner_lane
        cmp o_ln,x
        bne _r
        ; coin height (pixels) = level * 12 must be inside the body
        lda o_h,x
        asl
        asl
        sta tmp0
        asl
        adc tmp0                ; *12
        clc
        adc #8
        cmp pjh+1               ; below the feet?
        bcc _r
        sbc #8
        sta tmp0
        lda pjh+1
        clc
        adc #38
        ldy pslide
        beq +
        sbc #22
+       cmp tmp0
        bcc _r
_take   lda #0
        sta o_t,x
        jmp take_coin
_r      rts
_obst   sta tmp0
        jsr runner_lane
        cmp o_ln,x
        bne _r
        lda tmp0
        cmp #OB_BAR
        beq _bar
        bcs _blk
        ; hurdle: jump over it
        lda pslide
        bne _hit
        lda pjh+1
        cmp #18
        bcs _passed
        jmp _hit
_bar    lda pslide
        bne _passed
        jmp _hit
_blk    lda pjh+1
        cmp #36
        bcs _passed
_hit    lda pw_t+3              ; amulet saves once
        beq _crash
        lda #0
        sta pw_t+3
        sta o_t,x
        lda #25
        sta pflash
        lda #SFX_SHIELD
        jmp sfx_start
_crash  lda #1
        sta pdead
        rts
_passed lda #SFX_WHOOSH
        jmp sfx_start

; ---------------------------------------------------- side bump: an obstacle beside the runner in lane A?
; C = 1 blocked
lane_blocked
        sta tmp0
        ldx ohead
-       cpx otail
        beq _free
        lda o_t,x
        beq _n
        cmp #OB_COIN
        bcs _n
        lda o_ln,x
        cmp tmp0
        bne _n
        lda o_zh,x
        bne _n
        lda o_zl,x
        cmp #ZRUN-18
        bcc _n
        cmp #ZRUN+20
        bcs _n
        ; a hurdle can be passed in the air, a bar while sliding
        lda o_t,x
        cmp #OB_BARR
        bne +
        lda pjh+1
        cmp #18
        bcs _n
        sec
        rts
+       cmp #OB_BAR
        bne _blk
        lda pslide
        bne _n
_blk    sec
        rts
_n      inx
        txa
        and #NO-1
        tax
        jmp -
_free   clc
        rts

; ---------------------------------------------------- projection: soft list and sprite candidates
project
        lda #0
        sta sd_n
        sta cv_n
        ldx ohead
_loop   cpx otail
        bne +
        jmp _done
+       lda o_t,x
        bne +
        jmp _next
+       ; base line
        lda o_zh,x
        bne _far
        ldy o_zl,x
        lda ytab_n,y
        jmp _yb
_far    sta tmp0
        lda o_zl,x
        lsr tmp0
        ror
        lsr tmp0
        ror
        sec
        sbc #64
        tay
        lda ytab_f,y
_yb     sta tmp1                ; base line
        tay
        cmp #NEAR_Y
        bcc _soft
        jmp _near
_soft   ; ---- far: soft list
        ldy sd_n
        lda o_t,x
        sec
        sbc #1
        cmp #4
        bcc +
        lda #4                  ; all power-ups share one shape
+       sta tmp2
        cmp #3
        bne +
        lda #3
+       asl
        asl
        asl
        asl
        sta tmp3
        ldy tmp1
        lda fcls,y
        ora tmp3
        ldy sd_n
        sta sd_k,y
        ; lane centre
        ldy tmp1
        lda fofs,y
        sta tmp3
        lda #80
        ldy o_ln,x
        beq _fl0
        dey
        beq _fl1
        clc
        adc tmp3
        jmp _fl1
_fl0    sec
        sbc tmp3
_fl1    ldy sd_n
        sta sd_x,y
        ; coins in the air
        lda tmp1
        sta sd_y,y
        lda o_t,x
        cmp #OB_COIN
        bne +
        jsr lift
        ldy sd_n
        sta sd_y,y
+       inc sd_n
        jmp _next
_near   ; ---- near: sprite candidate
        ldy cv_n
        cpy #NV
        bcc +
        jmp _next
+       ldy tmp1
        lda nofs,y
        sta tmp3
        lda ncls,y
        sta tmp4
        lda #160
        ldy o_ln,x
        beq _nl0
        dey
        beq _nl1
        clc
        adc tmp3
        jmp _nl1
_nl0    sec
        sbc tmp3
_nl1    sta tmp2                ; centre x
        ldy cv_n
        lda o_t,x
        cmp #OB_BARR
        bne _nb
        ; hurdle: x-expanded
        lda tmp2
        sta cv_x,y
        lda tmp1
        clc
        adc #30
        sta cv_y,y
        lda #SPR_BARR0
        clc
        adc tmp4
        sta cv_p,y
        lda #2
        sta cv_c,y
        lda #1
        sta cv_e,y
        lda #21
        sta cv_h,y
        jmp _cvok
_nb     cmp #OB_COIN
        bcs _ncoin
        ; bar / block: x and y expanded
        lda tmp2
        sta cv_x,y
        lda tmp1
        clc
        adc #9
        sta cv_y,y
        lda o_t,x
        cmp #OB_BAR
        bne +
        lda #SPR_BAR0
        clc
        adc tmp4
        sta cv_p,y
        stx tmp5
        ldx zone
        lda bar_col,x
        ldx tmp5
        sta cv_c,y
        jmp ++
+       lda #SPR_BLK0
        clc
        adc tmp4
        sta cv_p,y
        stx tmp5
        ldx zone
        lda blk_col,x
        ldx tmp5
        sta cv_c,y
+       lda #3
        sta cv_e,y
        lda #42
        sta cv_h,y
        jmp _cvok
_ncoin  ; coin or power-up: not expanded
        lda tmp2
        clc
        adc #12
        sta cv_x,y
        jsr lift                ; A = base line - height
        clc
        adc #30
        ldy cv_n
        sta cv_y,y
        lda #0
        sta cv_e,y
        lda #21
        sta cv_h,y
        lda o_t,x
        cmp #OB_COIN
        bne _npw
        lda frame
        lsr
        lsr
        lsr
        and #1
        beq +
        lda #NCLS
+       clc
        adc tmp4
        adc #SPR_COIN0_0
        sta cv_p,y
        lda #7
        sta cv_c,y
        jmp _cvok
_npw    sec
        sbc #OB_PWR
        tay
        lda pwr_base,y
        clc
        adc tmp4
        ldy cv_n
        sta cv_p,y
        lda o_t,x
        sec
        sbc #OB_PWR
        tay
        lda pwr_col,y
        ldy cv_n
        sta cv_c,y
_cvok   lda #0
        sta cv_xh,y
        lda cv_y,y
        cmp #250
        bcs _next               ; below the screen
        inc cv_n
_next   inx
        txa
        and #NO-1
        tax
        jmp _loop
_done   rts

; coin X with base line tmp1: A = tmp1 - height level * hstep
lift
        ldy tmp1
        lda hstep,y
        sta tmp7
        lda tmp1
        ldy o_h,x
        beq +
-       sec
        sbc tmp7
        dey
        bne -
+       rts

blk_col .byte 12, 9, 9, 14, 12
bar_col .byte 9, 9, 8, 12, 8
pwr_col .byte 2, 13, 3, 4
pwr_base .byte SPR_PWR0_0, SPR_PWR1_0, SPR_PWR2_0, SPR_PWR3_0
