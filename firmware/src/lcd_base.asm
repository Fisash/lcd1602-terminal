#define LCD_RS 0
#define LCD_RW 1
#define LCD_E  2
#define LCD_BL 3

#define ADDRES 0x4E

.section .text

.global lcd_base_init
.global lcd_write_byte
.global lcd_do_command
.global lcd_clear
.global lcd_draw_char
.global lcd_set_cursor

; from i2c
.extern i2c_init
.extern i2c_write_start
.extern i2c_write_data
.extern i2c_write_stop

; from delay
.extern delay_big
.extern delay_small

; init lcd 1602 for 4 bit state, 2 lines
lcd_base_init:                
    rcall i2c_init       ;
                         ;
    ldi r16,0x33         ; init sequance
    rcall lcd_do_command ;
    rcall delay_big      ;
    ldi r16,0x32         ;
    rcall lcd_do_command ;
    rcall delay_big      ;
    ldi r16,0x28         ; 4-bit, 2 lines 
    rcall lcd_do_command ;
    ldi r16,0x0C         ; display ON         
    rcall lcd_do_command ;
    ldi r16,0x06         ; entry mode
    rcall lcd_do_command ;
    ret                  

; write byte from r17 by i2c
; every part like 76543210 where
; 3 2 1 0 - BL, E, RW, RS; 7 6 5 4 - data part
; we call i2c twice cause we need no change E for send byte
lcd_write_byte:                    ; 
    rcall i2c_write_start          ; start i2c seccion
    ldi r16, ADDRES                ; put addres of lcd port to r16
    rcall i2c_write_data           ; set this addres for i2c
                                   ;
    ori r17,(1<<LCD_E)|(1<<LCD_BL) ; set lcd_e (enable) and lcd_bl (blight) bits to 1
                                   ;
    mov r16,r17                    ;
    rcall i2c_write_data           ; output data byte
                                   ;
    andi r16, ~(1<<LCD_E)          ; set lcd_e to 0
    rcall i2c_write_data           ; output byte with lcd_e = 0
                                   ;
    rcall i2c_write_stop           ; stop i2c seccion
    ret                            ;

; r16 = command
lcd_do_command:
    push r18
    push r16

    mov r17,r16
    andi r17,0b11110000
    rcall lcd_write_byte

    pop r16
    swap r16
    andi r16,0b11110000
    mov r17,r16
    rcall lcd_write_byte
    rcall delay_small

    pop r18
    ret

; do 0x01 command and delay for clean complited
lcd_clear:
    ldi r16, 0x01
    rcall lcd_do_command
    rcall delay_big
    ret

; r16 = char
lcd_draw_char:
    push r18
    push r16

    mov r17,r16
    andi r17,0b11110000
    ori r17,(1<<LCD_RS)

    rcall lcd_write_byte

    pop r16
    swap r16
    andi r16,0b11110000
    ori r16,(1<<LCD_RS)

    mov r17,r16
    rcall lcd_write_byte
    rcall delay_small
    pop r18
    ret

; set cursor position by hd44780 ddram (get it from r16)
; r16 have to be in 0x00-0x27 or 0x40-0x67)
lcd_set_cursor:
    ori r16, 0b10000000
    rcall lcd_do_command
    ret
