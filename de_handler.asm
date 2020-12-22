.global my_de_handler
.extern what_to_do, old_de_handler

.data

.text
.align 4, 0x90
my_de_handler:
  # Prologue
  pushq %rbp
  movq %rsp, %rbp
  
  pushq %r12
  pushq %rax
  pushq %rdi
  
  # Preparing arguments for function what_to_do and calling it
  movq %rax , %rdi # numerator is always in rax
  call what_to_do
  
  popq %rdi
  movq %rax, %r12
  popq %rax
  
  cmp $0, %r12
  jne .what_to_do_returned_non_zero
  popq %r12
  call *old_de_handler
  leave
  iretq
  
.what_to_do_returned_non_zero:
  movq %r12, %rax
  popq %r12
  leave
  popq %r15 # should hold rip
  addq $3, %r15 # skip to next command after idiv
  pushq %r15
  iretq
  
