; =====================================================================
;  Raster interrupts
;  Menus: one IRQ per frame.
;  Game:  bottom (raster 251): sky colours, charset 1, sprites 0-7, music
;         split  (raster 121): charset 2 and the ground colour at the horizon
;         mux    (raster 160+): re-use sprites 2-7 further down
; =====================================================================

; ---------------------------------------------------- menus
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
        lda #D018S
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

; ---------------------------------------------------- game
irq_game_on
        sei
        lda #0
        sta spend
        sta nearpend
        sta vs_cnt
        sta vs_cnt+NV
        sta vbuf
        lda #NV
        sta vshow
        lda #<irq_bottom
        sta $fffe
        lda #>irq_bottom
        sta $ffff
        lda $d011
        and #$7f
        sta $d011
        lda #251
        sta $d012
        lda #1
        sta $d01a
        asl $d019
        cli
        rts

irq_bottom
        pha
        txa
        pha
        tya
        pha
        cld
        asl $d019
        lda #$18
        sta $d016
        lda #D018S
        sta $d018
        lda z_sky
        sta $d021
        ; new sprite list?
        lda spend
        beq +
        lda vbuf
        eor #NV
        sta vbuf
        eor #NV
        sta vshow
        lda #0
        sta spend
+       ; runner (sprites 0 and 1)
        lda ps_x
        sta $d000
        sta $d002
        lda ps_y0
        sta $d001
        lda ps_y1
        sta $d003
        lda ps_p0
        sta SCR+$3f8
        lda ps_p1
        sta SCR+$3f9
        lda ps_c0
        sta $d027
        lda ps_c1
        sta $d028
        lda ps_xh
        sta $d010
        lda #3
        sta mux_tmpe
        lda #0
        sta mux_tmpx
        sta mux_tmpy
        ; first six virtual sprites
        ldx vshow
        txa
        clc
        adc vs_cnt,x
        sta mux_end
        ldy #0
_first  cpx mux_end
        bcs _fdone
        cpy #6
        bcs _fdone
        jsr mux_write
        inx
        iny
        jmp _first
_fdone  stx mux_i
        ; enable: runner + used sprites
        lda mux_tmpe
        sta $d015
        lda mux_tmpx
        sta $d01d
        lda mux_tmpy
        sta $d017
        ; next: horizon split
        lda #SPLIT
        sta $d012
        lda #<irq_split
        sta $fffe
        lda #>irq_split
        sta $ffff
        inc frame
        cli
        jsr music_play
        jsr sfx_play
        ; stripes of the near rows (the beam has just left them)
        lda nearpend
        beq +
        lda #0
        sta nearpend
        jsr speed2
+       pla
        tay
        pla
        tax
        pla
        rti

; X = virtual sprite index (list offset included), Y = 0..5 hardware slot (sprite 2+Y)
; keeps $d015/$d01d/$d017 images in mux_tmpe/x/y (bottom IRQ) - in the mux IRQ the
; registers are changed directly
mux_write
        sty irqtmp
        lda hw2tab,y
        tay                     ; Y = sprite register offset (x2)
        lda vs_y,x
        sta $d001,y
        lda vs_x,x
        sta $d000,y
        ldy irqtmp
        lda vs_p,x
        sta SCR+$3fa,y
        lda vs_c,x
        sta $d029,y
        ; x high bit
        lda vs_xh,x
        beq +
        lda $d010
        ora bit2tab,y
        sta $d010
        jmp ++
+       lda $d010
        and nbit2tab,y
        sta $d010
+       ; expansion
        lda vs_e,x
        lsr
        bcc +
        lda mux_tmpx
        ora bit2tab,y
        sta mux_tmpx
        jmp ++
+       lda mux_tmpx
        and nbit2tab,y
        sta mux_tmpx
+       lda vs_e,x
        and #2
        beq +
        lda mux_tmpy
        ora bit2tab,y
        sta mux_tmpy
        jmp ++
+       lda mux_tmpy
        and nbit2tab,y
        sta mux_tmpy
+       lda mux_tmpe
        ora bit2tab,y
        sta mux_tmpe
        rts

hw2tab  .byte 4, 6, 8, 10, 12, 14
bit2tab .byte 4, 8, 16, 32, 64, 128
nbit2tab .byte $fb, $f7, $ef, $df, $bf, $7f

irq_split
        pha
        txa
        pha
        tya
        pha
        cld
        asl $d019
        lda #D018G
        ldx z_bg
-       ldy $d012
        cpy #SPLIT+1
        bne -
        ; wait for the end of the visible part of the line (sky line 71 is drawn
        ; with charset 1), switch before the badline of row 9 fetches its characters
        ldy #7
-       dey
        bne -
        ldy ntsc                ; NTSC lines are two cycles longer
        beq +
        nop
        nop
+       nop
        sta $d018
        stx $d021
        ; schedule the multiplexer or the bottom IRQ
        jmp mux_next

irq_mux
        pha
        txa
        pha
        tya
        pha
        cld
        asl $d019
mux_again
        ldx mux_i
        txa
        sec
        sbc vshow
        sec
-       sbc #6
        bcs -
        adc #6
        tay                     ; hardware slot = index mod 6
        lda mux_tmpe            ; keep registers in sync with the images
        sta $d015
        jsr mux_write
        lda mux_tmpe
        sta $d015
        lda mux_tmpx
        sta $d01d
        lda mux_tmpy
        sta $d017
        inc mux_i
mux_next
        ldx mux_i
        cpx mux_end
        bcs _tobot
        ; raster line where the sprite 6 entries before ends
        lda vs_y-6,x
        clc
        adc vs_h-6,x
        sta irqtmp
        lda $d012
        clc
        adc #2
        cmp irqtmp
        bcc _sched
        jmp mux_again           ; already there
_sched  lda irqtmp
        sta $d012
        lda #<irq_mux
        sta $fffe
        lda #>irq_mux
        sta $ffff
        jmp _out
_tobot  lda #251
        sta $d012
        lda #<irq_bottom
        sta $fffe
        lda #>irq_bottom
        sta $ffff
_out    pla
        tay
        pla
        tax
        pla
        rti
