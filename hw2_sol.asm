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


read_char:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	%rdi, %rsi	# Address to read to -> %rdi
	movq	$0, %rdi	# 0 = stdin
	movq	$1, %rdx	# Read 1 byte
	leave
	ret



calc_expr_overloaded:
	pushq	%rbp
	movq	%rsp, %rbp
	# bytes: c(-11), op_char(-10), i(-9), state(-8)	=== 4 bytes
	# 8 bytes (long long): num(0)					=== 8 bytes
	subq	$12, %rsp
	movq	$0, (%rsp) # num = 0
	# States: START = 0, NUM1 = 1, NUM2 = 2, EXP1 = 3, EXP2 = 4, OP = 5
	movw	$0, -8(%rsp) # i = state = 0
	
	

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
