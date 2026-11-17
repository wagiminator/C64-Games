; =====================================================================
;  Game flow
; =====================================================================

zone_start_lo .byte <0, <5000, <12000, <22000, <35000, <48600
zone_start_hi .byte >0, >5000, >12000, >22000, >35000, >48600

new_game
        ldx #$ff
        txs
        lda #$0b
        sta $d011
        jsr irq_simple_on
        lda #0
        sta $d015
        sta score
        sta score+1
        sta score+2
        sta ps
        sta pface
        sta psq
        sta pshoot
        sta ptime
        sta vxf
        sta vxi
        sta pxf
        sta pyf
        sta zone
        sta endflag
        sta spend
        sta joyprev
        jsr world_reset
        ; camera at the start height (cheat: chosen zone)
        ldx startzone
        lda zone_start_lo,x
        clc
        adc #<CAM0
        sta caml
        lda zone_start_hi,x
        adc #>CAM0
        sta camh
        lda #PS_FALL            ; (no camera move yet)
        sta ps
        jsr camera_update
        lda #PS_NORM
        sta ps
        ; start platform two rows above the bottom of the screen
        lda trl
        sec
        sbc #22
        sta g_rl
        sta g_ml
        sta tmp0
        lda trh
        sbc #0
        sta g_rh
        sta g_mh
        sta tmp1
        lda #17
        sta tmp2
        lda #T_PLAT
        jsr place
        lda #70
        sta pxi
        ; feet on it: y = row * 8 + 7
        lda tmp0
        sta pyl
        lda tmp1
        asl pyl
        rol
        asl pyl
        rol
        asl pyl
        rol
        sta pyh
        lda pyl
        ora #7
        sta pyl
        lda #<JUMPV
        sta vyf
        lda #>JUMPV
        sta vyi
        ; zone for the start height
-       ldx zone
        lda hgtl
        cmp zone_lo+1,x
        lda hgth
        sbc zone_hi+1,x
        bcc +
        inc zone
        jmp -
+       jsr gen_ahead
        ; both screens
        lda #1
        sta hid
        jsr clear_hidden
        jsr draw_world
        lda #0
        sta hid
        jsr clear_hidden
        jsr draw_world
        jsr zone_colours
        lda nd020
        sta $d020
        lda nd021
        sta $d021
        lda nd022
        sta $d022
        lda nd023
        sta $d023
        lda #D018A
        sta $d018
        lda #%01101000
        sta $d01c
        lda #0
        sta $d01d
        sta $d017
        sta $d01b
        lda #8
        sta $d025
        lda #1
        sta $d026
        lda #1
        sta hid
        jsr irq_game_on
        lda musicoff
        bne +
        lda #TUNE_GAME
        jsr music_start
+       jsr waitframe
        lda caml
        and #7
        ora #$10
        sta $d011

; ---------------------------------------------------- main loop: one step per frame
game_loop
-       lda spend
        bne -
        ; NTSC: skip every sixth step, so the game runs at the PAL speed
        lda ntsc
        beq +
        dec ntscc
        bpl +
        lda #5
        sta ntscc
        jsr waitframe
+       jsr keys
        jsr player_update
        jsr camera_update
        jsr zone_check
        jsr objects_animate
        jsr mon_update
        jsr gen_ahead
        jsr cull_world
        jsr draw_world
        jsr score_render
        jsr sprites_build
        jsr zone_colours
        lda hid
        beq +
        lda #D018B
        bne ++
+       lda #D018A
+       sta nd018
        lda caml
        and #7
        ora #$10
        sta nd011
        lda #1
        sta spend
        lda hid
        eor #1
        sta hid
        ; ---- end of the game?
        lda ps
        cmp #PS_FALL
        bcc game_loop
        cmp #PS_MOON
        beq _moon
        lda dtimer
        bne game_loop
        jsr wait_shown
        jmp game_over
_moon   ; the camera sinks a little to show the whole moon
        lda pyl
        clc
        adc #130
        sta tmp0
        lda pyh
        adc #0
        sta tmp1
        lda tmp0
        cmp caml
        lda tmp1
        sbc camh
        bcs +
        lda caml
        bne *+4
        dec camh
        dec caml
+       lda dtimer
        cmp #120
        bne +
        lda #TUNE_MOON
        jsr music_start
+       lda dtimer
        cmp #70
        bne +
        ; plant the flag
        lda #M_FLAG
        sta m_t
        lda pxi
        clc
        adc #9
        cmp #148
        bcc *+4
        lda #148
        sta m_x
        lda pyl
        sta m_yl
        lda pyh
        sta m_yh
+       dec dtimer
        bne game_loop
        jsr wait_shown
        jmp ending

wait_shown
-       lda spend
        bne -
        rts

zone_colours
        ldy zone
        lda zone_bg,y
        sta nd020
        sta nd021
        lda zone_grid,y
        sta nd022
        lda zone_out,y
        sta nd023
        rts

zone_check
        ldx zone
        cpx #NZONES-1
        bcs +
        lda hgtl
        cmp zone_lo+1,x
        lda hgth
        sbc zone_hi+1,x
        bcc +
        inc zone
        lda #SFX_ZONE
        jsr sfx_start
+       rts

; ---------------------------------------------------- moving, breaking, vanishing platforms
objects_animate
        ldx #NOBJ-1
_o      lda o_t,x
        cmp #T_MOVE
        bne _br
        lda o_st,x              ; frames per step
        cmp #1
        beq +
        lda frame
        and #1
        bne _n
+       lda o_dx,x
        bne _ml
        inc o_x,x
        lda o_x,x
        cmp #140
        bcc _n
        lda #1
        sta o_dx,x
        bne _n
_ml     dec o_x,x
        bne _n
        lda #0
        sta o_dx,x
        beq _n
_br     cmp #T_BROKE
        bne _po
        inc o_tm,x
        lda o_tm,x
        cmp #28
        bcs _kill
        and #3
        bne _n
        lda o_rl,x              ; the pieces fall
        bne +
        dec o_rh,x
+       dec o_rl,x
        jmp _n
_po     cmp #T_POOF
        bne _n
        dec o_tm,x
        bne _n
_kill   lda #T_DEAD
        sta o_t,x
_n      dex
        bpl _o
        rts

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
        jmp music_start
_r      rts

pause_game
        jsr wait_shown
        lda #0
        sta $d418
        ; "PAUSED" in the score sprites of the shown screen
        ldx #5
-       lda t_paused,x
        sta sprtxt,x
        dex
        bpl -
        lda hid
        eor #1
        sta hid
        jsr text_sprites
        lda hid
        eor #1
        sta hid
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
        rts
t_paused .text "PAUSED"
