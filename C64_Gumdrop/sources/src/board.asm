; =====================================================================
;  Board logic: generation, matches, specials, gravity, moves, shuffle
;  cell index = row * 9 + column
; =====================================================================

; colour of code A for matching -> A ($fe = never matches)
colour_of
        cmp #EMPTY
        beq _no
        and #7
        cmp #RAINBOW
        bne _r
_no     lda #$fe
_r      rts

; ---------------------------------------------------- new board without matches and with a move
fill_board
        ldx #0
_cell   stx tmp0
_again  lda ncol
        jsr rndmod
        sta tmp1
        ; two to the left?
        ldx tmp0
        jsr col_of_x
        cmp #2
        bcc +
        ldx tmp0
        lda board-1,x
        cmp tmp1
        bne +
        lda board-2,x
        cmp tmp1
        beq _again
+       ldx tmp0
        cpx #18
        bcc +
        lda board-9,x
        cmp tmp1
        bne +
        lda board-18,x
        cmp tmp1
        beq _again
+       ldx tmp0
        lda tmp1
        sta board,x
        inx
        cpx #81
        bne _cell
        jsr find_move
        bcc fill_board
        rts

; column of cell X -> A
col_of_x
        txa
-       cmp #9
        bcc +
        sbc #9
        bcs -
+       rts

; ---------------------------------------------------- matches
; mark[] |= 1 / 2 for horizontal / vertical runs of 3+, creations for 4, 5 and crossings
; C = 1 if anything matched
find_matches
        ldx #80
        lda #0
-       sta mark,x
        dex
        bpl -
        sta ncre
        sta tmp7                ; found
        ; ---- rows
        lda #0
        sta fm_line
_row    lda #0
        sta fm_pos
_hr     jsr fm_cell_h           ; x = cell
        lda board,x
        jsr colour_of
        sta fm_t
        lda #1
        sta fm_len
-       lda fm_pos
        clc
        adc fm_len
        cmp #9
        bcs +
        jsr fm_cell_hl          ; cell at fm_pos + fm_len
        lda board,x
        jsr colour_of
        cmp fm_t
        bne +
        inc fm_len
        bne -
+       lda fm_t
        cmp #$fe
        beq _hn
        lda fm_len
        cmp #3
        bcc _hn
        inc tmp7
        lda #1
        sta fm_bit
        lda #1
        sta fm_step
        jsr fm_mark_run
        ; 4: column blaster (vertical stripes), 5: rainbow
        lda fm_len
        cmp #4
        bcc _hn
        bne _h5
        lda fm_t
        ora #$10
        jmp +
_h5     lda #RAINBOW
+       jsr fm_create
_hn     lda fm_pos
        clc
        adc fm_len
        sta fm_pos
        cmp #9
        bcc _hr
        inc fm_line
        lda fm_line
        cmp #9
        bne _row
        ; ---- columns
        lda #0
        sta fm_line
_col    lda #0
        sta fm_pos
_vr     jsr fm_cell_v
        lda board,x
        jsr colour_of
        sta fm_t
        lda #1
        sta fm_len
-       lda fm_pos
        clc
        adc fm_len
        cmp #9
        bcs +
        jsr fm_cell_vl
        lda board,x
        jsr colour_of
        cmp fm_t
        bne +
        inc fm_len
        bne -
+       lda fm_t
        cmp #$fe
        beq _vn
        lda fm_len
        cmp #3
        bcc _vn
        inc tmp7
        lda #2
        sta fm_bit
        lda #9
        sta fm_step
        jsr fm_mark_run
        lda fm_len
        cmp #4
        bcc _vn
        bne _v5
        lda fm_t
        ora #$08                ; row blaster (horizontal stripes)
        jmp +
_v5     lda #RAINBOW
+       jsr fm_create
_vn     lda fm_pos
        clc
        adc fm_len
        sta fm_pos
        cmp #9
        bcc _vr
        inc fm_line
        lda fm_line
        cmp #9
        bne _col
        ; ---- crossings: bomb
        ldx #80
_x      lda mark,x
        cmp #3
        bne _nx
        stx tmp6
        jsr fm_has_cre
        bcs _nx2
        lda board,x
        and #7
        ora #$18
        ldy ncre
        cpy #16
        bcs _nx2
        sta cre_code,y
        txa
        sta cre_cell,y
        inc ncre
_nx2    ldx tmp6
_nx     dex
        bpl _x
        lda tmp7
        cmp #1
        rts

fm_line .byte 0
fm_pos  .byte 0
fm_len  .byte 0
fm_t    .byte 0
fm_bit  .byte 0
fm_step .byte 0
fm_first .byte 0

; cell of the run start in the row / column scan
fm_cell_h
        lda fm_line
        asl
        asl
        asl
        adc fm_line
        adc fm_pos
        tax
        rts
fm_cell_hl
        jsr fm_cell_h
        txa
        clc
        adc fm_len
        tax
        rts
fm_cell_v
        lda fm_pos
        asl
        asl
        asl
        adc fm_pos
        adc fm_line
        tax
        rts
fm_cell_vl
        lda fm_pos
        clc
        adc fm_len
        sta tmp5
        asl
        asl
        asl
        adc tmp5
        adc fm_line
        tax
        rts

; mark the run (start fm_pos, length fm_len, step fm_step, bit fm_bit); fm_first = pivot cell
fm_mark_run
        lda fm_step
        cmp #1
        bne +
        jsr fm_cell_h
        jmp ++
+       jsr fm_cell_v
+       stx fm_first
        lda fm_len
        sta tmp5
        lda #$ff
        sta tmp4                ; pivot: a swapped cell in the run
-       lda mark,x
        ora fm_bit
        sta mark,x
        cpx sa
        beq +
        cpx sb
        bne ++
+       stx tmp4
+       txa
        clc
        adc fm_step
        tax
        dec tmp5
        bne -
        lda tmp4
        cmp #$ff
        bne +
        lda fm_first
        clc
        adc fm_step             ; the second cell of the run
+       sta fm_first
        rts

; create sweet A at the pivot fm_first (unless there is a creation already)
fm_create
        ldx fm_first
        stx tmp6
        pha
        jsr fm_has_cre
        pla
        bcs _r
        ldy ncre
        cpy #16
        bcs _r
        sta cre_code,y
        lda tmp6
        sta cre_cell,y
        inc ncre
_r      rts

; is there a creation at cell tmp6? -> C
fm_has_cre
        ldy ncre
        beq _no
-       dey
        lda cre_cell,y
        cmp tmp6
        beq _yes
        tya
        bne -
_no     clc
        rts
_yes    sec
        rts

; ---------------------------------------------------- a match at cell X? (for move search) -> C
match_at
        stx ma_c
        lda board,x
        jsr colour_of
        cmp #$fe
        beq _no
        sta ma_t
        jsr col_of_x
        sta ma_col
        ; horizontal
        lda #1
        sta ma_n
        ldx ma_c
        ldy ma_col
-       dey
        bmi +
        dex
        lda board,x
        jsr colour_of
        cmp ma_t
        bne +
        inc ma_n
        bne -
+       ldx ma_c
        ldy ma_col
-       iny
        cpy #9
        bcs +
        inx
        lda board,x
        jsr colour_of
        cmp ma_t
        bne +
        inc ma_n
        bne -
+       lda ma_n
        cmp #3
        bcs _yes
        ; vertical
        lda #1
        sta ma_n
        lda ma_c
-       sec
        sbc #9
        bcc +
        tax
        lda board,x
        jsr colour_of
        cmp ma_t
        bne +
        inc ma_n
        txa
        jmp -
+       lda ma_c
-       clc
        adc #9
        cmp #81
        bcs +
        tax
        lda board,x
        jsr colour_of
        cmp ma_t
        bne +
        inc ma_n
        txa
        jmp -
+       lda ma_n
        cmp #3
        bcs _yes
_no     ldx ma_c
        clc
        rts
_yes    ldx ma_c
        sec
        rts
ma_c    .byte 0
ma_t    .byte 0
ma_n    .byte 0
ma_col  .byte 0

; ---------------------------------------------------- is there a possible move? -> C, hint_a / hint_b
; the search starts at a random cell
find_move
        jsr rnd
        and #63
        sta fv_start
        lda #0
        sta fv_n
_cell   lda fv_start
        clc
        adc fv_n
-       cmp #81
        bcc +
        sbc #81
        bcs -
+       sta fv_a
        tax
        lda board,x
        cmp #RAINBOW
        bne _right
        ; a rainbow sweet can be swapped with any neighbour
        stx hint_a
        jsr col_of_x
        cmp #8
        bcc +
        dex
        dex
+       inx
        stx hint_b
        sec
        rts
_right  ldx fv_a
        jsr col_of_x
        cmp #8
        bcs _down
        lda fv_a
        clc
        adc #1
        jsr fv_try
        bcs _found
_down   lda fv_a
        cmp #72
        bcs _next
        clc
        adc #9
        jsr fv_try
        bcs _found
_next   inc fv_n
        lda fv_n
        cmp #81
        bne _cell
        clc
        rts
_found  lda fv_a
        sta hint_a
        lda fv_b
        sta hint_b
        sec
        rts
fv_start .byte 0
fv_n    .byte 0
fv_a    .byte 0
fv_b    .byte 0

; try swapping fv_a with cell A -> C
fv_try
        sta fv_b
        ; two specials next to each other
        ldx fv_a
        lda board,x
        and #$18
        beq +
        ldx fv_b
        lda board,x
        and #$18
        beq +
        sec
        rts
+       jsr swap_ab
        ldx fv_a
        jsr match_at
        bcs +
        ldx fv_b
        jsr match_at
+       php
        jsr swap_ab
        plp
        rts
swap_ab
        ldx fv_a
        ldy fv_b
        lda board,x
        pha
        lda board,y
        sta board,x
        pla
        sta board,y
        rts

; ---------------------------------------------------- specials: expand the marked area
; repeats until no new special is activated; counts in ex_line / ex_bomb / ex_rb for effects
expand_specials
        lda #0
        sta ex_any
_pass   lda #0
        sta ex_new
        ldx #80
_c      lda mark,x
        beq _n
        and #$40
        bne _n
        lda board,x
        cmp #EMPTY
        beq _n
        cmp #RAINBOW
        beq _rb
        and #$18
        beq _n
        ; activate
        lda mark,x
        ora #$40
        sta mark,x
        inc ex_new
        stx tmp0
        jsr cell_rc
        ldx tmp0
        lda board,x
        and #$18
        cmp #$08
        beq _rowb
        cmp #$10
        beq _colb
        ; bomb: 3 x 3
        jsr ex_bomb
        jmp _nn
_rowb   jsr ex_row
        jmp _nn
_colb   jsr ex_col
        jmp _nn
_rb     lda mark,x
        ora #$40
        sta mark,x
        inc ex_new
        stx tmp0
        ; colour: the swap partner's or a random one
        lda rbtarget
        cmp #$ff
        bne +
        jsr random_colour
+       jsr ex_colour
        lda #$ff
        sta rbtarget
        lda #SFX_RAINBOW
        jsr sfx_start
_nn     ldx tmp0
_n      dex
        bpl _c
        lda ex_new
        beq +
        inc ex_any
        jmp _pass
+       rts
ex_new  .byte 0
ex_any  .byte 0
rbtarget .byte $ff

ex_row  lda tmp1
        asl
        asl
        asl
        adc tmp1
        tax
        ldy #9
-       jsr ex_mark
        inx
        dey
        bne -
        lda #SFX_LINE
        jmp sfx_start
ex_col  ldx tmp2
        ldy #9
-       jsr ex_mark
        txa
        clc
        adc #9
        tax
        dey
        bne -
        lda #SFX_LINE
        jmp sfx_start
ex_bomb lda #SFX_BOMB
        jsr sfx_start
        lda tmp1
        sec
        sbc #1
        sta tmp3                ; row
        lda #3
        sta tmp4
_br     lda tmp3
        cmp #9
        bcs _bn                 ; outside (also -1)
        lda tmp2
        sec
        sbc #1
        sta tmp5
        lda #3
        sta tmp6
_bc     lda tmp5
        cmp #9
        bcs +
        lda tmp3
        asl
        asl
        asl
        adc tmp3
        adc tmp5
        tax
        jsr ex_mark
+       inc tmp5
        dec tmp6
        bne _bc
_bn     inc tmp3
        dec tmp4
        bne _br
        rts
ex_mark lda mark,x
        ora #4
        sta mark,x
        rts
; mark all sweets of colour A
ex_colour
        sta tmp3
        ldx #80
-       lda board,x
        jsr colour_of
        cmp tmp3
        bne +
        jsr ex_mark
+       dex
        bpl -
        rts
; colour of a random sweet on the board -> A
random_colour
-       jsr rnd
        and #127
        cmp #81
        bcs -
        tax
        lda board,x
        jsr colour_of
        cmp #6
        bcs -
        rts

; ---------------------------------------------------- remove marked sweets, place creations,
; build the falling display lists and the new board
gravity_setup
        ; creations into newcode
        ldx #80
        lda #EMPTY
-       sta newcode,x
        dex
        bpl -
        ldy ncre
        beq +
-       dey
        ldx cre_cell,y
        lda cre_code,y
        sta newcode,x
        tya
        bne -
+       lda #0
        sta gv_c
_col    ; survivors from the bottom
        lda #8
        sta gv_k                ; next target row
        lda #8
        sta gv_r
_sr     lda gv_r
        asl
        asl
        asl
        adc gv_r
        adc gv_c
        tax
        lda mark,x
        beq _keep
        ldy gv_c
        lda #1
        sta colmov,y
        lda newcode,x
        cmp #EMPTY
        beq _gone
        bne _put
_keep   lda board,x
_put    pha
        ; display slot column*9 + k
        lda gv_c
        asl
        asl
        asl
        adc gv_c
        adc gv_k
        tay
        pla
        sta dcode,y
        sta gv_code
        lda gv_r
        asl
        asl
        asl
        asl
        sta dyl,y
        lda #0
        sta dyh,y
        ; new board cell (k, c)
        lda gv_k
        asl
        asl
        asl
        adc gv_k
        adc gv_c
        tax
        lda gv_code
        sta nboard,x
        lda gv_r
        cmp gv_k
        beq +
        lda #1
        ldx gv_c
        sta colmov,x
+       dec gv_k
_gone   dec gv_r
        bpl _sr
        ; new sweets for rows gv_k .. 0, entering from above
        lda gv_k
        bmi _done
        ldx gv_c
        lda #1
        sta colmov,x
        lda gv_k
        clc
        adc #1
        sta gv_m                ; number of new sweets
-       lda ncol
        jsr rndmod
        sta gv_code
        lda gv_c
        asl
        asl
        asl
        adc gv_c
        adc gv_k
        tay
        lda gv_code
        sta dcode,y
        ; y = (k - m) * 16
        lda gv_k
        sec
        sbc gv_m
        asl
        asl
        asl
        asl
        sta dyl,y
        lda #$ff
        sta dyh,y
        lda gv_k
        asl
        asl
        asl
        adc gv_k
        adc gv_c
        tax
        lda gv_code
        sta nboard,x
        dec gv_k
        bpl -
_done   inc gv_c
        lda gv_c
        cmp #9
        beq +
        jmp _col
+       ; the new board
        ldx #80
-       lda nboard,x
        sta board,x
        dex
        bpl -
        rts
gv_c    .byte 0
gv_r    .byte 0
gv_k    .byte 0
gv_m    .byte 0
gv_code .byte 0
nboard  .fill 81
stepcol .fill 9

; ---------------------------------------------------- animate falling columns
animate_fall
        lda #2
        sta fallv
_step   lda #0
        sta anyfall
        ldx #0
_c      stx tmp0
        lda colmov,x
        beq _nc
        lda #0
        sta tmp1                ; moved in this column
        ; slots c*9 .. c*9+8
        txa
        asl
        asl
        asl
        adc tmp0
        tax
        ldy #0
_k      ; target = k * 16
        tya
        asl
        asl
        asl
        asl
        sta tmp2
        lda dyh,x
        bmi _mv
        lda dyl,x
        cmp tmp2
        bcs _at
_mv     lda dyl,x
        clc
        adc fallv
        sta dyl,x
        lda dyh,x
        adc #0
        sta dyh,x
        bmi +
        lda dyl,x
        cmp tmp2
        bcc +
_at     lda tmp2
        sta dyl,x
        lda #0
        sta dyh,x
        jmp _nk
+       inc tmp1
_nk     inx
        iny
        cpy #9
        bne _k
        ldx tmp0
        lda #1
        sta stepcol,x
        jsr compose_column
        ldx tmp0
        lda tmp1
        bne +
        lda #0
        sta colmov,x            ; landed
        jmp _nc
+       inc anyfall
_nc     ldx tmp0
        inx
        cpx #9
        bne _c
        ; all composed: copy them right after the frame start
        jsr wait_keys
        ldx #0
-       lda stepcol,x
        beq +
        lda #0
        sta stepcol,x
        txa
        pha
        jsr copy_column
        pla
        tax
+       inx
        cpx #9
        bne -
        lda fallv
        cmp #8
        bcs +
        inc fallv
+       lda anyfall
        bne _step
        lda #SFX_SWAP
        jmp sfx_start

; ---------------------------------------------------- shuffle (no moves left)
shuffle
        lda #20
        sta sh_try
_try    ; Fisher-Yates over all cells
        ldx #80
-       stx tmp0
        txa
        clc
        adc #1
        jsr rndmod
        tay
        ldx tmp0
        lda board,x
        pha
        lda board,y
        sta board,x
        pla
        sta board,y
        dex
        bne -
        lda #$ff
        sta sa
        sta sb
        jsr find_matches
        bcs _bad
        jsr find_move
        bcs _ok
_bad    dec sh_try
        bne _try
        jsr fill_board
_ok     rts
sh_try  .byte 0
