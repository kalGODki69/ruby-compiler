#include "tree_nodes.h"
#include <stdlib.h>
#include <string.h>

// External line counter from Bison locations
extern int yylineno;

// Helper: allocate zeroed memory
static void *xmalloc(size_t size) {
    void *p = malloc(size);
    if (!p) {
        fprintf(stderr, "Out of memory\n");
        exit(1);
    }
    memset(p, 0, size);
    return p;
}

// Helper: duplicate a string
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
    n->base.line = yylineno;
    n->value = value;
    return (Node *)n;
}

Node *create_float(double value) {
    NFloat *n = (NFloat *)xmalloc(sizeof(NFloat));
    n->base.type = N_FLOAT;
    n->base.line = yylineno;
    n->value = value;
    return (Node *)n;
}

Node *create_string(char *value) {
    NString *n = (NString *)xmalloc(sizeof(NString));
    n->base.type = N_STRING;
    n->base.line = yylineno;
    n->value = xstrdup(value);
    free(value);
    return (Node *)n;
}

Node *create_string_sq(char *value) {
    NString *n = (NString *)xmalloc(sizeof(NString));
    n->base.type = N_STRING_SQ;
    n->base.line = yylineno;
    n->value = xstrdup(value);
    free(value);
    return (Node *)n;
}

Node *create_symbol(char *value) {
    NSymbol *n = (NSymbol *)xmalloc(sizeof(NSymbol));
    n->base.type = N_SYMBOL;
    n->base.line = yylineno;
    n->value = xstrdup(value);
    free(value);
    return (Node *)n;
}

Node *create_bool(int value) {
    Node *n = (Node *)xmalloc(sizeof(Node));
    n->type = value ? N_TRUE : N_FALSE;
    n->line = yylineno;
    return n;
}

Node *create_nil(void) {
    Node *n = (Node *)xmalloc(sizeof(Node));
    n->type = N_NIL;
    n->line = yylineno;
    return n;
}

Node *create_self(void) {
    Node *n = (Node *)xmalloc(sizeof(Node));
    n->type = N_SELF;
    n->line = yylineno;
    return n;
}

// IDENTIFIERS
static Node *create_id_node(NodeType t, char *name) {
    NId *n = (NId *)xmalloc(sizeof(NId));
    n->base.type = t;
    n->base.line = yylineno;
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
    n->base.line = yylineno;
    n->op = op;
    n->lhs = lhs;
    n->rhs = rhs;
    return (Node *)n;
}

Node *create_unop(OpCode op, Node *operand) {
    NUnOp *n = (NUnOp *)xmalloc(sizeof(NUnOp));
    n->base.type = N_UNOP;
    n->base.line = yylineno;
    n->op = op;
    n->operand = operand;
    return (Node *)n;
}

Node *create_ternary(Node *cond, Node *then_e, Node *else_e) {
    NTernary *n = (NTernary *)xmalloc(sizeof(NTernary));
    n->base.type = N_TERNARY;
    n->base.line = yylineno;
    n->cond = cond;
    n->then_expr = then_e;
    n->else_expr = else_e;
    return (Node *)n;
}

Node *create_assign(OpCode op, Node *target, Node *value) {
    NAssign *n = (NAssign *)xmalloc(sizeof(NAssign));
    n->base.type = N_ASSIGN;
    n->base.line = yylineno;
    n->op = op;
    n->target = target;
    n->value = value;
    return (Node *)n;
}

Node *create_range(int inclusive, Node *from, Node *to) {
    NRange *n = (NRange *)xmalloc(sizeof(NRange));
    n->base.type = N_RANGE;
    n->base.line = yylineno;
    n->inclusive = inclusive;
    n->from = from;
    n->to = to;
    return (Node *)n;
}

// COLLECTIONS
Node *create_array(Node **items, int count) {
    NArray *n = (NArray *)xmalloc(sizeof(NArray));
    n->base.type = N_ARRAY;
    n->base.line = yylineno;
    n->items = items;
    n->count = count;
    return (Node *)n;
}

Node *create_hash(Node **pairs, int count) {
    NHash *n = (NHash *)xmalloc(sizeof(NHash));
    n->base.type = N_HASH;
    n->base.line = yylineno;
    n->pairs = pairs;
    n->count = count;
    return (Node *)n;
}

Node *create_hash_pair(Node *key, Node *value) {
    NHashPair *n = (NHashPair *)xmalloc(sizeof(NHashPair));
    n->base.type = N_HASH_PAIR;
    n->base.line = yylineno;
    n->key = key;
    n->value = value;
    return (Node *)n;
}

Node *create_hash_list_single(Node *pair) {
    Node **pairs = (Node **)xmalloc(sizeof(Node *));
    pairs[0] = pair;
    return create_hash(pairs, 1);
}

Node *create_hash_list_append(Node *hash, Node *pair) {
    NHash *n = (NHash *)hash;
    n->pairs = (Node **)realloc(n->pairs, (n->count + 1) * sizeof(Node *));
    n->pairs[n->count++] = pair;
    return hash;
}

Node *create_index(Node *object, Node *index) {
    NIndex *n = (NIndex *)xmalloc(sizeof(NIndex));
    n->base.type = N_INDEX;
    n->base.line = yylineno;
    n->object = object;
    n->index = index;
    return (Node *)n;
}

// CALLS
Node *create_call(Node *receiver, char *method, Node *args, Node *block, int scope_op) {
    NCall *n = (NCall *)xmalloc(sizeof(NCall));
    n->base.type = N_CALL;
    n->base.line = yylineno;
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
    n->base.line = yylineno;
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
    n->base.line = yylineno;
    n->params = params;
    n->body = body;
    n->braces = braces;
    return (Node *)n;
}

Node *create_block_params_single(char *name) {
    NBlockParams *n = (NBlockParams *)xmalloc(sizeof(NBlockParams));
    n->base.type = N_BLOCK_PARAMS;
    n->base.line = yylineno;
    n->names = (char **)xmalloc(sizeof(char *));
    n->names[0] = xstrdup(name);
    free(name);
    n->count = 1;
    return (Node *)n;
}

Node *create_block_params_empty(void) {
    NBlockParams *n = (NBlockParams *)xmalloc(sizeof(NBlockParams));
    n->base.type = N_BLOCK_PARAMS;
    n->base.line = yylineno;
    n->names = NULL;
    n->count = 0;
    return (Node *)n;
}

// STATEMENTS
Node *create_stmt_list_single(Node *stmt) {
    NStmtList *n = (NStmtList *)xmalloc(sizeof(NStmtList));
    n->base.type = N_STMT_LIST;
    n->base.line = yylineno;
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
    n->base.line = yylineno;
    n->stmts = NULL;
    n->count = 0;
    return (Node *)n;
}

Node *create_return(Node *value) {
    NReturn *n = (NReturn *)xmalloc(sizeof(NReturn));
    n->base.type = N_RETURN;
    n->base.line = yylineno;
    n->value = value;
    return (Node *)n;
}

Node *create_break(void) {
    Node *n = (Node *)xmalloc(sizeof(Node));
    n->type = N_BREAK;
    n->line = yylineno;
    return n;
}

Node *create_next(void) {
    Node *n = (Node *)xmalloc(sizeof(Node));
    n->type = N_NEXT;
    n->line = yylineno;
    return n;
}

Node *create_print(int kind, Node *expr) {
    NPrint *n = (NPrint *)xmalloc(sizeof(NPrint));
    n->base.type = N_PRINT;
    n->base.line = yylineno;
    n->kind = kind;
    n->expr = expr;
    return (Node *)n;
}

// CONTROL FLOW
Node *create_if(Node *cond, Node *body, Node *elsifs, Node *else_body) {
    NIf *n = (NIf *)xmalloc(sizeof(NIf));
    n->base.type = N_IF;
    n->base.line = yylineno;
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
    n->base.line = yylineno;
    n->cond = cond;
    n->body = body;
    return (Node *)n;
}

Node *create_unless(Node *cond, Node *body, Node *else_body) {
    NUnless *n = (NUnless *)xmalloc(sizeof(NUnless));
    n->base.type = N_UNLESS;
    n->base.line = yylineno;
    n->cond = cond;
    n->body = body;
    n->else_body = else_body;
    return (Node *)n;
}

Node *create_while(Node *cond, Node *body) {
    NWhile *n = (NWhile *)xmalloc(sizeof(NWhile));
    n->base.type = N_WHILE;
    n->base.line = yylineno;
    n->cond = cond;
    n->body = body;
    return (Node *)n;
}

Node *create_until(Node *cond, Node *body) {
    NUntil *n = (NUntil *)xmalloc(sizeof(NUntil));
    n->base.type = N_UNTIL;
    n->base.line = yylineno;
    n->cond = cond;
    n->body = body;
    return (Node *)n;
}

Node *create_for(char *var, Node *iterable, Node *body) {
    NFor *n = (NFor *)xmalloc(sizeof(NFor));
    n->base.type = N_FOR;
    n->base.line = yylineno;
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
    n->base.line = yylineno;
    n->name = xstrdup(name);
    free(name);
    n->params = params;
    n->body = body;
    return (Node *)n;
}

Node *create_param_list_single(char *name) {
    NParamList *n = (NParamList *)xmalloc(sizeof(NParamList));
    n->base.type = N_PARAM_LIST;
    n->base.line = yylineno;
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
    n->base.line = yylineno;
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
    n->base.line = yylineno;
    n->name = xstrdup(name);
    free(name);
    n->body = body;
    return (Node *)n;
}

// BEGIN / RESCUE / ENSURE
Node *create_begin_rescue(Node *body, Node *rescue_body, Node *ensure_body) {
    NBeginRescue *n = (NBeginRescue *)xmalloc(sizeof(NBeginRescue));
    n->base.type = N_BEGIN_RESCUE;
    n->base.line = yylineno;
    n->body = body;
    n->rescue_body = rescue_body;
    n->ensure_body = ensure_body;
    return (Node *)n;
}