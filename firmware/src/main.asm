.include "base_macro.inc"

#define DDRD 0x0A
#define PORTD 0x0B
#define PIND 0x09

#define DDRB 0x04
#define PORTB 0x05
#define PINB 0x03

.section .bss
input_line_offset: .space 1
output_line_offset: .space 1

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

main:
    ldi r16, 0xFF
    out 0x3D, r16
    ldi r16, 0x08
    out 0x3E, r16

    rcall uart_init
    rcall lcd_init

    ldi r16, 0
    sts output_line_offset, r16
    sts input_line_processing, r16

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
loop:
    rcall input_line_processing
    rcall output_line_processing
    rjmp loop

output_line_processing:
    rcall uart_try_read
    brne 1f
    rcall lcd_cursor_to_line2
    lds r17, output_line_offset
    rcall lcd_cursor_add
    inc r17
    sts output_line_offset, r17
     
    rcall lcd_input_char
    rcall lcd_cursor_to_line1
    ;lds r17, input_line_offset
    ;rcall lcd_cursor_add
1:  ret

input_line_processing:
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
    tap_button PIND, 7, 'u', 'z'

6:  sbis PINB, 0
    rcall lcd_erase_char
    rjmp 7f

7:  sbic PINB, 1
    rjmp 8f
    tap_button PINB, 1, '0', '9'

8:  sbic PINB, 2
    rjmp 9f
    tap_button PINB, 2, 'c', 'g'

9:  rcall delay_tap
    ldi r16, 0
    ldi r17, 0
    rcall lcd_draw_buffer

    ret
