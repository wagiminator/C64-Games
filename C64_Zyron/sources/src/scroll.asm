; =====================================================================
;  Scrolling engine: terrain generation, double-buffered screens
; =====================================================================

; ---------------------------------------------------- level init
init_level
        ; terrain charset
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
        ; terrain colours
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
        lda lev_hcol,x
        ldy #11
-       sta charcol+LAY_H,y
        dey
        bpl -
        lda lev_d022,x
        sta $d022
        lda lev_d023,x
        sta $d023
        ; level header
        lda level_tab_lo,x
        sta ptr0
        lda level_tab_hi,x
        sta ptr0+1
        ldy #0
        lda (ptr0),y
        sta gC
        iny
        lda (ptr0),y
        sta gF
        iny
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
        sta stopcol
        iny
        lda (ptr0),y
        sta stopcol+1
        lda #0
        sta runleft
        sta genx
        sta genx+1
        jsr run_step
        ; clear both screens (rows 0..21)
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
        ; draw columns 0..38 into screen A + colour ram
        lda #0
        sta tmp6
_ic     jsr gen_column
        ldx #0
-       lda rowlo,x
        clc
        adc tmp6
        sta ptr0
        sta ptr1
        lda rowhiA,x
        adc #0
        sta ptr0+1
        lda rowlo,x
        clc
        adc tmp6
        lda rowhiC,x
        adc #0
        sta ptr1+1
        ldy #0
        lda colchars,x
        sta (ptr0),y
        lda colbuf,x
        sta (ptr1),y
        inx
        cpx #PFROWS
        bne -
        lda tmp6
        cmp #38
        beq +
        jsr advance_gen
        inc tmp6
        bne _ic
+       ; copy rows to screen B as well (not needed, back buffer gets rebuilt)
        lda #38
        sta rightcol
        lda #0
        sta rightcol+1
        lda #7
        sta xfine
        lda #0
        sta front
        sta scrollpx
        sta cur_scrollpx
        lda #1
        sta scrolling
        ; row 21 colour = black
        ldx #39
        lda #0
-       sta COLRAM+21*40,x
        dex
        bpl -
        rts

; ---------------------------------------------------- run iterator
run_step
        lda runleft
        bne _go
        ldy #0
        lda (runptr),y
        bne +
        lda #0                  ; end of runs: stay flat
        sta rundc
        sta rundf
        beq _apply
+       sta runleft
        iny
        lda (runptr),y
        pha
        and #3
        tax
        lda dcode,x
        sta rundc
        pla
        lsr
        lsr
        and #3
        tax
        lda dcode,x
        sta rundf
        lda runptr
        clc
        adc #2
        sta runptr
        bcc _go
        inc runptr+1
_go     dec runleft
_apply  lda gC
        clc
        adc rundc
        sta nC
        lda gF
        clc
        adc rundf
        sta nF
        rts
dcode   .byte 0,1,$ff,0
; xfine 3..6 -> column ranges
shift_from .byte 30,20,10,0
shift_to   .byte 38,30,20,10

advance_gen
        lda nC
        sta gC
        lda nF
        sta gF
        inc genx
        bne +
        inc genx+1
+       jmp run_step

; ---------------------------------------------------- column generation
; builds colchars[0..20] and colbuf[0..20] for map column genx (heights gC/gF, next nC/nF)
gen_column
        lda genx
        and #7
        tax
        lda bgofs_lo,x
        sta ptr2
        lda bgofs_hi,x
        sta ptr2+1
        ldy #PFROWS-1
-       lda (ptr2),y
        sta colchars,y
        dey
        bpl -
        lda genx
        and #1
        sta tmp7
        ; ---- ceiling
        lda gC
        beq _floor
        lda nC
        sec
        sbc gC
        beq _cflat
        cmp #1
        beq _cdown
        ; rising: E = gC-1, slope 19
        ldx gC
        dex
        lda #128+19
        bne _cset
_cdown  ldx gC
        lda #128+18
        bne _cset
_cflat  ldx gC
        dex
        lda #128+10
        clc
        adc tmp7
_cset   sta colchars,x
        stx tmp4                ; E
        ldy #1                  ; depth
        dex
        bmi _floor
-       jsr depthchar
        clc
        adc #10
        sta colchars,x
        iny
        dex
        bpl -
_floor  ; ---- floor
        lda gF
        beq _cols
        lda #21
        sec
        sbc gF
        sta tmp5                ; T
        lda nF
        sec
        sbc gF
        beq _fflat
        cmp #1
        beq _fup
        ; falling: E = T, slope 9
        ldx tmp5
        lda #128+9
        bne _fset
_fup    ldx tmp5
        dex
        lda #128+8
        bne _fset
_fflat  ldx tmp5
        lda #128
        clc
        adc tmp7
_fset   sta colchars,x
        ldy #1
        inx
        cpx #PFROWS
        bcs _cols
-       jsr depthchar
        sta colchars,x
        iny
        inx
        cpx #PFROWS
        bcc -
_cols   ldx #PFROWS-1
-       ldy colchars,x
        lda charcol,y
        sta colbuf,x
        dex
        bpl -
        rts

; Y = depth (>=1), X = row -> A = floor char
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

; ---------------------------------------------------- screen shift (front -> back, shifted left)
; X = first column, tmp0 = end column (exclusive)
shift_ab
-
        .for r := 0, r < PFROWS, r += 1
        lda SCRA + r*40 + 1,x
        sta SCRB + r*40,x
        .next
        inx
        cpx tmp0
        beq +
        jmp -
+       rts
shift_ba
-
        .for r := 0, r < PFROWS, r += 1
        lda SCRB + r*40 + 1,x
        sta SCRA + r*40,x
        .next
        inx
        cpx tmp0
        beq +
        jmp -
+       rts

put_col_a
        .for r := 0, r < PFROWS, r += 1
        lda colchars+r
        sta SCRA + r*40 + 38
        .next
        rts
put_col_b
        .for r := 0, r < PFROWS, r += 1
        lda colchars+r
        sta SCRB + r*40 + 38
        .next
        rts

; ---------------------------------------------------- per frame scroll update (main loop)
scroll_update
        lda #0
        sta scrolled
        lda scrolling
        bne +
        jmp _regs
+       lda #1
        sta scrolled
        inc scrollpx
        dec xfine
        bpl _phase
        ; ---- coarse step
        lda #7
        sta xfine
        lda front
        eor #1
        sta front
        lda #1
        sta nx_cshift
        inc rightcol
        bne +
        inc rightcol+1
+       jsr process_events
        lda rightcol
        cmp stopcol
        bne _regs
        lda rightcol+1
        cmp stopcol+1
        bne _regs
        lda #0
        sta scrolling
        jsr boss_trigger
        jmp _regs
_phase  ldx xfine
        cpx #3
        bcc _gen
        lda shift_from-3,x
        sta tmp1
        lda shift_to-3,x
        sta tmp0
        ldx tmp1
        lda front
        bne +
        jsr shift_ab
        jmp _regs
+       jsr shift_ba
        jmp _regs
_gen    cpx #2
        bne _regs
        jsr advance_gen
        jsr gen_column
        lda front
        bne +
        jsr put_col_b
        jmp _regs
+       jsr put_col_a
_regs   lda xfine
        ora #$10
        sta nx_d016
        lda front
        beq +
        lda #D018B
        bne ++
+       lda #D018A
+       sta nx_d018
        rts

; ---------------------------------------------------- char lookup at sprite coords
; in: tmp0/tmp1 = x (16 bit sprite coord), A = y (sprite coord)
; out: A = char code (0 if outside), N set if solid (>= 128)
charat
        sec
        sbc #50
        bcc _out
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
        sta tmp3
        lda tmp2
        sec
        sbc xfine
        sta tmp2
        lda tmp3
        sbc #0
        bmi _out
        lsr
        lda tmp2
        ror
        lsr
        lsr
        cmp #39
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

; ---------------------------------------------------- level events
process_events
_lp     ldy #1
        lda (evptr),y
        cmp #$ff
        beq _done
        cmp rightcol+1
        bcc _fire
        bne _done
        dey
        lda (evptr),y
        cmp rightcol
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
        sta tmp2                ; y
        iny
        lda (evptr),y
        sta tmp3                ; param
        jsr spawn_event
        lda evptr
        clc
        adc #6
        sta evptr
        bcc _lp
        inc evptr+1
        bne _lp
_done   rts
