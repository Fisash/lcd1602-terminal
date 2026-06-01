global sys_read
global sys_write
global sys_open
global sys_close
global sys_errno

section .text

generic_syscall_3:
    push ebp
    mov ebp, esp
    push ebx
    mov ebx, [ebp+8]
    mov ecx, [ebp+12]
    mov edx, [ebp+16]
    int 80h
    mov edx, eax
    and edx, 0fffff000h
    cmp edx, 0fffff000h
    jne .okay
    mov [sys_errno], eax
    mov eax, -1
.okay:
    pop ebx
    mov esp, ebp
    pop ebp 
    ret

sys_read:
    mov eax, 3
    jmp generic_syscall_3
sys_write:
    mov eax, 4
    jmp generic_syscall_3
sys_open:
    mov eax, 5
    jmp generic_syscall_3
sys_close:
    mov eax, 6
    jmp generic_syscall_3

section  .bss
sys_errno resd 1
