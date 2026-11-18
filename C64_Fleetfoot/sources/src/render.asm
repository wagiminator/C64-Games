; =====================================================================
;  Rendering: stripe code generator, stripes, far objects, sprite lists
; =====================================================================

; ---------------------------------------------------- generate the stripe code at SPEED
; For every ground line and every character of that row that changes with the
; stripes:  lda STSRC+2k,y / sta char byte   (Y = 0 plain, 1 stripe, from STTAB).
; Far rows also restore all their characters (objects are drawn into them):
; constant bytes are written with  lda #v / sta.
emit    sty gen_sy
        ldy #0
        sta (gptr),y
        inc gptr
        bne +
        inc gptr+1
+       ldy gen_sy
        rts

; ptr1 = CS2 + c*8 + l, ptr2 = stripe_data + c*8 + l  (c in X)
gen_addr
        txa
        asl
        asl
        asl
        ora gen_l
        sta ptr1
        sta ptr2
        txa
        lsr
        lsr
        lsr
        lsr
        lsr
        sta tmp0
        clc
        adc #>CS2
        sta ptr1+1
        lda ptr2
        clc
        adc #<stripe_data
        sta ptr2
        lda tmp0
        adc #>stripe_data
        sta ptr2+1
        rts

; A = plain byte, tmp1 = stripe byte for char X on line gen_l (row gen_r)
gen_bytes
        jsr gen_addr
        ldy #0
        lda (ptr2),y
        sta tmp1
        lda (ptr1),y
        ldy gen_y
        cpy #STRIPE_TOP
        bcs +
        sta tmp1
+       rts

gen_stripe_code
        lda #<SPEED
        sta gptr
        lda #>SPEED
        sta gptr+1
        lda #<STSRC
        sta gen_k
        lda #>STSRC
        sta gen_k+1
        lda #0
        sta gen_r
_row    lda #0
        sta gen_l
_line   lda gen_r
        asl
        asl
        asl
        ora gen_l
        clc
        adc #HY
        sta gen_y
        lda #0
        sta gen_ldy
        sta gen_n
        ; ---- candidates of this line: soft chars, then the row's own non-soft chars
        ldy gen_r
        ldx sc_s0,y
-       ldy gen_r
        txa
        cmp sc_s1,y
        bcs +
        lda #1
        jsr gen_cand
        inx
        jmp -
+       ldy gen_r
        ldx sc_n0,y
-       ldy gen_r
        txa
        cmp sc_n1,y
        bcs _group
        lda sc_owner,x
        sec
        sbc #9
        cmp gen_r
        bne +
        lda #0
        jsr gen_cand
+       inx
        jmp -
        ; ---- emit groups of equal byte pairs
_group  ldx #0
_gi     cpx gen_n
        bcs _lnext
        lda cd_done,x
        bne _gnext
        stx gen_i
        lda cd_p,x
        cmp cd_s,x
        bne _pair
        ; constant: lda #p
        lda #$a9
        jsr emit
        lda cd_p,x
        jsr emit
        jmp _stores
_pair   lda gen_ldy
        bne +
        inc gen_ldy
        lda #$a0                ; ldy #depth of the line (6 bits)
        jsr emit
        ldy gen_y
        lda zline-HY,y
        and #STRIPE_P-1
        jsr emit
        lda #$be                ; ldx STLCAM,y
        jsr emit
        lda #<STLCAM
        jsr emit
        lda #>STLCAM
        jsr emit
+       ldx gen_i
        ldy #0
        lda cd_p,x
        sta (gen_k),y
        iny
        lda cd_s,x
        sta (gen_k),y
        lda #$bd                ; lda STSRC+2k,x
        jsr emit
        lda gen_k
        jsr emit
        lda gen_k+1
        jsr emit
        lda gen_k
        clc
        adc #2
        sta gen_k
        bcc _stores
        inc gen_k+1
_stores ; sta for this char and all later ones with the same pair
        ldx gen_i
        jsr gen_sta
        inx
-       cpx gen_n
        bcs +
        lda cd_done,x
        bne _sn
        ldy gen_i
        lda cd_p,x
        cmp cd_p,y
        bne _sn
        lda cd_s,x
        cmp cd_s,y
        bne _sn
        jsr gen_sta
_sn     inx
        jmp -
+       ldx gen_i
_gnext  inx
        jmp _gi
_lnext  inc gen_l
        lda gen_l
        cmp #8
        beq +
        jmp _line
+       inc gen_r
        lda gen_r
        cmp #16
        beq _end
        cmp #NEAR_Y/8-9
        beq +
        jmp _row
+       ; rows below NEAR_Y: second routine
        lda #$60                ; rts
        jsr emit
        lda gptr
        sta speed2+1
        lda gptr+1
        sta speed2+2
        jmp _row
_end    lda #$60                ; rts
        jmp emit

speed2  jmp $ffff               ; stripes of the near rows (patched)

; add char X as candidate (A = 1 soft): skipped when constant and not soft
gen_cand
        sta tmp4
        stx tmp3
        jsr gen_bytes           ; A = plain, tmp1 = stripe, ptr1 = address
        ldx tmp3
        cmp tmp1
        bne +
        ldy tmp4
        beq _skip               ; static char: nothing to do
+       ldy gen_n
        sta cd_p,y
        lda tmp1
        sta cd_s,y
        lda ptr1
        sta cd_lo,y
        lda ptr1+1
        sta cd_hi,y
        lda #0
        sta cd_done,y
        inc gen_n
_skip   rts

; emit sta for candidate X and mark it done
gen_sta
        lda #1
        sta cd_done,x
        lda #$8d
        jsr emit
        lda cd_lo,x
        jsr emit
        lda cd_hi,x
        jmp emit

; ---------------------------------------------------- stripe phase table for the current camera position
; STLCAM[d] = 1 when ((d + camz) & 63) < STRIPE_D  (d = depth of a line, 6 bits)
calc_stripes
        lda #0
        ldx #STRIPE_P-1
-       sta STLCAM,x
        dex
        bpl -
        lda #0
        sec
        sbc camz
        and #STRIPE_P-1
        tax                     ; first d with a stripe
        ldy #STRIPE_D
        lda #1
-       sta STLCAM,x
        inx
        txa
        and #STRIPE_P-1
        tax
        lda #1
        dey
        bne -
        rts

; ---------------------------------------------------- far objects drawn into the soft characters
; soft list: sd_k (kind*16+class), sd_x (centre, MC pixels), sd_y (base line, lifted for coins)
draw_soft
        ldx sd_n
        bne +
        rts
+       dex
        stx tmp7                ; draw from the last (farthest) to the first
_obj    ldx tmp7
        ; the beam has left the screen: update the near rows first
        lda sd_y,x
        cmp #DOT_Y
        bcs _rects
        ; ---- far away: one bright pixel
        sec
        sbc #HY+1
        bcc _dnext
        tay
        lda sd_x,x
        cmp lx0,y
        bcc _dnext
        cmp lx1,y
        beq +
        bcs _dnext
+       sta tmp5
        lda #$ff                ; coins and power-ups bright, obstacles in the ground colour
        ldy sd_k,x
        cpy #3*16
        bcs +
        lda #$55
+       sta rpat
        lda sd_y,x
        sec
        sbc #HY+1
        tay
        lda tmp5
        lsr
        lsr
        tax
        lda la_lo,y
        clc
        adc col8_lo,x
        sta ptr3
        lda la_hi,y
        adc col8_hi,x
        sta ptr3+1
        ldx tmp5
        lda lmask_x,x
        and rmask_x,x
        sta fmask
        ldy #0
        lda (ptr3),y
        eor rpat
        and fmask
        eor (ptr3),y
        sta (ptr3),y
_dnext  dec tmp7
        bpl +
        rts
+       jmp _obj
_rects  ldy sd_k,x
        lda far_lo,y
        sta cptr
        lda far_hi,y
        sta cptr+1
        lda sd_x,x
        sta tmp5                ; centre x
        lda sd_y,x
        sta tmp6                ; base line
        ldy #0
        lda (cptr),y
        sta tmp4                ; number of rectangles
        iny
_rect   ; x0, x1, h0, h1, pattern
        lda (cptr),y
        clc
        adc tmp5
        sta rx0
        iny
        lda (cptr),y
        clc
        adc tmp5
        sta rx1
        iny
        lda tmp6
        sec
        sbc (cptr),y            ; - h0 -> bottom line
        sta ry1
        iny
        lda tmp6
        sec
        sbc (cptr),y            ; - h1 -> top line
        sta ry0
        iny
        lda (cptr),y
        sta rpat
        iny
        sty rptr
        jsr fill_rect
        ldy rptr
        dec tmp4
        bne _rect
        dec tmp7
        bpl _obj
        rts

; fill rx0..rx1 (MC pixels) x ry0..ry1 (lines) with rpat, clipped to the soft area.
; Works per character row: for every byte column a pointer to the first line,
; the lines of that row via the Y register.
fill_rect
        lda ry0
        cmp #HY
        bcs +
        lda #HY
        sta ry0
+       lda ry1
        cmp #NEAR_Y
        bcc +
        lda #NEAR_Y-1
        sta ry1
+       lda ry0
        cmp ry1
        beq +
        bcc +
        rts
+       ; ---- fast path: one byte column, inside the soft area of the top line
        lda rx0
        lsr
        lsr
        sta fcol
        lda rx1
        lsr
        lsr
        cmp fcol
        bne _seg
        lda ry0
        sec
        sbc #HY
        tax
        lda rx0
        cmp lx0,x
        bcc _seg
        lda lx1,x
        cmp rx1
        bcc _seg
        ldx rx0
        lda lmask_x,x
        ldx rx1
        and rmask_x,x
        sta fmask
        ldy fcol
_fseg   lda ry0
        sec
        sbc #HY
        tax
        lda la_lo,x
        clc
        adc col8_lo,y
        sta ptr3
        lda la_hi,x
        adc col8_hi,y
        sta ptr3+1
        lda ry0
        ora #7
        cmp ry1
        bcc +
        lda ry1
+       sta fseg1
        sec
        sbc ry0
        tay                     ; lines - 1
-       lda (ptr3),y
        eor rpat
        and fmask
        eor (ptr3),y
        sta (ptr3),y
        dey
        bpl -
        lda fseg1
        cmp ry1
        bcs +
        adc #1
        sta ry0
        ldy fcol
        jmp _fseg
+       rts
_seg    ; segment: lines ry0 .. min(ry1, end of this char row)
        lda ry0
        ora #7
        cmp ry1
        bcc +
        lda ry1
+       sta fseg1
        sec
        sbc ry0
        sta flines              ; lines - 1
        lda ry0
        sec
        sbc #HY
        tax
        ; clip x to this row
        lda rx0
        cmp lx0,x
        bcs +
        lda lx0,x
+       sta fx0
        lda rx1
        cmp lx1,x
        bcc +
        lda lx1,x
+       sta fx1
        cmp fx0
        bcc _nextseg
        lda la_lo,x
        sta fbase
        lda la_hi,x
        sta fbase+1
        lda fx0
        lsr
        lsr
        sta fcol
        lda fx1
        lsr
        lsr
        sta fcol1
        ; left mask
        ldx fx0
        lda lmask_x,x
        sta fmask
_col    ldy fcol
        lda fbase
        clc
        adc col8_lo,y
        sta ptr3
        lda fbase+1
        adc col8_hi,y
        sta ptr3+1
        cpy fcol1
        bne +
        ldx fx1
        lda rmask_x,x
        and fmask
        sta fmask
+       ldy flines
        lda fmask
        cmp #$ff
        bne _masked
        lda rpat
-       sta (ptr3),y
        dey
        bpl -
        jmp _colnext
_masked
-       lda (ptr3),y
        eor rpat
        and fmask
        eor (ptr3),y
        sta (ptr3),y
        dey
        bpl -
_colnext
        lda #$ff
        sta fmask
        lda fcol
        cmp fcol1
        inc fcol
        bcc _col
_nextseg
        lda fseg1
        cmp ry1
        bcs +
        adc #1
        sta ry0
        jmp _seg
+       rts

lmask   .byte $ff, $3f, $0f, $03
rmask   .byte $c0, $f0, $fc, $ff
