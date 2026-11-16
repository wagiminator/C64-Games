; =====================================================================
;  Game flow: levels, wave director, banners, win / lose, pause, cheat
; =====================================================================
KEY_P = 41
KEY_N = 39
KEY_STOP = 63
BANNER_ROW = 13

;               L1  L2  L3  L4  L5  L6  L7  L8  L9  L10
lv_r    .byte    6,  8, 11, 14, 16, 18, 20, 20, 22,  0
lv_b1   .byte    0,  0,  4,  5,  6,  6,  7,  8,  8,  0
lv_b2   .byte    3,  4,  6,  7,  8,  9, 10, 10, 12,  0
lv_int  .byte   75, 65, 55, 48, 45, 42, 40, 38, 36, 40
lv_first .byte 200,170,140,120,110,100, 90, 90, 90, 60
lv_area .byte    0,  0,  0,  0,  1,  1,  1,  2,  2,  2
lv_w    .byte 255,255,255,255
        .byte 180,255,255,255
        .byte 150,230,255,255
        .byte 130,200,230,255
        .byte 120,190,225,255
        .byte 110,180,225,255
        .byte 110,180,220,255
        .byte 100,170,215,255
        .byte  90,160,210,255
        .byte 200,255,255,255
area_bg  .byte 13, 13, 11
area_d022 .byte 5, 12, 5
area_tune .byte TUNE_DAY, TUNE_DUSK, TUNE_NIGHT
area_sun .byte $00, $75, $00
area_sunh .byte $01, $00, $01

new_game
        lda #0
        sta score
        sta score+1
        sta score+2
        sta nextext
        sta nextext+2
        lda #$10
        sta nextext+1
        lda #3
        sta lives
        lda startlevel
        sta level

level_start
        ldx level
        lda lv_area,x
        sta area
        jsr level_intro
        jsr play_setup
        lda #<t_ready1
        ldx #>t_ready1
        jsr banner_show
        lda #100
        jsr banner_wait
        jsr banner_clear
        jmp play_loop
t_ready1 .null "READY... SET... PLANT!"

; ---------------------------------------------------- set up a level
play_setup
        lda #$0b
        sta $d011
        jsr music_stop
        jsr irq_game_on
        lda #1
        jsr clear_screen
        ldx area
        lda area_bg,x
        sta lawnbg
        lda area_d022,x
        sta $d022
        lda #0
        sta pat_speed
        sta pat_speed+1
        sta pat_speed+2
        sta pat_speed+3
        lda #0
        sta $d023
        ; clear state
        ldx #44
        lda #0
-       sta g_type,x
        dex
        bpl -
        ldx #39
-       sta pe_x,x
        dex
        bpl -
        ldx #N_Z-1
-       sta z_t,x
        dex
        bpl -
        ldx #N_SUN-1
-       sta su_on,x
        dex
        bpl -
        ldx #6
-       sta pk_cd,x
        dex
        bpl -
        ldx #4
-       sta mw_st,x
        sta lz_cnt,x
        dex
        bpl -
        sta nzomb
        sta held
        sta lvdone
        sta lost
        sta skipflag
        sta ex_t
        sta bo_on
        sta msg_t
        sta sp_n
        sta sp_all
        sta sp_ph
        sta cur_lc
        sta cur_bc
        sta cur_c
        sta lastdir
        sta firelast
        lda #3
        sta cur_r
        sta cur_lr
        ; sun
        ldx area
        lda area_sun,x
        sta sun
        lda area_sunh,x
        sta sun+1
        lda cheat
        beq +
        lda #$90
        sta sun
        lda #$99
        sta sun+1
+       lda #<200
        sta skysun_t
        lda #1
        sta skysun_t+1
        ; packets unlocked
        lda level
        clc
        adc #2
        cmp #7
        bcc +
        lda #6
+       sta npack
        ; director
        ldx level
        lda lv_r,x
        clc
        adc lv_b1,x
        adc lv_b2,x
        sta sp_tot
        lda lv_first,x
        sta sp_t
        lda #0
        sta sp_t+1
        ; draw the lawn
        ldx #44
-       jsr draw_cell
        dex
        bpl -
        ldx #4
-       stx tmp6
        txa
        jsr draw_patio
        ldx tmp6
        dex
        bpl -
        jsr hud_static
        lda level
        cmp #9
        bne +
        jsr boss_start
        lda #6
        sta sp_ph
        lda #TUNE_BOSS
        bne ++
+       ldx area
        lda area_tune,x
+       jsr music_start
        lda #$ff
        sta lastkey
        jsr hud_update
        jsr lane_lists
        jsr build_list
        jsr waitframe
        lda #$1b
        sta $d011
        rts

; ---------------------------------------------------- wave director
director
        lda sp_ph
        cmp #6
        bcc +
        rts
+       ; timer in units of 8 frames (bursts: frames)
        cmp #3
        beq _bj
        cmp #5
        bne +
_bj     jmp _burst
+       lda frame
        and #7
        beq +
        rts
+       dec sp_t
        beq +
        rts
+
        lda sp_ph
        beq _start
        cmp #1
        beq _reg
        ; 2 or 4: announcement over -> burst
        inc sp_ph
        lda #10
        sta sp_t
        ldx level
        lda sp_ph
        cmp #3
        bne +
        lda lv_b1,x
        bne ++
+       lda lv_b2,x
+       sta sp_burst
        rts
_start  lda #1
        sta sp_ph
        lda #1
        sta sp_t
        lda #SFX_GROAN
        jmp sfx_start
_reg    lda nzomb
        cmp #11
        bcc +
        lda #4
        sta sp_t
        rts
+       jsr spawn_one
        inc sp_n
        ldx level
        jsr rnd
        and #15
        clc
        adc lv_int,x
        sta sp_t
        ; second zombie now and then in later levels
        lda level
        cmp #3
        bcc +
        jsr rnd
        cmp #60
        bcs +
        lda sp_n
        cmp lv_r,x
        bcs +
        jsr spawn_one
        inc sp_n
+       ldx level
        lda lv_r,x
        lsr
        cmp sp_n
        bne +
        lda lv_b1,x
        beq +
        lda #2
        sta sp_ph
        lda #18
        sta sp_t
        lda #<t_huge
        ldx #>t_huge
        jmp announce
+       ldx level
        lda sp_n
        cmp lv_r,x
        bcc _r
        lda #4
        sta sp_ph
        lda #18
        sta sp_t
        lda #<t_final
        ldx #>t_final
        jmp announce
_r      rts
_burst  dec sp_t
        bne _r
        lda #12
        sta sp_t
        lda nzomb
        cmp #11
        bcs _r
        jsr spawn_one
        dec sp_burst
        bne _r
        lda sp_ph
        cmp #3
        bne +
        lda #1
        sta sp_ph
        ldx level
        lda lv_int,x
        sta sp_t
        rts
+       lda #6
        sta sp_ph
        rts

spawn_one
        ldx level
        txa
        asl
        asl
        tay
        jsr rnd
        ldx #Z_WALK
-       cmp lv_w,y
        bcc +
        beq +
        iny
        inx
        cpx #Z_RUN
        bne -
+       txa
        ldy #$ff
        jsr zombie_spawn
        inc sp_all
        rts

announce
        sta ptr0
        stx ptr0+1
        lda #SFX_SIREN
        jsr sfx_start
        lda #2
        ldx area
        cpx #2
        bne +
        lda #7
+       jsr banner_text
        lda #140
        sta msg_t
        rts
t_huge  .null "A HUGE WAVE IS COMING!"
t_final .null "FINAL WAVE!"

; ---------------------------------------------------- banner on row 13
banner_show                     ; A/X = text (colour 0)
        sta ptr0
        stx ptr0+1
        lda #0
        ldx area
        cpx #2
        bne banner_text
        lda #1
banner_text                     ; ptr0 = text, A = colour
        sta tmp2
        ldx #39
        lda #32
-       sta SCRA+BANNER_ROW*40,x
        dex
        bpl -
        lda #BANNER_ROW
        sta tmp1
        jmp print_centre
banner_clear                    ; redraw lane 2 (rows 12..15)
        lda #2
        jmp draw_lane
banner_wait
        sta tmp7
-       jsr waitframe
        dec tmp7
        bne -
        rts

msg_tick
        lda msg_t
        beq +
        dec msg_t
        bne +
        jsr banner_clear
+       rts

; ---------------------------------------------------- input
read_input
        jsr joyread
        sta joy
        lda DBGAI
        beq +
        jsr ai_joy
+       jsr scan_key
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
DBGAI = $03fd

pause_game
        lda #<t_pause
        ldx #>t_pause
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

; ---------------------------------------------------- main loop
play_loop
        jsr waitframe
        lda frame
        sta lagf
        jsr read_input
        lda skipflag
        beq +
        jsr skip_level
+       #PROF 0
        jsr cursor_update
        jsr packets_tick
        jsr sky_sun
        #PROF 1
        jsr lane_lists
        #PROF 2
        jsr plants_tick
        #PROF 3
        jsr peas_update
        #PROF 4
        jsr zombies_update
        #PROF 5
        jsr mowers_update
        jsr boss_update
        jsr director
        jsr suns_update
        #PROF 6
        jsr anim_plants
        jsr msg_tick
        lda cheat
        beq +
        lda #$90
        sta sun
        lda #$99
        sta sun+1
+       jsr hud_update
        #PROF 7
        jsr build_list
        #PROF 8
        lda frame
        cmp lagf
        beq +
        inc lagcnt
+       lda lost
        beq +
        jmp level_lost
+       lda sp_ph
        cmp #6
        bcc +
        lda nzomb
        ora bo_on
        bne +
        jmp level_clear
+       jmp play_loop

skip_level
        lda #0
        sta skipflag
        ldx #N_Z-1
-       lda z_t,x
        beq +
        jsr zombie_kill
+       dex
        bpl -
        lda #6
        sta sp_ph
        lda bo_on
        beq +
        lda #255
        jsr boss_damage
        lda #255
        jsr boss_damage
+       rts

level_clear
        lda #60
        jsr banner_wait
        jsr music_stop
        lda #TUNE_CLEAR
        jsr music_start
        ; bonus 1000 + 500 per unused mower
        lda #0
        ldx #$01
        jsr score_add
        ldx #4
-       lda mw_st,x
        bne +
        stx tmp6
        lda #$50
        ldx #0
        jsr score_add
        ldx tmp6
+       dex
        bpl -
        lda #1
        sta hudflag
        jsr hud_update
        lda #<t_clear
        ldx #>t_clear
        jsr banner_show
        lda #200
        jsr banner_wait
        jsr music_stop
        inc level
        lda level
        cmp #10
        bcs +
        jmp level_start
+       jmp ending
t_clear .null "LEVEL CLEAR!  GARDEN SAVED!"

level_lost
        jsr music_stop
        lda #SFX_DEATH
        jsr sfx_start
        lda #<t_lost
        ldx #>t_lost
        jsr banner_show
        lda #200
        jsr banner_wait
        dec lives
        lda #1
        sta hudflag
        lda lives
        beq +
        jmp level_start
+       jmp game_over
t_lost  .null "THE UNDEAD REACHED YOUR HOUSE!"

lvname_tab .word lvname0, lvname1, lvname2
lvname0 .null "A SUNNY DAY IN THE GARDEN"
lvname1 .null "DUSK - FEWER SUNS FROM THE SKY"
lvname2 .null "NIGHT - ONLY YOUR SUNBLOOMS SHINE"

; ---------------------------------------------------- test autopilot (DBGAI <> 0)
; plan: column 0 sunblooms, then spitters, twinspits, rocknuts (col 6), frostpods
ai_joy
        lda #0
        sta joy
        lda frame
        and #3
        beq +
        rts
+       lda ai_tr
        bpl _go
        jsr ai_plan
        lda ai_tr
        bpl _go
        rts
_go     lda cur_r
        cmp ai_tr
        beq _col
        bcc +
        lda #1
        sta joy
        rts
+       lda #2
        sta joy
        rts
_col    lda cur_c
        cmp ai_tc
        beq _at
        bcc +
        lda #4
        sta joy
        rts
+       lda #8
        sta joy
        rts
_at     lda ai_pr
        bne _rel
        lda #16
        sta joy
        lda #1
        sta ai_pr
        rts
_rel    lda #0
        sta ai_pr
        lda cur_r
        bne _done
        lda ai_cr               ; packet taken -> go to the cell
        sta ai_tr
        lda ai_cc
        sta ai_tc
        rts
_done   lda #$ff
        sta ai_tr
        rts
ai_tr   .byte $ff
ai_tc   .byte 0
ai_cr   .byte 0
ai_cc   .byte 0
ai_pr   .byte 0

ai_plan
        ldx #N_SUN-1
-       lda su_on,x
        beq +
        lda su_lane,x
        clc
        adc #1
        sta ai_tr
        lda su_col,x
        sta ai_tc
        rts
+       dex
        bpl -
        ldy #0
_pl     lda ai_order,y
        cmp #$ff
        beq _none
        tax
        lda g_type,x
        bne _nx
        lda ai_ptype,y
        sec
        sbc #1
        cmp npack
        bcs _nx
        tax
        lda pk_cd,x
        bne _none
        jsr can_afford
        bcc _none
        stx ai_tc
        lda #0
        sta ai_tr
        lda ai_order,y
        tax
        lda cell_lane,x
        clc
        adc #1
        sta ai_cr
        lda cell_col,x
        sta ai_cc
        rts
_nx     iny
        bne _pl
_none   rts
ai_order .byte 18,9,19,27,10,28,0,36,1,37,20,11,29,2,38,24,15,33,6,42,21,12,30,3,39,20,11,29,2,38,$ff
ai_ptype .byte 1,1,2,1,2,2,1,1,2,2,6,6,6,6,6,3,3,3,3,3,5,5,5,5,5,2,2,2,2,2

PROF    .macro n
        .if PROFILE
        ldx #\n
        jsr prof_stamp
        .fi
        .endm
        .if PROFILE
prof_stamp
        lda $dd05
        sta prof_ch
        lda $dd04
        sta prof_cl
        lda $dd05
        cmp prof_ch
        beq +
        sta prof_ch
        lda #$ff
        sta prof_cl
+       cpx #0
        beq _set
        lda nzomb
        cmp #10
        bcc _set
        ; delta = last - cur
        lda prof_ll
        sec
        sbc prof_cl
        sta tmp0
        lda prof_lh
        sbc prof_ch
        sta tmp1
        lda prof_s0,x
        clc
        adc tmp0
        sta prof_s0,x
        lda prof_s1,x
        adc tmp1
        sta prof_s1,x
        lda prof_s2,x
        adc #0
        sta prof_s2,x
        cpx #8
        bne _set
        inc prof_n
        bne _set
        inc prof_n+1
_set    lda prof_cl
        sta prof_ll
        lda prof_ch
        sta prof_lh
        rts
prof_cl .byte 0
prof_ch .byte 0
prof_ll .byte 0
prof_lh .byte 0
prof_n  .word 0
prof_s0 .fill 10
prof_s1 .fill 10
prof_s2 .fill 10
        .fi
