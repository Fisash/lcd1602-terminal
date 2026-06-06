.section .text

.global delay_1_nested
.global delay_2_nested
.global delay_3_nested

.global delay_tiny
.global delay_small
.global delay_big
.global delay_tap
.global sdelay_tap
.global delay_huge


; delay by loop with r20 iteration
delay_1_nested:
    dec r20
    brne delay_1_nested
    ret
 
; delay by loop with 255*r20 iteration
delay_2_nested:
    ldi r21, 255
1:  dec r21
    brne 1b
    dec r20
    brne delay_2_nested
    ret

; delay by loop with 255*255*r20 iteration
delay_3_nested:
    ldi r21, 255
1:  ldi r22, 255
2:  dec r22
    brne 2b
    dec r21
    brne 1b
    dec r20
    brne delay_3_nested
    ret

; delay by 20 iterations
delay_tiny:
    ldi r20, 20
    rcall delay_1_nested
    ret

; delay by 255 iterations
delay_small:
    ldi r20,255
    rcall delay_1_nested
    ret

; delay by 255*255 iterations
delay_big:
    ldi r20, 255
    rcall delay_2_nested
    ret

; delay by 255*255*45 iterations (~1 sec)
delay_huge:
    ldi r20, 45
    rcall delay_3_nested
    ret

; delay by 255*255*25
delay_tap:
    ldi r20, 25
    rcall delay_3_nested
    ret

; safe (for registers) delay tap
sdelay_tap:
    push r20
    push r21
    push r22
    rcall delay_tap
    pop r22
    pop r21
    pop r20
    ret
