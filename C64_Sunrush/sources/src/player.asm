; =====================================================================
;  Player car: throttle, brake, steering, drift in curves, crashes
; =====================================================================
PXMAX   = 300

; acceleration by speed band (v >> 5), 1/16 units per frame^2
acctab  .byte 9,8,7,6,5,4,4,3,2,2,1,1,1

; one physics step (one frame)
player_frame
        lda state
        cmp #1
        beq _race
        cmp #3
        beq _coast
        cmp #2
        beq _coast
        ; countdown: stand still
        lda #0
        sta vl
        sta vh
        jmp _move
_coast  ; time up / goal: roll out
        lda #3
        jsr v_sub
        jsr centre_drift
        jmp _move
_race   lda crash_t
        beq +
        jmp _crash
+       ; ---- throttle / brake
        lda joy
        and #$10
        beq _nogas
        lda vh
        sta tmp0
        lda vl
        lsr tmp0
        ror
        lsr tmp0
        ror
        lsr
        lsr
        lsr                     ; v >> 5
        tax
        lda acctab,x
        jsr v_add
        jmp _brk
_nogas  lda #1
        jsr v_sub
_brk    lda joy
        and #$02
        beq +
        lda #10
        jsr v_sub
+       ; grass
        lda offroad
        beq +
        lda vh
        bne _slow
        lda vl
        cmp #VGRASS
        bcc +
_slow   lda #7
        jsr v_sub
+       ; clamp to VMAX
        lda vh
        cmp #>VMAX
        bcc _st
        lda vl
        cmp #<VMAX
        bcc _st
        lda #<VMAX
        sta vl
        lda #>VMAX
        sta vh
_st     ; ---- steering (rate grows with speed)
        lda vh
        sta tmp0
        lda vl
        lsr tmp0
        ror
        lsr
        lsr
        lsr
        lsr
        lsr                     ; v >> 6 (0..5)
        clc
        adc #2
        sta tmp1
        lda vl
        ora vh
        bne +
        lda #0
        sta tmp1                ; no steering when standing
+       lda joy
        and #$04
        beq +
        lda tmp1
        jsr px_sub
        lda #256-1
        sta steer
        jmp _cf
+       lda joy
        and #$08
        beq +
        lda tmp1
        jsr px_add
        lda #1
        sta steer
        jmp _cf
+       lda #0
        sta steer
_cf     ; ---- centrifugal drift, grows with the square of the speed:
        ;      px -= curve * (v/4)^2 / 256 * 3/4 / 16  (1/16 px resolution)
        lda pcurve
        bne +
        jmp _move
+       sta tmp2
        lda vh
        sta tmp0
        lda vl
        lsr tmp0
        ror
        lsr tmp0
        ror                     ; v/4 (0..88)
        sta mula
        sta mulb
        jsr mul8
        lda mulr+1              ; q = (v/4)^2 / 256 (0..30)
        sta mula
        lda tmp2
        bpl +
        eor #$ff
        clc
        adc #1
+       sta mulb
        jsr mul8
        lda mulr                ; q * |curve| (0..120)
        lsr
        lsr
        sta tmp3
        lda mulr
        sec
        sbc tmp3                ; * 3/4 -> drift in 1/16 px
        sta tmp3
        and #$0f
        clc
        adc dfrac
        sta dfrac
        lsr
        lsr
        lsr
        lsr
        sta tmp0                ; carry from the fraction
        lda dfrac
        and #$0f
        sta dfrac
        lda tmp3
        lsr
        lsr
        lsr
        lsr
        clc
        adc tmp0
        bne +
        jmp _move
+       sta tmp3
        lda tmp2
        bmi +
        lda tmp3
        jsr px_sub
        jmp _move
+       lda tmp3
        jsr px_add
        jmp _move
_crash  dec crash_t
        lda #16
        jsr v_sub
        lda crash_t
        cmp #1
        bne _move
        lda #0                  ; back on the road
        sta pxl
        sta pxh
_move   ; ---- bump / shake
        lda bump_t
        beq +
        dec bump_t
+       ; ---- clamp px
        lda pxh
        bmi _pneg
        cmp #>PXMAX
        bcc _pok
        lda pxl
        cmp #<PXMAX
        bcc _pok
        lda #<PXMAX
        sta pxl
        lda #>PXMAX
        sta pxh
        jmp _pok
_pneg   cmp #>(-PXMAX)
        bcc _pmin
        bne _pok
        lda pxl
        cmp #<(-PXMAX)
        bcs _pok
_pmin   lda #<(-PXMAX)
        sta pxl
        lda #>(-PXMAX)
        sta pxh
_pok    ; ---- off road?  |px| > 148
        lda pxh
        bpl +
        lda #0
        sec
        sbc pxl
        sta tmp0
        lda #0
        sbc pxh
        jmp ++
+       lda pxl
        sta tmp0
        lda pxh
+       ldx #0
        cmp #0
        bne _off
        lda tmp0
        cmp #149
        bcc +
_off    ldx #1
+       stx offroad
        ; ---- bounce on grass, shake on crash
        lda #0
        sta sbounce
        lda offroad
        ora bump_t
        beq +
        lda vl
        ora vh
        beq +
        lda frame
        lsr
        and #1
        sta sbounce
+       lda crash_t
        beq +
        lda frame
        and #4
        lsr
        sec
        sbc #1
        sta steer
+       ; ---- position: pos += v/16
        lda vl
        asl
        asl
        asl
        asl
        clc
        adc posf
        sta posf
        lda vh
        sta tmp0
        lda vl
        lsr tmp0
        ror
        lsr tmp0
        ror
        lsr tmp0
        ror
        lsr tmp0
        ror
        adc posl
        sta posl
        bcc +
        inc posh
+       ; ---- scenery pan: scnp += curve * v / 64
        lda pcurve
        beq _eng
        sta tmp2
        lda vh
        sta tmp0
        lda vl
        lsr tmp0
        ror
        lsr tmp0
        ror
        sta tmp1                ; v/4
        lda tmp2
        bmi _pl
-       lda scnpl
        clc
        adc tmp1
        sta scnpl
        bcc +
        inc scnph
+       dec tmp2
        bne -
        jmp _eng
_pl     lda scnpl
        sec
        sbc tmp1
        sta scnpl
        bcs +
        dec scnph
+       inc tmp2
        bne _pl
_eng    ; ---- engine pitch: $0280 + v * 8 (37 Hz idle .. 200 Hz top speed), once per update
        lda tmp7
        cmp #1
        bne _scr
        lda vl
        sta mula
        lda #8
        sta mulb
        jsr mul8
        lda vh
        asl
        asl
        asl
        clc
        adc mulr+1
        sta tmp0
        lda mulr
        clc
        adc #$80
        sta eng_fl
        lda tmp0
        adc #$02
        sta eng_fh
_scr    ; ---- score: + v/32 (units of 10) while racing
        lda state
        cmp #1
        bne _r
        lda vh
        sta tmp0
        lda vl
        lsr tmp0
        ror
        lsr
        lsr
        lsr
        lsr
        tax
        lda bcdtab,x
        ldx #0
        jsr score_add
_r      rts
bcdtab  .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$10,$11,$12

; A = amount: v += A / v -= A (clamped at 0)
v_add   clc
        adc vl
        sta vl
        bcc +
        inc vh
+       rts
v_sub   sta tmp0
        lda vl
        sec
        sbc tmp0
        sta vl
        bcs +
        dec vh
        bpl +
        lda #0
        sta vl
        sta vh
+       rts
px_add  clc
        adc pxl
        sta pxl
        bcc +
        inc pxh
+       rts
px_sub  sta tmp0
        lda pxl
        sec
        sbc tmp0
        sta pxl
        bcs +
        dec pxh
+       rts

; steer back towards the centre lane (goal / time up)
centre_drift
        lda pxh
        bmi +
        ora pxl
        beq _r
        lda #1
        jmp px_sub
+       lda #1
        jmp px_add
_r      rts

; collision with traffic
player_bump
        lda bump_t
        bne bump_r
        lsr vh
        ror vl
bump_fx lda bump_t
        bne bump_r
        lda #24
        sta bump_t
        lda #SFX_BUMP
        jsr sfx_start
bump_r  rts

; crash into a roadside object
player_crash
        lda crash_t
        bne _r
        lda #90
        sta crash_t
        lda #SFX_CRASH
        jsr sfx_start
_r      rts

; -> A = sprite pointer of the first car quarter
car_frame
        ldx #0
        lda crash_t
        beq +
        lda frame
        lsr
        lsr
        and #1
        tax
        inx
        bne _f
+       lda steer
        beq +
        bmi _l
        ldx #2
        bne _f
_l      ldx #1
        bne _f
+       lda joy
        and #$02
        beq _f
        ldx #3
_f      txa
        asl
        asl
        clc
        adc #SPR_CAR
        rts
