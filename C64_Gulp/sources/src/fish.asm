; =====================================================================
;  Fish: spawning, swimming, eating, jellyfish, clam, bursts
; =====================================================================
K_T1    = 1
K_T2    = 2
K_T3    = 3
K_PRED  = 4
K_JELLY = 5
K_GOLD  = 6
K_CLAM  = 7
K_BOSS  = 8
CLAM_Y  = 205

;            -  T1  T2  T3  PRED JEL GOLD CLAM BOSS
ktier   .byte 0,  1,  2,  3,  9,   0,  1,   0,   9
kwide   .byte 0,  0,  0,  0,  1,   0,  0,   0,   0
kbx0    .byte 0,  4,  4,  2,  4,   4,  4,   4,   6
        .byte     6,  6,  5,  8,   6,  6,   4,  10      ; shrunk "death" boxes (kind | 8)
kbx1    .byte 0, 20, 20, 22, 44,  20, 20,  20,  42
        .byte    18, 18, 19, 40,  18, 18,  20,  38
kby0    .byte 0,  8,  6,  5,  7,   3,  8,  12,   6
        .byte     9,  8,  7,  9,   5,  9,  12,  10
kby1    .byte 0, 13, 15, 16, 15,  16, 13,  20,  38
        .byte    12, 13, 14, 13,  14, 12,  20,  34
kgrow   .byte 0,  1,  2,  3,  0,   0,  3,   0,   0
kpts    .byte 0,$01,$02,$04,  0,   0,$25,   0,   0
kspd_l  .byte 0,$40,$e0,$b0,$90, $a0,$20
kspd_h  .byte 0,  1,  0,  0,  1,   0,  2
; colours per zone (index zone*8 + kind)
kcol    .byte 0,13, 4,10,12, 1, 7,0
        .byte 0,15, 3, 2,11,10, 7,0
        .byte 0, 5,15, 4,12, 3, 7,0
zone8   .byte 0,8,16
zone6   .byte 0,6,12
zone2   .byte 0,2,4

; ---------------------------------------------------- level tables (zone*3+lvl)
lv_t2   .byte 10,12, 0, 12,14, 0, 14,16, 0
lv_t3   .byte 24,28,20, 28,32,24, 32,36,28
lv_goal .byte 44,50,30, 50,56,34, 56,62,38
lv_max  .byte  7, 8, 6,  8, 9, 7,  9, 9, 7
lv_rate .byte 40,34,46, 34,30,42, 30,26,38
lv_spd  .byte  0,$10, 0,$10,$20,$10,$20,$30,$20
lv_bhp  .byte  0, 0, 3,  0, 0, 4,  0, 0, 5
; cumulative spawn weights T1 T2 T3 PRED JELLY GOLD
lv_w    .byte 125,185,218,232,246,255
        .byte  90,160,205,226,245,255
        .byte 110,190,230,230,248,255
        .byte  90,160,205,228,246,255
        .byte  80,150,200,226,245,255
        .byte 110,190,230,230,248,255
        .byte  80,150,200,228,246,255
        .byte  70,140,195,226,245,255
        .byte 110,190,230,230,248,255

fish_clear
        ldx #N_FISH-1
        lda #0
-       sta f_k,x
        dex
        bpl -
        sta nfish
        sta bu_t
        sta bu_t+1
        rts

; ---------------------------------------------------- objects in a 21-line band around A
band_count
        sta tmp4
        lda #0
        sta tmp5
        lda py
        jsr _near
        ldx #N_FISH-1
-       lda f_k,x
        beq +
        lda f_y,x
        jsr _near
        beq +
        ldy f_k,x
        lda kwide,y
        beq +
        inc tmp5
+       dex
        bpl -
        lda b_on
        beq +
        lda tmp4
        clc
        adc #21
        cmp b_y
        bcc +
        lda b_y
        clc
        adc #42
        cmp tmp4
        bcc +
        inc tmp5
        inc tmp5
+       lda tmp5
        rts
_near   sec
        sbc tmp4
        bcs +
        eor #$ff
        adc #1
+       cmp #22
        bcs +
        inc tmp5
        lda #1
        rts
+       lda #0
        rts

; ---------------------------------------------------- spawner
fish_spawn
        dec spawn_t
        beq +
        rts
+       ldy lvidx
        jsr rnd
        and #15
        clc
        adc lv_rate,y
        sta spawn_t
        lda nfish
        cmp lv_max,y
        bcc +
        rts
+       ldx #N_FISH-1
-       lda f_k,x
        beq _slot
        dex
        bpl -
        rts
_slot   stx fi
        ; kind
        lda lvidx
        asl
        sta tmp0
        asl
        adc tmp0                ; *6
        tay
        jsr rnd
        ldx #1
-       cmp lv_w,y
        bcc _kind
        iny
        inx
        cpx #7
        bne -
        ldx #K_T1
_kind   stx tmp6
        cpx #K_PRED
        beq +
        cpx #K_JELLY
        bne ++
+       jsr count_kind
        cmp #2
        bcc +
        lda #K_T1
        sta tmp6
+       ; y position (avoid crowded bands)
        lda #4
        sta tmp7
_try    jsr rnd
        and #127
        clc
        adc #YMIN+2
        cmp #YMAX-10
        bcc +
        sbc #60
+       ldx tmp6
        cpx #K_JELLY
        bne +
        and #63
        adc #110
+       sta tmp3
        jsr band_count
        cmp #5
        bcc _place
        dec tmp7
        bne _try
        rts
_place  ldx fi
        lda tmp6
        sta f_k,x
        tay
        lda tmp3
        sta f_yb,x
        sta f_y,x
        jsr rnd
        sta f_ph,x
        lda #0
        sta f_xf,x
        ; speed
        ldy lvidx
        jsr rnd
        and lv_spd,y
        ldy tmp6
        clc
        adc kspd_l,y
        sta tmp0
        lda kspd_h,y
        adc #0
        sta tmp1
        jsr rnd
        and #1
        sta f_dir,x
        bne _left
        lda #$d0
        sta f_xl,x
        lda #$ff
        sta f_xh,x
        lda tmp0
        sta f_vl,x
        lda tmp1
        sta f_vh,x
        jmp _spr
_left   lda #88
        sta f_xl,x
        lda #1
        sta f_xh,x
        lda #0
        sec
        sbc tmp0
        sta f_vl,x
        lda #0
        sbc tmp1
        sta f_vh,x
_spr    ; sprite base pointer
        ldy zone
        lda tmp6
        cmp #K_PRED
        bne +
        lda zone2,y
        ora f_dir,x
        asl
        asl
        adc #SPR_PRED
        jmp _sp
+       cmp #K_JELLY
        bne +
        lda #SPR_JELLY
        jmp _sp
+       lda tmp6
        cmp #K_GOLD
        bne +
        lda #K_T1
+       sec
        sbc #1
        sta tmp0
        lda zone6,y
        lsr
        clc
        adc tmp0
        asl
        ora f_dir,x
        asl
        adc #SPR_FISH
_sp     sta f_spr,x
        lda zone8,y
        clc
        adc tmp6
        tay
        lda kcol,y
        sta f_col,x
        inc nfish
        rts

count_kind                      ; X = kind -> A = number alive (jelly counts double)
        stx tmp1
        lda #0
        cpx #K_JELLY
        bne +
        lda #1
+       sta tmp0
        ldy #N_FISH-1
-       lda f_k,y
        cmp tmp1
        bne +
        inc tmp0
+       dey
        bpl -
        lda tmp0
        rts

; ---------------------------------------------------- per frame update
fish_update
        ldx #N_FISH-1
_lp     lda f_k,x
        bne +
        jmp _nx
+       stx fi
        ; x += v
        lda f_xf,x
        clc
        adc f_vl,x
        sta f_xf,x
        lda f_xl,x
        adc f_vh,x
        sta f_xl,x
        lda f_vh,x
        bmi +
        lda f_xh,x
        adc #0
        jmp ++
+       lda f_xh,x
        adc #$ff
+       sta f_xh,x
        ; off screen?
        lda f_dir,x
        bne +
        lda f_xh,x
        cmp #1
        bne _y
        lda f_xl,x
        cmp #88
        bcc _y
        jmp _free
+       lda f_xh,x
        bpl _y
        lda f_xl,x
        cmp #$d0
        bcs _y
        jmp _free
_y      ; vertical behaviour
        lda f_k,x
        cmp #K_JELLY
        bne _npj
        inc f_ph,x
        inc f_ph,x
        ldy f_ph,x
        lda sintab,y
        cmp #$80
        ror
        cmp #$80
        ror
        cmp #$80
        ror
        clc
        adc f_yb,x
        sta f_y,x
        jmp _col
_npj    cmp #K_PRED
        bne _wob
        lda pstate
        bne _wob
        lda frame
        and #1
        bne _wob
        lda py
        cmp f_yb,x
        beq _wob
        bcc +
        lda f_yb,x
        cmp #YMAX-6
        bcs _wob
        inc f_yb,x
        bne _wob
+       lda f_yb,x
        cmp #YMIN+2
        bcc _wob
        dec f_yb,x
_wob    lda f_ph,x
        clc
        adc #3
        sta f_ph,x
        tay
        lda sintab,y
        cmp #$80
        ror
        cmp #$80
        ror
        cmp #$80
        ror
        cmp #$80
        ror
        cmp #$80
        ror
        clc
        adc f_yb,x
        sta f_y,x
_col    ; collision with player
        lda pstate
        cmp #1
        beq _nx
        lda f_xl,x
        sta tmp0
        lda f_xh,x
        sta tmp1
        lda f_y,x
        sta tmp2
        ldy f_k,x
        jsr hit_box
        bcc _nx
        ldx fi
        ldy f_k,x
        jsr fish_touch
        ldx fi
_nx     dex
        bmi +
        jmp _lp
+       rts
_free   lda #0
        sta f_k,x
        dec nfish
        jmp _nx

; ---------------------------------------------------- box overlap with player
; tmp0/tmp1 = object x, tmp2 = object y, Y = box kind -> C=1 overlap
hit_box
        lda tmp0
        sec
        sbc pxl
        sta cdx
        lda tmp1
        sbc pxh
        beq _p
        cmp #$ff
        bne _no
        lda cdx
        cmp #$c0
        bcc _no
        bcs _x
_p      lda cdx
        cmp #$40
        bcs _no
_x      lda cdx
        clc
        adc kbx0,y
        sec
        sbc pbx1
        bpl _no
        lda cdx
        clc
        adc kbx1,y
        sec
        sbc pbx0
        bmi _no
        beq _no
        lda tmp2
        sec
        sbc py
        sta cdy
        bcc _n
        cmp #48
        bcs _no
        bcc _yy
_n      cmp #$d0
        bcc _no
_yy     lda cdy
        clc
        adc kby0,y
        sec
        sbc pby1
        bpl _no
        lda cdy
        clc
        adc kby1,y
        sec
        sbc pby0
        bmi _no
        beq _no
        sec
        rts
_no     clc
        rts

; X = fish, Y = kind
fish_touch
        cpy #K_JELLY
        bne +
        jmp player_stun
+       lda pstate
        cmp #2
        beq _big                ; stunned fish can't eat
        lda ktier,y
        sec
        sbc #1
        cmp psize
        beq _eat
        bcc _eat
_big    lda ktier,y
        sec
        sbc #1
        cmp psize
        beq _r
        bcc _r
        tya
        clc
        adc #8
        tay
        jsr hit_box
        bcc _r
        jmp player_die
_r      rts
_eat    ; ---- eat it
        sty tmp6
        lda #0
        sta f_k,x
        dec nfish
        ; burst
        lda bu_i
        eor #1
        sta bu_i
        tay
        lda #12
        sta bu_t,y
        lda f_xl,x
        sta bu_xl,y
        lda f_xh,x
        sta bu_xh,y
        lda f_y,x
        sta bu_y,y
        ; combo / multiplier
        lda combo_t
        beq +
        inc combo
        jmp ++
+       lda #1
        sta combo
+       lda #90
        sta combo_t
        lda combo
        lsr
        lsr
        clc
        adc #1
        cmp #5
        bcc +
        lda #4
+       sta mult
        ; score = pts * mult
        ldy tmp6
        lda kpts,y
        sta tmp7
        lda mult
        sta tmp5
-       lda tmp7
        ldx #0
        jsr score_add
        dec tmp5
        bne -
        lda #1
        sta hudflag
        ; growth
        ldy tmp6
        lda growth
        clc
        adc kgrow,y
        bcc +
        lda #255
+       sta growth
        lda #12
        sta pmouth
        lda #1
        sta barflag
        lda #SFX_GULP
        cpy #K_GOLD
        bne +
        lda #SFX_PEARL
+       jsr sfx_start
        jmp check_growth

check_growth
        lda lvl
        cmp #2
        bne _norm
        lda power
        bne _r
        lda growth
        cmp g_goal
        bcc _r
        lda #200
        sta power
        lda #SFX_GROW
        jsr sfx_start
        lda #<t_power
        ldx #>t_power
        jmp show_msg
_r      rts
_norm   lda growth
        cmp g_goal
        bcc +
        lda #1
        sta lvdone
        rts
+       ldx psize
        bne +
        cmp g_t2
        bcc _r
        lda #1
        bne _grow
+       cpx #1
        bne _r
        cmp g_t3
        bcc _r
        lda #2
_grow   sta psize
        jsr set_pbox
        lda #SFX_GROW
        jsr sfx_start
        lda #<t_grow
        ldx #>t_grow
        jmp show_msg

t_grow  .null "YOU GREW!"
t_power .null "POWER BITE!"

; ---------------------------------------------------- clam with pearl
clam_update
        dec cl_t
        bne _touch
        ldx cl_st
        bne +
        lda #1                  ; closed -> opening
        sta cl_st
        lda #10
        sta cl_t
        rts
+       cpx #1
        bne +
        lda #2                  ; open with pearl
        sta cl_st
        lda #220
        sta cl_t
        rts
+       lda #0                  ; close
        sta cl_st
        jsr rnd
        and #127
        ora #128
        sta cl_t
        rts
_touch  lda cl_st
        cmp #2
        bne _r
        lda pstate
        bne _r
        lda cl_xl
        sta tmp0
        lda cl_xh
        sta tmp1
        lda #CLAM_Y
        sta tmp2
        ldy #K_CLAM
        jsr hit_box
        bcc _r
        lda #3
        sta cl_st
        lda #60
        sta cl_t
        lda #$50
        ldx #0
        jsr score_add
        lda #1
        sta hudflag
        lda #SFX_PEARL
        jsr sfx_start
        lda #<t_pearl
        ldx #>t_pearl
        jmp show_msg
_r      rts
t_pearl .null "PEARL +500"

; ---------------------------------------------------- sprite list output
; emit one sprite (exl/exh/ey/ep/ec) at list index X
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

; exl += 24
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

fish_emit
        ldy #N_FISH-1
_lp     lda f_k,y
        beq _nx
        sty fi
        lda f_xl,y
        sta exl
        lda f_xh,y
        sta exh
        lda f_y,y
        sta ey
        lda f_col,y
        sta ec
        tya
        asl
        asl
        asl
        adc frame
        lsr
        lsr
        lsr
        and #1
        sta tmp0
        lda f_k,y
        cmp #K_JELLY
        bne +
        lda frame
        lsr
        lsr
        lsr
        lsr
        and #1
        adc #SPR_JELLY
        sta ep
        jsr emit
        jmp _n2
+       cmp #K_PRED
        bne +
        lda tmp0
        asl
        adc f_spr,y
        sta ep
        jsr emit
        jsr emit_next
        jsr emit
        jmp _n2
+       lda tmp0
        clc
        adc f_spr,y
        sta ep
        jsr emit
_n2     ldy fi
_nx     dey
        bpl _lp
        rts

effects_emit
        ; clam
        lda cl_xl
        sta exl
        lda cl_xh
        sta exh
        lda #CLAM_Y
        sta ey
        lda cl_st
        clc
        adc #SPR_CLAM
        sta ep
        ldy zone
        lda clamcol,y
        sta ec
        jsr emit
        ; bursts
        ldy #1
_bl     lda bu_t,y
        beq _bn
        sec
        sbc #1
        sta bu_t,y
        beq _bn
        lda #12
        sec
        sbc bu_t,y
        lsr
        lsr
        cmp #3
        bcc +
        lda #2
+       clc
        adc #SPR_BURST
        sta ep
        lda bu_xl,y
        sta exl
        lda bu_xh,y
        sta exh
        lda bu_y,y
        sta ey
        lda #1
        sta ec
        jsr emit
_bn     dey
        bpl _bl
        rts
clamcol .byte 10,7,15
cl_xtab .byte 200,96,150
