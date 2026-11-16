; =====================================================================
;  Game flow: sectors, waves, boss stage, lives, pause, cheat keys
; =====================================================================
KEY_P = 41
KEY_N = 39
KEY_STOP = 63
BANNER_ROW = 20

new_game
        lda #0
        sta score
        sta score+1
        sta score+2
        sta nextext
        sta nextext+2
        sta wave
        sta power
        sta powtime
        sta powtime+1
        lda #$20
        sta nextext+1
        lda #3
        sta lives
        lda startlevel
        sta sector

sector_start
        lda sector
        sta level
        jsr level_intro
        ; load this sector's alien designs
        ldx sector
        lda alienset_lo,x
        sta ptr0
        lda alienset_hi,x
        sta ptr0+1
        lda #<(CHARSET+CH_ALIEN*8)
        sta ptr1
        lda #>(CHARSET+CH_ALIEN*8)
        sta ptr1+1
        ldx #3
        ldy #0
-       lda (ptr0),y
        sta (ptr1),y
        iny
        bne -
        inc ptr0+1
        inc ptr1+1
        dex
        bne -

wave_start
        lda wave
        cmp #4
        bne +
        jmp boss_stage
+       jsr play_setup
        jsr form_init
        jsr wave_banner
        jmp play_loop

; ---------------------------------------------------- screen + state setup
play_setup
        lda #$0b
        sta $d011
        lda #0
        sta starmove
        jsr music_stop
        jsr sprites_off
        jsr write_sprites
        lda #1
        jsr clear_screen
        jsr game_starfill
        ldx #39
-       lda #CH_GROUND
        sta SCRA+ROW_GND*40,x
        lda #5
        sta COLRAM+ROW_GND*40,x
        dex
        bpl -
        jsr bunkers_reset
        jsr hud_static
        lda #0
        sta ufo_on
        sta cap_on
        sta ex_t
        sta pop_t
        sta invaded
        sta skipflag
        sta bossmode
        sta ufo_tim
        sta ufo_tim+1
        sta b_dead
        sta b_hp
        sta marchcool
        sta shotalt
        jsr eb_clear
        ; difficulty
        lda sector
        asl
        asl
        asl
        sta tmp0
        lda wave
        asl
        asl
        clc
        adc tmp0
        sta tmp0
        lda #50
        ldx sector
        bne +
        lda #62                 ; sector 1: gentler fire rate
+       sec
        sbc tmp0
        cmp #14
        bcs +
        lda #14
+       sta firebase
        sta firetimer
        lda #2
        ldx sector
        bne +
        ldx wave
        cpx #2
        bcc ++
+       lda #3
+       sta maxeb
        jsr player_reset
        lda #$ff
        sta lastkey
        jsr waitframe
        lda #$1b
        sta $d011
        rts

; fill all empty cells with the game star field
game_starfill
        ldx #0
_r      lda gamerowpat,x
        bmi _nx
        stx tmp3
        lda #0
        sta ftmp0
        lda #39
        sta ftmp1
        jsr bg_fill
        ldx tmp3
_nx     inx
        cpx #25
        bne _r
        rts

; ---------------------------------------------------- banners on row 20
; ptr0 = text, A = colour; shows for tmp7 frames (sprites keep running)
banner
        sta tmp2
        lda #BANNER_ROW
        sta tmp1
        jsr print_centre
-       jsr waitframe
        jsr write_sprites
        jsr hud_update
        dec tmp7
        bne -
banner_clear
        lda #0
        sta ftmp0
        lda #39
        sta ftmp1
        ldx #BANNER_ROW
        jmp bg_fill

wave_banner
        lda sector
        clc
        adc #49
        sta t_wave+5
        lda wave
        clc
        adc #49
        sta t_wave+7
        lda #<t_wave
        sta ptr0
        lda #>t_wave
        sta ptr0+1
        lda #100
        sta tmp7
        lda #7
        jmp banner
t_wave  .null "WAVE 1-1  GET READY!"

; ---------------------------------------------------- input
read_input
        jsr joyread
        sta joy
        jsr scan_key
        cmp lastkey
        beq _r
        sta lastkey
        cmp #KEY_P
        bne +
        jsr pause_game
        rts
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
        lda #BANNER_ROW
        sta tmp1
        lda #1
        sta tmp2
        jsr print_centre
        lda $d404
        pha
        lda #0
        sta $d404
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
        pla
        jsr banner_clear
        rts
t_pause .null "PAUSE  -  P: GO ON   RUN/STOP: QUIT"

quit_game
        ldx #$ff
        txs
        jsr music_stop
        jsr sprites_off
        jsr write_sprites
        jmp title_screen

; ---------------------------------------------------- main loop (waves)
play_loop
        jsr waitframe
        lda frame
        sta lagf
        jsr write_sprites
        jsr read_input
        lda skipflag
        beq +
        jmp wave_clear
+       jsr player_update
        jsr pb_update
        lda pstate
        bne +
        dec ftimer
        bne +
        jsr form_step
+       jsr alien_fire
        jsr eb_update
        jsr ufo_update
        jsr misc_update
        jsr hud_update
        lda nalive
        bne +
        jmp wave_clear
+       lda invaded
        beq +
        jmp invasion
+       jsr check_death
        lda frame
        cmp lagf
        beq +
        inc lagcnt
+       jmp play_loop

; after the death animation: lose a life or end the game
check_death
        lda pstate
        beq _r
        lda ptimer
        cmp #110
        bcc _r
        dec lives
        lda #1
        sta hudflag
        lda lives
        bne +
        pla
        pla
        jmp end_game
+       jsr eb_clear
        jsr player_reset
_r      rts

end_game
        lda #60
        sta tmp7
-       jsr waitframe
        jsr write_sprites
        dec tmp7
        bne -
        jsr sprites_off
        jsr write_sprites
        jmp game_over

invasion
        lda cheat
        beq +
        jmp wave_clear
+       lda #0
        sta lives
        lda #1
        sta pstate
        lda #0
        sta ptimer
        lda #SFX_DEATH
        jsr sfx_start
        lda #<t_landed
        sta ptr0
        lda #>t_landed
        sta ptr0+1
        lda #BANNER_ROW
        sta tmp1
        lda #2
        sta tmp2
        jsr print_centre
-       jsr waitframe
        jsr player_update
        jsr write_sprites
        lda ptimer
        cmp #150
        bcc -
        jmp end_game
t_landed .null "THE SWARM HAS LANDED!"

wave_clear
        lda nalive
        beq _wc_go
        lda #0
        sta nalive
        ldx #0
_wc_lp  stx frow
        txa
        asl
        adc fy
        cmp #25
        bcs _wc_nx
        tax
        lda spanl
        sta ftmp0
        lda spanr
        sta ftmp1
        jsr bg_fill
_wc_nx  ldx frow
        inx
        cpx #5
        bne _wc_lp
_wc_go
        jsr eb_clear
        lda #0
        sta pb_on
        sta pb_on+1
        sta spy+1
        sta spy+2
        sta spy+7
        sta ufo_on
        sta cap_on
        lda #20
        sta tmp7
-       jsr waitframe
        jsr misc_update
        jsr hud_update
        jsr write_sprites
        dec tmp7
        bne -
        lda #TUNE_CLEAR
        jsr music_start
        lda #<t_clear
        sta ptr0
        lda #>t_clear
        sta ptr0+1
        lda #130
        sta tmp7
        lda #3
        jsr banner
        jsr music_stop
        inc wave
        jmp wave_start
t_clear .null "WAVE CLEARED!"

; ---------------------------------------------------- boss stage
boss_stage
        jsr play_setup
        jsr boss_start
        lda #TUNE_BOSS
        jsr music_start
        ldx sector
        lda bossname_lo,x
        sta ptr0
        lda bossname_hi,x
        sta ptr0+1
        lda #2
        sta tmp2
        lda #BANNER_ROW
        sta tmp1
        jsr print_centre
        lda #0
        sta bantim
boss_loop
        jsr waitframe
        jsr write_sprites
        jsr read_input
        lda bantim
        cmp #200
        bcs +
        inc bantim
        cmp #199
        bne +
        jsr banner_clear
+       lda skipflag
        beq +
        lda #0
        sta skipflag
        lda b_hp
        beq +
        jsr boss_kill
+       jsr player_update
        jsr pb_update
        jsr boss_update
        lda b_dead
        bne +
        jsr eb_update
+       jsr misc_update
        jsr hud_update
        lda b_hp
        bne +
        lda b_dead
        beq boss_done
+       jsr check_death
        jmp boss_loop

boss_done
        jsr music_stop
        jsr eb_clear
        lda #0
        sta spy+1
        sta spy+2
        sta pb_on
        sta pb_on+1
        lda #TUNE_CLEAR
        jsr music_start
        lda #<t_sclear
        sta ptr0
        lda #>t_sclear
        sta ptr0+1
        lda #170
        sta tmp7
        lda #7
        jsr banner
        jsr music_stop
        jsr sprites_off
        jsr write_sprites
        lda #0
        sta wave
        sta bossmode
        inc sector
        lda sector
        cmp #3
        bcc +
        jmp ending
+       jmp sector_start
t_sclear .null "SECTOR CLEARED!  BONUS AWARDED"

bossname_lo .byte <t_boss1,<t_boss2,<t_boss3
bossname_hi .byte >t_boss1,>t_boss2,>t_boss3
t_boss1 .null "WARNING: HIVE CARRIER APPROACHING"
t_boss2 .null "WARNING: BATTLE STATION APPROACHING"
t_boss3 .null "WARNING: THE SWARM QUEEN!"

lvname_tab .word lvname0, lvname1, lvname2
lvname0 .null "THE BEETLE FRONT"
lvname1 .null "THE MACHINE WALL"
lvname2 .null "THE CRYSTAL VOID"
