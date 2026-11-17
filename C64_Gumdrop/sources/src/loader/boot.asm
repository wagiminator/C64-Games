; =====================================================================
;  GUMDROP disk boot: uploads 1541 drive code, 2-bit fastload of the
;  crunched game file (2nd directory entry), in-place decrunch, start.
; =====================================================================
        .cpu "6502i"

SETLFS  = $ffba
SETNAM  = $ffbd
OPEN    = $ffc0
CHKOUT  = $ffc9
CHROUT  = $ffd2
CLRCHN  = $ffcc
GAMESTART = $0810
LBASE   = $0400

        * = $0801
        .word (+), 2026
        .null $9e, format("%d", boot)
+       .word 0

boot
        lda #0
        sta $d020
        sta $d021
        ldx #0
-       lda msg,x
        beq +
        jsr CHROUT
        inx
        bne -
+       ; ---- open command channel
        lda #15
        ldx $ba
        bne +
        ldx #8
+       ldy #15
        jsr SETLFS
        lda #0
        jsr SETNAM
        jsr OPEN
        ; ---- upload drive code with M-W (32 byte chunks)
        lda #<drivecode
        sta $fb
        lda #>drivecode
        sta $fc
        lda #<DRVADDR
        sta $fd
        lda #>DRVADDR
        sta $fe
_mw     ldx #15
        jsr CHKOUT
        lda #$4d
        jsr CHROUT
        lda #$2d
        jsr CHROUT
        lda #$57
        jsr CHROUT
        lda $fd
        jsr CHROUT
        lda $fe
        jsr CHROUT
        lda #32
        jsr CHROUT
        ldy #0
-       lda ($fb),y
        jsr CHROUT
        iny
        cpy #32
        bne -
        jsr CLRCHN
        lda $fb
        clc
        adc #32
        sta $fb
        bcc +
        inc $fc
+       lda $fd
        clc
        adc #32
        sta $fd
        bcc +
        inc $fe
+       lda $fd
        cmp #<(DRVADDR+DRVLEN)
        lda $fe
        sbc #>(DRVADDR+DRVLEN)
        bcc _mw
        ; ---- execute
        ldx #15
        jsr CHKOUT
        ldx #0
-       lda mecmd,x
        jsr CHROUT
        inx
        cpx #5
        bne -
        jsr CLRCHN
        ; ---- copy fast loader to $0400 and go
        sei
        lda #$0b
        sta $d011
        ldx #0
-       lda lblock,x
        sta LBASE,x
        lda lblock+$100,x
        sta LBASE+$100,x
        lda lblock+$200,x
        sta LBASE+$200,x
        inx
        bne -
        jmp fastload

msg     .byte 147, 5, 13, 13, 13, 13, 13, 13, 13, 13, 13
        .text "            gumdrop is loading..."
        .byte 13, 0
mecmd   .byte $4d,$2d,$45
        .byte <DRVADDR, >DRVADDR

; ---------------------------------------------------- C64 side fast loader
lblock
        .logical LBASE
fastload
        lda #$7f
        sta $dc0d
        lda $dc0d
        lda #0
        sta $d015
        lda #$27                ; hold DATA = ready
        sta $dd00
        lda #2
        sta hdr
        ldy #0
_blk    jsr getbyte
        beq _eof
        sta cnt
_byte   jsr getbyte
        ldx hdr
        beq _st
        dec hdr
        cpx #2
        bne +
        sta $02
        sta tsget
        jmp _nb
+       sta $03
        sta tsget+1
        jmp _nb
_st     sta ($02),y
        inc $02
        bne _nb
        inc $03
_nb     dec cnt
        bne _byte
        inc $d020
        jmp _blk
_eof    lda #$07
        sta $dd00
        lda #0
        sta $d020
        lda #$35
        sta $01
        jsr tsdecrunch
        jmp GAMESTART

hdr     .byte 0
cnt     .byte 0

; 2-bit receive. C64 holds DATA low while busy; drive pulls CLK when ready.
getbyte
-       bit $dd00               ; wait CLK low (drive ready)
        bvs -
        lda #$07                ; release DATA -> go
        sta $dd00               ; T = 0
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                     ; 16 cycles
        lda $dd00               ; read at T=20
        sta r0
        nop
        nop
        bit $ff
        lda $dd00               ; T=34
        sta r1
        nop
        nop
        bit $ff
        lda $dd00               ; T=48
        sta r2
        nop
        nop
        bit $ff
        lda $dd00               ; T=62
        sta r3
        lda #$27                ; busy again
        sta $dd00
        lda r0
        and #$c0
        sta r0
        lda r1
        and #$c0
        lsr
        lsr
        ora r0
        sta r0
        lda r2
        and #$c0
        lsr
        lsr
        lsr
        lsr
        ora r0
        sta r0
        lda r3
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
        ora r0
        eor #POLARITY
        cmp #0
        rts
r0 = $04
r1 = $05
r2 = $06
r3 = $07

        .include "decrunch.asm"
        .cerror * > $0800, "loader too big"
        .here
        .fill 3*256 - (* - lblock), 0

; ---------------------------------------------------- 1541 drive code
DRVADDR = $0500
drivecode
        .logical DRVADDR
drv     lda #0
        sta $1800
        lda #18
        sta $06
        lda #1
        sta $07
        jsr rdsec
        lda $0323
        sta $06
        lda $0324
        sta $07
_next
        .if NOREAD
        dec fakecnt
        bne +
        lda #0
        sta $0300
        lda #200
        sta $0301
        jmp _xx
+       lda #17
        sta $0300
_xx
        .else
        jsr rdsec
        .fi
        lda $0300
        beq _last
        lda #$ff
        bne +
_last   lda $0301
+       sta lastidx
        sec
        sbc #1
        jsr send
        ldx #2
-       lda $0300,x
        jsr send
        cpx lastidx
        beq +
        inx
        bne -
+       lda $0300
        beq _eof
        sta $06
        lda $0301
        sta $07
        jmp _next
_eof    lda #0
        jsr send
        lda #0
        sta $1800
        rts

rdsec   ldy #8
-       lda #$80
        sta $00
        cli
-       lda $00
        bmi -
        cmp #1
        beq +
        dey
        bne --
+       rts

; A = byte, preserves X
send    sta sbyte
        and #3
        tay
        lda enc,y
        sta o3
        lda sbyte
        lsr
        lsr
        and #3
        tay
        lda enc,y
        sta o2
        lda sbyte
        lsr
        lsr
        lsr
        lsr
        and #3
        tay
        lda enc,y
        sta o1
        lda sbyte
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
        tay
        lda enc,y
        sta o0
-       lda $1800               ; wait until C64 holds DATA
        lsr
        bcc -
        lda #$08                ; CLK low = byte ready
        sta $1800
        sei
        lda #$01
-       bit $1800               ; wait for DATA release
        bne -
        lda o0                  ; +10
        sta $1800
        nop
        nop
        nop
        lda o1                  ; +24
        sta $1800
        nop
        nop
        nop
        lda o2                  ; +38
        sta $1800
        nop
        nop
        nop
        lda o3                  ; +52
        sta $1800
        nop
        nop
        nop
        nop
        lda #0                  ; release
        sta $1800
        cli
        rts
enc     .byte $0a,$02,$08,$00
sbyte   .byte 0
fakecnt .byte 87
lastidx .byte 0
o0      .byte 0
o1      .byte 0
o2      .byte 0
o3      .byte 0
        .here
DRVLEN = * - drivecode
