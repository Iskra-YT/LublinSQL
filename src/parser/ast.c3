module lublinsql::parser;

enum NodeType : int {
    NUMBER,
    BINARY_OP
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
    return string::format(mem, "(%s %s %s)", this.left.repr(), op_symbol(this.op), this.right.repr());
}

fn void Node.free(Node* this) {
    if (this.type == NodeType.BINARY_OP) {
        this.left.free();
        this.right.free();
    }
    free(this);
}