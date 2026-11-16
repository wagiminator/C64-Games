; =====================================================================
;  Sprites, player, bullets, bunkers, UFO, capsules, HUD
; =====================================================================

; ---------------------------------------------------- sprite shadow -> VIC
write_sprites
        lda #0
        sta wsen
        sta wsmsb
        ldx #7
        ldy #14
_lp     lda spy,x
        beq _off
        sta $d001,y
        lda spx,x
        asl
        sta $d000,y
        bcc +
        lda wsmsb
        ora bittab,x
        sta wsmsb
+       lda wsen
        ora bittab,x
        sta wsen
        lda spc,x
        sta $d027,x
        lda spp,x
        sta SCRA+$3f8,x
_off    dey
        dey
        dex
        bpl _lp
        lda wsmsb
        sta $d010
        lda wsen
        sta $d015
        lda spexp
        sta $d017
        sta $d01d
        rts

sprites_off
        lda #0
        ldx #7
-       sta spy,x
        dex
        bpl -
        sta spexp
        rts

; ---------------------------------------------------- player
player_reset
        lda #88
        sta px
        lda #0
        sta pstate
        sta ptimer
        sta firecool
        sta pb_on
        sta pb_on+1
        lda #PLAYER_SY
        sta spy
        lda #SPR_PLAYER
        sta spp
        lda #13
        sta spc
        lda px
        sta spx
        rts

player_update
        lda pstate
        beq _alive
        inc ptimer
        lda ptimer
        lsr
        lsr
        lsr
        cmp #4
        bcc +
        lda #0
        sta spy
        rts
+       clc
        adc #SPR_PDIE
        sta spp
        lda #7
        sta spc
        rts
_alive  lda joy
        and #4
        beq +
        lda px
        cmp #17
        bcc +
        dec px
+       lda joy
        and #8
        beq +
        lda px
        cmp #160
        bcs +
        inc px
+       lda px
        sta spx
        lda #PLAYER_SY
        sta spy
        lda #SPR_PLAYER
        sta spp
        lda #13
        ldx cheat
        beq +
        lda frame
        and #4
        beq +
        lda #3
        bne ++
+       lda #13
+       sta spc
        ; fire
        lda firecool
        beq _cf
        dec firecool
        rts
_cf     lda joy
        and #$10
        beq _r
        lda power
        cmp #2
        beq _double
        ldx #0
        lda pb_on
        beq _fire1
        lda power
        beq _r
        inx
        lda pb_on+1
        bne _r
_fire1  lda px
        sta pb_x,x
        lda #216
        sta pb_y,x
        lda #1
        sta pb_on,x
        ldy power
        lda pbspeed,y
        sta pb_sp
        lda pbcool,y
        sta firecool
        lda #SFX_SHOOT
        jsr sfx_start
_r      rts
_double lda pb_on
        ora pb_on+1
        bne _r
        lda px
        sec
        sbc #4
        sta pb_x
        clc
        adc #8
        sta pb_x+1
        lda #216
        sta pb_y
        sta pb_y+1
        lda #1
        sta pb_on
        sta pb_on+1
        lda #6
        sta pb_sp
        lda #10
        sta firecool
        lda #SFX_LASER
        jsr sfx_start
        rts
pbspeed .byte 6,8,6
pbcool  .byte 10,7,10

player_die
        lda cheat
        bne _r
        lda pstate
        bne _r
        lda #1
        sta pstate
        lda #0
        sta ptimer
        sta pb_on
        sta pb_on+1
        lda #SFX_DEATH
        jsr sfx_start
_r      rts

; ---------------------------------------------------- player bullets
pb_update
        ldx #1
_lp     lda pb_on,x
        beq _off
        lda pb_y,x
        sec
        sbc pb_sp
        sta pb_y,x
        cmp #60
        bcc _kill
        stx pbi
        lda pb_x,x
        sec
        sbc #6
        sta tmp0
        lda pb_y,x
        sec
        sbc #44
        sta tmp1
        jsr pb_collide
        ldx pbi
        bcs _kill
        lda pb_x,x
        sta spx+1,x
        lda pb_y,x
        sta spy+1,x
        lda #SPR_BULLET
        sta spp+1,x
        lda #7
        sta spc+1,x
        jmp _nx
_kill   lda #0
        sta pb_on,x
_off    lda #0
        sta spy+1,x
_nx     dex
        bpl _lp
        rts

; tmp0 = screen x/2, tmp1 = screen y of bullet tip -> C=1 bullet used up
pb_collide
        lda bossmode
        beq +
        jsr boss_hit
        bcc _bk
        rts
+       jsr form_hit
        bcc _ufo
        jsr form_kill
        sec
        rts
_ufo    lda ufo_on
        beq _bk
        lda tmp1
        cmp #12
        bcc _bk
        cmp #24
        bcs _bk
        lda spx+7
        sec
        sbc #11
        sta tmp2
        lda tmp0
        sec
        sbc tmp2
        cmp #11
        bcs _bk
        jsr ufo_kill
        sec
        rts
_bk     jsr bunk_test
        bcs _hitb
        lda tmp1
        clc
        adc #3
        sta tmp1
        jsr bunk_test
        bcs _hitb
        clc
        rts
_hitb   lda #1
        jsr bunk_erode
        sec
        rts

; ---------------------------------------------------- alien bullets
alien_fire
        lda pstate
        bne _r
        lda firetimer
        beq +
        dec firetimer
_r      rts
+       jsr rnd
        and #15
        clc
        adc firebase
        sta firetimer
        ldx maxeb
        dex
-       lda eb_on,x
        beq _slot
        dex
        bpl -
        rts
_slot   stx ebi
        jsr form_shooter
        bcc _r
        ; X = row, Y = column
        txa
        asl
        clc
        adc fy
        cmp #INVADE_ROW
        bcs _r
        asl
        asl
        asl
        clc
        adc #54
        ldx ebi
        sta eb_y,x
        lda colx,y
        clc
        adc #9
        sta eb_x,x
        lda shotalt
        eor #1
        sta shotalt
        beq _zig
        ; plasma: faster, aimed from sector 2 on
        ldy sector
        lda pl_sp,y
        sta eb_sp,x
        lda pl_spf,y
        sta eb_spf,x
        lda #SPR_ABULLET+2
        sta eb_fr,x
        lda #0
        sta eb_vx,x
        lda sector
        beq +
        jsr aim_vx
        jmp +
_zig    ldy sector
        lda zg_sp,y
        sta eb_sp,x
        lda zg_spf,y
        sta eb_spf,x
        lda #SPR_ABULLET
        sta eb_fr,x
        lda #0
        sta eb_vx,x
+       lda #0
        sta eb_xf,x
        sta eb_yf,x
        lda #1
        sta eb_on,x
        lda #SFX_ESHOT
        jmp sfx_start

; alien bullet speeds per sector (pixels + 1/256 fraction per frame)
; sector 1 is gentler: plasma 2.5 (else 3), zigzag 1.75 (else 2 / 3)
pl_sp   .byte 2,3,3
pl_spf  .byte 128,0,0
zg_sp   .byte 1,2,3
zg_spf  .byte 192,0,0
bs_sp   .byte 1,2,2
bs_spf  .byte 192,0,0
ba_sp   .byte 2,3,3
ba_spf  .byte 128,0,0

; X = bullet slot -> eb_vx aimed at player
aim_vx
        lda px
        sec
        sbc eb_x,x
        bcc _neg
        cmp #21
        bcc +
        lda #21
+       sta tmp2
        asl
        adc tmp2
        asl
        sta eb_vx,x
        rts
_neg    eor #$ff
        adc #1
        cmp #21
        bcc +
        lda #21
+       sta tmp2
        asl
        adc tmp2
        asl
        eor #$ff
        clc
        adc #1
        sta eb_vx,x
        rts

eb_update
        ldx #2
_lp     lda eb_on,x
        bne +
        lda b_dead
        bne _nxj
        lda #0
        sta spy+3,x
_nxj    jmp _nx
+       lda eb_vx,x
        beq _ny
        clc
        adc eb_xf,x
        sta eb_xf,x
        lda eb_vx,x
        bmi _neg
        lda eb_x,x
        adc #0
        jmp _sx
_neg    lda eb_x,x
        adc #$ff
_sx     sta eb_x,x
        cmp #12
        bcc _kill
        cmp #172
        bcs _kill
_ny     lda eb_yf,x
        clc
        adc eb_spf,x
        sta eb_yf,x
        lda eb_y,x
        adc eb_sp,x
        sta eb_y,x
        cmp #221
        bcs _kill
        stx ebi
        lda eb_x,x
        sec
        sbc #6
        sta tmp0
        lda eb_y,x
        sec
        sbc #35
        sta tmp1
        jsr eb_collide
        ldx ebi
        bcs _kill
        lda eb_x,x
        sta spx+3,x
        lda eb_y,x
        sta spy+3,x
        lda frame
        lsr
        lsr
        and #1
        clc
        adc eb_fr,x
        sta spp+3,x
        lda #1
        sta spc+3,x
        jmp _nx
_kill   lda #0
        sta eb_on,x
        sta spy+3,x
_nx     dex
        bmi +
        jmp _lp
+       rts

eb_collide
        lda pstate
        bne _bk
        lda tmp1
        cmp #176
        bcc _bk
        cmp #186
        bcs _bk
        lda px
        sec
        sbc #12
        sta tmp2
        lda tmp0
        sec
        sbc tmp2
        cmp #11
        bcs _bk
        jsr player_die
        sec
        rts
_bk     jsr bunk_test
        bcs _hitb
        lda tmp1
        sec
        sbc #2
        sta tmp1
        jsr bunk_test
        bcs _hitb
        clc
        rts
_hitb   lda #0
        jsr bunk_erode
        sec
        rts

eb_clear
        ldx #2
        lda #0
-       sta eb_on,x
        sta spy+3,x
        dex
        bpl -
        rts

; ---------------------------------------------------- bunkers
; tmp0 = screen x/2, tmp1 = screen y -> C=1 if solid; bptr/bmask set
bunk_test
        lda tmp1
        cmp #ROW_BUNK*8
        bcc _no
        cmp #ROW_BUNK*8+16
        bcs _no
        lsr
        lsr
        lsr
        tax
        lda tmp0
        cmp #160
        bcs _no
        lsr
        lsr
        clc
        adc rowlo,x
        sta bptr
        lda rowhiA,x
        adc #0
        sta bptr+1
        ldy #0
        lda (bptr),y
        sec
        sbc #CH_BUNK
        cmp #24
        bcs _no
        adc #CH_BUNK
        sta bptr
        lda #0
        asl bptr
        rol
        asl bptr
        rol
        asl bptr
        rol
        adc #>CHARSET
        sta bptr+1
        lda tmp1
        and #7
        ora bptr
        sta bptr
        lda tmp0
        and #3
        tax
        lda pixmask,x
        sta bmask
        and (bptr),y
        beq _no
        sec
        rts
_no     clc
        rts
pixmask .byte $c0,$30,$0c,$03

; A = 0: crater grows downwards (alien shot), 1: upwards (player shot)
bunk_erode
        sta edir
        lda tmp0
        sta ex0
        lda tmp1
        sta ey0
        ldx #ERN-1
_lp     stx eidx
        lda ex0
        clc
        adc erx,x
        sta tmp0
        lda edir
        bne _up
        lda ey0
        clc
        adc ery,x
        jmp +
_up     lda ey0
        sec
        sbc ery,x
+       sta tmp1
        jsr bunk_test
        bcc +
        lda bmask
        eor #$ff
        and (bptr),y
        sta (bptr),y
+       ldx eidx
        dex
        bpl _lp
        ; one random speck
        jsr rnd
        and #3
        sec
        sbc #1
        clc
        adc ex0
        sta tmp0
        jsr rnd
        and #3
        clc
        adc ey0
        sbc #1
        sta tmp1
        jsr bunk_test
        bcc +
        lda bmask
        eor #$ff
        and (bptr),y
        sta (bptr),y
+       lda #SFX_BUNKER
        jmp sfx_start
erx     .byte 0,0,0,0,$ff,1,$ff,1,0,$ff,1
ery     .byte 0,1,2,3,0,0,1,2,4,3,3
ERN = 11

bk_ofs  .for b := 0, b < 4, b += 1
        .for j := 0, j < 2, j += 1
        .for i := 0, i < 3, i += 1
        .byte j*40 + (5,14,23,32)[b] + i
        .next
        .next
        .next

bunkers_reset
        ldx #0
-       lda bunker_orig,x
        sta CHARSET+CH_BUNK*8,x
        inx
        cpx #192
        bne -
        ldx #23
-       ldy bk_ofs,x
        txa
        clc
        adc #CH_BUNK
        sta SCRA+ROW_BUNK*40,y
        lda #5
        sta COLRAM+ROW_BUNK*40,y
        dex
        bpl -
        rts

; capsule S: rebuild, but never over aliens
bunkers_repair
        ldx #0
-       lda bunker_orig,x
        sta CHARSET+CH_BUNK*8,x
        inx
        cpx #192
        bne -
        ldx #23
-       ldy bk_ofs,x
        lda SCRA+ROW_BUNK*40,y
        cmp #CH_ALIEN
        bcc +
        cmp #CH_BUNK
        bcc _sk
+       txa
        clc
        adc #CH_BUNK
        sta SCRA+ROW_BUNK*40,y
        lda #5
        sta COLRAM+ROW_BUNK*40,y
_sk     dex
        bpl -
        rts

; ---------------------------------------------------- UFO & capsules
ufo_update
        lda bossmode
        bne _r
        lda cap_on
        beq +
        jmp cap_update
+       lda ufo_on
        bne _move
        inc ufo_tim
        bne +
        inc ufo_tim+1
+       lda ufo_tim+1
        cmp #4
        bcc _r
        lda nalive
        cmp #8
        bcc _r
        lda pstate
        bne _r
        jsr rnd
        and #$7f
        sta ufo_tim
        lda #0
        sta ufo_tim+1
        lda #1
        sta ufo_on
        jsr rnd
        and #1
        sta ufo_dir
        beq +
        lda #174
        bne ++
+       lda #0
+       sta spx+7
        lda #58
        sta spy+7
        lda #SPR_UFO
        sta spp+7
        lda #10
        sta spc+7
_r      rts
_move   lda ufo_dir
        bne _ml
        inc spx+7
        lda spx+7
        cmp #175
        bcs _gone
        bcc _anim
_ml     dec spx+7
        beq _gone
_anim   lda frame
        lsr
        lsr
        lsr
        and #1
        clc
        adc #SPR_UFO
        sta spp+7
        lda frame
        and #15
        bne +
        lda #SFX_UFO
        jsr sfx_start
+       rts
_gone   lda #0
        sta ufo_on
        sta spy+7
        rts

ufo_pts .byte $05,$10,$15,$30
ufo_txt .text " 50100150300"

ufo_kill
        lda #0
        sta ufo_on
        ; explosion at ufo
        lda spx+7
        sta spx+6
        lda #52
        sta spy+6
        lda #SPR_AEXPL
        sta spp+6
        lda #10
        sta spc+6
        lda #16
        sta ex_t
        jsr rnd
        and #3
        tay
        sta tmp3
        lda ufo_pts,y
        ldx #0
        jsr score_add
        ; popup text
        lda spx+7
        sec
        sbc #10
        bcs +
        lda #0
+       lsr
        lsr
        cmp #36
        bcc +
        lda #36
+       sta pop_col
        tay
        lda tmp3
        asl
        adc tmp3
        tax
        lda ufo_txt,x
        sta SCRA+40,y
        lda ufo_txt+1,x
        sta SCRA+41,y
        lda ufo_txt+2,x
        sta SCRA+42,y
        lda #7
        sta COLRAM+40,y
        sta COLRAM+41,y
        sta COLRAM+42,y
        lda #70
        sta pop_t
        lda #SFX_EXPLO
        jsr sfx_start
        ; capsule?
        lda #0
        sta spy+7
        jsr rnd
        cmp #160
        bcs _r
        jsr rnd
        and #7
        tay
        lda captab,y
        sta cap_t
        tay
        lda #SPR_CAPSULE
        clc
        adc cap_t
        sta spp+7
        lda capcol,y
        sta spc+7
        lda #56
        sta spy+7
        lda #1
        sta cap_on
_r      rts
captab  .byte 0,0,1,1,2,2,0,3           ; R R D D S S R +
capcol  .byte 10,14,5,7

cap_update
        inc spy+7
        lda spy+7
        cmp #222
        bcs _gone
        cmp #206
        bcc _r
        lda spx+7
        sec
        sbc px
        clc
        adc #9
        cmp #19
        bcs _r
        ; caught
        lda #0
        sta cap_on
        sta spy+7
        ldx cap_t
        beq _rapid
        dex
        beq _dbl
        dex
        beq _shield
        lda lives
        cmp #9
        bcs +
        inc lives
+       lda #1
        sta hudflag
        lda #SFX_EXTRA
        jmp sfx_start
_rapid  lda #1
        bne _pw
_dbl    lda #2
_pw     sta power
        lda #<750
        sta powtime
        lda #>750
        sta powtime+1
        lda #1
        sta statflag
        lda #SFX_POWERUP
        jmp sfx_start
_shield jsr bunkers_repair
        lda #SFX_POWERUP
        jmp sfx_start
_gone   lda #0
        sta cap_on
        sta spy+7
_r      rts

; ---------------------------------------------------- misc per-frame
misc_update
        lda marchcool
        beq +
        dec marchcool
+       lda bossmode
        bne _pop
        lda ex_t
        beq _pop
        dec ex_t
        bne +
        lda #0
        sta spy+6
        beq _pop
+       lda #16
        sec
        sbc ex_t
        lsr
        lsr
        clc
        adc #SPR_AEXPL
        sta spp+6
_pop    lda pop_t
        beq _pow
        dec pop_t
        bne _pow
        lda pop_col
        sta ftmp0
        clc
        adc #2
        sta ftmp1
        ldx #1
        jsr bg_fill
_pow    lda power
        beq _r
        lda powtime
        bne +
        dec powtime+1
+       dec powtime
        lda powtime
        ora powtime+1
        bne +
        sta power
        lda #1
        sta statflag
        lda #SFX_MENU
        jmp sfx_start
+       lda frame
        and #15
        bne _r
        lda #1
        sta statflag
_r      rts

; ---------------------------------------------------- HUD
hud_static
        #print t_hscore, 0, 0, 3
        #print t_hhi, 15, 0, 3
        #print t_hwave, 30, 0, 3
        lda #CH_LIFE
        sta SCRA+24*40
        lda #5
        sta COLRAM+24*40
        lda #1
        sta hudflag
        sta statflag
        rts
t_hscore .null "SCORE"
t_hhi   .null "HI"
t_hwave .null "WAVE"

; A = BCD, Y = screen offset (row 0) -> two digits
put_bcd pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRA,y
        lda #1
        sta COLRAM,y
        iny
        pla
        and #15
        ora #48
        sta SCRA,y
        lda #1
        sta COLRAM,y
        iny
        rts

hud_update
        lda hudflag
        bne +
        jmp _st
+
        lda #0
        sta hudflag
        ldy #6
        lda score+2
        jsr put_bcd
        lda score+1
        jsr put_bcd
        lda score
        jsr put_bcd
        lda #48
        sta SCRA,y
        lda #1
        sta COLRAM,y
        ; hi = max(table top, score)
        lda hiscores+3
        sta tmp3
        lda hiscores+4
        sta tmp4
        lda hiscores+5
        sta tmp5
        lda score+2
        cmp tmp5
        bcc _tab
        bne _sc
        lda score+1
        cmp tmp4
        bcc _tab
        bne _sc
        lda score
        cmp tmp3
        bcc _tab
_sc     lda score
        sta tmp3
        lda score+1
        sta tmp4
        lda score+2
        sta tmp5
_tab    ldy #18
        lda tmp5
        jsr put_bcd
        lda tmp4
        jsr put_bcd
        lda tmp3
        jsr put_bcd
        lda #48
        sta SCRA,y
        lda #1
        sta COLRAM,y
        ; wave s-w
        lda sector
        clc
        adc #49
        sta SCRA+35
        lda #45
        sta SCRA+36
        lda wave
        clc
        adc #49
        ldx bossmode
        beq +
        lda #2                  ; 'B'
+       sta SCRA+37
        lda #1
        sta COLRAM+35
        sta COLRAM+36
        sta COLRAM+37
        ; lives
        lda lives
        ora #48
        sta SCRA+24*40+1
        lda #1
        sta COLRAM+24*40+1
_st     lda statflag
        bne +
        rts
+       lda #0
        sta statflag
        ; clear status area cols 4..39
        ldx #35
        lda #32
-       sta SCRA+24*40+4,x
        dex
        bpl -
        lda bossmode
        beq _pw
        #print t_boss, 6, 24, 2
        lda b_hp
        sta tmp0
        lda #2
        sta tmp1
        jmp _bar
_pw     lda power
        bne +
        rts
+       cmp #1
        bne +
        #print t_rapid, 6, 24, 7
        jmp ++
+       #print t_double, 6, 24, 3
+       lda powtime+1
        sta tmp0
        lda powtime
        asl
        rol tmp0
        asl
        rol tmp0
        asl
        rol tmp0                ; tmp0 = powtime / 32 (0..23)
        lda #7
        sta tmp1
        ; bar: tmp0 = quarters, from col 18
_bar    ldx #0
-       lda tmp0
        beq _e
        cmp #4
        bcc _p
        sbc #4
        sta tmp0
        lda #CH_BAR+4
        jmp _s
_p      clc
        adc #CH_BAR
        ldy #0
        sty tmp0
_s      sta SCRA+24*40+18,x
        lda tmp1
        sta COLRAM+24*40+18,x
        inx
        cpx #20
        bne -
_e      rts
t_boss  .null "MOTHERSHIP"
t_rapid .null "RAPID FIRE"
t_double .null "DOUBLE SHOT"
