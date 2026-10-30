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
%expect 66

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

// IF
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

// BEGIN
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
    | expr '[' expr ']'             { $$ = create_index($1, $3); }
    | '(' expr ')'                  { $$ = $2; }
    ;

// PRIMARY
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
    | '|' param_list '|'            { $$ = $2; }
    ;

%%

// TREE PRINTER

static void printIndent(FILE *out, int depth) {
    int i;
    for (i = 0; i < depth; i++) fprintf(out, "  ");
}

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

static const char *printKindStr(int kind) {
    switch (kind) {
        case PRINT_PUTS: return "puts";
        case PRINT_PRINT: return "print";
        case PRINT_P: return "p";
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

static void printNode(FILE *out, Node *n, int depth);

static void printStmtList(FILE *out, Node *n, int depth) {
    NStmtList *sl = (NStmtList *)n;
    int i;
    printIndent(out, depth);
    fprintf(out, "<stmt_list count=\"%d\">\n", sl->count);
    for (i = 0; i < sl->count; i++) {
        printNode(out, sl->stmts[i], depth + 1);
    }
    printIndent(out, depth);
    fprintf(out, "</stmt_list>\n");
}

static void printNode(FILE *out, Node *n, int depth) {
    if (!n) return;
    printIndent(out, depth);

    switch (n->type) {
    case N_INT:
        fprintf(out, "<int value=\"%d\"/>\n", ((NInt *)n)->value); break;
    case N_FLOAT:
        fprintf(out, "<float value=\"%f\"/>\n", ((NFloat *)n)->value); break;
    case N_STRING:
        fprintf(out, "<string value=\"%s\"/>\n", ((NString *)n)->value); break;
    case N_STRING_SQ:
        fprintf(out, "<string_sq value=\"%s\"/>\n", ((NString *)n)->value); break;
    case N_SYMBOL:
        fprintf(out, "<symbol value=\"%s\"/>\n", ((NSymbol *)n)->value); break;
    case N_TRUE:
        fprintf(out, "<true/>\n"); break;
    case N_FALSE:
        fprintf(out, "<false/>\n"); break;
    case N_NIL:
        fprintf(out, "<nil/>\n"); break;
    case N_SELF:
        fprintf(out, "<self/>\n"); break;
    case N_ID: case N_IVAR: case N_CVAR: case N_GVAR: case N_CONSTANT:
        fprintf(out, "<%s name=\"%s\"/>\n", printIdType(n->type), ((NId *)n)->name); break;
    case N_BINOP: {
        NBinOp *b = (NBinOp *)n;
        fprintf(out, "<binop op=\"%s\">\n", printOp(b->op));
        printNode(out, b->lhs, depth + 1);
        printNode(out, b->rhs, depth + 1);
        printIndent(out, depth); fprintf(out, "</binop>\n");
        break;
    }
    case N_UNOP: {
        NUnOp *u = (NUnOp *)n;
        fprintf(out, "<unop op=\"%s\">\n", printOp(u->op));
        printNode(out, u->operand, depth + 1);
        printIndent(out, depth); fprintf(out, "</unop>\n");
        break;
    }
    case N_TERNARY: {
        NTernary *t = (NTernary *)n;
        fprintf(out, "<ternary>\n");
        printNode(out, t->cond, depth + 1);
        printNode(out, t->then_expr, depth + 1);
        printNode(out, t->else_expr, depth + 1);
        printIndent(out, depth); fprintf(out, "</ternary>\n");
        break;
    }
    case N_ASSIGN: {
        NAssign *a = (NAssign *)n;
        fprintf(out, "<assign op=\"%s\">\n", printOp(a->op));
        printNode(out, a->target, depth + 1);
        printNode(out, a->value, depth + 1);
        printIndent(out, depth); fprintf(out, "</assign>\n");
        break;
    }
    case N_RANGE: {
        NRange *r = (NRange *)n;
        fprintf(out, "<range type=\"%s\">\n", r->inclusive ? ".." : "...");
        printNode(out, r->from, depth + 1);
        printNode(out, r->to, depth + 1);
        printIndent(out, depth); fprintf(out, "</range>\n");
        break;
    }
    case N_ARRAY: fprintf(out, "<array count=\"%d\"/>\n", ((NArray *)n)->count); break;
    case N_HASH: fprintf(out, "<hash/>\n"); break;
    case N_HASH_PAIR: {
        NHashPair *hp = (NHashPair *)n;
        fprintf(out, "<hash_pair>\n");
        printNode(out, hp->key, depth + 1);
        printNode(out, hp->value, depth + 1);
        printIndent(out, depth); fprintf(out, "</hash_pair>\n");
        break;
    }
    case N_INDEX: {
        NIndex *ix = (NIndex *)n;
        fprintf(out, "<index>\n");
        printNode(out, ix->object, depth + 1);
        printNode(out, ix->index, depth + 1);
        printIndent(out, depth); fprintf(out, "</index>\n");
        break;
    }
    case N_CALL: {
        NCall *c = (NCall *)n;
        fprintf(out, "<call method=\"%s\" scope=\"%s\">\n", c->method, c->scope_op ? "::" : ".");
        if (c->receiver) {
            printIndent(out, depth + 1); fprintf(out, "<receiver>\n");
            printNode(out, c->receiver, depth + 2);
            printIndent(out, depth + 1); fprintf(out, "</receiver>\n");
        }
        if (c->args) {
            printIndent(out, depth + 1); fprintf(out, "<args>\n");
            printNode(out, c->args, depth + 2);
            printIndent(out, depth + 1); fprintf(out, "</args>\n");
        }
        if (c->block) printNode(out, c->block, depth + 1);
        printIndent(out, depth); fprintf(out, "</call>\n");
        break;
    }
    case N_BLOCK: {
        NBlock *bl = (NBlock *)n;
        fprintf(out, "<block braces=\"%d\">\n", bl->braces);
        if (bl->params) printNode(out, bl->params, depth + 1);
        if (bl->body) printNode(out, bl->body, depth + 1);
        printIndent(out, depth); fprintf(out, "</block>\n");
        break;
    }
    case N_BLOCK_PARAMS: {
        NBlockParams *bp = (NBlockParams *)n; int i;
        fprintf(out, "<block_params count=\"%d\">\n", bp->count);
        for (i = 0; i < bp->count; i++) { printIndent(out, depth + 1); fprintf(out, "<param name=\"%s\"/>\n", bp->names[i]); }
        printIndent(out, depth); fprintf(out, "</block_params>\n");
        break;
    }
    case N_STMT_LIST: printStmtList(out, n, depth); break;
    case N_RETURN: {
        NReturn *r = (NReturn *)n;
        if (r->value) { fprintf(out, "<return>\n"); printNode(out, r->value, depth + 1); printIndent(out, depth); fprintf(out, "</return>\n"); }
        else fprintf(out, "<return/>\n");
        break;
    }
    case N_BREAK: fprintf(out, "<break/>\n"); break;
    case N_NEXT: fprintf(out, "<next/>\n"); break;
    case N_PRINT: {
        NPrint *p = (NPrint *)n;
        fprintf(out, "<print kind=\"%s\">\n", printKindStr(p->kind));
        printNode(out, p->expr, depth + 1);
        printIndent(out, depth); fprintf(out, "</print>\n");
        break;
    }
    case N_IF: {
        NIf *i = (NIf *)n;
        fprintf(out, "<if>\n");
        printIndent(out, depth + 1); fprintf(out, "<cond>\n"); printNode(out, i->cond, depth + 2); printIndent(out, depth + 1); fprintf(out, "</cond>\n");
        printIndent(out, depth + 1); fprintf(out, "<then>\n"); printNode(out, i->body, depth + 2); printIndent(out, depth + 1); fprintf(out, "</then>\n");
        if (i->else_body) { printIndent(out, depth + 1); fprintf(out, "<else>\n"); printNode(out, i->else_body, depth + 2); printIndent(out, depth + 1); fprintf(out, "</else>\n"); }
        printIndent(out, depth); fprintf(out, "</if>\n");
        break;
    }
    case N_UNLESS: {
        NUnless *u = (NUnless *)n;
        fprintf(out, "<unless>\n");
        printNode(out, u->cond, depth + 1);
        printNode(out, u->body, depth + 1);
        if (u->else_body) printNode(out, u->else_body, depth + 1);
        printIndent(out, depth); fprintf(out, "</unless>\n");
        break;
    }
    case N_WHILE: {
        NWhile *w = (NWhile *)n;
        fprintf(out, "<while>\n");
        printNode(out, w->cond, depth + 1);
        printNode(out, w->body, depth + 1);
        printIndent(out, depth); fprintf(out, "</while>\n");
        break;
    }
    case N_UNTIL: {
        NUntil *u = (NUntil *)n;
        fprintf(out, "<until>\n");
        printNode(out, u->cond, depth + 1);
        printNode(out, u->body, depth + 1);
        printIndent(out, depth); fprintf(out, "</until>\n");
        break;
    }
    case N_FOR: {
        NFor *f = (NFor *)n;
        fprintf(out, "<for var=\"%s\">\n", f->var);
        printNode(out, f->iterable, depth + 1);
        printNode(out, f->body, depth + 1);
        printIndent(out, depth); fprintf(out, "</for>\n");
        break;
    }
    case N_DEF: {
        NDef *d = (NDef *)n;
        fprintf(out, "<def name=\"%s\">\n", d->name);
        if (d->params) printNode(out, d->params, depth + 1);
        if (d->body) printNode(out, d->body, depth + 1);
        printIndent(out, depth); fprintf(out, "</def>\n");
        break;
    }
    case N_PARAM_LIST: {
        NParamList *pl = (NParamList *)n; int i;
        fprintf(out, "<param_list count=\"%d\">\n", pl->count);
        for (i = 0; i < pl->count; i++) { printIndent(out, depth + 1); fprintf(out, "<param name=\"%s\"/>\n", pl->names[i]); }
        printIndent(out, depth); fprintf(out, "</param_list>\n");
        break;
    }
    case N_CLASS: {
        NClass *c = (NClass *)n;
        fprintf(out, "<class name=\"%s\"", c->name);
        if (c->parent) fprintf(out, " parent=\"%s\"", c->parent);
        fprintf(out, ">\n");
        if (c->body) printNode(out, c->body, depth + 1);
        printIndent(out, depth); fprintf(out, "</class>\n");
        break;
    }
    case N_MODULE: {
        NModule *m = (NModule *)n;
        fprintf(out, "<module name=\"%s\">\n", m->name);
        if (m->body) printNode(out, m->body, depth + 1);
        printIndent(out, depth); fprintf(out, "</module>\n");
        break;
    }
    case N_BEGIN_RESCUE: {
        NBeginRescue *br = (NBeginRescue *)n;
        fprintf(out, "<begin_rescue>\n");
        if (br->body) printNode(out, br->body, depth + 1);
        if (br->rescue_body) printNode(out, br->rescue_body, depth + 1);
        if (br->ensure_body) printNode(out, br->ensure_body, depth + 1);
        printIndent(out, depth); fprintf(out, "</begin_rescue>\n");
        break;
    }
    case N_ELSIF: {
        NElsif *e = (NElsif *)n;
        fprintf(out, "<elsif>\n");
        printNode(out, e->cond, depth + 1);
        printNode(out, e->body, depth + 1);
        printIndent(out, depth); fprintf(out, "</elsif>\n");
        break;
    }
    case N_ARG_LIST: {
        NArgList *al = (NArgList *)n; int i;
        fprintf(out, "<arg_list count=\"%d\">\n", al->count);
        for (i = 0; i < al->count; i++) printNode(out, al->items[i], depth + 1);
        printIndent(out, depth); fprintf(out, "</arg_list>\n");
        break;
    }
    default: fprintf(out, "<unknown type=\"%d\"/>\n", n->type); break;
    }
}

void printTree(FILE *out, Node *root) {
    fprintf(out, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    fprintf(out, "<program>\n");
    if (root) printNode(out, root, 1);
    fprintf(out, "</program>\n");
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