.global	calc_expr
.section .data
# A 64bit integer is at most 19 digits + sign + '\0'
num_buf: .zero 21

.section .text

calc_op:
	# '+' == 43 ; '-' == 45 ; '*' == 42 ; '/' == 47
	# rdi - op_char ; rsi - num1 ; rdx - num2
	pushq	%rbp
	movq	%rsp, %rbp
op_add:
	cmp		$43, %rsi
	jne		op_sub
	addq	%rsi, %rdx
	jmp		epilogue_calc_op
op_sub:
	cmp		$45, %rsi
	jne		op_mult
	subq	%rsi, %rdx
	jmp		epilogue_calc_op
op_mult:
	cmp		$42, %rsi
	jne		op_div
	imulq	%rsi, %rdx
	jmp		epilogue_calc_op
op_div:
	# Assuming cmp $47, %rsi bust be eq
	idivq	%rsi, %rdx
	jmp		epilogue_calc_op
epilogue_calc_op:
	movq	%rdx, %rax # Move result to ret reg
	leave
	ret


read_char: # rdi - dest addr
	pushq	%rbp
	movq	$0, %rax # sys_read
	movq	%rsp, %rbp
	movq	%rdi, %rsi	# dest addr -> %rsi
	movq	$0, %rdi	# 0 = stdin
	movq	$1, %rdx	# Read 1 byte
	syscall
	leave
	ret



calc_expr_overloaded:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$41, %rsp
	movq	%rdi, -32(%rdi) # Save string_convert until we need it
	# Calle saved
	movq	%r14, -24(%rsp)
	movq	%r13, -16(%rsp)
	movq	%r12, -8(%rsp)
	# op_char (rsp-40) === 1 bytes
	movq	$0, (%rsp) # num = 0

	# States: START = 0, NUM1 = 1, NUM2 = 2, EXP1 = 3, EXP2 = 4, OP = 5
	# r12 = c ; r13 = i; r14 = state # We only use LSByte of those
	movq $0, %r13	# i = 0
	movq $s_START, %r14	# state = 0

read_loop:
	# Read char
	movq	%r13, %rdi		# rdi = i
	addq	$buf, %rdi		# rdi = curr_cell_addr
	call read_char
	leaq	1(%r13), %r13	# i++
	# switch(state)
	jmp		%r14			# Go to state
s_START:
	cmp		$40, %r12
	jeq		START_else		# if c != '(' # Assuming either a digit or a negsign
	movq	$s_NUM1, %r14	# state = NUM1
	jmp		read_loop		# switch break
START_else:					# if c == '('
	movq	$s_EXP1, %r14	# state = EXP1
	movq	-32(%rdi), %rdi # recovert string_convert
	call	calc_expr_overloaded
	jmp		read_loop		# switch break

s_NUM1:
	# Make sure '0' <= c <= '9'
	cmp		%r12, $48
	jl		NUM1_elif		# jmp if c < '0'
	cmp		%r12, $57
	jg		NUM1_elif		# c > '9'
	jmp		read_loop		# switch break
NUM1_elif:
	cmp		%r12, $41		# c == ')'
	jne		NUM1_else
	pushq	%rbx			# Save rbx
	movq	%rdi, %rbx		# Move string_convert to calee saved (rbx)
	movq	$buf, %rdi		# rdi = buf
	movb	$0, -1(%rdi, %r13) # buf[i-1] = '\0'
	call	%rbx			# Call string_convert(buf)
	popq	%rbx			# Restore callee saved reg
	# The string_convert return value is our return value
	# movq	%rax, %rax
	jmp		epilogue_overloaded
NUM1_else:
	# Assuming c in {-,+,*,/}
	movq	%r12, -40(%rsp)	# op_char = c
	# Convert string to integer (64 bit)
	pushq	%rbx			# Save rbx
	movq	%rdi, %rbx		# Move string_convert to calee saved (rbx)
	movq	$buf, %rdi		# rdi = buf
	movb	$0, -1(%rdi, %r13) # buf[i-1] = '\0'
	call	%rbx			# Call string_convert(buf)
	movq	%rbx, %rdi		# restore string_convert
	popq	%rbx			# Restore callee saved reg
	# End call string_convert
	movq	%rax, (%rsp)	# num = string_convert result
	movq	$0, %r13		# i = 0
	jmp		read_loop		# switch break

s_NUM2:
# TODO: Implement state
	jmp		read_loop		# switch break

s_EXP1:
	cmp		%r12, $41
	jne		EXP1_else 		# c == ')'
	movq	(%rsp), %rax	# Set return value
	jmp		epilogue_overloaded # Return num
EXP1_else:					# c != ')'
	movb	%r12b,-40(%rsp)	# Save operator
	movq	$0, %r13		# Reset i = 0
	movq	$s_OP, %r14		# state = OP
	jmp		read_loop		# switch break

s_EXP2:
	# Assuming c == ')'
	# This is actually the result (see s_OP)
	movq	(%rsp), %rax # Set return value
	jmp		epilogue_overloaded # return nu

s_OP:
	cmp		%r12, $40
	jne		OP_else 		# c == '('
	movq	$s_EXP2, %r14	# state = EXP2
	# TODO: recusive call and calc op
	jmp		read_loop 		# switch break
OP_else:					# c != '('
	movq	$s_NUM2, %r14	# state = NUM2
	jmp		read_loop		# switch break

	
	

epilogue_overloaded:
	movq	-24(%rsp), %r14
	movq	-16(%rsp), %r13
	movq	-8(%rsp), %r12
	leave
	ret






calc_expr:
	pushq %rbp
	movq %rsp, %rbp
	pushq %rsi # Backup result_as_string
	
	# %rdi already contains string_convert
	call calc_expr_overloaded

	movq %rax, %rdi # Move return value to be the first param
	popq %rsi
	call %rsi

epilogue_calc_expr:
	leave
	ret
