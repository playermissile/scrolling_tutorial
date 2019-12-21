; Written in 2019 by Rob McMullen, https://playermissile.com/scrolling_tutorial/
; Copyright and related rights waived via CC0: https://creativecommons.org/publicdomain/zero/1.0/
        *= $3000

.include "hardware.s"


init
        jsr init_font

        lda #<dlist_lms_mode4
        sta SDLSTL
        lda #>dlist_lms_mode4
        sta SDLSTL+1
        jsr fillscreen_test_pattern
        lda #$80
        ldx #22
        jsr label_pages

loop
        ldx #15         ; number of VBLANKs to wait
?start  lda RTCLOK+2    ; check fastest moving RTCLOCK byte
?wait   cmp RTCLOK+2    ; VBLANK will update this
        beq ?wait       ; delay until VBLANK changes it
        dex             ; delay for a number of VBLANKs
        bpl ?start

        ; enough time has passed, scroll one line
        jsr coarse_scroll_right

        jmp loop

; move viewport one byte to the right by pointing each display list start
; address to one byte higher in memory
coarse_scroll_right
        ldy #22         ; 22 lines to modify
        ldx #4          ; 4th byte after start of display list is low byte of address
?loop   inc dlist_lms_mode4,x
        inx             ; skip to next low byte which is 3 bytes away
        inx
        inx
        dey
        bne ?loop
        rts


.include "util_font.s"
.include "util_scroll.s"
.include "font_data_antic4.s"

; tell DOS where to run the program when loaded
        * = $2e0
        .word init
