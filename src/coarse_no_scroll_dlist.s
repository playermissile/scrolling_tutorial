; Written in 2019 by Rob McMullen, https://playermissile.com/scrolling_tutorial/
; Copyright and related rights waived via CC0: https://creativecommons.org/publicdomain/zero/1.0/
        *= $3000

.include "hardware.s"


init
        jsr init_font

        lda #<dlist_coarse_mode4
        sta SDLSTL
        lda #>dlist_coarse_mode4
        sta SDLSTL+1
        jsr fillscreen_coarse_test_pattern
;        lda #$80
;        ldx #24
;        jsr label_pages

forever
        jmp forever

; Simple display list to be used as coarse scrolling comparison
dlist_coarse_mode4
        .byte $70,$70,$70       ; 24 blank lines
        .byte $44,$00,$80       ; Mode 4 + LMS + address
        .byte 4,4,4,4,4,4,4,4   ; 21 more Mode 4 lines
        .byte 4,4,4,4,4,4,4,4
        .byte 4,4,4,4,4
        .byte $42,<static_text, >static_text ; 2 Mode 2 lines + LMS + address
        .byte $2
        .byte $41,<dlist_coarse_mode4,>dlist_coarse_mode4 ; JVB ends display list

        ;             0123456789012345678901234567890123456789
static_text
        .sbyte +$80, " ANTIC MODE 2, NOT SCROLLED, FIRST LINE "
        .sbyte       " ANTIC MODE 2, NOT SCROLLED, SECOND LINE"


.include "util_font.s"
.include "util_scroll.s"
.include "font_data_antic4.s"

; tell DOS where to run the program when loaded
        * = $2e0
        .word init
