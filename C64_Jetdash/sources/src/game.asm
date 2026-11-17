; =====================================================================
;  Game flow: start, main loop, zones, HUD, pause
; =====================================================================

zs_col_lo .byte <0, <500, <1000, <1500, <2000, <2450
zs_col_hi .byte >0, >500, >1000, >1500, >2000, >2450
zs_m_lo   .byte <0, <1000, <2000, <3000, <4000, <4900
zs_m_hi   .byte >0, >1000, >2000, >3000, >4000, >4900
zs_bcd    .byte $00, $10, $20, $30, $40, $49
zs_zone   .byte 0, 1, 2, 3, 4, 4

; ---------------------------------------------------- start a new game
new_game
        ldx #$ff
        txs
        lda #$0b
        sta $d011
        lda #0
        sta $d015
        jsr irq_simple_on
        jsr waitframe
        ; clear both screens, colours: HUD hires white, playfield multicolour yellow
        ldx #0
-       lda #32
        sta SCRA,x
        sta SCRA+$100,x
        sta SCRA+$200,x
        sta SCRA+$2e8,x
        sta SCRB,x
        sta SCRB+$100,x
        sta SCRB+$200,x
        sta SCRB+$2e8,x
        lda #8+7
        sta COLRAM,x
        sta COLRAM+$100,x
        sta COLRAM+$200,x
        sta COLRAM+$2e8,x
        inx
        bne -
        ldx #79
        lda #1
-       sta COLRAM,x
        dex
        bpl -
        lda #8+7
        sta COLRAM+15           ; coin icon
        ; ---- variables
        ldx #0
        lda cheat
        beq +
        ldx startzone
+       stx tmp0
        lda zs_zone,x
        sta zone
        sta gzone
        lda zs_col_lo,x
        sta gcl
        sta wcl
        lda zs_col_hi,x
        sta gch
        sta wch
        lda zs_m_lo,x
        sta mbl
        lda zs_m_hi,x
        sta mbh
        lda #0
        sta metres
        sta metres+2
        lda zs_bcd,x
        sta metres+1
        lda #0
        sta coins
        sta coins+1
        sta score
        sta score+1
        sta score+2
        sta mquart
        sta subpx
        sta prep
        sta swapnow
        sta disp
        sta gplen
        sta lwait
        sta lactive
        sta ldone
        sta gnopat
        sta l_ph
        sta ms_st
        sta ms_st+1
        sta wk_st
        sta wk_st+1
        sta bx_st
        sta pmode
        sta vyf
        sta vyi
        sta hyf
        sta gdir
        sta invuln
        sta panim
        sta flash
        sta exittime
        sta msgtime
        sta endflag
        sta thrust
        sta sen
        sta sxh
        sta joyprev
        sta ntscc
        lda #1
        sta ground
        lda #YMAX
        sta hyi
        lda #HEROX
        sta herox
        lda #7
        sta xs
        sta nxs
        sta curxs
        lda #30
        sta gap
        lda #<220
        sta boxcnt
        lda #>220
        sta boxcnt+1
        lda #<400
        sta mtimer
        lda #>400
        sta mtimer+1
        jsr calc_level
        jsr set_speed
        ; ---- fill screen A with columns 0..38
        lda #0
        sta gen_x
-       lda #0
        jsr gen_column
        inc gen_x
        lda gen_x
        cmp #39
        bne -
        lda #0
        sta wk_st
        sta wk_st+1
        sta bx_st
        ; ---- HUD and colours
        jsr hud_static
        jsr hud_digits
        jsr zone_colours
        jsr zone_message
        ; ---- sprites
        lda #%11111110
        sta $d01c
        lda #8
        sta $d025
        lda #1
        sta $d026
        lda #0
        sta $d017
        sta $d01d
        sta $d01b
        jsr hero_sprites
        lda #D018GA
        sta nd018
        sta $d018
        jsr irq_game_on
        lda #1
        sta spend
        jsr wait_shown
        lda #$1b
        sta $d011
        lda musicoff
        bne +
        lda #TUNE_GAME
        jsr music_start
+       jmp game_loop

; ---------------------------------------------------- main loop
game_loop
        jsr wait_shown
        lda ntsc
        beq +
        inc ntscc
        lda ntscc
        cmp #6
        bne +
        lda #0
        sta ntscc
        jmp game_loop
+       lda DBGRAST
        beq +
        sta $d020
+       jsr read_input
        jsr keys
        jsr scroll_advance
        jsr distance_update
        jsr zone_check
        jsr player_update
        jsr player_collide
        jsr hazards_update
        jsr anim_chars
        jsr hud_update
        jsr hero_sprites
        lda invuln
        beq +
        dec invuln
+       lda flash
        beq +
        dec flash
        bne +
        lda zbg
        sta $d021
+       ; ---- the new state
        lda #D018GA
        ldx disp
        beq +
        lda #D018GB
+       sta nd018
        lda xs
        sta nxs
        lda #1
        sta spend
        lda DBGRAST
        beq +
        lda #2
        sta $d020
+       jsr prep_step
        lda DBGRAST
        beq +
        lda #0
        sta $d020
+
        ; ---- end of the game?
        lda pmode
        cmp #PM_DEAD
        bne +
        lda dtimer
        bne +
        jmp game_end
+       lda herox
        cmp #250
        bcc +
        lda #1
        sta endflag
        jmp game_end
+       jmp game_loop

wait_shown
-       lda spend
        bne -
        rts

; ---------------------------------------------------- end of a game: score = metres + 10 * coins
game_end
        jsr wait_shown
        lda #0
        sta $d015
        ; coins * 10 (BCD shift by one digit)
        lda coins
        asl
        asl
        asl
        asl
        sta tmp0
        lda coins
        lsr
        lsr
        lsr
        lsr
        sta tmp1
        lda coins+1
        asl
        asl
        asl
        asl
        ora tmp1
        sta tmp1
        lda coins+1
        lsr
        lsr
        lsr
        lsr
        sta tmp2
        sed
        lda metres
        clc
        adc tmp0
        sta score
        lda metres+1
        adc tmp1
        sta score+1
        lda metres+2
        adc tmp2
        sta score+2
        cld
        ; best distance
        lda metres+2
        cmp best+2
        bcc _nb
        bne _b
        lda metres+1
        cmp best+1
        bcc _nb
        bne _b
        lda metres
        cmp best
        bcc _nb
_b      lda metres
        sta best
        lda metres+1
        sta best+1
        lda metres+2
        sta best+2
_nb     lda endflag
        beq +
        jmp ending
+       jmp game_over

; ---------------------------------------------------- input (joystick or autopilot)
read_input
        jsr joyread
        ldx DBGAI
        beq +
        jsr autopilot
+       sta joy
        lda joyprev
        eor #$ff
        and joy
        sta joynew
        lda joy
        sta joyprev
        rts

; ---------------------------------------------------- distance, level and speed
distance_update
        lda moved
        beq _r
        sta tmp7
-       inc mquart
        lda mquart
        cmp #4
        bne +
        lda #0
        sta mquart
        inc mbl
        bne ++
        inc mbh
+       dec tmp7
        bne -
        jmp calc_level
+       sed
        lda metres
        clc
        adc #1
        sta metres
        lda metres+1
        adc #0
        sta metres+1
        lda metres+2
        adc #0
        sta metres+2
        cld
        inc hudchg
        dec tmp7
        bne -
        jmp calc_level
_r      rts

calc_level
        lda mbh
        cmp #16
        bcc +
        lda #15
+       sta lvl
        rts

set_speed
        ldx lvl
        lda d_spdlo,x
        sta spdf
        lda d_spdhi,x
        sta spdi
        rts

; ---------------------------------------------------- zones
zone_check
        lda pmode
        cmp #PM_DEAD
        bcs +
        jsr set_speed
+       lda zone
        cmp gzone
        bcs _r
        ; the gate reached the hero's column?
        lda wcl
        clc
        adc #8
        sta tmp0
        lda wch
        adc #0
        sta tmp1
        lda tmp0
        cmp gatel
        lda tmp1
        sbc gateh
        bcc _r
        inc zone
        jsr zone_colours
        jsr zone_message
        lda #1
        sta $d021
        lda #5
        sta flash
        lda zone
        cmp #5
        bne +
        ; outside: fly away
        lda pmode
        cmp #PM_DEAD
        bcs _r
        lda #PM_EXIT
        sta pmode
        lda #0
        sta gdir
        sta exittime
        lda musicoff
        bne _r
        lda #TUNE_END
        jmp music_start
+       lda #SFX_ZONE
        jmp sfx_start
_r      rts

zone_colours
        ldx zone
        lda zone_bg,x
        sta zbg
        sta $d021
        lda zone_c1,x
        sta $d022
        lda zone_c2,x
        sta $d023
        lda #0
        sta $d020
        rts

; zone name in HUD row 1 (16 chars at column 12)
zone_message
        lda zone
        asl
        asl
        asl
        asl
        tax
        ldy #0
-       lda zone_names,x
        sta SCRA+40+12,y
        sta SCRB+40+12,y
        inx
        iny
        cpy #16
        bne -
        lda #150
        sta msgtime
        rts

; ---------------------------------------------------- HUD (row 0 of both screens)
hud_static
        ldx #39
-       lda t_hud,x
        sta SCRA,x
        sta SCRB,x
        dex
        bpl -
        rts
t_hud   .text " 00000 M       "
        .byte CH_COIN
        .text "0000        BEST 00000M "

hud_update
        lda msgtime
        beq +
        dec msgtime
        bne +
        ldx #15
        lda #32
-       sta SCRA+40+12,x
        sta SCRB+40+12,x
        dex
        bpl -
+       lda hudchg
        beq _r
        lda #0
        sta hudchg
        jmp hud_digits
_r      rts

hud_digits
        ldx #1
        lda metres+2
        jsr _d1
        lda metres+1
        jsr _d2
        lda metres
        jsr _d2
        ldx #16
        lda coins+1
        jsr _d2
        lda coins
        jsr _d2
        ldx #33
        lda best+2
        jsr _d1
        lda best+1
        jsr _d2
        lda best
        jmp _d2
_d2     pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRA,x
        sta SCRB,x
        inx
        pla
_d1     and #15
        ora #48
        sta SCRA,x
        sta SCRB,x
        inx
        rts

; ---------------------------------------------------- animated chars: coins and zappers
anim_chars
        lda frame
        and #3
        bne _z
        lda frame
        lsr
        lsr
        and #3
        asl
        asl
        asl
        tax
        ldy #0
-       lda coin_anim,x
        sta CHARGAME+CH_COIN*8,y
        inx
        iny
        cpy #8
        bne -
_z      lda frame
        and #3
        cmp #2
        bne _r
        lda frame
        and #4
        beq +
        lda #40
+       tax
        ldy #0
-       lda zap_anim,x
        sta CHARGAME+CH_ZH*8,y
        inx
        iny
        cpy #40
        bne -
_r      rts

; ---------------------------------------------------- keys: pause, music
keys
        jsr scan_key
        cmp lastkey
        beq _r
        sta lastkey
        cmp #KEY_P
        beq pause_game
        cmp #KEY_M
        bne _r
        lda musicoff
        eor #1
        sta musicoff
        beq +
        jmp music_stop
+       lda #TUNE_GAME
        ldx zone
        cpx #5
        bne +
        lda #TUNE_END
+       jmp music_start
_r      rts

pause_game
        lda #0
        sta $d418
        ldx #15
-       lda t_paused,x
        sta SCRA+40+12,x
        sta SCRB+40+12,x
        dex
        bpl -
-       jsr waitframe
        jsr scan_key
        cmp #KEY_STOP
        bne +
        jmp title_screen
+       cmp #$ff
        bne -
-       jsr waitframe
        jsr scan_key
        cmp #KEY_STOP
        bne +
        jmp title_screen
+       cmp #KEY_P
        bne -
        sta lastkey
        lda #$0f
        sta $d418
        lda #1
        sta msgtime
        rts
t_paused .text "     PAUSED     "

; ---------------------------------------------------- autopilot (testing only)
; looks at the columns in front of the hero and steers to the middle of the
; widest free gap; collects coins on the way
autopilot
        lda #0
        sta ai_joy
        ; columns HEROX/8+2 .. +7 of the displayed screen
        ldx #22
_row    stx ai_r
        jsr row_ptrs
        lda #0
        sta ai_bad
        ldy #(HEROX/8)+1
-       lda (scrp),y
        sec
        sbc #CH_ZH
        cmp #5
        bcs +
        inc ai_bad
+       iny
        cpy #(HEROX/8)+8
        bne -
        ldx ai_r
        lda ai_bad
        sta ai_rowbad,x
        dex
        cpx #2
        bne _row
        ; laser rows are bad too
        lda lactive
        beq +
        ldx l_r1
        beq +
        inc ai_rowbad,x
        ldx l_r2
        beq +
        inc ai_rowbad,x
+       ; find the free row (3 free rows below it) closest to the hero
        ; preferred row wanders up and down
        lda frame
        and #$fe
        tax
        lda sine64,x
        lsr
        lsr
        lsr
        clc
        adc #5
        sta ai_cur
        lda #0
        sta ai_best
        lda #99
        sta ai_dist
        ldx #3
_cand   lda ai_rowbad,x
        ora ai_rowbad+1,x
        ora ai_rowbad+2,x
        bne _nc
        txa
        sec
        sbc ai_cur
        bcs +
        eor #$ff
        adc #1
+       cmp ai_dist
        bcs _nc
        sta ai_dist
        stx ai_best
_nc     inx
        cpx #21
        bne _cand
        ; target y = best row * 8 - 2 (sprite top)
        lda ai_best
        beq _wave
        asl
        asl
        asl
        sec
        sbc #2
        jmp _go
_wave   lda frame
        and #127
        clc
        adc #40
_go     sta ai_ty
        ; missiles: dodge
        lda ms_st
        cmp #2
        bcc _nomis
        lda ms_y
        sec
        sbc hyi
        clc
        adc #24
        cmp #48
        bcs _nomis
        lda hyi
        cmp #90
        lda #30
        bcs +
        lda #140
+       sta ai_ty
_nomis  ldx pmode
        cpx #PM_COPTER
        beq _cop
        cpx #PM_GRAV
        beq _grav
        ; jetpack: thrust while below the target or falling fast near it
        lda hyi
        cmp ai_ty
        bcc _done
        lda #$10
        sta ai_joy
        jmp _done
_cop    lda hyi
        cmp ai_ty
        bcc _done
        lda vyi
        bmi _done
        lda frame
        and #1
        beq _done
        lda #$10
        sta ai_joy
        jmp _done
_grav   lda frame
        and #63
        bne _done
        lda #$10
        sta ai_joy
_done   lda ai_joy
        rts
ai_joy  .byte 0
ai_r    .byte 0
ai_bad  .byte 0
ai_cur  .byte 0
ai_best .byte 0
ai_dist .byte 0
ai_ty   .byte 0
ai_rowbad .fill 26
