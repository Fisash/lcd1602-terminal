.include "base_macro.inc"

.section .text

.global is_digit

; set zero flag if r16 is digit and fall zero flag if not
is_digit:
    cpi  r16, '0'                  ; compare with '0'
    brlo 1f                        ; if is lower -> this is not digit
    cpi  r16, '9' + 1              ; compare with '9'+1
    brsh 1f                        ; if is '9'+1 or higher -> this is not digit
    set_zero                       ; else this is digit. set zero flag
    rjmp 2f                        ; jump to ret
1:  clr_zero                       ; this is not digit so clear zero flag
2:  ret                            ;
