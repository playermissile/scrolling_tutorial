; Written in 2019 by Rob McMullen, https://playermissile.com/scrolling_tutorial/
; Copyright and related rights waived via CC0: https://creativecommons.org/publicdomain/zero/1.0/
        *= $3000

.include "hardware.s"

delay = 5               ; number of VBLANKs between scrolling updates
vert_scroll_max = 8     ; ANTIC mode 4 has 8 scan lines
horz_scroll_max = 4     ; ANTIC mode 4 has 4 color clocks

delay_count = $80       ; counter for scrolling updates

vert_scroll = $90       ; variable used to store VSCROL value
horz_scroll = $91       ; variable used to store HSCROL value

pressed = $a0           ; user still pressing button?
latest_joystick = $a1   ; last joystick direction processed
joystick_y = $a2        ; down = 1, up=$ff, no movement = 0
joystick_x = $a3        ; right = 1, left=$ff, no movement = 0
vscroll_x2 = $a4        ; twice vertical scrolling? no = 0, yes = $ff

init    lda #0          ; initialize horizontal scrolling value
        sta horz_scroll
        sta HSCROL      ; initialize hardware register

        lda #0          ; initialize vertical scrolling value
        sta vert_scroll
        sta VSCROL      ; initialize hardware register

        lda #0
        sta pressed
        sta latest_joystick
        sta joystick_x
        sta joystick_y

        lda #delay      ; number of VBLANKs to wait
        sta delay_count

        jsr to_wide
        jsr to_1x

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

forever jmp forever


vbi     jsr check_console ; handle OPTION & SELECT keys for control changes
        jsr record_joystick ; check joystick for scrolling direction
        dec delay_count ; wait for number of VBLANKs before updating
        bne ?exit       ;   fine/coarse scrolling

        jsr process_joystick ; update scrolling position based on current joystick direction

        lda #delay      ; reset counter
        sta delay_count
?exit   jmp XITVBV      ; exit VBI through operating system routine


check_console
        lda CONSOL
        cmp #7          ; are no console keys pressed?
        beq ?not_anything ; yep, skip all checks
        bit pressed     ; something already pressed? Wait until released
        bmi ?exit       ;   before allowing anything new
        cmp #3          ; is OPTION pressed by itself?
        bne ?not_option ; nope, not that; check something else
        lda #$ff        ; store value to indicate console key is pressed
        sta pressed
        lda SDMCTL      ; check current playfield width
        cmp #$22        ; is it normal width?
        beq to_wide     ; it's currently normal, switch to wide
        bne to_narrow   ; otherwise it's wide, switch to normal
?not_option
        cmp #5          ; is SELECT pressed by itself?
        bne ?not_anything ; nope, not that; check something else
        lda #$ff        ; store value to indicate console key is pressed
        sta pressed
        lda vscroll_x2  ; check current step size
        beq to_2x       ; zero is 1x, switch to 2x
        bne to_1x       ; non-zero is 2x, switch to 1x
?not_anything
        lda #0          ; no console key pressed, so clear the variable
        sta pressed     ;   to allow a new press
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
        lda STICK0      ; check joystick
        cmp #$0f
        bcs ?fast       ; only store if a direction is pressed
        sta latest_joystick
?fast   lda STRIG0      ; easter egg: check trigger
        bne ?done       ; not pressed
        lda #1          ; pressed = ludicrous speed!
        sta delay_count
?done   rts

process_joystick
        lda #0                  ; clear joystick movement vars
        sta joystick_x
        sta joystick_y
        lda latest_joystick     ; bits 3 - 0 = right, left, down, up
        ror a                   ; put bit 0 (UP) in carry
        bcs ?down               ; carry clear = up, set = not pressed
        dec joystick_y
?down   ror a                   ; put bit 1 (DOWN) in carry
        bcs ?left
        inc joystick_y
?left   ror a                   ; put bit 2 (LEFT) in carry
        bcs ?right
        dec joystick_x
?right  ror a                   ; put bit 3 (RIGHT) in carry
        bcs ?next
        inc joystick_x
?next   lda #0
        sta latest_joystick     ; reset joystick

        lda joystick_x  ; check horizontal scrolling
        beq ?updown     ; zero means no movement, move on to vert
        bmi ?left1      ; bit 7 set ($ff) means left
        jsr fine_scroll_right ; otherwise, it's right
        jmp ?storeh
?left1  jsr fine_scroll_left
?storeh sta HSCROL      ; store vertical scroll value in hardware register
        clc             ; convert scroll value...
        adc #$90        ;   to ATASCII text and...
        sta joystick_text+29 ;   store on screen

?updown lda joystick_y  ; check vertical scrolling
        beq ?done       ; zero means no movement, we're done
        bmi ?up1        ; bit 7 set ($ff) means up
        jsr fine_scroll_down ; otherwise, it's down
        jmp ?storev
?up1    jsr fine_scroll_up
?storev sta VSCROL      ; store vertical scroll value in hardware register
        clc             ; convert scroll value...
        adc #$90        ;   to ATASCII text and...
        sta joystick_text+38 ;   store on screen
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
