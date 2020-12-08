# High-Level Plan

* Get Input expression from stdin
* Checks if expression is empty (includes only '\n')
    * In case expression is empty, set return value to 0 and jump to FINISH
    * else continue
* While (expression is not empty)
    * Parse expression (deepest sub-expression)
    * Calculate the result
* Set return value
* FINISH: call print functions

# Pseudo Code
>value_to_return = 0  
expression = get_line_from_stdin()  
if is_empty(expression): jump FINISH

>while not is_empty(expression):
>>deepest_exp = get_deepest_expression(expression)  
operand1, operand2, op = parse_expression(deepest_exp)  
result = calc(operand1, operand2, op)
> 
> FINISH: 
> output_to_stdout(what_to_print)

