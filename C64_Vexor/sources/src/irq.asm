; =====================================================================
;  IRQ handling: simple mode (menus) and game mode (split + mux)
; =====================================================================

; ---------------------------------------------------- simple mode
irq_simple_on
        sei
        lda #0
        sta gamemode
        sta $d015
        lda #<irq_simple
        sta $fffe
        lda #>irq_simple
        sta $ffff
        lda #$1b
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
        lda #$18
        sta $d016
        lda #D018A
        sta $d018
        jsr bg_rotate
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

; wait for next frame (simple mode)
waitframe
        lda frame
-       cmp frame
        beq -
        rts

IPROF_IN .macro
        .if PROFILE
        lda $dc04
        sta $03e0
        lda $dc05
        sta $03e1
        .fi
        .endm
IPROF_OUT .macro slot
        .if PROFILE
        sec
        lda $03e0
        sbc $dc04
        sta $03e2
        lda $03e1
        sbc $dc05
        sta $03e3
        clc
        lda $03e2
        adc $03e4+\slot*2
        sta $03e4+\slot*2
        lda $03e3
        adc $03e5+\slot*2
        sta $03e5+\slot*2
        .fi
        .endm

; ---------------------------------------------------- game mode
irq_game_on
        sei
        lda #1
        sta gamemode
        lda #0
        sta ready
        sta do_cshift
        sta $d015
        sta cur_d015
        lda #<irq_split
        sta $fffe
        lda #>irq_split
        sta $ffff
        lda #$17
        sta $d011
        lda #SPLITL
        sta $d012
        sta cur_split
        lda #1
        sta $d01a
        asl $d019
        cli
        rts

; ---------------------------------------------------- fixed bottom edge
; Raster IRQ on line BLANKL: switch to the invalid ECM+BMM mode (black) and
; sprites off, timed to land in the horizontal blank between BLANKL and
; BLANKL+1. The playfield therefore always ends on the same line, no matter
; where the vertical fine scroll puts the char rows / HUD split.
; Sprites that are already being displayed cannot be switched off via $d015,
; so their pointers are bent to an empty sprite before the VIC fetches the data
; for line BLANKL+1 (sprites 0-2 at cycles 58-62, sprites 3-7 next line 1-9).
; The real pointers for the next frame are set again in irq_top.
; Three handler variants (chosen via the vector when scheduling, blank_mode):
; 0 = screen A shown, 1 = screen B shown, 2 = BLANKL is a badline.
blank_ab .macro scr
        lda #SPR_EMPTY          ; 2
        .for i := 0, i < 8, i += 1
        sta \scr+$3f8+i         ; 32
        .next
        bit $ea                 ; 3
        stx $d011               ; 4
        .endm

irq_blank_a                     ; handler starts at cycle ~7..14
        pha                     ; 3
        stx irqsx               ; 3
        ldx cur_blank           ; 3
        #blank_ab SCRA          ; -> $d011 write at ~cycle 58..66
        jmp irq_blank_x
irq_blank_b
        pha
        stx irqsx
        ldx cur_blank
        #blank_ab SCRB
irq_blank_x
        ldx irqsx
        lda #0
        sta $d015
        jsr blank_next
        pla
        rti
irq_blank_l                     ; badline: CPU halted until cycle ~55
        pha
        lda cur_blank           ; edge first, sprites a line later
        sta $d011
        lda #SPR_EMPTY
        .for i := 0, i < 8, i += 1
        sta SCRA+$3f8+i
        sta SCRB+$3f8+i
        .next
        lda #0
        sta $d015
        jsr blank_next
        pla
        rti
blank_vlo .byte <irq_blank_a, <irq_blank_b, <irq_blank_l
blank_vhi .byte >irq_blank_a, >irq_blank_b, >irq_blank_l

blank_do                        ; inline entry from the multiplexer (X, Y free)
        ldx blank_mode          ; 3
        beq _a                  ; 2/3
        dex
        beq _b
        lda cur_blank
        sta $d011
        lda #SPR_EMPTY
        .for i := 0, i < 8, i += 1
        sta SCRA+$3f8+i
        sta SCRB+$3f8+i
        .next
        jmp _off
_a      ldx cur_blank
        #blank_ab SCRA
        jmp _off
_b      ldx cur_blank
        #blank_ab SCRB
_off    lda #0
        sta $d015
blank_next                      ; chain to the HUD split irq
        lda cur_split
        sta $d012
        lda #<irq_split
        sta $fffe
        lda #>irq_split
        sta $ffff
        asl $d019
        rts

irq_split
        pha                     ; 3
        lda split_bl            ; 3
        bne _direct             ; 2/3
        lda #$77                ; yscroll 7 for the HUD badline at 223,
        sta $d011               ; but still black (invalid mode)
        txa
        pha
        tya
        pha
        cld
        #IPROF_IN
        lda #D018A
        sta $d018
        lda #0
        sta $d015
        ldx #HUDLINE-1
        ldy #$17
-       cpx $d012               ; 7-cycle poll: leaves at cycle 0..6 of HUDLINE
        bcs -
        sty $d011               ; HUD: normal text mode before its first pixel
        jmp _latch
_direct lda #$17                ; SPLITL was a badline: the CPU only gets
        sta $d011               ; here at ~cycle 60, switch at once
        txa
        pha
        tya
        pha
        cld
        #IPROF_IN
        lda #D018A
        sta $d018
        lda #0
        sta $d015
_latch
        ; ---- latch next frame data
        lda ready
        beq _nolatch
        lda nx_d011
        sta cur_d011
        ora #$60
        sta cur_blank
        and #7
        ldx #2
        cmp #BLANKL & 7
        beq +
        ldx #0
        lda nx_d018
        cmp #D018A
        beq +
        inx
+       stx blank_mode
        lda nx_d011
        and #7
        ldx #0
        cmp #SPLITL & 7
        bne +
        inx
+       stx split_bl
        lda nx_split
        sta cur_split
        lda nx_d018
        sta cur_d018
        lda nx_cshift
        sta do_cshift
        lda nx_base
        sta mux_base
        clc
        adc nx_count
        sta mux_end
        lda scrollpx
        sta cur_scrollpx
        lda #0
        sta ready
        sta nx_cshift
_nolatch
        ; ---- first 8 sprites
        ldx mux_base
        ldy #0
_f8     cpx mux_end
        beq _f8d
        cpy #8
        beq _f8d
        sty itmp0
        jsr mux_write_np
        ldy itmp0
        iny
        inx
        bne _f8
_f8d    stx mux_idx
        lda d015tab,y
        sta cur_d015
        ; ---- next irq: top of screen
        lda #<irq_top
        sta $fffe
        lda #>irq_top
        sta $ffff
        lda #TOPLINE
        sta $d012
        asl $d019
        inc frame
        #IPROF_OUT 0
        cli
        #IPROF_IN
        lda do_cshift
        beq +
        jsr CSHIFT
        lda #0
        sta do_cshift
+       jsr bg_rotate
        jsr music_play
        jsr sfx_play
        #IPROF_OUT 1
        pla
        tay
        pla
        tax
        pla
        rti

irq_top
        pha
        txa
        pha
        tya
        pha
        cld
        #IPROF_IN
        lda cur_d011
        sta $d011
        lda cur_d018
        sta $d018
        lda cur_d015
        sta $d015
        ldx mux_base            ; pointers of the first 8 sprites
-       cpx mux_idx
        beq +
        ldy slot1tab,x
        lda outp,x
        sta SCRA+$3f8,y
        sta SCRB+$3f8,y
        inx
        bne -
+       ldx mux_idx
        jmp mux_sched

irq_mux
        pha
        txa
        pha
        tya
        pha
        cld
        #IPROF_IN
mux_loop
        lda $d012               ; burst ran into the bottom edge? stop:
        cmp #BLANKL-1           ; sprites written this late are past their
        bcs mux_tosplit         ; start line and would not show anyway
        ldx mux_idx
        jsr mux_write
        inx
        stx mux_idx
mux_sched
        cpx mux_end
        bcs mux_tosplit
        lda outy-8,x
        clc
        adc #22
        sta irqtmp
        lda #BLANKL-3
        cmp irqtmp
        bcc mux_tosplit
        beq mux_tosplit
        lda irqtmp
        sta irqtmp
        lda $d012
        clc
        adc #1
        cmp irqtmp
        bcc _sched
-       lda $d012
        cmp irqtmp
        bcc -
        jmp mux_loop
_sched  lda irqtmp
        sta $d012
        lda #<irq_mux
        sta $fffe
        lda #>irq_mux
        sta $ffff
        asl $d019
        #IPROF_OUT 2
        pla
        tay
        pla
        tax
        pla
        rti
mux_tosplit
        lda $d012               ; too close to the blank line for an irq?
        cmp #BLANKL-1
        bcc +
-       lda $d012               ; then wait for it here (same timing as irq)
        cmp #BLANKL
        bcc -
        jsr blank_do
        jmp _xit
+       lda #BLANKL
        sta $d012
        ldx blank_mode
        lda blank_vlo,x
        sta $fffe
        lda blank_vhi,x
        sta $ffff
        asl $d019
_xit
        #IPROF_OUT 2
        pla
        tay
        pla
        tax
        pla
        rti

; X = index into out tables
mux_write_np                    ; as mux_write, without the sprite pointer
        ldy slot2tab,x
        lda outy,x
        sta $d001,y
        lda outxl,x
        sta $d000,y
        ldy slot1tab,x
        jmp mux_wcol
mux_write
        ldy slot2tab,x
        lda outy,x
        sta $d001,y
        lda outxl,x
        sta $d000,y
        ldy slot1tab,x
        lda outp,x
        sta SCRA+$3f8,y
        sta SCRB+$3f8,y
mux_wcol
        lda outc,x
        sta $d027,y
        lda outxh,x
        beq +
        lda $d010
        ora bittab,y
        sta $d010
        rts
+       lda $d010
        and nbittab,y
        sta $d010
        rts

d015tab .byte 0,1,3,7,15,31,63,127,255
bittab  .byte 1,2,4,8,16,32,64,128
nbittab .byte $fe,$fd,$fb,$f7,$ef,$df,$bf,$7f
slot1tab
        .for i := 0, i < 80, i += 1
        .byte i & 7
        .next
slot2tab
        .for i := 0, i < 80, i += 1
        .byte (i & 7) * 2
        .next

; ---------------------------------------------------- parallax rotation
bg_rotate
        ldx #2
_lp     lda pacc_l,x
        clc
        adc pat_speed,x
        sta pacc_l,x
        lda pacc_h,x
        adc #0
        sta pacc_h,x
        lda cur_scrollpx
        sec
        sbc pacc_h,x
        and #63
        sec
        sbc prot,x
        and #63
        beq _next
        stx bgsave
        ldy prot,x
        sty bgold
        cmp #32
        bcs _left
        iny
        jmp +
_left   dey
+       tya
        and #63
        sta prot,x
        sta bgnew
        lda lstep_lo,x
        sta ijvec
        lda lstep_hi,x
        sta ijvec+1
        jsr _jmp
        ldx bgsave
_next   dex
        bpl _lp
        rts
_jmp    jmp (ijvec)

lstep_lo .byte <lstep0,<lstep1,<lstep2
lstep_hi .byte >lstep0,>lstep1,>lstep2

; sparse strip update: erase every entry at the old phase, draw at the new phase
; (line = (offset - phase) & 63 : a higher phase moves the content up)
lstep   .macro base, first, end
        ldx #\first
-       lda e_off,x
        sec
        sbc bgold
        and #63
        ora e_col,x
        tay
        lda #0
        sta \base,y
        inx
        cpx #\end
        bne -
        ldx #\first
-       lda e_off,x
        sec
        sbc bgnew
        and #63
        ora e_col,x
        tay
        lda e_val,x
        ora \base,y
        sta \base,y
        inx
        cpx #\end
        bne -
        rts
        .endm

lstep0  #lstep CHARSET+LAY_F*8, E0_FIRST, E1_FIRST
lstep1  #lstep CHARSET+LAY_M*8, E1_FIRST, E2_FIRST
lstep2  #lstep CHARSET+LAY_A*8, E2_FIRST, E3_FIRST

; ---------------------------------------------------- colour RAM shift code generator
; emits for r = 19..0: 40 x (lda $d800+r*40+c / sta $d800+(r+1)*40+c)
;       then 40 x (lda rowcols+c / sta $d800+c) ; rts
gen_cshift
        lda #<CSHIFT
        sta ptr0
        lda #>CSHIFT
        sta ptr0+1
        lda #<(COLRAM+19*40)
        sta ptr1
        lda #>(COLRAM+19*40)
        sta ptr1+1
        lda #20
        sta tmp2
_row    lda #0
        sta tmp3
_col    lda #$ad
        jsr _emit
        lda ptr1
        clc
        adc tmp3
        php
        jsr _emit
        plp
        lda ptr1+1
        adc #0
        jsr _emit
        lda #$8d
        jsr _emit
        lda ptr1
        clc
        adc tmp3
        php
        clc
        adc #40
        php
        jsr _emit
        plp
        lda ptr1+1
        adc #0
        plp
        adc #0
        jsr _emit
        inc tmp3
        lda tmp3
        cmp #40
        bne _col
        lda ptr1
        sec
        sbc #40
        sta ptr1
        bcs +
        dec ptr1+1
+       dec tmp2
        bne _row
        ; row 0 from rowcols
        lda #0
        sta tmp3
-       lda #$ad
        jsr _emit
        lda #<rowcols
        clc
        adc tmp3
        php
        jsr _emit
        plp
        lda #>rowcols
        adc #0
        jsr _emit
        lda #$8d
        jsr _emit
        lda tmp3
        jsr _emit
        lda #>COLRAM
        jsr _emit
        inc tmp3
        lda tmp3
        cmp #40
        bne -
        lda #$60
_emit   ldy #0
        sta (ptr0),y
        inc ptr0
        bne +
        inc ptr0+1
+       rts
