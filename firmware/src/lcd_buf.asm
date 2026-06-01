#define REAL_LINE_SIZE 16

#define LINE_BUF_SIZE 64

.include "base_macro.inc"

.section .bss
line1_buffer: .space LINE_BUF_SIZE 
line2_buffer: .space LINE_BUF_SIZE 

cursor_ptr: .space 2

.section .text

.global lcd_init
.global lcd_move_cursor_to_z
.global lcd_cursor_to_line1
.global lcd_cursor_to_line2

.global lcd_input_char
.global lcd_erase_char
.global lcd_replace_char

.global lcd_draw_buffer
.global clear_buffer

; from lcd_base
.extern lcd_base_init
.extern lcd_do_command
.extern lcd_clear
.extern lcd_draw_char
.extern lcd_set_cursor_by_addres

lcd_init:
    rcall lcd_base_init
    rcall lcd_cursor_to_line1
    rcall clear_buffer 
    ret

; ----------------------------- work with cursor ------------------------------
; load addres that cursor ptr stored to Z
lcd_load_cursor_addres_to_z:
    lds r30, cursor_ptr
    lds r31, cursor_ptr+1
    ret

; -------------------- move ---------------------
; move cursor to Z addres
lcd_move_cursor_to_z:
    set_y cursor_ptr
    st Y+, r30
    st Y, r31
    ret

; move cursor to start of line1 buffer
lcd_cursor_to_line1:
    set_z line1_buffer
    rcall lcd_move_cursor_to_z
    ret

; move cursor to start of line2 buffer
lcd_cursor_to_line2:
    set_z line2_buffer
    rcall lcd_move_cursor_to_z
    ret

; increment cursor ptr for next addres
lcd_cursor_increment:
    rcall lcd_load_cursor_addres_to_z
    adi_z 1
    rcall lcd_move_cursor_to_z
    ret
    
; decrement cursor ptr for previous addres
lcd_cursor_decrement:
    rcall lcd_load_cursor_addres_to_z
    subi_z 1
    rcall lcd_move_cursor_to_z
    ret
    
; ----------------------------- write to buffers ------------------------------
; ----------- cursor based char input -----------
; put char to addres from cursor and increment cursor ptr
; r16 = char
lcd_input_char:
    rcall  lcd_load_cursor_addres_to_z
    st Z, r16
    rcall lcd_cursor_increment
    ret

; dec cursor, put space (and inc cursor), dec cursor.
lcd_erase_char:
    rcall lcd_cursor_decrement
    ldi r16, ' '
    rcall lcd_input_char
    rcall lcd_cursor_decrement
    ret
    
; r16 = new value of current char
lcd_replace_char:
    rcall lcd_cursor_decrement
    rcall lcd_draw_char
    ret

; ---------------------- flash -----------------------
; copy bytes while another byte is not 0x0
; from Z to Y
copy_flash_string_from_z_to_y:
1:  lpm r16, Z+          ; read another byte from z
    tst r16              ; if it is 0x0
    breq 2f              ; jump to end
    st Y+, r16           ; else write this byte to Y
    rjmp 1b              ; jump to next iteration
2:  ret                  ;

; copy bytes while another byte is not 0x0
; from Z to line1_buffer
copy_flash_string_to_line1:
    set_y line1_buffer
    rcall copy_flash_string_from_z_to_y
    ret

; copy bytes while another byte is not 0x0
; from Z to line2_buffer
copy_flash_string_to_line2:
    set_y line2_buffer
    rcall copy_flash_string_from_z_to_y
    ret

; todo: copy flash string to cursor addres

; ------------------------ helping drawing procedures -------------------------
; draw r19 chars from Z index with increment Z
lcd_draw_chars_from_z:
    ld r16, Z+ 
    rcall lcd_draw_char
    dec r19
    brne lcd_draw_chars_from_z
    ret

; clear r17 bytes from z
; (fill thoose bytes for space char)
clear_bytes_from_z:
    ldi r16, ' '
1:  st Z+, r16
    dec r17
    brne 1b
    ret


; ------------------------ work with ready-made buffer ------------------------
; fill line buffers for space char
clear_buffer:
    set_z line1_buffer
    ldi r17, LINE_BUF_SIZE
    rcall clear_bytes_from_z

    set_z line2_buffer
    ldi r17, LINE_BUF_SIZE
    rcall clear_bytes_from_z
    ret


; r16 = offset of first line
; r17 = offset of second line
lcd_draw_buffer:
    push r17
    push r16
    push r17
    push r16

    ; debug
    rcall uart_output_buffer
    rcall uart_output_cursor_value

    rcall lcd_clear             ; clear lcd and set cursor to 0x0

    set_z line1_buffer          ; set r31:r30 for bss buffer addres
    pop r16    
    add_z r16                   
    ldi r19, REAL_LINE_SIZE     ;
    rcall lcd_draw_chars_from_z ; draw first line

    ldi r16, 0x40               ;
    rcall lcd_set_cursor        ; set cursor to start of second line
    
    set_z line2_buffer          ; set r31:r30 for bss buffer addres
    pop r17    
    add_z r17                   ; add r17 to Z (offset for start second line buffer)
    ldi r19, REAL_LINE_SIZE     ;
    rcall lcd_draw_chars_from_z ; draw second line
    
    pop r16
    pop r17
    ret                         

; --------------------------------- debugging ----------------------------------
start_cursor_seq: .asciz "/^m[CUR"
.p2align 1 
uart_output_cursor_value:
    set_z start_cursor_seq
    rcall uart_write_string

    rcall lcd_load_cursor_addres_to_z
    mov r16, r30
    rcall uart_write
    mov r16, r31
    rcall uart_write
    ret
    
start_buffer_seq: .asciz "/^m[BUF"
.p2align 1 
uart_output_buffer:
    set_z start_buffer_seq
    rcall uart_write_string

    set_z line1_buffer
    ldi r17, 16
1:  ld r16, Z+
    rcall uart_write 
    dec r17
    brne 1b
    ret
