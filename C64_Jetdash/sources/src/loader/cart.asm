; =====================================================================
;  JETDASH Magic Desk cartridge boot (8 KB banks at $8000, $DE00 = bank,
;  bit 7 of $DE00 disables the cartridge). Copies the crunched game
;  image from the banks into RAM, decrunches in place and starts it.
; =====================================================================
        .cpu "6502i"
GAMESTART = $0810
LBASE   = $0400
BLOBOFS = $0400                 ; blob position inside bank 0
; BLOBLEN defined on command line

        * = $8000
        .word cold, cold
        .byte $c3, $c2, $cd, $38, $30
cold
        sei
        ldx #$ff
        txs
        cld
        lda #$37
        sta $01
        lda #$2f
        sta $00
        lda #0
        sta $de00
        jsr $fda3               ; IOINIT (CIAs)
        lda #0
        sta $d011
        sta $d020
        sta $d021
        sta $d015
        ldx #0
-       lda cblock,x
        sta LBASE,x
        lda cblock+$100,x
        sta LBASE+$100,x
        lda cblock+$200,x
        sta LBASE+$200,x
        inx
        bne -
        jmp copier

cblock
        .logical LBASE
copier
        lda #<($8000+BLOBOFS)
        sta $02
        lda #>($8000+BLOBOFS)
        sta $03
        lda #0
        sta bank
        lda #<BLOBLEN
        sta $06
        lda #>BLOBLEN
        sta $07
        jsr getsrc
        sta $04
        sta tsget
        jsr getsrc
        sta $05
        sta tsget+1
        ldy #0
_lp     jsr getsrc
        sta ($04),y
        inc $04
        bne +
        inc $05
+       lda $06
        bne +
        dec $07
+       dec $06
        lda $06
        ora $07
        bne _lp
        lda #$80                ; cartridge off
        sta $de00
        lda #$35
        sta $01
        jsr tsdecrunch
        jmp GAMESTART

getsrc  ldy #0
        lda ($02),y
        inc $02
        bne +
        inc $03
        ldx $03
        cpx #$a0
        bne +
        ldx #$80
        stx $03
        inc bank
        ldx bank
        stx $de00
+       rts
bank    .byte 0

        .include "decrunch.asm"
        .cerror * > $0800, "cart loader too big"
        .here
        .cerror * > $8000+BLOBOFS, "cart boot too big"
