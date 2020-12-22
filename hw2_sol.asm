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
	cmp		$43, %dil
	jne		op_sub
	addq	%rdx, %rsi
	jmp		epilogue_calc_op
op_sub:
	cmp		$45, %dil
	jne		op_mult
	subq	%rdx, %rsi
	jmp		epilogue_calc_op
op_mult:
	cmp		$42, %dil
	jne		op_div
	imulq	%rdx, %rsi
	jmp		epilogue_calc_op
op_div:
	# Assuming cmp $47, %rsi bust be eq
	movq	%rsi, %rax
	movq	%rdx, %rdi
	movq	$1, %rcx
	imulq	%rcx
	idivq	%rdi
	movq	%rax, %rsi
	jmp		epilogue_calc_op
epilogue_calc_op:
	movq	%rsi, %rax # Move result to ret reg
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
	movb	(%rsi), %al # Set return value to the read character
	leave
	ret



calc_expr_overloaded:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$41, %rsp
	movq	%rdi, -8(%rbp) # Save string_convert until we need it
	# Calle saved
	movq	%r12, -16(%rbp)
	movq	%r13, -24(%rbp)
	movq	%r14, -32(%rbp)
	# op_char (rsp-40) === 1 bytes
	movq	$0, -40(%rbp) # num = 0

	# States: START = 0, NUM1 = 1, NUM2 = 2, EXP1 = 3, EXP2 = 4, OP = 5
	# r12 = c ; r13 = i; r14 = state # We only use LSByte of those
	movq $0, %r13	# i = 0
	movq $s_START, %r14	# state = 0

read_loop:
	# Read char
	movq	%r13, %rdi		# rdi = i
	addq	$num_buf, %rdi	# rdi = curr_cell_addr
	call	read_char
	movb	%al, %r12b		# c = new char
	movsbq	%r12b, %r12		# Sign extend characer
	leaq	1(%r13), %r13	# i++
	# switch(state)
	jmp		%r14			# Go to state
s_START:
	cmp		$40, %r12
	je		START_else		# if c != '(' # Assuming either a digit or a negsign
	movq	$s_NUM1, %r14	# state = NUM1
	jmp		read_loop		# switch break
START_else:					# if c == '('
	movq	$s_EXP1, %r14	# state = EXP1
	movq	-8(%rbp), %rdi # recover string_convert
	call	calc_expr_overloaded
	movq	%rax, -40(%rbp)	# num = recursion result
	jmp		read_loop		# switch break

s_NUM1:
	# Make sure '0' <= c <= '9'
	cmp		$48, %r12
	jl		NUM1_elif		# jmp if c < '0'
	cmp		$57, %r12
	jg		NUM1_elif		# c > '9'
	jmp		read_loop		# switch break
NUM1_elif:
	cmp		$41, %r12		# c == ')'
	jne		NUM1_else
	movq	$num_buf, %rdi	# rdi = num_buf
	movb	$0, -1(%rdi, %r13) # num_buf[i-1] = '\0'
	call	*-8(%rbp)		# Call string_convert(num_buf)
	# The string_convert return value is our return value
	# movq	%rax, %rax
	jmp		epilogue_overloaded
NUM1_else:
	# Assuming c in {-,+,*,/}
	movb	%r12b, -41(%rbp)	# op_char = c
	movq	$s_OP, %r14	# state = OP
	# Convert string to integer (64 bit)
	movq	$num_buf, %rdi	# rdi = num_buf
	movb	$0, -1(%rdi, %r13) # num_buf[i-1] = '\0'
	call	*-8(%rbp)		# Call string_convert(num_buf)
	# End call string_convert
	movq	%rax, -40(%rbp)	# num = string_convert result
	movq	$0, %r13		# i = 0
	jmp		read_loop		# switch break

s_NUM2:
	# Make sure '0' <= c <= '9'
	cmp		$41, %r12
	je		NUM2_else		# jmp if c == ')'
	jmp		read_loop		# switch break
NUM2_else:
	# Convert string to integer (64 bit)
	movq	$num_buf, %rdi	# rdi = num_buf
	movb	$0, -1(%rdi, %r13) # num_buf[i-1] = '\0'
	call	*-8(%rbp)		# Call string_convert(num_buf)
	# End call string_convert
	movb	-41(%rbp), %dil	# op_char is 1st param
	movq	-40(%rbp), %rsi	# num is 2nd param
	movq	%rax, %rdx		# string_convert result is 3rd param
	call	calc_op
	# result of calc_op is anyways the result of our call
	# movq	%rax, %rax
	jmp		epilogue_overloaded

s_EXP1:
	cmp		$41, %r12
	jne		EXP1_else 		# c == ')'
	movq	-40(%rbp), %rax	# Set return value
	jmp		epilogue_overloaded # Return num
EXP1_else:					# c != ')'
	movb	%r12b,-41(%rbp)	# Save operator
	movq	$0, %r13		# Reset i = 0
	movq	$s_OP, %r14		# state = OP
	jmp		read_loop		# switch break

s_EXP2:
	# Assuming c == ')'
	# This is actually the result (see s_OP)
	movq	-40(%rbp), %rax # Set return value
	jmp		epilogue_overloaded # return nu

s_OP:
	cmp		$40, %r12
	jne		OP_else 		# c == '('
	movq	$s_EXP2, %r14	# state = EXP2
	# Call recursively
	movq	-8(%rbp), %rdi	# Set
	call calc_expr_overloaded
	# End recursive call
	# Call calc_op
	movb	-41(%rbp), %dil	# op_char is the 1st param
	movq	-40(%rbp), %rsi	# num is the 2nd param
	movq	%rax, %rdx		# 3rd param is the recursive call
	call calc_op
	# End call calc_op
	movq	%rax, -40(%rbp)	# num = result
	jmp		read_loop 		# switch break
OP_else:					# c != '('
	movq	$s_NUM2, %r14	# state = NUM2
	jmp		read_loop		# switch break

epilogue_overloaded:
	movq	-16(%rbp), %r12
	movq	-24(%rbp), %r13
	movq	-32(%rbp), %r14
	leave
	ret


calc_expr:
	pushq	%rbp
	movq	%rsp, %rbp
	pushq	%rsi			# Backup result_as_string
	pushq	%rdi			# Backup string_convert
	movq	$num_buf, %rdi	# setup param for read_char
	call	read_char		# Read first char (should be '(')
	popq	%rdi			# Restore string_convert

	# %rdi already contains string_convert
	call	calc_expr_overloaded
	popq 	%rsi			# Restore result_as_string
	movq	%rax, %rdi		# Move return value to be the first param
	call	*%rsi

epilogue_calc_expr:
	leave
	ret
