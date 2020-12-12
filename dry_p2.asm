.section .data
msg1: .ascii "HOW YOOOU DOOIN?"
msg2: .ascii "JOEY DOESN'T SHARE FOOD!"
msg1_len: .quad msg2 - msg1
msg2_len: .quad msg1_len - msg2
all_msg_len: .quad msg1_len - msg1

.section .text
.global main
main:
    mov $msg1, %rsi
    mov $1, %rdi
    mov $1, %rdx
    mov $1, %rax
    xor %rbx, %rbx
    
    movq all_msg_len, %r9
    # movq msg1_len, %r9
    inc %r9
    mov $Joey_func, %rcx
    call Joey_func

Joey_func:
        cmp %rbx, %r9
        je end
        addb $0x20, (%rsi)
        test $1, %rbx
        jnz skip
        syscall
skip:   inc %rsi
        inc %rbx
        call Joey_func
        jmp *%rcx
end:    ret
