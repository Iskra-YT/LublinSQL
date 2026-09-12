module lublinsql::ir;

import std::collections::list;

typedef IRNode = void*;

typedef IRExpr = void*;

enum IRNodeType : {
    IR_PROGRAM,
    IR_TYPE_DECL,
    IR_TABLE_DECL,
    IR_SQL_STMT,
    IR_EXPR_STMT,
    IR_LITERAL,
    IR_IDENTIFIER,
    IR_BINARY,
    IR_CALL,
    IR_FIELD,
}

enum IRTypeKind : {
    PRIMITIVE,
    RECORD,
    ARRAY
}

enum IRPrimitive : {
    STRING,
    INT,
    DOUBLE,
    BOOL,
    NONE,
    ANY
}

struct IRHeader {
    IRNodeType type;
}

struct IRType {
    IRTypeKind kind;
    String name;
    IRType* element;
    IRTypeDecl* declaration;
}

struct IRProgram {
    IRNodeType type;
    List{IRNode} types;
    List{IRNode} tables;
    List{IRNode} statements;
}

struct IRTypeDecl {
    IRNodeType type;
    String name;
    List{IRNode} fields;
}

struct IRField {
    IRNodeType type;
    String name;
    IRType* base_type;
}

struct IRTableDecl {
    IRNodeType type;
    String name;
    IRType* element_type;
}

struct IRSqlStmt {
    IRNodeType type;
    String sql;
}

struct IRExprStmt {
    IRNodeType type;
    IRExpr expr;
}

struct IRLiteral {
    IRNodeType type;
    IRPrimitive kind;
    double number;
    String string;
    bool boolean;
}

struct IRIdentifier {
    IRNodeType type;
    String name;
    IRType* resolved;
}

struct IRBinary {
    IRNodeType type;
    String op;
    IRExpr left;
    IRExpr right;
    IRType* result;
}

struct IRCall {
    IRNodeType type;
    String callee;
    List{IRExpr} args;
    IRType* result;
}