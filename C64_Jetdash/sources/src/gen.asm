; =====================================================================
;  Level generator: one world column at a time
;  background tile (8 columns wide, random per zone), patterns of coins
;  and zappers, laser sequences, workers and gadget boxes
; =====================================================================

; ---------------------------------------------------- column for the hidden screen
gen_column_hidden
        lda #38
        sta gen_x
        lda disp
        eor #1
        jmp gen_column

; ---------------------------------------------------- generate world column gc into screen A (A=0) / B (A=1), column gen_x
gen_column
        sta gen_buf
        ; ---- background tile
        lda gcl
        and #7
        bne _tile
        lda gzone
        cmp #5
        bcs _pick
        ; zone boundary: (gzone + 1) * 500 columns
        tax
        lda zcol_lo+1,x
        sta tmp0
        lda zcol_hi+1,x
        sta tmp1
        lda gcl
        cmp tmp0
        lda gch
        sbc tmp1
        bcc _pick
        inc gzone
        lda gzone
        cmp #5
        bne +
        sta gnopat              ; outside: no more patterns, lasers or missiles
        lda #0
        sta gplen
        sta lwait
+       lda gcl
        sta gatel
        lda gch
        sta gateh
        lda #T_GATE
        bne _set
_pick   jsr rnd
        and #7
        sta tmp0
        lda gzone
        asl
        asl
        asl
        ora tmp0
        tax
        lda zone_tiles,x
_set    sta gtile
_tile   lda gcl
        and #63
        tax
        lda gtile
        sta ctile,x
        tay
        lda tile_lo,y
        sta ptr2
        lda tile_hi,y
        sta ptr2+1
        lda gcl
        and #7
        tay
        lda tcol_off,y
        clc
        adc ptr2
        sta ptr2
        bcc +
        inc ptr2+1
+       ldy #22
-       lda (ptr2),y
        sta colbuf,y
        dey
        bpl -
        ; ---- patterns and events
        jsr gen_events
        ; ---- write the column
        ldx #2
        ldy gen_x
-       lda rowlo,x
        sta ptr2
        lda gen_buf
        bne +
        lda rowhiA,x
        bne ++
+       lda rowhiB,x
+       sta ptr2+1
        lda colbuf-2,x
        sta (ptr2),y
        inx
        cpx #25
        bne -
        ; ---- next column
        inc gcl
        bne +
        inc gch
+       rts

gen_x   .byte 0
gen_buf .byte 0
zcol_lo .byte <(ZONECOLS*0), <(ZONECOLS*1), <(ZONECOLS*2), <(ZONECOLS*3), <(ZONECOLS*4), <(ZONECOLS*5), $ff
zcol_hi .byte >(ZONECOLS*0), >(ZONECOLS*1), >(ZONECOLS*2), >(ZONECOLS*3), >(ZONECOLS*4), >(ZONECOLS*5), $ff

; ---------------------------------------------------- patterns, lasers, spawns
gen_events
        lda gplen
        beq _nopat
        ; ---- next column of the current pattern
        ldy #0
        lda (gptr),y
        sta tmp4                ; entries
        iny
        tax
        beq _pend
-       lda (gptr),y            ; row offset
        iny
        clc
        adc gprow
        sec
        sbc #2
        tax
        lda (gptr),y
        iny
        sta colbuf,x
        dec tmp4
        bne -
_pend   tya
        clc
        adc gptr
        sta gptr
        bcc +
        inc gptr+1
+       dec gplen
        bne _spawn
        ; gap until the next pattern
        ldx lvl
        lda d_gapmax,x
        sec
        sbc d_gapmin,x
        clc
        adc #1
        jsr rndmod
        ldx lvl
        clc
        adc d_gapmin,x
        sta gap
        jmp _spawn
_nopat  lda lwait
        beq +
        dec lwait
        bne _r
        jmp laser_start
+       lda lactive
        bne _r
        lda ldone
        beq +
        dec ldone
        rts
+       lda gap
        beq _new
        dec gap
        jmp _spawn
_new    lda gnopat
        bne _r
        ; ---- a laser sequence?
        jsr rnd
        ldx lvl
        cmp d_plaser,x
        bcs _pat
        lda #48
        sta lwait
        rts
_pat    ; ---- choose a pool
        ldy #0                  ; coins
        jsr rnd
        ldx lvl
        cmp d_pcoin,x
        bcc _pool
        iny                     ; easy
        jsr rnd
        ldx lvl
        cmp d_peasy,x
        bcc _pool
        iny                     ; medium
        cmp d_pmed,x
        bcc _pool
        iny                     ; hard
_pool   sty tmp5
        lda pool_n,y
        jsr rndmod
        ldy tmp5
        clc
        adc pool_start,y
        tax
        lda pat_lo,x
        sta gptr
        lda pat_hi,x
        sta gptr+1
        ldy #0
        lda (gptr),y
        sta gplen
        iny
        lda #21
        sec
        sbc (gptr),y            ; 21 - height
        jsr rndmod
        clc
        adc #3
        sta gprow
        lda gptr
        clc
        adc #2
        sta gptr
        bcc _spawn
        inc gptr+1
_spawn  ; ---- workers and boxes
        lda gnopat
        ora lwait
        ora lactive
        ora ldone
        bne _r
        jsr rnd
        ldx lvl
        cmp d_pwork,x
        bcs +
        jsr worker_spawn
+       lda boxcnt
        bne +
        dec boxcnt+1
+       dec boxcnt
        lda boxcnt
        ora boxcnt+1
        bne _r
        jsr rnd
        and #127
        clc
        adc #140
        sta boxcnt
        lda #0
        sta boxcnt+1
        jmp box_spawn
_r      rts

; ---------------------------------------------------- random number 0..A-1
rndmod
        sta tmp6
        jsr rnd
        ; (rnd * tmp6) >> 8
        sta tmp7
        lda #0
        ldx #8
-       lsr tmp7
        bcc +
        clc
        adc tmp6
+       ror
        dex
        bne -
        rts
