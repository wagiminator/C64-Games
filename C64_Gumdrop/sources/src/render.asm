; =====================================================================
;  Multicolour bitmap renderer
;  The board is 9 x 9 cells of 16 x 16 pixels (2 x 2 bitmap cells).
;  Each column is drawn from its display list (dcode, dyl/dyh). Sweets
;  alternate between the two colour slots of the screen RAM (%01 = high
;  nibble, %10 = low nibble), so two sweets can share a bitmap cell while
;  falling; %11 is white from colour RAM.
; =====================================================================

; ---------------------------------------------------- clear the whole game screen
clear_game_screen
        lda #<BITMAP
        sta ptr0
        lda #>BITMAP
        sta ptr0+1
        ldx #32
        lda #0
        tay
-       sta (ptr0),y
        iny
        bne -
        inc ptr0+1
        dex
        bne -
        ldx #0
-       lda #0
        sta SCRG,x
        sta SCRG+$100,x
        sta SCRG+$200,x
        sta SCRG+$2e8,x
        lda #1
        sta COLRAM,x
        sta COLRAM+$100,x
        sta COLRAM+$200,x
        sta COLRAM+$2e8,x
        inx
        bne -
        ; text rows: spaces
        ldx #199
        lda #32
-       sta SCRG+TEXTROW*40,x
        dex
        cpx #$ff
        bne -
        rts

; ---------------------------------------------------- side pictures and board frame
draw_decor
        ; jar (columns 0..9) and meter (columns 30..39)
        lda #<jar_bm
        sta dptr
        lda #>jar_bm
        sta dptr+1
        lda #<jar_scr
        sta ptr2
        lda #>jar_scr
        sta ptr2+1
        lda #<jar_col
        sta ptr3
        lda #>jar_col
        sta ptr3+1
        lda #0
        jsr _pic
        lda #<met_bm
        sta dptr
        lda #>met_bm
        sta dptr+1
        lda #<met_scr
        sta ptr2
        lda #>met_scr
        sta ptr2+1
        lda #<met_col
        sta ptr3
        lda #>met_col
        sta ptr3+1
        lda #30
        jsr _pic
        jmp draw_frame
_pic    sta tmp4                ; first column
        lda #0
        sta tmp5                ; row
_prow   ldx tmp5
        lda bmrow_lo,x
        sta bptr
        lda bmrow_hi,x
        sta bptr+1
        lda tmp4
        asl
        asl
        asl
        clc
        adc bptr
        sta bptr
        bcc +
        inc bptr+1
+       ; 10 cells x 8 bytes = 80 bytes in a row
        ldy #79
-       lda (dptr),y
        sta (bptr),y
        dey
        bpl -
        lda dptr
        clc
        adc #80
        sta dptr
        bcc +
        inc dptr+1
+       ; colours
        lda rowlo,x
        clc
        adc tmp4
        sta sptr2
        sta ptr1
        lda rowhiG,x
        adc #0
        sta sptr2+1
        lda rowlo,x
        clc
        adc tmp4
        lda rowhiC,x
        adc #0
        sta ptr1+1
        ldy #9
-       lda (ptr2),y
        sta (sptr2),y
        lda (ptr3),y
        sta (ptr1),y
        dey
        bpl -
        lda ptr2
        clc
        adc #10
        sta ptr2
        bcc +
        inc ptr2+1
+       lda ptr3
        clc
        adc #10
        sta ptr3
        bcc +
        inc ptr3+1
+       inc tmp5
        lda tmp5
        cmp #20
        bne _prow
        rts

; candy cane frame: rows 0 and 19 (columns 10..29), columns 10 and 29 (rows 1..18)
draw_frame
        ldx #10
_fx     txa
        pha
        ldy #0
        jsr _cellptr            ; row 0, column x
        ldy #7
-       lda frm_top,y
        sta (bptr),y
        dey
        bpl -
        pla
        pha
        tax
        ldy #19
        jsr _cellptr
        ldy #7
-       lda frm_top,y
        sta (bptr),y
        dey
        bpl -
        pla
        tax
        lda #$20                ; red in the high nibble
        sta SCRG+10-10,x
        sta SCRG+19*40,x
        inx
        cpx #30
        bne _fx
        ldy #1
_fy     tya
        pha
        ldx #10
        jsr _cellptr
        ldy #7
-       lda frm_side,y
        sta (bptr),y
        dey
        bpl -
        pla
        pha
        tay
        ldx #29
        jsr _cellptr
        ldy #7
-       lda frm_side,y
        sta (bptr),y
        dey
        bpl -
        pla
        tay
        lda rowlo,y
        sta sptr2
        lda rowhiG,y
        sta sptr2+1
        tya
        pha
        lda #$20
        ldy #10
        sta (sptr2),y
        ldy #29
        sta (sptr2),y
        pla
        tay
        iny
        cpy #19
        bne _fy
        ; corners
        ldx #10
        ldy #0
        jsr _corner
        ldx #29
        ldy #0
        jsr _corner
        ldx #10
        ldy #19
        jsr _corner
        ldx #29
        ldy #19
_corner jsr _cellptr
        ldy #7
-       lda frm_corner,y
        sta (bptr),y
        dey
        bpl -
        rts
; bptr = bitmap cell at column X, row Y
_cellptr
        lda bmrow_lo,y
        sta bptr
        lda bmrow_hi,y
        sta bptr+1
        txa
        asl
        asl
        asl
        php
        clc
        adc bptr
        sta bptr
        lda bptr+1
        adc #0
        plp
        bcc +
        adc #0                  ; x * 8 >= 256 (carry from the shift)
+       sta bptr+1
        rts

; ---------------------------------------------------- column buffers
; Every column is first composed in RAM (left and right byte column of the
; 144 board lines and the colour nibble of the 18 cell rows), then copied to
; the bitmap in one go. The bitmap is never cleared while it is visible, so
; moving sweets do not flicker.
CBL     = $c400                 ; 9 x 144 left bytes
CBR     = CBL+9*144             ; 9 x 144 right bytes
CBN     = CBR+9*144             ; 9 x 18 colour nibbles

; X = column -> cbl / cbr = buffers of the column, rc_n = nibble index, rc_x = screen column
col_base
        stx rc_c
        txa
        asl
        clc
        adc #BX0
        sta rc_x
        lda col144_lo,x
        clc
        adc #<CBL
        sta cbl
        lda col144_hi,x
        adc #>CBL
        sta cbl+1
        lda col144_lo,x
        clc
        adc #<CBR
        sta cbr
        lda col144_hi,x
        adc #>CBR
        sta cbr+1
        lda col18,x
        sta rc_n
        rts
col144_lo .byte <(0*144), <(1*144), <(2*144), <(3*144), <(4*144), <(5*144), <(6*144), <(7*144), <(8*144)
col144_hi .byte >(0*144), >(1*144), >(2*144), >(3*144), >(4*144), >(5*144), >(6*144), >(7*144), >(8*144)
col18   .byte 0, 18, 36, 54, 72, 90, 108, 126, 144

; ---------------------------------------------------- render all columns
render_all
        ldx #0
-       txa
        pha
        jsr compose_column
        pla
        tax
        inx
        cpx #9
        bne -
        jsr waitframe
        ldx #0
-       txa
        pha
        jsr copy_column
        pla
        tax
        inx
        cpx #9
        bne -
        rts

; ---------------------------------------------------- render column X (compose and copy)
render_column
        txa
        pha
        jsr compose_column
        pla
        tax
        jmp copy_column

rc_c    .byte 0
rc_k    .byte 0
rc_y    .word 0
rc_nib  .byte 0
rc_x    .byte 0                 ; screen column of the left half
rc_n    .byte 0                 ; first nibble of the column

; ---------------------------------------------------- compose column X in its buffer
compose_column
        jsr col_base
        ; ---- clear
        lda #0
        ldy #143
-       sta (cbl),y
        sta (cbr),y
        dey
        cpy #$ff
        bne -
        ldx rc_n
        ldy #17
-       sta CBN,x
        inx
        dey
        bpl -
        ; ---- ice
        lda #0
        sta rc_k
_ice    lda rc_k
        asl
        asl
        asl
        adc rc_k                ; row * 9
        adc rc_c
        tax
        lda ice,x
        beq _nice
        ldx #0
        cmp #2
        bcc +
        ldx #32
+       stx tmp7
        lda rc_k
        asl
        asl
        asl
        asl
        sta rc_y
        lda #0
        sta rc_y+1
        lda #<ice_bm
        clc
        adc tmp7
        sta dptr
        lda #>ice_bm
        adc #0
        sta dptr+1
        jsr blit
_nice   inc rc_k
        lda rc_k
        cmp #9
        bne _ice
        ; ---- sweets of the display list
        lda #0
        sta rc_k
_sw     lda rc_c
        asl
        asl
        asl
        adc rc_c
        adc rc_k
        tax
        lda dcode,x
        cmp #EMPTY
        beq _nsw
        pha
        lda dyl,x
        sta rc_y
        lda dyh,x
        sta rc_y+1
        pla
        jsr shape_of            ; -> A = shape, X = colour
        stx tmp6
        ; data pointer: shape * 32 in table A or B (parity)
        sta dptr
        lda #0
        sta dptr+1
        ldx #5
-       asl dptr
        rol dptr+1
        dex
        bne -
        lda rc_k
        and #1
        bne _pb
        lda dptr
        clc
        adc #<shapeA
        sta dptr
        lda dptr+1
        adc #>shapeA
        sta dptr+1
        lda tmp6
        asl
        asl
        asl
        asl
        sta rc_nib
        jmp _go
_pb     lda dptr
        clc
        adc #<shapeB
        sta dptr
        lda dptr+1
        adc #>shapeB
        sta dptr+1
        lda tmp6
        sta rc_nib
_go     jsr blit
        jsr nibbles
_nsw    inc rc_k
        lda rc_k
        cmp #9
        bne _sw
        rts

; ---------------------------------------------------- copy the buffer of column X to the screen
copy_column
        jsr col_base
        lda cbl
        sta ptr2
        lda cbl+1
        sta ptr2+1
        lda cbr
        sta ptr3
        lda cbr+1
        sta ptr3+1
        ldx #1
_row    lda rc_x
        asl
        asl
        asl
        clc
        adc bmrow_lo,x
        sta bptr
        lda bmrow_hi,x
        adc #0
        sta bptr+1
        lda bptr
        clc
        adc #8
        sta ptr1
        lda bptr+1
        adc #0
        sta ptr1+1
        ldy #7
-       lda (ptr2),y
        sta (bptr),y
        lda (ptr3),y
        sta (ptr1),y
        dey
        bpl -
        ; colours of the two cells
        lda rowlo,x
        clc
        adc rc_x
        sta sptr2
        lda rowhiG,x
        adc #0
        sta sptr2+1
        txa
        clc
        adc rc_n
        tay
        lda CBN-1,y
        ldy #0
        sta (sptr2),y
        iny
        sta (sptr2),y
        ; next cell row
        lda ptr2
        clc
        adc #8
        sta ptr2
        bcc +
        inc ptr2+1
+       lda ptr3
        clc
        adc #8
        sta ptr3
        bcc +
        inc ptr3+1
+       inx
        cpx #19
        bne _row
        rts

; shape and colour of display code A -> A = shape, X = colour
shape_of
        cmp #$40
        bcs _pop
        sta tmp7
        and #7
        cmp #RAINBOW
        bne +
        ldx rbcol
        lda #SH_RAINBOW
        rts
+       tax
        lda sweet_col,x
        pha
        txa
        asl
        asl
        sta tmp5
        lda tmp7
        lsr
        lsr
        lsr
        and #3
        ora tmp5
        tay
        pla
        tax
        tya
        rts
_pop    sta tmp7
        and #7
        tax
        lda sweet_col,x
        cpx #RAINBOW
        bcc +
        lda #1
+       tax
        lda tmp7
        lsr
        lsr
        lsr
        lsr
        and #1
        clc
        adc #SH_POP0
        rts

; OR 16 lines of 2 bytes from dptr into the column buffer at board line rc_y (signed)
blit
        lda dptr
        sta _bl+1
        clc
        adc #1
        sta _br+1
        lda dptr+1
        sta _bl+2
        adc #0
        sta _br+2
        ldx #0                  ; data index (line * 2)
_ln     txa
        lsr
        clc
        adc rc_y
        tay
        lda rc_y+1
        adc #0
        bne _skip               ; < 0 or > 255
        cpy #144
        bcs _skip
_bl     lda $1000,x
        ora (cbl),y
        sta (cbl),y
_br     lda $1000,x
        ora (cbr),y
        sta (cbr),y
_skip   inx
        inx
        cpx #32
        bne _ln
        rts

; colour nibble rc_nib into the cell rows covered by the sweet at rc_y
nibbles
        lda rc_y
        clc
        adc #15
        sta tmp3
        lda rc_y+1
        adc #0
        bmi _r                  ; ends above the board
        bne _l143
        lda tmp3
        cmp #144
        bcc +
_l143   lda #143
        sta tmp3                ; last line
+       lda rc_y+1
        bpl +
        lda #0
        beq ++
+       lda rc_y
+       ; cell rows 0..17 = line / 8
        lsr
        lsr
        lsr
        clc
        adc rc_n
        tax
        lda tmp3
        lsr
        lsr
        lsr
        clc
        adc rc_n
        sta tmp3
-       lda CBN,x
        ora rc_nib
        sta CBN,x
        cpx tmp3
        inx
        bcc -
_r      rts

; ---------------------------------------------------- display list from the board (column X)
dlist_from_board
        stx tmp0
        ldy #0                  ; row
-       tya
        asl
        asl
        asl
        sta tmp1
        tya
        clc
        adc tmp1                ; row * 9
        adc tmp0
        tax
        lda board,x
        pha
        lda tmp0
        asl
        asl
        asl
        adc tmp0
        sta tmp1
        tya
        clc
        adc tmp1
        tax
        pla
        sta dcode,x
        tya
        asl
        asl
        asl
        asl
        sta dyl,x
        lda #0
        sta dyh,x
        iny
        cpy #9
        bne -
        ldx tmp0
        rts

dlist_all
        ldx #0
-       jsr dlist_from_board
        inx
        cpx #9
        bne -
        rts

; ---------------------------------------------------- rainbow sweets: cycle the colour
rainbow_cycle
        inc rbtime
        lda rbtime
        and #3
        bne _r
        ldx rbcol
        lda rb_next,x
        sta rbcol
        ; update the colour nibbles of all rainbow sweets at rest
        ldx #80
-       lda board,x
        cmp #RAINBOW
        bne _n
        stx tmp0
        jsr cell_rc             ; -> tmp1 row, tmp2 column
        jsr rb_nib
        ldx tmp0
_n      dex
        bpl -
_r      rts
rb_next .byte 2,2,8,1,14,7,4,4,10,9,13,0,0,5,4,3
; cell index tmp0 -> tmp1 = row, tmp2 = column
cell_rc
        lda tmp0
        ldx #0
-       cmp #9
        bcc +
        sbc #9
        inx
        bne -
+       sta tmp2
        stx tmp1
        rts
; set the rainbow colour in the 2 x 2 cells of board cell (tmp1, tmp2)
rb_nib
        lda tmp1
        asl
        clc
        adc #1                  ; screen row
        tax
        lda tmp2
        asl
        adc #BX0
        sta tmp3
        lda #2
        sta tmp4
_rw     lda rowlo,x
        clc
        adc tmp3
        sta sptr2
        lda rowhiG,x
        adc #0
        sta sptr2+1
        ldy #1
-       lda (sptr2),y
        sta tmp5
        lda tmp1
        and #1
        bne _lo
        lda tmp5
        and #$0f
        sta tmp5
        lda rbcol
        asl
        asl
        asl
        asl
        ora tmp5
        jmp +
_lo     lda tmp5
        and #$f0
        ora rbcol
+       sta (sptr2),y
        dey
        bpl -
        inx
        dec tmp4
        bne _rw
        rts

; ---------------------------------------------------- the goal meter: fill to meterh lines
draw_meter
        lda #MET_BOT
        sec
        sbc meterh
        sta tmp6                ; lines above this one are empty
        lda #MET_TOP
        sta tmp4
_ml     lda tmp4
        lsr
        lsr
        lsr
        tax                     ; screen row
        lda tmp4
        and #7
        clc
        adc bmrow_lo,x
        sta bptr
        lda bmrow_hi,x
        adc #0
        sta bptr+1
        ; column MET_X0 * 8
        lda bptr
        clc
        adc #<(MET_X0*8)
        sta bptr
        lda bptr+1
        adc #>(MET_X0*8)
        sta bptr+1
        lda #0
        ldx tmp4
        cpx tmp6
        bcc +
        beq +
        lda #$55
+       ldy #0
        sta (bptr),y
        ldy #8
        sta (bptr),y
        ldy #16
        sta (bptr),y
        ldy #24
        sta (bptr),y
        inc tmp4
        lda tmp4
        cmp #MET_BOT+1
        bne _ml
        rts

; fill colour of the meter (high nibble) in its interior cells
meter_colour
        ldx #MET_TOP/8
-       lda rowlo,x
        clc
        adc #MET_X0
        sta sptr2
        lda rowhiG,x
        adc #0
        sta sptr2+1
        ldy #3
        lda #$a0                ; pink
-       sta (sptr2),y
        dey
        bpl -
        inx
        cpx #MET_BOT/8+1
        bne --
        rts
