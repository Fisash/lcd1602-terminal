.include "base_macro.inc"

#define DDRD 0x0A
#define PORTD 0x0B
#define PIND 0x09

#define DDRB 0x04
#define PORTB 0x05
#define PINB 0x03

.section .bss
line1_current_offset: .space 1
line1_max_offset: .space 1

line2_current_offset: .space 1

.section .text
.global main
.global render
.global update_line2_offset

; from delay.asm
.extern delay_big
.extern delay_tap
.extern delay_huge

; from lcd_buf
.extern lcd_init
.extern lcd_move_cursor_to_z
.extern lcd_cursor_to_line1
.extern lcd_cursor_to_line2
.extern lcd_cursor_add

.extern lcd_input_char
.extern lcd_erase_char
.extern lcd_replace_char
.extern lcd_draw_buffer
.extern clear_buffer

; from uart.asm
.extern uart_init
.extern uart_write
.extern uart_read

; from uart_buf.asm
.extern uart_try_read

; from typer.asm
.extern type_char

.macro tap_button reg, bit, start, end
    set_z \reg+0x20
    ldi r18, \bit
    ldi r22, \start
    ldi r24, \end
    rcall type_char
.endm

#define start_message_len 16
start_message: .asciz "lcd1602-terminal"
.p2align 1 

main:
    ldi r16, 0xFF
    out 0x3D, r16
    ldi r16, 0x08
    out 0x3E, r16

    rcall uart_init
    rcall lcd_init

    set_z start_message
    rcall copy_flash_string_to_line1

    ldi r16, start_message_len
    sts line1_max_offset, r16

    ldi r16, 0
    sts line1_current_offset, r16
    sts line2_current_offset, r16

    rcall change_state_to_typing

    ldi r16, 0x0  ; null mask
    out DDRD, r16 ; now ALL bits of DDRD is 0 - bits of D-port in INPUT (D0-D7)
    cbi DDRB, 0   ; now D8 in INPUT
    cbi DDRB, 1   ; now D9 in INPUT
    cbi DDRB, 2   ; now D10 in INPUT

    ldi r16, 0b11111111
    out PORTD, r16; now ALL bits of PORTDB is - bits of D-port in HIGH (5V)
    sbi PORTB, 0  ; now D8 in HIGH (5V)
    sbi PORTB, 1  ; now D9 in HIGH (5V)
    sbi PORTB, 2  ; now D10 in HIGH (5V)
    rjmp typing_loop

render:
    lds r16, line1_current_offset  ; set buffer offset
    lds r17, line2_current_offset   ; and second line offset
    rcall lcd_draw_buffer          ; render lcd buffer
    rcall sdelay_tap                
    rcall update_line1_offset   ; for line 1 scrolling
    ret

; r16 = current line1 offet
update_line1_offset:
    inc r16
    lds r17, line1_max_offset
    cp r16, r17
    brne 1f
    ldi r16, 0
1:  sts line1_current_offset, r16
    ret
    
reading_loop:
    rcall uart_read                ; read byte from uart. put in r16
    cpi r16, 0x04                  ; if it is 0x04
    breq 1f                        ; so jump to exit reading loop
    rcall lcd_input_char           ; put this char to lcd buffer
    rjmp reading_loop              ; jump to next iteration
1:  rcall lcd_get_cursor_offset_from_line1; get offset for scrolling
    sts line1_max_offset, r17      ; set it as max offset
    rcall change_state_to_typing   ; we got 0x04, so clear line and move cursor for typing

    ldi r16, 0
    sts line1_current_offset, r16

    rcall render                   ; draw buffer to lcd

typing_loop:
    sbic PIND, 2
    rjmp 1f
    tap_button PIND, 2, ' ', '/'

1:  sbic PIND, 3
    rjmp 2f
    tap_button PIND, 3, 'a', 'e'

2:  sbic PIND, 4
    rjmp 3f
    tap_button PIND, 4, 'f', 'j'

3:  sbic PIND, 5
    rjmp 4f
    tap_button PIND, 5, 'k', 'o'

4:  sbic PIND, 6
    rjmp 5f
    tap_button PIND, 6, 'p', 't'

5:  sbic PIND, 7
    rjmp 6f
    tap_button PIND, 7, 'u', '}'

6:  sbic PINB, 0
    rjmp 7f
    rcall lcd_erase_char
    rcall update_line2_offset

7:  sbic PINB, 1
    rjmp 8f
    tap_button PINB, 1, '0', '?'

8:  sbis PINB, 2
    rjmp send_typed

    rcall render
    rjmp typing_loop

; it calls from typer when it input new char
; to not call it every typer loop iteraion
update_line2_offset:
    push_z
    push r24
    push r25

    rcall lcd_get_cursor_offset_from_line2   ; load string length to r17
    cpi r17, 17                              ; compare with 17
    brlo 1f                                  ; if it < 17, jump to 1f
    brsh 2f                                  ; is it >= 17, jump to 2f
                                             ;
1:  ldi r16, 0                               ; if length < 17
    sts line2_current_offset, r16            ; set line2 offset = 0
    rjmp 3f                                  ; jump to ret
2:  subi r17, 16                             ; if length >= 17, make r17=length-16
    sts line2_current_offset, r17            ; set line2 offset = length-16
3:  pop r25
    pop r24
    pop_z 
    ret


; send typed text from buffer to uart
send_typed:
    rcall uart_output_line2_to_cursor   ; output typing buffer from start to cursor
    ldi r16, 0x0a                       ; load end of line (\n) byte to r16
    rcall uart_write                    ; send this to uart. so we upload out typed cmd
    rcall change_state_to_reading
    rjmp reading_loop

change_state_to_typing:
    rcall clear_line2_buffer
    rcall lcd_cursor_to_line2
    ret

change_state_to_reading:
    rcall clear_line1_buffer
    rcall lcd_cursor_to_line1 
    ret
