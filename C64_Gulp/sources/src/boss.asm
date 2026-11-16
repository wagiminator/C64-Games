; =====================================================================
;  Boss: giant hunter (4 sprites, 48 x 42). Bite it while POWER is on.
; =====================================================================
bosscol .byte 5,10,14
bspd_l  .byte $90,$b0,$d0
b_bonus .byte $05,$10,$15

boss_start
        lda #1
        sta b_on
        sta b_dir
        lda #88
        sta b_xl
        lda #1
        sta b_xh
        lda #0
        sta b_xf
        sta b_fl
        sta b_dead
        sta b_flee
        lda #100
        sta b_y
        ldy lvidx
        lda lv_bhp,y
        sta b_hp
        lda #150
        sta b_t
        rts

; A = speed fraction, X = speed int: move along b_dir
b_move
        sta tmp0
        stx tmp1
        lda b_dir
        bne _l
        lda b_xf
        clc
        adc tmp0
        sta b_xf
        lda b_xl
        adc tmp1
        sta b_xl
        lda b_xh
        adc #0
        sta b_xh
        cmp #1
        bne _r
        lda b_xl
        cmp #88
        bcc _r
        lda #88
        sta b_xl
        jmp _edge
_l      lda b_xf
        sec
        sbc tmp0
        sta b_xf
        lda b_xl
        sbc tmp1
        sta b_xl
        lda b_xh
        sbc #0
        sta b_xh
        bpl _r
        lda b_xl
        cmp #$d0
        bcs _r
        lda #$d0
        sta b_xl
_edge   lda b_flee
        beq _r
        lda #0
        sta b_flee
        lda #70
        sta b_t
_r      rts

boss_update
        lda b_on
        bne +
        rts
+       lda b_dead
        beq _alive
        dec b_dead
        bne +
        lda #0
        sta b_on
        lda #1
        sta lvdone
        rts
+       lda b_y
        cmp #200
        bcs +
        inc b_y
+       rts
_alive  lda b_fl
        beq +
        dec b_fl
+       lda b_t
        beq _act
        dec b_t
        rts
_act    lda b_flee
        beq _chase
        dec b_flee
        lda #$80
        ldx #2
        jmp b_move
_chase  lda b_xl
        clc
        adc #12
        sta tmp0
        lda b_xh
        adc #0
        sta tmp1
        lda tmp0
        sec
        sbc pxl
        lda tmp1
        sbc pxh
        bmi _right
        lda #1
        bne +
_right  lda #0
+       sta b_dir
        ldy zone
        lda bspd_l,y
        ldx #0
        ldy b_hp
        cpy #2
        bcs +
        clc
        adc #$30
+       jsr b_move
        ; vertical: aim mouth at player
        lda frame
        and #1
        bne _hit
        lda py
        sec
        sbc #12
        bcs +
        lda #0
+       cmp b_y
        beq _hit
        bcc _up
        lda b_y
        cmp #YMAX-20
        bcs _hit
        inc b_y
        bne _hit
_up     lda b_y
        cmp #YMIN+1
        bcc _hit
        dec b_y
_hit    lda pstate
        cmp #1
        beq _r
        lda b_xl
        sta tmp0
        lda b_xh
        sta tmp1
        lda b_y
        sta tmp2
        ldy #K_BOSS
        jsr hit_box
        bcc _r
        lda power
        bne _bite
        ldy #K_BOSS+8
        jsr hit_box
        bcc _r
        jmp player_die
_r      rts
_bite   lda #0
        sta power
        lda g_t3
        sta growth
        lda #1
        sta barflag
        sta hudflag
        lda #24
        sta b_fl
        lda #0
        ldx #$01
        jsr score_add
        dec b_hp
        bne _flee
        lda #150
        sta b_dead
        lda #SFX_BIGEXPLO
        jsr sfx_start
        ldx zone
        lda b_bonus,x
        tax
        lda #0
        jsr score_add
        lda #<t_bossko
        ldx #>t_bossko
        jmp show_msg
_flee   lda b_dir
        eor #1
        sta b_dir
        lda #90
        sta b_flee
        lda #SFX_BITE
        jsr sfx_start
        lda #<t_bite
        ldx #>t_bite
        jmp show_msg
t_bite  .null "CHOMP!"
t_bossko .null "BOSS BEATEN!"

boss_emit
        lda b_on
        beq _r
        lda b_dead
        bne +
        lda frame
        lsr
        lsr
        lsr
        lsr
        and #1
+       and #1
        sta tmp0
        ldy zone
        tya
        asl
        ora b_dir
        asl
        ora tmp0
        asl
        asl
        adc #SPR_BOSS
        sta ep
        lda bosscol,y
        ldy b_fl
        bne _fl
        ldy b_dead
        beq _c
        ldy frame
        cpy #128
        bcc _c
_fl     lda frame
        and #2
        beq _c
        lda #1
_c      sta ec
        lda b_xl
        sta exl
        lda b_xh
        sta exh
        lda b_y
        sta ey
        jsr emit
        jsr emit_next
        jsr emit
        lda b_xl
        sta exl
        lda b_xh
        sta exh
        lda b_y
        clc
        adc #21
        sta ey
        inc ep
        jsr emit
        jsr emit_next
        jmp emit
_r      rts
