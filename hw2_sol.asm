.section .text
.global	calc_expr

calc_op:
	# >>> ord('+')
	# 43
	# >>> ord('-')
	# 45
	# >>> ord('*')
	# 42
	# >>> ord('/')
	# 47

	# rdi - op_char ; rsi - num1 ; rdx - num2
	pushq %rbp
	movq %rsp, %rbp
op_add:
	cmp $43, %rsi
	jne op_sub
	addq %rsi, %rdx
	jmp end_calc_op
op_sub:
	cmp $45, %rsi
	jne op_mult
	subq %rsi, %rdx
	jmp end_calc_op
op_mult:
	cmp $42, %rsi
	jne op_div
	imulq %rsi, %rdx
	jmp end_calc_op
op_div:
	# Assuming cmp $47, %rsi bust be eq
	idivq %rsi, %rdx
	jmp end_calc_op

	

epilogue_calc_op:
	movq %rdx, %rax # Move result to ret reg
	leave
	ret


calc_expr_overloaded:
	pushq %rbp
	movq %rsp, %rbp


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
