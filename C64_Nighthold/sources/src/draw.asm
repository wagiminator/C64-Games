; =====================================================================
;  Drawing: background, objects, HUD sprites, palette
;  Every update the hidden screen is rebuilt completely: the 40 x 25
;  window of the map, then gems, creatures, effects and weapons on top.
; =====================================================================

; ---------------------------------------------------- copy the map window into the hidden screen
bg_copy
        lda #0
        sta dst
        lda hidhi
        sta dst+1
        lda bcxl
        and #63
        sta tmp7
        ldx #0
_row    txa
        clc
        adc bcyl
        and #63
        tay
        lda maprow_lo,y
        clc
        adc tmp7
        sta src
        lda maprow_hi,y
        adc #0
        sta src+1
        ldy #0
        .rept 40
        lda (src),y
        sta (dst),y
        iny
        .endrept
        lda dst
        clc
        adc #40
        sta dst
        bcc +
        inc dst+1
+       inx
        cpx #25
        beq +
        jmp _row
+       rts

; ---------------------------------------------------- world cell (tmp0/1 x, tmp2/3 y) on the hidden screen?
; -> C = 1 and optr / Y set (store with sta (optr),y)
obj_scr
        lda tmp2
        sec
        sbc bcyl
        tax
        lda tmp3
        sbc bcyh
        bne _no
        cpx #25
        bcs _no
        lda tmp0
        sec
        sbc bcxl
        tay
        lda tmp1
        sbc bcxh
        bne _no
        cpy #40
        bcs _no
        lda rowlo,x
        sta optr
        lda rowhiA,x
        clc
        adc hiadd
        sta optr+1
        sec
        rts
_no     clc
        rts
hiadd   .byte 0

; ---------------------------------------------------- objects
draw_objects
        lda hidhi
        sec
        sbc #>SCRA
        sta hiadd
        ; ---- gems and hearts
        ldx #NG-1
_g      lda g_t,x
        beq _ng
        stx tmp6
        lda g_xl,x
        sta tmp0
        lda g_xh,x
        sta tmp1
        lda g_yl,x
        sta tmp2
        lda g_yh,x
        sta tmp3
        jsr obj_scr
        bcc +
        ldx tmp6
        lda g_t,x
        tax
        lda gem_char-1,x
        sta (optr),y
+       ldx tmp6
_ng     dex
        bpl _g
        ; ---- creatures (inline visibility test)
        lda frame
        lsr
        lsr
        lsr
        and #1
        sta tmp5                ; animation frame
        ldx #NE-1
_e      lda e_t,x
        beq _ne
        lda e_yl,x
        sec
        sbc bcyl
        tay
        lda e_yh,x
        sbc bcyh
        bne _ne
        cpy #25
        bcs _ne
        lda e_xl,x
        sec
        sbc bcxl
        sta tmp4
        lda e_xh,x
        sbc bcxh
        bne _ne
        lda tmp4
        cmp #40
        bcs _ne
        lda rowlo,y
        sta optr
        lda rowhiA,y
        clc
        adc hiadd
        sta optr+1
        ldy e_t,x
        lda cre_char-1,y
        ldy e_fl,x
        beq +
        dec e_fl,x
        clc
        adc #2
        bne ++
+       clc
        adc tmp5
+       ldy tmp4
        sta (optr),y
_ne     dex
        bpl _e
        ; ---- effects
        ldx #NFX-1
_f      lda fx_t,x
        beq _nfx
        stx tmp6
        lda fx_xl,x
        sta tmp0
        lda fx_xh,x
        sta tmp1
        lda fx_yl,x
        sta tmp2
        lda fx_yh,x
        sta tmp3
        lda fx_t,x
        cmp #1
        beq _bolt
        jsr obj_scr
        bcc +
        ldx tmp6
        lda fx_t,x
        cmp #2
        bne _poof
        lda frame
        lsr
        and #1
        clc
        adc fx_tm,x
        and #1
        clc
        adc #CH_FIRE0
        sta (optr),y
        ; fire also on the four neighbours for big flasks
        jmp +
_poof   lda fx_tm,x
        and #2
        lsr
        clc
        adc #CH_POOF0
        sta (optr),y
+       ldx tmp6
        jmp _nfx
_bolt   ; a column of lightning from 6 cells above down to the target
        lda #6
        sta tmp7
-       lda tmp2
        sec
        sbc tmp7
        sta tmp2
        lda tmp3
        sbc #0
        sta tmp3
        jsr obj_scr
        bcc +
        lda tmp7
        and #1
        clc
        adc #CH_BOLT0
        sta (optr),y
+       lda tmp2
        clc
        adc tmp7
        sta tmp2
        lda tmp3
        adc #0
        sta tmp3
        dec tmp7
        bne -
        jsr obj_scr
        bcc +
        lda #CH_BOLT2
        sta (optr),y
+       ldx tmp6
_nfx    dex
        bpl _f
        ; ---- knives
        ldx #NK-1
_k      lda k_on,x
        beq _nk
        stx tmp6
        lda k_xl,x
        sta tmp0
        lda k_xh,x
        sta tmp1
        lda k_yl,x
        sta tmp2
        lda k_yh,x
        sta tmp3
        jsr obj_scr
        bcc +
        ldx tmp6
        lda k_d,x
        clc
        adc #CH_KNIFE0
        sta (optr),y
+       ldx tmp6
_nk     dex
        bpl _k
        ; ---- orbs
        lda w_lvl+3
        beq _r
        jsr orb_count
        sta tmp6
-       dec tmp6
        bmi _r
        lda tmp6
        jsr orb_cell
        jsr obj_scr
        bcc -
        lda frame
        lsr
        lsr
        and #1
        clc
        adc #CH_ORB0
        sta (optr),y
        jmp -
_r      rts

gem_char .byte CH_GEM0, CH_GEM1, CH_GEM2, CH_HEART, CH_CHEST
cre_char .byte CH_CREATURE0+0, CH_CREATURE0+3, CH_CREATURE0+6, CH_CREATURE0+9, CH_CREATURE0+12, CH_CREATURE0+15

; ---------------------------------------------------- palette of the night phase
pal_col  .byte 5, 4, 2, 6
set_palette
        ldx phase
        lda pal_col,x
        ora #8
        ldx #0
-       sta COLRAM,x
        sta COLRAM+$100,x
        sta COLRAM+$200,x
        sta COLRAM+$2e8,x
        inx
        bne -
        lda #0
        sta $d021
        lda #11
        sta $d022
        lda #1
        sta $d023
        rts

; ---------------------------------------------------- HUD sprites
; text in txtbuf (5 glyph indices) -> sprite at ptr0 (rows 0..4)
hud_text
        ldy #62
        lda #0
-       sta (ptr0),y
        dey
        bpl -
hud_text_nc
        lda #0
        sta tmp4                ; glyph
_gl     ldx tmp4
        lda txtbuf,x
        asl
        asl
        clc
        adc txtbuf,x            ; * 5
        sta tmp5                ; font index
        lda #0
        sta tmp6                ; row
_rw     ldx tmp5
        lda hud_font,x
        sta tmp7
        ; 3 bits at x = glyph * 4
        lda #0
        sta tmp3
_bit    asl tmp7
        bcc _nb
        lda tmp4
        asl
        asl
        clc
        adc tmp3                ; x
        pha
        lsr
        lsr
        lsr
        sta tmp2
        lda tmp6
        asl
        clc
        adc tmp6
        adc tmp2
        tay                     ; byte = row * 3 + x / 8
        pla
        and #7
        tax
        lda bitmask,x
        ora (ptr0),y
        sta (ptr0),y
_nb     inc tmp3
        lda tmp3
        cmp #3
        bne _bit
        inc tmp5
        inc tmp6
        lda tmp6
        cmp #5
        bne _rw
        inc tmp4
        lda tmp4
        cmp #5
        bne _gl
        rts
bitmask .byte $80,$40,$20,$10,$08,$04,$02,$01

; time "MM:SS" and "LV12" / kills
hud_update
        ; one part every second update: time, level and kills, xp bar
        inc hudslow
        lda hudslow
        and #1
        beq +
        rts
+       lda hudchg
        bne +
        rts
+       inc hudpart
        lda hudpart
        and #3
        beq hud_time
        cmp #1
        beq hud_lvl
        cmp #2
        bne +
        jmp xp_bar
+       lda #0
        sta hudchg
        rts
hudpart .byte 0
hudslow .byte 0
hud_time
        lda mins
        jsr bin2dig2
        stx txtbuf
        sty txtbuf+1
        lda #10
        sta txtbuf+2
        lda secs
        jsr bin2dig2
        stx txtbuf+3
        sty txtbuf+4
        lda #<(SPRDATA+(SPR_HUDT-$40)*64)
        sta ptr0
        lda #>(SPRDATA+(SPR_HUDT-$40)*64)
        sta ptr0+1
        jmp hud_text
hud_lvl
        lda #11
        sta txtbuf
        lda #12
        sta txtbuf+1
        lda plevel
        jsr bin2dig2
        stx txtbuf+2
        sty txtbuf+3
        lda #14
        sta txtbuf+4
        lda #<(SPRDATA+(SPR_HUDL-$40)*64)
        sta ptr0
        lda #>(SPRDATA+(SPR_HUDL-$40)*64)
        sta ptr0+1
        jsr hud_text
        ; kills in rows 8..12 of the level sprite: "K" + 4 digits
        lda #13
        sta txtbuf
        lda kills+1
        lsr
        lsr
        lsr
        lsr
        sta txtbuf+1
        lda kills+1
        and #15
        sta txtbuf+2
        lda kills
        lsr
        lsr
        lsr
        lsr
        sta txtbuf+3
        lda kills
        and #15
        sta txtbuf+4
        lda #<(SPRDATA+(SPR_HUDL-$40)*64+24)
        sta ptr0
        lda #>(SPRDATA+(SPR_HUDL-$40)*64+24)
        sta ptr0+1
        jmp hud_text_add

; like hud_text, but without clearing (second line)
hud_text_add
        lda ptr0
        pha
        lda ptr0+1
        pha
        ; clear 15 bytes (rows 8..12)
        ldy #14
        lda #0
-       sta (ptr0),y
        dey
        bpl -
        pla
        sta ptr0+1
        pla
        sta ptr0
        jmp hud_text_nc

; A (0..99) -> X tens, Y ones (glyph indices)
bin2dig2
        ldx #0
-       cmp #10
        bcc +
        sbc #10
        inx
        bne -
+       tay
        rts

; xp bar: two sprites, rows 0 and 6 frame, rows 2..4 fill (48 data pixels)
xp_bar
        ; fill width = xp * 46 / xpnext
        lda xp
        sta tmp0
        lda xp+1
        sta tmp1
        ldx #0
        ; tmp2/3 = accumulated xpnext / 46 steps: simple repeated subtraction of xpnext/46
        lda xpnext
        sta tmp2
        lda xpnext+1
        sta tmp3
        ; w = xp * 46 / xpnext  via 46 comparisons of xp*46 >= k*xpnext
        lda #0
        sta tmp4                ; acc lo (k * xpnext)
        sta tmp5
        sta tmp6                ; result
        ; xp * 46 in tmp0/tmp1/tmp7
        lda #0
        sta tmp7
        lda tmp0
        sta ptr1
        lda tmp1
        sta ptr1+1
        lda #0
        sta tmp0
        sta tmp1
        ldx #46
-       lda tmp0
        clc
        adc ptr1
        sta tmp0
        lda tmp1
        adc ptr1+1
        sta tmp1
        bcc +
        inc tmp7
+       dex
        bne -
_lp     lda tmp6
        cmp #46
        bcs _draw
        lda tmp4
        clc
        adc tmp2
        sta tmp4
        lda tmp5
        adc tmp3
        sta tmp5
        ; (tmp7 is 0 for all sensible values)
        lda tmp1
        cmp tmp5
        bcc _draw
        bne +
        lda tmp0
        cmp tmp4
        bcc _draw
+       inc tmp6
        jmp _lp
_draw   ; fill pixels 1 .. w of the 48 pixel wide bar (6 bytes)
        ldx #5
        lda #0
-       sta txtbuf,x
        dex
        bpl -
        ldx #0
_px     cpx tmp6
        bcs _rows
        txa
        clc
        adc #1
        tay
        lsr
        lsr
        lsr
        sta tmp3
        tya
        and #7
        tay
        lda bitmask,y
        ldy tmp3
        ora txtbuf,y
        sta txtbuf,y
        inx
        bne _px
_rows   ldy #0
-       lda #$ff
        sta XPS,y
        sta XPS+18,y
        sta XPS+64,y
        sta XPS+64+18,y
        iny
        cpy #3
        bne -
        ldy #3
        lda #0
-       sta XPS,y
        sta XPS+64,y
        iny
        cpy #18
        bne -
        ; end caps rows 1..5
        ldy #3
-       lda #$80
        sta XPS,y
        lda #$01
        sta XPS+64+2,y
        iny
        iny
        iny
        cpy #18
        bne -
        ; fill rows 2..4
        ldy #6
-       lda txtbuf
        ora #$80
        sta XPS,y
        lda txtbuf+1
        sta XPS+1,y
        lda txtbuf+2
        sta XPS+2,y
        lda txtbuf+3
        sta XPS+64,y
        lda txtbuf+4
        sta XPS+64+1,y
        lda txtbuf+5
        ora #$01
        sta XPS+64+2,y
        iny
        iny
        iny
        cpy #15
        bne -
        rts
XPS = SPRDATA+(SPR_XPL-$40)*64

; ---------------------------------------------------- hero body with the health bar (rows 19..20)
bodyfr  .byte SPR_HEROR0+1
bb_fr   .byte 0
bb_hp   .byte 0
bb_max  .byte 0
body_bar
        lda bodyfr
        cmp bb_fr
        bne +
        lda hp
        cmp bb_hp
        bne +
        lda maxhp
        cmp bb_max
        bne +
        rts
+       lda bodyfr
        sta bb_fr
        lda hp
        sta bb_hp
        lda maxhp
        sta bb_max
        ; copy the body frame
        lda bodyfr
        sec
        sbc #$40
        sta ptr0+1
        lda #0
        lsr ptr0+1
        ror
        lsr ptr0+1
        ror
        sta ptr0
        lda ptr0+1
        clc
        adc #>SPRDATA
        sta ptr0+1
        ldy #56
-       lda (ptr0),y
        sta BODYS,y
        dey
        bpl -
        ; n = hp * 12 / maxhp
        lda #0
        sta tmp2
        sta tmp3
        ldy #12
-       lda tmp2
        clc
        adc hp
        sta tmp2
        bcc +
        inc tmp3
+       dey
        bne -
        ldx #0
        lda #0
        sta tmp4
        sta tmp5
_n      lda tmp4
        clc
        adc maxhp
        sta tmp4
        bcc +
        inc tmp5
+       lda tmp3
        cmp tmp5
        bcc _bar
        bne +
        lda tmp2
        cmp tmp4
        bcc _bar
+       inx
        cpx #12
        bne _n
_bar    stx tmp6
        ldx #0                  ; byte
        ldy #0                  ; pixel
_by     lda #0
        sta tmp7
        lda #4
        sta tmp5
-       asl tmp7
        asl tmp7
        cpy tmp6
        bcs +
        inc tmp7
+       iny
        dec tmp5
        bne -
        lda tmp7
        sta BODYS+57,x
        sta BODYS+60,x
        inx
        cpx #3
        bne _by
        rts
BODYS = SPRDATA+(SPR_BODY-$40)*64
