; =====================================================================
;  Game flow: new game, level start, mid-level shop, main loop
; =====================================================================
X_NONE = 0
X_NEXT = 1
X_OVER = 2
X_QUIT = 3
X_SHOP = 4

        .virtual $03a0
exitcode .byte ?
startlevel .byte ?
keytmp  .byte ?
resuming .byte ?
        .endv

new_game
        lda #0
        sta score
        sta score+1
        sta score+2
        sta nextext
        sta nextext+2
        sta credits
        sta credits+1
        sta autofire
        sta sideshot
        sta rearshot
        sta laser
        sta homing
        sta novaitem
        sta novatime
        lda #$50
        sta nextext+1
        lda #3
        sta lives
        lda #1
        sta mainpow
        sta pspeed
        lda #ENERGYMAX
        sta energy
        lda cheat
        beq +
        lda #$99
        sta credits
        sta credits+1
+       lda startlevel
        sta level

; ---- start current level
start_level
        jsr level_intro
        lda #0
        sta resuming
        jsr game_setup
        jsr clear_objects
        jsr init_level
        lda novaitem
        beq +
        lda #0
        sta novaitem
        lda #20
        sta novatime
+       jmp game_enter

; ---- common: blank screen, irq off
game_setup
        lda #$0b
        sta $d011
        jsr waitframe
        sei
        lda #0
        sta $d015
        sta $d01a
        cli
        rts

; ---- enter/resume the playfield
game_enter
        jsr init_vsprites
        jsr player_place
        lda #0
        sta paused
        sta stagestate
        sta bombflash
        sta exitcode
        sta shoppend
        lda #$ff
        sta $dc00
        sta joy
        sta joyprev
        lda #$ff
        sta $d01c
        lda #11
        sta $d025
        lda #1
        sta $d026
        lda #0
        sta $d01b
        sta $d017
        sta $d01d
        sta $d010
        sta $d020
        lda #$18
        sta $d016
        jsr draw_hud
        lda #1
        sta hudflag
        lda level
        and #1
        clc
        adc #TUNE_STAGE1
        jsr music_start
        lda #0
        sta ready
        jsr scroll_regs_init
        jsr irq_game_on

game_loop
        jsr read_input
        lda paused
        bne _paused
        jsr scroll_update
        jsr update_spawners
        jsr update_player
        jsr update_pbullets
        jsr update_enemies
        jsr update_ebullets
        jsr update_boss
        jsr collisions
        jsr stage_logic
_paused jsr build_sprites
        jsr update_hud
        ; sync with irq
        lda #1
        sta ready
-       lda ready
        bne -
        lda shoppend
        beq +
        lda #X_SHOP
        sta exitcode
+       lda exitcode
        bne +
        jmp game_loop
+       ; ---- leave game loop (let pending colour shift finish)
        jsr waitframe
        jsr waitframe
        lda #0
        sta $d015
        lda exitcode
        cmp #X_SHOP
        bne _notshop
        ; ---- mid-level shop: save playfield, shop, restore
        jsr save_playfield
        jsr irq_simple_on
        jsr shop_screen
        jsr game_setup
        jsr restore_playfield
        jsr clear_objects
        jmp game_enter
_notshop
        jsr irq_simple_on
        lda #0
        sta $d020
        lda exitcode
        cmp #X_NEXT
        beq _next
        jmp game_over
_next   lda level
        cmp #4
        bcs +
        jsr shop_screen         ; end-of-level shop
+       inc level
        lda level
        cmp #5
        bcc +
        jmp ending
+       jmp start_level

scroll_regs_init
        lda yfine
        ora #$10
        sta nx_d011
        sta cur_d011
        ora #$60
        sta cur_blank
        lda #0
        sta blank_mode          ; refined by the next latch
        sta split_bl
        lda front
        beq +
        lda #D018B
        bne ++
+       lda #D018A
+       sta nx_d018
        sta cur_d018
        lda #SPLITL
        sta nx_split
        sta cur_split
        lda #0
        sta nx_cshift
        sta do_cshift
        rts

; copy front screen (1KB) and colour RAM (1KB) to BACKUP / back
save_playfield
        lda front
        beq +
        lda #>SCRB
        bne ++
+       lda #>SCRA
+       sta ptr0+1
        lda #>BACKUP
        sta ptr1+1
        lda #>COLRAM
        sta ptr2+1
        lda #>(BACKUP+$400)
        sta ptr3+1
        jmp copy4

restore_playfield
        lda #0
        sta front
        lda #>BACKUP
        sta ptr0+1
        lda #>SCRA
        sta ptr1+1
        lda #>(BACKUP+$400)
        sta ptr2+1
        lda #>COLRAM
        sta ptr3+1
copy4   lda #0
        sta ptr0
        sta ptr1
        sta ptr2
        sta ptr3
        ldx #4
        ldy #0
-       lda (ptr0),y
        sta (ptr1),y
        lda (ptr2),y
        sta (ptr3),y
        iny
        bne -
        inc ptr0+1
        inc ptr1+1
        inc ptr2+1
        inc ptr3+1
        dex
        bne -
        rts

; ---------------------------------------------------- input
read_input
        lda joy
        sta joyprev
        jsr joyread
        sta joy
        lda #41                 ; P
        jsr keytest
        sta tmp2
        lda #63                 ; RUN/STOP
        jsr keytest
        sta tmp0
        lda #39                 ; N
        jsr keytest
        sta tmp1
        lda tmp2
        ora tmp1
        bne +
        lda #0
        sta lastkey
        beq _stop
+       lda lastkey
        bne _stop
        lda #1
        sta lastkey
        lda tmp2
        beq _nkey
        lda paused
        eor #1
        sta paused
        lda #1
        sta hudflag
        bne _stop
_nkey   lda cheat
        beq _stop
        lda #X_NEXT
        sta exitcode
_stop   lda paused
        beq +
        lda tmp0
        beq +
        lda #X_QUIT
        sta exitcode
+       rts

; ---------------------------------------------------- stage logic
stage_logic
        lda stagestate
        cmp #1
        bne _s2
        dec stagetimer
        bne _go
        jsr boss_spawn
        lda #4
        sta stagestate
        rts
_s2     cmp #2
        bne _go
        dec stagetimer
        bne _r
        dec stagetimer+1
        bpl _r
        lda #X_NEXT
        sta exitcode
        rts
_go     lda lives
        bne _r
        lda pstate
        cmp #2
        bne _r
        dec ptimer
        bne _r
        lda #X_OVER
        sta exitcode
_r      rts

stage_clear
        lda #2
        sta stagestate
        lda #<300
        sta stagetimer
        lda #>300
        sta stagetimer+1
        lda #1
        sta hudflag
        lda #TUNE_CLEAR
        jmp music_start
