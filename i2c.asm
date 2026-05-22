#define DDRB   0x04
#define PORTB  0x05
#define DDRC   0x07
#define PORTC  0x08

; TWI registers
#define TWBR 0xB8
#define TWSR 0xB9
#define TWDR 0xBB
#define TWCR 0xBC

#define TWINT 7
#define TWSTA 5
#define TWSTO 4
#define TWEN  2

.section .text
.global i2c_init

.global i2c_write_start
.global i2c_write_addres
.global i2c_write_data
.global i2c_write_stop

.global i2c_send_byte
.global i2c_send_bytes

.extern delay_big

i2c_init:                
    sbi PORTC, 4         ; pullup SDA for A4 pin
    sbi PORTC, 5         ; pullup SCL for A5 pin

    ldi r16, 72          ; TWI 100kHz 16MHz value
    sts TWBR, r16        ;
    clr r16              ;
    sts TWSR,r16         ;
    ldi r16,(1<<TWEN)    ;
    sts TWCR,r16         ;
    rcall delay_big      ; 
    ret                  

; ---------------------- procedures for send byte ------------------------

; wait while twint bit from twcr will active
wait_twint:
    lds r18,TWCR
    sbrs r18,TWINT
    rjmp wait_twint
    ret

i2c_write_start:
    ldi r18,(1<<TWINT)|(1<<TWSTA)|(1<<TWEN) 
    sts TWCR,r18

    rcall wait_twint
    ret

i2c_write_stop:
    ldi r18,(1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
    sts TWCR,r18

    ret

; write addres byte from r16
i2c_write_addres:
    sts TWDR,r16
    ldi r18,(1<<TWINT)|(1<<TWEN)
    sts TWCR,r18
    
    rcall wait_twint
    ret

; write data byte from r16
i2c_write_data:
    sts TWDR,r16
    ldi r18,(1<<TWINT)|(1<<TWEN)
    sts TWCR,r18
    
    rcall wait_twint
    ret

; I2C SECCION
; write byte from r16 by i2c protocol to OUTPUT
i2c_send_byte:
    rcall i2c_write_start
    rcall i2c_write_addres
    rcall i2c_write_data
    rcall i2c_write_stop
    ret

; write r17 bytes from Z
i2c_send_bytes:
    rcall i2c_write_start
    rcall i2c_write_addres
    
1:  ld r16, Z+
    rcall i2c_write_data
    dec r17
    brne 1b
    
    rcall i2c_write_stop
    ret
    
