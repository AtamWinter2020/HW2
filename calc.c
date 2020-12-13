#include <stdio.h>
#include <stdlib.h>
#define MAX_LEN 100
#define MAX_LONG_LONG 27

void calc_expr(long long (*string_convert)(char*), int (*result_as_string)(long long));

/*
 * This variable will not change.
 */
char what_to_print[MAX_LEN];
typedef enum {START,NUM1, NUM2, EXP1, EXP2, OP} State;

long long calc_expr(long long (*string_convert)(char*), int (*result_as_string)(long long)){
    char c;
    long long first = 0, second = 0;
    short i = 0; // can be a single byte
    char buff[MAX_LONG_LONG];
    State state = start;

    while((buff[i++]=c=getchar()){
        switch(state){
            case START:
            if(((buff[i++]=c=getchar()) <= '9' && c >= '0') || c == '-') state=NUM1;
            else {
                // Assuming c=='('
                state = EXP1;
                first = calc_expr(string_convert, result_as_string);
                i = 0;
            }
            break;
            case NUM1:
            if(((buff[i++]=c=getchar()) <= '9' && c >= '0'));
            else if(c == ')'){
                buff[i-1] = '\0';
                return string_convert(buff);
            }else{
                // Assuming c in {-,+,*,/}
                state = OP;
                buff[i-1] = '\0';
                first = string_convert(buff);
                i = 0;
            }
            break;
            case NUM2:
            if(((buff[i++]=c=getchar()) <= '9' && c >= '0'));
            else{
                // Assuming c=='('
                buff[i-1] = '\0';
                return first + string_convert(buff); // TODO: Make compatible with any operator
            }
            break;
            case EXP1:
            first = calc_expr(string_convert, result_as_string);
            if ((c=getchar()) == ')'){
                return first;
            }else{
                // TODO: Save operator
            }
            i = 0;
            state = OP;
            break;
            case EXP2:
            second = calc_expr(string_convert, result_as_string);
            assert ((buff[i++]=c=getchar()) == ')');
            // TODO: Support all the operators
            return first + second;
            case OP:
            i = 0;
            if((buff[i++]=c=getchar()) == '('){
                state = EXP2;
            }else{
                // Assuming a start of a number
                state = NUM2;
            }
            break;
        }
    }
}

/*
 * This is an example for an implementation of string_convert(char* num).
 * BE CAREFUL - this implementation can be different in other tests.
 * The function declaration will (of course) always be the same and the return value will always be the conversion of
 * the string num into a 10 base representation long long variable.
 */
long long string_convert(char* num) {
    return strtol(num, NULL, 10);
}

/*
 * This is an example for an implementation of result_as_string(long long num).
 * BE CAREFUL - this implementation can be different in other tests.
 * The function declaration will (of course) always be the same and the return value will always be the length
 * of the string that was copied into 'what_to_print'
 */
int result_as_string(long long num) {
    return snprintf(what_to_print, MAX_LEN, "Result is: %lld\n", num);
}

int main() {
    calc_expr(&string_convert, &result_as_string);
    return 0;
}