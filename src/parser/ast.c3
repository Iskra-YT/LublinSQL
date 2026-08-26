module lublinsql::parser;

import std::collections::list;
import std::io;

enum NodeType : {
    PROGRAM_NODE,
    NUMBER_NODE,
    BINARY_NODE,
    SQL_NODE,
    IDENTIFIER_NODE
}

typedef Node = void*;

struct NodeHeader {
    NodeType type;
}

struct ProgramNode {
    NodeType type;
    List{Node} statements;
}

struct NumberNode {
    NodeType type;
    double value;
}

struct IdentifierNode {
    NodeType type;
    String value;
}

struct BinaryNode {
    NodeType type;
    Node left;
    String op;
    Node right;
}

struct SQLNode {
    NodeType type;
    String sql;
}

fn void repr_nodes(Node node) {
    if (!node) return;
    NodeHeader* header = (NodeHeader*)node;

    switch (header.type) {
        case PROGRAM_NODE:
            ProgramNode* pn = (ProgramNode*)node;
            io::print("{PROGRAM: ");
            foreach (n : pn.statements) {
                repr_nodes(n);
            }
            io::print("};");

        case NUMBER_NODE:
            NumberNode* nn = (NumberNode*)node;
            io::printf(" (NumberNode: %f) ", nn.value);

        case IDENTIFIER_NODE:
            IdentifierNode* in = (IdentifierNode*)node;
            io::printf(" (IdentifierNode: %s) ", in.value);

        case BINARY_NODE:
            BinaryNode* bn = (BinaryNode*)node;
            io::printf(" (BinaryNode: ");
            repr_nodes(bn.left);
            io::printf(" %s ", bn.op);
            repr_nodes(bn.right);
            io::printf(") ");

        case SQL_NODE:
            SQLNode* sn = (SQLNode*)node;
            io::printf(" (SQLNode: %s) ", sn.sql);
    }
}