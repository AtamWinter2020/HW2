#include <stdio.h>
#include <stdlib.h>
#define MAX_LEN 100
#define MAX_LONG_LONG 27

/*
 * This variable will not change.
 */
char what_to_print[MAX_LEN];

long long calc_op(char op_char, long long num1, long long num2) {
    switch (op_char) {
        case '+':
            return num1 + num2;
        case '-':
            return num1 - num2;
        case '*':
            return num1 * num2;
        case '/':
            return num1 / num2;
    }
}
typedef enum { START, NUM1, NUM2, EXP1, EXP2, OP } State;
char buff[MAX_LONG_LONG];

long long calc_expr_overloaded(long long (*string_convert)(char *)) {
    char c, op_char;
    long long num = 0;
    short i = 0;  // can be a single byte
    State state = START;

    while ((buff[i++] = c = getchar()) != '\n') {
        switch (state) {
            case START:
                if ((c <= '9' && c >= '0') || c == '-')
                    state = NUM1;
                else {
                    // Assuming c=='('
                    state = EXP1;
                    num = calc_expr_overloaded(string_convert);
                    i = 0;
                }
                break;
            case NUM1:
                if (c <= '9' && c >= '0')
                    ;
                else if (c == ')') {
                    buff[i - 1] = '\0';
                    return string_convert(buff);
                } else {
                    // Assuming c in {-,+,*,/}
                    op_char = c;
                    state = OP;
                    buff[i - 1] = '\0';
                    num = string_convert(buff);
                    i = 0;
                }
                break;
            case NUM2:
                if (c <= '9' && c >= '0')
                    ;
                else {
                    // Assuming c==')'
                    buff[i - 1] = '\0';
                    return calc_op(op_char, num, string_convert(buff));
                }
                break;
            case EXP1:
                if (c == ')') {
                    return num;
                } else {
                    // Assuming c in {-,+,*,/}
                    op_char = c;
                }
                i = 0;
                state = OP;
                break;
            case EXP2:
                // Assuming c == ')'
                // This is actually the result (see state OP)
                return num;
            case OP:
                if (c == '(') {
                    state = EXP2;
                    num = calc_op(op_char, num,
                                    calc_expr_overloaded(string_convert));
                } else {
                    // Assuming a start of a number
                    state = NUM2;
                }
                break;
        }
    }
    // If it reached here, there's an error
    return -1;
}

void calc_expr(long long (*string_convert)(char *),
               int (*result_as_string)(long long)) {
    getchar();  // Assuming '('
    long long num = calc_expr_overloaded(string_convert);
    getchar();  // Assuming '\n'
    result_as_string(num);
}

/*
 * This is an example for an implementation of string_convert(char* num).
 * BE CAREFUL - this implementation can be different in other tests.
 * The function declaration will (of course) always be the same and the return
 * value will always be the conversion of the string num into a 10 base
 * representation long long variable.
 */
long long string_convert(char *num) { return strtol(num, NULL, 10); }

/*
 * This is an example for an implementation of result_as_string(long long num).
 * BE CAREFUL - this implementation can be different in other tests.
 * The function declaration will (of course) always be the same and the return
 * value will always be the length of the string that was copied into
 * 'what_to_print'
 */
int result_as_string(long long num) {
    return snprintf(what_to_print, MAX_LEN, "Result is: %lld\n", num);
}

int main() {
    calc_expr(&string_convert, &result_as_string);
    printf("%s", what_to_print);
    return 0;
}