; =====================================================================
;  Turbo tape boot loader (loaded by KERNAL, then reads turbo blocks)
;  pulse lengths: bit 0 ~208 cycles, bit 1 ~352 cycles, threshold 280
; =====================================================================
        .cpu "6502i"
GAMESTART = $0810
LBASE   = $0400
THRESH  = 280

        * = $0801
        .word (+), 2026
        .null $9e, format("%d", boot)
+       .word 0

boot    sei
        lda #$0b
        sta $d011
        ldx #0
-       lda lblock,x
        sta LBASE,x
        lda lblock+$100,x
        sta LBASE+$100,x
        inx
        bne -
        jmp tload

lblock
        .logical LBASE
tload
        lda #$7f
        sta $dc0d
        sta $dd0d
        lda $dc0d
        lda #0
        sta $d015
        sta $d020
        lda $01
        and #$df                ; cassette motor on
        sta $01
        lda #<THRESH
        sta $dc04
        lda #>THRESH
        sta $dc05
        lda #$19
        sta $dc0e
_sync   jsr getbit
        rol byte
        lda byte
        cmp #$40
        bne _sync
_pil    jsr getbyte
        cmp #$40
        beq _pil
        cmp #$5a
        bne _sync
        jsr getbyte
        sta $02
        sta tsget
        jsr getbyte
        sta $03
        sta tsget+1
        jsr getbyte
        sta cnt
        jsr getbyte
        sta cnt+1
        lda #0
        sta chk
        ldy #0
_lp     jsr getbyte
        sta ($02),y
        eor chk
        sta chk
        inc $02
        bne +
        inc $03
+       lda cnt
        bne +
        dec cnt+1
+       dec cnt
        lda cnt
        ora cnt+1
        bne _lp
        jsr getbyte
        cmp chk
        beq _ok
        lda $01                 ; load error: motor off, red border
        ora #$20
        sta $01
        lda #2
        sta $d020
        lda #$1b
        sta $d011
-       jmp -
_ok     lda $01
        ora #$20                ; motor off
        sta $01
        lda #0
        sta $d020
        lda #$35
        sta $01
        jsr tsdecrunch
        jmp GAMESTART

getbyte
        lda #1
        sta byte
-       jsr getbit
        rol byte
        bcc -
        lda byte
        sta $d020               ; loading stripes
        rts

; C = bit (1 = long pulse)
getbit
-       lda $dc0d
        and #$10
        beq -
        lda $dc0e               ; bit0 = 1 while timer still running (short pulse)
        eor #1
        lsr
        lda #$19                ; restart one-shot timer (force load)
        sta $dc0e
        rts

byte    .byte 0
chk     .byte 0
cnt     .word 0

        .include "decrunch.asm"
        .cerror * > $0800, "loader too big"
        .cerror * > LBASE+$200, "loader > 512 bytes"
        .here
