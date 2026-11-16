; =====================================================================
;  Title screen, stage intro, game over, ending, hiscore entry
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
        .endv

; ---------------------------------------------------- common
screen_setup                    ; blank, simple irq, clear screen
        lda #$0b
        sta $d011
        jsr irq_simple_on
        lda #0
        sta $d015
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

; fill spaces of rows (tmp6..tmp7-1) with parallax star chars
starfill_rows
        ldx tmp6
_r      lda rowlo,x
        sta ptr0
        sta ptr1
        lda rowhiA,x
        sta ptr0+1
        lda rowhiC,x
        sta ptr1+1
        cpx #LOGOROW
        bcc +
        cpx #LOGOROW+LOGOROWS
        bcc _nx
+       stx tmp4
        ldy #39
-       lda (ptr0),y
        cmp #32
        bne +
        lda tcolbase,y
        beq +
        sta tmp5
        lda tcolph,y
        clc
        adc tmp4
        and #7
        adc tmp5
        sta (ptr0),y
        stx tmp3
        tax
        lda charcol,x
        ldx tmp3
        sta (ptr1),y
+       dey
        bpl -
_nx     inx
        cpx tmp7
        bne _r
        rts

starfill_all
        lda #0
        sta tmp6
        lda #25
        sta tmp7
        jmp starfill_rows

; clear rows tmp6..tmp7-1 to spaces
clear_rows
        ldx tmp6
-       lda rowlo,x
        sta ptr0
        lda rowhiA,x
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
        jsr screen_setup
        ; logo
        ldx #0
-       lda logo_chars,x
        sta SCRA+LOGOROW*40,x
        lda logo_chars+200,x
        sta SCRA+LOGOROW*40+200,x
        inx
        cpx #200
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
        cpx #6
        bne +
        lda #1
        sta cheat
        lda #SFX_CHEAT
        jsr sfx_start
        jsr show_cheat
+       rts
_sel    ; stage select with keys 1..6
        ldx #4
-       cmp stagekeys,x
        beq +
        dex
        bpl -
        rts
+       stx startlevel
        lda #SFX_MENU
        jsr sfx_start
        jmp show_cheat
cheatcode .byte 28,33,22,36,10,41          ; B I T M A P
stagekeys .byte 56,59,8,11,16              ; 1 2 3 4 5

show_cheat
        lda cheat
        beq +
        #print t_cheaton, 2, 20, 2
        lda startlevel
        clc
        adc #49
        sta SCRA+20*40+37
+       rts

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
        lda rowhiA,y
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
        lda #48
        sta (ptr0),y
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

t_title .byte 9,3
        .null "A TRIBUTE TO XENON 2: MEGABLAST"
        .byte 21,1
        .null "PRESS FIRE TO START"
        .byte 23,4
        .null "CODE, GRAPHICS & SOUND: CLAUDE 2026"
        .byte $ff
t_instr .byte 11,7
        .null "JOYSTICK IN PORT 2"
        .byte 12,1
        .null "FIRE: SHOOT    (BUY AUTOFIRE AT SHOP)"
        .byte 14,3
        .null "COLLECT CREDIT BUBBLES FROM WRECKS"
        .byte 15,1
        .null "AND SPEND THEM AT GRIMBLE'S SHOP"
        .byte 16,1
        .null "MID-STAGE AND AFTER EVERY BOSS."
        .byte 18,5
        .null "P PAUSE   (RUN/STOP IN PAUSE: QUIT)"
        .byte $ff
t_cheaton .null "CHEAT MODE! KEYS 1-5 = START STAGE:"

; ---------------------------------------------------- stage intro
level_intro
        jsr screen_setup
        jsr music_stop
        jsr starfill_all
        lda #<t_stagen
        sta ptr0
        lda #>t_stagen
        sta ptr0+1
        lda #9
        sta tmp1
        lda #1
        sta tmp2
        jsr print_centre
        lda level
        clc
        adc #49
        sta SCRA+9*40+26
        ; level name
        lda level
        asl
        tax
        lda lvname_tab,x
        sta ptr0
        lda lvname_tab+1,x
        sta ptr0+1
        lda #12
        sta tmp1
        lda #7
        sta tmp2
        jsr print_centre
        lda #<t_ready
        sta ptr0
        lda #>t_ready
        sta ptr0+1
        lda #16
        sta tmp1
        lda #3
        sta tmp2
        jsr print_centre
        jsr screen_show
        lda #SFX_MENU
        jsr sfx_start
        jsr wait_release
        lda #90
        jsr wait_or_fire
        jsr wait_release
        rts
t_stagen .null "S T A G E    "
t_ready  .null "GET READY!"

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

print_final_score
        lda #<t_fscore
        sta ptr0
        lda #>t_fscore
        sta ptr0+1
        lda #14
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
        lda #48
        sta txtbuf,x
        lda #0
        sta txtbuf+1,x
        lda #<txtbuf
        sta ptr0
        lda #>txtbuf
        sta ptr0+1
        lda #16
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
t_fscore .null "YOUR SCORE"

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
        ; ptr3 now after $ff of page
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
-       lda SCRA+3*40,x
        cmp #64
        bcs +
        lda tmp0
        sta COLRAM+3*40,x
+       lda SCRA+3*40+190,x
        cmp #64
        bcs +
        lda tmp0
        sta COLRAM+3*40+190,x
+       lda SCRA+3*40+380,x
        cmp #64
        bcs +
        lda tmp0
        sta COLRAM+3*40+380,x
+       lda SCRA+3*40+570,x
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
        .byte 6,1
        .null "CONGRATULATIONS!"
        .byte 9,1
        .null "THE MOTHER WORM IS NO MORE"
        .byte 11,1
        .null "AND THE VEXOR SWARM IS SCATTERED."
        .byte 15,1
        .null "GRIMBLE SENDS HIS REGARDS"
        .byte 16,1
        .null "... AND HIS INVOICE."
        .byte $ff
        .byte 5,1
        .null "- V E X O R -"
        .byte 8,1
        .null "PROGRAMMING"
        .byte 9,1
        .null "CLAUDE"
        .byte 12,1
        .null "GRAPHICS AND LEVEL DESIGN"
        .byte 13,1
        .null "CLAUDE"
        .byte 16,1
        .null "MUSIC AND SOUND EFFECTS"
        .byte 17,1
        .null "CLAUDE"
        .byte $ff
        .byte 6,1
        .null "A TRIBUTE TO"
        .byte 9,1
        .null "XENON 2: MEGABLAST (1989)"
        .byte 11,1
        .null "BY THE BITMAP BROTHERS"
        .byte 15,1
        .null "WRITTEN IN 6502 ASSEMBLER"
        .byte 16,1
        .null "FOR THE COMMODORE 64"
        .byte $ff
        .byte 7,1
        .null "THANK YOU FOR PLAYING!"
        .byte 11,1
        .null "FIVE STAGES - FIVE BOSSES"
        .byte 13,1
        .null "AND ONE VERY RICH TRADER."
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
        sta SCRA+13*40+18,y
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
