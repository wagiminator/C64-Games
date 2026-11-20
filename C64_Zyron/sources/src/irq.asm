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
        jsr bg_drift
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
        lda #$1b
        sta $d011
        lda #SPLIT
        sta $d012
        lda #1
        sta $d01a
        asl $d019
        cli
        rts

irq_split
        pha
        txa
        pha
        tya
        pha
        cld
        #IPROF_IN
        lda #$18
        sta $d016
        lda #D018A
        sta $d018
        lda #0
        sta $d015
        ; ---- latch next frame data
        lda ready
        beq _nolatch
        lda nx_d016
        sta cur_d016
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
        ; ---- sprites whose hardware sprite is free from the top of the frame
        ldx mux_base
        lda #0
        sta cur_d015
_f8     cpx mux_end
        beq _f8d
        lda outfree,x
        bne _f8n
        jsr mux_write
        ldy outslot,x
        lda cur_d015
        ora bittab,y
        sta cur_d015
_f8n    inx
        bne _f8
_f8d    ldx mux_base
        stx mux_idx
        ; ---- parallax char rotation
        jsr bg_rotate
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
+       jsr music_play
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
        lda cur_d016
        sta $d016
        lda cur_d018
        sta $d018
        lda cur_d015
        sta $d015
        ldx mux_idx
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
        ldx mux_idx
        jsr mux_write
        inx
        stx mux_idx
mux_sched
        ; entries already written in the split IRQ are skipped
_skp    cpx mux_end
        bcs _tosplit
        lda outfree,x
        bne +
        inx
        stx mux_idx
        bne _skp
+       cmp #SPLIT-3
        bcs _tosplit
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
_tosplit
        lda #SPLIT
        sta $d012
        lda #<irq_split
        sta $fffe
        lda #>irq_split
        sta $ffff
        asl $d019
        #IPROF_OUT 2
        pla
        tay
        pla
        tax
        pla
        rti

; X = index into out tables
mux_write
        lda outslot,x
        asl
        tay
        lda outy,x
        sta $d001,y
        lda outxl,x
        sta $d000,y
        ldy outslot,x
        lda outp,x
        sta SCRA+$3f8,y
        sta SCRB+$3f8,y
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

bittab  .byte 1,2,4,8,16,32,64,128
nbittab .byte $fe,$fd,$fb,$f7,$ef,$df,$bf,$7f

; ---------------------------------------------------- parallax rotation (3 layers)
; layer 0: far stars (8 chars), 1: mid stars (4 chars), 2: skyline (8 chars)
bg_rotate
        lda cur_scrollpx        ; terrain halted (boss, stage end)?
        cmp bglast              ; -> freeze the parallax layers too
        beq bg_hold
        sta bglast
bg_drift                        ; entry for title/credits: always drift
        ldx #2
-       lda pacc_l,x
        clc
        adc pat_speed,x
        sta pacc_l,x
        lda pacc_h,x
        adc #0
        sta pacc_h,x
        dex
        bpl -
bg_hold ldx #2
_lp     lda cur_scrollpx
        sec
        sbc pacc_h,x
        and lay_pm,x
        sec
        sbc prot,x
        and lay_pm,x
        beq _next
        stx bgsave
        cmp lay_half,x
        bcs _left
        lda prot,x
        clc
        adc #1
        and lay_pm,x
        sta prot,x
        lda rotr_lo,x
        sta ijvec
        lda rotr_hi,x
        sta ijvec+1
        jmp _go
_left   lda prot,x
        sec
        sbc #1
        and lay_pm,x
        sta prot,x
        lda rotl_lo,x
        sta ijvec
        lda rotl_hi,x
        sta ijvec+1
_go     jsr _jmp
        ldx bgsave
_next   dex
        bpl _lp
        rts
_jmp    jmp (ijvec)

rotr_lo .byte <rotr0,<rotr1,<rotr2
rotr_hi .byte >rotr0,>rotr1,>rotr2
rotl_lo .byte <rotl0,<rotl1,<rotl2
rotl_hi .byte >rotl0,>rotl1,>rotl2

; rotate a strip of n chars (8 lines) by one pixel (wrapping)
rotr    .macro base, n
        .for row := 0, row < 8, row += 1
        lda \base+(\n-1)*8+row
        lsr
        .for c := 0, c < \n, c += 1
        ror \base+c*8+row
        .next
        .next
        rts
        .endm
rotl    .macro base, n
        .for row := 0, row < 8, row += 1
        lda \base+row
        asl
        .for c := \n-1, c >= 0, c -= 1
        rol \base+c*8+row
        .next
        .next
        rts
        .endm

rotr0   #rotr CHARSET+LAY_F*8, 8
rotr1   #rotr CHARSET+LAY_M*8, 8
rotr2   #rotr CHARSET+LAY_H*8, 8
rotl0   #rotl CHARSET+LAY_F*8, 8
rotl1   #rotl CHARSET+LAY_M*8, 8
rotl2   #rotl CHARSET+LAY_H*8, 8

; ---------------------------------------------------- colour RAM shift code generator
; emits: for each row r: 38 x (lda $d800+r*40+c+1 / sta $d800+r*40+c),
;        then lda colbuf+r / sta $d800+r*40+38 ; rts
gen_cshift
        lda #<CSHIFT
        sta ptr0
        lda #>CSHIFT
        sta ptr0+1
        lda #<COLRAM
        sta ptr1
        lda #>COLRAM
        sta ptr1+1
        lda #0
        sta tmp2                ; row
_row    lda #38
        sta tmp3
_col    lda #$ad
        jsr _emit
        lda ptr1
        clc
        adc #1
        php
        jsr _emit
        plp
        lda ptr1+1
        adc #0
        jsr _emit
        lda #$8d
        jsr _emit
        lda ptr1
        jsr _emit
        lda ptr1+1
        jsr _emit
        inc ptr1
        bne +
        inc ptr1+1
+       dec tmp3
        bne _col
        ; lda colbuf+r
        lda #$ad
        jsr _emit
        lda #<colbuf
        clc
        adc tmp2
        php
        jsr _emit
        plp
        lda #>colbuf
        adc #0
        jsr _emit
        lda #$8d
        jsr _emit
        lda ptr1
        jsr _emit
        lda ptr1+1
        jsr _emit
        ; next row: +2
        lda ptr1
        clc
        adc #2
        sta ptr1
        bcc +
        inc ptr1+1
+       inc tmp2
        lda tmp2
        cmp #PFROWS
        bne _row
        lda #$60
_emit   ldy #0
        sta (ptr0),y
        inc ptr0
        bne +
        inc ptr0+1
+       rts
