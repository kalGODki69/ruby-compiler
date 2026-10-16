%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree_nodes.h"

extern int yylex(void);
extern int yylineno;
extern FILE *yyin;
void yyerror(const char *s);

Node *g_root = NULL;
%}

// Bison options
%locations
%define parse.error verbose
%defines
%expect 67

// YYSTYPE - union of all semantic value types
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
%token KW_TRUE KW_FALSE KW_NIL
%token KW_SELF KW_SUPER
%token KW_AND KW_OR KW_NOT
%token KW_BEGIN KW_RESCUE KW_ENSURE KW_RAISE
%token KW_CASE KW_WHEN KW_THEN
%token KW_PUTS KW_PRINT KW_P

// TERMINALS: LITERALS
%token <intval>   INT
%token <floatval> FLOAT
%token <strval>   STRING
%token <strval>   STRING_SQ
%token <strval>   SYMBOL
%token <strval>   ID
%token <strval>   IVAR
%token <strval>   CVAR
%token <strval>   GVAR
%token <strval>   CONSTANT

// TERMINALS: COMPOUND OPERATORS
%token OP_CASE_EQ
%token OP_CMP
%token OP_EQ
%token OP_NEQ
%token OP_LE
%token OP_GE
%token OP_POW
%token OP_PLUS_ASSIGN
%token OP_MINUS_ASSIGN
%token OP_MUL_ASSIGN
%token OP_DIV_ASSIGN
%token OP_LSHIFT
%token OP_RSHIFT
%token OP_AND
%token OP_OR
%token OP_RANGE_INC
%token OP_RANGE_EXC
%token OP_SCOPE
%token OP_HASH_ROCKET

// PRECEDENCE (from LOWEST to HIGHEST)
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

// NONTERMINAL TYPES
%type <node> program stmt_list stmt
%type <node> expr primary
%type <node> array_literal hash_literal hash_pairs hash_pair
%type <node> call_expr index_expr expr_list
%type <node> block block_params
%type <node> if_stmt elsif_list unless_stmt
%type <node> while_stmt until_stmt for_stmt
%type <node> def_stmt class_stmt module_stmt
%type <node> begin_rescue print_stmt param_list

%start program

%%

// PROGRAM
program
    : stmt_list                     { g_root = $1; $$ = $1; }
    ;

// STATEMENTS
stmt_list
    :                               { $$ = create_stmt_list_empty(); }
    | stmt_list stmt                { $$ = create_stmt_list_append($1, $2); }
    ;

stmt
    : expr                          { $$ = $1; }
    | KW_RETURN expr                { $$ = create_return($2); }
    | KW_BREAK                      { $$ = create_break(); }
    | KW_NEXT                       { $$ = create_next(); }
    | if_stmt                       { $$ = $1; }
    | unless_stmt                   { $$ = $1; }
    | while_stmt                    { $$ = $1; }
    | until_stmt                    { $$ = $1; }
    | for_stmt                      { $$ = $1; }
    | def_stmt                      { $$ = $1; }
    | class_stmt                    { $$ = $1; }
    | module_stmt                   { $$ = $1; }
    | begin_rescue                  { $$ = $1; }
    | print_stmt                    { $$ = $1; }
    ;

// IF / ELSIF / ELSE
if_stmt
    : KW_IF expr stmt_list KW_END
        { $$ = create_if($2, $3, NULL, NULL); }
    | KW_IF expr stmt_list KW_ELSE stmt_list KW_END
        { $$ = create_if($2, $3, NULL, $5); }
    | KW_IF expr stmt_list elsif_list KW_END
        { $$ = create_if($2, $3, $4, NULL); }
    | KW_IF expr stmt_list elsif_list KW_ELSE stmt_list KW_END
        { $$ = create_if($2, $3, $4, $6); }
    ;

elsif_list
    : KW_ELSIF expr stmt_list
        { $$ = create_elsif_single($2, $3); }
    | elsif_list KW_ELSIF expr stmt_list
        { $$ = $1; }
    ;

// UNLESS
unless_stmt
    : KW_UNLESS expr stmt_list KW_END
        { $$ = create_unless($2, $3, NULL); }
    | KW_UNLESS expr stmt_list KW_ELSE stmt_list KW_END
        { $$ = create_unless($2, $3, $5); }
    ;

// WHILE
while_stmt
    : KW_WHILE expr stmt_list KW_END
        { $$ = create_while($2, $3); }
    ;

// UNTIL
until_stmt
    : KW_UNTIL expr stmt_list KW_END
        { $$ = create_until($2, $3); }
    ;

// FOR
for_stmt
    : KW_FOR ID KW_IN expr stmt_list KW_END
        { $$ = create_for($2, $4, $5); }
    ;

// DEF
def_stmt
    : KW_DEF ID '(' param_list ')' stmt_list KW_END
        { $$ = create_def($2, $4, $6); }
    | KW_DEF ID '(' ')' stmt_list KW_END
        { $$ = create_def($2, NULL, $5); }
    | KW_DEF ID stmt_list KW_END
        { $$ = create_def($2, NULL, $3); }
    ;

param_list
    : ID                            { $$ = create_param_list_single($1); }
    | param_list ',' ID             { $$ = create_param_list_append($1, $3); }
    ;

// CLASS
class_stmt
    : KW_CLASS CONSTANT stmt_list KW_END
        { $$ = create_class($2, NULL, $3); }
    | KW_CLASS CONSTANT '<' CONSTANT stmt_list KW_END
        { $$ = create_class($2, $4, $5); }
    ;

// MODULE
module_stmt
    : KW_MODULE CONSTANT stmt_list KW_END
        { $$ = create_module($2, $3); }
    ;

// BEGIN / RESCUE / ENSURE
begin_rescue
    : KW_BEGIN stmt_list KW_END
        { $$ = create_begin_rescue($2, NULL, NULL); }
    | KW_BEGIN stmt_list KW_RESCUE stmt_list KW_END
        { $$ = create_begin_rescue($2, $4, NULL); }
    | KW_BEGIN stmt_list KW_RESCUE stmt_list KW_ENSURE stmt_list KW_END
        { $$ = create_begin_rescue($2, $4, $6); }
    | KW_BEGIN stmt_list KW_ENSURE stmt_list KW_END
        { $$ = create_begin_rescue($2, NULL, $4); }
    ;

// PRINT
print_stmt
    : KW_PUTS '(' expr ')'          { $$ = create_print(PRINT_PUTS, $3); }
    | KW_PRINT '(' expr ')'         { $$ = create_print(PRINT_PRINT, $3); }
    | KW_P '(' expr ')'             { $$ = create_print(PRINT_P, $3); }
    ;

// EXPRESSIONS
expr
    : primary                       { $$ = $1; }
    | expr '+' expr                 { $$ = create_binop(OPC_ADD, $1, $3); }
    | expr '-' expr                 { $$ = create_binop(OPC_SUB, $1, $3); }
    | expr '*' expr                 { $$ = create_binop(OPC_MUL, $1, $3); }
    | expr '/' expr                 { $$ = create_binop(OPC_DIV, $1, $3); }
    | expr '%' expr                 { $$ = create_binop(OPC_MOD, $1, $3); }
    | expr OP_POW expr              { $$ = create_binop(OPC_POW, $1, $3); }
    | expr OP_EQ expr               { $$ = create_binop(OPC_EQ, $1, $3); }
    | expr OP_NEQ expr              { $$ = create_binop(OPC_NEQ, $1, $3); }
    | expr '<' expr                 { $$ = create_binop(OPC_LT, $1, $3); }
    | expr '>' expr                 { $$ = create_binop(OPC_GT, $1, $3); }
    | expr OP_LE expr               { $$ = create_binop(OPC_LE, $1, $3); }
    | expr OP_GE expr               { $$ = create_binop(OPC_GE, $1, $3); }
    | expr OP_CMP expr              { $$ = create_binop(OPC_CMP, $1, $3); }
    | expr OP_CASE_EQ expr          { $$ = create_binop(OPC_CASE_EQ, $1, $3); }
    | expr OP_AND expr              { $$ = create_binop(OPC_AND, $1, $3); }
    | expr OP_OR expr               { $$ = create_binop(OPC_OR, $1, $3); }
    | expr KW_AND expr              { $$ = create_binop(OPC_KW_AND, $1, $3); }
    | expr KW_OR expr               { $$ = create_binop(OPC_KW_OR, $1, $3); }
    | '!' expr                      { $$ = create_unop(OPC_NOT, $2); }
    | KW_NOT expr                   { $$ = create_unop(OPC_KW_NOT, $2); }
    | '-' expr %prec UMINUS         { $$ = create_unop(OPC_NEG, $2); }
    | '+' expr %prec UMINUS         { $$ = create_unop(OPC_POS, $2); }
    | expr '?' expr ':' expr        { $$ = create_ternary($1, $3, $5); }
    | expr '=' expr                 { $$ = create_assign(OPC_ADD, $1, $3); }
    | expr OP_PLUS_ASSIGN expr      { $$ = create_assign(OPC_PLUS_ASSIGN, $1, $3); }
    | expr OP_MINUS_ASSIGN expr     { $$ = create_assign(OPC_MINUS_ASSIGN, $1, $3); }
    | expr OP_MUL_ASSIGN expr       { $$ = create_assign(OPC_MUL_ASSIGN, $1, $3); }
    | expr OP_DIV_ASSIGN expr       { $$ = create_assign(OPC_DIV_ASSIGN, $1, $3); }
    | expr OP_LSHIFT expr           { $$ = create_binop(OPC_LSHIFT, $1, $3); }
    | expr OP_RSHIFT expr           { $$ = create_binop(OPC_RSHIFT, $1, $3); }
    | expr '&' expr                 { $$ = create_binop(OPC_BITAND, $1, $3); }
    | expr '|' expr                 { $$ = create_binop(OPC_BITOR, $1, $3); }
    | expr '^' expr                 { $$ = create_binop(OPC_BITXOR, $1, $3); }
    | expr OP_RANGE_INC expr        { $$ = create_range(1, $1, $3); }
    | expr OP_RANGE_EXC expr        { $$ = create_range(0, $1, $3); }
    | '(' expr ')'                  { $$ = $2; }
    ;

// PRIMARY EXPRESSIONS
primary
    : INT                           { $$ = create_int($1); }
    | FLOAT                         { $$ = create_float($1); }
    | STRING                        { $$ = create_string($1); }
    | STRING_SQ                     { $$ = create_string_sq($1); }
    | SYMBOL                        { $$ = create_symbol($1); }
    | ID                            { $$ = create_id($1); }
    | IVAR                          { $$ = create_ivar($1); }
    | CVAR                          { $$ = create_cvar($1); }
    | GVAR                          { $$ = create_gvar($1); }
    | CONSTANT                      { $$ = create_constant($1); }
    | KW_TRUE                       { $$ = create_bool(1); }
    | KW_FALSE                      { $$ = create_bool(0); }
    | KW_NIL                        { $$ = create_nil(); }
    | KW_SELF                       { $$ = create_self(); }
    | array_literal                 { $$ = $1; }
    | hash_literal                  { $$ = $1; }
    | call_expr                     { $$ = $1; }
    | index_expr                    { $$ = $1; }
    ;

// ARRAYS
array_literal
    : '[' ']'                       { $$ = create_array(NULL, 0); }
    | '[' expr_list ']'             { $$ = create_array(NULL, 0); }
    ;

// HASHES
hash_literal
    : '{' '}'                       { $$ = create_hash(NULL, 0); }
    | '{' hash_pairs '}'            { $$ = create_hash(NULL, 0); }
    ;

hash_pairs
    : hash_pair                     { $$ = $1; }
    | hash_pairs ',' hash_pair      { $$ = $1; }
    ;

hash_pair
    : expr OP_HASH_ROCKET expr      { $$ = create_hash_pair($1, $3); }
    ;

// METHOD CALLS AND INDEXING
call_expr
    : ID '(' ')'                    { $$ = create_call(NULL, $1, NULL, NULL, 0); }
    | ID '(' expr_list ')'          { $$ = create_call(NULL, $1, $3, NULL, 0); }
    | ID block                      { $$ = create_call(NULL, $1, NULL, $2, 0); }
    | expr '.' ID                   { $$ = create_call($1, $3, NULL, NULL, 0); }
    | expr '.' ID '(' ')'           { $$ = create_call($1, $3, NULL, NULL, 0); }
    | expr '.' ID '(' expr_list ')' { $$ = create_call($1, $3, $5, NULL, 0); }
    | expr '.' ID block             { $$ = create_call($1, $3, NULL, $4, 0); }
    | expr OP_SCOPE ID              { $$ = create_call($1, $3, NULL, NULL, 1); }
    ;

index_expr
    : expr '[' expr ']'             { $$ = create_index($1, $3); }
    ;

expr_list
    : expr                          { $$ = $1; }
    | expr_list ',' expr            { $$ = $1; }
    ;

// BLOCKS
block
    : KW_DO stmt_list KW_END
        { $$ = create_block(NULL, $2, 0); }
    | KW_DO block_params stmt_list KW_END
        { $$ = create_block($2, $3, 0); }
    | '{' stmt_list '}'
        { $$ = create_block(NULL, $2, 1); }
    | '{' block_params stmt_list '}'
        { $$ = create_block($2, $3, 1); }
    ;

block_params
    : '|' '|'                       { $$ = create_block_params_empty(); }
    | '|' ID '|'                    { $$ = create_block_params_single($2); }
    | '|' param_list '|'            { $$ = $2; }
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