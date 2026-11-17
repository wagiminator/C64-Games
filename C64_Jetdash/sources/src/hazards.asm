; =====================================================================
;  Missiles, lasers, workers, gadget box and explosion
;  sprites: 3, 4 workers   5, 6 missiles   (3..6 laser emitters)   7 box
; =====================================================================

hazards_update
        jsr missiles_update
        jsr laser_update
        jsr workers_update
        jmp box_update

; sprite X at screen position tmp0/tmp1 (16 bit), y register A
spr_place
        sta sy,x
        lda tmp0
        clc
        adc #24
        sta sx,x
        lda tmp1
        adc #0
        beq +
        lda sxh
        ora bittab,x
        sta sxh
        jmp ++
+       lda sxh
        and bitclr,x
        sta sxh
+       lda sen
        ora bittab,x
        sta sen
        rts
spr_off lda sen
        and bitclr,x
        sta sen
        rts
bitclr  .byte $fe,$fd,$fb,$f7,$ef,$df,$bf,$7f

; X = slot: screen x -= moved, C = 1 if it left the screen (x < -24)
scroll_obj
        .block
        lda wk_xl,x
        rts
        .endblock

; ---------------------------------------------------- missiles
missiles_update
        ; new waves
        lda pmode
        cmp #PM_DEAD
        bcs _slots
        lda lwait
        ora lactive
        ora gnopat
        bne _slots
        ldx lvl
        lda d_mtime,x
        beq _slots
        lda mtimer
        bne +
        dec mtimer+1
+       dec mtimer
        lda mtimer
        ora mtimer+1
        bne _slots
        ldx lvl
        lda d_mtime,x
        asl
        sta mtimer
        lda #0
        rol
        sta mtimer+1
        jsr rnd
        and #63
        clc
        adc mtimer
        sta mtimer
        bcc +
        inc mtimer+1
+       lda ms_st
        bne +
        lda #1
        sta ms_st
        sta ms_t
+       jsr rnd
        ldx lvl
        cmp d_mdouble,x
        bcs _slots
        lda ms_st+1
        bne _slots
        lda #1
        sta ms_st+1
        lda #30
        sta ms_t+1
_slots  ldx #NMIS-1
_ms     stx tmp6
        lda ms_st,x
        bne +
        jmp _off
+       cmp #1
        bne _trk
        dec ms_t,x
        bne _show
        lda #2
        sta ms_st,x
        lda #70
        sta ms_t,x
        lda hyi
        sta ms_y,x
        lda #SFX_WARN
        jsr sfx_start
        ldx tmp6
        jmp _show
_trk    cmp #2
        bne _lock
        ; follow the hero
        lda ms_y,x
        cmp hyi
        beq +
        bcc _down
        dec ms_y,x
        jmp +
_down   inc ms_y,x
+       dec ms_t,x
        bne _show
        lda #3
        sta ms_st,x
        lda #24
        sta ms_t,x
        jmp _show
_lock   cmp #3
        bne _fly
        dec ms_t,x
        bne _show
        lda #4
        sta ms_st,x
        lda #<344
        sta ms_xl,x
        lda #>344
        sta ms_xh,x
        lda #SFX_LAUNCH
        jsr sfx_start
        ldx tmp6
        jmp _show
_fly    lda ms_xl,x
        sec
        sbc #7
        sta ms_xl,x
        lda ms_xh,x
        sbc #0
        sta ms_xh,x
        bpl +
        lda ms_xl,x
        cmp #<(-24)
        bcs +
        lda #0
        sta ms_st,x
        jmp _off
+       ; collision with the hero
        lda pmode
        cmp #PM_DEAD
        bcs _show
        lda invuln
        ora cheat
        bne _show
        lda ms_xh,x
        bne _show
        lda ms_xl,x
        sec
        sbc #HEROX-15
        cmp #30
        bcs _show
        lda ms_y,x
        sec
        sbc hyi
        clc
        adc #10
        cmp #21
        bcs _show
        lda #0
        sta ms_st,x
        jsr player_hit
        ldx tmp6
        lda #SFX_BOOM
        jsr sfx_start
        ldx tmp6
        jmp _off
_show   ; sprite 5 + slot (unless the lasers use it)
        lda lactive
        bne _next
        txa
        clc
        adc #5
        tay
        lda ms_st,x
        cmp #1
        beq _hide
        cmp #4
        beq _msp
        ; warning sign at the right edge
        lda #<300
        sta tmp0
        lda #>300
        sta tmp1
        lda ms_st,x
        cmp #3
        beq +
        lda frame
        and #16
        bne _w0
        lda #SPR_WARN0
        bne _w1
_w0     lda #SPR_WARN1
_w1     ldx #2
        bne _wc
+       lda #SPR_WARN1
        ldx #2
        pha
        lda frame
        and #4
        beq +
        ldx #7
+       pla
_wc     sta sptr,y
        txa
        sta sc,y
        ldx tmp6
        lda ms_y,x
        clc
        adc #SPRY0
        tya
        tax
        lda ms_y-5,x
        jmp _place
_msp    lda ms_xl,x
        sta tmp0
        lda ms_xh,x
        sta tmp1
        lda frame
        lsr
        and #1
        clc
        adc #SPR_MISS0
        sta sptr,y
        lda #12
        sta sc,y
        tya
        tax
        lda ms_y-5,x
_place  clc
        adc #SPRY0
        jsr spr_place
        jmp _next
_hide   lda lactive
        bne _next
        txa
        clc
        adc #5
        tax
        jsr spr_off
        jmp _next
_off    lda lactive
        bne _next
        txa
        clc
        adc #5
        tax
        jsr spr_off
_next   ldx tmp6
        dex
        bmi +
        jmp _ms
+       rts

; ---------------------------------------------------- lasers
laser_start
        lda #NLSEQ
        jsr rndmod
        tax
        lda lseq_lo,x
        sta l_ptr
        lda lseq_hi,x
        sta l_ptr+1
        ldy #0
        lda (l_ptr),y
        sta l_steps
        inc l_ptr
        bne +
        inc l_ptr+1
+       lda #1
        sta lactive
        lda #0
        sta wk_st
        sta wk_st+1
        ; the emitters take sprites 3..6
        lda sen
        and #%10000111
        sta sen
laser_step
        ldy #0
        lda (l_ptr),y
        sta l_r1
        iny
        lda (l_ptr),y
        sta l_r2
        iny
        lda (l_ptr),y
        sta l_t
        iny
        lda (l_ptr),y
        sta l_fire
        iny
        lda (l_ptr),y
        sta l_pause
        lda l_ptr
        clc
        adc #5
        sta l_ptr
        bcc +
        inc l_ptr+1
+       lda #1
        sta l_ph
        lda #SFX_CHARGE
        jmp sfx_start

laser_update
        lda lactive
        bne +
        rts
+       lda l_ph
        cmp #1
        bne _fire
        ; ---- warning
        lda frame
        and #4
        lsr
        lsr
        ldx #0
        jsr laser_char
        lda #CH_LWARN
        jsr laser_rows
        dec l_t
        bne _spr
        lda #2
        sta l_ph
        lda l_fire
        sta l_t
        lda #SFX_LASER
        jsr sfx_start
        jmp _spr
_fire   cmp #2
        bne _pause
        lda frame
        lsr
        and #1
        ora #2
        ldx #0
        jsr laser_char
        lda #CH_LBEAM
        jsr laser_rows
        jsr laser_hit
        dec l_t
        bne _spr
        ; beams off: restore the rows
        ldx l_r1
        beq +
        jsr restore_row
+       ldx l_r2
        beq +
        jsr restore_row
+       lda #3
        sta l_ph
        lda l_pause
        sta l_t
        jmp _spr
_pause  lda l_t
        beq +
        dec l_t
        bne _spr
+       dec l_steps
        beq _end
        jsr laser_step
        jmp _spr
_end    lda #0
        sta lactive
        sta l_ph
        lda #12
        sta ldone
        lda sen
        and #%10000111
        sta sen
        rts
_spr    ; emitters: 3/4 for row 1, 5/6 for row 2
        lda l_r1
        ldx #3
        jsr _emit
        lda l_r2
        ldx #5
_emit   beq _eoff
        asl
        asl
        asl
        sec
        sbc #6
        sta tmp2                ; sprite top on screen
        lda #0
        sta tmp0
        sta tmp1
        lda l_ph
        cmp #3
        beq _eoff
        lda frame
        and #2
        lsr
        clc
        adc #SPR_EMITL0
        sta sptr,x
        lda #12
        sta sc,x
        lda tmp2
        clc
        adc #SPRY0
        jsr spr_place
        inx
        lda #<296
        sta tmp0
        lda #>296
        sta tmp1
        lda frame
        and #2
        lsr
        clc
        adc #SPR_EMITR0
        sta sptr,x
        lda #12
        sta sc,x
        lda tmp2
        clc
        adc #SPRY0
        jmp spr_place
_eoff   jsr spr_off
        inx
        jmp spr_off

; A = laser char frame (0,1 warn / 2,3 beam) -> copy into the charset
laser_char
        asl
        asl
        asl
        tax
        ldy #0
-       lda laser_anim,x
        sta laser_dst,y
        inx
        iny
        cpy #8
        bne -
        rts
laser_dst = CHARGAME + CH_LWARN * 8         ; (warn and beam share the frames: see laser_rows)

; fill the laser rows with char A (warn frames go to CH_LWARN, beam frames to CH_LBEAM)
laser_rows
        sta tmp5
        cmp #CH_LBEAM
        bne +
        ; the beam frame was written to CH_LWARN: move it to CH_LBEAM
        ldy #7
-       lda CHARGAME+CH_LWARN*8,y
        sta CHARGAME+CH_LBEAM*8,y
        dey
        bpl -
+       ldx l_r1
        beq +
        lda tmp5
        jsr fill_row
+       ldx l_r2
        beq +
        lda tmp5
        jsr fill_row
+       rts

laser_hit
        lda pmode
        cmp #PM_DEAD
        bcs _r
        lda invuln
        ora cheat
        bne _r
        lda l_r1
        jsr _row
        lda l_r2
_row    beq _r
        asl
        asl
        asl
        sta tmp0                ; beam top line - 1
        ; hit if hy + 3 <= row*8 + 6  and  hy + 17 >= row*8 + 1
        lda hyi
        clc
        adc #3
        sec
        sbc #7
        cmp tmp0
        bcs _r
        lda hyi
        clc
        adc #17
        cmp tmp0
        bcc _r
        jmp player_hit
_r      rts

; ---------------------------------------------------- workers
worker_spawn
        ldx #0
        lda wk_st
        beq +
        inx
        lda wk_st+1
        bne _r
+       lda #1
        sta wk_st,x
        lda #<344
        sta wk_xl,x
        lda #>344
        sta wk_xh,x
        jsr rnd
        and #1
        sta wk_dir,x
_r      rts

workers_update
        ldx #NWRK-1
_lp     stx tmp6
        lda wk_st,x
        bne +
        jmp _off
+       ; scroll
        lda wk_xl,x
        sec
        sbc moved
        sta wk_xl,x
        lda wk_xh,x
        sbc #0
        sta wk_xh,x
        lda wk_st,x
        cmp #1
        bne _pos
        ; walk (every second frame)
        lda frame
        and #1
        beq _knock
        lda wk_dir,x
        beq _left
        inc wk_xl,x
        bne _knock
        inc wk_xh,x
        jmp _knock
_left   lda wk_xl,x
        bne +
        dec wk_xh,x
+       dec wk_xl,x
_knock  ; the jetpack exhaust knocks them over
        lda thrust
        beq _pos
        lda pmode
        bne _pos
        lda wk_xh,x
        bne _pos
        lda wk_xl,x
        sec
        sbc #HEROX-12
        cmp #22
        bcs _pos
        lda #2
        sta wk_st,x
        lda #SFX_OOPS
        jsr sfx_start
        ldx tmp6
_pos    lda wk_xh,x
        bpl +
        lda wk_xl,x
        cmp #<(-24)
        bcs +
        lda #0
        sta wk_st,x
        jmp _off
+       lda lactive
        bne _next
        lda wk_xl,x
        sta tmp0
        lda wk_xh,x
        sta tmp1
        txa
        clc
        adc #3
        tay
        ldx tmp6
        lda wk_st,x
        cmp #2
        lda #SPR_WORK2
        bcs +
        lda frame
        lsr
        lsr
        lsr
        and #1
        clc
        adc #SPR_WORK0
+       sta sptr,y
        lda #7
        sta sc,y
        tya
        tax
        lda #WORKY+SPRY0
        jsr spr_place
        jmp _next
_off    lda lactive
        bne _next
        txa
        clc
        adc #3
        tax
        jsr spr_off
_next   ldx tmp6
        dex
        bmi +
        jmp _lp
+       rts

; ---------------------------------------------------- gadget box (sprite 7)
box_spawn
        lda bx_st
        bne _r
        lda pmode
        bne _r
        lda #1
        sta bx_st
        lda #<344
        sta bx_xl
        lda #>344
        sta bx_xh
        lda #90
        jsr rndmod
        clc
        adc #50
        sta bx_y
        lda #0
        sta bx_t
_r      rts

; explosion where the hero is (unless the box is on screen)
expl_start
        lda bx_st
        cmp #1
        beq _r
        lda #2
        sta bx_st
        lda #<HEROX
        sta bx_xl
        lda #0
        sta bx_xh
        sta bx_t
        lda hyi
        sta bx_y
_r      rts

box_update
        ldx #7
        lda bx_st
        bne +
        jmp spr_off
+       lda bx_xl
        sec
        sbc moved
        sta bx_xl
        lda bx_xh
        sbc #0
        sta bx_xh
        bpl +
        lda bx_xl
        cmp #<(-24)
        bcs +
        lda #0
        sta bx_st
        jmp spr_off
+       inc bx_t
        lda bx_xl
        sta tmp0
        lda bx_xh
        sta tmp1
        lda bx_st
        cmp #2
        beq _expl
        ; bobbing box
        lda bx_t
        lsr
        lsr
        and #15
        tax
        lda bob_tab,x
        clc
        adc bx_y
        sta tmp2
        lda bx_t
        lsr
        lsr
        lsr
        and #1
        clc
        adc #SPR_BOX0
        sta sptr+7
        lda #5
        sta sc+7
        ; collected?
        lda pmode
        bne _show
        lda bx_xh
        bne _show
        lda bx_xl
        sec
        sbc #HEROX-16
        cmp #32
        bcs _show
        lda tmp2
        sec
        sbc hyi
        clc
        adc #16
        cmp #33
        bcs _show
        lda #0
        sta bx_st
        ldx #7
        jsr spr_off
        jmp vehicle_start
_show   ldx #7
        lda tmp2
        clc
        adc #SPRY0
        jmp spr_place
_expl   lda bx_t
        cmp #18
        bcc +
        lda #0
        sta bx_st
        ldx #7
        jmp spr_off
+       ldx #0
        cmp #6
        bcc +
        inx
        cmp #12
        bcc +
        inx
+       txa
        clc
        adc #SPR_EXPL0
        sta sptr+7
        lda #7
        sta sc+7
        lda bx_y
        sta tmp2
        jmp _show
bob_tab .byte 0,1,2,3,4,4,5,5,5,5,4,4,3,2,1,0
