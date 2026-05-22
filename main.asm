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

; from lcd.asm
.extern lcd_init
.extern clear_buffer
.extern copy_flash_string_to_buffer
.extern lcd_draw_buffer
.extern lcd_draw_flash_string
.extern lcd_shift_left

.extern lcd_draw_scrolling_buffer
.extern copy_flash_string_to_first_scrolling_line
.extern copy_flash_string_to_second_scrolling_line
.extern clear_scrolling_buffer

; from uart.asm
.extern uart_init
.extern uart_write
.extern uart_read

; from typer.asm
.extern type_char

.macro tap_button reg, bit, start, end
    set_z \reg+0x20
    ldi r18, \bit
    ldi r22, \start
    ldi r24, \end
    rcall type_char
    rcall delay_tap
.endm

main:
    ldi r16, 0xFF
    out 0x3D, r16
    ldi r16, 0x08
    out 0x3E, r16

    rcall lcd_init
    rcall uart_init
    
    rcall lcd_clear

    ldi r16, 0x0  ; null mask
    out DDRD, r16 ; now ALL bits of DDRD is 0 - bits of D-port in INPUT (D0-D7)
    cbi DDRB, 0   ; now D8 in INPUT

    ldi r16, 0b11111111
    out PORTD, r16; nor ALL bits of PORTDB is - bits of D-port i LOW 
    sbi PORTB, 0

loop:
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
    rcall delay_tap
    
    rjmp loop

