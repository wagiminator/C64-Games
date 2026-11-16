; =====================================================================
;  Vertical scrolling engine: wall/island generation, double buffers
; =====================================================================

init_level
        ; terrain charset & colours
        lda level
        asl
        tax
        lda terr_ofs,x
        sta ptr0
        lda terr_ofs+1,x
        sta ptr0+1
        ldy #0
-       lda (ptr0),y
        sta CHARSET+128*8,y
        iny
        bne -
        lda level
        asl
        asl
        asl
        asl
        asl
        tax
        ldy #0
-       lda terr_cols,x
        sta charcol+128,y
        inx
        iny
        cpy #32
        bne -
        ldx level
        lda lev_d022,x
        sta $d022
        lda lev_d023,x
        sta $d023
        lda level_tab_lo,x
        sta ptr0
        lda level_tab_hi,x
        sta ptr0+1
        ldy #0
        lda (ptr0),y
        sta gL
        iny
        lda (ptr0),y
        sta gR
        ldy #2
        lda (ptr0),y
        sta runptr
        iny
        lda (ptr0),y
        sta runptr+1
        iny
        lda (ptr0),y
        sta evptr
        iny
        lda (ptr0),y
        sta evptr+1
        iny
        lda (ptr0),y
        sta stoprow
        iny
        lda (ptr0),y
        sta stoprow+1
        iny
        lda (ptr0),y
        sta islptr
        iny
        lda (ptr0),y
        sta islptr+1
        lda #0
        sta runleft
        sta genrow
        sta genrow+1
        sta is_h
        sta is_h+1
        sta is_h+2
        jsr run_step
        ; clear both screens rows 0..21
        ldx #0
        lda #32
-       sta SCRA,x
        sta SCRA+256,x
        sta SCRA+512,x
        sta SCRB,x
        sta SCRB+256,x
        sta SCRB+512,x
        inx
        bne -
        ldx #22*40-768-1
-       sta SCRA+768,x
        sta SCRB+768,x
        dex
        bpl -
        ; generate rows bottom (screen row 20) to top (row 0)
        lda #20
        sta tmp6
_ir     jsr gen_row
        ldx tmp6
        lda rowlo,x
        sta ptr0
        sta ptr1
        lda rowhiA,x
        sta ptr0+1
        lda rowhiC,x
        sta ptr1+1
        ldy #39
-       lda rowchars,y
        sta (ptr0),y
        lda rowcols,y
        sta (ptr1),y
        dey
        bpl -
        lda tmp6
        beq +
        jsr advance_gen
        dec tmp6
        jmp _ir
+       ldx #39
        lda #0
-       sta COLRAM+21*40,x
        dex
        bpl -
        lda #0
        sta yfine
        sta front
        sta scrollpx
        sta cur_scrollpx
        lda #1
        sta scrolling
        rts

; ---------------------------------------------------- run iterator (dl, dr)
run_step
        lda runleft
        bne _go
        ldy #0
        lda (runptr),y
        bne +
        lda #0
        sta rundl
        sta rundr
        beq _apply
+       sta runleft
        iny
        lda (runptr),y
        pha
        and #3
        tax
        lda dcode,x
        sta rundl
        pla
        lsr
        lsr
        and #3
        tax
        lda dcode,x
        sta rundr
        lda runptr
        clc
        adc #2
        sta runptr
        bcc _go
        inc runptr+1
_go     dec runleft
_apply  lda gL
        clc
        adc rundl
        sta nL
        lda gR
        clc
        adc rundr
        sta nR
        rts
dcode   .byte 0,1,$ff,0

advance_gen
        lda nL
        sta gL
        lda nR
        sta gR
        ; age islands
        ldx #2
-       lda is_h,x
        beq +
        inc is_k,x
        lda is_k,x
        cmp is_h,x
        bne +
        lda #0
        sta is_h,x
+       dex
        bpl -
        inc genrow
        bne +
        inc genrow+1
+       jmp run_step

; ---------------------------------------------------- row generation
; builds rowchars[0..39] / rowcols[0..39] for map row genrow
gen_row
        ; activate islands starting at this row
_ia     ldy #1
        lda (islptr),y
        cmp #$ff
        beq _bg
        cmp genrow+1
        bne _bg
        dey
        lda (islptr),y
        cmp genrow
        bne _bg
        ldx #2
-       lda is_h,x
        beq +
        dex
        bpl -
        ldx #0
+       ldy #2
        lda (islptr),y
        sta is_col,x
        iny
        lda (islptr),y
        sta is_w,x
        iny
        lda (islptr),y
        sta is_h,x
        lda #0
        sta is_k,x
        lda islptr
        clc
        adc #5
        sta islptr
        bcc _ia
        inc islptr+1
        bne _ia
_bg     ; background stars
        lda genrow
        and #7
        sta tmp7
        tax
        lda bgofs_lo,x
        sta ptr2
        lda bgofs_hi,x
        sta ptr2+1
        ldy #39
-       lda (ptr2),y
        sta rowchars,y
        dey
        bpl -
        ; ---- left wall
        lda gL
        beq _right
        lda nL
        sec
        sbc gL
        beq _lflat
        cmp #1
        beq _lgrow
        ldx gL                  ; shrinking: edge cell becomes lower-left slope
        dex
        lda #128+9
        bne _lset
_lgrow  ldx gL                  ; growing: extra upper-left slope at gL
        lda #128+8
        bne _lset
_lflat  ldx gL
        dex
        lda #128+0
        clc
        adc tmp7
_lset   sta rowchars,x
        ldy #1
        dex
        bmi _right
-       jsr depthchar
        sta rowchars,x
        iny
        dex
        bpl -
_right  ; ---- right wall: first solid column F = 40-gR
        lda gR
        beq _isl
        lda #40
        sec
        sbc gR
        sta tmp5
        lda nR
        sec
        sbc gR
        beq _rflat
        cmp #1
        beq _rgrow
        ldx tmp5                ; shrinking
        lda #128+19
        bne _rset
_rgrow  ldx tmp5
        dex
        lda #128+18
        bne _rset
_rflat  ldx tmp5
        lda #128+10
        clc
        adc tmp7
_rset   sta rowchars,x
        ldy #1
        inx
        cpx #40
        bcs _isl
-       jsr depthchar
        clc
        adc #10
        sta rowchars,x
        iny
        inx
        cpx #40
        bcc -
_isl    ; ---- islands
        ldx #2
_il     lda is_h,x
        beq _inx
        stx tmp4
        ; vertical tile row: 0 top, 1 mid, 2 bottom
        ldy #1
        lda is_k,x
        bne +
        ldy #2
+       clc
        adc #1
        cmp is_h,x
        bne +
        ldy #0
+       lda tiley3,y
        sta tmp3
        lda is_col,x
        tay
        clc
        adc is_w,x
        sta tmp2                ; end column
        ; left tile
        lda tmp3
        clc
        adc #128+20
        sta rowchars,y
        iny
-       cpy tmp2
        beq _ilr
        lda tmp3
        clc
        adc #128+21
        sta rowchars,y
        iny
        jmp -
_ilr    dey
        lda tmp3
        clc
        adc #128+22
        sta rowchars,y
        ldx tmp4
_inx    dex
        bpl _il
        ; ---- colours
        ldx #39
-       ldy rowchars,x
        lda charcol,y
        sta rowcols,x
        dex
        bpl -
        rts
tiley3  .byte 0,3,6

; Y = depth (>=1), X = column -> A = left wall depth char
depthchar
        cpy #1
        bne +
        lda #128+2
        clc
        adc tmp7
        rts
+       txa
        and #1
        asl
        clc
        adc #128+4
        adc tmp7
        rts

; ---------------------------------------------------- buffer shift (front -> back, one row down)
; X = first column, tmp0 = end column (exclusive)
shift_ab
-
        .for r := 0, r < PFROWS-1, r += 1
        lda SCRA + r*40,x
        sta SCRB + (r+1)*40,x
        .next
        inx
        cpx tmp0
        beq +
        jmp -
+       rts
shift_ba
-
        .for r := 0, r < PFROWS-1, r += 1
        lda SCRB + r*40,x
        sta SCRA + (r+1)*40,x
        .next
        inx
        cpx tmp0
        beq +
        jmp -
+       rts

put_row_a
        ldx #39
-       lda rowchars,x
        sta SCRA,x
        dex
        bpl -
        rts
put_row_b
        ldx #39
-       lda rowchars,x
        sta SCRB,x
        dex
        bpl -
        rts

; ---------------------------------------------------- per frame scroll update
scroll_update
        lda #0
        sta scrolled
        lda scrolling
        bne +
        jmp _regs
+       lda #1
        sta scrolled
        inc scrollpx
        inc yfine
        lda yfine
        cmp #8
        bne _phase
        ; ---- coarse step
        lda #0
        sta yfine
        lda front
        eor #1
        sta front
        lda #1
        sta nx_cshift
        jsr process_events
        lda genrow
        cmp stoprow
        bne _regs
        lda genrow+1
        cmp stoprow+1
        bne _regs
        lda #0
        sta scrolling
        jsr boss_trigger
        jmp _regs
_phase  ldx yfine
        cpx #5
        bcs _gen
        lda shift_from-1,x
        sta tmp1
        lda shift_to-1,x
        sta tmp0
        ldx tmp1
        lda front
        bne +
        jsr shift_ab
        jmp _regs
+       jsr shift_ba
        jmp _regs
_gen    bne _regs               ; only at yfine == 5
        jsr advance_gen
        jsr gen_row
        lda front
        bne +
        jsr put_row_b
        jmp _regs
+       jsr put_row_a
_regs   lda yfine
        ora #$10
        sta nx_d011
        lda #SPLITL             ; fixed: the bottom edge is drawn at BLANKL
        sta nx_split
        lda front
        beq +
        lda #D018B
        bne ++
+       lda #D018A
+       sta nx_d018
        rts
shift_from .byte 0,10,20,30
shift_to   .byte 10,20,30,40

; ---------------------------------------------------- char lookup at sprite coords
; in: tmp0/tmp1 = x (16 bit sprite coord), A = y (sprite coord)
; out: A = char (0 if outside), N set if solid; tmp2 = local x (pixel), tmp3 = local y
charat
        sec
        sbc #47
        bcc _out
        sec
        sbc yfine
        bcc _out
        sta tmp3
        lsr
        lsr
        lsr
        cmp #PFROWS
        bcs _out
        tay
        lda tmp0
        sec
        sbc #24
        sta tmp2
        lda tmp1
        sbc #0
        bmi _out
        lsr
        lda tmp2
        ror
        lsr
        lsr
        cmp #40
        bcs _out
        clc
        adc rowlo,y
        sta ptr3
        lda front
        bne +
        lda rowhiA,y
        bne ++
+       lda rowhiB,y
+       adc #0
        sta ptr3+1
        ldy #0
        lda (ptr3),y
        rts
_out    lda #0
        rts

; ---------------------------------------------------- level events (row based)
process_events
_lp     ldy #1
        lda (evptr),y
        cmp #$ff
        beq _done
        cmp genrow+1
        bcc _fire
        bne _done
        dey
        lda (evptr),y
        cmp genrow
        beq _fire
        bcs _done
_fire   ldy #2
        lda (evptr),y
        sta tmp0                ; type
        iny
        lda (evptr),y
        sta tmp1                ; count
        iny
        lda (evptr),y
        sta tmp2                ; x lo
        iny
        lda (evptr),y
        sta tmp3                ; param (bit7 = x hi)
        jsr spawn_event
        lda evptr
        clc
        adc #6
        sta evptr
        bcc _lp
        inc evptr+1
        bne _lp
_done   rts
