        *= $3000

.include "hardware.s"

delay = 5

delay_count = $80       ; counter between scrolls

vert_scroll = $90       ; variable used to store VSCROL value
vert_scroll_max = 8     ; ANTIC mode 4 has 8 scan lines
horz_scroll = $91       ; variable used to store HSCROL value
horz_scroll_max = 4     ; ANTIC mode 4 has 4 color clocks

pressed = $a0           ; user still pressing button?
latest_joystick = $a1   ; last joystick direction processed
joystick_down = $a2     ; down = 1, up=$ff, no movement = 0
joystick_right = $a3    ; right = 1, left=$ff, no movement = 0
vscroll_x2 = $a4        ; twice vertical scrolling? no = 0, yes = $ff

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

        ; load deferred vertical blank address
        ldx #>vbi
        ldy #<vbi
        lda #7
        jsr SETVBV

        ; activate display list interrupt
        lda #NMIEN_VBI | NMIEN_DLI
        sta NMIEN

        jsr fillscreen_test_pattern
        lda #$80
        ldx #$38        ; 56 pages; bytes $8000 - $b7ff
        jsr label_pages

        lda #0          ; initialize horizontal scrolling value
        sta horz_scroll
        sta HSCROL      ; initialize hardware register

        lda #0          ; initialize vertical scrolling value
        sta vert_scroll
        sta VSCROL      ; initialize hardware register

        lda #0
        sta pressed

        lda #delay      ; number of VBLANKs to wait
        sta delay_count

        jsr to_wide
        jsr to_1x

forever jmp forever


vbi     jsr toggle_wide ; handle OPTION & SELECT keys for control changes
        jsr record_joystick ; check joystick for scrolling direction
        dec delay_count ; wait for number of VBLANKs before updating
        bne ?exit       ;   fine/coarse scrolling

        jsr process_joystick ; update scrolling position based on current joystick direction

        lda #delay      ; reset counter
        sta delay_count
?exit   jmp XITVBV      ; exit VBI through operating system routine


toggle_wide
        lda CONSOL
        cmp #7          ; nothing pressed
        beq ?not_anything
        bit pressed     ; something already pressed? Wait until released
        bmi ?exit       ;   before allowing anything new
        cmp #3          ; option by itself
        bne ?not_option
        lda #$ff
        sta pressed
        lda SDMCTL
        cmp #$22
        beq to_wide
        bne to_narrow
?not_option
        cmp #5          ; select by itself
        bne ?not_anything
        lda #$ff
        sta pressed
        lda vscroll_x2
        beq to_2x
        bne to_1x
?not_anything
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

to_2x   lda #$ff        ; enable 2x vertical scrolling
        sta vscroll_x2
        lda #<x2_text ; change status text
        sta dlist_2d_mode4_status_line3+1
        lda #>x2_text
        sta dlist_2d_mode4_status_line3+2
        rts

to_1x   lda #0          ; enable 1x vertical scrolling
        sta vscroll_x2
        lda #<x1_text   ; change status text
        sta dlist_2d_mode4_status_line3+1
        lda #>x1_text
        sta dlist_2d_mode4_status_line3+2
        rts


; JOYSTICK DIRECTION

record_joystick
        lda STICK0
        cmp #$0f
        bcs ?done       ; only store if a direction is pressed
        sta latest_joystick
?done   rts

process_joystick
        lda #0
        sta joystick_down
        sta joystick_right
        lda latest_joystick     ; bits 3 - 0 = right, left, down, up
        ror a                   ; put bit 0 (UP) in carry
        bcs ?down               ; carry clear = up, set = not pressed
        dec joystick_down
?down   ror a                   ; put bit 1 (DOWN) in carry
        bcs ?left
        inc joystick_down
?left   ror a                   ; put bit 2 (LEFT) in carry
        bcs ?right
        dec joystick_right
?right  ror a                   ; put bit 3 (RIGHT) in carry
        bcs ?next
        inc joystick_right
?next   lda #0
        sta latest_joystick     ; reset joystick

        lda joystick_right
        beq ?updown
        bmi ?left1
        jsr fine_scroll_right
        jmp ?storeh
?left1  jsr fine_scroll_left
?storeh sta HSCROL      ; store vertical scroll value in hardware register
        clc
        adc #$90
        sta joystick_text+29

?updown lda joystick_down
        beq ?done
        bmi ?up1
        jsr fine_scroll_down
        jmp ?storev
?up1    jsr fine_scroll_up
?storev sta VSCROL      ; store vertical scroll value in hardware register
        clc
        adc #$90
        sta joystick_text+38
?done   rts


; HORIZONTAL SCROLLING

; scroll one color clock right and check if at HSCROL limit, returns
; HSCROL value in A
fine_scroll_right
        dec horz_scroll
        lda horz_scroll
        bpl ?done       ; if non-negative, still in the middle of the character
        jsr coarse_scroll_right ; wrapped to $ff, do a coarse scroll...
        lda #horz_scroll_max-1  ;  ...followed by reseting the HSCROL register
        sta horz_scroll
?done   rts

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

; scroll one color clock left and check if at HSCROL limit, returns
; HSCROL value in A
fine_scroll_left
        inc horz_scroll
        lda horz_scroll
        cmp #horz_scroll_max ; check to see if we need to do a coarse scroll
        bcc ?done       ; nope, still in the middle of the character
        jsr coarse_scroll_left ; yep, do a coarse scroll...
        lda #0          ;  ...followed by reseting the HSCROL register
        sta horz_scroll
?done   rts

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

; scroll one scan line up and check if at VSCROL limit, returns
; VSCROL value in A
fine_scroll_up
        dec vert_scroll
        bit vscroll_x2
        bpl ?not_2x
        dec vert_scroll
?not_2x lda vert_scroll
        bpl ?done       ; if non-negative, still in the middle of the character
        jsr coarse_scroll_up   ; wrapped to $ff, do a coarse scroll...
        lda #vert_scroll_max-1 ;  ...followed by reseting the vscroll register
        sta vert_scroll
?done   rts

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

; scroll one scan line down and check if at VSCROL limit, returns
; VSCROL value in A
fine_scroll_down
        inc vert_scroll
        bit vscroll_x2
        bpl ?not_2x
        inc vert_scroll
?not_2x lda vert_scroll
        cmp #vert_scroll_max ; check to see if we need to do a coarse scroll
        bcc ?done       ; nope, still in the middle of the character
        jsr coarse_scroll_down ; yep, do a coarse scroll...
        lda #0          ;  ...followed by reseting the vscroll register
        sta vert_scroll
?done   rts

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
