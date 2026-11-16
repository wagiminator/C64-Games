; =====================================================================
;  SID music player + sound effects (sfx use voice 3)
; =====================================================================
TUNE_TITLE  = 0
TUNE_STAGE1 = 1
TUNE_STAGE2 = 2
TUNE_BOSS   = 3
TUNE_CLEAR  = 4
TUNE_OVER   = 5
TUNE_END    = 6
TUNE_SHOP   = 7

        .virtual $0300
mu_on   .byte ?
mu_speed .byte ?
mu_tick .byte ?
mv_tpl  .fill 3
mv_tph  .fill 3
mv_tsl  .fill 3
mv_tsh  .fill 3
mv_ppl  .fill 3
mv_pph  .fill 3
mv_cnt  .fill 3
mv_dur  .fill 3
mv_ins  .fill 3
mv_note .fill 3
mv_wt   .fill 3
mv_wave .fill 3
mv_gate .fill 3
mv_pwl  .fill 3
mv_pwh  .fill 3
mv_pwd  .fill 3
mv_vib  .fill 3
mv_new  .fill 3
mv_stop .fill 3
mv_fl   .fill 3
mv_fh   .fill 3
sfx_act .byte ?
sfx_new .byte ?
sfx_pr  .byte ?
sfx_pl  .byte ?
sfx_ph  .byte ?
mu_tmp  .byte ?
mu_tmp2 .byte ?
        .endv

sid_init
        ldx #$18
        lda #0
-       sta $d400,x
        dex
        bpl -
        lda #$0f
        sta $d418
        lda #0
        sta mu_on
        sta sfx_act
        rts

; A = tune number
music_start
        sei
        tay
        lda #0
        sta mu_on
        lda mus_song_speed,y
        sta mu_speed
        lda #0
        sta mu_tick
        lda mus_trk0_lo,y
        sta mv_tpl
        sta mv_tsl
        lda mus_trk0_hi,y
        sta mv_tph
        sta mv_tsh
        lda mus_trk1_lo,y
        sta mv_tpl+1
        sta mv_tsl+1
        lda mus_trk1_hi,y
        sta mv_tph+1
        sta mv_tsh+1
        lda mus_trk2_lo,y
        sta mv_tpl+2
        sta mv_tsl+2
        lda mus_trk2_hi,y
        sta mv_tph+2
        sta mv_tsh+2
        ldx #2
-       lda #<mu_endpat
        sta mv_ppl,x
        lda #>mu_endpat
        sta mv_pph,x
        lda #1
        sta mv_cnt,x
        sta mv_dur,x
        lda #0
        sta mv_ins,x
        sta mv_stop,x
        sta mv_new,x
        sta mv_gate,x
        sta mv_wave,x
        sta mv_wt,x
        dex
        bpl -
        lda #0
        sta $d404
        sta $d40b
        ldx sfx_act
        bne +
        sta $d412
+       lda #1
        sta mu_on
        cli
        rts
mu_endpat .byte $ff

music_stop
        lda #0
        sta mu_on
        sta $d404
        sta $d40b
        sta $d412
        rts

music_play
        lda mu_on
        bne +
        rts
+       dec mu_tick
        bpl _frames
        lda mu_speed
        sec
        sbc #1
        sta mu_tick
        ldx #2
-       lda mv_stop,x
        bne +
        jsr tick_voice
+       dex
        bpl -
_frames ldx #2
-       lda mv_stop,x
        bne +
        jsr frame_voice
+       dex
        bpl -
        rts

tick_voice
        dec mv_cnt,x
        beq +
        rts
+       lda mv_ppl,x
        sta mptr
        lda mv_pph,x
        sta mptr+1
        ldy #0
_rd     lda (mptr),y
        iny
        cmp #$ff
        bne _notend
        ; ---- next pattern from track
_trk    lda mv_tpl,x
        sta iptr
        lda mv_tph,x
        sta iptr+1
        ldy #0
        lda (iptr),y
        cmp #$fe
        bne +
        iny
        lda (iptr),y
        clc
        adc mv_tsl,x
        sta mv_tpl,x
        lda mv_tsh,x
        adc #0
        sta mv_tph,x
        jmp _trk
+       cmp #$ff
        bne +
        lda #1
        sta mv_stop,x
        lda #0
        sta mv_gate,x
        ldy sidofs,x
        lda mv_wave,x
        and #$fe
        cpx #2
        bne _w
        ldy sfx_act
        bne _nw
        ldy sidofs,x
_w      sta $d404,y
_nw     rts
+       tay
        lda mus_pat_lo,y
        sta mptr
        lda mus_pat_hi,y
        sta mptr+1
        inc mv_tpl,x
        bne +
        inc mv_tph,x
+       ldy #0
        jmp _rd
_notend cmp #$c0
        bcc +
        and #$3f
        sta mv_ins,x
        jmp _rd
+       cmp #$80
        bcc +
        and #$3f
        clc
        adc #1
        sta mv_dur,x
        jmp _rd
+       cmp #$60
        bne +
        lda #0
        sta mv_gate,x
        jmp _set
+       cmp #$61
        beq _set
        ; ---- new note
        sta mv_note,x
        sty mu_tmp
        ldy mv_ins,x
        lda ins_wt,y
        sta mv_wt,x
        lda ins_pwl,y
        sta mv_pwl,x
        lda ins_pwh,y
        sta mv_pwh,x
        lda #0
        sta mv_vib,x
        sta mv_pwd,x
        lda #1
        sta mv_new,x
        sta mv_gate,x
        ldy mu_tmp
_set    lda mv_dur,x
        sta mv_cnt,x
        tya
        clc
        adc mptr
        sta mv_ppl,x
        lda mptr+1
        adc #0
        sta mv_pph,x
        rts

sidofs  .byte 0,7,14

frame_voice
        ldy sidofs,x
        lda mv_new,x
        beq _cont
        lda #0
        sta mv_new,x
        cpx #2
        bne +
        lda sfx_act
        bne _cont
+       lda #$08
        sta $d404,y
        sty mu_tmp
        ldy mv_ins,x
        lda ins_ad,y
        pha
        lda ins_sr,y
        ldy mu_tmp
        sta $d406,y
        pla
        sta $d405,y
_cont   ; ---- wavetable
        lda mv_wt,x
        tay
        lda wt_wave,y
        cmp #$ff
        bne +
        lda wt_note,y
        sta mv_wt,x
        tay
        lda wt_wave,y
+       sta mv_wave,x
        lda wt_note,y
        bmi _abs
        cmp #$40
        bcc +
        ora #$80
+       clc
        adc mv_note,x
        jmp _nt
_abs    and #$7f
_nt     cmp #96
        bcc +
        lda #95
+       tay
        lda freq_lo,y
        sta mv_fl,x
        lda freq_hi,y
        sta mv_fh,x
        ; advance wavetable (stop at jump markers handled next frame)
        inc mv_wt,x
        ; ---- vibrato
        ldy mv_ins,x
        lda ins_vib,y
        beq _novib
        sta mu_tmp
        inc mv_vib,x
        lda mv_vib,x
        cmp ins_vdel,y
        bcc _novib
        ; amount = fh * depth / 4
        lda #0
        ldy mu_tmp
-       clc
        adc mv_fh,x
        dey
        bne -
        lsr
        lsr
        sta mu_tmp
        lda mv_vib,x
        and #7
        tay
        lda vibtab,y
        beq _novib
        bmi _vneg
        tay
-       lda mv_fl,x
        clc
        adc mu_tmp
        sta mv_fl,x
        bcc +
        inc mv_fh,x
+       dey
        bne -
        jmp _novib
_vneg   eor #$ff
        clc
        adc #1
        tay
-       lda mv_fl,x
        sec
        sbc mu_tmp
        sta mv_fl,x
        bcs +
        dec mv_fh,x
+       dey
        bne -
_novib  ; ---- pulse modulation
        ldy mv_ins,x
        lda ins_pws,y
        beq _nopw
        sta mu_tmp
        lda mv_pwd,x
        bne _pdn
        lda mv_pwl,x
        clc
        adc mu_tmp
        sta mv_pwl,x
        lda mv_pwh,x
        adc #0
        sta mv_pwh,x
        cmp #$0e
        bcc _nopw
        lda #1
        sta mv_pwd,x
        bne _nopw
_pdn    lda mv_pwl,x
        sec
        sbc mu_tmp
        sta mv_pwl,x
        lda mv_pwh,x
        sbc #0
        sta mv_pwh,x
        cmp #$02
        bcs _nopw
        lda #0
        sta mv_pwd,x
_nopw   ; ---- write SID
        cpx #2
        bne +
        lda sfx_act
        beq _v3
        rts
_v3     ldy mv_ins,x
        lda ins_ad,y
        sta $d413
        lda ins_sr,y
        sta $d414
+       ldy sidofs,x
        lda mv_fl,x
        sta $d400,y
        lda mv_fh,x
        sta $d401,y
        lda mv_pwl,x
        sta $d402,y
        lda mv_pwh,x
        sta $d403,y
        lda mv_wave,x
        and #$fe
        sta mu_tmp
        lda mv_gate,x
        and mv_wave,x
        and #1
        ora mu_tmp
        sta $d404,y
        rts

vibtab  .byte 0,1,2,1,0,$ff,$fe,$ff

; ---------------------------------------------------- sound effects
; A = sfx number (preserves X,Y)
sfx_start
        sta mu_tmp2
        txa
        pha
        ldx mu_tmp2
        lda sfx_act
        beq +
        lda sfx_prio,x
        cmp sfx_pr
        bcc _r
+       php
        sei
        lda sfx_prio,x
        sta sfx_pr
        lda sfx_lo,x
        sta sfx_pl
        lda sfx_hi,x
        sta sfx_ph
        lda #1
        sta sfx_new
        sta sfx_act
        plp
_r      pla
        tax
        rts

sfx_play
        lda sfx_act
        bne +
        rts
+       lda sfx_pl
        sta iptr
        lda sfx_ph
        sta iptr+1
        ldy #0
        lda sfx_new
        beq _frm
        lda #0
        sta sfx_new
        lda #$08
        sta $d412
        lda (iptr),y
        sta $d413
        iny
        lda (iptr),y
        sta $d414
        iny
        lda (iptr),y
        sta $d411
        lda #0
        sta $d410
        lda iptr
        clc
        adc #3
        sta iptr
        bcc +
        inc iptr+1
+       ldy #0
_frm    lda (iptr),y
        bne +
        sta $d412
        sta sfx_act
        rts
+       pha
        iny
        lda (iptr),y
        sta $d40f
        lda #0
        sta $d40e
        pla
        sta $d412
        lda iptr
        clc
        adc #2
        sta sfx_pl
        lda iptr+1
        adc #0
        sta sfx_ph
        rts
