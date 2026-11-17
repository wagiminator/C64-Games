; =====================================================================
;  Game flow: levels, input, swapping, resolving, texts, meter
; =====================================================================

; ---------------------------------------------------- start a new game
new_game
        ldx #$ff
        txs
        lda #0
        sta score
        sta score+1
        sta score+2
        sta endflag
        lda #3
        sta lives
        lda #0
        ldx cheat
        beq +
        lda startzone
+       sta level

; ---------------------------------------------------- start (or retry) the current level
level_start
        ldx #$ff
        txs
        lda #$0b
        sta $d011
        lda #0
        sta $d015
        jsr irq_simple_on
        jsr waitframe
        jsr clear_game_screen
        jsr draw_decor
        jsr meter_colour
        ; ---- level parameters
        ldx level
        lda lv_goal,x
        sta goal
        lda lv_moves,x
        sta moves
        lda lv_cols,x
        sta ncol
        lda lv_t0,x
        sta target
        lda lv_t1,x
        sta target+1
        lda lv_t2,x
        sta target+2
        lda lv_tbin,x
        sta tbin
        lda lv_lay,x
        tay
        lda lay_lo,y
        sta ptr0
        lda lay_hi,y
        sta ptr0+1
        lda #0
        sta iceleft
        ldy #80
-       lda (ptr0),y
        sta ice,y
        clc
        adc iceleft
        sta iceleft
        dey
        bpl -
        lda iceleft
        sta icetotal
        lda #0
        sta lscore
        sta lscore+1
        sta lscore+2
        sta pts20
        sta pts20+1
        sta selected
        sta reptime
        sta idle
        sta idle+1
        sta msgtime
        sta meterh
        sta aitime
        ldx #8
        lda #0
-       sta colmov,x
        dex
        bpl -
        lda #4
        sta cr
        sta cc
        lda #2
        sta rbcol
        lda #$ff
        sta sa
        sta sb
        sta rbtarget
        ; ---- board
        jsr fill_board
        jsr dlist_all
        jsr render_all
        jsr draw_meter
        jsr texts_all
        ; ---- sprites: 0 cursor (hires), 1 + 2 swapped sweets (multicolour), 3 + 4 hint (hires)
        lda #%00000110
        sta $d01c
        lda #1
        sta $d025
        lda #BGCOL
        sta $d026
        sta $d021
        lda #0
        sta $d017
        sta $d01d
        sta $d01b
        sta $d020
        sta $d010
        lda #SPR_CURSOR0
        sta SCRG+$3f8
        sta SCRG+$3fb
        sta SCRG+$3fc
        lda #1
        sta $d027
        lda #7
        sta $d02a
        sta $d02b
        jsr cursor_sprite
        lda #%00000001
        sta $d015
        jsr irq_game_on
        jsr waitframe
        lda musicoff
        bne +
        lda #TUNE_GAME
        jsr music_start
+       ; "LEVEL 01" message
        lda #<t_lvmsg
        sta ptr0
        lda #>t_lvmsg
        sta ptr0+1
        jsr message
        lda level
        clc
        adc #1
        jsr bin2bcd
        pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRG+24*40+19
        pla
        and #15
        ora #48
        sta SCRG+24*40+20

; ---------------------------------------------------- waiting for a move
play_loop
        jsr waitframe
        jsr read_input
        jsr keys
        jsr rainbow_cycle
        jsr msg_update
        ; ---- autopilot (testing)
        lda DBGAI
        beq _human
        inc aitime
        lda aitime
        cmp #25
        bcc _human
        lda #0
        sta aitime
        jsr find_move
        bcc _human
        lda hint_a
        jsr set_cursor
        lda hint_a
        ldx hint_b
        jsr do_swap
        jmp play_loop
_human  ; ---- fire: select / deselect
        lda joynew
        and #$10
        beq +
        lda selected
        eor #1
        sta selected
        lda #SFX_SELECT
        jsr sfx_start
        jsr idle_reset
+       ; ---- directions with auto repeat
        lda joy
        and #$0f
        bne +
        sta reptime
        beq _hint
+       sta tmp7
        lda reptime
        beq _act
        dec reptime
        bne _hint
        lda #5
        sta reptime
        bne _act2
_act    lda #14
        sta reptime
_act2   jsr idle_reset
        lda selected
        bne _swap
        ; move the cursor
        lda tmp7
        lsr
        bcc +
        lda cr
        beq +
        dec cr
+       lda tmp7
        and #2
        beq +
        lda cr
        cmp #8
        beq +
        inc cr
+       lda tmp7
        and #4
        beq +
        lda cc
        beq +
        dec cc
+       lda tmp7
        and #8
        beq +
        lda cc
        cmp #8
        beq +
        inc cc
+       jmp _hint
_swap   ; swap with the neighbour in the direction
        jsr cursor_cell
        sta tmp6
        ldx #$ff
        lda tmp7
        lsr
        bcc +
        lda cr
        beq _nos
        lda tmp6
        sec
        sbc #9
        tax
        jmp _doit
+       lda tmp7
        and #2
        beq +
        lda cr
        cmp #8
        beq _nos
        lda tmp6
        clc
        adc #9
        tax
        jmp _doit
+       lda tmp7
        and #4
        beq +
        lda cc
        beq _nos
        ldx tmp6
        dex
        jmp _doit
+       lda cc
        cmp #8
        beq _nos
        ldx tmp6
        inx
_doit   lda #0
        sta selected
        lda tmp6
        jsr do_swap
        jmp play_loop
_nos    lda #0
        sta selected
_hint   ; ---- hint after a while
        inc idle
        bne +
        inc idle+1
+       lda idle+1
        bne _show
        lda idle
        cmp #250
        bcc _nohint
_show   lda frame
        and #16
        beq _nohint
        lda hint_a
        ldx #3
        jsr cell_sprite
        lda hint_b
        ldx #4
        jsr cell_sprite
        lda $d015
        ora #%00011000
        sta $d015
        jmp +
_nohint lda $d015
        and #%11100111
        sta $d015
+       jsr cursor_sprite
        jmp play_loop

idle_reset
        lda #0
        sta idle
        sta idle+1
        rts

; cursor cell index -> A
cursor_cell
        lda cr
        asl
        asl
        asl
        adc cr
        adc cc
        rts
; A = cell -> cursor there
set_cursor
        sta tmp0
        jsr cell_rc
        lda tmp1
        sta cr
        lda tmp2
        sta cc
        rts

cursor_sprite
        jsr cursor_cell
        ldx #0
        jsr cell_sprite
        dec $d000
        dec $d001
        ; selected: thick and blinking yellow
        lda selected
        beq +
        lda #SPR_CURSOR1
        sta SCRG+$3f8
        lda frame
        and #8
        beq ++
        lda #7
        bne +++
+       lda #SPR_CURSOR0
        sta SCRG+$3f8
+       lda #1
+       sta $d027
        rts

; sprite X to the position of cell A
cell_sprite
        sta tmp0
        txa
        asl
        sta tmp3
        jsr cell_rc
        ldx tmp3
        lda tmp2
        asl
        asl
        asl
        asl
        clc
        adc #24+BX0*8
        sta $d000,x
        lda tmp1
        asl
        asl
        asl
        asl
        clc
        adc #50+BY0
        sta $d001,x
        rts

; ---------------------------------------------------- input
read_input
        jsr joyread
        sta joy
        lda joyprev
        eor #$ff
        and joy
        sta joynew
        lda joy
        sta joyprev
        rts

; ---------------------------------------------------- swap cells A and X
do_swap
        sta sa
        stx sb
        lda #$ff
        sta rbtarget
        jsr idle_reset
        lda $d015
        and #%11100111
        sta $d015
        lda #SFX_SWAP
        jsr sfx_start
        ; sweets as sprites
        lda sa
        ldx #1
        jsr sweet_sprite
        lda sb
        ldx #2
        jsr sweet_sprite
        ; hide them on the board
        lda sa
        jsr hide_cell
        lda sb
        jsr hide_cell
        lda $d015
        ora #%00000110
        sta $d015
        ; animate 8 x 2 pixels
        jsr swap_anim
        ; swap on the board
        ldx sa
        ldy sb
        lda board,x
        pha
        lda board,y
        sta board,x
        pla
        sta board,y
        ; valid?
        lda #0
        sta swspec
        lda board,x
        cmp #RAINBOW
        beq _rb
        lda board,y
        cmp #RAINBOW
        beq _rb
        lda board,x
        and #$18
        beq +
        lda board,y
        and #$18
        beq +
        lda #2
        sta swspec
        bne _ok
+       jsr find_matches
        bcs _ok
        ; ---- not valid: swap back
        lda #SFX_BACK
        jsr sfx_start
        jsr swap_back_anim
        ldx sa
        ldy sb
        lda board,x
        pha
        lda board,y
        sta board,x
        pla
        sta board,y
        jsr show_cells
        lda #$ff
        sta sa
        sta sb
        rts
_rb     lda #1
        sta swspec
_ok     jsr show_cells
        ; one move used
        lda cheat
        bne +
        dec moves
+       jsr text_moves
        jsr resolve
        lda #$ff
        sta sa
        sta sb
        jsr check_goal
        rts

; sweet of cell A as sprite X (1 or 2)
sweet_sprite
        stx tmp4
        tax
        lda board,x
        jsr shape_of
        ldy tmp4
        pha
        txa
        sta $d027,y
        pla
        cmp #25
        bcc +
        lda #24
+       clc
        adc #SPR_SWEET0
        sta SCRG+$3f8,y
        lda sa
        cpy #1
        beq +
        lda sb
+       ldx tmp4
        jmp cell_sprite

; remove cell A from the display (only)
hide_cell
        sta tmp0
        jsr cell_rc
        lda tmp2
        asl
        asl
        asl
        adc tmp2
        adc tmp1
        tax
        lda #EMPTY
        sta dcode,x
        ldx tmp2
        jmp render_column

; display lists of the two swapped columns from the board, sprites off
show_cells
        lda sa
        sta tmp0
        jsr cell_rc
        ldx tmp2
        stx sc_c1
        jsr dlist_from_board
        jsr render_column
        lda sb
        sta tmp0
        jsr cell_rc
        ldx tmp2
        cpx sc_c1
        beq +
        jsr dlist_from_board
        jsr render_column
+       lda $d015
        and #%11111001
        sta $d015
        rts
sc_c1   .byte 0

; move sprite 1 towards cell sb and sprite 2 towards cell sa
swap_anim
        lda #8
        sta tmp6
-       jsr wait_keys
        jsr swap_step
        dec tmp6
        bne -
        rts
swap_back_anim
        lda #8
        sta tmp6
-       jsr wait_keys
        jsr swap_step_back
        dec tmp6
        bne -
        rts
; direction: sb - sa = 1 (right), 9 (down)
swap_step
        jsr swap_dir
        bne _v
        inc $d002
        inc $d002
        dec $d004
        dec $d004
        rts
_v      inc $d003
        inc $d003
        dec $d005
        dec $d005
        rts
swap_step_back
        jsr swap_dir
        bne _v
        dec $d002
        dec $d002
        inc $d004
        inc $d004
        rts
_v      dec $d003
        dec $d003
        inc $d005
        inc $d005
        rts
; Z = 1: horizontal; sa < sb is made sure by swapping
swap_dir
        lda sb
        cmp sa
        bcs +
        ; sb < sa: exchange so that sa is left / above
        ldx sa
        stx sb
        sta sa
        ; swap the sprites too
        ldx #3
-       lda $d002,x
        pha
        dex
        bpl -
        lda $d004
        sta $d002
        lda $d005
        sta $d003
        pla
        pla
        pla
        pla
        ; (positions only matter: re-place both sprites)
        lda sa
        ldx #1
        jsr sweet_sprite
        lda sb
        ldx #2
        jsr sweet_sprite
        lda sb
+       sec
        sbc sa
        cmp #1
        beq +
        lda #1
        rts
+       lda #0
        rts

; ---------------------------------------------------- resolve matches, specials and cascades
resolve
        lda #0
        sta cascade
_loop   inc cascade
        lda swspec
        beq _normal
        ; ---- first step after swapping specials
        ldx #80
        lda #0
-       sta mark,x
        dex
        bpl -
        sta ncre
        lda swspec
        cmp #2
        beq _two
        ; a rainbow: all sweets of the partner's colour
        ldx sa
        ldy sb
        lda board,x
        cmp #RAINBOW
        bne +
        lda board,y
        cmp #RAINBOW
        bne _rb1
        ; two rainbows: the whole board
        ldx #80
        lda #4
-       sta mark,x
        dex
        bpl -
        jmp _sp
+       ; sb is the rainbow
        tya
        tax
        ldy sa
_rb1    ; x = rainbow, y = partner
        lda #$44
        sta mark,x
        lda board,y
        jsr colour_of
        jsr ex_colour
        lda #SFX_RAINBOW
        jsr sfx_start
        jmp _sp
_two    ldx sa
        lda #4
        sta mark,x
        ldx sb
        sta mark,x
_sp     lda #0
        sta swspec
        jmp _found
_normal jsr find_matches
        bcs _found
        jmp _end
_found  jsr expand_specials
        ; ---- count, score, ice
        lda #0
        sta tmp7
        ldx #80
_cnt    lda mark,x
        beq _nc
        inc tmp7
        lda ice,x
        beq _nc
        dec ice,x
        dec iceleft
        stx tmp6
        lda #5
        jsr add_units
        lda #SFX_ICE
        jsr sfx_start
        ldx tmp6
_nc     dex
        bpl _cnt
        ; 60 points x cascade per sweet
        lda tmp7
        sta tmp6
-       lda cascade
        cmp #6
        bcc +
        lda #5
+       sta tmp5
        asl
        adc tmp5                ; 3 units per cascade step
        jsr add_units
        dec tmp6
        bne -
        ; creations: 200 points each
        ldx ncre
        beq +
-       lda #10
        stx tmp6
        jsr add_units
        ldx tmp6
        dex
        bne -
        lda #SFX_SPECIAL
        jsr sfx_start
+       ; sound by cascade
        ldx cascade
        cpx #4
        bcc +
        ldx #3
+       lda pop_sfx-1,x
        jsr sfx_start
        jsr cascade_msg
        jsr text_score
        ; ---- pop animation
        lda #$40
        jsr show_pops
        ldx #5
        jsr wait_x
        lda #$50
        jsr show_pops
        ldx #5
        jsr wait_x
        ; ---- fall
        jsr gravity_setup
        jsr animate_fall
        jsr update_meter
        jsr text_goal
        jmp _loop
_end    ; no more matches: any moves left?
        jsr find_move
        bcs +
        lda #<t_shuffle
        sta ptr0
        lda #>t_shuffle
        sta ptr0+1
        jsr message
        lda #SFX_SHUFFLE
        jsr sfx_start
        ldx #40
        jsr wait_x
        jsr shuffle
        jsr dlist_all
        jsr render_all
        jmp _loop
+       rts
pop_sfx .byte SFX_POP, SFX_POP2, SFX_POP3

; marked cells as pop frame A ($40 / $50) in the display, render those columns
show_pops
        sta sp_f
        lda #0
        sta sp_c                ; column
_c      lda #0
        sta sp_n                ; marked in this column
        ldy #0                  ; row
-       tya
        asl
        asl
        asl
        sta tmp2
        tya
        clc
        adc tmp2
        adc sp_c
        tax
        lda mark,x
        beq +
        inc sp_n
        lda board,x
        and #7
        ora sp_f
        pha
        lda sp_c
        asl
        asl
        asl
        adc sp_c
        sta tmp2
        tya
        clc
        adc tmp2
        tax
        pla
        sta dcode,x
+       iny
        cpy #9
        bne -
        lda sp_n
        beq +
        ldx sp_c
        jsr render_column
+       inc sp_c
        lda sp_c
        cmp #9
        bne _c
        rts
sp_f    .byte 0
sp_c    .byte 0
sp_n    .byte 0

wait_x
-       jsr wait_keys
        dex
        bne -
        rts

; one frame, with pause and music keys (X is kept)
wait_keys
        txa
        pha
        jsr waitframe
        jsr keys
        pla
        tax
        rts

; ---------------------------------------------------- goal reached / out of moves
check_goal
        lda goal
        bne _ice
        ; level score >= target?
        lda lscore+2
        cmp target+2
        bcc _moves
        bne _won
        lda lscore+1
        cmp target+1
        bcc _moves
        bne _won
        lda lscore
        cmp target
        bcs _won
        jmp _moves
_ice    lda iceleft
        beq _won
_moves  lda moves
        beq _lost
        rts
_won    jmp level_won
_lost   jmp level_lost

level_won
        lda #<t_clear
        sta ptr0
        lda #>t_clear
        sta ptr0+1
        jsr message
        lda musicoff
        bne +
        lda #TUNE_CLEAR
        jsr music_start
+       ldx #60
        jsr wait_x
        ; bonus for the moves left: 300 points each
-       lda moves
        beq +
        dec moves
        lda #15
        jsr add_units
        jsr text_moves
        jsr text_score
        lda #SFX_BONUS
        jsr sfx_start
        ldx #6
        jsr wait_x
        jmp -
+       ldx #120
        jsr wait_x
        inc level
        lda level
        cmp #NLEVELS
        bcc +
        lda #1
        sta endflag
        jsr music_stop
        jmp ending
+       jmp level_start

level_lost
        lda #<t_lost
        sta ptr0
        lda #>t_lost
        sta ptr0+1
        jsr message
        jsr music_stop
        lda #SFX_FAIL
        jsr sfx_start
        ldx #150
        jsr wait_x
        dec lives
        bne +
        jmp game_over
+       jmp level_start

; ---------------------------------------------------- points: A units of 20 points
add_units
        tax
        beq _r
-       sed
        lda score
        clc
        adc #$20
        sta score
        lda score+1
        adc #0
        sta score+1
        lda score+2
        adc #0
        sta score+2
        lda lscore
        clc
        adc #$20
        sta lscore
        lda lscore+1
        adc #0
        sta lscore+1
        lda lscore+2
        adc #0
        sta lscore+2
        cld
        inc pts20
        bne +
        inc pts20+1
+       dex
        bne -
_r      rts

; ---------------------------------------------------- the goal meter
update_meter
        lda goal
        bne _ice
        ; q = tbin * 10, acc = pts20 * 64
        lda tbin
        sta tmp0
        lda #0
        sta tmp1
        asl tmp0
        rol tmp1                ; *2
        lda tmp0
        sta tmp2
        lda tmp1
        sta tmp3
        asl tmp0
        rol tmp1
        asl tmp0
        rol tmp1                ; *8
        lda tmp0
        clc
        adc tmp2
        sta tmp0
        lda tmp1
        adc tmp3
        sta tmp1                ; q = *10
        lda pts20
        sta tmp2
        lda pts20+1
        sta tmp3
        jmp _div
_ice    lda icetotal
        beq _full
        sta tmp0
        lda #0
        sta tmp1
        lda icetotal
        sec
        sbc iceleft
        sta tmp2
        lda #0
        sta tmp3
_div    ; acc (tmp2/tmp3/tmp4) = value * 64
        lda #0
        sta tmp4
        ldx #6
-       asl tmp2
        rol tmp3
        rol tmp4
        dex
        bne -
        ldx #0
-       cpx #64
        bcs _set
        lda tmp2
        sec
        sbc tmp0
        sta tmp5
        lda tmp3
        sbc tmp1
        sta tmp6
        lda tmp4
        sbc #0
        bcc _set
        sta tmp4
        lda tmp6
        sta tmp3
        lda tmp5
        sta tmp2
        inx
        bne -
_full   ldx #64
_set    lda meter_h,x
        cmp meterh
        beq +
        sta meterh
        jmp draw_meter
+       rts

; ---------------------------------------------------- texts (rows 21..24 of the game screen)
texts_all
        ldx #39
-       lda t_row21,x
        sta SCRG+21*40,x
        lda t_row23,x
        sta SCRG+23*40,x
        lda #15
        sta COLRAM+21*40,x
        sta COLRAM+22*40,x
        sta COLRAM+23*40,x
        lda #7
        sta COLRAM+24*40,x
        dex
        bpl -
        ; highlight the numbers
        lda #1
        ldx #1
        sta COLRAM+21*40+7
        sta COLRAM+21*40+8
        ldx #5
-       sta COLRAM+21*40+20,x
        sta COLRAM+23*40+31,x
        dex
        bpl -
        sta COLRAM+21*40+37
        sta COLRAM+21*40+38
        ; level number
        lda level
        clc
        adc #1
        jsr bin2bcd
        ldx #7
        jsr put_bcd2
        jsr text_score
        jsr text_moves
        jsr text_goal
        ; lives
        ldx #0
-       lda #32
        cpx lives
        bcs +
        lda #CH_HEART
+       sta SCRG+23*40+7,x
        lda #10
        sta COLRAM+23*40+7,x
        inx
        cpx #5
        bne -
        ; hiscore
        ldx #31
        lda hiscores+5
        jsr put_bcd2_23
        lda hiscores+4
        jsr put_bcd2_23
        lda hiscores+3
        jmp put_bcd2_23
t_row21 .text " LEVEL 00     SCORE 000000     MOVES 00 "
t_row23 .text " LIVES                    HIGH 000000   "

text_score
        ldx #20
        lda score+2
        jsr put_bcd2
        lda score+1
        jsr put_bcd2
        lda score
        jmp put_bcd2
text_moves
        lda moves
        jsr bin2bcd
        ldx #37
        jmp put_bcd2

text_goal
        ldx #39
        lda #32
-       sta SCRG+22*40,x
        dex
        bpl -
        lda goal
        bne _ice
        ldx #0
-       lda t_goal_s,x
        beq +
        sta SCRG+22*40+3,x
        inx
        bne -
+       ldx #9
        lda target+2
        jsr put_bcd2_22
        lda target+1
        jsr put_bcd2_22
        lda target
        jsr put_bcd2_22
        ldx #29
        lda lscore+2
        jsr put_bcd2_22
        lda lscore+1
        jsr put_bcd2_22
        lda lscore
        jmp put_bcd2_22
_ice    ldx #0
-       lda t_goal_i,x
        beq +
        sta SCRG+22*40+3,x
        inx
        bne -
+       lda iceleft
        ldx #0
-       cmp #100
        bcc +
        sbc #100
        inx
        bne -
+       pha
        txa
        ora #48
        sta SCRG+22*40+34
        pla
        jsr bin2bcd
        ldx #35
        jmp put_bcd2_22
t_goal_s .null "GOAL: 000000 POINTS   NOW 000000"
t_goal_i .null "GOAL: CLEAR ALL THE ICE   LEFT 000"

; A = BCD -> two digits at row 21 / 22 / 23, column X (X += 2)
put_bcd2
        pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRG+21*40,x
        pla
        and #15
        ora #48
        sta SCRG+21*40+1,x
        inx
        inx
        rts
put_bcd2_22
        pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRG+22*40,x
        pla
        and #15
        ora #48
        sta SCRG+22*40+1,x
        inx
        inx
        rts
put_bcd2_23
        pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRG+23*40,x
        pla
        and #15
        ora #48
        sta SCRG+23*40+1,x
        inx
        inx
        rts

; A (0..99) -> BCD
bin2bcd
        ldx #0
-       cmp #10
        bcc +
        sbc #10
        inx
        bne -
+       sta tmp0
        txa
        asl
        asl
        asl
        asl
        ora tmp0
        rts

; message (ptr0, zero terminated) centred in row 24
message
        ldx #39
        lda #32
-       sta SCRG+24*40,x
        dex
        bpl -
        ldy #0
-       lda (ptr0),y
        beq +
        iny
        bne -
+       tya
        lsr
        eor #$ff
        sec
        adc #20
        tax
        ldy #0
-       lda (ptr0),y
        beq +
        sta SCRG+24*40,x
        inx
        iny
        bne -
+       lda #120
        sta msgtime
        rts
msg_update
        lda msgtime
        beq +
        dec msgtime
        bne +
        ldx #39
        lda #32
-       sta SCRG+24*40,x
        dex
        bpl -
+       ; message colours flash
        lda frame
        lsr
        lsr
        and #7
        tax
        lda msg_cols,x
        ldx #39
-       sta COLRAM+24*40,x
        dex
        bpl -
        rts
msg_cols .byte 7,7,8,10,1,10,8,7

cascade_msg
        lda cascade
        cmp #3
        bcc _r
        cmp #5
        bcs _5
        cmp #4
        bcs _4
        lda #<t_yummy
        ldx #>t_yummy
        bne +
_4      lda #<t_superb
        ldx #>t_superb
        bne +
_5      lda #<t_amazing
        ldx #>t_amazing
+       sta ptr0
        stx ptr0+1
        jmp message
_r      rts

t_lvmsg   .null "LEVEL 00 - GO!"
t_shuffle .null "NO MORE MOVES - SHUFFLE!"
t_clear   .null "LEVEL CLEAR!  BONUS FOR EVERY MOVE LEFT"
t_lost    .null "OUT OF MOVES!"
t_yummy   .null "YUMMY!"
t_superb  .null "SUPERB!"
t_amazing .null "AMAZING!"
t_paused  .null "PAUSED"

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
        lda #<t_paused
        sta ptr0
        lda #>t_paused
        sta ptr0+1
        jsr message
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
