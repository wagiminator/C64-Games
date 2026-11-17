; =====================================================================
;  Game flow: start, main loop, hero, time, bosses, level up, dawn
; =====================================================================

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
        ; ---- variables
        lda #0
        ldx #NE-1
-       sta e_t,x
        dex
        bpl -
        ldx #NG-1
-       sta g_t,x
        dex
        bpl -
        ldx #NK-1
-       sta k_on,x
        dex
        bpl -
        ldx #NFX-1
-       sta fx_t,x
        dex
        bpl -
        ldx #NITEMS-1
-       sta w_lvl,x
        dex
        bpl -
        sta score
        sta score+1
        sta score+2
        sta kills
        sta kills+1
        sta kills+2
        sta xp
        sta xp+1
        sta xpnext+1
        sta lvpend
        sta dead
        sta iframes
        sta b_on
        sta b_fl
        sta tfr
        sta secs
        sta subx
        sta suby
        sta orbang
        sta ecount
        sta endflag
        sta pface
        sta panim
        sta disp
        sta aiturn
        sta joyprev
        sta ntscc
        lda #5
        sta xpnext
        lda #1
        sta plevel
        sta w_lvl               ; silver knives
        sta spawnt
        lda #4
        sta w_cd
        lda #100
        sta hp
        sta maxhp
        lda #2
        sta spdi
        lda #0
        sta spdf
        sta pdir
        ; start minute (cheat)
        lda #0
        ldx cheat
        beq +
        lda startzone
+       sta mins
        jsr min_phase
        ; bosses before the start minute count as done
        ldx #0
        lda mins
        cmp #4
        bcc +
        inx
        cmp #7
        bcc +
        inx
+       stx bossdone
        lda mins
        jsr mul60
        ; world position: the middle of the 16 bit range
        lda #0
        sta pxl
        sta pyl
        lda #$80
        sta pxh
        sta pyh
        jsr clear_grid
        jsr hero_cell
        jsr camera
        ; ---- screens and sprites
        lda #2
        sta $d025
        lda #7
        sta $d026
        lda #%00001110
        sta $d01c
        lda #%11001100
        sta $d01d
        lda #%00001100
        sta $d017
        lda #0
        sta $d01b
        sta $d020
        ; fixed sprite settings (shadows)
        lda #0
        sta sc
        lda #14
        sta sc+1
        lda #3
        sta sc+2
        lda #1
        sta sc+4
        sta sc+5
        lda #7
        sta sc+6
        sta sc+7
        lda #HEROSX
        sta sx
        sta sx+1
        lda #HEROSY
        sta sy
        sta sy+1
        lda #<290
        sta sx+4
        lda #%00010000
        sta sxh
        lda #36
        sta sx+5
        lda #124
        sta sx+6
        lda #172
        sta sx+7
        lda #58
        sta sy+4
        sta sy+5
        sta sy+6
        sta sy+7
        lda #SPR_HUDT
        sta sptr+4
        lda #SPR_HUDL
        sta sptr+5
        lda #SPR_XPL
        sta sptr+6
        lda #SPR_XPR
        sta sptr+7
        lda #SPR_BODY
        sta sptr+1
        inc hudchg
        jsr hud_update
        jsr set_palette
        ; first picture
        jsr build_frame
        jsr irq_game_on
        lda #1
        sta spend
        jsr wait_shown
        lda musicoff
        bne +
        lda #TUNE_GAME
        jsr music_start
+       lda frame
        sta lastfr

; ---------------------------------------------------- main loop (one update every second frame)
game_loop
-       lda frame
        sec
        sbc lastfr
        cmp #2
        bcc -
        lda frame
        sec
        sbc lastfr
        sta elapsed
        lda frame
        sta lastfr
        ; NTSC: every sixth update is skipped
        lda ntsc
        beq +
        inc ntscc
        lda ntscc
        cmp #6
        bne +
        lda #0
        sta ntscc
        jsr time_update         ; the clock goes on
        jmp game_loop
+       lda #1
        jsr dbgcol
        jsr read_input
        jsr keys
        jsr hero_move
        jsr time_update
        jsr spawn_update
        lda #2
        jsr dbgcol
        jsr enemies_update
        lda #3
        jsr dbgcol
        jsr weapons_update
        jsr boss_update
        lda #4
        jsr dbgcol
        jsr gems_update
        jsr fx_update
        lda iframes
        beq +
        dec iframes
+       jsr wait_shown          ; (the logic above ran while the last picture was waiting)
        jsr build_frame
        jsr hud_update
        ; ---- events
        lda dead
        beq +
        jmp hero_died
+       lda lvpend
        beq +
        jsr level_up
+       lda mins
        cmp #ENDMIN
        bcc +
        jmp dawn
+       jmp game_loop

wait_shown
-       lda spend
        bne -
        rts

; ---------------------------------------------------- build the hidden screen and the new state
build_frame
        lda #5
        jsr dbgcol
        jsr camera
        lda #>SCRB
        ldx disp
        beq +
        lda #>SCRA
+       sta hidhi
        jsr bg_copy
        lda #6
        jsr dbgcol
        jsr draw_objects
        lda #7
        jsr dbgcol
        jsr hero_sprites
        jsr boss_sprite
        ; scroll registers
        lda camxl
        and #7
        eor #7
        ora #$10
        sta nd016
        lda camyl
        and #7
        eor #7
        ora #$10
        sta nd011
        lda #D018GB
        ldx disp
        beq +
        lda #D018GA
+       sta nd018
        lda disp
        eor #1
        sta disp
        lda #1
        sta spend
        lda #0
dbgcol  ldx DBGRAST
        beq +
        sta $d020
+       rts

; ---------------------------------------------------- camera and the top left cell of the screen
camera
        lda pxl
        sec
        sbc #CAMDX
        sta camxl
        lda pxh
        sbc #0
        sta camxh
        lda pyl
        sec
        sbc #CAMDY
        sta camyl
        lda pyh
        sbc #0
        sta camyh
        lda camxh
        sta bcxh
        lda camxl
        lsr bcxh
        ror
        lsr bcxh
        ror
        lsr bcxh
        ror
        sta bcxl
        lda camyh
        sta bcyh
        lda camyl
        lsr bcyh
        ror
        lsr bcyh
        ror
        lsr bcyh
        ror
        sta bcyl
        rts

hero_cell
        lda pxl
        clc
        adc #12
        sta pcxl
        lda pxh
        adc #0
        sta pcxh
        lsr pcxh
        ror pcxl
        lsr pcxh
        ror pcxl
        lsr pcxh
        ror pcxl
        lda pyl
        clc
        adc #10
        sta pcyl
        lda pyh
        adc #0
        sta pcyh
        lsr pcyh
        ror pcyl
        lsr pcyh
        ror pcyl
        lsr pcyh
        ror pcyl
        rts

; ---------------------------------------------------- input
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

; ---------------------------------------------------- hero movement (8 directions)
hero_move
        lda #0
        sta moving
        lda dead
        beq +
        rts
+       ; dx, dy from the joystick
        lda #0
        sta tmp4
        sta tmp5
        lda joy
        and #1
        beq +
        dec tmp5
+       lda joy
        and #2
        beq +
        inc tmp5
+       lda joy
        and #4
        beq +
        dec tmp4
+       lda joy
        and #8
        beq +
        inc tmp4
+       lda tmp4
        ora tmp5
        beq _r
        inc moving
        ; direction 0..7
        lda tmp5
        clc
        adc #1
        sta tmp6
        asl
        adc tmp6
        sta tmp6
        lda tmp4
        clc
        adc #1
        adc tmp6
        tax
        lda dir_of,x
        sta pdir
        lda tmp4
        beq _nf
        bmi _fl
        lda #0
        beq _sf
_fl     lda #1
_sf     sta pface
_nf
        ; step = speed (8.8)
        lda subx
        clc
        adc spdf
        sta subx
        lda spdi
        adc #0
        sta tmp6
        ; x
        lda tmp4
        beq _y
        bmi _xm
        lda pxl
        clc
        adc tmp6
        sta pxl
        bcc _y
        inc pxh
        jmp _y
_xm     lda pxl
        sec
        sbc tmp6
        sta pxl
        bcs _y
        dec pxh
_y      lda tmp5
        beq _c
        bmi _ym
        lda pyl
        clc
        adc tmp6
        sta pyl
        bcc _c
        inc pyh
        jmp _c
_ym     lda pyl
        sec
        sbc tmp6
        sta pyl
        bcs _c
        dec pyh
_c      inc panim
        jsr hero_cell
_r      rts
dir_of  .byte 5, 6, 7, 4, 0, 0, 3, 2, 1

; ---------------------------------------------------- hero sprites (0 overlay, 1 body with health bar, 2 glow)
hero_sprites
        lda panim
        lsr
        lsr
        and #3
        ldx moving
        bne +
        lda #0
+       asl
        ldx pface
        beq +
        clc
        adc #SPR_HEROL0-SPR_HEROR0
+       clc
        adc #SPR_HEROR0
        ldx dead
        beq +
        lda #SPR_HEROD
+       sta sptr
        clc
        adc #1
        sta bodyfr
        jsr body_bar
        ; blinking after a hit
        lda sen
        ora #%11110011
        sta sen
        lda iframes
        beq +
        lda frame
        and #2
        beq +
        lda sen
        and #%11111100
        sta sen
+
        ; glow
        lda w_lvl+1
        beq _noglow
        lda frame
        lsr
        lsr
        and #1
        clc
        adc #SPR_AURA0
        sta sptr+2
        lda #HEROSX-12
        sta sx+2
        lda #HEROSY-10
        sta sy+2
        lda sen
        ora #%00000100
        sta sen
        rts
_noglow lda sen
        and #%11111011
        sta sen
        rts

; ---------------------------------------------------- time, phases, bosses
time_update
        lda tfr
        clc
        adc elapsed
        sta tfr
        ldx ntsc
        cmp fps_tab,x
        bcc _r
        sbc fps_tab,x
        sta tfr
        jmp +
fps_tab .byte 50, 60
elapsed .byte 2
+
        inc tsecs
        bne +
        inc tsecs+1
+       ; 10 points per second
        sed
        lda score
        clc
        adc #$10
        sta score
        lda score+1
        adc #0
        sta score+1
        lda score+2
        adc #0
        sta score+2
        cld
        inc hudchg
        inc secs
        lda secs
        cmp #60
        bcc _r
        lda #0
        sta secs
        inc mins
        jsr min_phase
        jsr set_palette
_r      rts

min_phase
        ldx mins
        lda phase_of,x
        sta phase
        rts
phase_of .byte 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 3

mul60   ; tsecs = A * 60
        tax
        lda #0
        sta tsecs
        sta tsecs+1
        cpx #0
        beq _r
-       lda tsecs
        clc
        adc #60
        sta tsecs
        bcc +
        inc tsecs+1
+       dex
        bne -
_r      rts

; bosses at the start of minutes 3, 6 and 9
boss_update
        lda b_on
        bne _move
        lda dead
        bne _r
        ldx bossdone
        cpx #3
        bcs _r
        lda mins
        cmp boss_min,x
        bcc _r
        ; appears to the upper right
        stx b_kind
        inc bossdone
        lda #1
        sta b_on
        lda #0
        sta b_fl
        lda boss_hp_lo,x
        sta b_hpl
        lda boss_hp_hi,x
        sta b_hph
        lda pxl
        clc
        adc #150
        sta b_xl
        lda pxh
        adc #0
        sta b_xh
        lda pyl
        sec
        sbc #90
        sta b_yl
        lda pyh
        sbc #0
        sta b_yh
        lda #SFX_BOSS
        jsr sfx_start
        lda musicoff
        bne _r
        lda #TUNE_BOSS
        jmp music_start
_r      rts
_move   lda b_fl
        beq +
        dec b_fl
+       ; follow the hero (centre to centre)
        ldx b_kind
        lda boss_spd,x
        sta tmp6
        ; x
        lda b_xl
        clc
        adc #12
        sta tmp0
        lda b_xh
        adc #0
        sta tmp1
        lda tmp0
        cmp pxl
        lda tmp1
        sbc pxh
        bcs _left
        lda b_xl
        clc
        adc tmp6
        sta b_xl
        bcc _y
        inc b_xh
        jmp _y
_left   lda b_xl
        sec
        sbc tmp6
        sta b_xl
        bcs _y
        dec b_xh
_y      lda b_yl
        clc
        adc #11
        sta tmp0
        lda b_yh
        adc #0
        sta tmp1
        lda tmp0
        cmp pyl
        lda tmp1
        sbc pyh
        bcs _up
        lda b_yl
        clc
        adc tmp6
        sta b_yl
        bcc _hit
        inc b_yh
        jmp _hit
_up     lda b_yl
        sec
        sbc tmp6
        sta b_yl
        bcs _hit
        dec b_yh
_hit    ; touching the hero?
        lda b_xl
        clc
        adc #24
        sta tmp4
        lda b_xh
        adc #0
        sta tmp5
        lda tmp4
        sec
        sbc pxl
        sta tmp4
        lda tmp5
        sbc pxh
        jsr abs_small
        bcs _r2
        cmp #24
        bcs _r2
        lda b_yl
        clc
        adc #21
        sta tmp4
        lda b_yh
        adc #0
        sta tmp5
        lda tmp4
        sec
        sbc pyl
        sta tmp4
        lda tmp5
        sbc pyh
        jsr abs_small
        bcs _r2
        cmp #22
        bcs _r2
        lda #12
        jsr hurt_a
_r2     rts
boss_min  .byte 3, 6, 9
boss_hp_lo .byte <150, <320, <640
boss_hp_hi .byte >150, >320, >640
boss_spd  .byte 2, 1, 1
boss_col  .byte 4, 5, 6

boss_die
        lda #0
        sta b_on
        ; chest and poofs at the boss centre
        lda b_xl
        clc
        adc #24
        sta tmp0
        lda b_xh
        adc #0
        sta tmp1
        lsr tmp1
        ror tmp0
        lsr tmp1
        ror tmp0
        lsr tmp1
        ror tmp0
        lda b_yl
        clc
        adc #21
        sta tmp2
        lda b_yh
        adc #0
        sta tmp3
        lsr tmp3
        ror tmp2
        lsr tmp3
        ror tmp2
        lsr tmp3
        ror tmp2
        lda #5
        jsr drop_gem
        lda #3
        jsr add_fx
        ; 1000 points
        sed
        lda score+1
        clc
        adc #$10
        sta score+1
        lda score+2
        adc #0
        sta score+2
        cld
        lda #SFX_BOSSDIE
        jsr sfx_start
        lda musicoff
        bne +
        lda #TUNE_GAME
        jsr music_start
+       rts

boss_sprite
        lda b_on
        bne +
        lda sen
        and #%11110111
        sta sen
        rts
+       ; screen position = world - camera + (31, 54)
        lda b_xl
        sec
        sbc camxl
        sta tmp0
        lda b_xh
        sbc camxh
        sta tmp1
        lda tmp0
        clc
        adc #31
        sta tmp0
        lda tmp1
        adc #0
        sta tmp1
        bmi _off
        cmp #2
        bcs _off
        lda b_yl
        sec
        sbc camyl
        sta tmp2
        lda b_yh
        sbc camyh
        sta tmp3
        lda tmp2
        clc
        adc #54
        sta tmp2
        lda tmp3
        adc #0
        bne _off
        lda tmp0
        sta sx+3
        lda sxh
        and #%11110111
        ldx tmp1
        beq +
        ora #%00001000
+       sta sxh
        lda tmp2
        sta sy+3
        ldx b_kind
        lda frame
        lsr
        lsr
        lsr
        and #1
        sta tmp4
        txa
        asl
        ora tmp4
        clc
        adc #SPR_BOSS0_0
        sta sptr+3
        lda boss_col,x
        ldy b_fl
        beq +
        lda #1
+       sta sc+3
        lda sen
        ora #%00001000
        sta sen
        rts
_off    lda sen
        and #%11110111
        sta sen
        rts

; ---------------------------------------------------- level up: choose one of three items
level_up
        dec lvpend
        jsr wait_shown
        ; choose 3 different items that are not at their maximum
        lda #0
        sta lu_n
        lda #40
        sta lu_try
_pick   dec lu_try
        beq _picked
        lda #NITEMS
        jsr rndmod
        tax
        jsr item_max
        cmp w_lvl,x
        beq _pick
        bcc _pick
        ; not chosen yet?
        ldy lu_n
        beq +
-       dey
        txa
        cmp lu_opt,y
        beq _pick
        tya
        bne -
+       txa
        ldy lu_n
        sta lu_opt,y
        inc lu_n
        lda lu_n
        cmp #3
        bne _pick
_picked lda lu_n
        bne +
        ; everything at maximum: heal instead
        lda maxhp
        sta hp
        rts
+       lda #SFX_LEVELUP
        jsr sfx_start
        lda $d015               ; only the status sprites stay visible
        and #%11110000
        sta $d015
        lda #0
        sta lu_sel
        jsr lu_draw
        jsr wait_release
        lda #0
        sta lu_ai
_wait   jsr waitframe
        jsr lu_arrows
        jsr joyread
        ldx DBGAI
        beq +
        inc lu_ai
        lda lu_ai
        cmp #60
        bcc _wait
        lda #$10
+       sta tmp0
        and #$10
        bne _take
        lda lu_rep
        beq +
        dec lu_rep
        jmp _wait
+       lda tmp0
        and #3
        beq _wait
        lda #12
        sta lu_rep
        lda #SFX_MOVE
        jsr sfx_start
        lda tmp0
        lsr
        bcc _down
        dec lu_sel
        bpl _wait
        lda lu_n
        sec
        sbc #1
        sta lu_sel
        jmp _wait
_down   inc lu_sel
        lda lu_sel
        cmp lu_n
        bcc _wait
        lda #0
        sta lu_sel
        jmp _wait
_take   ldx lu_sel
        lda lu_opt,x
        jsr take_item
        lda #SFX_CHOOSE
        jsr sfx_start
        jsr wait_release
        jsr set_palette         ; restores the colours of the box
        inc hudchg
        lda frame
        sta lastfr
        rts
lu_n    .byte 0
lu_try  .byte 0
lu_rep  .byte 0
lu_ai   .byte 0

LUROW = 5
LUCOL = 4
; the box on the shown screen
lu_draw
        ldx disp                ; the buffer shown now
        lda scr_hi,x
        sta lu_scr
        ; frame and background, rows LUROW .. LUROW+13, columns LUCOL .. LUCOL+31
        ldx #0
_r      txa
        clc
        adc #LUROW
        tay
        lda rowlo,y
        clc
        adc #LUCOL
        sta ptr0
        sta ptr1
        lda rowhiA,y
        sec
        sbc #>SCRA
        clc
        adc lu_scr
        adc #0
        sta ptr0+1
        lda rowlo,y
        clc
        adc #LUCOL
        lda rowhiC,y
        adc #0
        sta ptr1+1
        ldy #31
-       lda #32
        cpx #0
        bne +
        lda #CH_UI_H
+       cpx #13
        bne +
        lda #CH_UI_H
+       cpy #0
        beq _side
        cpy #31
        bne _put
_side   lda #CH_UI_V
        cpx #0
        bne +
        lda #CH_UI_TL
        cpy #0
        beq _put
        lda #CH_UI_TR
        bne _put
+       cpx #13
        bne _put
        lda #CH_UI_BL
        cpy #0
        beq _put
        lda #CH_UI_BR
_put    sta (ptr0),y
        lda #1
        sta (ptr1),y
        dey
        bpl -
        inx
        cpx #14
        bne _r
        ; title
        lda #<t_lvup
        sta ptr2
        lda #>t_lvup
        sta ptr2+1
        ldx #LUROW+1
        ldy #LUCOL+11
        lda #7
        jsr lu_text
        ; options
        lda #0
        sta tmp6
_o      ldx tmp6
        lda lu_opt,x
        sta tmp7
        ; name
        asl
        tax
        lda item_name,x
        sta ptr2
        lda item_name+1,x
        sta ptr2+1
        lda tmp6
        asl
        clc
        adc tmp6
        adc #LUROW+3
        sta tmp5
        tax
        ldy #LUCOL+4
        lda #1
        jsr lu_text
        ; level / new
        ldx tmp7
        lda w_lvl,x
        bne +
        lda #<t_new
        sta ptr2
        lda #>t_new
        sta ptr2+1
        jmp ++
+       clc
        adc #1+48
        sta t_lvn+3
        lda #<t_lvn
        sta ptr2
        lda #>t_lvn
        sta ptr2+1
+       ldx tmp5
        ldy #LUCOL+24
        lda #3
        jsr lu_text
        ; description
        lda tmp7
        asl
        tax
        lda item_desc,x
        sta ptr2
        lda item_desc+1,x
        sta ptr2+1
        ldx tmp5
        inx
        ldy #LUCOL+4
        lda #15
        jsr lu_text
        inc tmp6
        lda tmp6
        cmp lu_n
        bne _o
        rts
lu_scr  .byte 0
scr_hi  .byte >SCRA, >SCRB

; text ptr2 at row X, column Y, colour A
lu_text
        sta tmp4
        sty tmp3
        lda rowlo,x
        clc
        adc tmp3
        sta ptr0
        sta ptr1
        lda rowhiA,x
        adc #0
        sec
        sbc #>SCRA
        clc
        adc lu_scr
        sta ptr0+1
        lda rowlo,x
        clc
        adc tmp3
        lda rowhiC,x
        adc #0
        sta ptr1+1
        ldy #0
-       lda (ptr2),y
        beq +
        sta (ptr0),y
        lda tmp4
        sta (ptr1),y
        iny
        bne -
+       rts

; arrow in front of the selected option
lu_arrows
        lda #0
        sta tmp6
-       lda tmp6
        asl
        clc
        adc tmp6
        adc #LUROW+3
        tax
        lda rowlo,x
        clc
        adc #LUCOL+2
        sta ptr0
        lda rowhiA,x
        adc #0
        sec
        sbc #>SCRA
        clc
        adc lu_scr
        sta ptr0+1
        lda #32
        ldx tmp6
        cpx lu_sel
        bne +
        lda frame
        and #16
        beq +
        lda #CH_UI_ARROW
        bne ++
+       cpx lu_sel
        bne +
        lda #CH_UI_ARROW
+       ldy #0
        sta (ptr0),y
        inc tmp6
        lda tmp6
        cmp lu_n
        bne -
        rts

t_lvup  .null "LEVEL UP!"
t_new   .null "NEW!"
t_lvn   .null "LV 0"
item_name .word n0, n1, n2, n3, n4, n5, n6, n7, n8
item_desc .word d0, d1, d2, d3, d4, d5, d6, d7, d8
n0      .null "SILVER KNIVES"
n1      .null "LANTERN GLOW"
n2      .null "STORM BELL"
n3      .null "SPIRIT ORBS"
n4      .null "FIRE FLASK"
n5      .null "SWIFT BOOTS"
n6      .null "HOURGLASS"
n7      .null "LODESTONE"
n8      .null "IRON HEART"
d0      .null "FLY AT THE NEAREST FOE"
d1      .null "BURNS EVERYTHING CLOSE"
d2      .null "LIGHTNING FROM ABOVE"
d3      .null "CIRCLE AROUND YOU"
d4      .null "BURSTS AMONG THE FOES"
d5      .null "YOU MOVE FASTER"
d6      .null "WEAPONS RELOAD FASTER"
d7      .null "GEMS FLY TO YOU"
d8      .null "MORE HEALTH, HEALS NOW"

; ---------------------------------------------------- the hero has died
hero_died
        jsr music_stop
        lda #SFX_DIE
        jsr sfx_start
        lda #100
        sta evcnt
-       jsr wait_shown
        jsr waitframe
        jsr waitframe
        jsr fx_update
        jsr build_frame
        dec evcnt
        bne -
        jsr wait_shown
        lda #0
        sta $d015
        jmp game_over

; ---------------------------------------------------- dawn: the night is over
dawn
        jsr music_stop
        lda musicoff
        bne +
        lda #TUNE_DAWN
        jsr music_start
+       ; all creatures vanish
        ldx #NE-1
-       lda e_t,x
        beq +
        stx tmp6
        lda e_xl,x
        sta tmp0
        lda e_xh,x
        sta tmp1
        lda e_yl,x
        sta tmp2
        lda e_yh,x
        sta tmp3
        jsr remove_enemy
        lda #3
        jsr add_fx
        ldx tmp6
+       dex
        bpl -
        lda #0
        sta b_on
        ; 5000 points
        sed
        lda score+1
        clc
        adc #$50
        sta score+1
        lda score+2
        adc #0
        sta score+2
        cld
        ; the sky gets brighter
        lda #0
        sta evcnt
_lp     jsr wait_shown
        jsr waitframe
        jsr waitframe
        jsr fx_update
        jsr build_frame
        lda evcnt
        lsr
        lsr
        lsr
        lsr
        tax
        lda dawn_bg,x
        sta $d021
        inc evcnt
        lda evcnt
        cmp #160
        bne _lp
        jsr wait_shown
        lda #0
        sta $d015
        lda #1
        sta endflag
        jmp ending
dawn_bg .byte 0, 0, 6, 6, 6, 14, 14, 14, 3, 3, 3
evcnt   .byte 0

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
        ldx b_on
        beq +
        lda #TUNE_BOSS
+       jmp music_start
_r      rts

pause_game
        jsr wait_shown
        lda #0
        sta $d418
        ; "PAUSED" in the time sprite
        lda #<(SPRDATA+(SPR_HUDT-$40)*64)
        sta ptr0
        lda #>(SPRDATA+(SPR_HUDT-$40)*64)
        sta ptr0+1
        ldx #4
-       lda t_pause,x
        sta txtbuf,x
        dex
        bpl -
        jsr hud_text
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
        inc hudchg
        lda frame
        sta lastfr
        rts
t_pause .byte 14, 10, 14, 10, 14         ; " : : " (blinking dots)

; ---------------------------------------------------- autopilot (testing only)
; walks away from the side with more creatures nearby, otherwise in a slow circle
autopilot
        inc aiturn
        lda #0
        sta ai_l
        sta ai_r
        sta ai_u
        sta ai_d
        ldx #NE-1
_e      lda e_t,x
        beq _n
        lda pcxl
        sec
        sbc e_xl,x
        sta tmp4
        lda pcxh
        sbc e_xh,x
        jsr abs_small
        bcs _n
        cmp #9
        bcs _n
        lda pcyl
        sec
        sbc e_yl,x
        sta tmp4
        lda pcyh
        sbc e_yh,x
        jsr abs_small
        bcs _n
        cmp #7
        bcs _n
        ; which side?
        lda e_xl,x
        sec
        sbc pcxl
        bmi +
        inc ai_r
        jmp ++
+       inc ai_l
+       lda e_yl,x
        sec
        sbc pcyl
        bmi +
        inc ai_d
        jmp _n
+       inc ai_u
_n      dex
        bpl _e
        lda ai_l
        ora ai_r
        ora ai_u
        ora ai_d
        bne +
        ; nothing near: circle
        lda aiturn
        lsr
        lsr
        lsr
        lsr
        lsr
        and #7
        tax
        lda ai_dirs,x
        rts
+       lda #0
        sta tmp5
        lda ai_l
        cmp ai_r
        beq +
        bcc ++
        lda #8                  ; more on the left: go right
        sta tmp5
        jmp +
+       lda #4
        sta tmp5
+       lda ai_u
        cmp ai_d
        beq _done
        bcc +
        lda tmp5
        ora #2
        sta tmp5
        jmp _done
+       lda tmp5
        ora #1
        sta tmp5
_done   lda tmp5
        bne +
        lda #8
+       rts
ai_dirs .byte 8, 10, 2, 6, 4, 5, 1, 9
ai_l    .byte 0
ai_r    .byte 0
ai_u    .byte 0
ai_d    .byte 0
