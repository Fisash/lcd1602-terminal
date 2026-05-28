global _start
    
section .bss
    device_fd: resb 4
    buf: resb 1024

section .text

start_msg db "uart debugger starting...", 10
start_msg_len equ $-start_msg

device_name db "/dev/ttyUSB0", 0

open_error_text db "cant open /dev/ttyUSB0", 10
open_error_text_len equ $-open_error_text

read_error_text db "cant read deivce", 10
read_error_text_len equ $-read_error_text

eof db "eof", 10

_start:
    mov ecx, start_msg
    mov edx, start_msg_len
    call stdout_write

open_device:
    mov ebx, device_name
    mov ecx, 0
    call open
    mov edx, eax
    and edx, 0fffff000h
    cmp edx, 0fffff000h
    jz open_error
    mov [device_fd], eax
    
read_device:
    mov ebx, [device_fd]
    mov ecx, buf
    mov edx, 128
    call read
    
    cmp eax, 0
    jl read_error
    je read_eof
    
    mov ecx, buf
    mov edx, eax
    call stdout_write
    jmp read_device

read_eof:
    mov ecx, eof
    mov edx, 4
    call stdout_write
    jmp read_device
    
read_error:
    mov ecx, read_error_text
    mov edx, read_error_text_len
    call stdout_write
    
close_device:
    mov ebx, [device_fd]
    call close
        
    jmp exit
    
open_error:
    mov ecx, open_error_text
    mov edx, open_error_text_len
    call stdout_write
    
    jmp exit
    
stdout_write:
    mov ebx, 1
    call write
    ret

open:
    mov eax, 5
    int 80h
    ret

close:
    mov eax, 6
    int 80h
    ret

read:
    mov eax, 3
    int 80h
    ret

write:
    mov eax, 4
    int 80h
    ret

exit:
    mov eax, 1
    mov ebx, 0
    int 80h
