; =====================================================================
;  Zombies, lawn mowers, the boss and the sprite list
; =====================================================================
Z_WALK  = 1
Z_HELM  = 2
Z_KNIGHT = 3
Z_RUN   = 4

;              -  WALK HELM KNIGHT RUN
zhp     .byte 0,  10,  22,  52,   12
zspd    .byte 0, $26, $26, $22,  $58
zpts    .byte 0, $01, $02, $04,  $02
zcol    .byte 0,   5,   5,   5,   10
zpb     .byte 0, SPR_ZOMBIE, SPR_ZOMBIE+4, SPR_ZOMBIE+8, SPR_ZOMBIE+12

; spawn zombie of type A in lane Y (Y = $ff -> choose a lane)
zombie_spawn
        sta tmp0
        cpy #$ff
        bne _lane
        ; pick a random lane, prefer ones with few zombies
        lda #3
        sta tmp1
-       jsr rnd
        and #7
        cmp #5
        bcc +
        sbc #3
+       tay
        lda lz_cnt,y
        cmp #4
        bcc _lane
        dec tmp1
        bne -
_lane   sty tmp1
        ldx #N_Z-1
-       lda z_t,x
        beq +
        dex
        bpl -
        rts
+       lda tmp0
        sta z_t,x
        tay
        lda zhp,y
        sta z_hp,x
        lda tmp1
        sta z_lane,x
        tay
        lda lane_y,y
        sta z_y,x
        jsr rnd
        and #15
        clc
        adc #88
        sta z_xl,x
        lda #1
        sta z_xh,x
        lda #0
        sta z_xf,x
        sta z_st,x
        sta z_tm,x
        sta z_slow,x
        sta z_fl,x
        inc nzomb
        ; count it in the lane list right away (prevents bunching)
        ldy tmp1
        lda lz_cnt,y
        clc
        adc #1
        sta lz_cnt,y
        rts

; X = zombie (keeps tmp vars intact)
zombie_kill
        lda z_st,x
        cmp #2
        beq _r
        lda #2
        sta z_st,x
        lda #0
        sta z_tm,x
        txa
        pha
        ldy z_t,x
        lda zpts,y
        ldx #0
        jsr score_add
        lda #1
        sta hudflag
        pla
        tax
_r      rts

; per-lane lists (frontline info for plants and peas)
lane_lists
        lda frame
        and #1
        beq +
        rts
+       ldx #4
        lda #0
-       sta lz_cnt,x
        sta lz_max,x
        sta lz_maxh,x
        dex
        bpl -
        ldx #N_Z-1
_lp     lda z_t,x
        beq _nx
        lda z_st,x
        cmp #2
        beq _nx
        ldy z_lane,x
        lda lz_cnt,y
        cmp #8
        bcs _nx
        sta tmp0
        adc lane8,y
        stx tmp1
        tay
        lda tmp1
        sta lz_idx,y
        ldy z_lane,x
        lda lz_cnt,y
        clc
        adc #1
        sta lz_cnt,y
        ; on screen? (x < 344)
        lda z_xh,x
        beq +
        lda z_xl,x
        cmp #88
        bcs _nx
+       lda z_xh,x
        cmp lz_maxh,y
        bcc _nx
        bne +
        lda z_xl,x
        cmp lz_max,y
        bcc _nx
+       lda z_xl,x
        sta lz_max,y
        lda z_xh,x
        sta lz_maxh,y
_nx     dex
        bpl _lp
        rts

zombies_update
        ldx #N_Z-1
_lp     lda z_t,x
        bne +
_nx     dex
        bpl _lp
        rts
+       stx fi
        lda z_fl,x
        beq +
        dec z_fl,x
+       lda z_slow,x
        beq +
        dec z_slow,x
+       lda z_st,x
        cmp #2
        bne +
        inc z_tm,x
        lda z_tm,x
        cmp #45
        bcc _nx
        lda #0
        sta z_t,x
        dec nzomb
        jmp _nx
+       cmp #1
        bne _walk
        jmp _eat
_walk   ldy z_t,x
        lda zspd,y
        ldy z_slow,x
        beq +
        lsr
+       sta tmp0
        lda z_xf,x
        sec
        sbc tmp0
        sta z_xf,x
        lda z_xl,x
        sbc #0
        sta z_xl,x
        lda z_xh,x
        sbc #0
        sta z_xh,x
        ; cell under the zombie's front: lawn x = zx - 52 (half the zombies per frame)
        txa
        eor frame
        and #1
        beq +
        jmp _nx
+       jsr front_cell
        bcc _house
        bmi _nx2
        tay
        lda g_type,y
        beq _nx2
        lda #1
        sta z_st,x
        lda #0
        sta z_tm,x
_nx2    ldx fi
        jmp _nx
_house  ; zombie reached the patio
        ldy z_lane,x
        lda mw_st,y
        bne +
        jsr mower_go
        ldx fi
        jmp _nx
+       lda z_xh,x
        bmi _lose
        lda z_xl,x
        cmp #30
        bcs _nx2
_lose   lda cheat
        beq +
        jsr zombie_kill
        ldx fi
        jmp _nx
+       lda #1
        sta lost
        ldx fi
        jmp _nx
_eat    txa
        eor frame
        and #1
        beq +
        jmp _nx
+       jsr front_cell
        bcc _stop
        bmi _stop
        tay
        lda g_type,y
        beq _stop
        inc z_tm,x
        lda z_tm,x
        cmp #13
        bcc _nx2
        lda #0
        sta z_tm,x
        lda #SFX_CHOMP
        jsr sfx_start
        lda g_hp,y
        sec
        sbc #1
        sta g_hp,y
        bne _nx2
        lda #0
        sta g_type,y
        tya
        tax
        jsr draw_cell
        ldx fi
_stop   lda #0
        sta z_st,x
        jmp _nx2

; X = zombie -> C=0: in the patio; else A = cell (N=1: right of the lawn)
front_cell
        lda z_xl,x
        sec
        sbc #52
        sta tmp0
        lda z_xh,x
        sbc #0
        bmi _patio
        sta tmp1
        ; col = (lawn x + 2) / 32
        lda tmp0
        lsr tmp1
        ror
        lsr
        lsr
        lsr
        lsr
        cmp #9
        bcs _out
        ldy z_lane,x
        clc
        adc lane9,y
        sec
        rts
_out    lda #$ff
        sec
        rts
_patio  clc
        rts

; ---------------------------------------------------- lawn mowers
mower_go                        ; Y = lane
        lda #1
        sta mw_st,y
        lda #28
        sta mw_xl,y
        lda #0
        sta mw_xh,y
        sty tmp7
        tya
        jsr draw_patio
        lda #SFX_MOWER
        jmp sfx_start

mowers_update
        ldy #4
_lp     lda mw_st,y
        cmp #1
        bne _nx
        lda mw_xl,y
        clc
        adc #3
        sta mw_xl,y
        bcc +
        lda #1
        sta mw_xh,y
+       lda mw_xh,y
        beq +
        lda mw_xl,y
        cmp #88
        bcc +
        lda #2
        sta mw_st,y
        jmp _nx
+       sty tmp7
        ; flatten zombies in this lane that overlap
        ldx #N_Z-1
_zl     lda z_t,x
        beq _zn
        lda z_lane,x
        cmp tmp7
        bne _zn
        ldy tmp7
        lda z_xl,x
        sec
        sbc mw_xl,y
        sta tmp0
        lda z_xh,x
        sbc mw_xh,y
        bne _zn
        lda tmp0
        cmp #18
        bcs _zn
        jsr zombie_kill
_zn     dex
        bpl _zl
        ; boss
        ldy tmp7
        lda bo_on
        beq _nx
        lda bo_dead
        bne _nx
        cpy bo_lane
        bne _nx
        lda bo_xl
        sec
        sbc mw_xl,y
        lda bo_xh
        sbc mw_xh,y
        bne _nx
        lda #2
        sta mw_st,y
        lda #60
        jsr boss_damage
        ldy tmp7
_nx     dey
        bmi +
        jmp _lp
+       rts

; ---------------------------------------------------- boss: THE GRAVE KING
boss_start
        lda #1
        sta bo_on
        lda #88
        sta bo_xl
        lda #1
        sta bo_xh
        lda #0
        sta bo_xf
        sta bo_dead
        sta bo_fl
        lda #2
        sta bo_lane
        lda lane_y+2
        sec
        sbc #21
        sta bo_y
        lda #<300
        sta bo_hpl
        lda #>300
        sta bo_hph
        lda #200
        sta bo_tm
        lda #250
        sta bo_tl
        rts

; A = damage
boss_damage
        sta tmp0
        lda #3
        sta bo_fl
        lda bo_hpl
        sec
        sbc tmp0
        sta bo_hpl
        lda bo_hph
        sbc #0
        sta bo_hph
        bcc _dead
        ora bo_hpl
        bne _r
_dead   lda #0
        sta bo_hpl
        sta bo_hph
        lda bo_dead
        bne _r
        lda #150
        sta bo_dead
        lda #SFX_BIGEXPLO
        jsr sfx_start
        lda #0
        ldx #$01
        jsr score_add           ; 1000 points
        lda #0
        ldx #$01
        jsr score_add
_r      lda #1
        sta hudflag
        rts

boss_update
        lda bo_on
        bne +
        rts
+       lda bo_fl
        beq +
        dec bo_fl
+       lda bo_dead
        beq _alive
        dec bo_dead
        bne +
        lda #0
        sta bo_on
+       lda bo_dead
        and #15
        bne _r
        lda #SFX_BIGEXPLO
        jsr sfx_start
        lda bo_xl
        sta ex_xl
        lda bo_xh
        sta ex_xh
        lda bo_y
        clc
        adc #8
        sta ex_y
        lda #30
        sta ex_t
_r      rts
_alive  ; vertical move toward the lane
        ldy bo_lane
        lda lane_y,y
        sec
        sbc #21
        cmp bo_y
        beq _walk
        bcc +
        inc bo_y
        bne _walk
+       dec bo_y
_walk   lda bo_xf
        sec
        sbc #$1c
        sta bo_xf
        lda bo_xl
        sbc #0
        sta bo_xl
        lda bo_xh
        sbc #0
        sta bo_xh
        ; crush plants under the front
        lda bo_xl
        sec
        sbc #44
        sta tmp0
        lda bo_xh
        sbc #0
        bmi _house
        lsr
        lda tmp0
        ror
        lsr
        lsr
        lsr
        lsr
        cmp #9
        bcs _summon
        ldy bo_lane
        clc
        adc lane9,y
        tax
        lda g_type,x
        beq _summon
        lda #0
        sta g_type,x
        jsr draw_cell
        lda #SFX_CHOMP
        jsr sfx_start
        jmp _summon
_house  ldy bo_lane
        lda mw_st,y
        bne +
        jsr mower_go
        jmp _summon
+       lda bo_xl
        cmp #20
        bcs _summon
        lda cheat
        bne _push
        lda #1
        sta lost
        rts
_push   lda #200
        sta bo_xl
        lda #0
        sta bo_xh
_summon dec bo_tm
        bne _lane
        lda #220
        sta bo_tm
        lda #Z_WALK
        ldy #$ff
        jsr zombie_spawn
        jsr rnd
        and #1
        clc
        adc #Z_WALK
        ldy #$ff
        jsr zombie_spawn
        lda #SFX_GROAN
        jsr sfx_start
_lane   dec bo_tl
        bne _r2
        lda #250
        sta bo_tl
        jsr rnd
        and #1
        bne +
        lda bo_lane
        beq _r2
        dec bo_lane
        rts
+       lda bo_lane
        cmp #4
        bcs _r2
        inc bo_lane
_r2     rts

; ---------------------------------------------------- sprite list
emit    lda exh
        bmi _r
        beq _ok
        lda exl
        cmp #88
        bcs _r
_ok     cpx #NVS
        bcs _r
        lda ey
        sta cy,x
        lda exl
        sta cxl,x
        lda exh
        sta cxh,x
        lda ep
        sta cp,x
        lda ec
        sta cc,x
        inx
_r      rts

emit_next
        lda exl
        clc
        adc #24
        sta exl
        lda exh
        adc #0
        sta exh
        inc ep
        rts

build_list
        ldx #0
        ; zombies (tight loop, writes the list directly)
        ldy #N_Z-1
_zl     lda z_t,y
        beq _zn
        lda z_xh,y
        beq +
        lda z_xl,y
        cmp #88
        bcs _zn
+       cpx #NVS
        bcs _zn
        lda z_xl,y
        sta cxl,x
        lda z_xh,y
        sta cxh,x
        lda z_y,y
        sta cy,x
        lda z_st,y
        cmp #2
        beq _down
        asl
        sta tmp5
        tya
        asl
        asl
        asl
        adc frame
        lsr
        lsr
        lsr
        lsr
        and #1
        ora tmp5
        stx tmp4
        ldx z_t,y
        clc
        adc zpb,x
        ldx tmp4
        sta cp,x
        jmp _zc
_down   lda z_tm,y
        lsr
        lsr
        lsr
        lsr
        cmp #3
        bcc +
        lda #2
+       clc
        adc #SPR_ZDOWN
        sta cp,x
_zc     lda z_fl,y
        beq +
        lda #1
        bne _zs
+       lda z_slow,y
        beq +
        lda #14
        bne _zs
+       stx tmp4
        ldx z_t,y
        lda zcol,x
        ldx tmp4
_zs     sta cc,x
        inx
_zn     dey
        bmi +
        jmp _zl
+
        ; suns
        ldy #N_SUN-1
-       lda su_on,y
        beq +
        lda su_t,y
        cmp #190
        bcc _sv
        lda frame
        and #4
        beq +
_sv     lda su_xl,y
        sta exl
        lda su_xh,y
        sta exh
        lda su_y,y
        sta ey
        lda frame
        lsr
        lsr
        lsr
        and #1
        adc #SPR_SUN
        sta ep
        lda #7
        sta ec
        jsr emit
+       dey
        bpl -
        ; mowers in motion
        ldy #4
-       lda mw_st,y
        cmp #1
        bne +
        lda mw_xl,y
        sta exl
        lda mw_xh,y
        sta exh
        lda lane_y,y
        sta ey
        lda #SPR_MOWER
        sta ep
        lda #2
        sta ec
        jsr emit
+       dey
        bpl -
        ; boss (2x2)
        lda bo_on
        beq _nob
        lda frame
        lsr
        lsr
        lsr
        lsr
        and #1
        asl
        asl
        adc #SPR_BOSS
        sta ep
        lda #5
        ldy bo_fl
        beq +
        lda #1
+       ldy bo_dead
        beq +
        lda frame
        and #2
        beq +
        lda #2
+       sta ec
        lda bo_xl
        sta exl
        lda bo_xh
        sta exh
        lda bo_y
        sta ey
        jsr emit
        jsr emit_next
        jsr emit
        lda bo_xl
        sta exl
        lda bo_xh
        sta exh
        lda bo_y
        clc
        adc #21
        sta ey
        inc ep
        jsr emit
        jsr emit_next
        jsr emit
_nob    ; explosion (2x2 of the same frame)
        lda ex_t
        beq _noe
        dec ex_t
        lda #30
        sec
        sbc ex_t
        lsr
        lsr
        lsr
        cmp #3
        bcc +
        lda #2
+       clc
        adc #SPR_EXPL
        sta ep
        lda #8
        sta ec
        lda ex_xl
        sta exl
        lda ex_xh
        sta exh
        lda ex_y
        sta ey
        jsr emit
        dec ep
        jsr emit_next
        jsr emit
        lda ex_xl
        sta exl
        lda ex_xh
        sta exh
        lda ex_y
        clc
        adc #20
        sta ey
        jsr emit
        dec ep
        jsr emit_next
        jsr emit
_noe    ; cursor
        lda cur_r
        beq _nc
        sec
        sbc #1
        tay
        lda lane_y,y
        sec
        sbc #12
        sta ey
        ldy cur_c
        lda plantx_l,y
        clc
        adc #4
        sta exl
        lda plantx_h,y
        adc #0
        sta exh
        lda #0
        ldy held
        beq +
        lda #1
        cpy #P_SHOVEL
        bne +
        lda #2
+       clc
        adc #SPR_CURSOR
        sta ep
        lda #1
        ldy frame
        cpy #128
        bcc +
        lda #7
+       sta ec
        jsr emit
_nc     stx nactive
        #PROF 9
        jmp sort_sprites
