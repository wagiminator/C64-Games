; =====================================================================
;  Virtual sprites (candidates), sorting and multiplexer preparation
; =====================================================================
;  Every object has a fixed candidate ID (0 ship, 1 orb, 2..9 shots,
;  10..19 enemies, 20..27 enemy bullets, 28..36 boss), so the Y order of
;  the last frame is kept in sord and an insertion sort only has to fix
;  what moved. The candidates are double buffered (cbase = 0 / NV): the
;  IRQ shows one buffer while the main loop builds the other one.

init_vsprites
        lda #0
        sta mux_base
        sta mux_end
        sta mux_idx
        sta nx_count
        ; sort order: IDs in a row + end mark (ID NC is never shown)
        ldx #NC
-       txa
        sta sord,x
        dex
        bpl -
        lda #$ff
        sta cy+NC
        sta cy+NV+NC
        ; queue entries 0..7 of both buffers: hardware sprites 0..7, free at once
        ldx #7
-       txa
        sta outslot,x
        sta outslot+NV,x
        lda #0
        sta outfree,x
        sta outfree+NV,x
        dex
        bpl -
        rts

build_sprites
        lda mux_base            ; build into the buffer the IRQ does not show
        beq +
        lda #0
        beq ++
+       lda #NV
+       sta cbase
        sta nx_base
        tax
        clc                     ; point the Y lookups of sort and allocation
        adc #<cy                ; at this buffer
        sta s_cy0+1
        sta s_cy1+1
        sta s_cy2+1
        sta a_cy+1
        sta f_cy+1
        ; ---- ID 0: player
        lda pstate
        bne _pdie
        lda pinv
        beq +
        lda frame
        and #4
        bne _pnone
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
        inx
        jmp _porb
_pdie   cmp #1
        bne _pnone
        lda ptimer
        lsr
        lsr
        lsr
        cmp #6
        bcs _pnone
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
        jmp _porb
_pnone  lda #$ff
        sta cy,x
        inx
_porb   ; ---- ID 1: orb
        lda orbon
        beq _onone
        lda pstate
        bne _onone
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
        jmp _pb
_onone  lda #$ff
        sta cy,x
        inx
_pb     ; ---- IDs 2..9: player bullets
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
        dey
        bpl _pl
        bmi _ens
_pn     lda #$ff
        sta cy,x
        inx
        dey
        bpl _pl
_ens    ; ---- IDs 10..19: enemies
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
        dey
        bpl _el
        bmi _ebs
_en     lda #$ff
        sta cy,x
        inx
        dey
        bpl _el
_ebs    ; ---- IDs 20..27: enemy bullets
        lda frame
        lsr
        lsr
        and #1
        clc
        adc #SPR_EBULLET
        sta tmp0
        ldy #N_EB-1
_bl     lda eb_on,y
        beq _bn
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
        dey
        bpl _bl
        bmi _bos
_bn     lda #$ff
        sta cy,x
        inx
        dey
        bpl _bl
_bos    ; ---- IDs 28..36: boss (X = cbase + ID_BOSS)
        jsr boss_sprites

; ---- insertion sort of the IDs by Y: the order of the last frame is almost right
sort_sprites
        ldy sord
s_cy0 = *
        lda cy,y                ; (operand patched to this buffer)
        sta tmp2                ; largest Y so far
        ldx #1
_sl     ldy sord,x
s_cy1 = *
        lda cy,y
        cmp tmp2
        bcc _ins
        sta tmp2
        inx
        cpx #NC
        bne _sl
        beq alloc_sprites
_ins    sta tmp3                ; move it down past all larger ones
        sty tmp4
        stx tmp5
-       lda sord-1,x
        sta sord,x
        dex
        beq +
        ldy sord-1,x
s_cy2 = *
        lda cy,y
        cmp tmp3
        beq +
        bcs -
+       lda tmp4
        sta sord,x
        ldx tmp5
        inx
        cpx #NC
        bne _sl

; ---- allocate the hardware sprites in Y order. They wait in a queue in the order
;      they get free; entry i takes the head (queue position i) and puts its
;      hardware sprite back at position i+8, so the write lines grow along the
;      list. Boss parts and the ship take over the hardware sprite of a sprite
;      without priority when none is free in time.
alloc_sprites
        ldx cbase               ; X = output entry = queue head
        lda #0
        sta si
        sta mtw
_al     ldy si
        lda sord,y
        sta tmp4
        tay                     ; Y = ID
a_cy = *
        lda cy,y
        cmp #SPLIT-4
        bcs _done               ; (the rest is lower or not shown)
        sbc #MUXGAP-1           ; (C = 0) latest write line that is early enough
        ldy outfree,x
        beq _take               ; hardware sprite free from the top: split IRQ
        sta tmp3
        cmp mtw
        bcc _full               ; the IRQ chain is still busy with earlier writes
        cpy tmp3
        beq +
        bcs _full               ; the hardware sprite is not free in time
+       tya                     ; the chain writes at max(free line, mtw)
        cmp mtw
        bcs +
        lda mtw
+       clc
        adc #MUXW
        sta mtw
        lda tmp3
        sec
_take   adc #21+MUXGAP          ; (C = 1) free after its 21 lines
        sta outfree+8,x
        lda tmp4
        clc
        adc cbase
        sta outcand,x
        lda outslot,x
        sta outslot+8,x
        txa
        sta outlast+8,x
        inx
_nx     inc si
        bne _al
_done   txa
        sec
        sbc cbase
        sta nx_count
        rts
        ; ---- no hardware sprite free in time
_full   lda tmp4
        beq +                   ; the ship
        cmp #ID_BOSS
        bcc _nx                 ; other sprites are dropped
+       ldy tmp4
        stx tmp2                ; queue head
f_cy = *
        lda cy,y
        sta tmp3                ; Y of the new sprite
        lda #8
        sta tmp5
_fs     ldy outlast,x           ; last entry of the hardware sprite at queue pos X
        lda outcand,y
        sec
        sbc cbase
        beq _fsn                ; the ship
        cmp #ID_BOSS
        bcc _evict
_fsn    inx
        dec tmp5
        bne _fs
        ldx tmp2                ; all have priority: dropped
        jmp _nx
_evict  ; entry Y shows the new sprite instead (same write line, same sprite)
        lda tmp4
        clc
        adc cbase
        sta outcand,y
        sty tmp6
        lda outslot,x
        sta tmp0
        ; this hardware sprite now gets free last: to the end of the queue
        lda tmp2
        clc
        adc #7
        sta tmp1
-       cpx tmp1
        beq +
        lda outslot+1,x
        sta outslot,x
        lda outfree+1,x
        sta outfree,x
        lda outlast+1,x
        sta outlast,x
        inx
        bne -
+       lda tmp0
        sta outslot,x
        lda tmp3
        clc
        adc #22
        sta outfree,x
        lda tmp6
        sta outlast,x
        ldx tmp2
        jmp _nx
