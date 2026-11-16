; =====================================================================
;  IRQ: menu mode (one irq) and game mode (sprite multiplexer)
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
        lda starmove
        beq +
        jsr bg_rotate
+       inc frame
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

; ---------------------------------------------------- game mode
irq_game_on
        sei
        lda #0
        sta ready
        sta nx_count
        sta mux_base
        sta mux_end
        sta mux_idx
        sta cur_d015
        sta $d015
        lda #<irq_bottom
        sta $fffe
        lda #>irq_bottom
        sta $ffff
        lda $d011
        and #$7f
        sta $d011
        lda #SPLIT
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
        lda #D018A
        sta $d018
        lda #0
        sta $d015
        sta $d021
        lda ready
        beq _nolatch
        lda nx_base
        sta mux_base
        clc
        adc nx_count
        sta mux_end
        lda #0
        sta ready
_nolatch
        ldx mux_base
        ldy #0
_f8     cpx mux_end
        beq _f8d
        cpy #8
        beq _f8d
        sty itmp0
        jsr mux_write
        ldy itmp0
        iny
        inx
        bne _f8
_f8d    stx mux_idx
        lda d015tab,y
        sta cur_d015
        jsr bg_rotate
        lda #<irq_hud
        sta $fffe
        lda #>irq_hud
        sta $ffff
        lda #HUDLINE
        sta $d012
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

irq_hud
        pha
        txa
        pha
        tya
        pha
        cld
        lda zbg
        sta $d021
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
mux_loop
        ldx mux_idx
        jsr mux_write
        inx
        stx mux_idx
mux_sched
        cpx mux_end
        bcs _tosplit
        lda outy-8,x
        clc
        adc #22
        cmp #SPLIT-3
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
        pla
        tay
        pla
        tax
        pla
        rti
_tosplit
        lda #SPLIT
        sta $d012
        lda #<irq_bottom
        sta $fffe
        lda #>irq_bottom
        sta $ffff
        asl $d019
        pla
        tay
        pla
        tax
        pla
        rti

; X = index into out tables
mux_write
        ldy slot2tab,x
        lda outy,x
        sta $d001,y
        lda outxl,x
        sta $d000,y
        ldy slot1tab,x
        lda outp,x
        sta SCRA+$3f8,y
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

; ---------------------------------------------------- sort virtual sprites into next out buffer
; bucket lists (16 buckets of 16 lines), sorted on insert; accept max 8 per 21-line band
sort_sprites
        ldx #15
        lda #$ff
-       sta bhead,x
        dex
        bpl -
        ldx nactive
        dex
        bpl _si
        jmp _empty
_si     lda cy,x
        sta tmp2
        lsr
        lsr
        lsr
        lsr
        sta tmp3
        tay
        lda bhead,y
        bmi _front
        tay
        lda cy,y
        cmp tmp2
        bcs _front
_walk   sty tmp4
        lda bnext,y
        bmi _after
        tay
        lda cy,y
        cmp tmp2
        bcc _walk
_after  ldy tmp4
        lda bnext,y
        sta bnext,x
        txa
        sta bnext,y
        dex
        bpl _si
        bmi _sorted
_front  ldy tmp3
        lda bhead,y
        sta bnext,x
        txa
        sta bhead,y
        dex
        bpl _si
_sorted
        lda mux_base
        beq +
        lda #0
        beq ++
+       lda #40
+       sta nx_base
        sta tmp7
        tax
        lda #0
        sta tmp6
_tb     ldy tmp6
        lda bhead,y
_ti     bmi _nb
        sta tmp4
        tay
        lda cy,y
        cmp #SPLIT-4
        bcs _adone
        sta tmp5
        txa
        sec
        sbc tmp7
        cmp #8
        bcc _ok
        lda outy-8,x
        adc #21
        cmp #SPLIT-3
        bcs _skip
        adc #1
        cmp tmp5
        beq _ok
        bcs _skip
_ok     lda tmp5
        sta outy,x
        lda cxl,y
        sta outxl,x
        lda cxh,y
        sta outxh,x
        lda cp,y
        sta outp,x
        lda cc,y
        sta outc,x
        inx
_skip   ldy tmp4
        lda bnext,y
        jmp _ti
_nb     inc tmp6
        lda tmp6
        cmp #16
        bne _tb
_adone  txa
        sec
        sbc tmp7
        sta nx_count
        lda #1
        sta ready
        rts
_empty  lda mux_base
        beq +
        lda #0
        beq ++
+       lda #40
+       sta nx_base
        lda #0
        sta nx_count
        lda #1
        sta ready
        rts

; ---------------------------------------------------- pattern rotation (bubbles / waves)
bg_rotate
        ldx #3
_lp     lda pacc_l,x
        clc
        adc pat_speed,x
        sta pacc_l,x
        lda pacc_h,x
        adc #0
        sta pacc_h,x
        lda #0
        sec
        sbc pacc_h,x
        and #15
        sec
        sbc prot,x
        and #15
        beq _next
        stx bgsave
        cmp #8
        bcs _left
        lda prot,x
        clc
        adc #1
        and #15
        sta prot,x
        lda rotr_lo,x
        sta ijvec
        lda rotr_hi,x
        sta ijvec+1
        jmp _go
_left   lda prot,x
        sec
        sbc #1
        and #15
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

rotr_lo .byte <rotr0,<rotr1,<rotr2,<rotr3
rotr_hi .byte >rotr0,>rotr1,>rotr2,>rotr3
rotl_lo .byte <rotl0,<rotl1,<rotl2,<rotl3
rotl_hi .byte >rotl0,>rotl1,>rotl2,>rotl3

rotr    .macro base
        .for row := 0, row < 8, row += 1
        lda \base+8+row
        lsr
        ror \base+row
        ror \base+8+row
        .next
        rts
        .endm
rotl    .macro base
        .for row := 0, row < 8, row += 1
        lda \base+row
        asl
        rol \base+8+row
        rol \base+row
        .next
        rts
        .endm
PATC    = CHARSET + CH_BG*8
rotr0   #rotr PATC+0*16
rotr1   #rotr PATC+1*16
rotr2   #rotr PATC+2*16
rotr3   #rotr PATC+3*16
rotl0   #rotl PATC+0*16
rotl1   #rotl PATC+1*16
rotl2   #rotl PATC+2*16
rotl3   #rotl PATC+3*16
