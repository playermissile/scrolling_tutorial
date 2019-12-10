        *= $3000

.include "hardware.s"


init
        jsr init_font

        lda #<dlist_course_mode4
        sta SDLSTL
        lda #>dlist_course_mode4
        sta SDLSTL+1
        jsr fillscreen_course_test_pattern
;        lda #$80
;        ldx #24
;        jsr label_pages

forever
        jmp forever


; one page per line, used as comparison to horizontal scrolling. Start visible
; region just like scrolling version
dlist_course_mode4
        .byte $70,$70,$70       ; region A: no scrolling
        .byte $64,$00,$80
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $24
        .byte $42,<static_text, >static_text
        .byte $2
        .byte $41,<dlist_course_mode4,>dlist_course_mode4

        ;             0123456789012345678901234567890123456789
static_text
        .sbyte +$80, " ANTIC mode 2, not scrolled, first line "
        .sbyte       " ANTIC mode 2, not scrolled, second line"


.include "util_font.s"
.include "util_scroll.s"
.include "font_data_antic4.s"

; tell DOS where to run the program when loaded
        * = $2e0
        .word init
