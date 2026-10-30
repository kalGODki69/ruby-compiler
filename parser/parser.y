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
%expect 34

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

// NONTERMINAL TYPES
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
    : stmt_list                     { g_root = $1; $$ = $1; }
    ;

// STATEMENTS
stmt_list
    : /* empty */                   { $$ = create_stmt_list_empty(); }
    | stmt                          { $$ = create_stmt_list_single($1); }
    | stmt_list ENDL stmt           { $$ = create_stmt_list_append($1, $3); }
    | stmt_list ENDL                { $$ = $1; }
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
    ;

// IF
if_stmt
    : KW_IF expr ENDL stmt_list KW_END
        { $$ = create_if($2, $4, NULL, NULL); }
    | KW_IF expr ENDL stmt_list KW_ELSE ENDL stmt_list KW_END
        { $$ = create_if($2, $4, NULL, $7); }
    | KW_IF expr ENDL stmt_list elsif_list KW_END
        { $$ = create_if($2, $4, $5, NULL); }
    | KW_IF expr ENDL stmt_list elsif_list KW_ELSE ENDL stmt_list KW_END
        { $$ = create_if($2, $4, $5, $8); }
    ;

elsif_list
    : KW_ELSIF expr ENDL stmt_list
        { $$ = create_elsif_single($2, $4); }
    | elsif_list KW_ELSIF expr ENDL stmt_list
        { $$ = $1; }
    ;

// UNLESS
unless_stmt
    : KW_UNLESS expr ENDL stmt_list KW_END
        { $$ = create_unless($2, $4, NULL); }
    | KW_UNLESS expr ENDL stmt_list KW_ELSE ENDL stmt_list KW_END
        { $$ = create_unless($2, $4, $7); }
    ;

// WHILE
while_stmt
    : KW_WHILE expr ENDL stmt_list KW_END
        { $$ = create_while($2, $4); }
    ;

// UNTIL
until_stmt
    : KW_UNTIL expr ENDL stmt_list KW_END
        { $$ = create_until($2, $4); }
    ;

// FOR
for_stmt
    : KW_FOR ID KW_IN expr ENDL stmt_list KW_END
        { $$ = create_for($2, $4, $6); }
    ;

// DEF
def_stmt
    : KW_DEF ID '(' param_list ')' ENDL stmt_list KW_END
        { $$ = create_def($2, $4, $7); }
    | KW_DEF ID '(' ')' ENDL stmt_list KW_END
        { $$ = create_def($2, NULL, $6); }
    | KW_DEF ID ENDL stmt_list KW_END
        { $$ = create_def($2, NULL, $4); }
    ;

param_list
    : ID                            { $$ = create_param_list_single($1); }
    | param_list ',' ID             { $$ = create_param_list_append($1, $3); }
    ;

// CLASS
class_stmt
    : KW_CLASS CONSTANT ENDL stmt_list KW_END
        { $$ = create_class($2, NULL, $4); }
    | KW_CLASS CONSTANT '<' CONSTANT ENDL stmt_list KW_END
        { $$ = create_class($2, $4, $6); }
    ;

// MODULE
module_stmt
    : KW_MODULE CONSTANT ENDL stmt_list KW_END
        { $$ = create_module($2, $4); }
    ;

// BEGIN
begin_rescue
    : KW_BEGIN ENDL stmt_list KW_END
        { $$ = create_begin_rescue($3, NULL, NULL); }
    | KW_BEGIN ENDL stmt_list KW_RESCUE ENDL stmt_list KW_END
        { $$ = create_begin_rescue($3, $6, NULL); }
    | KW_BEGIN ENDL stmt_list KW_RESCUE ENDL stmt_list KW_ENSURE ENDL stmt_list KW_END
        { $$ = create_begin_rescue($3, $6, $9); }
    | KW_BEGIN ENDL stmt_list KW_ENSURE ENDL stmt_list KW_END
        { $$ = create_begin_rescue($3, NULL, $6); }
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
    | expr '[' expr ']'             { $$ = create_index($1, $3); }
    | '(' expr ')'                  { $$ = $2; }
    ;

// PRIMARY
primary
    : INT                           { $$ = create_int($1); }
    | FLOAT                         { $$ = create_float($1); }
    | STRING                        { $$ = create_string($1); }
    | SYMBOL                        { $$ = create_symbol($1); }
    | ID                            { $$ = create_id($1); }
    | IVAR                          { $$ = create_ivar($1); }
    | CVAR                          { $$ = create_cvar($1); }
    | GVAR                          { $$ = create_gvar($1); }
    | CONSTANT                      { $$ = create_constant($1); }
    | BOOL                          { $$ = create_bool($1); }
    | KW_NIL                        { $$ = create_nil(); }
    | KW_SELF                       { $$ = create_self(); }
    | array_literal                 { $$ = $1; }
    | hash_literal                  { $$ = $1; }
    | call_expr                     { $$ = $1; }
    ;

// ARRAYS
array_literal
    : '[' ']'                       { $$ = create_array(NULL, 0); }
    | '[' expr_list ']'             { $$ = create_array(NULL, 0); }
    ;

// HASHES
hash_literal
    : '{' '}'                       { $$ = create_hash(NULL, 0); }
    | '{' hash_pairs '}'            { $$ = $2; }
    ;

hash_pairs
    : hash_pair                     { $$ = create_hash_list_single($1); }
    | hash_pairs ',' hash_pair      { $$ = create_hash_list_append($1, $3); }
    ;

hash_pair
    : expr OP_HASH_ROCKET expr      { $$ = create_hash_pair($1, $3); }
    ;

// CALLS
call_expr
    : ID '(' ')'                    { $$ = create_call(NULL, $1, NULL, NULL, 0); }
    | ID '(' expr_list ')'          { $$ = create_call(NULL, $1, $3, NULL, 0); }
    | ID block                      { $$ = create_call(NULL, $1, NULL, $2, 0); }
    | expr '.' ID                   { $$ = create_call($1, $3, NULL, NULL, 0); }
    | expr '.' ID '(' ')'           { $$ = create_call($1, $3, NULL, NULL, 0); }
    | expr '.' ID '(' expr_list ')' { $$ = create_call($1, $3, $5, NULL, 0); }
    | expr '.' ID block             { $$ = create_call($1, $3, NULL, $4, 0); }
    | expr OP_SCOPE ID              { $$ = create_call($1, $3, NULL, NULL, 1); }
    | expr OP_SCOPE ID '(' ')'      { $$ = create_call($1, $3, NULL, NULL, 1); }
    | expr OP_SCOPE ID '(' expr_list ')' { $$ = create_call($1, $3, $5, NULL, 1); }
    ;

expr_list
    : expr                          { $$ = $1; }
    | expr_list ',' expr            { $$ = $1; }
    ;

// BLOCKS
block
    : KW_DO ENDL stmt_list KW_END
        { $$ = create_block(NULL, $3, 0); }
    | KW_DO block_params ENDL stmt_list KW_END
        { $$ = create_block($2, $4, 0); }
    | '{' stmt_list '}'
        { $$ = create_block(NULL, $2, 1); }
    | '{' block_params stmt_list '}'
        { $$ = create_block($2, $3, 1); }
    ;

block_params
    : '|' '|'                       { $$ = create_block_params_empty(); }
    | '|' param_list '|'            { $$ = $2; }
    ;

%%

// TREE PRINTER (DOT FORMAT)

static int node_id_counter = 0;

static const char *printOp(OpCode op) {
    switch (op) {
        case OPC_ADD: return "+";
        case OPC_SUB: return "-";
        case OPC_MUL: return "*";
        case OPC_DIV: return "/";
        case OPC_MOD: return "%";
        case OPC_POW: return "**";
        case OPC_EQ: return "==";
        case OPC_NEQ: return "!=";
        case OPC_LT: return "<";
        case OPC_GT: return ">";
        case OPC_LE: return "<=";
        case OPC_GE: return ">=";
        case OPC_CMP: return "<=>";
        case OPC_CASE_EQ: return "===";
        case OPC_AND: return "&&";
        case OPC_OR: return "||";
        case OPC_KW_AND: return "and";
        case OPC_KW_OR: return "or";
        case OPC_LSHIFT: return "<<";
        case OPC_RSHIFT: return ">>";
        case OPC_BITAND: return "&";
        case OPC_BITOR: return "|";
        case OPC_BITXOR: return "^";
        case OPC_NOT: return "!";
        case OPC_KW_NOT: return "not";
        case OPC_NEG: return "-";
        case OPC_POS: return "+";
        case OPC_PLUS_ASSIGN: return "+=";
        case OPC_MINUS_ASSIGN: return "-=";
        case OPC_MUL_ASSIGN: return "*=";
        case OPC_DIV_ASSIGN: return "/=";
        default: return "?";
    }
}

static const char *printIdType(NodeType t) {
    switch (t) {
        case N_ID: return "id";
        case N_IVAR: return "ivar";
        case N_CVAR: return "cvar";
        case N_GVAR: return "gvar";
        case N_CONSTANT: return "constant";
        default: return "?";
    }
}

static int printDotNode(FILE *out, Node *n, int parent_id) {
    if (!n) return -1;

    int my_id = node_id_counter++;
    
    switch (n->type) {
    case N_INT:
        fprintf(out, "    node%d [label=\"int %d\"];\n", my_id, ((NInt *)n)->value); break;
    case N_FLOAT:
        fprintf(out, "    node%d [label=\"float %f\"];\n", my_id, ((NFloat *)n)->value); break;
    case N_STRING:
        fprintf(out, "    node%d [label=\"string '%s'\"];\n", my_id, ((NString *)n)->value); break;
    case N_SYMBOL:
        fprintf(out, "    node%d [label=\"symbol :%s\"];\n", my_id, ((NSymbol *)n)->value); break;
    case N_TRUE: fprintf(out, "    node%d [label=\"true\"];\n", my_id); break;
    case N_FALSE: fprintf(out, "    node%d [label=\"false\"];\n", my_id); break;
    case N_NIL: fprintf(out, "    node%d [label=\"nil\"];\n", my_id); break;
    case N_SELF: fprintf(out, "    node%d [label=\"self\"];\n", my_id); break;
    case N_ID: case N_IVAR: case N_CVAR: case N_GVAR: case N_CONSTANT:
        fprintf(out, "    node%d [label=\"%s %s\"];\n", my_id, printIdType(n->type), ((NId *)n)->name); break;
    case N_BINOP:
        fprintf(out, "    node%d [label=\"binop %s\"];\n", my_id, printOp(((NBinOp *)n)->op)); break;
    case N_UNOP:
        fprintf(out, "    node%d [label=\"unop %s\"];\n", my_id, printOp(((NUnOp *)n)->op)); break;
    case N_ASSIGN:
        fprintf(out, "    node%d [label=\"assign %s\"];\n", my_id, printOp(((NAssign *)n)->op)); break;
    case N_TERNARY: fprintf(out, "    node%d [label=\"ternary ?:\"];\n", my_id); break;
    case N_RANGE:
        fprintf(out, "    node%d [label=\"range %s\"];\n", my_id, ((NRange *)n)->inclusive ? ".." : "..."); break;
    case N_ARRAY: fprintf(out, "    node%d [label=\"array\"];\n", my_id); break;
    case N_HASH: fprintf(out, "    node%d [label=\"hash\"];\n", my_id); break;
    case N_HASH_PAIR: fprintf(out, "    node%d [label=\"pair =>\"];\n", my_id); break;
    case N_INDEX: fprintf(out, "    node%d [label=\"index []\"];\n", my_id); break;
    case N_CALL:
        fprintf(out, "    node%d [label=\"call %s %s\"];\n", my_id, ((NCall *)n)->scope_op ? "::" : ".", ((NCall *)n)->method); break;
    case N_BLOCK: fprintf(out, "    node%d [label=\"block\"];\n", my_id); break;
    case N_BLOCK_PARAMS: fprintf(out, "    node%d [label=\"params\"];\n", my_id); break;
    case N_STMT_LIST: fprintf(out, "    node%d [label=\"stmt_list\"];\n", my_id); break;
    case N_RETURN: fprintf(out, "    node%d [label=\"return\"];\n", my_id); break;
    case N_BREAK: fprintf(out, "    node%d [label=\"break\"];\n", my_id); break;
    case N_NEXT: fprintf(out, "    node%d [label=\"next\"];\n", my_id); break;
    case N_IF: fprintf(out, "    node%d [label=\"if\"];\n", my_id); break;
    case N_UNLESS: fprintf(out, "    node%d [label=\"unless\"];\n", my_id); break;
    case N_WHILE: fprintf(out, "    node%d [label=\"while\"];\n", my_id); break;
    case N_UNTIL: fprintf(out, "    node%d [label=\"until\"];\n", my_id); break;
    case N_FOR: fprintf(out, "    node%d [label=\"for %s\"];\n", my_id, ((NFor *)n)->var); break;
    case N_DEF: fprintf(out, "    node%d [label=\"def %s\"];\n", my_id, ((NDef *)n)->name); break;
    case N_PARAM_LIST: fprintf(out, "    node%d [label=\"param_list\"];\n", my_id); break;
    case N_CLASS: 
        if (((NClass *)n)->parent) fprintf(out, "    node%d [label=\"class %s < %s\"];\n", my_id, ((NClass *)n)->name, ((NClass *)n)->parent);
        else fprintf(out, "    node%d [label=\"class %s\"];\n", my_id, ((NClass *)n)->name); break;
    case N_MODULE: fprintf(out, "    node%d [label=\"module %s\"];\n", my_id, ((NModule *)n)->name); break;
    case N_BEGIN_RESCUE: fprintf(out, "    node%d [label=\"begin_rescue\"];\n", my_id); break;
    case N_ELSIF: fprintf(out, "    node%d [label=\"elsif\"];\n", my_id); break;
    case N_ARG_LIST: fprintf(out, "    node%d [label=\"args\"];\n", my_id); break;
    default: fprintf(out, "    node%d [label=\"unknown\"];\n", my_id); break;
    }

    if (parent_id != -1) {
        fprintf(out, "    node%d -> node%d;\n", parent_id, my_id);
    }

    switch (n->type) {
    case N_BINOP: {
        NBinOp *b = (NBinOp *)n;
        printDotNode(out, b->lhs, my_id);
        printDotNode(out, b->rhs, my_id);
        break;
    }
    case N_UNOP: printDotNode(out, ((NUnOp *)n)->operand, my_id); break;
    case N_TERNARY: {
        NTernary *t = (NTernary *)n;
        printDotNode(out, t->cond, my_id);
        printDotNode(out, t->then_expr, my_id);
        printDotNode(out, t->else_expr, my_id);
        break;
    }
    case N_ASSIGN: {
        NAssign *a = (NAssign *)n;
        printDotNode(out, a->target, my_id);
        printDotNode(out, a->value, my_id);
        break;
    }
    case N_RANGE: {
        NRange *r = (NRange *)n;
        printDotNode(out, r->from, my_id);
        printDotNode(out, r->to, my_id);
        break;
    }
    case N_HASH: {
        NHash *h = (NHash *)n; int i;
        for (i = 0; i < h->count; i++) printDotNode(out, h->pairs[i], my_id);
        break;
    }
    case N_HASH_PAIR: {
        NHashPair *hp = (NHashPair *)n;
        printDotNode(out, hp->key, my_id);
        printDotNode(out, hp->value, my_id);
        break;
    }
    case N_INDEX: {
        NIndex *ix = (NIndex *)n;
        printDotNode(out, ix->object, my_id);
        printDotNode(out, ix->index, my_id);
        break;
    }
    case N_CALL: {
        NCall *c = (NCall *)n;
        if (c->receiver) printDotNode(out, c->receiver, my_id);
        if (c->args) printDotNode(out, c->args, my_id);
        if (c->block) printDotNode(out, c->block, my_id);
        break;
    }
    case N_BLOCK: {
        NBlock *bl = (NBlock *)n;
        if (bl->params) printDotNode(out, bl->params, my_id);
        if (bl->body) printDotNode(out, bl->body, my_id);
        break;
    }
    case N_STMT_LIST: {
        NStmtList *sl = (NStmtList *)n; int i;
        for (i = 0; i < sl->count; i++) printDotNode(out, sl->stmts[i], my_id);
        break;
    }
    case N_RETURN: if (((NReturn *)n)->value) printDotNode(out, ((NReturn *)n)->value, my_id); break;
    case N_IF: {
        NIf *i = (NIf *)n;
        printDotNode(out, i->cond, my_id);
        printDotNode(out, i->body, my_id);
        if (i->else_body) printDotNode(out, i->else_body, my_id);
        break;
    }
    case N_UNLESS: {
        NUnless *u = (NUnless *)n;
        printDotNode(out, u->cond, my_id);
        printDotNode(out, u->body, my_id);
        if (u->else_body) printDotNode(out, u->else_body, my_id);
        break;
    }
    case N_WHILE: {
        NWhile *w = (NWhile *)n;
        printDotNode(out, w->cond, my_id);
        printDotNode(out, w->body, my_id);
        break;
    }
    case N_UNTIL: {
        NUntil *u = (NUntil *)n;
        printDotNode(out, u->cond, my_id);
        printDotNode(out, u->body, my_id);
        break;
    }
    case N_FOR: {
        NFor *f = (NFor *)n;
        printDotNode(out, f->iterable, my_id);
        printDotNode(out, f->body, my_id);
        break;
    }
    case N_DEF: {
        NDef *d = (NDef *)n;
        if (d->params) printDotNode(out, d->params, my_id);
        if (d->body) printDotNode(out, d->body, my_id);
        break;
    }
    case N_CLASS: if (((NClass *)n)->body) printDotNode(out, ((NClass *)n)->body, my_id); break;
    case N_MODULE: if (((NModule *)n)->body) printDotNode(out, ((NModule *)n)->body, my_id); break;
    case N_BEGIN_RESCUE: {
        NBeginRescue *br = (NBeginRescue *)n;
        if (br->body) printDotNode(out, br->body, my_id);
        if (br->rescue_body) printDotNode(out, br->rescue_body, my_id);
        if (br->ensure_body) printDotNode(out, br->ensure_body, my_id);
        break;
    }
    case N_ELSIF: {
        NElsif *e = (NElsif *)n;
        printDotNode(out, e->cond, my_id);
        printDotNode(out, e->body, my_id);
        break;
    }
    case N_ARG_LIST: {
        NArgList *al = (NArgList *)n; int i;
        for (i = 0; i < al->count; i++) printDotNode(out, al->items[i], my_id);
        break;
    }
    default: break;
    }

    return my_id;
}

void printTree(FILE *out, Node *root) {
    node_id_counter = 0;
    fprintf(out, "digraph AST {\n");
    if (root) printDotNode(out, root, -1);
    fprintf(out, "}\n");
}

// ERROR HANDLING
void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylloc.first_line, s);
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

    if (result == 0 && g_root) {
        printTree(stdout, g_root);
    }
    return result;
}