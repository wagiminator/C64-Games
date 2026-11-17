; =====================================================================
;  IRQ: menu mode (one irq) and race mode (sky split, road line program)
; =====================================================================
irq_simple_on
        sei
        lda #<irq_simple
        sta $fffe
        lda #>irq_simple
        sta $ffff
        lda $d011
        and #$7f
        sta $d011
        lda #250
        sta $d012
        lda #1
        sta $d01a
        asl $d019
        lda #0
        sta gamemode
        cli
        rts

irq_simple
        pha
        txa
        pha
        tya
        pha
        cld
        asl $d019
        lda #$08
        sta $d016
        lda #D18A
        sta $d018
        inc frame
        cli
        jsr music_play
        jsr sfx_play
        pla
        tay
        pla
        tax
        pla
        rti

waitframe
        lda frame
-       cmp frame
        beq -
        rts

; ---------------------------------------------------- race mode
irq_race_on
        sei
        lda #0
        sta ready
        lda #<irq_road
        sta $fffe
        lda #>irq_road
        sta $ffff
        lda $d011
        and #$7f
        sta $d011
        lda #120
        sta $d012
        lda #1
        sta $d01a
        sta gamemode
        asl $d019
        cli
        rts

; line 120: road line program (123..250), then frame switch and bottom work
irq_road
        pha
        txa
        pha
        tya
        pha
        cld
        asl $d019
        jsr lineprog
        ; ---- top of next frame: HUD in hires text on black
        lda #0
        sta $d021
        lda #$18
        sta $d016
        lda ready
        beq _nolatch
        jsr take_over
        jsr commit
_nolatch
        ldx dispscr
        lda d18tab,x
        sta $d018
        jsr spr8_write
        lda #<irq_sky
        sta $fffe
        lda #>irq_sky
        sta $ffff
        lda #74
        sta $d012
        asl $d019               ; drop a flag raised while the line program ran
        inc frame
        cli
        jsr music_play
        jsr sfx_play
        pla
        tay
        pla
        tax
        pla
        rti
d18tab  .byte D18A, D18B

; line 74: sky and scenery colours from line 75 on
irq_sky
        pha
        txa
        pha
        lda skycol
        ldx scn_fine
        pha
        lda #74
-       cmp $d012               ; wait until raster >= 75
        bcs -
        pla
        sta $d021
        stx $d016
        lda scn22
        sta $d022
        lda scn23
        sta $d023
        ; second take-over point: before the scenery rows (line 91) and the road (123)
        lda ready
        beq _noto
        tya
        pha
        jsr take_over
        ldx dispscr
        lda d18tab,x
        sta $d018
        lda scn_fine
        sta $d016
        jsr spr8_write
        jsr commit
        pla
        tay
_noto   lda #<irq_road
        sta $fffe
        lda #>irq_road
        sta $ffff
        lda #120
        sta $d012
        asl $d019
        pla
        tax
        pla
        rti

; new frame data: flip screens, take over sprites and scenery scroll
take_over
        ldx #35
-       lda s8_y,x
        sta l8_y,x
        dex
        bpl -
        lda st_scnf
        sta scn_fine
        lda dispscr
        eor #1
        sta dispscr
        lda #0
        sta ready
        rts

; write the first 8 sprites of the next frame (objects; slots 4-7 later become the car)
spr8_write
        ldx #7
-       txa
        asl
        tay
        lda l8_y,x
        sta $d001,y
        lda l8_x,x
        sta $d000,y
        lda l8_p,x
        sta SCRA+$3f8,x
        sta SCRB+$3f8,x
        lda l8_c,x
        sta $d027,x
        dex
        bpl -
        lda l8_m
        sta $d010
        lda l8_xx
        sta $d01d
        lda l8_yy
        sta $d017
        lda l8_e
        sta $d015
        rts

; ---------------------------------------------------- generate the row copy code at $e000
; for screen s (A/B) and road row r: 40 x (lda tplr<r>+k,x / sta scr+(ROADROW+r)*40+k), rts
gen_rowcopy
        lda #<RCCODE
        sta ptr1
        lda #>RCCODE
        sta ptr1+1
        ldx #0                  ; routine index 0..29
_scr    lda #<(SCRA+ROADROW*40)
        sta ptr3
        lda #>(SCRA+ROADROW*40)
        cpx #15
        bcc +
        lda #>(SCRB+ROADROW*40)
+       sta ptr3+1
_row    txa                     ; template row = routine index mod 15
        cmp #15
        bcc +
        sbc #15
+       tay
        lda tplrow_lo,y
        sta ptr2
        lda tplrow_hi,y
        sta ptr2+1
        lda ptr1
        sta rc_lo,x
        lda ptr1+1
        sta rc_hi,x
        lda #40
        sta tmp0
        ldy #0
_k      lda #$bd                ; lda abs,x
        sta (ptr1),y
        iny
        lda ptr2
        sta (ptr1),y
        iny
        lda ptr2+1
        sta (ptr1),y
        iny
        lda #$8d                ; sta abs
        sta (ptr1),y
        iny
        lda ptr3
        sta (ptr1),y
        iny
        lda ptr3+1
        sta (ptr1),y
        iny
        inc ptr2
        bne +
        inc ptr2+1
+       inc ptr3
        bne +
        inc ptr3+1
+       dec tmp0
        bne _k
        lda #$60                ; rts
        sta (ptr1),y
        iny
        tya
        clc
        adc ptr1
        sta ptr1
        bcc +
        inc ptr1+1
+       inx
        cpx #15
        beq _scr
        cpx #30
        bne _row
        rts

; X = routine index (0..29), A = template offset -> copy one road row
rowcopy
        tay
        lda rc_lo,x
        sta _j+1
        lda rc_hi,x
        sta _j+2
        tya
        tax
_j      jmp $ffff
