; =====================================================================
;  Game flow: race start, main loop, checkpoints and forks, goal, time
; =====================================================================
DBGAI   = $03fd
KEY_P   = 41
KEY_N   = 39
KEY_STOP = 63

new_game
        lda #0
        sta score
        sta score+1
        sta score+2
        lda #$75
        sta time_s
        lda #49
        sta time_f
        ; stage / leg from the start stage
        lda startstage
        sta stage
        ldx #0
-       lda leg_stage,x
        cmp stage
        beq +
        inx
        cpx #16
        bne -
        ldx #0
+       txa
        and #3
        sta legpos
        txa
        lsr
        lsr
        sta leg
        jsr race_setup
        jmp race_loop

; screen, HUD and stage set-up for a fresh race
race_setup
        lda #$0b
        sta $d011
        jsr music_stop
        lda #0
        sta $d015
        sta $d020
        ; both screens: clear, colours
        lda #32
        ldx #0
-       sta SCRA,x
        sta SCRA+$100,x
        sta SCRA+$200,x
        sta SCRA+$2e8,x
        sta SCRB,x
        sta SCRB+$100,x
        sta SCRB+$200,x
        sta SCRB+$2e8,x
        inx
        bne -
        lda #0
        sta posl
        sta posh
        sta posf
        sta pprevl
        sta pprevh
        sta pxl
        sta pxh
        sta vl
        sta vh
        sta scnpl
        sta scnph
        sta crash_t
        sta bump_t
        sta state
        sta cnt_t
        sta msg_t
        sta steer
        sta sbounce
        sta offroad
        sta forkmsg
        sta dispscr
        sta ready
        sta ob_lastk
        ldx #NTR-1
-       sta tr_on,x
        dex
        bpl -
        jsr stage_setup
        jsr hud_init
        ; first frame: project, draw both screens
        jsr track_pseg
        jsr road_update
        jsr objects_update
        jsr scenery_update
        jsr draw_rows
        lda #1
        sta dispscr
        jsr scenery_update
        jsr draw_rows
        lda #0
        sta dispscr
        jsr road_update
        jsr commit
        ldx #35
-       lda s8_y,x
        sta l8_y,x
        dex
        bpl -
        lda st_scnf
        sta scn_fine
        lda #0
        sta ready
        jsr irq_race_on
        jsr waitframe
        lda #$1b
        sta $d011
        ; music or engine
        lda station
        cmp #3
        beq +
        clc
        adc #TUNE_RADIO
        jsr music_start
        lda #0
        jsr engine_set
        jmp ++
+       lda #1
        jsr engine_set
+       lda frame
        sta lastfr
        rts

; ---------------------------------------------------- main loop
race_loop
-       lda ready               ; wait until the last frame was taken over
        bne -
        ; elapsed frames (1..4)
        lda frame
        sec
        sbc lastfr
        bne +
        lda frame
-       cmp frame
        beq -
        lda frame
        sec
        sbc lastfr
+       cmp #5
        bcc +
        lda #4
+       sta dt
        clc
        adc lastfr
        sta lastfr
        ; ---- input
        jsr joyread
        sta joy
        lda DBGAI
        beq +
        jsr autopilot
+       ; ---- per frame steps
        ldx dt
-       stx tmp7
        jsr player_frame
        jsr timer_frame
        jsr countdown_frame
        ldx tmp7
        dex
        bne -
        lda crashk
        beq +
        jsr player_crash
+       jsr traffic_update
        jsr track_pseg
        jsr road_update
        jsr objects_update
        jsr scenery_update
        jsr draw_rows
        jsr hud_update
        inc lagf
        lda #1
        sta ready
        ; ---- events
        jsr check_progress
        jsr keys
        jmp race_loop

; ---------------------------------------------------- countdown 3 - 2 - 1 - GO
countdown_frame
        lda state
        bne _r
        lda cnt_t
        inc cnt_t
        cmp #20
        beq _3
        cmp #70
        beq _2
        cmp #120
        beq _1
        cmp #170
        beq _go
_r      rts
_3      ldx #0
        beq _beep
_2      ldx #1
        bne _beep
_1      ldx #2
_beep   lda cd_lo,x
        ldy cd_hi,x
        jsr msg_set
        lda #SFX_BEEP
        jmp sfx_start
_go     lda #1
        sta state
        ldx #3
        lda cd_lo,x
        ldy cd_hi,x
        jsr msg_set
        lda #SFX_GO
        jmp sfx_start
cd_lo   .byte <t_cd3, <t_cd2, <t_cd1, <t_go
cd_hi   .byte >t_cd3, >t_cd2, >t_cd1, >t_go
t_cd3   .null "- 3 -"
t_cd2   .null "- 2 -"
t_cd1   .null "- 1 -"
t_go    .null "G O !"

; ---------------------------------------------------- time
timer_frame
        lda state
        cmp #1
        bne _r
        lda cheat
        bne _r
        dec time_f
        bpl _r
        lda fps1
        sta time_f
        sed
        lda time_s
        sec
        sbc #1
        sta time_s
        cld
        lda #1
        sta hudflag
        lda time_s
        beq _up
        cmp #$11
        bcs _r
        lda #SFX_TICK
        jmp sfx_start
_up     lda #2
        sta state
        lda #<t_timeup
        ldy #>t_timeup
        jsr msg_set
        lda #$ff
        sta msg_t
        lda #SFX_TIMEUP
        jmp sfx_start
_r      rts
t_timeup .null "T I M E   U P !"

; ---------------------------------------------------- checkpoints, forks, goal, end of race
check_progress
        lda state
        cmp #1
        beq _race
        cmp #2
        beq _stop
        cmp #3
        beq _stop
        rts
_stop   ; wait until the car stands still
        lda vl
        ora vh
        bne _r
        inc endwait
        lda endwait
        cmp #60
        bcc _r
        lda state
        cmp #3
        bne +
        jmp finish_goal
+       jmp game_over
_r      rts
_race   ; fork message
        lda leg
        cmp #3
        bcs _cp
        lda posh
        cmp #>FORK0
        bcc _cp
        lda forkmsg
        bne _cp
        lda #1
        sta forkmsg
        jsr fork_message
_cp     ; reached the end of the stage?
        lda posh
        cmp #>STAGE_LEN
        bcc _r
        bne +
        lda posl
        cmp #<STAGE_LEN
        bcc _r
+       lda leg
        cmp #3
        bne checkpoint
        ; ---- goal
        lda #3
        sta state
        lda legpos
        sta goalnum
        lda #0
        sta endwait
        lda #<t_goal
        ldy #>t_goal
        jsr msg_set
        lda #$ff
        sta msg_t
        lda #TUNE_GOAL
        jsr music_start
        lda #0
        jmp engine_set
t_goal  .null "G O A L !"

checkpoint
        ; branch by the side of the road the car is on
        lda pxh
        bmi +
        inc legpos
+       inc leg
        lda leg
        asl
        asl
        clc
        adc legpos
        tax
        lda leg_stage,x
        sta stage
        ; extend time
        ldx leg
        lda bonus_t,x
        sed
        clc
        adc time_s
        bcc +
        lda #$99
+       sta time_s
        cld
        ; continue seamlessly on the new course
        lda posl
        sec
        sbc #<STAGE_LEN
        sta posl
        lda posh
        sbc #>STAGE_LEN
        sta posh
        lda posl
        sta pprevl
        lda posh
        sta pprevh
        ldx #NTR-1
        lda #0
-       sta tr_on,x
        dex
        bpl -
        sta forkmsg
        jsr stage_setup
        jsr hud_static
        lda #<t_check
        ldy #>t_check
        jsr msg_set
        lda #SFX_EXTEND
        jmp sfx_start
bonus_t .byte $00, $60, $56, $52
t_check .null "CHECKPOINT!  EXTENDED TIME"

; "LEFT: name    RIGHT: name"
fork_message
        ldx #39
        lda #32
-       sta txtbuf,x
        dex
        bpl -
        lda leg
        clc
        adc #1
        asl
        asl
        adc legpos
        tax
        lda leg_stage,x
        pha
        lda leg_stage+1,x
        pha
        ldx #0
        ldy #0
-       lda t_left,y
        beq +
        sta txtbuf,x
        inx
        iny
        bne -
+       pla
        sta tmp6                ; right stage
        pla
        tay
        jsr _name
        inx
        inx
        ldy #0
-       lda t_right,y
        beq +
        sta txtbuf,x
        inx
        iny
        bne -
+       ldy tmp6
        jsr _name
        lda #0
        sta txtbuf,x
        lda #<txtbuf
        ldy #>txtbuf
        jsr msg_set
        lda #$ff
        sta msg_t
        rts
_name   lda th_name_lo,y
        sta ptr0
        lda th_name_hi,y
        sta ptr0+1
        ldy #0
-       lda (ptr0),y
        beq +
        sta txtbuf,x
        inx
        iny
        bne -
+       rts
t_left  .null "< "
t_right .null "  "

; ---------------------------------------------------- goal sequence: time bonus, ending
finish_goal
        lda #<t_bonus
        ldy #>t_bonus
        jsr msg_set
-       lda time_s
        beq +
        sed
        sec
        sbc #1
        sta time_s
        cld
        lda #$00
        ldx #$05
        jsr score_add
        lda #SFX_TICK
        jsr sfx_start
        lda #1
        sta hudflag
        jsr hud_update_both
        ldx #3
-       jsr waitframe
        dex
        bne -
        jmp --
+       ldx #100
-       jsr waitframe
        dex
        bne -
        lda #0
        jsr engine_set
        jmp ending
t_bonus .null "TIME BONUS  5000 PTS PER SECOND"

; ---------------------------------------------------- keys: pause, cheat skip
keys
        jsr scan_key
        cmp lastkey
        beq _r
        sta lastkey
        cmp #KEY_P
        bne +
        jmp pause_game
+       cmp #KEY_N
        bne _r
        lda cheat
        beq _r
        lda state
        cmp #1
        bne _r
        ; jump close to the checkpoint
        lda #<(STAGE_LEN-1500)
        sta posl
        sta pprevl
        lda #>(STAGE_LEN-1500)
        sta posh
        sta pprevh
        lda #0
        sta pseg
_r      rts

pause_game
        lda eng_on
        sta hsave
        lda #0
        jsr engine_set
        lda #0
        sta $d418
        lda #<t_pause
        ldy #>t_pause
        jsr msg_set
        jsr hud_update_both
-       jsr waitframe
        jsr scan_key
        cmp #KEY_STOP
        bne +
        jmp title_screen
+       cmp #KEY_P
        beq -
        cmp #$ff
        bne -
-       jsr waitframe
        jsr scan_key
        cmp #KEY_STOP
        bne +
        jmp title_screen
+       cmp #KEY_P
        bne -
        lda #$0f
        sta $d418
        lda hsave
        jsr engine_set
        lda #KEY_P
        sta lastkey
        lda #1
        sta msg_t
        lda frame
        sta lastfr
        rts
t_pause .null "P A U S E"

; ---------------------------------------------------- autopilot (testing)
autopilot
        lda #$10
        sta joy
        ; target lateral position against the curve drift
        lda pcurve
        asl
        asl
        asl
        asl
        sta tmp0                ; target px (signed 8 bit)
        ; dodge traffic close ahead
        ldx #NTR-1
_av     lda tr_on,x
        beq _avn
        lda tr_pl,x
        sec
        sbc posl
        lda tr_ph,x
        sbc posh
        bmi _avn
        cmp #6
        bcs _avn
        lda tr_x,x
        asl
        sta tmp1
        eor #$80
        sta tmp2
        lda tmp0
        eor #$80
        sta tmp3
        lda tmp2
        sec
        sbc tmp3
        bcs +
        eor #$ff
        adc #1
+       cmp #60
        bcs _avn
        lda tmp1
        bmi _dr
        sec
        sbc #90
        sta tmp0
        jmp _avn
_dr     clc
        adc #90
        sta tmp0
_avn    dex
        bpl _av
        lda pxh
        bmi _neg
        bne _left
        lda pxl
        bmi _left
        sec
        sbc tmp0
        jmp _cmp
_neg    cmp #$ff
        bne _right
        lda pxl
        bpl _right
        sec
        sbc tmp0
_cmp    bvs _r
        bmi _rgt
        cmp #6
        bcc _r
_left   lda joy
        ora #$04
        sta joy
        rts
_rgt    cmp #256-6
        bcs _r
_right  lda joy
        ora #$08
        sta joy
_r      rts
