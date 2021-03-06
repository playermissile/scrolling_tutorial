; Written in 2019 by Rob McMullen, https://playermissile.com/scrolling_tutorial/
; Copyright and related rights waived via CC0: https://creativecommons.org/publicdomain/zero/1.0/
; common routines, no origin here so they can be included wherever needed
; the screen memory is fixed at $8000, however.


;
; Create display list of 40x24 mode 4 lines
;
init_screen_parallax
        ; load display list & fill with test data
        lda #<dlist_parallax_mode4
        sta SDLSTL
        lda #>dlist_parallax_mode4
        sta SDLSTL+1
        jsr fillscreen_parallax
        lda #$80
        ldx #24
        jsr label_pages
        rts

;
; fill 24 pages with test pattern
;
fillscreen_parallax
        ldy #0
?loop   lda #$41
        sta $8000,y
        sta $8100,y
        sta $8200,y
        sta $8300,y
        sta $8400,y
        sta $8500,y
        sta $8600,y
        sta $8700,y
        sta $8800,y
        sta $8900,y

        lda #$a2
        sta $8a00,y
        sta $8b00,y

        lda #$43
        sta $8c00,y
        sta $8d00,y
        sta $8e00,y
        sta $8f00,y

        lda #$a4
        sta $9000,y
        sta $9100,y
        sta $9200,y
        sta $9300,y
        sta $9400,y
        sta $9500,y
        sta $9600,y
        sta $9700,y
        iny
        bne ?loop
        rts


;
; fill two groups of lines, each group 40 bytes each of A-Z
;
fillscreen_coarse_test_pattern
        ldy #0
?loop   lda #$41
        sta $8000,y
        adc #1
        sta $8028,y
        adc #1
        sta $8050,y
        adc #1
        sta $8078,y
        adc #1
        sta $80a0,y
        adc #1
        sta $80c8,y
        adc #1
        sta $80f0,y
        adc #1
        sta $8118,y
        adc #1
        sta $8140,y
        adc #1
        sta $8168,y
        adc #1
        sta $8190,y
        adc #1
        sta $81b8,y
        adc #1
        sta $81e0,y
        adc #1
        sta $8208,y
        adc #1
        sta $8230,y
        adc #1
        sta $8258,y
        adc #1
        sta $8280,y
        adc #1
        sta $82a8,y
        adc #1
        sta $82d0,y
        adc #1
        sta $82f8,y
        adc #1
        sta $8320,y
        adc #1
        sta $8348,y
        adc #1
        sta $8370,y
        adc #1
        sta $8398,y
        adc #1
        sta $83c0,y
        adc #1
        sta $83e8,y
        adc #7
        sta $8410,y
        adc #1
        sta $8438,y
        adc #1
        sta $8460,y
        adc #1
        sta $8488,y
        adc #1
        sta $84b0,y
        adc #1
        sta $84d8,y
        adc #1
        sta $8500,y
        adc #1
        sta $8528,y
        adc #1
        sta $8550,y
        adc #1
        sta $8578,y
        adc #1
        sta $85a0,y
        adc #1
        sta $85c8,y
        adc #1
        sta $85f0,y
        adc #1
        sta $8618,y
        adc #1
        sta $8640,y
        adc #1
        sta $8668,y
        adc #1
        sta $8690,y
        adc #1
        sta $86b8,y
        adc #1
        sta $86e0,y
        adc #1
        sta $8708,y
        adc #1
        sta $8730,y
        adc #1
        sta $8758,y
        adc #1
        sta $8780,y
        adc #1
        sta $87a8,y
        adc #1
        sta $87d0,y
        adc #1
        sta $87f8,y
        iny
        cpy #40
        bcs ?done
        jmp ?loop
?done   rts


;
; fill 56 pages with test pattern, A-Z vertically and checkerboard
; colors every 16 chars horizontally so scrolling movement will be
; visible.
;
fillscreen_test_pattern
        ldy #0
?loop   tya
        and #$10        ; every 16 bytes, change color
        asl a
        clc
        adc #$41
        sta $8000,y
        adc #1
        sta $8100,y
        adc #1
        sta $8200,y
        adc #1
        sta $8300,y
        adc #1
        sta $8400,y
        adc #1
        sta $8500,y
        adc #1
        sta $8600,y
        adc #1
        sta $8700,y
        adc #1
        sta $8800,y
        adc #1
        sta $8900,y
        adc #1
        sta $8a00,y
        adc #1
        sta $8b00,y
        adc #1
        sta $8c00,y
        adc #1
        sta $8d00,y
        adc #1
        sta $8e00,y
        adc #1
        sta $8f00,y
        adc #1
        sta $9000,y
        adc #1
        sta $9100,y
        adc #1
        sta $9200,y
        adc #1
        sta $9300,y
        adc #1
        sta $9400,y
        adc #1
        sta $9500,y
        adc #1
        sta $9600,y
        adc #1
        sta $9700,y
        adc #1
        sta $9800,y
        adc #1
        sta $9900,y
        adc #7
        sta $9a00,y
        adc #1
        sta $9b00,y
        adc #1
        sta $9c00,y
        adc #1
        sta $9d00,y
        adc #1
        sta $9e00,y
        adc #1
        sta $9f00,y
        adc #1
        sta $a000,y
        adc #1
        sta $a100,y
        adc #1
        sta $a200,y
        adc #1
        sta $a300,y
        adc #1
        sta $a400,y
        adc #1
        sta $a500,y
        adc #1
        sta $a600,y
        adc #1
        sta $a700,y
        adc #1
        sta $a800,y
        adc #1
        sta $a900,y
        adc #1
        sta $aa00,y
        adc #1
        sta $ab00,y
        adc #1
        sta $ac00,y
        adc #1
        sta $ad00,y
        adc #1
        sta $ae00,y
        adc #1
        sta $af00,y
        adc #1
        sta $b000,y
        adc #1
        sta $b100,y
        adc #1
        sta $b200,y
        adc #1
        sta $b300,y
        adc #1
        sta $b400,y
        adc #1
        sta $b500,y
        adc #1
        sta $b600,y
        adc #1
        sta $b700,y
        iny
        beq ?done
        jmp ?loop
?done   rts

;
; label pages with hex string addresses every 16 bytes
; args: start page number in A
;       number of pages in X
;
label_pages
        sta ?smc1+2
?outer  sta ?smc2+2
        sta ?smc3+2
        sta ?smc4+2
        ldy #0
?inner  lda ?smc1+2      ; high byte
        pha
        and #$f0        ; high nibble
        lsr a
        lsr a
        lsr a
        lsr a
        jsr get_digit
?smc1   sta $ff00,y
        pla             ; low nibble
        and #$0f
        jsr get_digit
?smc2   sta $ff01,y
        tya             ; low byte
        and #$f0        ; high nibble
        lsr a
        lsr a
        lsr a
        lsr a
        jsr get_digit
?smc3   sta $ff02,y
        tya
        and #$0f
        jsr get_digit
?smc4   sta $ff03,y

        tya
        clc
        adc #$10
        tay
        bne ?inner
        
        dex
        beq ?exit
        inc ?smc1+2
        lda ?smc1+2
        bne ?outer
?exit   rts

get_digit
        cmp #10
        bcc ?digit
        adc #6
?digit  adc #$10
        rts

;
; fill 32 pages with test pattern
;
fillscreen_scroll
        ldy #0
?loop   tya
        sta $8000,y
        sta $8100,y
        sta $8200,y
        sta $8300,y
        sta $8400,y
        sta $8500,y
        sta $8600,y
        sta $8700,y
        sta $8800,y
        sta $8900,y
        sta $8a00,y
        sta $8b00,y
        sta $8c00,y
        sta $8d00,y
        sta $8e00,y
        sta $8f00,y
        sta $9000,y
        sta $9100,y
        sta $9200,y
        sta $9300,y
        sta $9400,y
        sta $9500,y
        sta $9600,y
        sta $9700,y
        sta $9800,y
        sta $9900,y
        sta $9a00,y
        sta $9b00,y
        sta $9c00,y
        sta $9d00,y
        sta $9e00,y
        sta $9f00,y
        iny
        bne ?loop
        rts

;
; display lists
;

        ;             0123456789012345678901234567890123456789
footer_text
        .sbyte +$80, " ANTIC MODE 2, NOT SCROLLED, FIRST LINE "
footer_text_line_2
        .sbyte       " ANTIC MODE 2, NOT SCROLLED, SECOND LINE"


; NOTE: start display lists on a page boundary to avoid the possibility
; that it might be split over a 4K boundary

        *= (* & $ff00) + 256 ; next page boundary

; one page per line, used for coarse scrolling. Start visible region
; in middle of each page so it can scroll either right or left immediately
; without having to check for a border
dlist_lms_mode4
        .byte $70,$70,$70
        .byte $44,$70,$80       ; first line of scrolling region
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
        .byte $44,$70,$95       ; last line in scrolling region
        .byte $42,<footer_text, >footer_text ; 2 Mode 2 lines + LMS + address
        .byte $2
        .byte $41,<dlist_lms_mode4,>dlist_lms_mode4 ; JVB ends display list


; one page per line, used for coarse scrolling. Start visible region
; in middle of each page so it can scroll either right or left immediately
; without having to check for a border
dlist_hscroll_mode4
        .byte $70,$70,$70
        .byte $54,$70,$80       ; first line of scrolling region
        .byte $54,$70,$81
        .byte $54,$70,$82
        .byte $54,$70,$83
        .byte $54,$70,$84
        .byte $54,$70,$85
        .byte $54,$70,$86
        .byte $54,$70,$87
        .byte $54,$70,$88
        .byte $54,$70,$89
        .byte $54,$70,$8a
        .byte $54,$70,$8b
        .byte $54,$70,$8c
        .byte $54,$70,$8d
        .byte $54,$70,$8e
        .byte $54,$70,$8f
        .byte $54,$70,$90
        .byte $54,$70,$91
        .byte $54,$70,$92
        .byte $54,$70,$93
        .byte $54,$70,$94
dlist_hscroll_mode4_last_scrolling_line
        .byte $54,$70,$95       ; last line in scrolling region
        .byte $42,<footer_text, >footer_text ; 2 Mode 2 lines + LMS + address
        .byte $2
        .byte $41,<dlist_hscroll_mode4,>dlist_hscroll_mode4 ; JVB ends display list


        *= (* & $ff00) + 256 ; next page boundary

; one page per line, used for full 2d fine scrolling. Start visible region
; in middle of each page so it can scroll either right or left immediately
; without having to check for a border
dlist_2d_mode4
        .byte $70,$70,$70
        .byte $74,$70,$80       ; first line of scrolling region, VSCROLL + HSCROLL
        .byte $74,$70,$81
        .byte $74,$70,$82
        .byte $74,$70,$83
        .byte $74,$70,$84
        .byte $74,$70,$85
        .byte $74,$70,$86
        .byte $74,$70,$87
        .byte $74,$70,$88
        .byte $74,$70,$89
        .byte $74,$70,$8a
        .byte $74,$70,$8b
        .byte $74,$70,$8c
        .byte $74,$70,$8d
        .byte $74,$70,$8e
        .byte $74,$70,$8f
        .byte $74,$70,$90
        .byte $74,$70,$91
        .byte $74,$70,$92
        .byte $74,$70,$93
        .byte $74,$70,$94
dlist_2d_mode4_last_scrolling_line
        .byte $54,$70,$95       ; last line in scrolling region, HSCROLL only
dlist_2d_mode4_status_line1
        .byte $42,<joystick_text, >joystick_text ; Mode 2 + LMS + address
dlist_2d_mode4_status_line2
        .byte $42,<normal_text, >normal_text ; Mode 2 + LMS + address
dlist_2d_mode4_status_line3
        .byte $42,<x1_text, >x1_text ; Mode 2 + LMS + address
        .byte $41,<dlist_2d_mode4,>dlist_2d_mode4 ; JVB ends display list

        ;             0123456789012345678901234567890123456789
joystick_text
        .sbyte +$80, " SCROLL WITH JOYSTICK HSCROL=0 VSCROL=0 "
normal_text
        .sbyte       " PRESS OPTION FOR WIDE PLAYFIELD        "
wide_text
        .sbyte       " PRESS OPTION FOR NORMAL PLAYFIELD      "
x1_text
        .sbyte       " PRESS SELECT FOR VSCROLL SPEED X 2     "
x2_text
        .sbyte       " PRESS SELECT FOR VSCROLL SPEED X 1     "

        *= (* & $ff00) + 256 ; next page boundary

; one page per line, used for horizontal scrolling. Start visible region
; in middle of each page so it can scroll either right or left immediately
; without having to check for a border
dlist_parallax_mode4
        .byte $70,$70,$70       ; region A: no scrolling
        .byte $54,$70,$80
        .byte $54,$70,$81
        .byte $54,$70,$82
        .byte $54,$70,$83
        .byte $54,$70,$84
        .byte $54,$70,$85
        .byte $54,$70,$86
        .byte $54,$70,$87
        .byte $54,$70,$88
        .byte $d4,$70,$89
dlist_parallax_region_b
        .byte $54,$70,$8a       ; region B: 1/4 as much scrolling as D
        .byte $d4,$70,$8b
dlist_parallax_region_c
        .byte $54,$70,$8c       ; region C: 1/2 as much scrolling as D
        .byte $54,$70,$8d
        .byte $54,$70,$8e
        .byte $d4,$70,$8f
dlist_parallax_region_d
        .byte $54,$70,$90       ; region D: all the scrolling
        .byte $54,$70,$91
        .byte $54,$70,$92
        .byte $54,$70,$93
        .byte $54,$70,$94
        .byte $54,$70,$95
        .byte $54,$70,$96
        .byte $54,$70,$97
        .byte $41,<dlist_parallax_mode4,>dlist_parallax_mode4

dlist_parallax_mode4_row1_offset
        .byte 12*3+1,14*3+1,18*3+1
dlist_parallax_mode4_row2_offset
        .byte 13*3+1,15*3+1,19*3+1
dlist_parallax_mode4_row3_offset
        .byte 0,16*3+1,20*3+1
dlist_parallax_mode4_row4_offset
        .byte 0,17*3+1,21*3+1
dlist_parallax_mode4_row5_offset
        .byte 0,0,22*3+1
dlist_parallax_mode4_row6_offset
        .byte 0,0,23*3+1
dlist_parallax_mode4_row7_offset
        .byte 0,0,24*3+1
dlist_parallax_mode4_row8_offset
        .byte 0,0,25*3+1
