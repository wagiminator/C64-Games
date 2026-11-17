; =====================================================================
;  Horizontal scrolling with two screens
;  The hidden screen is prepared as a copy of the displayed one, shifted
;  left by one column (generated copy code, two halves in two frames),
;  plus the new column 38 from the generator. When the fine scroll
;  passes 0, the screens are swapped and the fine scroll starts at 7.
; =====================================================================

ROWSPLIT = 14                   ; rows 2..13 in the first half, 14..24 in the second

; ---------------------------------------------------- generate the copy code (once)
gen_speedcode
        lda #<SPDA
        sta ptr0
        lda #>SPDA
        sta ptr0+1
        lda #>SCRA
        ldx #>SCRB
        jsr _dir
        lda ptr2
        sta spd_a2
        lda ptr2+1
        sta spd_a2+1
        lda #<SPDB
        sta ptr0
        lda #>SPDB
        sta ptr0+1
        lda #>SCRB
        ldx #>SCRA
        jsr _dir
        lda ptr2
        sta spd_b2
        lda ptr2+1
        sta spd_b2+1
        rts
_dir    ; ptr1 = source (row 2, column 1), ptr3 = destination (row 2, column 0)
        sta ptr1+1
        stx ptr3+1
        lda #<(2*40+1)
        sta ptr1
        lda #<(2*40)
        sta ptr3
        ; (2*40 < 256)
        lda #2
        sta tmp4                ; row
_row    lda tmp4
        cmp #ROWSPLIT
        bne +
        lda #$60                ; rts: end of the first half
        jsr _emit
        lda ptr0
        sta ptr2
        lda ptr0+1
        sta ptr2+1
+       lda #38
        sta tmp5
_col    lda #$ad                ; lda abs
        jsr _emit
        lda ptr1
        jsr _emit
        lda ptr1+1
        jsr _emit
        lda #$8d                ; sta abs
        jsr _emit
        lda ptr3
        jsr _emit
        lda ptr3+1
        jsr _emit
        inc ptr1
        bne +
        inc ptr1+1
+       inc ptr3
        bne +
        inc ptr3+1
+       dec tmp5
        bne _col
        ; next row: +2
        lda ptr1
        clc
        adc #2
        sta ptr1
        bcc +
        inc ptr1+1
+       lda ptr3
        clc
        adc #2
        sta ptr3
        bcc +
        inc ptr3+1
+       inc tmp4
        lda tmp4
        cmp #25
        bne _row
        lda #$60
_emit   ldy #0
        sta (ptr0),y
        inc ptr0
        bne +
        inc ptr0+1
+       rts

spd_a2  .word 0
spd_b2  .word 0

; ---------------------------------------------------- one preparation step for the hidden screen
prep_step
        lda swapnow             ; the old screen is still visible this frame
        bne _r
        lda prep
        cmp #2
        bcs _r
        tax
        inc prep
        lda disp
        bne _fromb
        cpx #0
        bne +
        jmp SPDA
+       jsr _a2
        jmp gen_column_hidden
_a2     jmp (spd_a2)
_fromb  cpx #0
        bne +
        jmp SPDB
+       jsr _b2
        jmp gen_column_hidden
_b2     jmp (spd_b2)
_r      rts

; ---------------------------------------------------- advance the scroll position
; moves 'spdf/spdi' pixels per frame; sets 'moved' and 'swapnow'
scroll_advance
        lda #0
        sta moved
        sta swapnow
        lda subpx
        clc
        adc spdf
        sta subpx
        lda spdi
        adc #0
        sta tmp7                ; pixels this frame
        beq _r
_px     lda xs
        beq _coarse
        dec xs
        jmp _one
_coarse lda prep
        cmp #2
        bcc _r                  ; not ready: stall (should not happen)
        lda swapnow
        bne _r                  ; at most one swap per frame
        lda #7
        sta xs
        lda disp
        eor #1
        sta disp
        lda #0
        sta prep
        inc swapnow
        inc wcl
        bne _one
        inc wch
_one    inc moved
        dec tmp7
        bne _px
_r      rts

; ---------------------------------------------------- screen pointers for row X
; scrp = displayed screen row X, scrq = other screen row X
row_ptrs
        lda rowlo,x
        sta scrp
        sta scrq
        lda disp
        bne +
        lda rowhiA,x
        sta scrp+1
        lda rowhiB,x
        sta scrq+1
        rts
+       lda rowhiB,x
        sta scrp+1
        lda rowhiA,x
        sta scrq+1
        rts

; ---------------------------------------------------- background char of world column (wc) and row
; tmp0/tmp1 = world column, X = screen row (2..24) -> A = char
bg_char
        lda tmp0
        and #63
        tay
        lda ctile,y
        tay
        lda tile_lo,y
        sta ptr2
        lda tile_hi,y
        sta ptr2+1
        lda tmp0
        and #7
        tay
        lda tcol_off,y
        clc
        adc ptr2
        sta ptr2
        bcc +
        inc ptr2+1
+       txa
        sec
        sbc #2
        tay
        lda (ptr2),y
        rts

; ---------------------------------------------------- clear a playfield cell on both screens
; X = screen row, Y = screen column of the displayed screen
clear_cell
        sty tmp3
        stx tmp2
        jsr row_ptrs
        ; world column = wc + col
        lda wcl
        clc
        adc tmp3
        sta tmp0
        lda wch
        adc #0
        sta tmp1
        jsr bg_char
        ldy tmp3
        sta (scrp),y
        ldx prep                ; other screen: shifted copy once copying has begun
        beq +
        dey
        bmi +
        sta (scrq),y
+       ldx tmp2
        ldy tmp3
        rts

; ---------------------------------------------------- fill one row of both screens with char A
; X = screen row (laser beams)
fill_row
        pha
        jsr row_ptrs
        pla
        ldy #38
-       sta (scrp),y
        sta (scrq),y
        dey
        bpl -
        rts

; restore row X of both screens from the background
restore_row
        stx tmp2
        jsr row_ptrs
        lda wcl
        sta tmp0
        lda wch
        sta tmp1
        lda #0
        sta tmp3
-       ldx tmp2
        jsr bg_char
        ldy tmp3
        sta (scrp),y
        dey
        bmi +
        sta (scrq),y            ; other screen holds world column + 1 at y - 1
+       inc tmp0
        bne +
        inc tmp1
+       inc tmp3
        lda tmp3
        cmp #39
        bne -
        ; last column of the other screen
        ldx tmp2
        jsr bg_char
        ldy #38
        sta (scrq),y
        ldx tmp2
        rts
