        *= $3000

.include "hardware.s"

horz_dir = $80  ; 1 = right, $ff = left
vert_dir = $81  ; 1 = down, $ff = up

delay = 5

horz_min = 0    ; horizontal lower bound
horz_max = 255-44 ; horizontal upper bound is page width, less some extra to prevent unintentional wraparound
vert_min = $80  ; page $80 is first line in memory region
vert_max = $80+52-22 ; 52 lines high and 22 visible at a time

init
        jsr init_font

        lda #<dlist_lms_mode4
        sta SDLSTL
        lda #>dlist_lms_mode4
        sta SDLSTL+1
        jsr fillscreen_test_pattern
        lda #$80
        ldx #56
        jsr label_pages

        lda #$ff
        sta horz_dir
        lda #1
        sta vert_dir

; representative values for vertical and horizontal scrolling: the pointers
; to the display list LMS addresses themselves
horz_ref = dlist_lms_mode4 + 4
vert_ref = dlist_lms_mode4 + 5

loop
        ldx #delay      ; number of VBLANKs to wait
?start  lda RTCLOK+2    ; check fastest moving RTCLOCK byte
?wait   cmp RTCLOK+2    ; VBLANK will update this
        beq ?wait       ; delay until VBLANK changes it
        dex             ; delay for a number of VBLANKs
        bpl ?start

        ; enough time has passed, scroll one line

        ; check if horizontal direction needs updating
        lda horz_ref    ; reference horizontal position
        cmp #horz_max   ; too far to the right?
        bcc ?ck_left
        lda #$ff        ; yep, start scrolling left
        sta horz_dir
        bne ?ck_down
?ck_left cmp #horz_min  ; at left boundary?
        bne ?ck_down
        lda #1          ; yep, start scrolling right
        sta horz_dir

        ; check if vertical direction needs updating
?ck_down lda vert_ref   ; reference vertical position
        cmp #vert_max   ; too far to down?
        bcc ?ck_up
        lda #$ff        ; yep, start scrolling up
        sta vert_dir
        bne ?scroll
?ck_up cmp #vert_min+1  ; at top boundary?
        bcs ?scroll
        lda #1          ; yep, start scrolling down
        sta vert_dir

        ; directions are ok, now perform the scroll
?scroll jsr coarse_scroll_horz
        jsr coarse_scroll_vert

        jmp loop

; move viewport one byte to the left/right by pointing each display list
; address to one lower/byte higher in memory (i.e. changing low byte)
coarse_scroll_horz
        ldy #22         ; 22 lines to modify
        ldx #0
        lda horz_dir
        bmi ?left
?right  inc horz_ref,x  ; low bytes of display list referenced at this addr
        inx             ; skip to next low byte which is 3 bytes away
        inx
        inx
        dey
        bne ?right
        rts

?left   dec horz_ref,x  ; low bytes of display list referenced at this addr
        inx             ; skip to next low byte which is 3 bytes away
        inx
        inx
        dey
        bne ?left
        rts


; move viewport one line up/down by pointing each display list address
; one *page* lower/byte higher in memory (i.e. changing high byte)
coarse_scroll_vert
        ldy #22         ; 22 lines to modify
        ldx #0
        lda vert_dir
        bmi ?up
?down   inc vert_ref,x  ; high bytes of display list referenced at this addr
        inx             ; skip to next high byte which is 3 bytes away
        inx
        inx
        dey
        bne ?down
        rts

?up     dec vert_ref,x  ; high bytes of display list referenced at this addr
        inx             ; skip to next high byte which is 3 bytes away
        inx
        inx
        dey
        bne ?up
        rts

.include "util_font.s"
.include "util_scroll.s"
.include "font_data_antic4.s"

; tell DOS where to run the program when loaded
        * = $2e0
        .word init
