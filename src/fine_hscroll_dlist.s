; Written in 2019 by Rob McMullen, https://playermissile.com/scrolling_tutorial/
; Copyright and related rights waived via CC0: https://creativecommons.org/publicdomain/zero/1.0/
        *= $3000

.include "hardware.s"


init
        jsr init_font

        lda #<dlist_hscroll_mode4
        sta SDLSTL
        lda #>dlist_hscroll_mode4
        sta SDLSTL+1
        jsr fillscreen_test_pattern
        lda #$80
        ldx #22
        jsr label_pages

forever jmp forever



.include "util_font.s"
.include "util_scroll.s"
.include "font_data_antic4.s"

; tell DOS where to run the program when loaded
        * = $2e0
        .word init
