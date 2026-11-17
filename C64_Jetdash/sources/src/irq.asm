; =====================================================================
;  Raster interrupts
; =====================================================================

; ---------------------------------------------------- menus: one IRQ per frame
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
        lda #D018A
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

; ---------------------------------------------------- game: two IRQs per frame
;  line 250: apply the new state (screen, sprites), HUD without scrolling
;  line  65: fine scroll for the playfield (rows 2..24)
IRQ_TOP = 250
IRQ_SPLIT = 64

irq_game_on
        sei
        lda #0
        sta spend
        lda #<irq_game
        sta $fffe
        lda #>irq_game
        sta $ffff
        lda $d011
        and #$7f
        sta $d011
        lda #IRQ_TOP
        sta $d012
        lda #1
        sta $d01a
        asl $d019
        cli
        rts

irq_game
        pha
        txa
        pha
        tya
        pha
        cld
        asl $d019
        lda spend
        beq _nos
        lda nd018
        sta $d018
        lda nxs
        sta curxs
        ldx #0
        ldy #0
-       lda sx,y
        sta $d000,x
        lda sy,y
        sta $d001,x
        lda sc,y
        sta $d027,y
        lda sptr,y
        sta SCRA+$3f8,y
        sta SCRB+$3f8,y
        inx
        inx
        iny
        cpy #8
        bne -
        lda sxh
        sta $d010
        lda sen
        sta $d015
        lda #0
        sta spend
_nos    lda #$18                ; HUD: 40 columns, no fine scroll
        sta $d016
        lda #<irq_split
        sta $fffe
        lda #>irq_split
        sta $ffff
        lda #IRQ_SPLIT
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

irq_split
        pha
        lda curxs
        ora #$10                ; multicolour, 38 columns
        sta $d016
        asl $d019
        lda #<irq_game
        sta $fffe
        lda #>irq_game
        sta $ffff
        lda #IRQ_TOP
        sta $d012
        pla
        rti

irq_off
        sei
        lda #0
        sta $d01a
        asl $d019
        cli
        rts
