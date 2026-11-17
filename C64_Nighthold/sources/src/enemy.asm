; =====================================================================
;  Creatures, occupancy grid, gems, bosses
;  Creatures live on a grid of world cells. A 64 x 64 occupancy table
;  (world cell modulo 64) holds the creature index + 1 of every cell.
; =====================================================================

; type tables: bat, zombie, skeleton, ghost, ghoul, wraith
et_hp   .byte 2, 6, 9, 7, 18, 28
et_spd  .byte 2, 4, 3, 2, 3, 2          ; updates per step
et_dmg  .byte 1, 3, 4, 4, 6, 8
et_gem  .byte 1, 1, 2, 2, 2, 3
; waves per minute: 4 types, maximum count, spawn interval
wv_types .byte 0,0,0,0, 0,1,0,1, 1,2,1,2, 0,2,2,0, 2,3,3,2, 3,4,3,4, 4,1,4,1, 4,5,4,5, 0,3,5,5, 1,2,4,5
wv_max  .byte 16, 24, 32, 40, 46, 52, 58, 64, 68, 72
wv_int  .byte 20, 14, 12, 10, 8, 7, 6, 5, 4, 3

; ---------------------------------------------------- grid cell of (tmp0 x, tmp2 y) -> gptr, Y = 0
grid_at
        ldx tmp2
        lda tmp2
        and #63
        tax
        lda tmp0
        and #63
        ora grid_lo,x
        sta gptr
        lda grid_hi,x
        sta gptr+1
        ldy #0
        rts

clear_grid
        lda #<GRID
        sta ptr0
        lda #>GRID
        sta ptr0+1
        ldx #16
        lda #0
        tay
-       sta (ptr0),y
        iny
        bne -
        inc ptr0+1
        dex
        bne -
        rts

; ---------------------------------------------------- spawn creatures at the edge of the screen
spawn_update
        lda dead
        bne _r
        dec spawnt
        bne _r
        ldx mins
        cpx #ENDMIN
        bcs _r
        lda wv_int,x
        sta spawnt
        lda ecount
        cmp wv_max,x
        bcs _r
        jsr spawn_one
_r      rts

spawn_one
        ; free slot
        ldx #NE-1
-       lda e_t,x
        beq +
        dex
        bpl -
        rts
+       stx sp_slot
        ; position: one of the four sides
        jsr rnd
        and #3
        sta sp_side
        lda sp_side
        cmp #2
        bcs _lr
        ; top / bottom: x = pcx - 21 + rnd(42), y = pcy -/+ 14
        lda #42
        jsr rndmod
        sec
        sbc #21
        jsr _addx
        lda #14
        ldx sp_side
        beq +
        lda #<(-14)
+       jsr _addy
        jmp _place
_lr     lda #30
        jsr rndmod
        sec
        sbc #15
        jsr _addy
        lda #22
        ldx sp_side
        cpx #2
        beq +
        lda #<(-22)
+       jsr _addx
_place  jsr grid_at
        lda (gptr),y
        bne _r2
        ; type of this minute
        jsr rnd
        and #3
        sta tmp7
        lda mins
        asl
        asl
        ora tmp7
        tax
        lda wv_types,x
        tax
        ldy sp_slot
        clc
        adc #1
        sta e_t,y
        lda et_hp,x
        sta tmp7
        lda mins
        lsr
        clc
        adc tmp7
        sta e_hp,y
        lda et_spd,x
        sta e_tm,y
        lda #0
        sta e_fl,y
        sta e_hc,y
        lda tmp0
        sta e_xl,y
        lda tmp1
        sta e_xh,y
        lda tmp2
        sta e_yl,y
        lda tmp3
        sta e_yh,y
        tya
        clc
        adc #1
        ldy #0
        sta (gptr),y
_r2     rts
sp_slot .byte 0
sp_side .byte 0
; tmp0/1 = pcx + A (signed), tmp2/3 = pcy + A (signed)
_addx   sta tmp0
        lda #0
        bit tmp0
        bpl +
        lda #$ff
+       sta tmp1
        lda pcxl
        clc
        adc tmp0
        sta tmp0
        lda pcxh
        adc tmp1
        sta tmp1
        rts
_addy   sta tmp2
        lda #0
        bit tmp2
        bpl +
        lda #$ff
+       sta tmp3
        lda pcyl
        clc
        adc tmp2
        sta tmp2
        lda pcyh
        adc tmp3
        sta tmp3
        rts

; ---------------------------------------------------- move creatures, contact with the hero
enemies_update
        lda #0
        sta ecount
        ldx #NE-1
_e      stx tmp6
        lda e_t,x
        bne +
        jmp _n
+       inc ecount
        lda e_hc,x
        beq +
        dec e_hc,x
+       ; only on the creature's own beat
        dec e_tm,x
        beq +
        jmp _n
+       lda e_t,x
        tay
        lda et_spd-1,y
        sta e_tm,x
        ; dx = pcx - ex
        lda pcxl
        sec
        sbc e_xl,x
        sta tmp4
        lda pcxh
        sbc e_xh,x
        jsr small16             ; -> C = 0 if |d| < 128, A = d
        bcs _far
        sta tmp4
        cmp #29
        bcc +
        cmp #<(-28)
        bcc _far
+       lda pcyl
        sec
        sbc e_yl,x
        sta tmp5
        lda pcyh
        sbc e_yh,x
        jsr small16_y
        bcs _far
        sta tmp5
        cmp #20
        bcc +
        cmp #<(-19)
        bcc _far
+       ; contact?
        lda tmp4
        clc
        adc #1
        cmp #3
        bcs _move
        lda tmp5
        clc
        adc #1
        cmp #3
        bcs _move
        jsr hurt_hero
        jmp _n
_far    jsr remove_enemy
        jmp _n
_move   ; step towards the hero: diagonal, then x, then y
        lda tmp4
        jsr sign
        sta tmp4
        lda tmp5
        jsr sign
        sta tmp5
        lda tmp4
        ldy tmp5
        jsr try_step
        bcc _n
        ; blocked: x or y first (alternating), then around the obstacle
        lda tmp4
        beq _yonly
        lda tmp5
        beq _xonly
        lda frame
        eor tmp6
        and #1
        beq _yonly
_xonly  lda tmp4
        ldy #0
        jsr try_step
        bcc _n
        jmp _side
_yonly  lda #0
        ldy tmp5
        jsr try_step
        bcc _n
_side   ; sidestep: perpendicular to the main direction (sometimes)
        lda frame
        eor tmp6
        and #3
        bne _stuck
        lda tmp5
        bne +
        lda tmp4
        ldy #1
        jsr try_step
        bcc _n
        lda tmp4
        ldy #$ff
        jsr try_step
        bcc _n
        bcs _stuck
+       lda #1
        ldy tmp5
        jsr try_step
        bcc _n
        lda #$ff
        ldy tmp5
        jsr try_step
        bcc _n
_stuck  ldx tmp6
        lda e_tm,x              ; blocked: try again a little later
        clc
        adc #4
        sta e_tm,x
_n      ldx tmp6
        dex
        bmi +
        jmp _e
+       rts

; A/hi in A, lo in tmp4 -> C = 0 and A = lo if the 16 bit value is in -128..127
small16
        cmp #0
        bne +
        lda tmp4
        bmi _bad
        clc
        rts
+       cmp #$ff
        bne _bad
        lda tmp4
        bpl _bad
        clc
        rts
_bad    sec
        rts
small16_y
        cmp #0
        bne +
        lda tmp5
        bmi _bad
        clc
        rts
+       cmp #$ff
        bne _bad
        lda tmp5
        bpl _bad
        clc
        rts
_bad    sec
        rts
sign    beq +
        bmi _m
        lda #1
        rts
_m      lda #$ff
+       rts

; creature tmp6 steps by (A, Y) if the cell is free -> C = 0 moved
; (the grid only needs the low 6 bits, the 16 bit position is updated on success)
try_step
        sta tmp7
        sty ptr3
        ldx tmp6
        lda e_yl,x
        clc
        adc ptr3
        sta tmp2
        and #63
        tay
        lda e_xl,x
        clc
        adc tmp7
        sta tmp0
        cmp pcxl
        bne +
        lda tmp2
        cmp pcyl
        beq _no
        lda tmp0
+       and #63
        ora grid_lo,y
        sta gptr
        lda grid_hi,y
        sta gptr+1
        ldy #0
        lda (gptr),y
        bne _no
        lda tmp6
        clc
        adc #1
        sta (gptr),y
        ; clear the old cell
        lda e_yl,x
        and #63
        tay
        lda e_xl,x
        and #63
        ora grid_lo,y
        sta ptr2
        lda grid_hi,y
        sta ptr2+1
        ldy #0
        tya
        sta (ptr2),y
        ; new 16 bit position
        lda e_xl,x
        clc
        adc tmp7
        sta e_xl,x
        lda tmp7
        and #$80
        beq +
        lda #$ff
+       adc e_xh,x
        sta e_xh,x
        lda e_yl,x
        clc
        adc ptr3
        sta e_yl,x
        lda ptr3
        and #$80
        beq +
        lda #$ff
+       adc e_yh,x
        sta e_yh,x
        clc
        rts
_no     sec
        rts

; remove creature X (no drop)
remove_enemy
        stx tmp6
        lda e_xl,x
        sta tmp0
        lda e_yl,x
        sta tmp2
        jsr grid_at
        lda #0
        sta (gptr),y
        ldx tmp6
        sta e_t,x
        rts

; ---------------------------------------------------- damage creature X by A
hit_enemy
        sta tmp7
        lda e_t,x
        beq _r
        lda e_hp,x
        sec
        sbc tmp7
        bcc _kill
        beq _kill
        sta e_hp,x
        lda #2
        sta e_fl,x
        lda #SFX_HIT
        jmp sfx_start
_kill   stx he_x
        ; drop a gem (sometimes a heart)
        lda e_t,x
        tay
        lda et_gem-1,y
        sta he_g
        jsr rnd
        cmp #5
        bcs +
        lda #4
        sta he_g
+       lda e_xl,x
        sta tmp0
        lda e_xh,x
        sta tmp1
        lda e_yl,x
        sta tmp2
        lda e_yh,x
        sta tmp3
        jsr remove_enemy
        lda he_g
        jsr drop_gem
        lda #3
        jsr add_fx
        ; kills and score
        sed
        lda kills
        clc
        adc #1
        sta kills
        lda kills+1
        adc #0
        sta kills+1
        lda score
        clc
        adc #$10
        sta score
        lda score+1
        adc #0
        sta score+1
        lda score+2
        adc #0
        sta score+2
        cld
        inc hudchg
        lda #SFX_KILL
        jsr sfx_start
        ldx he_x
_r      rts
he_x    .byte 0
he_g    .byte 0

; ---------------------------------------------------- the hero is touched by creature tmp6
hurt_hero
        lda iframes
        ora cheat
        ora dead
        bne hh_ret
        ldx tmp6
        lda e_t,x
        tay
        lda et_dmg-1,y
hurt_a  sta tmp7
        lda iframes
        ora cheat
        ora dead
        bne _r
        lda hp
        sec
        sbc tmp7
        bcs +
        lda #0
+       sta hp
        lda #14
        sta iframes
        lda #SFX_HURT
        jsr sfx_start
        lda hp
        bne _r
        lda #1
        sta dead
_r
hh_ret  ldx tmp6
        rts

; ---------------------------------------------------- gems
; drop gem type A at tmp0..3 (if all slots are used, the value goes straight to xp)
drop_gem
        sta tmp7
        ldx #NG-1
-       lda g_t,x
        beq +
        dex
        bpl -
        lda tmp7
        cmp #4
        bcs _r
        tax
        lda gem_val-1,x
        jmp add_xp
+       lda tmp7
        sta g_t,x
        lda tmp0
        sta g_xl,x
        lda tmp1
        sta g_xh,x
        lda tmp2
        sta g_yl,x
        lda tmp3
        sta g_yh,x
_r      rts
gem_val .byte 1, 3, 8

gems_update
        lda w_lvl+7
        clc
        adc #1
        sta tmp5                ; pick up radius
        ldx #NG-1
_g      lda g_t,x
        beq _n
        ; |dx|, |dy| (16 bit, gems far away are dropped)
        lda pcxl
        sec
        sbc g_xl,x
        sta tmp4
        lda pcxh
        sbc g_xh,x
        jsr abs_small
        bcs _drop
        cmp tmp5
        beq +
        bcs _n
+       lda pcyl
        sec
        sbc g_yl,x
        sta tmp4
        lda pcyh
        sbc g_yh,x
        jsr abs_small
        bcs _drop
        cmp tmp5
        beq +
        bcs _n
+       ; collect
        stx tmp6
        lda g_t,x
        cmp #4
        beq _heart
        cmp #5
        beq _chest
        tax
        lda gem_val-1,x
        jsr add_xp
        lda #SFX_GEM
        jsr sfx_start
        jmp _done
_heart  lda hp
        clc
        adc #30
        bcs +
        cmp maxhp
        bcc ++
+       lda maxhp
+       sta hp
        lda #SFX_HEAL
        jsr sfx_start
        jmp _done
_chest  inc lvpend
        lda #SFX_HEAL
        jsr sfx_start
_done   ldx tmp6
_drop   lda #0
        sta g_t,x
_n      dex
        bpl _g
        rts
; 16 bit (A hi, tmp4 lo) -> C = 0, A = |value| if it is below 128
abs_small
        cmp #0
        bne +
        lda tmp4
        bmi _bad
        clc
        rts
+       cmp #$ff
        bne _bad
        lda tmp4
        bpl _bad
        eor #$ff
        clc
        adc #1
        clc
        rts
_bad    sec
        rts

; xp += A, level up when reaching xpnext
add_xp
        clc
        adc xp
        sta xp
        bcc +
        inc xp+1
+       inc hudchg
        lda xp+1
        cmp xpnext+1
        bcc _r
        bne +
        lda xp
        cmp xpnext
        bcc _r
+       ; level up
        lda xp
        sec
        sbc xpnext
        sta xp
        lda xp+1
        sbc xpnext+1
        sta xp+1
        inc plevel
        inc lvpend
        ; a level up heals a little
        lda hp
        clc
        adc #10
        bcs +
        cmp maxhp
        bcc ++
+       lda maxhp
+       sta hp
        ; next: + 5 + level * 3
        lda plevel
        asl
        clc
        adc plevel
        adc #5
        adc xpnext
        sta xpnext
        bcc _r
        inc xpnext+1
_r      rts

; ---------------------------------------------------- effects: type A at tmp0..3
add_fx
        sta tmp7
        ldy #NFX-1
-       lda fx_t,y
        beq +
        dey
        bpl -
        rts
+       lda tmp7
        sta fx_t,y
        lda tmp0
        sta fx_xl,y
        lda tmp1
        sta fx_xh,y
        lda tmp2
        sta fx_yl,y
        lda tmp3
        sta fx_yh,y
        ldx tmp7
        lda fx_time-1,x
        sta fx_tm,y
        rts
fx_time .byte 3, 8, 4

fx_update
        ldx #NFX-1
-       lda fx_t,x
        beq +
        dec fx_tm,x
        bne +
        lda #0
        sta fx_t,x
+       dex
        bpl -
        rts
