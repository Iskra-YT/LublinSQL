module lublinsql::parser;

import std::collections::list;
import lublinsql::lexer;

struct Parser {
    Tokens tokens;
    long offset;
}

fn Token* Parser.getCurrent(Parser* this) {
    if (this.tokens.size <= this.offset) return null;
    return &this.tokens[this.offset];
}

fn bool Parser.next(Parser* this) {
    if (this.tokens.size <= this.offset) return false;

    this.offset++;
    return true;
}

fn Parser make_parser(Tokens tokens) {
    Parser p = {
        .offset = 0,
        .tokens = tokens
    };

    return p; 
}

fn int get_precedence(String op) {
    if (op == "+" || op == "-") return 1;
    if (op == "*" || op == "/") return 2;
    return 0;
}

fn Node Parser.parse_primary(Parser* this) {
    Token* token = this.getCurrent();
    if (!token) return (Node)null;

    if (token.type == TokenType.NUMBER) {
        NumberNode* node = mem::malloc(NumberNode::size);
        node.type = NodeType.NUMBER_NODE;
        node.value = token.value.to_double() ?? 0;
        this.next();
        return (Node)node;
    }

    if (token.type == TokenType.DELIMITER && token.value == "(") {
        this.next();
        Node expr = this.parse_expression();
        if (this.getCurrent() && this.getCurrent().value == ")") {
            this.next();
        }
        return expr;
    }

    return (Node)null;
}

fn Node Parser.parse_binary(Parser* this, int min_prec) {
    Node left = this.parse_primary();
    if (!left) return (Node)null;

    while (true) {
        Token* token = this.getCurrent();
        if (!token || token.type != TokenType.OPERATOR) break;

        int prec = get_precedence(token.value);
        if (prec < min_prec) break;

        String op = token.value;
        this.next();

        Node right = this.parse_binary(prec + 1);
        if (!right) break;

        BinaryNode* node = mem::malloc(BinaryNode::size);
        node.type = NodeType.BINARY_NODE;
        node.left = left;
        node.op = op;
        node.right = right;
        left = (Node)node;
    }

    return left;
}

fn Node Parser.parse_expression(Parser* this) {
    return this.parse_binary(0);
}

fn Node Parser.parse_statement(Parser* this) {
    Node expr = this.parse_expression();
    if (!expr) return (Node)null;

    this.next();
    return expr;
}

fn Node Parser.parse(Parser* this) {
    List{Node} nodes;
    nodes.init(mem);

    while (this.getCurrent()) {
        Node statement = this.parse_statement();
        if (!statement) {
            this.next();
            continue;
        }

        nodes.push(statement);
    }

    ProgramNode* programNode = mem::malloc(ProgramNode::size);
    programNode.statements = nodes;
    programNode.type = NodeType.PROGRAM_NODE;

    return (Node)programNode;
}