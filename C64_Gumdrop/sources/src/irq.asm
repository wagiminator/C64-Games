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

; ---------------------------------------------------- game: bitmap above, text below
;  line 250: multicolour bitmap for the next frame
;  line 209: text mode for rows 20..24
IRQ_TOP = 250
IRQ_TEXT = 209

irq_game_on
        sei
        lda #<irq_game
        sta $fffe
        lda #>irq_game
        sta $ffff
        lda #$3b
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
        lda #$3b                ; bitmap on
        sta $d011
        lda #$18                ; multicolour
        sta $d016
        lda #D018BM
        sta $d018
        lda #<irq_text
        sta $fffe
        lda #>irq_text
        sta $ffff
        lda #IRQ_TEXT
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

irq_text
        pha
        asl $d019
        lda #211
-       cmp $d012
        bcs -
        lda #$1b                ; text mode
        sta $d011
        lda #$08
        sta $d016
        lda #D018TX
        sta $d018
        lda #<irq_game
        sta $fffe
        lda #>irq_game
        sta $ffff
        lda #IRQ_TOP
        sta $d012
        pla
        rti
