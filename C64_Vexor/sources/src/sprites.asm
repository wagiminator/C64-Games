; =====================================================================
;  Virtual sprite list, sorting and multiplexer preparation
; =====================================================================

init_vsprites
        lda #0
        sta mux_base
        sta mux_end
        sta mux_idx
        sta nx_count
        rts

; append sprite: A = y, uses sp_xl/sp_xh/sp_p/sp_c staged in ZP vars
build_sprites
        ldx #0
        ; ---- player
        lda pstate
        bne _pdie
        lda pinv
        beq +
        lda frame
        and #2
        bne _pb
+       lda py
        sta cy,x
        lda px_l
        sta cxl,x
        lda px_h
        sta cxh,x
        lda pframe
        bne +
        lda frame
        and #2
        lsr
+       clc
        adc #SPR_SHIP
        sta cp,x
        lda #14
        ldy hitflash
        beq +
        dec hitflash
        lda #2
+       ldy novatime
        beq +
        lda frame
        and #7
        tay
        lda novacols,y
+       sta cc,x
        inx
        jmp _pb
_pdie   cmp #1
        bne _pb
        lda ptimer
        lsr
        lsr
        lsr
        cmp #6
        bcs _pb
        adc #SPR_EXPLODE
        sta cp,x
        lda py
        sta cy,x
        lda px_l
        sta cxl,x
        lda px_h
        sta cxh,x
        lda #7
        sta cc,x
        inx
_pb     ; ---- player bullets
        ldy #N_PB-1
_pl     lda pb_t,y
        beq _pn
        lda pb_xh,y
        beq +
        lda pb_xl,y
        cmp #88
        bcs _pn
        lda #1
+       sta cxh,x
        lda pb_xl,y
        sta cxl,x
        lda pb_y,y
        sta cy,x
        lda pb_spr,y
        sta cp,x
        lda pb_col,y
        sta cc,x
        inx
_pn     dey
        bpl _pl
        ; ---- enemies
        ldy #N_EN-1
_el     lda en_t,y
        beq _en
        lda en_xh,y
        bmi _en
        beq +
        lda en_xl,y
        cmp #88
        bcs _en
        lda #1
+       sta cxh,x
        lda en_xl,y
        sta cxl,x
        lda en_y,y
        sta cy,x
        lda en_spr,y
        sta cp,x
        lda en_fl,y
        beq _nf
        lda #0
        sta en_fl,y             ; (flash lasts 1 frame per hit)
        lda #1
        bne _cf
_nf     lda en_col,y
_cf     sta cc,x
        inx
_en     dey
        bpl _el
        ; ---- enemy bullets
        lda frame
        lsr
        lsr
        and #1
        clc
        adc #SPR_EBULLET
        sta tmp0
        ldy #N_EB-1
-       lda eb_on,y
        beq +
        lda eb_xl,y
        sta cxl,x
        lda eb_xh,y
        sta cxh,x
        lda eb_y,y
        sta cy,x
        lda tmp0
        sta cp,x
        lda #10
        sta cc,x
        inx
+       dey
        bpl -
        ; ---- boss
        stx nactive
        jsr boss_sprites
        jmp sort_sprites

; bucket lists (16 buckets of 16 lines), each kept sorted on insert; then accept
sort_sprites
        ldx #15
        lda #$ff
-       sta bhead,x
        dex
        bpl -
        ldx nactive
        dex
        bpl _si
        jmp _empty
_si     lda cy,x
        sta tmp2
        lsr
        lsr
        lsr
        lsr
        sta tmp3
        tay
        lda bhead,y
        bmi _front
        tay
        lda cy,y
        cmp tmp2
        bcs _front
_walk   sty tmp4
        lda bnext,y
        bmi _after
        tay
        lda cy,y
        cmp tmp2
        bcc _walk
_after  ldy tmp4
        lda bnext,y
        sta bnext,x
        txa
        sta bnext,y
        dex
        bpl _si
        bmi _sorted
_front  ldy tmp3
        lda bhead,y
        sta bnext,x
        txa
        sta bhead,y
        dex
        bpl _si
_sorted
        ; ---- accept into out buffer (traverse buckets)
        lda mux_base
        beq +
        lda #0
        beq ++
+       lda #40
+       sta nx_base
        sta tmp7
        tax
        lda #0
        sta tmp6                ; bucket
_tb     ldy tmp6
        lda bhead,y
_ti     bmi _nb
        sta tmp4                ; current item
        tay
        lda cy,y
        cmp #SPLITC-4
        bcs _adone
        sta tmp5
        txa
        sec
        sbc tmp7
        cmp #8
        bcc _ok
        lda outy-8,x
        adc #21
        cmp #SPLITC-3
        bcs _skip
        adc #1
        cmp tmp5
        beq _ok
        bcs _skip
_ok     lda tmp5
        sta outy,x
        lda cxl,y
        sta outxl,x
        lda cxh,y
        sta outxh,x
        lda cp,y
        sta outp,x
        lda cc,y
        sta outc,x
        inx
_skip   ldy tmp4
        lda bnext,y
        jmp _ti
_nb     inc tmp6
        lda tmp6
        cmp #16
        bne _tb
_adone  txa
        sec
        sbc tmp7
        sta nx_count
        rts
_empty  lda mux_base
        beq +
        lda #0
        beq ++
+       lda #40
+       sta nx_base
        lda #0
        sta nx_count
        rts

novacols .byte 7,8,2,10,1,10,2,8
