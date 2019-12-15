        *= $3000

.include "hardware.s"

delay = 5

horz_scroll = $91       ; variable used to store HSCROL value
horz_scroll_max = 4     ; ANTIC mode 4 has 4 color clocks

init
        jsr init_font

        lda #<dlist_hscroll_mode4
        sta SDLSTL
        lda #>dlist_hscroll_mode4
        sta SDLSTL+1

        ; set DLI bit on last scrolling line before status line
        lda dlist_hscroll_mode4_last_scrolling_line
        ora #$80
        sta dlist_hscroll_mode4_last_scrolling_line

        ; load display list interrupt address
        lda #<dli
        sta VDSLST
        lda #>dli
        sta VDSLST+1

        ; activate display list interrupt
        lda #NMIEN_VBI | NMIEN_DLI
        sta NMIEN

        jsr fillscreen_test_pattern
        lda #$80
        ldx #22
        jsr label_pages

        lda #0          ; initialize horizontal scrolling value
        sta horz_scroll
        sta HSCROL      ; initialize hardware register

        lda #$23        ; enable wide playfield
        sta SDMCTL      ;   by saving to shadow register


loop    ldx #delay      ; number of VBLANKs to wait
?start  lda RTCLOK+2    ; check fastest moving RTCLOCK byte
?wait   cmp RTCLOK+2    ; VBLANK will update this
        beq ?wait       ; delay until VBLANK changes it
        dex             ; delay for a number of VBLANKs
        bpl ?start

        ; enough time has passed, scroll one color clock
        jsr fine_scroll_right

        jmp loop

; scroll one color clock right and check if at HSCROL limit
fine_scroll_right
        dec horz_scroll
        lda horz_scroll
        bpl ?done       ; if non-negative, still in the middle of the character
        jsr coarse_scroll_right ; wrapped to $ff, do a coarse scroll...
        lda #horz_scroll_max-1  ;  ...followed by reseting the HSCROL register
        sta horz_scroll
?done   sta HSCROL      ; store vertical scroll value in hardware register
        rts

; move viewport one byte to the right by pointing each display list start
; address to one byte higher in memory
coarse_scroll_right
        ldy #22         ; 22 lines to modify
        ldx #4          ; 4th byte after start of display list is low byte of address
?loop   inc dlist_hscroll_mode4,x
        inx             ; skip to next low byte which is 3 bytes away
        inx
        inx
        dey
        bne ?loop
        rts

dli     pha             ; only using A register, so save old value to the stack
        lda #$22        ; normal playfield width
        sta WSYNC       ; any value saved to WSYNC will trigger the pause
        sta DMACTL      ; store it in the hardware register
        pla             ; restore the A register
        rti             ; always end DLI with RTI!


.include "util_font.s"
.include "util_scroll.s"
.include "font_data_antic4.s"

; tell DOS where to run the program when loaded
        * = $2e0
        .word init
