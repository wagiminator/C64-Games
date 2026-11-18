; =====================================================================
;  Game flow: start, main loop, zones, score, HUD, power-ups, pause,
;  crash and escape
; =====================================================================

spd_hi  .byte 7, 8, 10, 11, 12
spd_lo  .byte $00, $80, $00, $40, $80
pw_dur  .byte 12, 12, 15, 30

new_game
        jsr screen_setup
        lda #0
        ldx #2
-       sta score,x
        dex
        bpl -
        sta coins
        sta coins+1
        sta dist
        sta dist+1
        sta camz
        sta camz+1
        sta camf
        sta slotacc
        sta metacc
        sta metres
        sta metres+1
        sta pat_n
        sta endflag
        sta ntscc
        sta bouly
        sta hudmsg
        sta aiturn
        sta deadt
        sta m100
        ldx #3
-       sta pw_t,x
        dex
        bpl -
        sta pwtick
        lda #6
        sta pat_gap             ; a few empty rows at the start
        lda startzone
        sta zone
        jsr clear_objects
        jsr reset_runner
        ; screen: HUD rows, ground
        ldx #79
-       lda #32
        sta SCR,x
        lda #1
        sta COLRAM,x
        dex
        bpl -
        ldx #0
-       lda ground_map,x
        sta SCR+9*40,x
        lda ground_map+256,x
        sta SCR+9*40+256,x
        inx
        bne -
        ldx #0
-       lda ground_map+512,x
        sta SCR+9*40+512,x
        inx
        cpx #128
        bne -
        jsr set_zone
        ldx #4
-       lda t_hscore,x
        sta SCR+1,x
        lda #7
        sta COLRAM+1,x
        dex
        bpl -
        ; sprites
        lda #$ff
        sta $d01c
        lda #0
        sta $d025
        sta $d01b
        sta $d010
        lda #1
        sta $d026
        lda #3
        sta $d015
        jsr irq_game_on
        jsr calc_stripes
        jsr project
        jsr runner_sprites
        jsr build_sprites
        lda #1
        sta spend
        jsr hud_update
        lda #TUNE_GAME
        ldx musicoff
        bne +
        jsr music_start
+       lda #60                 ; the boulder is right behind at the start
        sta stumble
        lda #SFX_RUMBLE
        jsr sfx_start
        lda frame
        sta lastfr
        jsr waitframe
        lda #$1b
        sta $d011

; ---------------------------------------------------- main loop: one update every second frame
game_loop
        jsr wait_render
        lda #1
        sta spend               ; sprites of this update go live at the bottom IRQ
        lda DBGRAST
        beq +
        lda #2
        sta $d020
+       lda #1
        sta nearpend            ; the bottom IRQ updates the near rows
        jsr SPEED               ; far rows
        lda DBGRAST
        beq +
        lda #7
        sta $d020
+
        jsr draw_soft
        lda DBGRAST
        beq +
        lda #5
        sta $d020
+       ; ---- logic for the next update: one tick per two frames
        lda tickacc
        clc
        adc elapsed
        tax
        and #1
        sta tickacc
        txa
        lsr
        bne +
        lda #1
+       cmp #4
        bcc +
        lda #3
+       sta nticks
-       jsr tick
        dec nticks
        bne -
-       lda nearpend            ; near rows done with the old stripe phase?
        bne -
        jsr calc_stripes
        jsr project
        jsr runner_sprites
-       lda spend
        bne -
        jsr build_sprites
        jsr hud_update
        lda DBGRAST
        beq +
        lda #0
        sta $d020
+       jsr keys
        lda deadt
        cmp #60
        bcc +
        jmp game_over
+       lda endflag
        beq game_loop
        jmp escaped



; wait for the next update: at least two frames after the last one, raster
; below the horizon row (the stripe code chases the beam)
wait_render
-       lda frame
        sec
        sbc lastfr
        cmp #2
        bcc -
        sta elapsed
-       lda $d011
        bmi -
        lda $d012
        cmp #134
        bcc -
        cmp #245
        bcs wait_render
        lda frame
        sta lastfr
        rts

; ---------------------------------------------------- one game step (1/25 s)
tick
        lda ntsc
        beq +
        inc ntscc
        lda ntscc
        cmp #6
        bne +
        lda #0
        sta ntscc
        rts
+       lda pdead
        beq +
        jmp dying
+       jsr runner_update
        ; camera
        lda camf
        clc
        adc spd
        sta camf
        lda spd+1
        adc #0
        sta step
        clc
        adc camz
        sta camz
        bcc +
        inc camz+1
+       jsr move_objects
        jsr gen_update
        jsr boulder_update
        jsr power_timers
        ; metres
        lda metacc
        clc
        adc step
        sta metacc
-       lda metacc
        cmp #16
        bcc +
        sbc #16
        sta metacc
        jsr add_metre
        jmp -
+       lda pdead
        beq +
        lda cheat               ; cheat: nothing can stop you
        beq _crash
        lda #0
        sta pdead
        rts
_crash  jsr music_stop
        lda #SFX_CRASH
        jsr sfx_start
+       rts

; crashed: the boulder rolls over the runner
dying
        inc deadt
        lda bouly
        cmp #84
        bcs +
        inc bouly
        inc bouly
+       lda deadt
        cmp #20
        bne +
        lda #SFX_RUMBLE
        jsr sfx_start
+       rts

add_metre
        inc metres
        bne +
        inc metres+1
+       sed
        lda dist
        clc
        adc #1
        sta dist
        lda dist+1
        adc #0
        sta dist+1
        cld
        ; points: land number, doubled by the star
        ldx zone
        inx
        txa
        ldy pw_t+2
        beq +
        asl
+       jsr score_addbin
        ; every 100 m a little faster
        inc m100
        lda m100
        cmp #100
        bcc +
        lda #0
        sta m100
        lda spd
        clc
        adc #$10
        sta spd
        bcc +
        inc spd+1
+       lda metres
        cmp #<ZONELEN
        bne +
        lda metres+1
        cmp #>ZONELEN
        bne +
        jmp next_zone
+       rts

next_zone
        lda #0
        sta metres
        sta metres+1
        sta m100
        inc zone
        lda zone
        cmp #NZONES
        bcc +
        lda #1
        sta endflag
        rts
+       jsr set_zone
        lda #SFX_ZONE
        jmp sfx_start

; palette, scenery and speed of the zone
set_zone
        ldx zone
        lda spd_lo,x
        sta spd
        lda spd_hi,x
        sta spd+1
        lda sky_bg,x
        sta z_sky
        lda gnd_bg,x
        sta z_bg
        lda gnd_22,x
        sta $d022
        lda gnd_23,x
        sta $d023
        ; colour RAM: sky rows MC + colour, ground rows MC + line colour
        lda sky_cr,x
        ora #8
        ldy #0
-       sta COLRAM+80,y
        sta COLRAM+80+180,y
        iny
        cpy #180
        bne -
        lda gnd_cr,x
        ora #8
        ldy #0
-       sta COLRAM+360,y
        sta COLRAM+360+256,y
        sta COLRAM+360+384,y
        iny
        bne -
        ; scenery characters 80.. and map rows 2..8
        lda scen_clo,x
        sta ptr0
        lda scen_chi,x
        sta ptr0+1
        lda #<(CS1+80*8)
        sta ptr1
        lda #>(CS1+80*8)
        sta ptr1+1
        lda scen_n,x
        sta tmp0
-       ldy #7
-       lda (ptr0),y
        sta (ptr1),y
        dey
        bpl -
        lda ptr0
        clc
        adc #8
        sta ptr0
        bcc +
        inc ptr0+1
+       lda ptr1
        clc
        adc #8
        sta ptr1
        bcc +
        inc ptr1+1
+       dec tmp0
        bne --
        ldx zone
        lda scen_mlo,x
        sta ptr0
        lda scen_mhi,x
        sta ptr0+1
        ldy #0
-       lda (ptr0),y
        sta SCR+80,y
        iny
        cpy #140
        bne -
        lda ptr0
        clc
        adc #140
        sta ptr0
        bcc +
        inc ptr0+1
+       ldy #0
-       lda (ptr0),y
        sta SCR+80+140,y
        iny
        cpy #140
        bne -
        lda #120
        sta hudmsg
        rts

; ---------------------------------------------------- coins and power-ups
take_coin
        sed
        lda coins
        clc
        adc #1
        sta coins
        lda coins+1
        adc #0
        sta coins+1
        cld
        lda #10
        ldy pw_t+2
        beq +
        asl
+       jsr score_addbin
        lda #SFX_COIN
        jmp sfx_start

; Y = power-up 0 magnet, 1 boots, 2 star (x2), 3 amulet
take_power
        lda pw_dur,y
        sta pw_t,y
        lda #25
        sta pflash
        lda #SFX_POWER
        jmp sfx_start

power_timers
        inc pwtick
        lda pwtick
        cmp #25
        bcc _r
        lda #0
        sta pwtick
        ldx #3
-       lda pw_t,x
        beq +
        dec pw_t,x
+       dex
        bpl -
_r      rts

; ---------------------------------------------------- HUD (rows 0 and 1)
hud_update
        ; score
        ldx #7
        lda score+2
        jsr hud_d2
        lda score+1
        jsr hud_d2
        lda score
        jsr hud_d2
        ; coins
        lda #CH_COIN
        sta SCR+16
        lda #7
        sta COLRAM+16
        ldx #17
        lda coins+1
        jsr hud_d2
        lda coins
        jsr hud_d2
        ; distance
        ldx #29
        lda dist+1
        jsr hud_d2
        lda dist
        jsr hud_d2
        lda #13                 ; "M"
        sta SCR+33
        ; power-ups in row 1: icon + 4 bar chars each
        ldy #0
_pw     tya
        asl
        asl
        sta tmp0
        tya
        adc tmp0                ; *5
        clc
        adc #41
        tax
        lda pw_t,y
        bne _on
        lda #32
        sta SCR,x
        sta SCR+1,x
        sta SCR+2,x
        sta SCR+3,x
        sta SCR+4,x
        jmp _pn
_on     lda pw_icon,y
        sta SCR,x
        lda pw_hcol,y
        sta COLRAM,x
        sta COLRAM+1,x
        sta COLRAM+2,x
        sta COLRAM+3,x
        sta COLRAM+4,x
        lda pw_t,y
        clc
        adc #3
        lsr
        lsr
        sta tmp1
        lda #4
        sta tmp2
-       inx
        lda #CH_BAR1
        dec tmp1
        bmi +
        lda #CH_BAR0
+       sta SCR,x
        dec tmp2
        bne -
_pn     iny
        cpy #4
        bne _pw
        ; zone name
        lda hudmsg
        beq _r
        dec hudmsg
        bne +
        ldx #18
        lda #32
-       sta SCR+62,x
        dex
        bpl -
_r      rts
+       lda zone
        asl
        tax
        lda zname,x
        sta ptr0
        lda zname+1,x
        sta ptr0+1
        ldy #0
-       lda (ptr0),y
        beq +
        sta SCR+62,y
        lda #7
        sta COLRAM+62,y
        iny
        bne -
+       rts

hud_d2  pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCR,x
        inx
        pla
        and #15
        ora #48
        sta SCR,x
        inx
        rts

t_hscore .text "SCORE"
pw_icon .byte CH_MAGNET, CH_BOOTS, CH_STAR, CH_AMULET
pw_hcol .byte 2, 5, 7, 4
zname   .word zn0, zn1, zn2, zn3, zn4
zn0     .null "1 TEMPLE HALLS"
zn1     .null "2 JUNGLE PATH"
zn2     .null "3 RED CANYON"
zn3     .null "4 CRYSTAL MINE"
zn4     .null "5 FIRE MOUNTAIN"

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
        lda #0
        sta $d418
-       jsr waitframe
        jsr scan_key
        cmp #KEY_STOP
        bne +
        jmp title_screen
+       cmp lastkey
        beq -
        sta lastkey
        cmp #KEY_P
        bne -
        lda #$0f
        sta $d418
        lda frame
        sta lastfr
        rts

; ---------------------------------------------------- reached the end of the last land
escaped
        jsr music_stop
        ; bonus 5000
        sed
        lda score+1
        clc
        adc #$50
        sta score+1
        lda score+2
        adc #0
        sta score+2
        cld
        jmp ending
