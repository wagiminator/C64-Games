; =====================================================================
;  Game flow: new game, level start, main loop, stage logic
; =====================================================================
X_NONE = 0
X_NEXT = 1
X_OVER = 2
X_QUIT = 3

        .virtual $03a0
exitcode .byte ?
startlevel .byte ?
keytmp  .byte ?
        .endv

new_game
        lda #0
        sta score
        sta score+1
        sta score+2
        sta nextext
        sta nextext+2
        lda #$50
        sta nextext+1
        lda #3
        sta lives
        lda startlevel
        sta level
        jsr player_reset
        lda #0
        sta orbon

; ---- start (or restart) current level
start_level
        jsr level_intro
        ; blank, set up
        lda #$0b
        sta $d011
        jsr waitframe
        sei
        lda #0
        sta $d015
        sta $d01a
        cli
        jsr clear_objects
        jsr init_level
        jsr init_vsprites
        ; keep weapons, reposition player
        lda #40
        sta px_l
        lda #0
        sta px_h
        sta pstate
        sta charge
        sta paused
        sta stagestate
        sta bombflash
        sta exitcode
        sta skipflag
        lda #120
        sta py
        sta oy
        lda #40
        sta ox_l
        lda #0
        sta ox_h
        lda #90
        sta pinv
        lda #$ff
        sta $dc00
        sta joy
        sta joyprev
        ; sprite setup
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
        .if PROFILE
        lda #$ff
        sta $dc04
        sta $dc05
        lda #$11
        sta $dc0e
        .fi
        jsr irq_game_on
        lda #$1b
        sta $d011

PROF    .macro idx
        .if PROFILE
        lda $dc04
        sta $0380+\idx
        lda $dc05
        sta $0390+\idx
        .fi
        .endm

game_loop
        #PROF 0
        jsr read_input
        lda paused
        bne _paused
        jsr scroll_update
        #PROF 1
        jsr update_spawners
        jsr update_player
        #PROF 2
        jsr update_pbullets
        #PROF 3
        jsr update_enemies
        #PROF 4
        jsr update_ebullets
        jsr update_boss
        #PROF 5
        jsr collisions
        #PROF 6
        jsr stage_logic
_paused jsr build_sprites
        #PROF 7
        jsr update_hud
        #PROF 8
        ; bomb flash
        lda bombflash
        beq +
        dec bombflash
        and #2
        beq +
        lda #1
        sta $d020
        bne ++
+       lda #0
        sta $d020
+       ; sync with irq
        #PROF 9
        lda #1
        sta ready
-       lda ready
        bne -
        #PROF 10
        .if PROFILE
        ldx #10
-       lda $0380,x
        sta $03c0,x
        lda $0390,x
        sta $03d0,x
        dex
        bpl -
        ldx #5
-       lda $03e4,x
        sta $03f0,x
        lda #0
        sta $03e4,x
        dex
        bpl -
        .fi
        lda exitcode
        bne +
        jmp game_loop
+       ; ---- leave game loop
        lda #0
        sta $d015
        jsr irq_simple_on
        lda #0
        sta $d020
        lda exitcode
        cmp #X_NEXT
        beq _next
        jmp game_over
_next   inc level
        lda level
        cmp #6
        bcc +
        jmp ending
+       jmp start_level

scroll_regs_init
        lda #$17
        sta nx_d016
        sta cur_d016
        lda #D018A
        sta nx_d018
        sta cur_d018
        lda #0
        sta nx_cshift
        sta do_cshift
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
_go     ; game over check
        lda lives
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
        lda #<330
        sta stagetimer
        lda #>330
        sta stagetimer+1
        lda #1
        sta hudflag
        lda #TUNE_CLEAR
        jmp music_start
