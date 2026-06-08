.include "base_macro.inc"

#define DDRD 0x0A
#define PORTD 0x0B
#define PIND 0x09

#define DDRB 0x04
#define PORTB 0x05
#define PINB 0x03

.section .text
.global main

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
    ldi r16, 0                     ; set buffer offset to zero
    ldi r17, 0                     ; and second line too zero offset
    rcall lcd_draw_buffer          ; render lcd buffer
    rcall delay_tap
    ret

reading_loop:
    rcall uart_read
    cpi r16, 0x04
    breq 1f
    rcall lcd_input_char 
    rjmp reading_loop
1:  rcall change_state_to_typing 
    rcall render

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

6:  sbis PINB, 0
    rcall lcd_erase_char

7:  sbic PINB, 1
    rjmp 8f
    ; 30-3F
    tap_button PINB, 1, '0', '?'

8:  sbis PINB, 2
    rjmp send_typed

    rcall render

    rjmp typing_loop

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
