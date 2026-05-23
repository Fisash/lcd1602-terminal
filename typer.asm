.include "base_macro.inc"

.section .text

.global type_char
.extern delay_tap
.extern delay_huge

; make mask of r18 bit
; result in r19
make_mask:
    ldi r19, 1       ; start mask value (0b00000001)
    tst r18
    breq 2f
1:  lsl r19
    dec r18
    brne 1b
2:  ret
    

; Z = addres of checking IO register
; r18 = number of bit
is_button_down:
    push r18
    push r24
    ld r24, Z        ; now r24 is value of IO reg
    rcall make_mask  ; now r19 is a bit mask
    and r24, r19     ; put mask for io reg
    tst r24
    pop r24
    pop r18
    ret

; Choosing char of ascii range by timing. Call AFTER button down
; ARGUMENTS:
; (button):
; Z = addres of checking IO register
; r18 = bit order number
; (typing):
; r22 - start typing ascii range code
; r24 - end typing ascii range code
; RESULT:
; r20 choosen ascii code
type_char:                ; 
    mov r16, r22          ; 
    rcall lcd_draw_char   ; new char that we will replace in leafing
    mov r20, r22          ; set r20 start ascii code
                          ;
1:  rcall sdelay_tap      ;

    ; we saved Z and r18 to this
    rcall is_button_down  ; check button status
    brne 2f               ; jump to end if button was upped
                          ; else:
    push r20
    mov r16, r20          ; now current choosen char in r16
    rcall lcd_replace_char; replace last char (from drawen in proc start) to this one
    pop r20

    inc r20               ;  

    mov r25, r24          ; now r25 = last ascii range char
    inc r25               ; now r25 = first out of range char code
    cp r20, r25           ; compare r20 with this code
    brlo 1b               ; if r20 is not out of range - go to next iter
    mov r20, r22          ; write r20 for next range circe
    rjmp 1b               ; next iter now
2:  ret                  
    
