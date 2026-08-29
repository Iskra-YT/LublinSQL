module lublinsql::parser;

import std::collections::list;
import std::io;

enum NodeType : {
    PROGRAM_NODE,
    NUMBER_NODE,
    STRING_LITERAL_NODE,
    FUNCTION_CALL_NODE,
    BINARY_NODE,
    SQL_NODE,
    IDENTIFIER_NODE,
    TYPE_NODE,
    TYPE_ELEMENT_NODE,
    TABLE_NODE,
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

struct StringLiteralNode {
    NodeType type;
    String value;
}

struct FunctionCallNode {
    NodeType type;
    Node callee;
    List{Node} args;
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

struct TypeElementNode {
    NodeType type;
    Node name;
    Node element_type;
}

struct TypeNode {
    NodeType type;
    Node name;
    List{Node} elements;
}

struct TableNode {
    NodeType type;
    Node name;
    Node table_type;
}

fn void reprNodes(Node node) {
    if (!node) return;
    NodeHeader* header = (NodeHeader*)node;

    switch (header.type) {
        case PROGRAM_NODE:
            ProgramNode* program_node = (ProgramNode*)node;
            io::print("{PROGRAM: ");
            foreach (n : program_node.statements) {
                reprNodes(n);
            }
            io::print("};");

        case NUMBER_NODE:
            NumberNode* number_node = (NumberNode*)node;
            io::printf(" (NumberNode: %f) ", number_node.value);

        case STRING_LITERAL_NODE:
            StringLiteralNode* string_literal_node = (StringLiteralNode*)node;
            io::printf(" (StringLiteralNode: %s) ", string_literal_node.value);

        case FUNCTION_CALL_NODE:
            FunctionCallNode* function_call_node = (FunctionCallNode*)node;
            io::printf(" (FunctionCallNode: ");
            reprNodes(function_call_node.callee);
            io::printf("(");
            foreach (n : function_call_node.args) {
                reprNodes(n);
            }
            io::printf(")) ");

        case IDENTIFIER_NODE:
            IdentifierNode* identifier_node = (IdentifierNode*)node;
            io::printf(" (IdentifierNode: %s) ", identifier_node.value);

        case BINARY_NODE:
            BinaryNode* binary_node = (BinaryNode*)node;
            io::printf(" (BinaryNode: ");
            reprNodes(binary_node.left);
            io::printf(" %s ", binary_node.op);
            reprNodes(binary_node.right);
            io::printf(") ");

        case SQL_NODE:
            SQLNode* sql_node = (SQLNode*)node;
            io::printf(" (SQLNode: %s) ", sql_node.sql);

        case TYPE_NODE:
            TypeNode* type_node = (TypeNode*)node;
            io::printf(" (TypeNode: ");
            reprNodes(type_node.name);
            foreach (n : type_node.elements) {
                reprNodes(n);
            }
            io::printf(" ) ");

        case TYPE_ELEMENT_NODE:
            TypeElementNode* type_element_node = (TypeElementNode*)node;
            io::printf(" (TypeElementNode: ");
            reprNodes(type_element_node.name);
            reprNodes(type_element_node.element_type);
            io::printf(" ) ");

        case TABLE_NODE:
            TableNode* table_node = (TableNode*)node;
            io::printf(" (TableNode: ");
            reprNodes(table_node.name);
            io::printf(" : ");
            reprNodes(table_node.table_type);
            io::printf(" ) ");

        default:
            io::printf(" (UnknownNode)");
    }
}