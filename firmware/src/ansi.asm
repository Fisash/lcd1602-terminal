.include "base_macro.inc"

; ----- states for parse ansi by bytes state machine ------
; input all chars to lcd buffer
#define NORMAL 0
; we got 0x1b, so wait for [
#define READ_CSI 1
; we got [, so reading params and command char
#define READ_PARAMS 2

#define ANSI_PARAM_BUF_SIZE 4

.section .bss
state_buffer: .space 1

ansi_params: .space ANSI_PARAM_BUF_SIZE
ansi_param_count: .space 1

.section .text

.global ansi_parse_byte

; from lcd_buf.asm
.extern lcd_input_char
; from strnum.asm
.extern is_digit

; fill ansi params by spaces
ansi_clear_param_buffer:
    push r16
    ldi r16, ' '
    set_z ansi_params
    ldi r17, ANSI_PARAM_BUF_SIZE
1:  st Z+, r16
    dec r17
    brne 1b
    pop r16
    ret

; parse r16 byte
ansi_parse:                        
    lds r17, state_buffer          ; load state to r17
    cpi r17, NORMAL                ; is normal state?
    breq ansi_parse_normal         ; so parse as normal
    cpi r17, READ_CSI              ; else is read csi state?
    breq ansi_parse_read_csi       ; so parse as read csi
    cpi r16, READ_PARAMS           ; else is read params state?
    breq ansi_parse_read_params    ; so parse as read params
    ret                            ; else r17 is undef state. just returns

; parse r16 byte in normal state
ansi_parse_normal:
    cpi r16, 0x1b                  ; if its esc byte
    breq 1f                        ; jump to change state
    rcall lcd_input_char           ; else input byte to lcd buffer
    rjmp 2f                        ; jump to ret
                                   ;
1:  ldi r17, READ_CSI              ; load READ_CSI state value to r17
    sts state_buffer, r17          ; store this value to state buffer
2:  ret                            ;
    
; parse r16 byte in read csi state
ansi_parse_read_csi:
    cpi r17, '['                   ; if its [ byte
    breq 1f                        ; jump to change state to read params
    ldi r17, NORMAL                ; else set r17 to normal state value
    sts state_buffer, r17          ; store normal value to state buffer (reset state)
    rjmp 2f                        ; jump to ret
1:  lds r17, READ_PARAMS           ; set r17 to read params state value
    sts state_buffer, r17          ; store this value to state buffer
    rcall ansi_clear_param_buffer  ; clear param buffer
2:  ret                            ;

; parse r16 byte in read params state 
ansi_parse_read_params:
    rcall is_digit                 ; is digit?
    brne 1f                        ; if this not digit. jump to 1f
                                   ; else is a digit
    lds r17, ansi_param_count      ; load param count to r17
    set_z ansi_params              ; now Z is ptr to start param buffer
    add_z r17                      ; now Z is ptr to current param
    ld r17, Z                      ; now r17 is the current param value
     
    ldi r18, 10                    ; put dec base to r18
    mul r17, r18                   ; 
    mov r17, r0                    ; now r17=r17*10
    add r17, r16                   ; now r17=(r17*10)+r16
    st Z, r17                      ; update param value by Z ptr
    rjmp 3f                        ; jump to ret
    
1:  cpi r16, ';'                   ; THIS IS NOT DIGIT. so compare with ;
    brne 2f                        ; if this not ; jump to 2f
    lds r17, ansi_param_count      ; load param count to r17
    inc r17                        ; increment (move to next param)
    sts ansi_param_count, r17      ; store new value to ram
    rjmp 3f                        ; jump to ret

2:  rcall ansi_do_commands         ; command processing...
    ldi r17, NORMAL
    sts state_buffer, r17
3:  ret

; do command with done param buffer and r16 as a command char
ansi_do_commands:
    cpi r16, 'J'
    breq ansi_j_command
    ret

ansi_j_command:
    lds r17, ansi_params           ;
    cpi r17, '2'                   ; 2J = clear screen
    brne 1f                        ;
    rcall clear_buffer             ;
1:  ret                            ;
