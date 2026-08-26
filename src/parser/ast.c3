module lublinsql::parser;

import std::collections::list;

enum NodeType : int {
    NUMBER,
    BINARY_OP,
    SQL_STATEMENT,
    PROGRAM
}

enum OpType : int {
    ADD,
    SUB,
    MUL,
    DIV
}

struct Node {
    NodeType type;
    double num_value;
    OpType op;
    Node* left;
    Node* right;
    String sql_body;
    List{Node*} nodes;
}

fn Node* make_number_node(double value) {
    Node* n = mem::new(Node);
    n.type = NodeType.NUMBER;
    n.num_value = value;
    return n;
}

fn Node* make_binop_node(OpType op, Node* left, Node* right) {
    Node* n = mem::new(Node);
    n.type = NodeType.BINARY_OP;
    n.op = op;
    n.left = left;
    n.right = right;
    return n;
}

fn Node* make_sql_statement_node(String body) {
    Node* n = mem::new(Node);
    n.type = NodeType.SQL_STATEMENT;
    n.sql_body = body;
    return n;
}

fn Node* make_program_node() {
    Node* n = mem::new(Node);
    n.type = NodeType.PROGRAM;
    n.nodes.init(mem);
    return n;
}

fn String op_symbol(OpType op) {
    switch (op) {
        case OpType.ADD: return "+";
        case OpType.SUB: return "-";
        case OpType.MUL: return "*";
        case OpType.DIV: return "/";
        default: return "?";
    }
}

fn String Node.repr(Node* this) {
    if (this.type == NodeType.NUMBER) {
        return string::format(mem, "%g", this.num_value);
    }
    if (this.type == NodeType.SQL_STATEMENT) {
        return string::format(mem, "sql { %s }", this.sql_body);
    }
    if (this.type == NodeType.PROGRAM) {
        String result = "";
        for (int i = 0; i < this.nodes.len(); i++) {
            String child_repr = this.nodes[i].repr();
            if (i > 0) {
                result = string::format(mem, "%s\n%s", result, child_repr);
            } else {
                result = child_repr;
            }
        }
        return result;
    }
    return string::format(mem, "(%s %s %s)", this.left.repr(), op_symbol(this.op), this.right.repr());
}

fn void Node.free(Node* this) {
    if (this.type == NodeType.BINARY_OP) {
        this.left.free();
        this.right.free();
    }
    if (this.type == NodeType.PROGRAM) {
        for (int i = 0; i < this.nodes.len(); i++) {
            this.nodes[i].free();
        }
        this.nodes.free();
    }
    if (this.sql_body) this.sql_body.free(mem);
    free(this);
}