%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex(void);
extern int yylineno;
void yyerror(const char *s);
%}

// Bison options
%locations
%define parse.error verbose
%defines
%expect 67

// TERMINALS: KEYWORDS
%token KW_IF KW_ELSIF KW_ELSE KW_END
%token KW_UNLESS
%token KW_WHILE KW_UNTIL
%token KW_FOR KW_IN KW_DO
%token KW_DEF KW_CLASS KW_MODULE
%token KW_RETURN KW_YIELD
%token KW_BREAK KW_NEXT
%token KW_TRUE KW_FALSE KW_NIL
%token KW_SELF KW_SUPER
%token KW_AND KW_OR KW_NOT
%token KW_BEGIN KW_RESCUE KW_ENSURE KW_RAISE
%token KW_CASE KW_WHEN KW_THEN
%token KW_PUTS KW_PRINT KW_P

// TERMINALS: LITERALS
%token INT
%token FLOAT
%token STRING
%token STRING_SQ
%token SYMBOL
%token ID
%token IVAR
%token CVAR
%token GVAR
%token CONSTANT

// TERMINALS: COMPOUND OPERATORS
%token OP_CASE_EQ       // ===
%token OP_CMP           // <=>
%token OP_EQ            // ==
%token OP_NEQ           // !=
%token OP_LE            // <=
%token OP_GE            // >=
%token OP_POW           // **
%token OP_PLUS_ASSIGN   // +=
%token OP_MINUS_ASSIGN  // -=
%token OP_MUL_ASSIGN    // *=
%token OP_DIV_ASSIGN    // /=
%token OP_LSHIFT        // <<
%token OP_RSHIFT        // >>
%token OP_AND           // &&
%token OP_OR            // ||
%token OP_RANGE_INC     // ..
%token OP_RANGE_EXC     // ...
%token OP_SCOPE         // ::
%token OP_HASH_ROCKET   // =>

// PRECEDENCE AND ASSOCIATIVITY (from LOWEST to HIGHEST)

// 1. Assignment - right associative
%right '=' OP_PLUS_ASSIGN OP_MINUS_ASSIGN OP_MUL_ASSIGN OP_DIV_ASSIGN

// 2. Logical and/or/not
%left KW_AND KW_OR
%right KW_NOT

// 3. Ternary operator - right associative
%right '?' ':'

// 4. Ranges - left associative
%left OP_RANGE_INC OP_RANGE_EXC

// 5. Logical OR
%left OP_OR

// 6. Logical AND
%left OP_AND

// 7. Comparisons - non-associative
%nonassoc OP_EQ OP_NEQ OP_CMP OP_CASE_EQ
%nonassoc '<' '>' OP_LE OP_GE

// 8. Bitwise operations
%left '|'
%left '^'
%left '&'

// 9. Shifts
%left OP_LSHIFT OP_RSHIFT

// 10. Low-priority arithmetic
%left '+' '-'

// 11. High-priority arithmetic
%left '*' '/' '%'

// 12. Unary minus (pseudo-token)
%right UMINUS

// 13. Exponentiation - right associative
%right OP_POW

// 14. Postfix operators: dot and :: - LEFT associative
%left '.' OP_SCOPE

// 15. Square brackets - also LEFT associative
%left '[' ']'

// 16. Closing parenthesis - non-associative
%nonassoc ')'

// START SYMBOL
%start program

%%

// PROGRAM - sequence of statements
program
    : stmt_list
    ;

stmt_list
    : // empty
    | stmt_list stmt
    ;

// STATEMENTS
stmt
    : expr
    | KW_RETURN expr
    | KW_BREAK
    | KW_NEXT
    | if_stmt
    | unless_stmt
    | while_stmt
    | until_stmt
    | for_stmt
    | def_stmt
    | class_stmt
    | module_stmt
    | begin_rescue
    | print_stmt
    ;

// if / elsif / else
if_stmt
    : KW_IF expr stmt_list KW_END
    | KW_IF expr stmt_list KW_ELSE stmt_list KW_END
    | KW_IF expr stmt_list elsif_list KW_END
    | KW_IF expr stmt_list elsif_list KW_ELSE stmt_list KW_END
    ;

elsif_list
    : KW_ELSIF expr stmt_list
    | elsif_list KW_ELSIF expr stmt_list
    ;

// unless
unless_stmt
    : KW_UNLESS expr stmt_list KW_END
    | KW_UNLESS expr stmt_list KW_ELSE stmt_list KW_END
    ;

// while
while_stmt
    : KW_WHILE expr stmt_list KW_END
    ;

// until
until_stmt
    : KW_UNTIL expr stmt_list KW_END
    ;

// for
for_stmt
    : KW_FOR ID KW_IN expr stmt_list KW_END
    ;

// def
def_stmt
    : KW_DEF ID '(' param_list ')' stmt_list KW_END
    | KW_DEF ID '(' ')' stmt_list KW_END
    | KW_DEF ID stmt_list KW_END
    ;

param_list
    : ID
    | param_list ',' ID
    ;

// class / module
class_stmt
    : KW_CLASS CONSTANT stmt_list KW_END
    | KW_CLASS CONSTANT '<' CONSTANT stmt_list KW_END
    ;

module_stmt
    : KW_MODULE CONSTANT stmt_list KW_END
    ;

// begin / rescue / ensure
begin_rescue
    : KW_BEGIN stmt_list KW_END
    | KW_BEGIN stmt_list KW_RESCUE stmt_list KW_END
    | KW_BEGIN stmt_list KW_RESCUE stmt_list KW_ENSURE stmt_list KW_END
    | KW_BEGIN stmt_list KW_ENSURE stmt_list KW_END
    ;

// puts / print / p
print_stmt
    : KW_PUTS '(' expr ')'
    | KW_PRINT '(' expr ')'
    | KW_P '(' expr ')'
    ;

// EXPRESSIONS
expr
    : primary
    | expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
    | expr '%' expr
    | expr OP_POW expr
    | expr OP_EQ expr
    | expr OP_NEQ expr
    | expr '<' expr
    | expr '>' expr
    | expr OP_LE expr
    | expr OP_GE expr
    | expr OP_CMP expr
    | expr OP_CASE_EQ expr
    | expr OP_AND expr
    | expr OP_OR expr
    | expr KW_AND expr
    | expr KW_OR expr
    | '!' expr
    | KW_NOT expr
    | '-' expr %prec UMINUS
    | '+' expr %prec UMINUS
    | expr '?' expr ':' expr
    | expr '=' expr
    | expr OP_PLUS_ASSIGN expr
    | expr OP_MINUS_ASSIGN expr
    | expr OP_MUL_ASSIGN expr
    | expr OP_DIV_ASSIGN expr
    | expr OP_LSHIFT expr
    | expr OP_RSHIFT expr
    | expr '&' expr
    | expr '|' expr
    | expr '^' expr
    | expr OP_RANGE_INC expr
    | expr OP_RANGE_EXC expr
    | '(' expr ')'
    ;

// primary expressions
primary
    : INT
    | FLOAT
    | STRING
    | STRING_SQ
    | SYMBOL
    | ID
    | IVAR
    | CVAR
    | GVAR
    | CONSTANT
    | KW_TRUE
    | KW_FALSE
    | KW_NIL
    | KW_SELF
    | array_literal
    | hash_literal
    | call_expr
    | index_expr
    ;

// literals
array_literal
    : '[' ']'
    | '[' expr_list ']'
    ;

hash_literal
    : '{' '}'
    | '{' hash_pairs '}'
    ;

hash_pairs
    : hash_pair
    | hash_pairs ',' hash_pair
    ;

hash_pair
    : expr OP_HASH_ROCKET expr
    ;

// method calls and indexing
call_expr
    : ID '(' ')'
    | ID '(' expr_list ')'
    | ID block
    | expr '.' ID
    | expr '.' ID '(' ')'
    | expr '.' ID '(' expr_list ')'
    | expr '.' ID block
    | expr OP_SCOPE ID
    ;

index_expr
    : expr '[' expr ']'
    ;

expr_list
    : expr
    | expr_list ',' expr
    ;

// blocks: do...end and {...}
block
    : KW_DO stmt_list KW_END
    | KW_DO block_params stmt_list KW_END
    | '{' stmt_list '}'
    | '{' block_params stmt_list '}'
    ;

block_params
    : '|' '|'
    | '|' ID '|'
    | '|' param_list '|'
    ;

%%

// ERROR HANDLING
void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n",
            yylloc.first_line, s);
}

// ENTRY POINT
int main(int argc, char **argv) {
    if (argc > 1) {
        extern FILE *yyin;
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror(argv[1]);
            return 1;
        }
    }
    int result = yyparse();
    if (yyin) fclose(yyin);
    return result;
}