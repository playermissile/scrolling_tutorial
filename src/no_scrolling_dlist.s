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
        ldx #24
        jsr label_pages

forever
        jmp forever


; one page per line, used as comparison to horizontal scrolling. Start visible
; region just like scrolling version
dlist_lms_mode4
        .byte $70,$70,$70       ; region A: no scrolling
        .byte $44,$70,$80
        .byte $44,$70,$81
        .byte $44,$70,$82
        .byte $44,$70,$83
        .byte $44,$70,$84
        .byte $44,$70,$85
        .byte $44,$70,$86
        .byte $44,$70,$87
        .byte $44,$70,$88
        .byte $44,$70,$89
        .byte $44,$70,$8a
        .byte $44,$70,$8b
        .byte $44,$70,$8c
        .byte $44,$70,$8d
        .byte $44,$70,$8e
        .byte $44,$70,$8f
        .byte $44,$70,$90
        .byte $44,$70,$91
        .byte $44,$70,$92
        .byte $44,$70,$93
        .byte $44,$70,$94
        .byte $44,$70,$95
        .byte $42,<static_text, >static_text
        .byte $2
        .byte $41,<dlist_lms_mode4,>dlist_lms_mode4

        ;       0123456789012345678901234567890123456789
static_text
        .sbyte " ANTIC mode 2, not scrolled, first line "
        .sbyte " ANTIC mode 2, not scrolled, second line"


.include "util_font.s"
.include "util_scroll.s"
.include "font_data_antic4.s"

; tell DOS where to run the program when loaded
        * = $2e0
        .word init
