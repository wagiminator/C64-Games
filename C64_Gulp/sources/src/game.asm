; =====================================================================
;  Game flow: zones, levels, boss levels, lives, pause, cheat keys
; =====================================================================
KEY_P = 41
KEY_N = 39
KEY_STOP = 63
BANNER_ROW = 12

new_game
        lda #0
        sta score
        sta score+1
        sta score+2
        sta nextext
        sta nextext+2
        sta lvl
        lda #$10
        sta nextext+1
        lda #3
        sta lives
        lda startlevel
        sta zone

zone_start
        lda zone
        sta level
        jsr level_intro

level_start
        jsr play_setup
        jsr level_banner
        jmp play_loop

; ---------------------------------------------------- set up a level
play_setup
        lda #$0b
        sta $d011
        jsr music_stop
        jsr irq_game_on
        lda #1
        jsr clear_screen
        jsr draw_scene
        jsr hud_static
        ldx zone
        lda zone_bg,x
        sta zbg
        lda zone_d022,x
        sta $d022
        lda zone_d023,x
        sta $d023
        lda #0
        cpx #2
        bne +
        lda #11
+       sta $d025
        ldx #3
-       lda pat_speed_game,x
        sta pat_speed,x
        dex
        bpl -
        ; level parameters
        lda zone
        asl
        adc zone
        adc lvl
        sta lvidx
        tay
        lda lv_t2,y
        sta g_t2
        lda lv_t3,y
        sta g_t3
        lda lv_goal,y
        sta g_goal
        jsr fish_clear
        lda #0
        sta b_on
        sta lvdone
        sta power
        sta combo
        sta combo_t
        sta msg_t
        sta skipflag
        sta growth
        sta psize
        lda #1
        sta mult
        lda #60
        sta spawn_t
        ldx zone
        lda cl_xtab,x
        sta cl_xl
        lda #0
        sta cl_xh
        sta cl_st
        lda #200
        sta cl_t
        lda lvl
        cmp #2
        bne +
        lda g_t3
        sta growth
        lda #2
        sta psize
        jsr boss_start
+       jsr player_reset
        lda #1
        sta hudflag
        sta barflag
        jsr hud_update
        lda lvl
        cmp #2
        bne +
        lda #TUNE_BOSS
        bne ++
+       lda zone
        clc
        adc #TUNE_REEF
+       jsr music_start
        lda #$ff
        sta lastkey
        jsr build_list
        jsr waitframe
        lda #$1b
        sta $d011
        rts

; ---------------------------------------------------- draw seabed scenery for the zone
draw_scene
        ldx zone
        lda scen_chars_lo,x
        sta ptr0
        lda scen_chars_hi,x
        sta ptr0+1
        lda #<(CHARSET+CH_SCEN*8)
        sta ptr1
        lda #>(CHARSET+CH_SCEN*8)
        sta ptr1+1
        ldx #4
        ldy #0
-       lda (ptr0),y
        sta (ptr1),y
        iny
        bne -
        inc ptr0+1
        inc ptr1+1
        dex
        bne -
        ; surface waves on row 2
        ldx #39
-       txa
        and #1
        ora #CH_BG+6
        sta SCRA+80,x
        lda #1
        sta COLRAM+80,x
        dex
        bpl -
        ; map rows 3..24
        ldx zone
        lda scen_map_lo,x
        sta ptr0
        lda scen_map_hi,x
        sta ptr0+1
        lda scen_col_lo,x
        sta ptr2
        lda scen_col_hi,x
        sta ptr2+1
        lda zone_plank,x
        sta tmp6
        lda #<(SCRA+120)
        sta ptr1
        lda #>(SCRA+120)
        sta ptr1+1
        lda #<(COLRAM+120)
        sta ptr3
        lda #>(COLRAM+120)
        sta ptr3+1
        lda #<880
        sta tmp4
        lda #>880
        sta tmp5
        lda #0
        sta tmp7
_lp     ldy #0
        lda (ptr0),y
        inc ptr0
        bne +
        inc ptr0+1
+       cmp #$80
        bcs _water
        sta tmp3
        tay
        lda (ptr2),y
        ldy #0
        sta (ptr3),y
        lda tmp3
        clc
        adc #CH_SCEN
        sta (ptr1),y
        jsr _adv
        jmp _chk
_water  and #$7f
        sta tmp3
-       lda tmp7
        clc
        adc #37
        sta tmp7
        and #63
        tay
        lda sparse,y
        beq +
        lda tmp7
        and #1
        ora #CH_PLK
        bne ++
+       lda #32
+       ldy #0
        sta (ptr1),y
        lda tmp6
        sta (ptr3),y
        jsr _adv
        dec tmp3
        bne -
        jmp _chk
_chk    lda tmp4
        ora tmp5
        bne _lp
        rts
_adv    inc ptr1
        bne +
        inc ptr1+1
+       inc ptr3
        bne +
        inc ptr3+1
+       lda tmp4
        bne +
        dec tmp5
+       dec tmp4
        rts

; ---------------------------------------------------- banners (row 12, saved/restored)
banner_show                     ; ptr0 = text, A = colour
        sta tmp2
        ldx #39
-       lda SCRA+BANNER_ROW*40,x
        sta bansave,x
        lda COLRAM+BANNER_ROW*40,x
        sta bancsave,x
        lda #32
        sta SCRA+BANNER_ROW*40,x
        dex
        bpl -
        lda #BANNER_ROW
        sta tmp1
        jmp print_centre
banner_clear
        ldx #39
-       lda bansave,x
        sta SCRA+BANNER_ROW*40,x
        lda bancsave,x
        sta COLRAM+BANNER_ROW*40,x
        dex
        bpl -
        rts
; A = frames to wait
banner_wait
        sta tmp7
-       jsr waitframe
        dec tmp7
        bne -
        rts

level_banner
        lda zone
        clc
        adc #49
        sta t_lvl+6
        lda lvl
        clc
        adc #49
        cmp #51
        bne +
        lda #2
+       sta t_lvl+8
        lda #<t_lvl
        sta ptr0
        lda #>t_lvl
        sta ptr0+1
        lda #7
        jsr banner_show
        lda #110
        jsr banner_wait
        jsr banner_clear
        lda lvl
        cmp #2
        bne +
        ldx zone
        lda bossname_lo,x
        sta ptr0
        lda bossname_hi,x
        sta ptr0+1
        lda #2
        jsr banner_show
        lda #100
        jsr banner_wait
        jsr banner_clear
+       rts
t_lvl   .null "LEVEL 1-1   GET READY!"

; ---------------------------------------------------- input
read_input
        jsr joyread
        sta joy
        lda DBGAI
        beq +
        jsr ai_joy
+
        jsr scan_key
        cmp lastkey
        beq _r
        sta lastkey
        cmp #KEY_P
        bne +
        jmp pause_game
+       ldx cheat
        beq _r
        cmp #KEY_N
        bne _r
        lda #1
        sta skipflag
_r      rts

pause_game
        lda #<t_pause
        sta ptr0
        lda #>t_pause
        sta ptr0+1
        lda #1
        jsr banner_show
-       jsr waitframe
        jsr scan_key
        cmp #$ff
        bne -
-       jsr waitframe
        jsr scan_key
        cmp #KEY_STOP
        bne +
        jmp quit_game
+       cmp #KEY_P
        bne -
        sta lastkey
        jmp banner_clear
t_pause .null "PAUSE - P: GO ON  RUN/STOP: QUIT"

quit_game
        ldx #$ff
        txs
        jsr music_stop
        jmp title_screen

; ---------------------------------------------------- per-frame timers
timers
        lda combo_t
        beq +
        dec combo_t
        bne +
        lda #0
        sta combo
        lda #1
        sta mult
        sta barflag
+       lda power
        beq +
        lda frame
        and #1
        bne +
        dec power
        bne +
        lda g_t3
        sta growth
        lda #1
        sta barflag
+       lda msg_t
        beq +
        dec msg_t
        bne +
        lda #1
        sta barflag
+       rts

build_list
        ldx #0
        jsr player_emit
        jsr boss_emit
        jsr fish_emit
        jsr effects_emit
        stx nactive
        jmp sort_sprites

; ---------------------------------------------------- main loop
play_loop
        jsr waitframe
        lda frame
        sta lagf
        jsr read_input
        lda skipflag
        beq +
        lda #0
        sta skipflag
        lda lvl
        cmp #2
        bne _skip
        lda b_dead
        bne +
        lda #0
        sta b_hp
        lda #150
        sta b_dead
        lda #SFX_BIGEXPLO
        jsr sfx_start
        jmp +
_skip   lda #1
        sta lvdone
+       jsr player_update
        jsr boss_update
        jsr fish_spawn
        jsr fish_update
        jsr clam_update
        jsr timers
        jsr hud_update
        jsr build_list
        lda frame
        cmp lagf
        beq +
        inc lagcnt
+       lda lvdone
        beq +
        jmp level_clear
+       lda pstate
        cmp #1
        bne play_loop
        lda ptimer
        cmp #110
        bcc play_loop
        ; life lost
        dec lives
        lda #1
        sta hudflag
        lda lives
        bne +
        jmp end_game
+       jsr player_reset
        lda b_on
        beq +
        lda b_dead
        bne +
        lda #100
        sta b_flee
        lda #0
        sta b_t
        lda b_xh
        bne _bfr
        lda b_xl
        cmp #148
        bcs _bfr
        lda #1
        bne _bfs
_bfr    lda #0
_bfs    sta b_dir
+       jmp play_loop

end_game
        lda #60
        jsr banner_wait
        jsr music_stop
        jmp game_over

level_clear
        jsr music_stop
        lda #TUNE_CLEAR
        jsr music_start
        lda #$00
        ldx #$01
        jsr score_add           ; bonus 1000
        lda #1
        sta hudflag
        jsr hud_update
        lda #<t_clear
        sta ptr0
        lda #>t_clear
        sta ptr0+1
        lda #7
        jsr banner_show
        lda #160
        jsr banner_wait
        jsr music_stop
        inc lvl
        lda lvl
        cmp #3
        beq +
        jmp level_start
+       lda #0
        sta lvl
        inc zone
        lda zone
        cmp #3
        bcs +
        jmp zone_start
+       jmp ending
t_clear .null "LEVEL CLEAR!  BONUS 1000"

bossname_lo .byte <t_boss1,<t_boss2,<t_boss3
bossname_hi .byte >t_boss1,>t_boss2,>t_boss3
t_boss1 .null "BEWARE OF BIG BRUTUS!"
t_boss2 .null "BEWARE OF THE GIANT OCTOPUS!"
t_boss3 .null "BEWARE OF THE LANTERN BEAST!"

lvname_tab .word lvname0, lvname1, lvname2
lvname0 .null "THE CORAL REEF"
lvname1 .null "THE KELP FOREST"
lvname2 .null "THE DEEP SEA"

; ---------------------------------------------------- test autopilot (only if DBGAI <> 0)
DBGAI = $03fd
ai_joy
        lda #$ff
        sta tmp6                ; best distance
        sta tmp7                ; best index
        lda #0
        sta tmp5                ; danger flags
        ldx #N_FISH-1
_lp     lda f_k,x
        beq +
        jsr ai_one
+       dex
        bpl _lp
        ; boss
        lda b_on
        beq _nob
        lda b_dead
        bne _nob
        lda power
        bne _hunt
        lda b_xl
        sec
        sbc pxl
        lda b_xh
        sbc pxh
        bmi +
        lda tmp5
        ora #4
        bne ++
+       lda tmp5
        ora #8
+       sta tmp5
        jmp _nob
_hunt   lda b_xl
        clc
        adc #12
        sta tmp0
        lda b_xh
        adc #0
        sta tmp1
        lda b_y
        clc
        adc #12
        sta tmp2
        jmp _steer
_nob    lda tmp5
        beq +
        sta joy
        rts
+       ldx tmp7
        bmi _home
        lda f_xl,x
        sta tmp0
        lda f_xh,x
        sta tmp1
        lda f_y,x
        sta tmp2
_steer  lda #0
        sta joy
        lda tmp0
        sec
        sbc pxl
        sta cdx
        lda tmp1
        sbc pxh
        bmi _l
        bne _rgt
        lda cdx
        cmp #4
        bcc _v
_rgt    lda #8
        bne _sx
_l      lda cdx
        cmp #$fc
        bcs _v
        lda #4
_sx     sta joy
_v      lda tmp2
        sec
        sbc py
        bcc _up
        cmp #3
        bcc _r
        lda joy
        ora #2
        sta joy
_r      rts
_up     cmp #$fd
        bcs _r
        lda joy
        ora #1
        sta joy
        rts
_home   lda #<160
        sta tmp0
        lda #0
        sta tmp1
        lda #130
        sta tmp2
        jmp _steer

ai_one
        ; dx (clamped) -> cdx signed, adx = |dx|
        lda f_xl,x
        sec
        sbc pxl
        sta cdx
        lda f_xh,x
        sbc pxh
        beq _pos
        cmp #$ff
        bne _nx
        lda cdx
        cmp #$81
        bcc _nx
        eor #$ff
        adc #0
        jmp _ax
_pos    lda cdx
        bmi _nx
_ax     sta tmp3                ; |dx|
        lda f_y,x
        sec
        sbc py
        sta cdy
        bcs +
        eor #$ff
        adc #1
+       sta tmp4                ; |dy|
        ; edible?
        ldy f_k,x
        cpy #K_JELLY
        beq _dang
        lda ktier,y
        sec
        sbc #1
        cmp psize
        beq _food
        bcc _food
_dang   lda tmp3
        cmp #60
        bcs _nx
        lda tmp4
        cmp #34
        bcs _nx
        lda cdx
        bmi +
        lda tmp5
        ora #4                  ; danger right -> go left
        bne ++
+       lda tmp5
        ora #8
+       sta tmp5
        lda cdy
        bmi +
        lda tmp5
        ora #1
        bne ++
+       lda tmp5
        ora #2
+       sta tmp5
        rts
_food   lda tmp3
        lsr
        clc
        adc tmp4
        bcs _nx
        cmp tmp6
        bcs _nx
        sta tmp6
        stx tmp7
_nx     rts
