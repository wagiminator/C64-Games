; =====================================================================
;  Player fish: inertia movement, 3 sizes, stun, death
; =====================================================================
ACC     = $26
PCOL    = 8

maxv_l  .byte $80,$40,$10
maxv_h  .byte $02,$02,$02
nmaxv_l .byte $80,$c0,$f0
nmaxv_h .byte $fd,$fd,$fd
pbox_x0 .byte 8,6,2
pbox_x1 .byte 20,22,23
pbox_y0 .byte 8,7,5
pbox_y1 .byte 13,15,16

player_reset
        lda #160
        sta pxl
        lda #0
        sta pxh
        sta pxf
        sta pyf
        sta pvxl
        sta pvxh
        sta pvyl
        sta pvyh
        sta pdir
        sta pstate
        sta ptimer
        sta pmouth
        lda #110
        sta py
        lda #100
        sta pinv
        jmp set_pbox

set_pbox
        ldy psize
        lda pbox_x0,y
        sta pbx0
        lda pbox_x1,y
        sta pbx1
        lda pbox_y0,y
        sta pby0
        lda pbox_y1,y
        sta pby1
        rts

player_update
        lda pinv
        beq +
        dec pinv
+       lda pmouth
        beq +
        dec pmouth
+       lda pstate
        cmp #1
        bne +
        ; eaten: bones float up
        inc ptimer
        lda ptimer
        and #1
        bne _r
        lda py
        cmp #YMIN
        bcc _r
        dec py
_r      rts
+       cmp #2
        bne _input
        ; stunned: drift and sink
        dec ptimer
        bne +
        lda #0
        sta pstate
+       lda #0
        sta tmp7
        lda pvyl
        clc
        adc #6
        sta pvyl
        lda pvyh
        adc #0
        sta pvyh
        jmp _move
_input  lda joy
        sta tmp7
_move   ; ---- horizontal
        lda tmp7
        and #4
        beq +
        lda pvxl
        sec
        sbc #ACC
        sta pvxl
        lda pvxh
        sbc #0
        sta pvxh
        lda #1
        sta pdir
        jmp _cx
+       lda tmp7
        and #8
        beq +
        lda pvxl
        clc
        adc #ACC
        sta pvxl
        lda pvxh
        adc #0
        sta pvxh
        lda #0
        sta pdir
        jmp _cx
+       ldx #pvxl-pvxl
        jsr friction
_cx     ldx #0
        jsr clampv
        ; ---- vertical
        lda tmp7
        and #1
        beq +
        lda pvyl
        sec
        sbc #ACC
        sta pvyl
        lda pvyh
        sbc #0
        sta pvyh
        jmp _cy
+       lda tmp7
        and #2
        beq +
        lda pvyl
        clc
        adc #ACC
        sta pvyl
        lda pvyh
        adc #0
        sta pvyh
        jmp _cy
+       lda pstate
        bne _cy
        ldx #pvyl-pvxl
        jsr friction
_cy     ldx #pvyl-pvxl
        jsr clampv
        ; ---- integrate x
        lda pxf
        clc
        adc pvxl
        sta pxf
        lda pxl
        adc pvxh
        sta pxl
        lda pvxh
        bmi +
        lda pxh
        adc #0
        jmp ++
+       lda pxh
        adc #$ff
+       sta pxh
        ; clamp x 24..320
        lda pxh
        bne _xr
        lda pxl
        cmp #XMIN
        bcs _xok
        lda #XMIN
        sta pxl
        jmp _xs
_xr     lda pxl
        cmp #<XMAX
        bcc _xok
        lda #<XMAX
        sta pxl
_xs     lda #0
        sta pvxl
        sta pvxh
_xok    ; ---- integrate y
        lda pyf
        clc
        adc pvyl
        sta pyf
        lda py
        adc pvyh
        sta py
        cmp #YMIN
        bcs +
        lda #YMIN
        sta py
        jmp _ys
+       cmp #YMAX
        bcc _yok
        lda #YMAX
        sta py
_ys     lda #0
        sta pvyl
        sta pvyh
_yok    rts

; X = 0 (x axis) or 2 (y axis): v -= v/16
friction
        lda pvxl,x
        sta tmp0
        lda pvxh,x
        sta tmp1
        ldy #4
-       lda tmp1
        cmp #$80
        ror tmp1
        ror tmp0
        dey
        bne -
        lda pvxl,x
        sec
        sbc tmp0
        sta pvxl,x
        lda pvxh,x
        sbc tmp1
        sta pvxh,x
        ; kill tiny speeds
        bne +
        lda pvxl,x
        cmp #$18
        bcs _r
        bcc _z
+       cmp #$ff
        bne _r
        lda pvxl,x
        cmp #$e8
        bcc _r
_z      lda #0
        sta pvxl,x
        sta pvxh,x
_r      rts

; X = 0 / 2 : clamp velocity to +-max(psize)
clampv
        ldy psize
        lda pvxh,x
        bmi _neg
        cmp maxv_h,y
        bcc _r
        bne +
        lda pvxl,x
        cmp maxv_l,y
        bcc _r
+       lda maxv_l,y
        sta pvxl,x
        lda maxv_h,y
        sta pvxh,x
_r      rts
_neg    cmp nmaxv_h,y
        bcc +
        bne _r
        lda pvxl,x
        cmp nmaxv_l,y
        bcs _r
+       lda nmaxv_l,y
        sta pvxl,x
        lda nmaxv_h,y
        sta pvxh,x
        rts

player_die
        lda cheat
        ora pinv
        bne _r
        lda pstate
        cmp #1
        beq _r
        lda #1
        sta pstate
        lda #0
        sta ptimer
        sta combo
        sta combo_t
        lda #1
        sta mult
        sta barflag
        lda #SFX_DEATH
        jsr sfx_start
_r      rts

player_stun
        lda cheat
        ora pinv
        bne _r
        lda pstate
        bne _r
        lda #2
        sta pstate
        lda #70
        sta ptimer
        lda #0
        sta combo
        sta combo_t
        lda #1
        sta mult
        sta barflag
        lda #SFX_STING
        jsr sfx_start
_r      rts

; ---------------------------------------------------- sprite for the list
player_emit
        lda pxl
        sta exl
        lda pxh
        sta exh
        lda py
        sta ey
        lda pstate
        cmp #1
        bne +
        lda ptimer
        cmp #100
        bcs _r
        lsr
        lsr
        lsr
        lsr
        and #1
        clc
        adc #SPR_BONES
        sta ep
        lda #1
        sta ec
        jmp emit
+       lda pinv
        beq +
        lda frame
        and #4
        beq _r
+       lda psize
        asl
        ora pdir
        sta tmp0
        asl
        adc tmp0
        sta tmp0                ; (size*2+dir)*3
        lda pmouth
        beq +
        lda #2
        bne ++
+       lda frame
        lsr
        lsr
        lsr
        and #1
+       clc
        adc tmp0
        adc #SPR_PLAYER
        sta ep
        ldy pstate
        beq _pw
        lda frame
        and #2
        beq _pc
        lda #1
        bne _sc
_pw     ldy power
        beq _pc
        lda frame
        and #4
        beq _pc
        lda #7
        bne _sc
_pc     lda #PCOL
_sc     sta ec
        jmp emit
_r      rts
