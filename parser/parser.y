%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree_nodes.h"

extern int yylex(void);
extern int yylineno;
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
    | expr '+' expr                 { $$ = create_binop(OP_ADD, $1, $3); }
    | expr '-' expr                 { $$ = create_binop(OP_SUB, $1, $3); }
    | expr '*' expr                 { $$ = create_binop(OP_MUL, $1, $3); }
    | expr '/' expr                 { $$ = create_binop(OP_DIV, $1, $3); }
    | expr '%' expr                 { $$ = create_binop(OP_MOD, $1, $3); }
    | expr OP_POW expr              { $$ = create_binop(OP_POW, $1, $3); }
    | expr OP_EQ expr               { $$ = create_binop(OP_EQ, $1, $3); }
    | expr OP_NEQ expr              { $$ = create_binop(OP_NEQ, $1, $3); }
    | expr '<' expr                 { $$ = create_binop(OP_LT, $1, $3); }
    | expr '>' expr                 { $$ = create_binop(OP_GT, $1, $3); }
    | expr OP_LE expr               { $$ = create_binop(OP_LE, $1, $3); }
    | expr OP_GE expr               { $$ = create_binop(OP_GE, $1, $3); }
    | expr OP_CMP expr              { $$ = create_binop(OP_CMP, $1, $3); }
    | expr OP_CASE_EQ expr          { $$ = create_binop(OP_CASE_EQ, $1, $3); }
    | expr OP_AND expr              { $$ = create_binop(OP_AND, $1, $3); }
    | expr OP_OR expr               { $$ = create_binop(OP_OR, $1, $3); }
    | expr KW_AND expr              { $$ = create_binop(OP_KW_AND, $1, $3); }
    | expr KW_OR expr               { $$ = create_binop(OP_KW_OR, $1, $3); }
    | '!' expr                      { $$ = create_unop(OP_NOT, $2); }
    | KW_NOT expr                   { $$ = create_unop(OP_KW_NOT, $2); }
    | '-' expr %prec UMINUS         { $$ = create_unop(OP_NEG, $2); }
    | '+' expr %prec UMINUS         { $$ = create_unop(OP_POS, $2); }
    | expr '?' expr ':' expr        { $$ = create_ternary($1, $3, $5); }
    | expr '=' expr                 { $$ = create_assign(OP_ADD, $1, $3); }
    | expr OP_PLUS_ASSIGN expr      { $$ = create_assign(OP_PLUS_ASSIGN, $1, $3); }
    | expr OP_MINUS_ASSIGN expr     { $$ = create_assign(OP_MINUS_ASSIGN, $1, $3); }
    | expr OP_MUL_ASSIGN expr       { $$ = create_assign(OP_MUL_ASSIGN, $1, $3); }
    | expr OP_DIV_ASSIGN expr       { $$ = create_assign(OP_DIV_ASSIGN, $1, $3); }
    | expr OP_LSHIFT expr           { $$ = create_binop(OP_LSHIFT, $1, $3); }
    | expr OP_RSHIFT expr           { $$ = create_binop(OP_RSHIFT, $1, $3); }
    | expr '&' expr                 { $$ = create_binop(OP_BITAND, $1, $3); }
    | expr '|' expr                 { $$ = create_binop(OP_BITOR, $1, $3); }
    | expr '^' expr                 { $$ = create_binop(OP_BITXOR, $1, $3); }
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
    | '[' expr_list ']'             { $$ = create_array((Node **)&($2), 0); }
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

// NODE CREATION HELPERS

static void *xmalloc(size_t size) {
    void *p = malloc(size);
    if (!p) {
        fprintf(stderr, "Out of memory\n");
        exit(1);
    }
    memset(p, 0, size);
    return p;
}

static char *xstrdup(const char *s) {
    if (!s) return NULL;
    char *p = (char *)xmalloc(strlen(s) + 1);
    strcpy(p, s);
    return p;
}

// LITERALS

Node *create_int(int value) {
    NInt *n = (NInt *)xmalloc(sizeof(NInt));
    n->base.type = N_INT;
    n->base.line = yylloc.first_line;
    n->value = value;
    return (Node *)n;
}

Node *create_float(double value) {
    NFloat *n = (NFloat *)xmalloc(sizeof(NFloat));
    n->base.type = N_FLOAT;
    n->base.line = yylloc.first_line;
    n->value = value;
    return (Node *)n;
}

Node *create_string(char *value) {
    NString *n = (NString *)xmalloc(sizeof(NString));
    n->base.type = N_STRING;
    n->base.line = yylloc.first_line;
    n->value = xstrdup(value);
    free(value);
    return (Node *)n;
}

Node *create_string_sq(char *value) {
    NString *n = (NString *)xmalloc(sizeof(NString));
    n->base.type = N_STRING_SQ;
    n->base.line = yylloc.first_line;
    n->value = xstrdup(value);
    free(value);
    return (Node *)n;
}

Node *create_symbol(char *value) {
    NSymbol *n = (NSymbol *)xmalloc(sizeof(NSymbol));
    n->base.type = N_SYMBOL;
    n->base.line = yylloc.first_line;
    n->value = xstrdup(value);
    free(value);
    return (Node *)n;
}

Node *create_bool(int value) {
    Node *n = (Node *)xmalloc(sizeof(Node));
    n->type = value ? N_TRUE : N_FALSE;
    n->line = yylloc.first_line;
    return n;
}

Node *create_nil(void) {
    Node *n = (Node *)xmalloc(sizeof(Node));
    n->type = N_NIL;
    n->line = yylloc.first_line;
    return n;
}

Node *create_self(void) {
    Node *n = (Node *)xmalloc(sizeof(Node));
    n->type = N_SELF;
    n->line = yylloc.first_line;
    return n;
}

// IDENTIFIERS

static Node *create_id_node(NodeType t, char *name) {
    NId *n = (NId *)xmalloc(sizeof(NId));
    n->base.type = t;
    n->base.line = yylloc.first_line;
    n->name = xstrdup(name);
    free(name);
    return (Node *)n;
}

Node *create_id(char *name)       { return create_id_node(N_ID, name); }
Node *create_ivar(char *name)     { return create_id_node(N_IVAR, name); }
Node *create_cvar(char *name)     { return create_id_node(N_CVAR, name); }
Node *create_gvar(char *name)     { return create_id_node(N_GVAR, name); }
Node *create_constant(char *name) { return create_id_node(N_CONSTANT, name); }

// EXPRESSIONS

Node *create_binop(OpCode op, Node *lhs, Node *rhs) {
    NBinOp *n = (NBinOp *)xmalloc(sizeof(NBinOp));
    n->base.type = N_BINOP;
    n->base.line = yylloc.first_line;
    n->op = op;
    n->lhs = lhs;
    n->rhs = rhs;
    return (Node *)n;
}

Node *create_unop(OpCode op, Node *operand) {
    NUnOp *n = (NUnOp *)xmalloc(sizeof(NUnOp));
    n->base.type = N_UNOP;
    n->base.line = yylloc.first_line;
    n->op = op;
    n->operand = operand;
    return (Node *)n;
}

Node *create_ternary(Node *cond, Node *then_e, Node *else_e) {
    NTernary *n = (NTernary *)xmalloc(sizeof(NTernary));
    n->base.type = N_TERNARY;
    n->base.line = yylloc.first_line;
    n->cond = cond;
    n->then_expr = then_e;
    n->else_expr = else_e;
    return (Node *)n;
}

Node *create_assign(OpCode op, Node *target, Node *value) {
    NAssign *n = (NAssign *)xmalloc(sizeof(NAssign));
    n->base.type = N_ASSIGN;
    n->base.line = yylloc.first_line;
    n->op = op;
    n->target = target;
    n->value = value;
    return (Node *)n;
}

Node *create_range(int inclusive, Node *from, Node *to) {
    NRange *n = (NRange *)xmalloc(sizeof(NRange));
    n->base.type = N_RANGE;
    n->base.line = yylloc.first_line;
    n->inclusive = inclusive;
    n->from = from;
    n->to = to;
    return (Node *)n;
}

// COLLECTIONS

Node *create_array(Node **items, int count) {
    NArray *n = (NArray *)xmalloc(sizeof(NArray));
    n->base.type = N_ARRAY;
    n->base.line = yylloc.first_line;
    n->items = items;
    n->count = count;
    return (Node *)n;
}

Node *create_hash(Node **pairs, int count) {
    NHash *n = (NHash *)xmalloc(sizeof(NHash));
    n->base.type = N_HASH;
    n->base.line = yylloc.first_line;
    n->pairs = pairs;
    n->count = count;
    return (Node *)n;
}

Node *create_hash_pair(Node *key, Node *value) {
    NHashPair *n = (NHashPair *)xmalloc(sizeof(NHashPair));
    n->base.type = N_HASH_PAIR;
    n->base.line = yylloc.first_line;
    n->key = key;
    n->value = value;
    return (Node *)n;
}

Node *create_index(Node *object, Node *index) {
    NIndex *n = (NIndex *)xmalloc(sizeof(NIndex));
    n->base.type = N_INDEX;
    n->base.line = yylloc.first_line;
    n->object = object;
    n->index = index;
    return (Node *)n;
}

// CALLS

Node *create_call(Node *receiver, char *method, Node *args, Node *block, int scope_op) {
    NCall *n = (NCall *)xmalloc(sizeof(NCall));
    n->base.type = N_CALL;
    n->base.line = yylloc.first_line;
    n->receiver = receiver;
    n->method = xstrdup(method);
    free(method);
    n->args = args;
    n->block = block;
    n->scope_op = scope_op;
    return (Node *)n;
}

Node *create_arg_list(Node *first) {
    NArgList *n = (NArgList *)xmalloc(sizeof(NArgList));
    n->base.type = N_ARG_LIST;
    n->base.line = yylloc.first_line;
    n->items = (Node **)xmalloc(sizeof(Node *));
    n->items[0] = first;
    n->count = 1;
    return (Node *)n;
}

Node *create_arg_list_append(Node *list, Node *item) {
    NArgList *n = (NArgList *)list;
    n->items = (Node **)realloc(n->items, (n->count + 1) * sizeof(Node *));
    n->items[n->count++] = item;
    return list;
}

// BLOCKS

Node *create_block(Node *params, Node *body, int braces) {
    NBlock *n = (NBlock *)xmalloc(sizeof(NBlock));
    n->base.type = N_BLOCK;
    n->base.line = yylloc.first_line;
    n->params = params;
    n->body = body;
    n->braces = braces;
    return (Node *)n;
}

Node *create_block_params_single(char *name) {
    NBlockParams *n = (NBlockParams *)xmalloc(sizeof(NBlockParams));
    n->base.type = N_BLOCK_PARAMS;
    n->base.line = yylloc.first_line;
    n->names = (char **)xmalloc(sizeof(char *));
    n->names[0] = xstrdup(name);
    free(name);
    n->count = 1;
    return (Node *)n;
}

Node *create_block_params_empty(void) {
    NBlockParams *n = (NBlockParams *)xmalloc(sizeof(NBlockParams));
    n->base.type = N_BLOCK_PARAMS;
    n->base.line = yylloc.first_line;
    n->names = NULL;
    n->count = 0;
    return (Node *)n;
}

// STATEMENTS

Node *create_stmt_list_single(Node *stmt) {
    NStmtList *n = (NStmtList *)xmalloc(sizeof(NStmtList));
    n->base.type = N_STMT_LIST;
    n->base.line = yylloc.first_line;
    n->stmts = (Node **)xmalloc(sizeof(Node *));
    n->stmts[0] = stmt;
    n->count = 1;
    return (Node *)n;
}

Node *create_stmt_list_append(Node *list, Node *stmt) {
    NStmtList *n = (NStmtList *)list;
    n->stmts = (Node **)realloc(n->stmts, (n->count + 1) * sizeof(Node *));
    n->stmts[n->count++] = stmt;
    return list;
}

Node *create_stmt_list_empty(void) {
    NStmtList *n = (NStmtList *)xmalloc(sizeof(NStmtList));
    n->base.type = N_STMT_LIST;
    n->base.line = yylloc.first_line;
    n->stmts = NULL;
    n->count = 0;
    return (Node *)n;
}

Node *create_return(Node *value) {
    NReturn *n = (NReturn *)xmalloc(sizeof(NReturn));
    n->base.type = N_RETURN;
    n->base.line = yylloc.first_line;
    n->value = value;
    return (Node *)n;
}

Node *create_break(void) {
    Node *n = (Node *)xmalloc(sizeof(Node));
    n->type = N_BREAK;
    n->line = yylloc.first_line;
    return n;
}

Node *create_next(void) {
    Node *n = (Node *)xmalloc(sizeof(Node));
    n->type = N_NEXT;
    n->line = yylloc.first_line;
    return n;
}

Node *create_print(int kind, Node *expr) {
    NPrint *n = (NPrint *)xmalloc(sizeof(NPrint));
    n->base.type = N_PRINT;
    n->base.line = yylloc.first_line;
    n->kind = kind;
    n->expr = expr;
    return (Node *)n;
}

// CONTROL FLOW

Node *create_if(Node *cond, Node *body, Node *elsifs, Node *else_body) {
    NIf *n = (NIf *)xmalloc(sizeof(NIf));
    n->base.type = N_IF;
    n->base.line = yylloc.first_line;
    n->cond = cond;
    n->body = body;
    n->elsifs = NULL;
    n->elsif_count = 0;
    n->else_body = else_body;
    (void)elsifs;
    return (Node *)n;
}

Node *create_elsif_single(Node *cond, Node *body) {
    NElsif *n = (NElsif *)xmalloc(sizeof(NElsif));
    n->base.type = N_ELSIF;
    n->base.line = yylloc.first_line;
    n->cond = cond;
    n->body = body;
    return (Node *)n;
}

Node *create_unless(Node *cond, Node *body, Node *else_body) {
    NUnless *n = (NUnless *)xmalloc(sizeof(NUnless));
    n->base.type = N_UNLESS;
    n->base.line = yylloc.first_line;
    n->cond = cond;
    n->body = body;
    n->else_body = else_body;
    return (Node *)n;
}

Node *create_while(Node *cond, Node *body) {
    NWhile *n = (NWhile *)xmalloc(sizeof(NWhile));
    n->base.type = N_WHILE;
    n->base.line = yylloc.first_line;
    n->cond = cond;
    n->body = body;
    return (Node *)n;
}

Node *create_until(Node *cond, Node *body) {
    NUntil *n = (NUntil *)xmalloc(sizeof(NUntil));
    n->base.type = N_UNTIL;
    n->base.line = yylloc.first_line;
    n->cond = cond;
    n->body = body;
    return (Node *)n;
}

Node *create_for(char *var, Node *iterable, Node *body) {
    NFor *n = (NFor *)xmalloc(sizeof(NFor));
    n->base.type = N_FOR;
    n->base.line = yylloc.first_line;
    n->var = xstrdup(var);
    free(var);
    n->iterable = iterable;
    n->body = body;
    return (Node *)n;
}

// DEFINITIONS

Node *create_def(char *name, Node *params, Node *body) {
    NDef *n = (NDef *)xmalloc(sizeof(NDef));
    n->base.type = N_DEF;
    n->base.line = yylloc.first_line;
    n->name = xstrdup(name);
    free(name);
    n->params = params;
    n->body = body;
    return (Node *)n;
}

Node *create_param_list_single(char *name) {
    NParamList *n = (NParamList *)xmalloc(sizeof(NParamList));
    n->base.type = N_PARAM_LIST;
    n->base.line = yylloc.first_line;
    n->names = (char **)xmalloc(sizeof(char *));
    n->names[0] = xstrdup(name);
    free(name);
    n->count = 1;
    return (Node *)n;
}

Node *create_param_list_append(Node *list, char *name) {
    NParamList *n = (NParamList *)list;
    n->names = (char **)realloc(n->names, (n->count + 1) * sizeof(char *));
    n->names[n->count++] = xstrdup(name);
    free(name);
    return list;
}

Node *create_class(char *name, char *parent, Node *body) {
    NClass *n = (NClass *)xmalloc(sizeof(NClass));
    n->base.type = N_CLASS;
    n->base.line = yylloc.first_line;
    n->name = xstrdup(name);
    free(name);
    n->parent = parent ? xstrdup(parent) : NULL;
    if (parent) free(parent);
    n->body = body;
    return (Node *)n;
}

Node *create_module(char *name, Node *body) {
    NModule *n = (NModule *)xmalloc(sizeof(NModule));
    n->base.type = N_MODULE;
    n->base.line = yylloc.first_line;
    n->name = xstrdup(name);
    free(name);
    n->body = body;
    return (Node *)n;
}

// BEGIN / RESCUE / ENSURE

Node *create_begin_rescue(Node *body, Node *rescue_body, Node *ensure_body) {
    NBeginRescue *n = (NBeginRescue *)xmalloc(sizeof(NBeginRescue));
    n->base.type = N_BEGIN_RESCUE;
    n->base.line = yylloc.first_line;
    n->body = body;
    n->rescue_body = rescue_body;
    n->ensure_body = ensure_body;
    return (Node *)n;
}

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