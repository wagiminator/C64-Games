; =====================================================================
;  Roadside objects, traffic, sprite projection and slot allocation
; =====================================================================
ZHIT    = 341                   ; depth of the player's front bumper
FORK0   = STAGE_LEN-9000        ; fork signs from here
FORK1   = STAGE_LEN-1200
DIV0    = STAGE_LEN-2600        ; centre divider
DIV1    = STAGE_LEN+300

        .virtual $cc00
cdzl    .byte ?                 ; candidate input
cdzh    .byte ?
cobj    .byte ?                 ; lateral position / 2 (signed)
cbase   .byte ?
ccol    .byte ?
kcur    .byte ?
pl      .byte ?                 ; current object position (16 bit)
ph      .byte ?
spl     .byte ?                 ; spacing
sph     .byte ?
hsh     .byte ?
pprevl  .byte ?
pprevh  .byte ?
upfree  .byte ?
lofree  .byte ?
crashk  .byte ?
latd    .byte ?
        .endv

; ---------------------------------------------------- 8x8 unsigned multiply mula*mulb -> mulr
mul8                            ; quarter squares: a*b = q(a+b) - q(|a-b|)
        lda mula
        sec
        sbc mulb
        bcs +
        eor #$ff
        adc #1
+       tay                     ; |a-b|
        lda mula
        clc
        adc mulb
        tax
        bcs _hi
        lda qsq_lo,x
        sec
        sbc qsq_lo,y
        sta mulr
        lda qsq_hi,x
        sbc qsq_hi,y
        sta mulr+1
        rts
_hi     lda qsq_lo+256,x
        sec
        sbc qsq_lo,y
        sta mulr
        lda qsq_hi+256,x
        sbc qsq_hi,y
        sta mulr+1
        rts

; ---------------------------------------------------- add one candidate (cdz, cobj, cbase, ccol)
add_cand
        ldx nc
        cpx #NCAND
        bcc +
        rts
+       ; line = inv_line[dz >> 2]
        lda cdzh
        lsr
        sta tmp1
        lda cdzl
        ror
        lsr tmp1
        ror
        tay
        lda tmp1
        beq +
        lda inv_line+256,y
        jmp ++
+       lda inv_line,y
+       cmp #NL
        bcc +
        rts
+       sta c_i,x
        tay                     ; Y = line
        ; lateral offset = |cobj| * sc8 >> 7
        lda cobj
        bpl +
        eor #$ff
        clc
        adc #1
+       sta mula
        lda sc8,y
        sta mulb
        stx tmp4
        sty tmp5
        jsr mul8
        ldx tmp4
        ldy tmp5
        asl mulr
        rol mulr+1              ; >> 7 = hi byte of << 1
        lda mulr+1
        sta tmp0
        lda #0
        sta tmp1
        lda cobj
        bpl +
        lda #0
        sec
        sbc tmp0
        sta tmp0
        lda #$ff
        sta tmp1
+       ; x = 184 + D[line] + offset - half width
        lda szcls,y
        sta tmp6
        txa
        pha
        tya
        pha
        lda tmp6
        pha
        lda tmp0
        pha
        lda tmp1
        pha
        jsr line_d              ; tmp2/tmp3 = D(line)
        pla
        sta tmp1
        pla
        sta tmp0
        pla
        sta tmp6
        pla
        tay
        pla
        tax
        lda tmp2
        clc
        adc tmp0
        sta tmp2
        lda tmp3
        adc tmp1
        sta tmp3
        lda tmp2
        clc
        adc #184
        sta tmp2
        lda tmp3
        adc #0
        sta tmp3
        sty tmp5
        ldy tmp6
        lda tmp2
        sec
        sbc cls_half,y
        sta tmp2
        lda tmp3
        sbc #0
        sta tmp3
        ; visible: 0 <= x < 344
        bmi _rej
        cmp #2
        bcs _rej
        cmp #1
        bne +
        lda tmp2
        cmp #88
        bcs _rej
+       lda tmp2
        sta c_xl,x
        lda tmp3
        sta c_xh,x
        lda cbase
        clc
        adc cls_frame,y
        sta c_p,x
        lda cls_exp,y
        sta c_e,x
        lda ccol
        sta c_c,x
        ; y = HOR + line - h
        lda tmp5
        clc
        adc #HOR
        sec
        sbc cls_h,y
        sta c_y,x
        inc nc
        rts
_rej    rts

; ---------------------------------------------------- build all candidates for this frame
objects_update
        lda #0
        sta nc
        lda #0
        sta crashk
        ; ---- traffic first (most important)
        ldx #NTR-1
_tr     lda tr_on,x
        beq _trn
        lda tr_pl,x
        sec
        sbc posl
        sta cdzl
        lda tr_ph,x
        sbc posh
        sta cdzh
        bmi _trn
        ; within ZNEAR..ZFAR?
        cmp #>ZFAR
        bcc +
        bne _trn
        lda cdzl
        cmp #<ZFAR
        bcs _trn
+       lda tr_x,x
        sta cobj
        lda tr_s,x
        sta cbase
        lda tr_c,x
        sta ccol
        stx tmp7
        jsr add_cand
        ldx tmp7
_trn    dex
        bpl _tr
        ; ---- roadside objects: first k with k*S >= pos + ZNEAR
        ldx theme
        lda th_spacing,x
        sta tmp2                ; S/4
        asl
        asl
        sta spl
        lda tmp2
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
        sta sph
        ; (pos + ZNEAR) / 4
        lda posl
        clc
        adc #<ZNEAR
        sta tmp0
        lda posh
        adc #>ZNEAR
        sta tmp1
        lsr tmp1
        ror tmp0
        lsr tmp1
        ror tmp0
        jsr div16_8             ; tmp0/1 = quotient
        inc tmp0                ; k0
        lda tmp0
        sta kcur
        ; p = k0 * S  (16 bit): (k0 * S/4) * 4
        lda tmp0
        sta mula
        lda tmp2
        sta mulb
        jsr mul8
        lda mulr
        sta pl
        lda mulr+1
        sta ph
        lda tmp1                ; quotient high byte (k0 >= 256)
        beq +
        ldx tmp1
-       lda ph
        clc
        adc tmp2
        sta ph
        dex
        bne -
+       asl pl
        rol ph
        asl pl
        rol ph
_obj    ; dz = p - pos ; stop when >= ZFAR
        lda pl
        sec
        sbc posl
        sta cdzl
        lda ph
        sbc posh
        sta cdzh
        cmp #>ZFAR
        bcc +
        beq _chk
        jmp _odone
_chk    lda cdzl
        cmp #<ZFAR
        bcc +
        jmp _odone
+       jsr roadside_k
        ; next k
        inc kcur
        lda pl
        clc
        adc spl
        sta pl
        lda ph
        adc sph
        sta ph
        lda nc
        cmp #NCAND
        bcs _odone
        jmp _obj
_odone  ; crash smoke / dust
        lda crash_t
        ora bump_t
        beq +
        jsr add_smoke
+       lda posl
        sta pprevl
        lda posh
        sta pprevh
        jmp allocate

; objects at position p (k = kcur)
roadside_k
        ; hash
        lda kcur
        asl
        asl
        asl
        adc kcur
        eor #$a5
        adc stage
        sta hsh
        ; checkpoint / start gate?
        lda leg
        cmp #3
        bne +
        lda ph
        cmp #>STAGE_LEN
        bcs _gatej
        jmp _plain0
_gatej  jmp _gate               ; goal gate
+       lda ph
        cmp #>STAGE_LEN
        bcc +
        lda pl
        sec
        sbc #<STAGE_LEN
        lda ph
        sbc #>STAGE_LEN
        bne +
        jmp _gate
+       ; start gate in the first stage
        lda stage
        bne _nostart
        lda pl
        sec
        sbc #<600
        tax
        lda ph
        sbc #>600
        bcc _nostart            ; p < 600
        bne _nostart            ; p >= 856
        jmp _gate
_nostart
        lda leg
        cmp #3
        bcs _plain0
        ; centre divider zone
        lda ph
        cmp #>DIV0
        bcc _fork
        cmp #>DIV1+1
        bcs _plain0
        lda #0
        sta cobj
        lda #SPR_BOLLARD
        sta cbase
        lda #8
        sta ccol
        jsr add_cand
        jmp _plain
_fork   cmp #>FORK0
        bcc _plain0
        cmp #>FORK1
        bcs _plain0
        lda kcur
        and #1
        bne _plain0
        lda #256-80
        sta cobj
        lda #SPR_SIGNL
        sta cbase
        lda #7
        sta ccol
        jsr add_cand
        lda #80
        sta cobj
        lda #SPR_SIGNR
        sta cbase
        jsr add_cand
        rts
_plain0
_plain  ; type
        lda hsh
        lsr
        lsr
        and #3
        cmp #3
        bne +
        lda #0
+       sta tmp0
        lda theme
        asl
        clc
        adc theme
        adc tmp0
        tax
        lda th_obj,x
        sta cbase
        lda th_objc,x
        sta ccol
        lda hsh
        lsr
        lsr
        lsr
        lsr
        lsr
        clc
        adc #82
        sta latd                ; lateral distance / 2
        lda hsh
        and #3
        cmp #1
        beq _right
        ; left side
        lda #0
        sec
        sbc latd
        sta cobj
        jsr hit_test
        jsr add_cand
        lda hsh
        and #3
        bne _r
_right  lda latd
        sta cobj
        jsr hit_test
        jsr add_cand
_r      rts
_gate   lda #256-76
        sta cobj
        lda #SPR_GATE
        sta cbase
        lda #2
        sta ccol
        jsr add_cand
        lda #76
        sta cobj
        jmp add_cand

; crash test for a roadside object crossing the front bumper (cobj, p)
hit_test
        lda offroad
        beq _no
        lda crash_t
        bne _no
        ; previous dz > ZHIT and current dz <= ZHIT ?
        ; current dz <= ZHIT
        lda cdzh
        cmp #>ZHIT
        bcc +
        bne _no
        lda cdzl
        cmp #<ZHIT+1
        bcs _no
+       ; previous dz (16 bit) = p - pprev
        lda pl
        sec
        sbc pprevl
        sta tmp4
        lda ph
        sbc pprevh
        sta tmp5
        cmp #>ZHIT
        bcc _no
        bne +
        lda tmp4
        cmp #<ZHIT+1
        bcc _no
+       ; lateral: |px/2 - cobj| < 22
        lda pxh
        cmp #$80
        ror
        lda pxl
        ror                     ; px/2 (8 bit, range ok)
        sec
        sbc cobj
        bpl +
        eor #$ff
        clc
        adc #1
+       cmp #22
        bcs _no
        lda #1
        sta crashk
_no     rts

add_smoke
        lda #0
        sta cobj
        lda frame
        lsr
        lsr
        and #1
        ora #SPR_SMOKE
        sta cbase
        lda #15
        sta ccol
        ; place just behind the car: fake candidate at line ~116
        ldx nc
        cpx #NCAND
        bcs +
        lda #116
        sta c_i,x
        lda #0
        sta c_xh,x
        lda frame
        and #2
        clc
        adc #CARX+4
        sta c_xl,x
        lda #CARY+20
        sta c_y,x
        lda cbase
        sta c_p,x
        lda #0
        sta c_e,x
        lda #15
        sta c_c,x
        inc nc
+       rts

; ---------------------------------------------------- slot allocation -> s8_*, hooks for the car
allocate
        ; order by line, nearest (largest) first: selection
        ldx #0
-       txa
        sta c_ord,x
        inx
        cpx nc
        bcc -
        ldx #0
_so     cpx nc
        bcs _sdone
        stx tmp0
        txa
        tay
        iny
_si     cpy nc
        bcs _snext
        lda c_ord,y
        sta tmp1
        stx tmp2
        lda c_ord,x
        tax
        lda c_i,x
        ldx tmp1
        cmp c_i,x
        ldx tmp2
        bcs +
        ; swap
        lda c_ord,x
        pha
        lda c_ord,y
        sta c_ord,x
        pla
        sta c_ord,y
+       iny
        bne _si
_snext  inx
        bne _so
_sdone  ; assign
        lda #$f0
        sta upfree
        lda #$0f
        sta lofree
        lda #0
        sta s8_m
        sta s8_e
        sta s8_xx
        sta s8_yy
        ldy #7
        lda #SPR_BLANK
-       sta s8_p,y
        dey
        bpl -
        ldy #0
_as     cpy nc
        bcs _adone
        lda c_ord,y
        tax
        lda c_i,x
        cmp #UPPER_MAX+1
        bcs _low
        lda upfree
        beq _low
        jsr takeslot_up
        jmp _put
_low    lda lofree
        beq _skipc
        jsr takeslot_lo
_put    ; slot in tmp3, candidate X
        sty tmp7
        ldy tmp3
        lda c_y,x
        sta s8_y,y
        lda c_xl,x
        sta s8_x,y
        lda c_p,x
        sta s8_p,y
        lda c_c,x
        sta s8_c,y
        lda bittab,y
        ora s8_e
        sta s8_e
        lda c_xh,x
        beq +
        lda bittab,y
        ora s8_m
        sta s8_m
+       lda c_e,x
        beq +
        lda bittab,y
        ora s8_xx
        sta s8_xx
        lda bittab,y
        ora s8_yy
        sta s8_yy
+       ldy tmp7
_skipc  iny
        bne _as
_adone  ; ---- car in slots 4-7 (written by the line program)
        lda s8_m
        and #$0f
        sta hk_m
        lda s8_e
        and #$0f
        ora #$f0
        sta hk_e
        lda s8_xx
        and #$0f
        sta hk_xx
        lda s8_yy
        and #$0f
        sta hk_yy
        jsr car_frame           ; A = first frame pointer
        sta hk_p
        clc
        adc #1
        sta hk_p+1
        adc #1
        sta hk_p+2
        adc #1
        sta hk_p+3
        lda sbounce
        clc
        adc #CARY
        sta hk_y
        sta hk_y+1
        clc
        adc #21
        sta hk_y+2
        sta hk_y+3
        lda #CARX
        clc
        adc steer
        sta hk_x
        sta hk_x+2
        clc
        adc #24
        sta hk_x+1
        sta hk_x+3
        lda #2
        sta hk_c
        sta hk_c+1
        sta hk_c+2
        sta hk_c+3
        rts

takeslot_up
        lda upfree
        ldx #0
        beq +
takeslot_lo
        lda lofree
        ldx #0
+       stx tmp3
-       lsr
        bcs +
        inc tmp3
        bne -
+       ldx tmp3
        lda bittab,x
        eor #$ff
        and upfree
        sta upfree
        lda bittab,x
        eor #$ff
        and lofree
        sta lofree
        lda c_ord,y
        tax
        rts

bittab  .byte 1,2,4,8,16,32,64,128

; ---------------------------------------------------- traffic movement and spawning
traffic_update
        ldx #NTR-1
_lp     lda tr_on,x
        bne +
        jmp _spawn
+       ; move: pos += v/16 per frame (v*16 added to pos:frac)
        ldy dt
-       lda tr_v,x
        asl
        asl
        asl
        asl
        clc
        adc tr_pf,x
        sta tr_pf,x
        lda tr_v,x
        lsr
        lsr
        lsr
        lsr
        adc tr_pl,x
        sta tr_pl,x
        bcc +
        inc tr_ph,x
+       dey
        bne -
        ; dz = trpos - pos
        lda tr_pl,x
        sec
        sbc posl
        sta tmp0
        lda tr_ph,x
        sbc posh
        sta tmp1
        bmi _behind
        cmp #>2400
        bcs _off
        ; collision: crossing ZHIT from above
        jsr traffic_hit
        jmp _nx
_behind cmp #$fe
        bcc _off
        jmp _nx                 ; still close behind
_off    lda #0
        sta tr_on,x
        jmp _nx
_spawn  ; spawn rate by density
        lda state
        cmp #1
        bne _nx
        jsr rnd
        and #63
        ldy theme
        cmp th_density,y
        bcs _nx
        txa
        cmp th_density,y
        beq +
        bcs _nx
+       ; new car ahead, beyond the view
        lda #1
        sta tr_on,x
        lda #0
        sta tr_hit,x
        jsr rnd
        and #$7f
        clc
        adc #<(ZFAR+100)
        sta tmp0
        lda #>(ZFAR+100)
        adc #0
        sta tmp1
        lda posl
        clc
        adc tmp0
        sta tr_pl,x
        lda posh
        adc tmp1
        sta tr_ph,x
        jsr rnd
        and #3
        tay
        lda lanetab,y
        sta tr_x,x
        jsr rnd
        and #63
        clc
        adc #96
        sta tr_v,x
        jsr rnd
        and #3
        sta tmp0
        lda theme
        asl
        asl
        adc tmp0
        tay
        lda th_traffic,y
        sta tr_s,x
        jsr rnd
        and #7
        tay
        lda traffic_cols,y
        sta tr_c,x
_nx     dex
        bmi +
        jmp _lp
+       rts
lanetab .byte 256-43, 0, 43, 0

; X = car, tmp0/tmp1 = dz
traffic_hit
        lda tmp1
        cmp #>ZHIT
        bcc +
        bne _no
        lda tmp0
        cmp #<ZHIT+1
        bcs _no
+       lda tmp1                ; too far past the bumper -> ignore
        cmp #>(ZHIT-60)
        bcc _no
        bne +
        lda tmp0
        cmp #<(ZHIT-60)
        bcc _no
+       ; lateral |px/2 - x| < 26
        lda pxh
        cmp #$80
        ror
        lda pxl
        ror
        sec
        sbc tr_x,x
        bpl +
        eor #$ff
        clc
        adc #1
+       cmp #26
        bcs _no
        ; push the other car ahead and drop below its speed
        lda posl
        clc
        adc #<(ZHIT+90)
        sta tr_pl,x
        lda posh
        adc #>(ZHIT+90)
        sta tr_ph,x
        lda tr_v,x
        sec
        sbc #40
        sta vl
        lda #0
        sta vh
        jmp bump_fx
_no     rts
