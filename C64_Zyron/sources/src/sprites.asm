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
        lda #0
        sta shipin
        ldx #0
        ; ---- player
        lda pstate
        bne _pdie
        lda pinv
        beq +
        lda frame
        and #4
        bne _porb
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
        beq +
        lda #3
+       clc
        adc #SPR_SHIP
        sta cp,x
        lda #14
        sta cc,x
        inc shipin              ; the ship (index 0) is never dropped
        inx
        jmp _porb
_pdie   cmp #1
        bne _porb
        lda ptimer
        lsr
        lsr
        lsr
        cmp #6
        bcs _porb
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
_porb   ; ---- orb
        lda orbon
        beq _pb
        lda pstate
        bne _pb
        lda oy
        sta cy,x
        lda ox_l
        sta cxl,x
        lda ox_h
        sta cxh,x
        lda frame
        lsr
        lsr
        and #3
        adc #SPR_ORB
        sta cp,x
        lda #10
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
        stx bstart              ; boss parts are never dropped
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
        jmp alloc_sprites
_empty  lda mux_base
        beq +
        lda #0
        beq ++
+       lda #40
+       sta nx_base
        lda #0
        sta nx_count
        rts

; ---- allocate the hardware sprites in Y order. They wait in a ring in the order
;      of their last use, so the head is always the one that gets free first and
;      the write lines of the list grow with the list. Boss parts and the ship
;      take over the hardware sprite of another sprite when none is free.
alloc_sprites
        ldx #7
-       txa
        sta sl_ring,x
        lda #0
        sta sl_free,x
        dex
        bpl -
        lda #0
        sta sl_head
        lda mux_base            ; output into the buffer that is not shown
        beq +
        lda #0
        beq ++
+       lda #40
+       sta nx_base
        sta tmp7
        tax                     ; X = output index
        lda #0
        sta tmp6                ; bucket
_tb     ldy tmp6
        lda bhead,y
_ti     bpl +
        jmp _nb
+       sta tmp4                ; candidate
        tay
        lda cy,y
        cmp #SPLIT-4
        bcc +
        jmp _done
+       sec
        sbc #MUXGAP
        bcs +
        lda #0
+       sta tmp3                ; latest free line that is early enough
        ldy sl_head
        lda sl_ring,y
        tay                     ; Y = hardware sprite at the head
        lda sl_free,y
        cmp tmp3
        beq +
        bcs _full
+       sta outfree,x
        lda sl_head
        clc
        adc #1
        and #7
        sta sl_head
_put    ; Y = hardware sprite, X = output entry
        tya
        sta outslot,x
        txa
        sta sl_last,y
        sty tmp5
        ldy tmp4
        lda cy,y
        sta outy,x
        clc
        adc #22                 ; free after its 21 lines
        ldy tmp5
        sta sl_free,y
        ldy tmp4
        jsr prio
        sta outpri,x
        lda cxl,y
        sta outxl,x
        lda cxh,y
        sta outxh,x
        lda cp,y
        sta outp,x
        lda cc,y
        sta outc,x
        inx
_next   ldy tmp4
        lda bnext,y
        jmp _ti
_nb     inc tmp6
        lda tmp6
        cmp #16
        beq _done
        jmp _tb
_done   txa
        sec
        sbc tmp7
        sta nx_count
        rts
        ; ---- no hardware sprite free: priority sprites replace the last
        ;      sprite of a hardware sprite that has no priority
_full   ldy tmp4
        jsr prio
        beq _next               ; dropped
        stx tmp2
        lda #8
        sta tmp5
        ldx sl_head             ; search from the oldest
_fs     lda sl_ring,x
        tay
        stx tmp1                ; ring position
        ldx sl_last,y
        lda outpri,x
        bne _fsn
        ; the replaced entry keeps its write line and hardware sprite
        txa
        ldx tmp2
        tax
        jsr _move               ; ring position tmp1 -> back
        ldy outslot,x
        jsr _put2
        ldx tmp2
        jmp _next
_fsn    ldx tmp1
        inx
        txa
        and #7
        tax
        dec tmp5
        bne _fs
        ldx tmp2
        jmp _next
; overwrite entry X with candidate tmp4 (hardware sprite Y)
_put2   tya
        sta tmp5
        ldy tmp4
        lda cy,y
        sta outy,x
        clc
        adc #22
        ldy tmp5
        sta sl_free,y
        ldy tmp4
        jsr prio
        sta outpri,x
        lda cxl,y
        sta outxl,x
        lda cxh,y
        sta outxh,x
        lda cp,y
        sta outp,x
        lda cc,y
        sta outc,x
        rts
; move the hardware sprite at ring position tmp1 to the back (just before the head)
_move   txa
        pha
        ldx tmp1
        lda sl_ring,x
        sta tmp5
-       txa
        clc
        adc #1
        and #7
        cmp sl_head
        beq +
        tay
        lda sl_ring,y
        sta sl_ring,x
        tya
        tax
        jmp -
+       lda tmp5
        sta sl_ring,x
        pla
        tax
        rts

; A = 1 (Z clear) when candidate Y must not be dropped: boss parts and the ship
prio    cpy bstart
        bcs _p1
        cpy #0
        bne _p0
        lda shipin
        rts
_p1     lda #1
        rts
_p0     lda #0
        rts
