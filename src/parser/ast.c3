module lublinsql::parser;

import std::collections::list;
import std::io;

enum NodeType : {
    PROGRAM_NODE,
    NUMBER_NODE,
    BINARY_NODE,
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

struct BinaryNode {
    NodeType type;
    Node left;
    String op;
    Node right;
}

fn void repr_nodes(Node node) {
    if (!node) return;
    NodeHeader* header = (NodeHeader*)node;

    switch (header.type) {
        case PROGRAM_NODE:
            ProgramNode* pn = (ProgramNode*)node;
            foreach (n : pn.statements) {
                repr_nodes(n);
            }

        case NUMBER_NODE:
            NumberNode* nn = (NumberNode*)node;
            io::printf(" (NumberNode: %f) ", nn.value);

        case BINARY_NODE:
            BinaryNode* bn = (BinaryNode*)node;
            io::printf(" (BinaryNode: ");
            repr_nodes(bn.left);
            io::printf(" %s ", bn.op);
            repr_nodes(bn.right);
            io::printf(")");
    }
}