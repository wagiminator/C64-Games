; =====================================================================
;  Alien formation: 5 rows x 11 columns, drawn with pre-shifted chars
;  column spacing 20 px (10 units of 2 px), row spacing 2 char rows
; =====================================================================
rowtype .byte 0,1,1,2,2
rowbase .byte 0,11,22,33,44
c10     .byte 0,10,20,30,40,50,60,70,80,90,100
sec3    .byte 0,3,6
rowcols .byte 7,3,5, 4,2,3, 1,7,4           ; per sector: type 0,1,2
alienpts .byte $03,$02,$01, $04,$03,$02, $05,$04,$03   ; BCD, units of 10
chbase  .byte CH_ALIEN+0,CH_ALIEN+12,CH_ALIEN+24,CH_ALIEN+36,CH_ALIEN+48,CH_ALIEN+60
marchnotes .byte 26,29,26,21                ; own 4-note pulse (D2 F2 D2 A1)

form_init
        ldx #54
        lda #1
-       sta alive,x
        dex
        bpl -
        ldx #10
        lda #5
-       sta colcnt,x
        dex
        bpl -
        ldx #4
        lda #11
-       sta rowcnt,x
        dex
        bpl -
        lda #55
        sta nalive
        lda #127
        sta fxo
        lda wave
        clc
        adc #4
        sta fy
        lda #0
        sta fdir
        sta fframe
        sta marchi
        sta invaded
        lda #20
        sta ftimer
        jsr form_bounds
        jsr form_cols
        jmp form_draw_all

; ---------------------------------------------------- lc / rc / br
form_bounds
        ldx #0
-       lda colcnt,x
        bne +
        inx
        cpx #11
        bne -
        rts
+       stx lc
        ldx #10
-       lda colcnt,x
        bne +
        dex
        bpl -
+       stx rc
        ldx #4
-       lda rowcnt,x
        bne +
        dex
        bpl -
+       stx br
        rts

; ---------------------------------------------------- column positions and redraw span
form_cols
        ldx #10
-       lda fxo
        clc
        adc c10,x
        sec
        sbc #100
        sta colx,x
        dex
        bpl -
        ldx lc
        lda colx,x
        lsr
        lsr
        sec
        sbc #1
        bcs +
        lda #0
+       sta spanl
        ldx rc
        lda colx,x
        lsr
        lsr
        clc
        adc #3
        cmp #40
        bcc +
        lda #39
+       sta spanr
        rts

; ---------------------------------------------------- background fill
; X = screen row, ftmp0..ftmp1 = first/last column (inclusive)
bg_fill
        stx fsalt
        lda rowlo,x
        sta fptr
        sta fcptr
        lda rowhiA,x
        sta fptr+1
        lda rowhiC,x
        sta fcptr+1
        cpx #ROW_BUNK
        bcc +
        cpx #ROW_BUNK+2
        bcs +
        ; bunker rows: keep intact bunker cells
        ldy ftmp0
-       lda (fptr),y
        cmp #CH_BUNK
        bcc _bz
        cmp #CH_BUNK+24
        bcc _bs
_bz     lda #32
        sta (fptr),y
_bs     iny
        cpy ftmp1
        beq -
        bcc -
        rts
+       lda gamerowpat,x
        bmi _blank
        tax
        lda pat_color,x
        sta ftmp3
        txa
        asl
        adc #CH_BG
        sta ftmp2
        lda fsalt
        asl
        asl
        asl
        sec
        sbc fsalt
        sta fsalt               ; row * 7
        ldy ftmp0
-       tya
        clc
        adc fsalt
        and #63
        tax
        lda sparse,x
        beq _sp
        tya
        and #1
        ora ftmp2
        bne _st
_sp     lda #32
_st     sta (fptr),y
        lda ftmp3
        sta (fcptr),y
        iny
        cpy ftmp1
        beq -
        bcc -
        rts
_blank  ldy ftmp0
        lda #32
-       sta (fptr),y
        iny
        cpy ftmp1
        beq -
        bcc -
        rts
sparse  .byte 1,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0
        .byte 0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0

; ---------------------------------------------------- draw
form_draw_all
        ldx #0
-       stx frow
        jsr form_row
        ldx frow
        inx
        cpx #5
        bne -
        rts

; X = formation row
form_row
        stx frow
        txa
        asl
        clc
        adc fy
        cmp #25
        bcc +
        rts
+       tax
        lda spanl
        sta ftmp0
        lda spanr
        sta ftmp1
        jsr bg_fill
        ldx frow
        lda rowcnt,x
        beq _out
        lda rowtype,x
        sta ftype
        ldy sector
        lda sec3,y
        clc
        adc ftype
        tay
        lda rowcols,y
        sta fclr
        lda ftype
        asl
        ora fframe
        tay
        lda chbase,y
        sta fch
        lda rowbase,x
        sta fidx
        ldx lc
_c      txa
        clc
        adc fidx
        tay
        lda alive,y
        beq _nx
        stx fcol
        lda colx,x
        and #3
        sta ftmp0
        asl
        adc ftmp0
        adc fch
        sta ftmp1
        lda colx,x
        lsr
        lsr
        tay
        ldx ftmp1
        txa
        sta (fptr),y
        lda fclr
        sta (fcptr),y
        iny
        inx
        txa
        sta (fptr),y
        lda fclr
        sta (fcptr),y
        lda ftmp0
        cmp #3
        bne +
        iny
        inx
        txa
        sta (fptr),y
        lda fclr
        sta (fcptr),y
+       ldx fcol
_nx     inx
        cpx rc
        beq _c
        bcc _c
_out    rts

; ---------------------------------------------------- one movement step
form_step
        lda nalive
        bne +
        rts
+       jsr form_bounds
        lda fdir
        bne _left
        ldx rc
        lda fxo
        clc
        adc c10,x
        bcs _drop
        cmp #250
        bcs _drop
        inc fxo
        jmp _move
_left   ldx lc
        lda fxo
        clc
        adc c10,x
        bcs +
        cmp #105
        bcc _drop
+       dec fxo
        jmp _move
_drop   jsr form_cols
        ldx #0
-       stx frow
        txa
        asl
        adc fy
        cmp #25
        bcs +
        tax
        lda spanl
        sta ftmp0
        lda spanr
        sta ftmp1
        jsr bg_fill
+       ldx frow
        inx
        cpx #5
        bne -
        inc fy
        lda fdir
        eor #1
        sta fdir
_move   lda fframe
        eor #1
        sta fframe
        jsr form_cols
        jsr form_draw_all
        jsr march_note
        ; invasion?
        lda br
        asl
        clc
        adc fy
        cmp #INVADE_ROW
        bcc +
        lda #1
        sta invaded
+       ; step period: alive/4 + 1 - sector - wave/2 (min 1)
        lda wave
        lsr
        clc
        adc sector
        sta ftmp0
        lda nalive
        lsr
        lsr
        sec
        sbc ftmp0
        bcs +
        lda #0
+       clc
        adc #1
        sta ftimer
        rts

; ---------------------------------------------------- march pulse on voice 1
march_note
        lda marchcool
        bne _r
        lda #4
        sta marchcool
        lda marchi
        clc
        adc #1
        and #3
        sta marchi
        tax
        ldy marchnotes,x
        lda freq_lo,y
        sta $d400
        lda freq_hi,y
        sta $d401
        lda #0
        sta $d402
        lda #$06
        sta $d403
        lda #$09
        sta $d405
        lda #$00
        sta $d406
        lda #$40
        sta $d404
        lda #$41
        sta $d404
_r      rts

; ---------------------------------------------------- hit test
; in: tmp0 = screen x/2 (bullet centre), tmp1 = screen y
; out: C=1 -> X = row, Y = column of the alien hit
form_hit
        lda nalive
        beq _no
        lda fy
        asl
        asl
        asl
        sta ftmp0
        lda tmp1
        sec
        sbc ftmp0
        bcc _no
        cmp #80
        bcs _no
        tax
        and #8
        bne _no
        txa
        lsr
        lsr
        lsr
        lsr
        sta frow
        lda tmp0
        clc
        adc #100
        bcs _big
        sec
        sbc fxo
        bcc _no
        bcs _dx
_big    sec
        sbc fxo
        bcs _no
_dx     cmp #110
        bcs _no
        tax
        lda mod10,x
        cmp #6
        bcs _no
        lda div10,x
        sta fcol
        ldx frow
        clc
        adc rowbase,x
        tay
        lda alive,y
        beq _no
        ldy fcol
        sec
        rts
_no     clc
        rts

; ---------------------------------------------------- kill alien X = row, Y = column
form_kill
        stx frow
        sty fcol
        tya
        clc
        adc rowbase,x
        tay
        lda #0
        sta alive,y
        dec nalive
        dec rowcnt,x
        ldx fcol
        dec colcnt,x
        ; erase chars
        lda colx,x
        lsr
        lsr
        sta ftmp0
        clc
        adc #1
        sta ftmp1
        lda colx,x
        and #3
        cmp #3
        bne +
        inc ftmp1
+       lda frow
        asl
        clc
        adc fy
        cmp #25
        bcs +
        tax
        jsr bg_fill
+       ; explosion sprite (slot 6)
        ldx fcol
        lda colx,x
        clc
        adc #9
        sta spx+6
        lda frow
        asl
        clc
        adc fy
        asl
        asl
        asl
        clc
        adc #44
        sta spy+6
        lda #SPR_AEXPL
        sta spp+6
        ldx frow
        lda rowtype,x
        sta ftype
        ldy sector
        lda sec3,y
        clc
        adc ftype
        tay
        lda rowcols,y
        sta spc+6
        lda #16
        sta ex_t
        lda alienpts,y
        ldx #0
        jsr score_add
        lda #SFX_HIT
        jsr sfx_start
        jsr form_bounds
        ; faster when fewer aliens: shorten current wait
        lda ftimer
        cmp #2
        bcc +
        dec ftimer
+       rts

; ---------------------------------------------------- choose a shooter
; out: C=1 -> X = row, Y = column of bottom-most alien in chosen column
form_shooter
        jsr rnd
        bmi _aim
        and #15
        cmp #11
        bcs _aim
        tay
        lda colcnt,y
        bne _have
_aim    lda px
        clc
        adc #91
        bcs _edge
        sec
        sbc fxo
        bcc _lft
        cmp #110
        bcs _edge
        tax
        ldy div10,x
        lda colcnt,y
        bne _have
_lft    ldy lc
        jmp _have
_edge   ldy rc
_have   sty fcol
        ldx #4
-       lda rowbase,x
        clc
        adc fcol
        tay
        lda alive,y
        bne _f
        dex
        bpl -
        clc
        rts
_f      ldy fcol
        sec
        rts
