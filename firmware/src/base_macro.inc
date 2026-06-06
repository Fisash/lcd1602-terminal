.macro set_z addr
    ldi r30, lo8(\addr)
    ldi r31, hi8(\addr)
.endm

.macro push_z
    push r30
    push r31
.endm

.macro pop_z
    pop r31
    pop r30
.endm

.macro add_z reg_low
    add  r30, \reg_low
    clr  r0
    adc  r31, r0
.endm

.macro adi_z val
    subi r30, lo8(-(\val))  
    sbci r31, hi8(-(\val))  
.endm

.macro sub_z reg_low
    sub  r30, \reg_low
    clr  r0
    sbc  r31, r0
.endm

.macro subi_z val
    subi r30, lo8(\val)  
    sbci r31, hi8(\val)  
.endm

.macro set_y addr
    ldi r28, lo8(\addr)
    ldi r29, hi8(\addr)
.endm

.macro set_x addr
    ldi r26, lo8(\addr)
    ldi r27, hi8(\addr)
.endm

.macro set_zero
    clr r0          
.endm

.macro clr_zero
    clr r0
    inc r0
    tst r0          
.endm
