        *= $3000

.include "hardware.s"

delay = 5

vert_scroll = $90       ; variable used to store VSCROL value
vert_scroll_max = 8     ; ANTIC mode 4 has 8 scan lines
horz_scroll = $91       ; variable used to store HSCROL value
horz_scroll_max = 4     ; ANTIC mode 4 has 4 color clocks

pressed = $a0           ; user still pressing button?

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
        ldx #$20        ; 32 pages; bytes $8000 - $9fff
        jsr label_pages

        lda #0          ; initialize horizontal scrolling value
        sta horz_scroll
        sta HSCROL      ; initialize hardware register

        lda #0          ; initialize vertical scrolling value
        sta vert_scroll
        sta VSCROL      ; initialize hardware register

        lda #0
        sta pressed

        jsr to_wide

loop    ldx #delay      ; number of VBLANKs to wait
        ldy RTCLOK+2    ; check fastest moving RTCLOCK byte
?start  jsr toggle_wide
?wait   cpy RTCLOK+2    ; VBLANK will update this
        beq ?start       ; delay until VBLANK changes it
        dex             ; delay for a number of VBLANKs
        bpl ?start

        jsr check_joystick ; check joystick for scrolling direction

        jmp loop

toggle_wide
        lda CONSOL
        cmp #3          ; option by itself
        bne ?not_pressed
        lda pressed
        bne ?exit
        lda #1
        sta pressed
        lda SDMCTL
        cmp #$22
        beq to_wide
        jmp to_narrow
?not_pressed
        lda #0
        sta pressed
?exit   rts

to_wide lda #$23        ; enable wide playfield
        sta SDMCTL      ;   by saving to shadow register
        lda #<wide_text ; change status text
        sta dlist_2d_mode4_status_line2+1
        lda #>wide_text
        sta dlist_2d_mode4_status_line2+2
        rts

to_narrow lda #$22      ; enable narrow playfield
        sta SDMCTL      ;   by saving to shadow register
        lda #<normal_text ; change status text
        sta dlist_2d_mode4_status_line2+1
        lda #>normal_text
        sta dlist_2d_mode4_status_line2+2
        rts


; JOYSTICK DIRECTION

check_joystick
        rts


; HORIZONTAL SCROLLING

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
?loop   inc dlist_2d_mode4,x
        inx             ; skip to next low byte which is 3 bytes away
        inx
        inx
        dey
        bne ?loop
        rts

; scroll one color clock left and check if at HSCROL limit
fine_scroll_left
        inc horz_scroll
        lda horz_scroll
        cmp #horz_scroll_max ; check to see if we need to do a coarse scroll
        bcc ?done       ; nope, still in the middle of the character
        jsr coarse_scroll_left ; yep, do a coarse scroll...
        lda #0          ;  ...followed by reseting the HSCROL register
        sta horz_scroll
?done   sta HSCROL      ; store vertical scroll value in hardware register
        rts

; move viewport one byte to the left by pointing each display list start
; address to one byte lower in memory
coarse_scroll_left
        ldy #22         ; 22 lines to modify
        ldx #4          ; 4th byte after start of display list is low byte of address
?loop   dec dlist_2d_mode4,x
        inx             ; skip to next low byte which is 3 bytes away
        inx
        inx
        dey
        bne ?loop
        rts


; VERTICAL SCROLLING

; scroll one scan line up and check if at VSCROL limit
fine_scroll_up
        dec vert_scroll
        lda vert_scroll
        bpl ?done       ; if non-negative, still in the middle of the character
        jsr coarse_scroll_up   ; wrapped to $ff, do a coarse scroll...
        lda #vert_scroll_max-1 ;  ...followed by reseting the vscroll register
        sta vert_scroll
?done   sta VSCROL      ; store vertical scroll value in hardware register
        rts

; move viewport one line up by pointing display list start address
; to the address one page earlier in memory
coarse_scroll_up
        ldy #22         ; 22 lines to modify
        ldx #5          ; 5th byte after start of display list is high byte of address
?loop   dec dlist_2d_mode4,x
        inx             ; skip to next low byte which is 3 bytes away
        inx
        inx
        dey
        bne ?loop
        rts

; scroll one scan line down and check if at VSCROL limit
fine_scroll_down
        inc vert_scroll
        lda vert_scroll
        cmp #vert_scroll_max ; check to see if we need to do a coarse scroll
        bcc ?done       ; nope, still in the middle of the character
        jsr coarse_scroll_down ; yep, do a coarse scroll...
        lda #0          ;  ...followed by reseting the vscroll register
        sta vert_scroll
?done   sta VSCROL      ; store vertical scroll value in hardware register
        rts

; move viewport one line down by pointing display list start address
; to the address one page later in memory
coarse_scroll_down
        ldy #22         ; 22 lines to modify
        ldx #5          ; 5th byte after start of display list is high byte of address
?loop   inc dlist_2d_mode4,x
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
