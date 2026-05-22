.macro set_z addr
    ldi r30, lo8(\addr)
    ldi r31, hi8(\addr)
.endm

.macro set_y addr
    ldi r28, lo8(\addr)
    ldi r29, hi8(\addr)
.endm

.macro set_x addr
    ldi r26, lo8(\addr)
    ldi r27, hi8(\addr)
.endm


.macro push_z
    push r30
    push r31
.endm

.macro pop_z
    pop r31
    pop r30
.endm
