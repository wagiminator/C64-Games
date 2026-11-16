; =====================================================================
;  HUD: seed bar (rows 0-2), cursor marker (row 3), status (row 24)
; =====================================================================
pk_col  .byte 6,11,16,21,26,31,36
stl_col .byte 0,0,1
stn_col .byte 6,6,7

hud_static
        ; sun icon
        ldx #3
-       ldy suni_ofs,x
        txa
        clc
        adc #CH_SUNI
        sta SCRA,y
        lda suni_col,x
        sta COLRAM,y
        dex
        bpl -
        ; packets
        ldx #0
-       cpx npack
        bcs +
        stx tmp7
        jsr draw_packet
        ldx tmp7
        inx
        bne -
+       ; shovel
        ldx #3
-       ldy shov_ofs,x
        txa
        clc
        adc #CH_SHOV
        sta SCRA,y
        lda shov_col,x
        sta COLRAM,y
        dex
        bpl -
        #print t_dig, 36, 2, 1
        ; status row
        ldx area
        lda stl_col,x
        sta stl
        lda stn_col,x
        sta stn
        lda #<t_sscore
        sta ptr0
        lda #>t_sscore
        sta ptr0+1
        lda #0
        sta tmp0
        lda #24
        sta tmp1
        lda stl
        sta tmp2
        jsr print_at
        lda #<t_slv
        sta ptr0
        lda #>t_slv
        sta ptr0+1
        lda #17
        sta tmp0
        lda stl
        sta tmp2
        jsr print_at
        lda #CH_LIFE
        sta SCRA+24*40+13
        lda #2
        sta COLRAM+24*40+13
        lda #1
        sta hudflag
        sta sunflag
        sta pkflag
        rts
suni_ofs .byte 0,1,40,41
shov_ofs .byte 37,38,77,78
t_dig   .null "DIG"
t_sscore .null "SCORE"
t_slv   .null "LEVEL"

; X = packet: icon + cost
draw_packet
        lda pk_col,x
        sta tmp0
        txa
        asl
        asl
        sta tmp1                ; icon index base
        ldy tmp0
        iny
        lda tmp1
        clc
        adc #CH_ICON
        sta SCRA,y
        adc #1
        sta SCRA+1,y
        adc #1
        sta SCRA+40,y
        adc #1
        sta SCRA+41,y
        ; cost text
        txa
        asl
        adc tmp7
        tax
        ldy tmp0
        lda p_costt,x
        sta SCRA+80,y
        lda p_costt+1,x
        sta SCRA+81,y
        lda p_costt+2,x
        sta SCRA+82,y
        rts

; colours of packets (ready / not affordable / cooling / held)
pack_colors
        ldx #0
_lp     cpx npack
        bcc +
        rts
+       stx tmp7
        lda pk_col,x
        tay
        iny
        lda pk_cd,x
        bne _dim
        jsr can_afford
        bcc _dim
        ; ready: real icon colours
        txa
        asl
        asl
        tax
        lda icon_col,x
        sta COLRAM,y
        lda icon_col+1,x
        sta COLRAM+1,y
        lda icon_col+2,x
        sta COLRAM+40,y
        lda icon_col+3,x
        sta COLRAM+41,y
        lda #1
        jmp _txt
_dim    lda #8
        sta COLRAM,y
        sta COLRAM+1,y
        sta COLRAM+40,y
        sta COLRAM+41,y
        ldx tmp7
        lda pk_cd,x
        beq +
        lda #0
        beq _txt
+       lda #2
_txt    ldx tmp7
        pha
        txa
        clc
        adc #1
        cmp held
        bne +
        pla
        lda #7
        pha
+       pla
        dey
        sta COLRAM+80,y
        sta COLRAM+81,y
        sta COLRAM+82,y
        inx
        jmp _lp

hud_update
        lda sunflag
        ora pkflag
        beq _nos
        lda #0
        sta pkflag
        jsr pack_colors
        jsr draw_marker
_nos    lda sunflag
        beq _nsun
        lda #0
        sta sunflag
        ; 4 digits, leading zeros blank
        lda #0
        sta tmp6
        lda sun+1
        lsr
        lsr
        lsr
        lsr
        jsr _dig
        sta SCRA+80
        lda sun+1
        and #15
        jsr _dig
        sta SCRA+81
        lda sun
        lsr
        lsr
        lsr
        lsr
        jsr _dig
        sta SCRA+82
        lda sun
        and #15
        ora #48
        sta SCRA+83
        lda #7
        sta COLRAM+80
        sta COLRAM+81
        sta COLRAM+82
        sta COLRAM+83
        lda #1
        sta pkflag
        jmp _nsun
_dig    cmp #0
        bne +
        ldx tmp6
        bne +
        lda #32
        rts
+       inc tmp6
        ora #48
        rts
_nsun   lda hudflag
        beq _prog
        lda #0
        sta hudflag
        ldy #6
        lda score+2
        jsr put_bcd24
        lda score+1
        jsr put_bcd24
        lda score
        jsr put_bcd24
        lda #48
        sta SCRA+24*40,y
        lda stn
        sta COLRAM+24*40,y
        lda lives
        ora #48
        sta SCRA+24*40+14
        lda stn
        sta COLRAM+24*40+14
        lda level
        clc
        adc #1
        ldx #48
-       cmp #10
        bcc +
        sbc #10
        inx
        bne -
+       ora #48
        sta SCRA+24*40+24
        txa
        sta SCRA+24*40+23
        lda stn
        sta COLRAM+24*40+23
        sta COLRAM+24*40+24
_prog   lda frame
        and #15
        beq +
        rts
+
        ; progress / boss bar, cols 26..39 (14 chars = 56 quarters)
        lda bo_on
        beq _p
        lda bo_hpl
        sta tmp0
        lda bo_hph
        sta tmp1
        lda #6
        sta tmp2
        jsr div16_8
        lda tmp0
        ldx #2
        jmp _bar
_p      lda sp_all
        sta tmp0
        lda #0
        sta tmp1
        ldx #3
-       asl tmp0
        rol tmp1
        dex
        bne -                   ; *8
        lda tmp0
        sta tmp3
        lda tmp1
        sta tmp4
        asl tmp0
        rol tmp1
        asl tmp0
        rol tmp1
        asl tmp0
        rol tmp1                ; *64
        lda tmp0
        sec
        sbc tmp3
        sta tmp0
        lda tmp1
        sbc tmp4
        sta tmp1                ; *56
        lda sp_tot
        sta tmp2
        jsr div16_8
        lda tmp0
        ldx #5
_bar    sta tmp0
        stx tmp1
        ldx #0
-       lda tmp0
        cmp #4
        bcc _q
        sbc #4
        sta tmp0
        lda #CH_BAR+4
        jmp _s
_q      clc
        adc #CH_BAR
        ldy #0
        sty tmp0
_s      sta SCRA+24*40+26,x
        lda tmp1
        sta COLRAM+24*40+26,x
        inx
        cpx #14
        bne -
_r      rts

put_bcd24
        pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRA+24*40,y
        lda stn
        sta COLRAM+24*40,y
        iny
        pla
        and #15
        ora #48
        sta SCRA+24*40,y
        lda stn
        sta COLRAM+24*40,y
        iny
        rts

; row 3: marker under the selected packet while on the seed bar
draw_marker
        ldx #39
        lda #32
-       sta SCRA+120,x
        dex
        bpl -
        lda cur_r
        bne _r
        ldx cur_c
        lda pk_col,x
        tay
        ldx #4
-       lda #CH_BAR+4
        sta SCRA+120,y
        lda #1
        sta COLRAM+120,y
        iny
        dex
        bne -
_r      rts
