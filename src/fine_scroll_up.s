        *= $3000

.include "hardware.s"

delay = 5

vert_scroll = $90       ; variable used to store VSCROL value
vert_scroll_max = 8     ; ANTIC mode 4 has 8 scan lines

init
        jsr init_font

        lda #<dlist_course_mode4
        sta SDLSTL
        lda #>dlist_course_mode4
        sta SDLSTL+1
        jsr fillscreen_course_test_pattern

        lda #0          ; initialize vertical scrolling value
        sta vert_scroll
        sta VSCROL      ; initialize hardware register

loop    ldx #delay      ; number of VBLANKs to wait
?start  lda RTCLOK+2    ; check fastest moving RTCLOCK byte
?wait   cmp RTCLOK+2    ; VBLANK will update this
        beq ?wait       ; delay until VBLANK changes it
        dex             ; delay for a number of VBLANKs
        bpl ?start

        ; enough time has passed, scroll one scan line
        jsr fine_scroll_up

        jmp loop

; scroll one scan line up and check if at VSCROL limit
fine_scroll_up
        dec vert_scroll
        lda vert_scroll
        bpl ?done       ; if non-negative, still in the middle of the character
        jsr course_scroll_up   ; wrapped to $ff, do a course scroll...
        lda #vert_scroll_max-1 ;  ...followed by reseting the vscroll register
        sta vert_scroll
?done   sta VSCROL      ; store vertical scroll value in hardware register
        rts

; move viewport one line down by pointing display list start address
; to the address 40 bytes further in memory
course_scroll_up
        sec
        lda dlist_course_address
        sbc #40
        sta dlist_course_address
        lda dlist_course_address+1
        sbc #0
        sta dlist_course_address+1
        rts

; Simple display list to be used as course scrolling comparison
dlist_course_mode4
        .byte $70,$70,$70       ; 24 blank lines
        .byte $64               ; Mode 4 + VSCROLL + LMS
dlist_course_address
        .byte $10,$84           ; screen address, starting in middle of memory layout
        .byte $24,$24,$24,$24,$24,$24,$24,$24   ; 20 more Mode 4 + VSCROLL lines
        .byte $24,$24,$24,$24,$24,$24,$24,$24
        .byte $24,$24,$24,$24
        .byte 4                 ; and the final Mode 4 without VSCROLL
        .byte $42,<static_text, >static_text ; 2 Mode 2 lines + LMS + address
        .byte $2
        .byte $41,<dlist_course_mode4,>dlist_course_mode4 ; JVB ends display list

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
