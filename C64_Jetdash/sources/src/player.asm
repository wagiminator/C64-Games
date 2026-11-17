; =====================================================================
;  The hero: jetpack, copter, gravity belt, crash; coins and zappers
; =====================================================================

player_update
        lda pmode
        cmp #PM_COPTER
        beq p_copter
        cmp #PM_GRAV
        bne +
        jmp p_grav
+       cmp #PM_DEAD
        bne +
        jmp p_dead
+       cmp #PM_EXIT
        bne p_jet
        jmp p_exit

; ---------------------------------------------------- jetpack
p_jet
        lda #0
        sta thrust
        lda joy
        and #$10
        beq _fall
        inc thrust
        lda #<(-THRUST)
        ldx #>(-THRUST)
        jsr add_vy
        jmp +
_fall   lda #<GRAV
        ldx #>GRAV
        jsr add_vy
+       jsr clamp_vy
        jsr move_y
        ; jetpack sound
        lda thrust
        beq +
        lda frame
        and #15
        bne +
        lda #SFX_JET
        jsr sfx_start
+       rts

; ---------------------------------------------------- copter: tap fire to flap
p_copter
        lda #0
        sta thrust
        lda joynew
        and #$10
        beq +
        lda #<FLAPV
        sta vyf
        lda #>FLAPV
        sta vyi
        lda #SFX_FLAP
        jsr sfx_start
+       lda #<CGRAV
        ldx #>CGRAV
        jsr add_vy
        ; fall at most CMAXD
        lda vyi
        bmi +
        cmp #>CMAXD
        bcc +
        lda #<CMAXD
        sta vyf
        lda #>CMAXD
        sta vyi
+       jmp move_y

; ---------------------------------------------------- gravity belt: fire flips gravity
p_grav
        lda #0
        sta thrust
        lda ground
        beq +
        lda joynew
        and #$10
        beq +
        lda gdir
        eor #1
        sta gdir
        lda #0
        sta ground
        lda #SFX_FLIP
        jsr sfx_start
+       lda gdir
        bne _up
        lda #<BGRAV
        ldx #>BGRAV
        jsr add_vy
        lda vyi
        bmi _mv
        cmp #>BMAXV
        bcc _mv
        lda #<BMAXV
        sta vyf
        lda #>BMAXV
        sta vyi
        jmp _mv
_up     lda #<(-BGRAV)
        ldx #>(-BGRAV)
        jsr add_vy
        lda vyi
        bpl _mv
        cmp #>(-BMAXV)
        bcs _mv
        lda #<(-BMAXV)
        sta vyf
        lda #>(-BMAXV)
        sta vyi
_mv     jmp move_y

; ---------------------------------------------------- crashed: tumble, bounce, slide to a halt
p_dead
        lda #0
        sta thrust
        lda #<GRAV
        ldx #>GRAV
        jsr add_vy
        jsr clamp_vy
        lda vyi
        sta tmp5
        jsr move_y
        lda ground
        cmp #1
        bne _slow
        ; landed: bounce if fast
        lda tmp5
        bmi _slow
        cmp #2
        bcc _slow
        lsr
        eor #$ff
        sta vyi
        lda #0
        sta vyf
        sta ground
        lda #SFX_BUMP
        jsr sfx_start
_slow   ; slow down the scrolling
        lda ground
        beq _r
        lda spdf
        sec
        sbc #6
        sta spdf
        lda spdi
        sbc #0
        sta spdi
        bcs +
        lda #0
        sta spdf
        sta spdi
+       lda spdf
        ora spdi
        bne _r
        dec dtimer
_r      rts

; ---------------------------------------------------- leaving the lab: fly out to the right
p_exit
        lda #1
        sta thrust
        ; drift to y = 90
        lda hyi
        cmp #90
        beq +
        bcc _dn
        dec hyi
        jmp +
_dn     inc hyi
+       inc exittime
        lda exittime
        cmp #60
        bcc _r
        inc herox
        inc herox
_r      rts

; ---------------------------------------------------- physics helpers
add_vy  clc
        adc vyf
        sta vyf
        txa
        adc vyi
        sta vyi
        rts

clamp_vy
        lda vyi
        bmi _neg
        cmp #>MAXDOWN
        bcc _r
        lda #<MAXDOWN
        sta vyf
        lda #>MAXDOWN
        sta vyi
        rts
_neg    cmp #>MAXUP
        bcs _r
        lda #<MAXUP
        sta vyf
        lda #>MAXUP
        sta vyi
_r      rts

; y += vy, stop at floor and ceiling (ground = 1 floor, 2 ceiling)
move_y
        lda #0
        sta ground
        lda hyf
        clc
        adc vyf
        sta hyf
        lda hyi
        adc vyi
        sta hyi
        ; floor
        lda vyi
        bmi _ceil
        lda hyi
        cmp #YMAX
        bcc _r
        lda #YMAX
        sta hyi
        lda #0
        sta hyf
        lda vyi
        sta tmp4
        lda #0
        sta vyf
        sta vyi
        lda #1
        sta ground
        rts
_ceil   lda hyi
        cmp #YMIN
        bcs _r
        lda #YMIN
        sta hyi
        lda #0
        sta hyf
        sta vyf
        sta vyi
        lda #2
        sta ground
_r      rts

; ---------------------------------------------------- coins and zappers
player_collide
        lda pmode
        cmp #PM_DEAD
        bcc +
        rts
+       ; ---- coins: cells under the hero
        lda #HEROX+4
        sec
        sbc xs
        lsr
        lsr
        lsr
        sta tmp4                ; first column
        lda hyi
        clc
        adc #2
        lsr
        lsr
        lsr
        sta tmp5                ; first row
        lda hyi
        clc
        adc #18
        lsr
        lsr
        lsr
        sta tmp6                ; last row
_crow   ldx tmp5
        jsr row_ptrs
        ldy tmp4
        lda #3
        sta tmp7
-       lda (scrp),y
        cmp #CH_COIN
        bne +
        jsr take_coin
        jsr row_ptrs
+       iny
        dec tmp7
        bne -
        inc tmp5
        lda tmp5
        cmp tmp6
        bcc _crow
        beq _crow
        ; ---- zappers: pixel test at a few points of the hero
        lda invuln
        ora cheat
        bne _r
        ldx #NHP-1
_pt     stx tmp7
        lda #HEROX
        clc
        adc hp_x,x
        sec
        sbc xs
        sta tmp4                ; x in screen pixels
        lda hyi
        clc
        adc hp_y,x
        sta tmp5                ; y
        lsr
        lsr
        lsr
        tax
        jsr row_ptrs
        lda tmp4
        lsr
        lsr
        lsr
        tay
        lda (scrp),y
        sec
        sbc #CH_ZH
        cmp #5
        bcs _nx
        adc #CH_ZH
        ; charset byte: CHARGAME + char * 8 + line
        sta ptr2
        lda #0
        asl ptr2
        rol
        asl ptr2
        rol
        asl ptr2
        rol
        adc #>CHARGAME
        sta ptr2+1
        lda tmp5
        and #7
        tay
        lda tmp4
        and #7
        lsr
        tax
        lda (ptr2),y
        and pairmask,x
        beq _nx
        jmp player_hit
_nx     ldx tmp7
        dex
        bpl _pt
_r      rts

NHP = 6
hp_x    .byte 12, 12, 6, 18, 12, 9
hp_y    .byte 3, 17, 10, 10, 10, 14

; Y = column, tmp5 = row of a coin
take_coin
        sty tmp3
        ldx tmp5
        jsr clear_cell
        sed
        lda coins
        clc
        adc #1
        sta coins
        lda coins+1
        adc #0
        sta coins+1
        cld
        inc hudchg
        lda #SFX_COIN
        jsr sfx_start
        ldx tmp5
        ldy tmp3
        rts

; ---------------------------------------------------- hit by a zapper, missile or laser
player_hit
        lda pmode
        cmp #PM_COPTER
        beq _lose
        cmp #PM_GRAV
        beq _lose
        cmp #PM_JET
        bne _r
        ; crash
        lda #PM_DEAD
        sta pmode
        lda #<$fe40
        sta vyf
        lda #>$fe40
        sta vyi
        lda #0
        sta thrust
        sta ground
        lda #60
        sta dtimer
        lda #SFX_ZAP
        jmp sfx_start
_lose   ; the vehicle is gone, continue with the jetpack
        lda #PM_JET
        sta pmode
        lda #INVTIME
        sta invuln
        lda #0
        sta gdir
        lda #SFX_BOOM
        jsr sfx_start
        jmp expl_start
_r      rts

; ---------------------------------------------------- vehicle from a gadget box
vehicle_start
        jsr rnd
        and #1
        clc
        adc #PM_COPTER
        sta pmode
        lda #0
        sta gdir
        sta vyf
        sta vyi
        lda #SFX_GADGET
        jmp sfx_start

; ---------------------------------------------------- hero sprites (0 overlay, 1 body, 2 flame/rotor/glow)
hero_sprites
        lda herox
        clc
        adc #24
        sta sx
        sta sx+1
        sta sx+2
        lda #0
        adc #0
        beq +
        lda #%00000111
+       sta tmp0                ; x high bits
        lda sxh
        and #%11111000
        ora tmp0
        sta sxh
        lda hyi
        clc
        adc #SPRY0
        sta sy
        sta sy+1
        ; running frame from the distance
        lda moved
        clc
        adc panim
        sta panim
        ; frame
        lda pmode
        cmp #PM_DEAD
        bne _alive
        ldx #5
        lda ground
        beq +
        ldx #6
+       jmp _set
_alive  ldx #4                  ; flying
        lda ground
        beq _set
        lda panim
        lsr
        lsr
        lsr
        and #3
        tax
_set    txa
        asl
        ldy pmode
        cpy #PM_GRAV
        bne +
        ldy gdir
        beq +
        clc
        adc #SPR_HEROU0-SPR_HERO0
+       clc
        adc #SPR_HERO0
        sta sptr
        adc #1
        sta sptr+1
        lda #0
        sta sc
        lda #14
        sta sc+1
        ; ---- sprite 2
        lda pmode
        cmp #PM_COPTER
        beq _rotor
        cmp #PM_GRAV
        beq _glow
        lda thrust
        beq _off2
        lda frame
        lsr
        and #3
        tax
        lda flame_seq,x
        sta sptr+2
        lda #7
        sta sc+2
        lda sy
        clc
        adc #15
        sta sy+2
        jmp _on2
_rotor  lda frame
        lsr
        and #1
        clc
        adc #SPR_ROTOR0
        sta sptr+2
        lda #12
        sta sc+2
        lda sy
        sec
        sbc #17
        sta sy+2
        jmp _on2
_glow   lda frame
        lsr
        lsr
        and #1
        ldx gdir
        bne +
        clc
        adc #SPR_GLOW0
        sta sptr+2
        lda sy
        clc
        adc #19
        sta sy+2
        jmp ++
+       clc
        adc #SPR_GLOWU0
        sta sptr+2
        lda sy
        sec
        sbc #19
        sta sy+2
+       lda #3
        sta sc+2
_on2    lda sen
        ora #%00000111
        sta sen
        jmp _blink
_off2   lda sen
        and #%11111011
        ora #%00000011
        sta sen
_blink  lda invuln
        beq +
        lda frame
        and #4
        beq +
        lda sen
        and #%11111000
        sta sen
+       lda herox
        cmp #250
        bcc +
        lda sen
        and #%11111000
        sta sen
+       rts
flame_seq .byte SPR_FLAME0, SPR_FLAME1, SPR_FLAME2, SPR_FLAME1
