; =====================================================================
;  Title screen, game over, ending, hiscore entry
; =====================================================================

        .virtual $03b0
tpanel  .byte ?
ttimer  .word ?
lastscan .byte ?
fadepos .byte ?
hsrank  .byte ?
hscur   .byte ?
hsletter .byte ?
hsdelay .byte ?
tb_t    .byte ?
        .endv

LOGOROW = 1

; ---------------------------------------------------- common
screen_setup                    ; blank, simple irq, clear screen
        lda #$0b
        sta $d011
        jsr irq_simple_on
        lda #0
        sta $d015
        sta $d017
        sta $d01d
        sta $d01b
        sta $d020
        sta $d021
        lda #1
        jsr clear_screen
        rts

screen_show
        jsr waitframe
        lda #$1b
        sta $d011
        rts

; (no starfield on the menu screens of SUNRUSH)
starfill_rows
starfill_all
        rts

; clear rows tmp6..tmp7-1 to spaces
clear_rows
        ldx tmp6
-       lda rowlo,x
        sta ptr0
        lda rowhi,x
        sta ptr0+1
        ldy #39
        lda #32
-       sta (ptr0),y
        dey
        bpl -
        inx
        cpx tmp7
        bne --
        rts

; wait until fire released
wait_release
-       jsr waitframe
        jsr joyread
        and #$10
        bne -
        rts

; A = frames to wait (x2), returns early (C=1) on fire
wait_or_fire
        sta tmp7
-       jsr waitframe
        jsr waitframe
        jsr joyread
        and #$10
        bne _f
        dec tmp7
        bne -
        clc
        rts
_f      sec
        rts

; print list: ptr3 -> [row, colour, text..0]* , $ff
print_list
        ldy #0
        lda (ptr3),y
        cmp #$ff
        beq _done
        sta tmp1
        iny
        lda (ptr3),y
        sta tmp2
        lda ptr3
        clc
        adc #2
        sta ptr0
        lda ptr3+1
        adc #0
        sta ptr0+1
        jsr print_centre
        ; skip string
        ldy #0
-       lda (ptr0),y
        beq +
        iny
        bne -
+       iny
        tya
        clc
        adc ptr0
        sta ptr3
        lda ptr0+1
        adc #0
        sta ptr3+1
        jmp print_list
_done   rts

; ---------------------------------------------------- title
title_screen
        ldx #$ff
        txs
        jsr music_stop
        jsr screen_setup
        ; logo
        ldx #0
-       lda logo_chars,x
        sta SCR+LOGOROW*40,x
        lda logo_chars+160,x
        sta SCR+LOGOROW*40+160,x
        inx
        cpx #160
        bne -
        lda #<t_title
        sta ptr3
        lda #>t_title
        sta ptr3+1
        jsr print_list
        lda #0
        sta tpanel
        jsr draw_panel
        lda #0
        sta tmp6
        lda #25
        sta tmp7
        jsr starfill_rows
        jsr show_cheat
        jsr title_sprites
        lda #TUNE_TITLE
        jsr music_start
        jsr screen_show
        lda #0
        sta ttimer
        sta ttimer+1
        sta cheatidx
        lda #$ff
        sta lastscan
        jsr wait_release
_loop   jsr waitframe
        jsr title_bounce
        ; logo colour cycling
        lda frame
        lsr
        lsr
        sta tmp0
        ldx #0
_lr     txa
        clc
        adc tmp0
        and #15
        tay
        lda logo_grad,y
        sta tmp1
        txa
        clc
        adc #LOGOROW
        tay
        lda rowlo,y
        sta ptr0
        lda rowhiC,y
        sta ptr0+1
        ldy #39
        lda tmp1
-       sta (ptr0),y
        dey
        bpl -
        inx
        cpx #LOGOROWS
        bne _lr
        ; panel switch
        inc ttimer
        bne +
        inc ttimer+1
+       lda ttimer
        cmp #<350
        bne +
        lda ttimer+1
        cmp #>350
        bne +
        lda #0
        sta ttimer
        sta ttimer+1
        lda tpanel
        eor #1
        sta tpanel
        jsr draw_panel
+       ; keyboard: cheat code & stage select
        jsr scan_key
        cmp lastscan
        beq _nokey
        sta lastscan
        cmp #$ff
        beq _nokey
        jsr cheat_key
_nokey  jsr joyread
        and #$10
        bne +
        jmp _loop
+
        lda #SFX_MENU
        jsr sfx_start
        jsr wait_release
        jmp new_game

cheat_key
        ldx cheat
        bne _sel
        ldx cheatidx
        cmp cheatcode,x
        beq _ok
        ldx #0
        cmp cheatcode
        bne +
        inx
+       stx cheatidx
        rts
_ok     inx
        stx cheatidx
        cpx #CHEATLEN
        bne +
        lda #1
        sta cheat
        lda #SFX_CHEAT
        jsr sfx_start
        jsr show_cheat
+       rts
_sel    ; start land with the keys 1..5
        ldx #4
-       cmp minkeys,x
        beq +
        dex
        bpl -
        rts
+       stx startzone
        lda #SFX_MENU
        jsr sfx_start
        jmp show_cheat
cheatcode .byte 26,38,42,18,14,39          ; G O L D E N
CHEATLEN = 6
minkeys .byte 56,59,8,11,16               ; 1 2 3 4 5

show_cheat
        lda cheat
        beq _scr
        #print t_cheaton, 4, 21, 2
        lda startzone
        clc
        adc #49
        sta SCR+21*40+4+(t_cheaton_end-t_cheaton-1)
_scr    rts

draw_panel
        lda #11
        sta tmp6
        lda #20
        sta tmp7
        jsr clear_rows
        lda tpanel
        bne _hs
        lda #<t_instr
        sta ptr3
        lda #>t_instr
        sta ptr3+1
        jsr print_list
        jmp _sf
_hs     jsr draw_hiscores
_sf     lda #11
        sta tmp6
        lda #20
        sta tmp7
        jmp starfill_rows

draw_hiscores
        #print t_hof, 14, 11, 7
        ldx #0                  ; entry
_e      stx hsrank
        txa
        clc
        adc #13
        tay
        lda rowlo,y
        clc
        adc #12
        sta ptr0
        sta ptr1
        lda rowhi,y
        adc #0
        sta ptr0+1
        lda rowlo,y
        clc
        adc #12
        lda rowhiC,y
        adc #0
        sta ptr1+1
        ; rank
        txa
        clc
        adc #49
        ldy #0
        sta (ptr0),y
        iny
        lda #46
        sta (ptr0),y
        ; name
        txa
        asl
        sta tmp0
        asl
        clc
        adc tmp0
        tax                     ; x = entry*6
        ldy #4
        lda hiscores,x
        sta (ptr0),y
        iny
        lda hiscores+1,x
        sta (ptr0),y
        iny
        lda hiscores+2,x
        sta (ptr0),y
        ; score digits at +10
        ldy #10
        lda hiscores+5,x
        jsr _d2
        lda hiscores+4,x
        jsr _d2
        lda hiscores+3,x
        jsr _d2
        ; colours
        ldy #16
        ldx hsrank
        lda hs_cols,x
-       sta (ptr1),y
        dey
        bpl -
        ldx hsrank
        inx
        cpx #5
        bne _e
        rts
_d2     pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta (ptr0),y
        iny
        pla
        and #15
        ora #48
        sta (ptr0),y
        iny
        rts
hs_cols .byte 7,1,3,3,3

t_hof   .null "HALL OF FAME"

t_title .byte 9,7
        .null "RUN FOR YOUR LIFE!"
        .byte 20,1
        .null "PRESS FIRE TO START"
        .byte 10,4
        .null "CODE, GRAPHICS & SOUND: CLAUDE 2026"
        .byte $ff
t_instr .byte 11,7
        .null "LEFT/RIGHT: CHANGE LANE"
        .byte 12,7
        .null "UP OR FIRE: JUMP   DOWN: SLIDE"
        .byte 14,1
        .null "THE BOULDER IS RIGHT BEHIND YOU!"
        .byte 15,3
        .null "DODGE BLOCKS, JUMP HURDLES, SLIDE"
        .byte 16,3
        .null "UNDER BARS AND GRAB THE COINS."
        .byte 18,1
        .null "ESCAPE THROUGH FIVE LANDS!"
        .byte 19,5
        .null "P: PAUSE   M: MUSIC ON/OFF"
        .byte $ff
t_cheaton .null "CHEAT ON! KEYS 1-5: START LAND "
t_cheaton_end

; ---------------------------------------------------- game over
game_over
        jsr screen_setup
        jsr starfill_all
        lda #<t_gover
        sta ptr0
        lda #>t_gover
        sta ptr0+1
        lda #11
        sta tmp1
        lda #2
        sta tmp2
        jsr print_centre
        lda #<t_caught
        ldx #>t_caught
        ldy pdead
        cpy #2
        beq +
        lda #<t_crashed
        ldx #>t_crashed
+       sta ptr0
        stx ptr0+1
        lda #9
        sta tmp1
        lda #10
        sta tmp2
        jsr print_centre
        jsr print_final_score
        jsr screen_show
        lda #TUNE_OVER
        jsr music_start
        lda #40
        jsr wait_or_fire
        jsr wait_release
        lda #100
        jsr wait_or_fire
        jsr wait_release
        jsr check_hiscore
        jmp title_screen
t_gover .null "G A M E   O V E R"
t_caught .null "THE BOULDER CAUGHT YOU!"
t_crashed .null "YOU CRASHED!"

print_final_score
        ; "DISTANCE 0000 M     COINS 0000"
        ldx #0
-       lda t_fline,x
        sta txtbuf,x
        inx
        cpx #t_fline_end-t_fline
        bne -
        lda #0
        sta txtbuf,x
        ldx #9
        lda dist+1
        jsr _d2
        lda dist
        jsr _d2
        ldx #26
        lda coins+1
        jsr _d2
        lda coins
        jsr _d2
        lda #<txtbuf
        sta ptr0
        lda #>txtbuf
        sta ptr0+1
        lda #14
        sta tmp1
        lda #15
        sta tmp2
        jsr print_centre
        lda #<t_fscore
        sta ptr0
        lda #>t_fscore
        sta ptr0+1
        lda #16
        sta tmp1
        lda #3
        sta tmp2
        jsr print_centre
        ldx #0
        lda score+2
        jsr _d2
        lda score+1
        jsr _d2
        lda score
        jsr _d2
        lda #0
        sta txtbuf,x
        lda #<txtbuf
        sta ptr0
        lda #>txtbuf
        sta ptr0+1
        lda #18
        sta tmp1
        lda #1
        sta tmp2
        jmp print_centre
_d2     pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta txtbuf,x
        inx
        pla
        and #15
        ora #48
        sta txtbuf,x
        inx
        rts
t_fline .text "DISTANCE 0000 M     COINS 0000"
t_fline_end
t_fscore .null "SCORE"

; ---------------------------------------------------- ending / credits
ending
        jsr screen_setup
        jsr starfill_all
        jsr screen_show
        lda #TUNE_END
        jsr music_start
        lda #<end_pages
        sta pageptr
        lda #>end_pages
        sta pageptr+1
_page   ldy #0
        lda (pageptr),y
        cmp #$fe
        bne +
        jmp _fin
+
        ; clear text rows 4..21
        lda #3
        sta tmp6
        lda #22
        sta tmp7
        jsr clear_rows
        ; colour rows black first
        ldx #0
        lda #0
-       sta COLRAM+3*40,x
        sta COLRAM+3*40+250,x
        sta COLRAM+3*40+500,x
        sta COLRAM+3*40+510,x
        inx
        cpx #250
        bne -
        lda pageptr
        sta ptr3
        lda pageptr+1
        sta ptr3+1
        jsr print_list
        ; ptr3 now at the $ff of the page
        lda ptr3
        clc
        adc #1
        sta pageptr
        lda ptr3+1
        adc #0
        sta pageptr+1
        ; fade in
        ldx #0
-       stx fadepos
        lda fade_tab,x
        jsr tint_text
        ldx #6
-       jsr waitframe
        dex
        bne -
        ldx fadepos
        inx
        cpx #5
        bne --
        lda #170
        jsr wait_or_fire
        jsr wait_release
        ; fade out
        ldx #4
-       stx fadepos
        lda fade_tab,x
        jsr tint_text
        ldx #6
-       jsr waitframe
        dex
        bne -
        ldx fadepos
        dex
        bpl --
        lda #0
        jsr tint_text
        ; restore stars in cleared rows
        lda #3
        sta tmp6
        lda #22
        sta tmp7
        jsr starfill_rows
        jmp _page
_fin    ; final page with score
        lda #3
        sta tmp6
        lda #22
        sta tmp7
        jsr clear_rows
        lda #<t_theend
        sta ptr0
        lda #>t_theend
        sta ptr0+1
        lda #9
        sta tmp1
        lda #7
        sta tmp2
        jsr print_centre
        jsr print_final_score
        lda #3
        sta tmp6
        lda #22
        sta tmp7
        jsr starfill_rows
        lda #250
        jsr wait_or_fire
        jsr wait_release
        jsr check_hiscore
        jmp title_screen
t_theend .null "T H E   E N D"

; colour all non-star text chars in rows 3..21 with A
tint_text
        sta tmp0
        ldx #0
-       lda SCR+3*40,x
        cmp #64
        bcs +
        lda tmp0
        sta COLRAM+3*40,x
+       lda SCR+3*40+190,x
        cmp #64
        bcs +
        lda tmp0
        sta COLRAM+3*40+190,x
+       lda SCR+3*40+380,x
        cmp #64
        bcs +
        lda tmp0
        sta COLRAM+3*40+380,x
+       lda SCR+3*40+570,x
        cmp #64
        bcs +
        lda tmp0
        sta COLRAM+3*40+570,x
+       inx
        cpx #190
        bne -
        rts
fade_tab .byte 0,6,4,3,1

end_pages
        .byte 5,7
        .null "DAYLIGHT!"
        .byte 9,1
        .null "WITH ONE LAST LEAP YOU JUMP"
        .byte 10,1
        .null "OUT OF THE MOUNTAIN AND DIVE"
        .byte 11,1
        .null "INTO THE RIVER FAR BELOW."
        .byte 14,1
        .null "THE BOULDER CRASHES INTO THE"
        .byte 15,1
        .null "ROCKS. THE GOLDEN IDOL IS YOURS."
        .byte 18,3
        .null "YOU ESCAPED!"
        .byte $ff
        .byte 5,1
        .null "- F L E E T F O O T -"
        .byte 8,1
        .null "PROGRAMMING"
        .byte 9,1
        .null "CLAUDE"
        .byte 12,1
        .null "GRAPHICS"
        .byte 13,1
        .null "CLAUDE"
        .byte 16,1
        .null "MUSIC AND SOUND EFFECTS"
        .byte 17,1
        .null "CLAUDE"
        .byte $ff
        .byte 6,1
        .null "INSPIRED BY TWO MODERN CLASSICS:"
        .byte 9,1
        .null "SUBWAY SURFERS (2012)"
        .byte 10,1
        .null "BY KILOO AND SYBO"
        .byte 12,1
        .null "TEMPLE RUN (2011)"
        .byte 13,1
        .null "BY IMANGI STUDIOS"
        .byte 16,1
        .null "WRITTEN IN 6502 ASSEMBLER"
        .byte 17,1
        .null "FOR THE COMMODORE 64"
        .byte $ff
        .byte 6,1
        .null "THANK YOU FOR PLAYING!"
        .byte 10,1
        .null "FIVE LANDS, ONE BOULDER"
        .byte 12,1
        .null "AND THE FASTEST FEET OF ALL:"
        .byte 14,1
        .null "YOURS."
        .byte $ff
        .byte $fe

; ---------------------------------------------------- hiscore check / entry
check_hiscore
        ; find rank
        ldx #0
_f      txa
        asl
        sta tmp0
        asl
        clc
        adc tmp0
        tay
        lda score+2
        cmp hiscores+5,y
        bcc _nx
        bne _found
        lda score+1
        cmp hiscores+4,y
        bcc _nx
        bne _found
        lda score
        cmp hiscores+3,y
        beq _nx
        bcs _found
_nx     inx
        cpx #5
        bne _f
        rts
_found  stx hsrank
        lda #3
        sta tmp1
_sh     lda tmp1
        cmp hsrank
        bcc _ins
        asl
        sta tmp0
        asl
        clc
        adc tmp0
        tay
        ldx #6
-       lda hiscores,y
        sta hiscores+6,y
        iny
        dex
        bne -
        dec tmp1
        bpl _sh
_ins    ; insert
        lda hsrank
        asl
        sta tmp0
        asl
        clc
        adc tmp0
        tax
        stx hscur
        lda #1
        sta hiscores,x
        sta hiscores+1,x
        sta hiscores+2,x
        lda score
        sta hiscores+3,x
        lda score+1
        sta hiscores+4,x
        lda score+2
        sta hiscores+5,x
        ; entry screen
        jsr screen_setup
        jsr starfill_all
        lda #<t_hsenter
        sta ptr3
        lda #>t_hsenter
        sta ptr3+1
        jsr print_list
        jsr screen_show
        lda #TUNE_TITLE
        jsr music_start
        jsr wait_release
        lda #0
        sta hsletter            ; which letter (0..2)
        sta tmp7
_eloop  jsr waitframe
        ; draw 3 letters at row 13 col 18
        ldx hscur
        ldy #0
-       lda hiscores,x
        sta SCR+13*40+18,y
        lda #1
        cpy hsletter
        bne +
        lda frame
        and #8
        beq +
        lda #7
        bne ++
+       lda #1
+       sta COLRAM+13*40+18,y
        inx
        iny
        cpy #3
        bne -
        ; input
        lda hsdelay
        beq +
        dec hsdelay
        jmp _eloop
+       jsr joyread
        beq _eloop
        sta tmp0
        lda #8
        sta hsdelay
        lda hscur
        clc
        adc hsletter
        tax
        lda tmp0
        and #1
        beq +
        jsr _next
+       lda tmp0
        and #2
        beq +
        jsr _prev
+       lda tmp0
        and #$10
        beq _eloop
        lda #SFX_MENU
        jsr sfx_start
        lda #14
        sta hsdelay
        inc hsletter
        lda hsletter
        cmp #3
        bne _eloop
        jsr wait_release
        rts
_next   ldy #0
-       lda hs_chars,y
        cmp hiscores,x
        beq +
        iny
        cpy #HS_NCH
        bne -
        ldy #$ff
+       iny
        cpy #HS_NCH
        bcc +
        ldy #0
+       lda hs_chars,y
        sta hiscores,x
        rts
_prev   ldy #0
-       lda hs_chars,y
        cmp hiscores,x
        beq +
        iny
        cpy #HS_NCH
        bne -
        ldy #0
+       dey
        bpl +
        ldy #HS_NCH-1
+       lda hs_chars,y
        sta hiscores,x
        rts
hs_chars .text "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-! "
HS_NCH = 40
t_hsenter
        .byte 6,7
        .null "CONGRATULATIONS!"
        .byte 8,1
        .null "YOUR SCORE IS IN THE HALL OF FAME."
        .byte 10,3
        .null "ENTER YOUR INITIALS:"
        .byte 17,4
        .null "UP/DOWN: LETTER   FIRE: NEXT"
        .byte $ff

; ---------------------------------------------------- title decoration: the runner flees from the boulder
title_sprites
        lda #0
        sta $d010
        sta $d01b
        lda #%00000100
        sta $d017
        sta $d01d
        lda #$ff
        sta $d01c
        lda #%00000111
        sta $d015
        lda #0
        sta $d025
        lda #1
        sta $d026
        lda #8
        sta $d027
        lda #6
        sta $d028
        lda #12
        sta $d029
        sta $d02a
        lda #0
        sta tb_t
        rts

title_bounce
        inc tb_t
        lda tb_t
        lsr
        sta tmp0
        clc
        adc #104
        sta $d000
        sta $d002
        lda tmp0
        clc
        adc #40
        sta $d004
        lda #0
        sta $d010
        lda #219
        sta $d001
        lda #240
        sta $d003
        lda #210
        sta $d005
        lda frame
        lsr
        lsr
        and #3
        asl
        clc
        adc #SPR_RUN0T
        sta SCR+$3f8
        adc #1
        sta SCR+$3f9
        lda frame
        lsr
        lsr
        and #1
        clc
        adc #SPR_BALL0
        sta SCR+$3fa
        rts
