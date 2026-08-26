module lublinsql::parser;

import lublinsql::lexer;

struct Parser {
    lexer::Tokens tokens;
    int pos;
}

fn Parser make_parser(lexer::Tokens tokens) {
    Parser p;
    p.tokens = tokens;
    p.pos = 0;
    return p;
}

fn lexer::Token* Parser.peek(Parser* this) {
    if (this.pos >= this.tokens.len()) return null;
    return &this.tokens[this.pos];
}

fn lexer::Token Parser.advance(Parser* this) {
    lexer::Token t = this.tokens[this.pos];
    this.pos++;
    return t;
}

fn bool Parser.match(Parser* this, String value) {
    lexer::Token* t = this.peek();
    if (t && t.value == value && t.type == lexer::TokenType.OPERATOR) {
        this.advance();
        return true;
    }
    return false;
}

fn Node* Parser.parse_factor(Parser* this) {
    lexer::Token* t = this.peek();
    if (!t) return null;

    if (t.type == lexer::TokenType.NUMBER) {
        this.advance();
        double val = t.value.to_double() ?? 0;
        return make_number_node(val);
    }

    if (t.value == "(" && t.type == lexer::TokenType.DELIMITER) {
        this.advance();
        Node* expr = this.parse_expression();
        if (!expr) return null;
        lexer::Token* close = this.peek();
        if (close && close.value == ")" && close.type == lexer::TokenType.DELIMITER) {
            this.advance();
            return expr;
        }
        expr.free();
        return null;
    }

    return null;
}

fn Node* Parser.parse_term(Parser* this) {
    Node* left = this.parse_factor();
    if (!left) return null;

    while (this.peek() && (this.peek().value == "*" || this.peek().value == "/")) {
        lexer::Token op = this.advance();
        Node* right = this.parse_factor();
        if (!right) {
            left.free();
            return null;
        }
        OpType op_type;
        if (op.value == "*") {
            op_type = OpType.MUL;
        } else {
            op_type = OpType.DIV;
        }
        left = make_binop_node(op_type, left, right);
    }

    return left;
}

fn Node* Parser.parse_expression(Parser* this) {
    Node* left = this.parse_term();
    if (!left) return null;

    while (this.peek() && (this.peek().value == "+" || this.peek().value == "-")) {
        lexer::Token op = this.advance();
        Node* right = this.parse_term();
        if (!right) {
            left.free();
            return null;
        }
        OpType op_type;
        if (op.value == "+") {
            op_type = OpType.ADD;
        } else {
            op_type = OpType.SUB;
        }
        left = make_binop_node(op_type, left, right);
    }

    return left;
}

fn Node* parse(lexer::Tokens tokens) {
    Parser p = make_parser(tokens);
    Node* result = p.parse_expression();
    return result;
}