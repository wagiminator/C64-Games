; =====================================================================
;  Grimble's trading post: buy and sell equipment between stages
; =====================================================================
NITEMS  = 10                    ; + EXIT
SHOPROW = 6

        .virtual $03c0
s_cur   .byte ?
s_mode  .byte ?                 ; 0 buy, 1 sell
s_delay .byte ?
s_msg   .byte ?
s_plo   .byte ?                 ; computed price (BCD)
s_phi   .byte ?
s_lvl   .byte ?
        .endv

; item tables: variable, max level, base price (BCD lo/hi), half (sell) price, sellable
it_var  .word mainpow, autofire, sideshot, rearshot, laser, homing, pspeed, energy, lives, novaitem
it_max  .byte 4,1,1,1,1,1,3,0,9,1
it_min  .byte 1,0,0,0,0,0,1,0,0,0
it_plo  .byte $00,$00,$00,$50,$50,$00,$50,$50,$50,$00
it_phi  .byte $03,$04,$06,$03,$07,$09,$02,$01,$12,$10
it_slo  .byte $50,$00,$00,$75,$75,$50,$25,$00,$00,$00
it_shi  .byte $01,$02,$03,$01,$03,$04,$01,$00,$00,$05
it_sell .byte 1,1,1,1,1,1,1,0,0,1
it_name .text "MAIN POWER  "
        .text "AUTOFIRE    "
        .text "SIDE SHOTS  "
        .text "REAR SHOT   "
        .text "LASER BEAM  "
        .text "HOMING PODS "
        .text "SPEED UP    "
        .text "ENERGY      "
        .text "EXTRA SHIP  "
        .text "NOVA POWER  "

shop_screen
        jsr screen_setup
        jsr starfill_all
        lda #<t_shop
        sta ptr3
        lda #>t_shop
        sta ptr3+1
        jsr print_list
        #print t_hdr, 3, 4, 3
        #print t_shop1, 1, 1, 7
        #print t_shop2, 1, 2, 4
        ; trader portrait (6 hardware sprites)
        ldx #5
-       txa
        clc
        adc #SPR_TRADER
        sta SCRA+$3f8,x
        lda #5
        sta $d027,x
        lda tr_x,x
        sta tmp0
        txa
        asl
        tay
        lda tmp0
        sta $d000,y
        lda tr_y,x
        sta $d001,y
        dex
        bpl -
        lda #$3f
        sta $d010
        lda #0
        sta $d017
        sta $d01d
        sta $d01b
        lda #$3f
        sta $d01c
        lda #11
        sta $d025
        lda #1
        sta $d026
        lda #0
        sta s_cur
        sta s_mode
        sta s_delay
        jsr shop_draw
        lda #0
        jsr shop_say
        jsr screen_show
        lda #$3f
        sta $d015
        lda #TUNE_SHOP
        jsr music_start
        jsr wait_release
_loop   jsr waitframe
        lda s_delay
        beq +
        dec s_delay
        jmp _loop
+       jsr joyread
        beq _loop
        sta tmp6
        lda #9
        sta s_delay
        lda tmp6
        and #1
        beq +
        dec s_cur
        bpl _mv
        lda #NITEMS
        sta s_cur
        jmp _mv
+       lda tmp6
        and #2
        beq +
        inc s_cur
        lda s_cur
        cmp #NITEMS+1
        bcc _mv
        lda #0
        sta s_cur
        jmp _mv
+       lda tmp6
        and #12
        beq +
        lda s_mode
        eor #1
        sta s_mode
        jmp _mv
+       lda tmp6
        and #$10
        beq _loop
        lda #16
        sta s_delay
        lda s_cur
        cmp #NITEMS
        beq _exit
        jsr shop_action
        jsr shop_draw
        jmp _loop
_mv     lda #SFX_MENU
        jsr sfx_start
        jsr shop_draw
        jmp _loop
_exit   lda #0
        sta $d015
        jsr wait_release
        rts

tr_x    .byte 0,24,48,0,24,48
tr_y    .byte 52,52,52,73,73,73

; ---------------------------------------------------- item level / price
; X = item -> s_lvl = current level, s_plo/s_phi = buy price (BCD)
shop_price
        txa
        asl
        tay
        lda it_var,y
        sta ptr0
        lda it_var+1,y
        sta ptr0+1
        ldy #0
        lda (ptr0),y
        sta s_lvl
        lda #0
        sta s_plo
        sta s_phi
        ; multi-level items: price = base * level
        ldy it_max,x
        cpy #2
        bcc _once
        cpx #8
        beq _once
        ldy s_lvl
        bne +
        ldy #1
+       sed
-       clc
        lda s_plo
        adc it_plo,x
        sta s_plo
        lda s_phi
        adc it_phi,x
        sta s_phi
        dey
        bne -
        cld
        rts
_once   lda it_plo,x
        sta s_plo
        lda it_phi,x
        sta s_phi
        rts

; ---------------------------------------------------- buy / sell
shop_action
        ldx s_cur
        jsr shop_price
        lda s_mode
        bne _sell
        ; ---- buy: check max
        cpx #7
        bne +
        lda energy
        cmp #ENERGYMAX
        bcs _max
        bcc _afford
+       lda s_lvl
        cmp it_max,x
        bcs _max
_afford lda credits+1
        cmp s_phi
        bcc _poor
        bne +
        lda credits
        cmp s_plo
        bcc _poor
+       sed
        sec
        lda credits
        sbc s_plo
        sta credits
        lda credits+1
        sbc s_phi
        sta credits+1
        cld
        cpx #7
        bne +
        lda #ENERGYMAX
        sta energy
        bne _ok
+       ldy #0
        lda (ptr0),y
        clc
        adc #1
        sta (ptr0),y
_ok     lda #SFX_POWERUP
        jsr sfx_start
        jsr rnd
        and #1
        clc
        adc #1
        jmp shop_say
_max    lda #3
        jmp shop_say
_poor   lda #SFX_HIT
        jsr sfx_start
        lda #4
        jmp shop_say
_sell   lda it_sell,x
        beq _nos
        lda s_lvl
        cmp it_min,x
        beq _nos
        bcc _nos
        ; credits += half price * (level-1 for multi, 1 for single)
        ldy #1
        lda it_max,x
        cmp #2
        bcc +
        ldy s_lvl
        dey
+       sed
-       clc
        lda credits
        adc it_slo,x
        sta credits
        lda credits+1
        adc it_shi,x
        sta credits+1
        bcc +
        lda #$99
        sta credits
        sta credits+1
+       dey
        bne -
        cld
        ldy #0
        lda (ptr0),y
        sec
        sbc #1
        sta (ptr0),y
        lda #SFX_EXTRA
        jsr sfx_start
        lda #5
        jmp shop_say
_nos    lda #6
        jmp shop_say

; ---------------------------------------------------- drawing
shop_draw
        ldx #0
_row    stx tmp6
        txa
        clc
        adc #SHOPROW
        tay
        lda rowlo,y
        sta ptr1
        sta ptr2
        lda rowhiA,y
        sta ptr1+1
        lda rowhiC,y
        sta ptr2+1
        ; colour
        lda #3
        cpx s_cur
        bne +
        lda #7
+       ldy #37
-       sta (ptr2),y
        dey
        bpl -
        ; cursor
        lda #32
        cpx s_cur
        bne +
        lda #CH_CUR
+       ldy #1
        sta (ptr1),y
        cpx #NITEMS
        bne _name
        ldy #3
        ldx #0
-       lda t_exit,x
        bne +
        jmp _nx
+       sta (ptr1),y
        iny
        inx
        bne -
_name   ; name
        txa
        asl
        asl
        sta tmp0
        asl
        clc
        adc tmp0                ; *12
        tax
        ldy #3
-       lda it_name,x
        sta (ptr1),y
        inx
        iny
        cpy #15
        bne -
        ; price / status
        ldx tmp6
        jsr shop_price
        ldy #17
        lda s_mode
        bne _sv
        cpx #7
        beq _bp
        lda s_lvl
        cmp it_max,x
        bcc _bp
        lda #<t_maxed
        ldx #>t_maxed
        jsr _txt
        jmp _lvl
_sv     lda it_sell,x
        beq _ns
        lda s_lvl
        cmp it_min,x
        beq _ns
        bcc _ns
        ; sell price: half * (lvl-1 or 1)
        lda #0
        sta s_plo
        sta s_phi
        lda it_max,x
        cmp #2
        lda #1
        bcc +
        lda s_lvl
        sec
        sbc #1
+       sta tmp0
        sed
-       clc
        lda s_plo
        adc it_slo,x
        sta s_plo
        lda s_phi
        adc it_shi,x
        sta s_phi
        dec tmp0
        bne -
        cld
        jmp _bp
_ns     lda #<t_dash
        ldx #>t_dash
        jsr _txt
        jmp _lvl
_bp     lda #36                 ; '$'
        sta (ptr1),y
        iny
        lda s_phi
        jsr _d2
        lda s_plo
        jsr _d2
        lda #32
        sta (ptr1),y
        iny
        sta (ptr1),y
_lvl    ; owned level at column 26
        ldx tmp6
        ldy #26
        cpx #7
        bne +
        lda energy
        lsr
        lsr
        ora #48
        sta (ptr1),y
        iny
        lda #47
        sta (ptr1),y
        iny
        lda #56
        sta (ptr1),y
        jmp _nx
+       lda s_lvl
        ora #48
        sta (ptr1),y
        iny
        lda #47
        sta (ptr1),y
        iny
        lda it_max,x
        ora #48
        sta (ptr1),y
_nx     ldx tmp6
        inx
        cpx #NITEMS+1
        beq +
        jmp _row
+       ; mode + credits
        lda s_mode
        beq +
        #print t_sellm, 2, 18, 2
        jmp ++
+       #print t_buym, 2, 18, 5
+       #print t_credits, 2, 20, 7
        ldx #0
        lda credits+1
        jsr _d2b
        lda credits
        jsr _d2b
        rts
_d2     pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta (ptr1),y
        iny
        pla
        and #15
        ora #48
        sta (ptr1),y
        iny
        rts
_d2b    pha
        lsr
        lsr
        lsr
        lsr
        ora #48
        sta SCRA+20*40+13,x
        inx
        pla
        and #15
        ora #48
        sta SCRA+20*40+13,x
        inx
        rts
_txt    sta ptr0
        stx ptr0+1
        ldx #0
-       sty tmp0
        txa
        tay
        lda (ptr0),y
        beq +
        ldy tmp0
        sta (ptr1),y
        iny
        inx
        bne -
+       ldy tmp0
        rts

; A = message number
shop_say
        asl
        tax
        lda says,x
        sta ptr0
        lda says+1,x
        sta ptr0+1
        ldx #39
        lda #32
-       sta SCRA+22*40,x
        dex
        bpl -
        lda #22
        sta tmp1
        lda #5
        sta tmp2
        jmp print_centre

says    .word say0, say1, say2, say3, say4, say5, say6
say0    .null "GREETINGS, PILOT! BUY SOMETHING SHINY."
say1    .null "SPLENDID CHOICE! IT EVEN WORKS."
say2    .null "PLEASURE DOING BUSINESS!"
say3    .null "YOU CAN'T IMPROVE ON PERFECTION."
say4    .null "NO CREDITS, NO DEAL. HA!"
say5    .null "I'LL TAKE IT... FOR A BARGAIN."
say6    .null "NOTHING TO SELL THERE, FRIEND."

t_exit    .null "EXIT SHOP"
t_maxed   .null "  MAX "
t_dash    .null "  --  "
t_buym    .null "MODE: BUY   (LEFT/RIGHT TO SWITCH)"
t_sellm   .null "MODE: SELL  (LEFT/RIGHT TO SWITCH)"
t_credits .null "CREDITS:  $"

t_shop1 .null "GRIMBLE'S GALACTIC GOODS"
t_shop2 .null "TRADER OF THE OUTER RIM"
t_hdr   .null "ITEM          PRICE    OWNED"
t_shop  .byte 24,4
        .null "UP/DOWN CHOOSE   FIRE CONFIRM"
        .byte $ff
