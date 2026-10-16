#ifndef TREE_NODES_H
#define TREE_NODES_H

// NODE TYPES
typedef enum {
    // Literals
    N_INT, N_FLOAT, N_STRING, N_STRING_SQ, N_SYMBOL,
    N_TRUE, N_FALSE, N_NIL, N_SELF,

    // Identifiers
    N_ID, N_IVAR, N_CVAR, N_GVAR, N_CONSTANT,

    // Expressions
    N_BINOP, N_UNOP, N_TERNARY, N_ASSIGN, N_RANGE,

    // Collections
    N_ARRAY, N_HASH, N_HASH_PAIR, N_INDEX,

    // Calls and blocks
    N_CALL, N_ARG_LIST, N_BLOCK, N_BLOCK_PARAMS,

    // Program and statements
    N_STMT_LIST, N_RETURN, N_BREAK, N_NEXT, N_PRINT,

    // Control flow
    N_IF, N_ELSIF, N_UNLESS, N_WHILE, N_UNTIL, N_FOR,

    // Definitions
    N_DEF, N_PARAM_LIST, N_CLASS, N_MODULE,

    // Begin / rescue
    N_BEGIN_RESCUE
} NodeType;

// OPERATOR CODES
typedef enum {
    OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_MOD, OP_POW,
    OP_EQ, OP_NEQ, OP_LT, OP_GT, OP_LE, OP_GE,
    OP_CMP, OP_CASE_EQ,
    OP_AND, OP_OR,
    OP_KW_AND, OP_KW_OR,
    OP_LSHIFT, OP_RSHIFT,
    OP_BITAND, OP_BITOR, OP_BITXOR,
    OP_NOT, OP_KW_NOT,
    OP_NEG, OP_POS,
    OP_PLUS_ASSIGN, OP_MINUS_ASSIGN,
    OP_MUL_ASSIGN, OP_DIV_ASSIGN
} OpCode;

// PRINT KINDS
typedef enum {
    PRINT_PUTS, PRINT_PRINT, PRINT_P
} PrintKind;

// BASE NODE - every concrete node starts with this
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
    Node  base;
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

// PROGRAM AND STATEMENTS
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

// YYSTYPE - union for Bison semantic values
union YYSTYPE {
    int          intval;
    double       floatval;
    char        *strval;
    struct Node *node;
};

#endif // TREE_NODES_H