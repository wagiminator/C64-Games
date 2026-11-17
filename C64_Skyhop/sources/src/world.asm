; =====================================================================
;  World: objects (platforms, springs, items, moon), generator, drawing
;  Objects live at world rows (8 px, y up). The playfield shows the rows
;  trow (screen row 0) down to trow-24; the hardware fine scroll does the rest.
; =====================================================================

world_reset
        ldx #NOBJ-1
-       lda #0
        sta o_t,x
        lda #$ff
        sta d_s0,x
        sta d_s1,x
        dex
        bpl -
        lda #0
        sta m_t
        sta b_on
        sta g_moon
        rts

; -> X = free slot, carry clear; carry set if none
obj_alloc
        ldx #NOBJ-1
-       lda o_t,x
        beq +
        dex
        bpl -
        sec
        rts
+       lda #0
        sta o_st,x
        sta o_tm,x
        sta o_dx,x
        clc
        rts

; colour RAM value (multicolour + fill colour) per type
obj_colour .byte 0, 8+5, 8+3, 8+2, 8+1, 8+1, 8+7, 8+3, 8+1, 8+2, 8+1, 0

; ---------------------------------------------------- desired shape of object X -> ds, dr, dc, dcol
obj_desire
        lda #$ff
        sta ds
        lda o_t,x
        beq _none
        cmp #T_DEAD
        beq _none
        tay
        lda obj_colour,y
        sta dcol
        lda o_x,x
        sta dc
        lda o_t,x
        cmp #T_MOVE
        bne +
        lda o_x,x
        and #3
        clc
        adc #S_MOVE0
        sta ds
        lda o_x,x
        lsr
        lsr
        sta dc
        jmp _rows
+       tay
        lda obj_shape,y
        sta ds
        cpy #T_SPRING
        bne _rows
        lda o_st,x
        beq _rows
        lda #S_SPRING2
        sta ds
_rows   ; bottom row on screen = trow - row
        lda trl
        sec
        sbc o_rl,x
        sta tmp0
        lda trh
        sbc o_rh,x
        bne _off
        ldy ds
        lda shp_h,y
        sta tmp1                ; h
        clc
        adc #24
        cmp tmp0                ; bottom > 24 + h - 1 ?
        bcc _off
        beq _off
        lda tmp0
        sec
        sbc tmp1
        clc
        adc #1
        sta dr                  ; top row (may be negative)
        rts
_off    lda #$ff
        sta ds
_none   rts
obj_shape .byte 0, S_PLAT, S_MOVE0, S_BREAK, S_PLAT, S_SPRING, S_HAT, S_JET, S_MOON, S_BROKEN, S_POOF, 0

; ---------------------------------------------------- draw / erase a shape into the hidden screen
; A = shape, tmp2 = top row (signed), tmp3 = column, tmp4 = colour (draw only)
shape_setup
        tay
        lda shp_w,y
        sta tmp5
        lda shp_h,y
        sta tmp6
        lda shp_lo,y
        sta ptr2
        lda shp_hi,y
        sta ptr2+1
        rts

; set ptr0 / ptr1 for row A (0..24) and column tmp3 of the hidden screen
row_ptrs
        tay
        lda rowlo,y
        clc
        adc tmp3
        sta ptr0
        sta ptr1
        lda hid
        bne +
        lda rowhiA,y
        bne ++
+       lda rowhiB,y
+       adc #0
        sta ptr0+1
        lda rowlo,y
        clc
        adc tmp3
        lda rowhiC,y
        adc #0
        sta ptr1+1
        rts

erase_shape
        jsr shape_setup
        lda #0
        sta tmp7                ; shape row
_row    lda tmp2
        clc
        adc tmp7
        cmp #25
        bcs _next               ; off screen (also negative)
        jsr row_ptrs
        ldy #0
-       tya
        clc
        adc tmp3
        and #1
        ora #CH_BG
        sta (ptr0),y
        iny
        cpy tmp5
        bne -
_next   inc tmp7
        lda tmp7
        cmp tmp6
        bne _row
        rts

draw_shape
        jsr shape_setup
        lda #0
        sta tmp7
_row    lda tmp2
        clc
        adc tmp7
        cmp #25
        bcs _skip
        jsr row_ptrs
        ldy #0
-       lda (ptr2),y
        cmp #BGM
        bne +
        tya
        clc
        adc tmp3
        and #1
        ora #CH_BG
        sta (ptr0),y
        jmp ++
+       sta (ptr0),y
        lda tmp4
        sta (ptr1),y
+       iny
        cpy tmp5
        bne -
_skip   lda ptr2                ; next shape row
        clc
        adc tmp5
        sta ptr2
        bcc +
        inc ptr2+1
+       inc tmp7
        lda tmp7
        cmp tmp6
        bne _row
        rts

; ---------------------------------------------------- bring the hidden screen up to date
chg     = txtbuf                ; NOBJ change flags
draw_world
        ; pass 1: erase what changed
        ldx #NOBJ-1
_p1     lda #0
        sta chg,x
        jsr obj_desire
        lda hid
        bne _b
        lda ds
        cmp d_s0,x
        bne _c0
        cmp #$ff
        beq _n1
        lda dr
        cmp d_r0,x
        bne _c0
        lda dc
        cmp d_c0,x
        beq _n1
_c0     lda d_s0,x
        cmp #$ff
        beq +
        stx tmp1
        sta tmp0
        lda d_r0,x
        sta tmp2
        lda d_c0,x
        sta tmp3
        lda tmp0
        jsr erase_shape
        ldx tmp1
+       lda ds
        sta d_s0,x
        lda dr
        sta d_r0,x
        lda dc
        sta d_c0,x
        jmp _ch
_b      lda ds
        cmp d_s1,x
        bne _c1
        cmp #$ff
        beq _n1
        lda dr
        cmp d_r1,x
        bne _c1
        lda dc
        cmp d_c1,x
        beq _n1
_c1     lda d_s1,x
        cmp #$ff
        beq +
        stx tmp1
        sta tmp0
        lda d_r1,x
        sta tmp2
        lda d_c1,x
        sta tmp3
        lda tmp0
        jsr erase_shape
        ldx tmp1
+       lda ds
        sta d_s1,x
        lda dr
        sta d_r1,x
        lda dc
        sta d_c1,x
_ch     lda ds
        cmp #$ff
        beq _n1
        lda #1
        sta chg,x
_n1     ; removed objects: free the slot once both screens are clean
        lda o_t,x
        cmp #T_DEAD
        bne +
        lda d_s0,x
        and d_s1,x
        cmp #$ff
        bne +
        lda #0
        sta o_t,x
+       dex
        bmi +
        jmp _p1
+
        ; pass 2: draw the changed objects
        ldx #NOBJ-1
_p2     lda chg,x
        beq _n2
        stx tmp1
        ldy o_t,x
        lda obj_colour,y
        sta tmp4
        lda hid
        bne +
        lda d_r0,x
        sta tmp2
        lda d_c0,x
        sta tmp3
        lda d_s0,x
        jmp ++
+       lda d_r1,x
        sta tmp2
        lda d_c1,x
        sta tmp3
        lda d_s1,x
+       jsr draw_shape
        ldx tmp1
_n2     dex
        bpl _p2
        rts

; fill the hidden screen with paper and forget what was drawn on it
clear_hidden
        lda hid
        bne +
        lda #>SCRA
        bne ++
+       lda #>SCRB
+       sta ptr0+1
        lda #0
        sta ptr0
        ldx #4
        ldy #0
-       tya
        and #1
        ora #CH_BG
        sta (ptr0),y
        iny
        bne -
        inc ptr0+1
        dex
        bne -
        ; colour RAM: multicolour everywhere
        ldx #0
        lda #8+1
-       sta COLRAM,x
        sta COLRAM+256,x
        sta COLRAM+512,x
        sta COLRAM+768,x
        inx
        bne -
        ldx #NOBJ-1
        lda #$ff
-       ldy hid
        bne +
        sta d_s0,x
        jmp ++
+       sta d_s1,x
+       dex
        bpl -
        rts

; ---------------------------------------------------- remove objects far below the screen
cull_world
        ldx #NOBJ-1
_c      lda o_t,x
        beq _n
        ; row < trow - 36 ? (shapes are up to 9 rows tall)
        lda o_rl,x
        clc
        adc #36
        sta tmp0
        lda o_rh,x
        adc #0
        sta tmp1
        lda tmp0
        cmp trl
        lda tmp1
        sbc trh
        bcs _n
        lda #0
        sta o_t,x
        lda #$ff
        sta d_s0,x
        sta d_s1,x
_n      dex
        bpl _c
        rts

; ---------------------------------------------------- generator
; random number 0..A-1
rndmod
        sta tmp7
        jsr rnd
-       cmp tmp7
        bcc +
        sbc tmp7
        jmp -
+       rts

gen_ahead
        lda #8
        sta g_cnt
_g      ; generate while g_row < trow + 3
        lda trl
        clc
        adc #3
        sta tmp0
        lda trh
        adc #0
        sta tmp1
        lda g_rl
        cmp tmp0
        lda g_rh
        sbc tmp1
        bcs +
        jsr gen_step
        dec g_cnt
        bne _g
+       rts

; place an object: A = type, tmp0/tmp1 = row, tmp2 = x  -> X = slot (carry set if none)
place
        sta tmp3
        jsr obj_alloc
        bcs +
        lda tmp3
        sta o_t,x
        lda tmp0
        sta o_rl,x
        lda tmp1
        sta o_rh,x
        lda tmp2
        sta o_x,x
        clc
+       rts

gen_step
        ldy lvl
        ; gap = gapmin + rnd(gapmax - gapmin + 1)
        lda d_gapmax,y
        sec
        sbc d_gapmin,y
        clc
        adc #1
        jsr rndmod
        ldy lvl
        clc
        adc d_gapmin,y
        sta gap
        ; new row
        lda g_rl
        clc
        adc gap
        sta nrl
        lda g_rh
        adc #0
        sta nrh
        ; the moon?
        lda g_moon
        bne _skipall
        lda nrl
        cmp #<MOONROW
        lda nrh
        sbc #>MOONROW
        bcc _normal
        jmp gen_moon
_skipall
        ; nothing more above the moon
        lda #$ff
        sta g_rh
        rts
_normal
        ; ---- decoys and extras between the last and the new platform
        lda #0
        sta midused
        lda gap
        cmp #3
        bcc _nomid
        ; monster?
        ldy lvl
        lda d_mgap,y
        beq _nomon
        sta tmp0
        lda m_t
        bne _nomon
        lda nrl
        sec
        sbc g_ml
        sta tmp1
        lda nrh
        sbc g_mh
        bne +
        lda tmp1
        cmp tmp0
        bcc _nomon
+       jsr gen_monster
        lda #1
        sta midused
        jmp _nomid
_nomon  ; extra normal platform half way
        jsr rnd
        ldy lvl
        cmp d_pextra,y
        bcs +
        lda gap
        lsr
        jsr mid_row
        lda #37
        jsr rndmod
        sta tmp2
        lda #T_PLAT
        jsr place
        lda #1
        sta midused
+       ; breaking decoy one row below the new platform
        jsr rnd
        ldy lvl
        cmp d_pbreak,y
        bcs _nomid
        lda gap
        sec
        sbc #1
        jsr mid_row
        lda #37
        jsr rndmod
        sta tmp2
        lda #T_BREAK
        jsr place
_nomid
        ; ---- the main platform
        lda nrl
        sta tmp0
        sta g_rl
        lda nrh
        sta tmp1
        sta g_rh
        jsr rnd
        ldy lvl
        cmp d_pmove,y
        bcs _static
        ; moving platform
        lda #141
        jsr rndmod
        sta tmp2
        lda #T_MOVE
        jsr place
        bcs +
        jsr rnd
        and #1
        sta o_dx,x
        ldy lvl
        lda d_mspeed,y
        sta o_st,x
+       rts
_static sec
        sbc d_pmove,y
        cmp d_pvan,y
        bcs _plain
        lda #37
        jsr rndmod
        sta tmp2
        lda #T_VAN
        jmp place
_plain  lda #37
        jsr rndmod
        sta tmp2
        lda #T_PLAT
        jsr place
        bcs _r
        ; something on top?
        lda tmp2
        sta tmp4                ; platform column
        lda tmp0
        clc
        adc #1
        sta tmp0
        bcc +
        inc tmp1
+       jsr rnd
        ldy lvl
        cmp d_pspring,y
        bcs _nosp
        lda #4
        jsr rndmod
        clc
        adc tmp4
        sta tmp2
        lda #T_SPRING
        jmp place
_nosp   sec
        sbc d_pspring,y
        cmp d_phat,y
        bcs _nohat
        lda #3
        jsr rndmod
        clc
        adc tmp4
        sta tmp2
        lda #T_HAT
        jmp place
_nohat  sec
        sbc d_phat,y
        cmp d_pjet,y
        bcs _r
        lda #3
        jsr rndmod
        clc
        adc tmp4
        sta tmp2
        lda #T_JET
        jmp place
_r      rts


; tmp0/tmp1 = g_row + A
mid_row
        clc
        adc g_rl
        sta tmp0
        lda g_rh
        adc #0
        sta tmp1
        rts

gen_monster
        lda gap
        lsr
        jsr mid_row
        lda tmp0
        sta g_ml
        lda tmp1
        sta g_mh
        ; y = row * 8 - 4 (bottom of the sprite)
        lda tmp0
        sta m_yl
        lda tmp1
        asl m_yl
        rol
        asl m_yl
        rol
        asl m_yl
        rol
        sta m_yh
        lda m_yl
        sec
        sbc #4
        sta m_yl
        bcs +
        dec m_yh
+       lda #148
        jsr rndmod
        sta m_x
        ldy lvl
        lda d_mtypes,y
        jsr rndmod
        clc
        adc #1
        sta m_t
        sta m_kind
        lda #1
        sta m_dx
        lda #0
        sta m_an
        rts

; the final platform and, a normal jump higher and a little to the right, the moon
gen_moon
        lda nrl
        sta tmp0
        lda nrh
        sta tmp1
        lda #MOONCOL-8
        sta tmp2
        lda #T_PLAT
        jsr place
        ; moon bottom 2 rows higher: its surface is 79 px above the platform
        lda tmp0
        clc
        adc #2
        sta tmp0
        bcc +
        inc tmp1
+       lda #MOONCOL
        sta tmp2
        lda #T_MOON
        jsr place
        lda #1
        sta g_moon
        lda #$ff
        sta g_rh
        rts
