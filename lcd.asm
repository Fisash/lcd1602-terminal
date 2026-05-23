#define LCD_RS 0
#define LCD_RW 1
#define LCD_E  2
#define LCD_BL 3

#define SCR_BFR_LINE_SIZE 64

#define ADDRES 0x4E

.include "base_macro.inc"

.section .bss
buffer: .space 32 ; buffer of frame for lcd 1602. 16*2 bytes

scrolling_first_line_buffer: .space SCR_BFR_LINE_SIZE ; for scrolling mode
scrolling_second_line_buffer: .space SCR_BFR_LINE_SIZE ; for scrolling mode


.section .text
; base
.global lcd_init
.global lcd_draw_char
.global lcd_do_command
.global lcd_erase_char
.global lcd_replace_char
.global lcd_clear
.global lcd_set_cursor_by_addres
.global lcd_set_cursor_by_position
.global lcd_draw_flash_string
.global lcd_draw_ram_string

; normal mode
.global lcd_draw_buffer
.global copy_flash_string_to_buffer
.global clear_buffer

; scrolling mode
.global lcd_draw_scrolling_buffer
.global copy_flash_string_to_first_scrolling_line
.global copy_flash_string_to_second_scrolling_line
.global copy_flash_string_from_z_to_y
.global clear_scrolling_buffer

; from i2c
.extern i2c_init
.extern i2c_write_start
.extern i2c_write_addres
.extern i2c_write_data
.extern i2c_write_stop

; from delay
.extern delay_big
.extern delay_small
.extern delay_tiny

; draw chars from bss buffer to lcd 
lcd_draw_buffer:
    rcall lcd_clear             ; clear lcd and set cursor to 0x0
    set_Z buffer                ; set r31:r30 for bss buffer addres
    ldi r19, 16                 ;
    rcall lcd_draw_chars_from_z ; draw first line
    ldi r16, 0x40               ;
    rcall lcd_set_cursor_by_addres; set cursor for start of second line
    ldi r19, 16                 ;
    rcall lcd_draw_chars_from_z ; draw second line

    ret                         ;
    
; draw r19 chars from Z index with inc
lcd_draw_chars_from_z:
    ld r16, Z+ 
    rcall lcd_draw_char
    dec r19
    brne lcd_draw_chars_from_z
    ret

; copy string from flash memory from r31:r30 (Z) addres 
; to first 0x0 byte to buffer
copy_flash_string_to_buffer:
    set_y buffer         ; now Y contains bss buffer addres
    rcall copy_flash_string_from_z_to_y
    ret
    
copy_flash_string_to_first_scrolling_line:
    set_y scrolling_first_line_buffer
    rcall copy_flash_string_from_z_to_y
    ret

copy_flash_string_to_second_scrolling_line:
    set_y scrolling_second_line_buffer
    rcall copy_flash_string_from_z_to_y
    ret

copy_flash_string_from_z_to_y:
1:  lpm r16, Z+          ; read another byte from flash
    tst r16              ; if it is 0x0
    breq 2f              ; jump to end
    st Y+, r16           ; else write this byte to buffer
    rjmp 1b              ; jump to next iteration
2:  ret                  ;

; draw string from flash memory from r31:r30 (Z) addres to first 0x0
lcd_draw_flash_string:
1:
    lpm r16, Z+
    tst r16
    breq 2f
    rcall lcd_draw_char
    rjmp 1b
2:
    ret

; insert string from flash memory by r31:r30 addres
lcd_draw_ram_string:
1:
    ld r16, Z+
    tst r16
    breq 2f
    rcall lcd_draw_char
    rjmp 1b
2:
    ret

; clear r17 bytes from z
; (fill thoose bytes for space char
clear_bytes_from_z:
    ldi r16, ' '
1:  st Z+, r16
    dec r17
    brne 1b
    ret

; fill buffer space char in full
clear_buffer:
    set_z buffer
    ldi r17, 32
    rcall clear_bytes_from_z
    ret
    
clear_scrolling_buffer:
    set_z scrolling_first_line_buffer
    ldi r17, SCR_BFR_LINE_SIZE
    rcall clear_bytes_from_z

    set_z scrolling_second_line_buffer
    ldi r17, SCR_BFR_LINE_SIZE
    rcall clear_bytes_from_z
    ret

; r16 = offset of first line
; r17 = offset of second line
; r16 and r17 from 0 to 64
lcd_draw_scrolling_buffer:
    push r17
    push r16

    push r17
    push r16

    rcall lcd_clear             ; clear lcd and set cursor to 0x0
    set_Z scrolling_first_line_buffer ; set r31:r30 for bss buffer addres
    pop r16    
    add r30, r16                ; add r16 to Z (offset for start first line buffer)
    adc r31, r1

    ldi r19, 16                 ;
    rcall lcd_draw_chars_from_z ; draw first line

    ldi r16, 0x40               ;
    rcall lcd_set_cursor_by_addres; set cursor for start of second line

    set_Z scrolling_second_line_buffer ; set r31:r30 for bss buffer addres
    pop r17    
    add r30, r17                ; add r17 to Z (offset for start second line buffer)
    adc r31, r1

    ldi r19, 16                 ;
    rcall lcd_draw_chars_from_z ; draw second line
    
    pop r16
    pop r17
    ret                         ;

; set cursor position to r16 row and r16 colum
; r16 have to be 0 or 1 
; r17 have to be in 0-15 (if you want chars to be vissable)
lcd_set_cursor_by_position:
    cpi r16, 1
    brne 1f
    ldi r16, 0x40
1:  add r16, r17
    rcall lcd_set_cursor_by_addres
    ret
    
; set cursor position by hd44780 ddram (get it from r16)
; r16 have to be in 0x00-0x27 or 0x40-0x67)
lcd_set_cursor_by_addres:
    ori r16, 0b10000000
    rcall lcd_do_command
    ret
    
; do 0x01 command and delay for clean complited
lcd_clear:
    ldi r16, 0x01
    rcall lcd_do_command
    rcall delay_big
    ret

; init lcd 1602 for 4 bit state, 2 lines
lcd_init:                
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

lcd_erase_char:          ;
    ldi r16, 0x10        ;
    rcall lcd_do_command ; move cursor left
    ldi r16, ' '         ; 
    rcall lcd_draw_char  ; draw space (and move cursor right)
    ldi r16, 0x10        ;
    rcall lcd_do_command ; move cursor left again
    ret                  ;

; r16 = new view of current char
lcd_replace_char:
    push r16
    ldi r16, 0x10
    rcall lcd_do_command
    pop r16
    rcall lcd_draw_char
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
