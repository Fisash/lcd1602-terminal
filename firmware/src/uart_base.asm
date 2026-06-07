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

; bodrate const 16MhZ / (16 * 9600) - 1 = 103 
.equ BAUD_9600, 103

.section .text
.global uart_init
.global uart_write
.global uart_write_string
.global uart_read
.global uart_try_read

; init 9600 bauds, 8 data-bits, 1 stop-bit, no parity
uart_init:
    ldi r16, hi8(BAUD_9600)
    sts UBRR0H, r16
    ldi r16, lo8(BAUD_9600)
    sts UBRR0L, r16

    ldi r16, (1 << RXEN0) | (1 << TXEN0)
    sts UCSR0B, r16

    ldi r16, (1 << UCSZ01) | (1 << UCSZ00)
    sts UCSR0C, r16
    ret

; r16 = byte for transmit
uart_write:
    push r17
1:  lds r17, UCSR0A
    sbrs r17, UDRE0
    rjmp 1b
    
    sts UDR0, r16
    pop r17
    ret

; writes bytes from Z to first 0x0
uart_write_string:
    lpm r16, Z+ 
    tst r16
    breq 1f
    rcall uart_write
    rjmp uart_write_string
1:  ret
      
; after this, r16 will contain recived byte
uart_read:
    lds r17, UCSR0A
    sbrs r17, RXC0
    rjmp uart_read
    lds r16, UDR0
    ret
