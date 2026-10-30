#ifndef TREE_NODES_H
#define TREE_NODES_H

#include <stdio.h>

// NODE TYPES
typedef enum {
    N_INT, N_FLOAT, N_STRING, N_STRING_SQ, N_SYMBOL,
    N_TRUE, N_FALSE, N_NIL, N_SELF,
    N_ID, N_IVAR, N_CVAR, N_GVAR, N_CONSTANT,
    N_BINOP, N_UNOP, N_TERNARY, N_ASSIGN, N_RANGE,
    N_ARRAY, N_HASH, N_HASH_PAIR, N_INDEX,
    N_CALL, N_ARG_LIST, N_BLOCK, N_BLOCK_PARAMS,
    N_STMT_LIST, N_RETURN, N_BREAK, N_NEXT, N_PRINT,
    N_IF, N_ELSIF, N_UNLESS, N_WHILE, N_UNTIL, N_FOR,
    N_DEF, N_PARAM_LIST, N_CLASS, N_MODULE,
    N_BEGIN_RESCUE
} NodeType;

// OPERATOR CODES (prefixed to avoid clash with Bison tokens)
typedef enum {
    OPC_ADD, OPC_SUB, OPC_MUL, OPC_DIV, OPC_MOD, OPC_POW,
    OPC_EQ, OPC_NEQ, OPC_LT, OPC_GT, OPC_LE, OPC_GE,
    OPC_CMP, OPC_CASE_EQ,
    OPC_AND, OPC_OR,
    OPC_KW_AND, OPC_KW_OR,
    OPC_LSHIFT, OPC_RSHIFT,
    OPC_BITAND, OPC_BITOR, OPC_BITXOR,
    OPC_NOT, OPC_KW_NOT,
    OPC_NEG, OPC_POS,
    OPC_PLUS_ASSIGN, OPC_MINUS_ASSIGN,
    OPC_MUL_ASSIGN, OPC_DIV_ASSIGN
} OpCode;

// PRINT KINDS
typedef enum {
    PRINT_PUTS, PRINT_PRINT, PRINT_P
} PrintKind;

// BASE NODE
typedef struct Node {
    NodeType type;
    int      line;
} Node;

// LITERALS
typedef struct {
    Node base;
    int  value;
} NInt;

typedef struct {
    Node   base;
    double value;
} NFloat;

typedef struct {
    Node  base;
    char *value;
} NString;

typedef struct {
    Node  base;
    char *value;
} NSymbol;

typedef struct {
    Node  base;
    char *name;
} NId;

// EXPRESSIONS
typedef struct {
    Node   base;
    OpCode op;
    Node  *lhs;
    Node  *rhs;
} NBinOp;

typedef struct {
    Node   base;
    OpCode op;
    Node  *operand;
} NUnOp;

typedef struct {
    Node  base;
    Node *cond;
    Node *then_expr;
    Node *else_expr;
} NTernary;

typedef struct {
    Node   base;
    OpCode op;
    Node  *target;
    Node  *value;
} NAssign;

typedef struct {
    Node  base;
    int    inclusive;
    Node  *from;
    Node  *to;
} NRange;

// COLLECTIONS
typedef struct {
    Node   base;
    Node **items;
    int    count;
} NArray;

typedef struct {
    Node   base;
    Node **pairs;
    int    count;
} NHash;

typedef struct {
    Node base;
    Node *key;
    Node *value;
} NHashPair;

typedef struct {
    Node  base;
    Node *object;
    Node *index;
} NIndex;

// CALLS AND BLOCKS
typedef struct {
    Node   base;
    Node  *receiver;
    char  *method;
    Node  *args;
    Node  *block;
    int    scope_op;
} NCall;

typedef struct {
    Node   base;
    Node **items;
    int    count;
} NArgList;

typedef struct {
    Node   base;
    Node  *params;
    Node  *body;
    int    braces;
} NBlock;

typedef struct {
    Node   base;
    char **names;
    int    count;
} NBlockParams;

// STATEMENTS
typedef struct {
    Node   base;
    Node **stmts;
    int    count;
} NStmtList;

typedef struct {
    Node  base;
    Node *value;
} NReturn;

typedef struct {
    Node base;
    int  kind;
    Node *expr;
} NPrint;

// CONTROL FLOW
typedef struct {
    Node   base;
    Node  *cond;
    Node  *body;
    Node **elsifs;
    int    elsif_count;
    Node  *else_body;
} NIf;

typedef struct {
    Node  base;
    Node *cond;
    Node *body;
} NElsif;

typedef struct {
    Node  base;
    Node *cond;
    Node *body;
    Node *else_body;
} NUnless;

typedef struct {
    Node  base;
    Node *cond;
    Node *body;
} NWhile;

typedef struct {
    Node  base;
    Node *cond;
    Node *body;
} NUntil;

typedef struct {
    Node  base;
    char *var;
    Node *iterable;
    Node *body;
} NFor;

// DEFINITIONS
typedef struct {
    Node  base;
    char *name;
    Node *params;
    Node *body;
} NDef;

typedef struct {
    Node   base;
    char **names;
    int    count;
} NParamList;

typedef struct {
    Node  base;
    char *name;
    char *parent;
    Node *body;
} NClass;

typedef struct {
    Node  base;
    char *name;
    Node *body;
} NModule;

// BEGIN / RESCUE / ENSURE
typedef struct {
    Node  base;
    Node *body;
    Node *rescue_body;
    Node *ensure_body;
} NBeginRescue;

// PROTOYPES OF CREATOR FUNCTIONS
Node *create_int(int value);
Node *create_float(double value);
Node *create_string(char *value);
Node *create_string_sq(char *value);
Node *create_symbol(char *value);
Node *create_bool(int value);
Node *create_nil(void);
Node *create_self(void);
Node *create_id(char *name);
Node *create_ivar(char *name);
Node *create_cvar(char *name);
Node *create_gvar(char *name);
Node *create_constant(char *name);
Node *create_binop(OpCode op, Node *lhs, Node *rhs);
Node *create_unop(OpCode op, Node *operand);
Node *create_ternary(Node *cond, Node *then_e, Node *else_e);
Node *create_assign(OpCode op, Node *target, Node *value);
Node *create_range(int inclusive, Node *from, Node *to);
Node *create_array(Node **items, int count);
Node *create_hash(Node **pairs, int count);
Node *create_hash_list_single(Node *pair);
Node *create_hash_list_append(Node *hash, Node *pair);
Node *create_hash_pair(Node *key, Node *value);
Node *create_index(Node *object, Node *index);
Node *create_call(Node *receiver, char *method, Node *args, Node *block, int scope_op);
Node *create_arg_list(Node *first);
Node *create_arg_list_append(Node *list, Node *item);
Node *create_block(Node *params, Node *body, int braces);
Node *create_block_params_single(char *name);
Node *create_block_params_empty(void);
Node *create_stmt_list_single(Node *stmt);
Node *create_stmt_list_append(Node *list, Node *stmt);
Node *create_stmt_list_empty(void);
Node *create_return(Node *value);
Node *create_break(void);
Node *create_next(void);
Node *create_print(int kind, Node *expr);
Node *create_if(Node *cond, Node *body, Node *elsifs, Node *else_body);
Node *create_elsif_single(Node *cond, Node *body);
Node *create_unless(Node *cond, Node *body, Node *else_body);
Node *create_while(Node *cond, Node *body);
Node *create_until(Node *cond, Node *body);
Node *create_for(char *var, Node *iterable, Node *body);
Node *create_def(char *name, Node *params, Node *body);
Node *create_param_list_single(char *name);
Node *create_param_list_append(Node *list, char *name);
Node *create_class(char *name, char *parent, Node *body);
Node *create_module(char *name, Node *body);
Node *create_begin_rescue(Node *body, Node *rescue_body, Node *ensure_body);

#endif