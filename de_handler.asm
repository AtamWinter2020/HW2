.globl my_de_handler
.extern what_to_do, old_de_handler

.data

.text
.align 4, 0x90
my_de_handler:
  # Prologue
  pushq %rbp
  movq %rsp, %rbp
  
  # Backing up caller-saved registers
  pushq %rdi
  pushq %rsi
  pushq %rdx
  pushq %rcx
  pushq %r8
  pushq %r9
  pushq %r10
  pushq %r11
  # Not sure we need to backup all of it - better safe than sorry
  
  # Preparing arguments for function what_to_do and calling it
  movq %rax , %rdi # numerator is always in rax
  call what_to_do
  
  # Restoring caller-saved registers
  popq %r11
  popq %r10
  popq %r9
  popq %r8
  popq %rcx
  popq %rdx
  popq %rsi
  popq %rdi
  
.handler_decision
  cmp $0, %rax
  jne .what_to_do_returned_non_zero
  je  .what_to_do_returned_zero
  
.what_to_do_returned_non_zero
  movq %rax, %rsi #rsi should hold the division result
  leave
  iretq
  
.what_to_do_returned_zero
  leave
  jmp *old_de_handler
  