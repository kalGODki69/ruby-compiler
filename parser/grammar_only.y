%{
#include <stdio.h>
#include <stdlib.h>
void yyerror(const char *s);
%}

// Bison options
%define parse.error verbose
%defines
%expect 0

// YYSTYPE
%union {
    int          intval;
    double       floatval;
    char        *strval;
    struct Node *node;
}

// TERMINALS: KEYWORDS
%token KW_IF KW_ELSIF KW_ELSE KW_END
%token KW_UNLESS
%token KW_WHILE KW_UNTIL
%token KW_FOR KW_IN KW_DO
%token KW_DEF KW_CLASS KW_MODULE
%token KW_RETURN KW_YIELD
%token KW_BREAK KW_NEXT
%token KW_NIL
%token KW_SELF KW_SUPER
%token KW_AND KW_OR KW_NOT
%token KW_BEGIN KW_RESCUE KW_ENSURE KW_RAISE
%token KW_CASE KW_WHEN KW_THEN
%token ENDL

// TERMINALS: LITERALS
%token <intval>   INT
%token <intval>   BOOL
%token <floatval> FLOAT
%token <strval>   STRING
%token <strval>   SYMBOL
%token <strval>   ID
%token <strval>   IVAR
%token <strval>   CVAR
%token <strval>   GVAR
%token <strval>   CONSTANT

// TERMINALS: COMPOUND OPERATORS
%token OP_CASE_EQ OP_CMP OP_EQ OP_NEQ OP_LE OP_GE OP_POW
%token OP_PLUS_ASSIGN OP_MINUS_ASSIGN OP_MUL_ASSIGN OP_DIV_ASSIGN
%token OP_LSHIFT OP_RSHIFT OP_AND OP_OR
%token OP_RANGE_INC OP_RANGE_EXC OP_SCOPE OP_HASH_ROCKET

// PRECEDENCE
%right '=' OP_PLUS_ASSIGN OP_MINUS_ASSIGN OP_MUL_ASSIGN OP_DIV_ASSIGN
%left KW_AND KW_OR
%right KW_NOT
%right '?' ':'
%left OP_RANGE_INC OP_RANGE_EXC
%left OP_OR
%left OP_AND
%nonassoc OP_EQ OP_NEQ OP_CMP OP_CASE_EQ
%nonassoc '<' '>' OP_LE OP_GE
%left '|'
%left '^'
%left '&'
%left OP_LSHIFT OP_RSHIFT
%left '+' '-'
%left '*' '/' '%'
%right UMINUS
%right OP_POW
%left '.' OP_SCOPE
%left '[' ']'
%nonassoc ')'

// NONTERMINAL TYPES (kept for completeness, but not used without actions)
%type <node> program stmt_list stmt
%type <node> expr primary
%type <node> array_literal hash_literal hash_pairs hash_pair
%type <node> call_expr expr_list
%type <node> block block_params
%type <node> if_stmt elsif_list unless_stmt
%type <node> while_stmt until_stmt for_stmt
%type <node> def_stmt class_stmt module_stmt
%type <node> begin_rescue param_list

%start program

%%

// PROGRAM
program
    : stmt_list
    ;

// STATEMENTS
stmt_list
    : /* empty */
    | stmt
    | stmt_list ENDL stmt
    | stmt_list ENDL
    ;

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
    ;

// IF
if_stmt
    : KW_IF expr ENDL stmt_list KW_END
    | KW_IF expr ENDL stmt_list KW_ELSE ENDL stmt_list KW_END
    | KW_IF expr ENDL stmt_list elsif_list KW_END
    | KW_IF expr ENDL stmt_list elsif_list KW_ELSE ENDL stmt_list KW_END
    ;

elsif_list
    : KW_ELSIF expr ENDL stmt_list
    | elsif_list KW_ELSIF expr ENDL stmt_list
    ;

// UNLESS
unless_stmt
    : KW_UNLESS expr ENDL stmt_list KW_END
    | KW_UNLESS expr ENDL stmt_list KW_ELSE ENDL stmt_list KW_END
    ;

// WHILE
while_stmt
    : KW_WHILE expr ENDL stmt_list KW_END
    ;

// UNTIL
until_stmt
    : KW_UNTIL expr ENDL stmt_list KW_END
    ;

// FOR
for_stmt
    : KW_FOR ID KW_IN expr ENDL stmt_list KW_END
    ;

// DEF
def_stmt
    : KW_DEF ID '(' param_list ')' ENDL stmt_list KW_END
    | KW_DEF ID '(' ')' ENDL stmt_list KW_END
    | KW_DEF ID ENDL stmt_list KW_END
    ;

param_list
    : ID
    | param_list ',' ID
    ;

// CLASS
class_stmt
    : KW_CLASS CONSTANT ENDL stmt_list KW_END
    | KW_CLASS CONSTANT '<' CONSTANT ENDL stmt_list KW_END
    ;

// MODULE
module_stmt
    : KW_MODULE CONSTANT ENDL stmt_list KW_END
    ;

// BEGIN
begin_rescue
    : KW_BEGIN ENDL stmt_list KW_END
    | KW_BEGIN ENDL stmt_list KW_RESCUE ENDL stmt_list KW_END
    | KW_BEGIN ENDL stmt_list KW_RESCUE ENDL stmt_list KW_ENSURE ENDL stmt_list KW_END
    | KW_BEGIN ENDL stmt_list KW_ENSURE ENDL stmt_list KW_END
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
    | expr '[' expr ']'
    | '(' expr ')'
    ;

// PRIMARY
primary
    : INT
    | FLOAT
    | STRING
    | SYMBOL
    | ID
    | IVAR
    | CVAR
    | GVAR
    | CONSTANT
    | BOOL
    | KW_NIL
    | KW_SELF
    | array_literal
    | hash_literal
    | call_expr
    ;

// ARRAYS
array_literal
    : '[' ']'
    | '[' expr_list ']'
    ;

// HASHES
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

// CALLS
call_expr
    : ID '(' ')'
    | ID '(' expr_list ')'
    | ID block
    | expr '.' ID
    | expr '.' ID '(' ')'
    | expr '.' ID '(' expr_list ')'
    | expr '.' ID block
    | expr OP_SCOPE ID
    | expr OP_SCOPE ID '(' ')'
    | expr OP_SCOPE ID '(' expr_list ')'
    ;

expr_list
    : expr
    | expr_list ',' expr
    ;

// BLOCKS
block
    : KW_DO ENDL stmt_list KW_END
    | KW_DO block_params ENDL stmt_list KW_END
    | '{' stmt_list '}'
    | '{' block_params stmt_list '}'
    ;

block_params
    : '|' '|'
    | '|' param_list '|'
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error: %s\n", s);
}