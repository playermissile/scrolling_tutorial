        *= $3000

.include "hardware.s"

delay = 5

vert_scroll = $90       ; variable used to store VSCROL value
vert_scroll_max = 8     ; ANTIC mode 4 has 8 scan lines
horz_scroll = $91       ; variable used to store HSCROL value
horz_scroll_max = 4     ; ANTIC mode 4 has 4 color clocks

init
        jsr init_font

        lda #<dlist_2d_mode4
        sta SDLSTL
        lda #>dlist_2d_mode4
        sta SDLSTL+1

        ; set DLI bit on last scrolling line before status line
        lda dlist_2d_mode4_last_scrolling_line
        ora #$80
        sta dlist_2d_mode4_last_scrolling_line

        jsr fillscreen_test_pattern
        lda #$80
        ldx #$20        ; 32 pages; bytes $8000 - $9fff
        jsr label_pages

        lda #0          ; initialize horizontal scrolling value
        sta horz_scroll
        sta HSCROL      ; initialize hardware register

        lda #0          ; initialize vertical scrolling value
        sta vert_scroll
        sta VSCROL      ; initialize hardware register

loop    jmp loop


.include "util_font.s"
.include "util_scroll.s"
.include "font_data_antic4.s"

; tell DOS where to run the program when loaded
        * = $2e0
        .word init
