; TSCrunch in-place decruncher (port of decrunch.asm by Antonio Savona, 2022)
; 64tass syntax, INPLACE variant.
tsget   = $f8
tstemp  = $fa
tsput   = $fb
lzput   = $fd

tsdecrunch
        ldy #$ff
_cp     iny
        lda (tsget),y
        sta tsput,y
        cpy #3
        bne _cp
        pha
        lda lzput
        sta optRun+1
        tya
        ldy #0
        beq update_getonly
entry2
        lax (tsget),y
        bmi rleorlz
        cmp #$20
        bcs lz2
        ; literal
        inc tsget
        beq updatelit_hi
return_from_updatelit
ts_delit_loop
        lda (tsget),y
        sta (tsput),y
        iny
        dex
        bne ts_delit_loop
        tya
        tax
updatezp
        ldy #0
updatezp_noclc
        adc tsput
        sta tsput
        bcs updateput_hi
putnoof
        txa
update_getonly
        adc tsget
        sta tsget
        bcc entry2
        inc tsget+1
        bcs entry2
updatelit_hi
        inc tsget+1
        bcc return_from_updatelit
updateput_hi
        inc tsput+1
        clc
        bcc putnoof
rleorlz
        alr #$7f
        bcc ts_delz
        ; RLE
        beq optRun
plain
        ldx #2
        iny
        sta tstemp
        lda (tsget),y
        ldy tstemp
runStart
        sta (tsput),y
ts_derle_loop
        dey
        sta (tsput),y
        bne ts_derle_loop
        lda tstemp
        bcs updatezp_noclc
done
        pla
        sta (tsput),y
        rts
lz2
        beq done
        ora #$80
        adc tsput
        sta lzput
        lda tsput+1
        sbc #$00
        sta lzput+1
        lda (lzput),y
        sta (tsput),y
        iny
        lda (lzput),y
        sta (tsput),y
        tya
        dey
        adc tsput
        sta tsput
        bcs lz2_put_hi
lz2_skp inc tsget
        bne entry2
        inc tsget+1
        bne entry2
lz2_put_hi
        inc tsput+1
        bcs lz2_skp
ts_delz
        lsr
        sta lzto+1
        iny
        lda tsput
        bcc long
        sbc (tsget),y
        sta lzput
        lda tsput+1
        sbc #$00
        ldx #2
lz_put
        sta lzput+1
        ldy #0
        lda (lzput),y
        sta (tsput),y
        iny
        lda (lzput),y
        sta (tsput),y
ts_delz_loop
        iny
        lda (lzput),y
        sta (tsput),y
lzto    cpy #0
        bne ts_delz_loop
        tya
        jmp updatezp
optRun
        ldy #255
        sty tstemp
        ldx #1
        bne runStart
long
        adc (tsget),y
        sta lzput
        iny
        lax (tsget),y
        ora #$80
        adc tsput+1
        cpx #$80
        rol lzto+1
        ldx #3
        bne lz_put
