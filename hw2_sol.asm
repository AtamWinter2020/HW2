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
	pushq %rdi # backup: string_convert(-9)
	# bytes: op_char(-9)			=== 1 bytes
	# 8 bytes (long long): num(0)	=== 8 bytes
	subq	$9, %rsp
	movq	$0, (%rsp) # num = 0
	# States: START = 0, NUM1 = 1, NUM2 = 2, EXP1 = 3, EXP2 = 4, OP = 5
	# r8 = c ; r9 = i; r10 = state # We only use LSByte of those
	movq $0, %r9	# i = 0
	movq $0, %r10	# state = 0

read_loop:
	# Read char
	movq	-9(%rsp), %rdi # rdi = i
	addq	$buf, %rdi # rdi = curr_cell_addr
	call read_char
	# switch(state)
state_START:
	cmp		%r10b, $0
	jne		state_NUM1
# TODO: Implement state
	jmp		read_loop		# switch break
state_NUM1:
	cmp		%r10b, $1
	jne		state_NUM2
# TODO: Implement state
	jmp		read_loop		# switch break

state_NUM2:
	cmp		%r10b, $2
	jne		state_EXP1
# TODO: Implement state
	jmp		read_loop		# switch break

state_EXP1:
	cmp		%r10b, $3		# state == this
	jne		state_EXP2
	cmp		%r8, $41
	jne		EXP1_else 		# c == ')'
	movq	(%rsp), %rax	# Set return value
	jmp		epilogue_calc_expr # Return num
EXP1_else:					# c != ')'
	movb	%r8b, -9(%rsp)	# Save operator
	movq	$0, %r9			# Reset i = 0
	movq	$5, %r10		# state = OP
	jmp		read_loop		# switch break

state_EXP2:
	# Assuming c == ')'
	# This is actually the result (see state_OP)
	cmp		%r10b, $4		# state == this
	jne		state_OP
	movq	(%rsp), %rax # Set return value
	jmp		epilogue_overloaded # return num
state_OP:
	# cmp	%r10b, $5		# state == this # Must happen
	cmp		%r8, $40
	jne		OP_else 		# c == '('
	movq	$4, %r10		# state = EXP2
	# TODO: recusive call and calc op
	jmp		read_loop 		# switch break
OP_else:					# c != '('
	movq	$2, %r10		# state = NUM2
	jmp		read_loop		# switch break

	
	

epilogue_overloaded:

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
