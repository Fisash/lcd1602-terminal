.include "base_macro.inc"

#define UCSR0A 0xC0
#define UCSR0B 0xC1
#define UCSR0C 0xC2

#define UBRR0L 0xC4
#define UBRR0H 0xC5

#define UDR0   0xC6

.equ RXEN0,  4
.equ TXEN0,  3
.equ UCSZ01, 2
.equ UCSZ00, 1
.equ UDRE0,  5
.equ RXC0,   7

;.section .bss
;uart_read_buffer: .space 128

.section .text
.global uart_try_read


; try get byte, if readed - set zero flag and put byte to r16
uart_try_read:
    push r17
    clr_zero
    lds r17, UCSR0A
    sbrs r17, RXC0
    rjmp 1f
    lds r16, UDR0
    set_zero
1:  pop r17 
    ret
