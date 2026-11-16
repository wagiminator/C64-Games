; =====================================================================
;  Lawn: cells, plants, peas (pre-shifted chars), suns, cursor
; =====================================================================
P_SUN   = 1
P_SPIT  = 2
P_ROCK  = 3
P_BOOM  = 4
P_FROST = 5
P_TWIN  = 6
P_SHOVEL = 7

;                  -  SUN SPIT ROCK BOOM FROST TWIN
p_hp    .byte 0,   6,   6,  72,  99,   6,   6
p_t0    .byte 0,  40,   1, 255,   6,   1,   1
p_cool  .byte     37,  37, 150, 250,  37,  37        ; units of 8 frames (packet 0..5)
p_costl .byte   $50, $00, $50, $50, $75, $00
p_costh .byte   $00, $01, $00, $01, $01, $02
p_costt .text " 50", "100", " 50", "150", "175", "200"

cell_lo .for i := 0, i < 45, i += 1
        .byte <(SCRA + (LAWNROW + (i / 9) * 4) * 40 + LAWNCOL + (i % 9) * 4)
        .next
cell_hi .for i := 0, i < 45, i += 1
        .byte >(SCRA + (LAWNROW + (i / 9) * 4) * 40 + LAWNCOL + (i % 9) * 4)
        .next
cell_lane .for i := 0, i < 45, i += 1
        .byte i / 9
        .next
cell_col .for i := 0, i < 45, i += 1
        .byte i % 9
        .next
cell_shade .for i := 0, i < 45, i += 1
        .byte ((i / 9) + (i % 9)) & 1
        .next
cellofs .byte 0,1,2,3, 40,41,42,43, 80,81,82,83, 120,121,122,123
lane9   .byte 0,9,18,27,36
lane8   .byte 0,8,16,24,32
pr_lo   .for l := 0, l < 5, l += 1
        .byte <(SCRA + (LAWNROW + 2 + l * 4) * 40)
        .next
pr_hi   .for l := 0, l < 5, l += 1
        .byte >(SCRA + (LAWNROW + 2 + l * 4) * 40)
        .next
lane_y  .byte 93, 125, 157, 189, 221      ; zombie sprite y per lane
plantx_l .for c := 0, c < 9, c += 1          ; sprite x of a cell's left edge
        .byte <(56 + c * 32)
        .next
plantx_h .for c := 0, c < 9, c += 1
        .byte >(56 + c * 32)
        .next

; ---------------------------------------------------- draw one cell (X = cell)
draw_cell
        stx tmp7
        lda cell_lo,x
        sta ptr0
        sta ptr1
        lda cell_hi,x
        sta ptr0+1
        clc
        adc #>(COLRAM-SCRA)
        sta ptr1+1
        lda cell_shade,x
        clc
        adc #CH_GRASS
        sta tmp6
        lda g_type,x
        beq _grass
        sec
        sbc #1
        sta tmp5
        asl
        adc tmp5
        asl
        asl
        sta tmp5                ; (type-1)*12
        ldx #0
-       ldy cellofs,x
        lda tmp6
        sta (ptr0),y
        lda #8+5
        sta (ptr1),y
        inx
        cpx #4
        bne -
        lda #4
        sta tmp4
_pl     ldx tmp4
        ldy cellofs,x
        txa
        clc
        adc tmp5
        sec
        sbc #4
        tax
        lda plant_col,x
        sta (ptr1),y
        txa
        clc
        adc #CH_PLANT
        sta (ptr0),y
        inc tmp4
        lda tmp4
        cmp #16
        bne _pl
        ldx tmp7
        rts
_grass  ldx #15
-       ldy cellofs,x
        lda tmp6
        sta (ptr0),y
        lda #8+5
        sta (ptr1),y
        dex
        bpl -
        ldx tmp7
        rts

draw_lane                       ; A = lane: redraw its 9 cells + patio
        sta tmp3
        tax
        lda lane9,x
        tax
        lda #9
        sta tmp2
-       jsr draw_cell
        inx
        dec tmp2
        bne -
        lda tmp3
        jmp draw_patio

; patio for lane A: wall + stones + mower if ready
draw_patio
        sta tmp3
        asl
        asl
        clc
        adc #LAWNROW
        tax
        ldy #4
-       lda rowlo,x
        sta ptr0
        sta ptr1
        lda rowhiA,x
        sta ptr0+1
        lda rowhiC,x
        sta ptr1+1
        sty tmp2
        ldy #0
        lda #CH_WALL
        sta (ptr0),y
        lda #wall_col
        sta (ptr1),y
        iny
-       lda #CH_STONE
        sta (ptr0),y
        lda #stone_col
        sta (ptr1),y
        iny
        cpy #4
        bne -
        ldy tmp2
        inx
        dey
        bne --
        ldx tmp3
        lda mw_st,x
        bne _r
        ; mower chars at rows +2,+3, cols 1..3
        txa
        asl
        asl
        clc
        adc #LAWNROW+2
        tax
        lda #0
        sta tmp2
_mr     lda rowlo,x
        sta ptr0
        sta ptr1
        lda rowhiA,x
        sta ptr0+1
        lda rowhiC,x
        sta ptr1+1
        ldy #1
-       sty tmp4
        ldy tmp2
        lda mower_col,y
        pha
        tya
        clc
        adc #CH_MOWER
        ldy tmp4
        sta (ptr0),y
        pla
        sta (ptr1),y
        inc tmp2
        iny
        cpy #4
        bne -
        inx
        lda tmp2
        cmp #6
        bne _mr
_r      rts

; ---------------------------------------------------- plant animation (frame swap, one type per frame)
anim_plants
        lda frame
        and #31
        cmp #6
        bcs _r
        tax
        lda pdst_lo,x
        sta ptr1
        lda pdst_hi,x
        sta ptr1+1
        txa
        asl
        sta tmp0
        lda frame
        and #32
        beq +
        inc tmp0
+       ldx tmp0
        lda psrc_lo,x
        sta ptr0
        lda psrc_hi,x
        sta ptr0+1
        ldy #95
-       lda (ptr0),y
        sta (ptr1),y
        dey
        bpl -
_r      rts
psrc_lo .for i := 0, i < 12, i += 1
        .byte <(plant_anim + i * 96)
        .next
psrc_hi .for i := 0, i < 12, i += 1
        .byte >(plant_anim + i * 96)
        .next
pdst_lo .for i := 0, i < 6, i += 1
        .byte <(CHARSET + (CH_PLANT + i * 12) * 8)
        .next
pdst_hi .for i := 0, i < 6, i += 1
        .byte >(CHARSET + (CH_PLANT + i * 12) * 8)
        .next

; ---------------------------------------------------- plants (every 8 frames)
plants_tick
        lda frame
        and #7
        sta pphase
        ldx #44
_lp     txa
        and #7
        cmp pphase
        bne _nx
        lda g_type,x
        bne +
_nx     dex
        bpl _lp
        rts
+       dec g_t,x
        bne _nx
        stx fi
        lda g_type,x
        cmp #P_SUN
        bne +
        lda #150
        sta g_t,x
        jsr sun_from_plant
        jmp _done
+       cmp #P_ROCK
        bne +
        lda #255
        sta g_t,x
        jmp _done
+       cmp #P_BOOM
        bne +
        jsr explode
        jmp _done
+       ; shooters: fire only if a target is ahead in the lane
        lda #2
        sta g_t,x
        ldy cell_lane,x
        jsr target_ahead
        bcc _done
        ldx fi
        lda #9
        sta g_t,x
        ldy cell_col,x
        lda c16tab,y
        clc
        adc #28
        sta tmp0                ; x2
        lda g_type,x
        cmp #P_FROST
        bne +
        lda #1
        bne ++
+       lda #0
+       sta tmp1
        lda cell_lane,x
        sta tmp2
        jsr pea_spawn
        ldx fi
        lda g_type,x
        cmp #P_TWIN
        bne +
        lda tmp0
        sec
        sbc #5
        sta tmp0
        jsr pea_spawn
+       lda #SFX_POP
        jsr sfx_start
_done   ldx fi
        jmp _nx
c16tab  .byte 0,16,32,48,64,80,96,112,128

; X = cell, Y = lane -> C=1 if zombie/boss on screen and right of the plant
target_ahead
        lda bo_on
        beq +
        cpy bo_lane
        beq _yes
+       lda lz_cnt,y
        beq _no
        ldx fi
        lda cell_col,x
        tax
        lda lz_maxh,y
        cmp plantx_h,x
        bcc _no
        bne _yes
        lda lz_max,y
        cmp plantx_l,x
        bcc _no
_yes    sec
        rts
_no     clc
        rts

; ---------------------------------------------------- boomberry explosion at cell fi
explode
        ldx fi
        lda #0
        sta g_type,x
        jsr draw_cell
        ldx fi
        lda cell_col,x
        tay
        lda plantx_l,y
        sec
        sbc #12
        sta ex_xl
        lda plantx_h,y
        sbc #0
        sta ex_xh
        ldy cell_lane,x
        lda lane_y,y
        sec
        sbc #22
        sta ex_y
        lda #30
        sta ex_t
        lda #SFX_BIGEXPLO
        jsr sfx_start
        ; damage zombies in lanes l-1..l+1 with |zx - cellx| < 52
        ldx fi
        lda cell_lane,x
        sta tmp3
        ldy cell_col,x
        lda plantx_l,y
        sta tmp4
        lda plantx_h,y
        sta tmp5
        ldx #N_Z-1
_zl     lda z_t,x
        beq _zn
        lda z_st,x
        cmp #2
        beq _zn
        lda z_lane,x
        sec
        sbc tmp3
        clc
        adc #1
        cmp #3
        bcs _zn
        lda z_xl,x
        sec
        sbc tmp4
        sta tmp6
        lda z_xh,x
        sbc tmp5
        beq _p
        cmp #$ff
        bne _zn
        lda tmp6
        cmp #256-52
        bcc _zn
        bcs _hit
_p      lda tmp6
        cmp #52
        bcs _zn
_hit    stx tmp7
        jsr zombie_kill
        ldx tmp7
_zn     dex
        bpl _zl
        ; boss
        lda bo_on
        beq _r
        lda bo_lane
        sec
        sbc tmp3
        clc
        adc #1
        cmp #3
        bcs _r
        lda bo_xl
        sec
        sbc tmp4
        lda bo_xh
        sbc tmp5
        bmi +
        cmp #1
        bcs _r
+       lda #40
        jmp boss_damage
_r      rts

; ---------------------------------------------------- peas
; tmp0 = x2, tmp1 = kind, tmp2 = lane
pea_spawn
        ldx tmp2
        lda lane8,x
        tax
        ldy #8
-       lda pe_x,x
        beq +
        inx
        dey
        bne -
        rts
+       lda tmp0
        sta pe_x,x
        lda tmp1
        sta pe_k,x
        rts

; Y = screen column, A = pea char offset (0..7) or $ff = grass; tmp5 = lane
pcell   cpy #LAWNCOL
        bcc _r
        cpy #40
        bcs _r
        sta tmp6
        tya
        sec
        sbc #LAWNCOL
        lsr
        lsr
        sta tmp7
        ldx tmp5
        clc
        adc lane9,x
        tax
        lda g_type,x
        bne _r
        lda tmp5
        clc
        adc tmp7
        and #1
        ldx tmp6
        bmi _g
        asl
        asl
        asl
        adc tmp6
        adc #CH_PEA
        sta (ptr0),y
        lda pcolor
        sta (ptr1),y
        rts
_g      clc
        adc #CH_GRASS
        sta (ptr0),y
_r      rts

; set ptr0/ptr1 for lane of slot X, tmp5 = lane
pea_lane
        lda slot_lane,x
        sta tmp5
        tay
        lda pr_lo,y
        sta ptr0
        sta ptr1
        lda pr_hi,y
        sta ptr0+1
        clc
        adc #>(COLRAM-SCRA)
        sta ptr1+1
        rts
slot_lane .for i := 0, i < 40, i += 1
        .byte i / 8
        .next

peas_update
        ldx #39
_lp     txa
        eor frame
        and #1
        bne _nxj
        lda pe_x,x
        bne +
_nxj    jmp _nx
+
        stx fi
        sta tmp4                ; old x2
        jsr pea_lane
        ldx fi
        lda #8+5
        ldy pe_k,x
        beq +
        lda #8+3
+       sta pcolor
        lda tmp4
        clc
        adc #2
        sta pe_x,x
        cmp #158
        bcs _gone
        jsr pea_collide
        bcs _gone
        ; erase the column we leave
        lda tmp4
        lsr
        lsr
        sta tmp3                ; old col
        ldx fi
        lda pe_x,x
        lsr
        lsr
        cmp tmp3
        beq +
        ldy tmp3
        lda #$ff
        jsr pcell
+       ; draw at the new position
        ldx fi
        lda pe_x,x
        and #3
        asl
        sta tmp3                ; shift*2
        lda pe_x,x
        lsr
        lsr
        tay
        lda tmp3
        jsr pcell
        ldx fi
        lda pe_x,x
        lsr
        lsr
        tay
        iny
        lda tmp3
        ora #1
        jsr pcell
        ldx fi
        jmp _nx
_gone   ldx fi
        lda #0
        sta pe_x,x
        lda tmp4
        lsr
        lsr
        tay
        sty tmp3
        lda #$ff
        jsr pcell
        ldy tmp3
        iny
        lda #$ff
        jsr pcell
        ldx fi
_nx     dex
        bmi +
        jmp _lp
+       rts

; X = pea slot -> C=1 if it hit something
pea_collide
        txa
        lsr
        lsr
        lsr
        sta tmp5                ; lane
        lda pe_x,x
        asl
        sta tmp0
        lda #0
        rol
        sta tmp1
        lda tmp0
        clc
        adc #24
        sta tmp0
        lda tmp1
        adc #0
        sta tmp1                ; pea sprite x (16 bit)
        ; boss
        lda bo_on
        beq _z
        lda bo_dead
        bne _z
        lda tmp5
        cmp bo_lane
        bne _z
        lda tmp0
        sec
        sbc bo_xl
        sta tmp2
        lda tmp1
        sbc bo_xh
        bne _z
        lda tmp2
        cmp #6
        bcc _z
        cmp #44
        bcs _z
        lda #1
        jsr boss_damage
        sec
        rts
_z      ldy tmp5
        lda lz_cnt,y
        beq _no
        sta tmp6
        lda lane8,y
        tay
_zl     ldx lz_idx,y
        lda z_st,x
        cmp #2
        beq _zn
        lda tmp0
        sec
        sbc z_xl,x
        sta tmp2
        lda tmp1
        sbc z_xh,x
        bne _zn
        lda tmp2
        cmp #22
        bcs _zn
        ; hit zombie X
        ldy fi
        lda pe_k,y
        beq +
        lda #250
        sta z_slow,x
+       lda #3
        sta z_fl,x
        dec z_hp,x
        bne +
        jsr zombie_kill
+       lda #SFX_SPLAT
        jsr sfx_start
        sec
        rts
_zn     iny
        dec tmp6
        bne _zl
_no     clc
        rts

; ---------------------------------------------------- suns
; spawn: tmp0/tmp1 = x, tmp2 = start y, tmp3 = target y, tmp4 = lane, tmp5 = col
sun_spawn
        ldx #N_SUN-1
-       lda su_on,x
        beq +
        dex
        bpl -
        rts
+       lda #1
        sta su_on,x
        lda tmp0
        sta su_xl,x
        lda tmp1
        sta su_xh,x
        lda tmp2
        sta su_y,x
        lda tmp3
        sta su_ty,x
        lda #0
        sta su_t,x
        lda tmp4
        sta su_lane,x
        lda tmp5
        sta su_col,x
        rts

sun_from_plant                  ; X = cell
        ldy cell_col,x
        lda plantx_l,y
        clc
        adc #6
        sta tmp0
        lda plantx_h,y
        adc #0
        sta tmp1
        ldy cell_lane,x
        lda lane_y,y
        sec
        sbc #20
        sta tmp2
        clc
        adc #8
        sta tmp3
        lda cell_lane,x
        sta tmp4
        lda cell_col,x
        sta tmp5
        jmp sun_spawn

sky_sun
        lda area
        cmp #2
        bcs _r
        lda skysun_t
        bne +
        dec skysun_t+1
+       dec skysun_t
        lda skysun_t
        ora skysun_t+1
        bne _r
        ldx area
        lda skysun_int,x
        sta skysun_t
        lda #1
        sta skysun_t+1
        jsr rnd
        and #15
        cmp #9
        bcc +
        sbc #7
+       sta tmp5
        jsr rnd
        and #7
        cmp #5
        bcc +
        sbc #3
+       sta tmp4
        ldy tmp5
        lda plantx_l,y
        clc
        adc #6
        sta tmp0
        lda plantx_h,y
        adc #0
        sta tmp1
        lda #84
        sta tmp2
        ldy tmp4
        lda lane_y,y
        sec
        sbc #12
        sta tmp3
        jmp sun_spawn
_r      rts
skysun_int .byte 70, 200

suns_update
        ldx #N_SUN-1
_lp     lda su_on,x
        beq _nx
        lda su_y,x
        cmp su_ty,x
        bcs _landed
        lda frame
        and #1
        bne _chk
        inc su_y,x
        jmp _chk
_landed inc su_t,x
        lda su_t,x
        cmp #250
        bcc _chk
        lda #0
        sta su_on,x
        jmp _nx
_chk    ; collect if the cursor is on this cell
        lda cur_r
        beq _nx
        sec
        sbc #1
        cmp su_lane,x
        bne _nx
        lda cur_c
        cmp su_col,x
        bne _nx
        lda #0
        sta su_on,x
        jsr add_sun25
        lda #SFX_SUN
        jsr sfx_start
_nx     dex
        bpl _lp
        rts

add_sun25
        sed
        lda sun
        clc
        adc #$25
        sta sun
        lda sun+1
        adc #0
        cmp #$99
        bcc +
        lda #$99
+       sta sun+1
        cld
        lda #1
        sta sunflag
        rts

; ---------------------------------------------------- cursor / seed bar control
BAR_SHOVEL = 6
cursor_update
        lda joy
        and #15
        bne +
        sta lastdir
        jmp _fire
+       cmp lastdir
        bne _first
        dec rep_t
        bne _fire
        lda #6
        sta rep_t
        jmp _move
_first  sta lastdir
        lda #14
        sta rep_t
_move   lda lastdir
        and #1
        beq _dn
        lda cur_r
        beq _dn
        dec cur_r
        bne _dn
        ; entering the bar
        lda cur_c
        sta cur_lc
        lda #1
        sta cur_lr
        lda cur_bc
        sta cur_c
        lda #1
        sta pkflag
        jmp _fire
_dn     lda lastdir
        and #2
        beq _lr
        lda cur_r
        cmp #5
        bcs _lr
        inc cur_r
        cmp #0
        bne _lr
        lda cur_c
        sta cur_bc
        lda cur_lc
        sta cur_c
        lda #1
        sta pkflag
_lr     lda lastdir
        and #4
        beq _rt
        jsr cur_left
_rt     lda lastdir
        and #8
        beq _fire
        jsr cur_right
_fire   lda joy
        and #16
        tax
        eor firelast
        and joy
        stx firelast
        and #16
        bne +
        rts
+       lda cur_r
        bne _lawn
        ; ---- seed bar
        lda cur_c
        cmp #BAR_SHOVEL
        bne +
        lda #P_SHOVEL
        jmp _take
+       tax
        lda pk_cd,x
        bne _nope
        jsr can_afford
        bcc _nope
        txa
        clc
        adc #1
_take   cmp held
        bne +
        lda #0
        sta held
        lda #1
        sta pkflag
        rts
+       sta held
        lda #1
        sta pkflag
        lda #SFX_MENU
        jsr sfx_start
        ; jump down onto the lawn
        lda cur_c
        sta cur_bc
        lda cur_lc
        sta cur_c
        lda cur_lr
        sta cur_r
        rts
_nope   lda #SFX_CHOMP
        jmp sfx_start
_lawn   ldx cur_r
        dex
        lda lane9,x
        clc
        adc cur_c
        tax
        lda held
        beq _r
        cmp #P_SHOVEL
        bne _plant
        lda g_type,x
        beq _r
        lda #0
        sta g_type,x
        sta held
        jsr draw_cell
        lda #1
        sta pkflag
        lda #SFX_PLANT
        jmp sfx_start
_plant  lda g_type,x
        bne _r
        lda held
        sta g_type,x
        tay
        lda p_hp,y
        sta g_hp,x
        lda p_t0,y
        sta g_t,x
        jsr draw_cell
        ldy held
        dey
        lda cheat
        bne +
        lda p_cool,y
        sta pk_cd,y
        sed
        lda sun
        sec
        sbc p_costl,y
        sta sun
        lda sun+1
        sbc p_costh,y
        sta sun+1
        cld
+       lda #0
        sta held
        lda #1
        sta pkflag
        sta sunflag
        lda #SFX_PLANT
        jmp sfx_start
_r      rts

; X = packet -> C=1 if sun >= cost
can_afford
        lda cheat
        bne _y
        lda sun+1
        cmp p_costh,x
        bcc _n
        bne _y
        lda sun
        cmp p_costl,x
        bcc _n
_y      sec
        rts
_n      clc
        rts

cur_left
        lda cur_c
        beq _r
        dec cur_c
        lda cur_r
        bne _r
        lda cur_c
        cmp npack
        bcc _pk
        lda npack
        sec
        sbc #1
        sta cur_c
_pk     lda #1
        sta pkflag
_r      rts
cur_right
        lda cur_r
        bne _lawn
        lda cur_c
        cmp #BAR_SHOVEL
        bcs _r
        inc cur_c
        lda cur_c
        cmp npack
        bcc +
        lda #BAR_SHOVEL
        sta cur_c
+       lda #1
        sta pkflag
_r      rts
_lawn   lda cur_c
        cmp #8
        bcs _r
        inc cur_c
        rts

; packet cooldowns (every 8 frames)
packets_tick
        lda frame
        and #7
        bne _r
        ldx #5
-       lda pk_cd,x
        beq +
        dec pk_cd,x
        bne +
        lda #1
        sta pkflag
+       dex
        bpl -
_r      rts
