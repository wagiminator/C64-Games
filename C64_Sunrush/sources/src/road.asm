; =====================================================================
;  Road engine: projection, stripes, coarse/fine shift, row copies,
;  scenery pan, stage themes
; =====================================================================

; ---------------------------------------------------- theme / stage setup
; set up colours, scenery and course of 'stage' (theme = stage)
stage_setup
        lda stage
        sta theme
        tax
        lda th_sky,x
        sta skycol
        lda th_s22,x
        sta scn22
        lda th_s23,x
        sta scn23
        txa
        asl
        tay
        ldx #0                  ; colour tables: entry v -> colour of stripe phase v & $40
-       txa
        and #$40
        beq +
        iny
+       lda th_grass,y
        sta gtab,x
        lda th_kerb,y
        sta ktab,x
        lda th_road,y
        sta rtab,x
        txa
        and #$40
        beq +
        dey
+       inx
        bne -
        lda theme
        asl
        asl
        asl
        tax
        jsr set_glow
        ; course pointers
        ldx stage
        lda crs_lo_lo,x
        sta crsl
        lda crs_lo_hi,x
        sta crsl+1
        lda crs_hi_lo,x
        sta crsh
        lda crs_hi_hi,x
        sta crsh+1
        lda crs_c_lo,x
        sta crsc
        lda crs_c_hi,x
        sta crsc+1
        lda #0
        sta pseg
        ; scenery characters
        ldx theme
        ldy th_scn,x
        lda scn_ch_lo,y
        sta ptr0
        lda scn_ch_hi,y
        sta ptr0+1
        lda #<(CHARSET+CH_SCN*8)
        sta ptr1
        lda #>(CHARSET+CH_SCN*8)
        sta ptr1+1
        lda scn_n,y
        sta tmp0                ; chars
-       ldy #7
-       lda (ptr0),y
        sta (ptr1),y
        dey
        bpl -
        lda ptr0
        clc
        adc #8
        sta ptr0
        bcc +
        inc ptr0+1
+       lda ptr1
        clc
        adc #8
        sta ptr1
        bcc +
        inc ptr1+1
+       dec tmp0
        bne --
        ; colour RAM: scenery rows and road rows
        ldx theme
        lda th_lane,x
        ldy #0
-       sta COLRAM+ROADROW*40,y
        sta COLRAM+ROADROW*40+200,y
        sta COLRAM+ROADROW*40+400,y
        iny
        cpy #200
        bne -
        txa
        asl
        asl
        sta tmp0
        txa
        clc
        adc tmp0
        tax                     ; theme*5
        ldy #0
_sr     lda th_srow,x
        sta tmp1
        sty tmp2
        tya
        clc
        adc #SCNROW
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
        ldy tmp2
        inx
        iny
        cpy #5
        bne _sr
        ; force redraw of everything on both screens
        lda #$ff
        ldx #14
-       sta rowxA,x
        sta rowxB,x
        dex
        bpl -
        lda #0
        ldx #14
-       sta crow,x
        sta rvar,x
        dex
        bpl -
        lda #$ff
        sta scnxA
        sta scnxB
        rts

; ---------------------------------------------------- segment of the player
; advance pseg while the segment ends at or before pos
track_pseg
        ldy pseg
-       lda (crsh),y
        cmp posh
        bcc _nx
        bne _ok
        lda (crsl),y
        cmp posl
        beq _nx
        bcs _ok
_nx     iny
        bne -
_ok     sty pseg
        lda (crsc),y
        sta pcurve
        rts

; ---------------------------------------------------- projection
road_update
        ; ---- segment boundaries in view
        ldy pseg
        ; skip segments ending before ZNEAR
_sk     lda (crsl),y
        sec
        sbc posl
        sta tmp0
        lda (crsh),y
        sbc posh
        sta tmp1                ; dz to segment end (unsigned, >= 0)
        cmp #>ZNEAR
        bcc _skip
        bne _first
        lda tmp0
        cmp #<ZNEAR
        bcs _first
_skip   iny
        bne _sk
_first  lda (crsc),y
        jsr curve16
        stx cvl
        sta cvh
        ldx #0
_bl     ; is this segment's end inside the view (dz < ZFAR)?
        lda tmp1
        cmp #>ZFAR
        bcc +
        bne _bdone
        lda tmp0
        cmp #<ZFAR
        bcs _bdone
+       ; line = inv_line[dz >> 2]
        lda tmp1
        lsr
        sta tmp3
        lda tmp0
        ror
        lsr tmp3
        ror
        sta tmp2
        lda tmp3
        beq +
        ; dz/4 >= 256
        lda tmp2
        clc
        adc #<inv_line
        sta ptr0
        lda #>inv_line
        adc #1
        sta ptr0+1
        sty tmp4
        ldy #0
        lda (ptr0),y
        ldy tmp4
        jmp ++
+       stx tmp4
        ldx tmp2
        lda inv_line,x
        ldx tmp4
+       sta bnd_line,x
        iny
        lda (crsc),y
        sty tmp4
        stx tmp5
        jsr curve16
        stx tmp6
        ldx tmp5
        sta bnd_ch,x
        lda tmp6
        sta bnd_cl,x
        ldy tmp4
        inx
        cpx #5
        bcs _bdone
        ; dz of the next segment end
        lda (crsl),y
        sec
        sbc posl
        sta tmp0
        lda (crsh),y
        sbc posh
        sta tmp1
        jmp _bl
_bdone  lda #0
        sta bnd_line,x
        cpx #0
        beq +
        lda bnd_cl-1,x
        sta bnd_cl,x
        lda bnd_ch-1,x
        sta bnd_ch,x
        jmp ++
+       lda cvl
        sta bnd_cl,x
        lda cvh
        sta bnd_ch,x
+
        ; ---- start values: y = -px * 256, dx = dp = px * 2.094
        lda #0
        sta yl
        sec
        sbc pxl
        sta ym
        lda #0
        sbc pxh
        sta yh
        ; dp = 2*px + px/8 - px/32 (8.8)
        lda pxl
        sta tmp0
        lda pxh
        sta tmp1
        asl tmp0
        rol tmp1                ; 2px
        lda pxh
        cmp #$80
        ror
        sta tmp3
        lda pxl
        ror
        sta tmp2                ; px/2
        lda tmp3
        cmp #$80
        ror tmp3
        ror tmp2
        lda tmp3
        cmp #$80
        ror tmp3
        ror tmp2                ; px/8
        lda tmp0
        clc
        adc tmp2
        sta dxl
        lda tmp1
        adc tmp3
        sta dxh
        lda tmp3
        cmp #$80
        ror tmp3
        ror tmp2
        lda tmp3
        cmp #$80
        ror tmp3
        ror tmp2                ; px/32
        lda dxl
        sec
        sbc tmp2
        sta dxl
        lda dxh
        sbc tmp3
        sta dxh
        ; ---- support values W[k] = D(8k-1), k = 15 (line 119) .. 0 (line -1)
        ; per step of 8 lines: y += 8 dx + 36 c ; dx += 8 c
        lda #0
        sta segp
        jsr curve_consts
        ldx #15
        lda ym
        sta WL,x
        lda yh
        sta WH,x
_ln     ; curve change within the next 8 lines?  (boundary line >= 8(k-1)-1)
        txa
        asl
        asl
        asl
        sec
        sbc #9                  ; 8k-1 - 8 = line at the end of the step
        bcs +
        lda #0
+       sta tmp4
-       ldy segp
        lda bnd_line,y
        beq _nosw
        cmp tmp4
        bcc _nosw
        lda bnd_cl,y
        sta cvl
        lda bnd_ch,y
        sta cvh
        inc segp
        jsr curve_consts
        jmp -
_nosw   ; 8 dx (16 bit, sign extended to 24)
        lda dxl
        sta tmp0
        lda dxh
        sta tmp1
        ldy #0
        cmp #$80
        bcc +
        dey
+       sty tmp2
        asl tmp0
        rol tmp1
        rol tmp2
        asl tmp0
        rol tmp1
        rol tmp2
        asl tmp0
        rol tmp1
        rol tmp2
        clc
        lda yl
        adc tmp0
        sta yl
        lda ym
        adc tmp1
        sta ym
        lda yh
        adc tmp2
        sta yh
        ; + 36 c
        clc
        lda yl
        adc c36l
        sta yl
        lda ym
        adc c36m
        sta ym
        lda yh
        adc c36h
        sta yh
        ; dx += 8 c
        clc
        lda dxl
        adc c8l
        sta dxl
        lda dxh
        adc c8h
        sta dxh
        dex
        lda ym
        sta WL,x
        lda yh
        sta WH,x
        cpx #0
        beq +
        jmp _ln
+
        ; ---- per row: coarse offset, fine scroll interpolated per pair of lines
        ldy #0                  ; row
_row    ; delta = W[r+1] - W[r] (tmp6:tmp4)
        lda WL+1,y
        sec
        sbc WL,y
        sta tmp4
        lda WH+1,y
        sbc WH,y
        sta tmp6
        ; sum = W[r] + W[r+1] = 2 * road centre of the row (tmp7:tmp3)
        lda WL,y
        clc
        adc WL+1,y
        sta tmp3
        lda WH,y
        adc WH+1,y
        sta tmp7
        ; keep the previous coarse offset while the whole row still fits into the fine
        ; scroll range: 2*f_centre = sum - 16*c_prev in [|delta|, 14 - |delta|]
        ; (fewer row copies when the road drifts slowly)
        lda crow,y
        sta tmp2
        and #$80
        beq +
        lda #$ff
+       sta tmp5
        asl tmp2
        rol tmp5
        asl tmp2
        rol tmp5
        asl tmp2
        rol tmp5
        asl tmp2
        rol tmp5
        lda tmp3
        sec
        sbc tmp2
        sta tmp2
        lda tmp7
        sbc tmp5
        bne _new
        lda tmp6                ; |delta| < 8 ?
        bmi _dneg
        bne _new
        lda tmp4
        jmp _dabs
_dneg   cmp #$ff
        bne _new
        lda tmp4
        eor #$ff
        clc
        adc #1
_dabs   cmp #8
        bcs _new
        sta tmp5
        lda tmp2
        cmp tmp5
        bcc _new
        lda #14
        sec
        sbc tmp5
        cmp tmp2
        bcc _new
        lda crow,y
        sta tmp0
        jmp _cok
_new    ; coarse = (sum + 1) >> 4 (row centre, rounded)
        lda tmp3
        clc
        adc #1                  ; round to the nearest character
        sta tmp0
        lda tmp7
        adc #0
        cmp #$80
        ror
        ror tmp0
        cmp #$80
        ror
        ror tmp0
        cmp #$80
        ror
        ror tmp0
        cmp #$80
        ror
        ror tmp0
        ; clamp to -TMARGIN..TMARGIN (A:tmp0 signed)
        ora #0
        bmi _neg
        bne _cmax
        lda tmp0
        cmp #TMARGIN+1
        bcc _cok
_cmax   lda #TMARGIN
        sta tmp0
        jmp _cok
_neg    cmp #$ff
        bne _cmin
        lda tmp0
        cmp #256-TMARGIN
        bcs _cok
_cmin   lda #256-TMARGIN
        sta tmp0
_cok    lda tmp0
        sta crow,y
        lda #TMARGIN
        sec
        sbc tmp0
        sta rowx,y
        lda tmp0
        asl
        asl
        asl
        sta tmp2                ; 8*coarse (low byte)
        ; sheared template variant for steep rows (with hysteresis: rvar = 0 / 1 (+) / 2 (-))
        lda #0
        sta tmp5                ; shtab offset (kind * 8)
        ldx srowk,y
        beq _v0
        lda tmp6
        bmi _vneg
        bne _vpos
        lda srowt,y             ; enter threshold
        sta tmp0
        lda rvar,y
        cmp #1
        bne +
        lda srowh,y             ; hold threshold
        sta tmp0
+       lda tmp4
        cmp tmp0
        bcc _v0
_vpos   stx tmp5
        lda #1
        sta rvar,y
        lda rowx,y
        clc
        adc #TW
        sta rowx,y
        jmp _vdone
_vneg   cmp #$ff
        bne _vn2
        lda srowt,y
        sta tmp0
        lda rvar,y
        cmp #2
        bne +
        lda srowh,y
        sta tmp0
+       lda tmp4
        clc
        adc tmp0
        bcs _v0                 ; delta >= -threshold
_vn2    txa
        clc
        adc #8
        sta tmp5
        lda #2
        sta rvar,y
        lda rowx,y
        clc
        adc #2*TW
        sta rowx,y
        jmp _vdone
_v0     lda #0
        sta rvar,y
_vdone  ; step per line = delta / 8 as 8.8
        lda tmp4
        and #7
        tax
        lda fractab,x
        sta tmp0                ; fraction
        lda tmp6
        cmp #$80
        ror
        ror tmp4
        cmp #$80
        ror
        ror tmp4
        cmp #$80
        ror
        ror tmp4                ; integer part (8 bit)
        ; f = W[r] - 8c
        lda WL,y
        sec
        sbc tmp2
        sta tmp3
        lda #$80
        sta tmp7                ; rounding fraction
        sty tmp2
        tya
        asl
        asl
        asl
        tax                     ; first line of the row
        ldy tmp5
        bne _shear
        ; ---- unsheared row: one value per pair of lines (step * 2)
        asl tmp0
        rol tmp4
        clc
        lda tmp7                ; lines 0,1
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+0,x
        sta stF+1,x
        clc
        lda tmp7                ; lines 2,3
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+2,x
        sta stF+3,x
        clc
        lda tmp7                ; lines 4,5
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+4,x
        sta stF+5,x
        clc
        lda tmp7                ; lines 6,7
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+6,x
        sta stF+7,x
        jmp _rnext
_shear  ; ---- sheared row: one value per line, minus the shift built into the chars
        clc
        lda tmp7                ; line 0: f += step (8.8)
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        sec
        sbc shtab+0,y
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+0,x
        clc
        lda tmp7                ; line 1: f += step (8.8)
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        sec
        sbc shtab+1,y
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+1,x
        clc
        lda tmp7                ; line 2: f += step (8.8)
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        sec
        sbc shtab+2,y
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+2,x
        clc
        lda tmp7                ; line 3: f += step (8.8)
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        sec
        sbc shtab+3,y
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+3,x
        clc
        lda tmp7                ; line 4: f += step (8.8)
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        sec
        sbc shtab+4,y
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+4,x
        clc
        lda tmp7                ; line 5: f += step (8.8)
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        sec
        sbc shtab+5,y
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+5,x
        clc
        lda tmp7                ; line 6: f += step (8.8)
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        sec
        sbc shtab+6,y
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+6,x
        clc
        lda tmp7                ; line 7: f += step (8.8)
        adc tmp0
        sta tmp7
        lda tmp3
        adc tmp4
        sta tmp3
        sec
        sbc shtab+7,y
        cmp #8
        bcc +
        jsr fclamp
+       ora #$10
        sta stF+7,x
_rnext  ldy tmp2
        iny
        cpy #15
        beq +
        jmp _row
+
        jsr phase_fix
        ; road d018 for the back screen
        lda dispscr
        eor #1
        tax
        lda d18road,x
        sta st_d18
        rts
d18road .byte D18RA, D18RB
; clamp the fine scroll value: >= $80 (negative) -> 0, else 7; returns with carry clear
fclamp  asl
        lda #7
        bcc +
        lda #0
+       clc
        rts

fractab .byte $00,$20,$40,$60,$80,$a0,$c0,$e0

; 8c (16 bit) and 36c (24 bit) from cvl/cvh
curve_consts
        lda cvl
        sta c8l
        lda cvh
        sta c8h
        asl c8l
        rol c8h
        asl c8l
        rol c8h                 ; 4c
        lda c8l
        sta c36l
        lda c8h
        sta c36m                ; 4c
        asl c8l
        rol c8h                 ; 8c
        ; 36c = 32c + 4c
        lda c8l
        sta tmp0
        lda c8h
        sta tmp1
        ldy #0
        cmp #$80
        bcc +
        dey
+       sty tmp2
        asl tmp0
        rol tmp1
        rol tmp2
        asl tmp0
        rol tmp1
        rol tmp2                ; 32c
        ldy #0
        lda c36m
        bpl +
        dey
+       sty c36h
        clc
        lda c36l
        adc tmp0
        sta c36l
        lda c36m
        adc tmp1
        sta c36m
        lda c36h
        adc tmp2
        sta c36h
        rts

; A = signed curve value -> X = low, A = high (16 bit sign extended)
curve16
        tax
        lda #0
        cpx #$80
        bcc +
        lda #$ff
+       rts

; ---------------------------------------------------- draw changed rows into the back screen
draw_rows
        lda dispscr
        bne _toA
        ; back screen = B
        ldy #14
-       lda rowx,y
        cmp rowxB,y
        beq +
        sta rowxB,y
        sty tmp7
        pha
        tya
        clc
        adc #15
        tax
        pla
        jsr rowcopy
        ldy tmp7
+       dey
        bpl -
        rts
_toA    ldy #14
-       lda rowx,y
        cmp rowxA,y
        beq +
        sta rowxA,y
        sty tmp7
        ldx tmp7
        jsr rowcopy
        ldy tmp7
+       dey
        bpl -
        rts

; ---------------------------------------------------- scenery pan
; scnp (1/16 px) -> coarse column and fine scroll; redraw scenery rows of the back screen
scenery_update
        ; px position = scnp >> 4 (12 bit)
        lda scnph
        sta tmp1
        lda scnpl
        ldx #4
-       lsr tmp1
        ror
        dex
        bne -
        sta tmp0                ; px low 8 bits (wraps every 256 px = 32 chars? use 64 chars = 512px)
        and #7
        eor #7
        ora #$10
        sta st_scnf
        ; coarse = (px >> 3) & 63
        lda tmp1
        lsr
        lda tmp0
        ror
        lsr
        lsr
        and #63
        sta tmp2
        ldx dispscr
        bne _a
        cmp scnxB
        beq _r
        sta scnxB
        lda #>SCRB
        bne _draw
_a      cmp scnxA
        beq _r
        sta scnxA
        lda #>SCRA
_draw   sta ptr1+1
        lda #<(SCNROW*40)
        sta ptr1
        lda ptr1+1
        clc
        adc #>(SCNROW*40)
        sta ptr1+1
        ldx theme
        ldy th_scn,x
        lda scn_map_lo,y
        clc
        adc tmp2
        sta ptr0
        lda scn_map_hi,y
        adc #0
        sta ptr0+1
        ldx #5
_rw     ldy #39
-       lda (ptr0),y
        sta (ptr1),y
        dey
        bpl -
        lda ptr0
        clc
        adc #104
        sta ptr0
        bcc +
        inc ptr0+1
+       lda ptr1
        clc
        adc #40
        sta ptr1
        bcc +
        inc ptr1+1
+       dex
        bne _rw
_r      rts

; ---------------------------------------------------- D(line) from the support values
; Y = line (0..119) -> tmp2/tmp3 = displacement (signed 16 bit); preserves X
line_d
        stx tmp7
        tya
        lsr
        lsr
        lsr
        tax                     ; row r
        tya
        and #7
        sta tmp6                ; j
        lda WL+1,x
        sec
        sbc WL,x
        sta tmp4
        lda WH+1,x
        sbc WH,x
        sta tmp5                ; delta
        ; |delta| * (j+1) / 8 via multiply (|delta| clamped to 255)
        lda tmp5
        bpl +
        lda #0
        sec
        sbc tmp4
        sta tmp4
        lda #0
        sbc tmp5
+       beq +
        lda #$ff
        sta tmp4
+       lda tmp4
        sta mula
        ldy tmp6
        iny
        sty mulb
        txa
        pha
        jsr mul8
        pla
        tax
        lda mulr+1
        sta tmp3
        lda mulr
        lsr tmp3
        ror
        lsr tmp3
        ror
        lsr tmp3
        ror
        sta tmp2
        lda tmp5
        bpl +
        lda #0
        sec
        sbc tmp2
        sta tmp2
        lda #0
        sbc tmp3
        sta tmp3
+
        lda tmp2
        clc
        adc WL,x
        sta tmp2
        lda tmp3
        adc WH,x
        sta tmp3
        ldx tmp7
        rts
