module lublinsql::parser;

import std::collections::list;
import lublinsql::lexer;
import lublinsql::position;

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

fn Parser makeParser(Tokens tokens) {
    Parser parser_state = {
        .offset = 0,
        .tokens = tokens
    };

    return parser_state;
}

fn int getPrecedence(String op) {
    if (op == "+" || op == "-") return 1;
    if (op == "*" || op == "/") return 2;
    return 0;
}

fn Resulter Parser.parsePrimary(Parser* this) {
    Token* token = this.getCurrent();
    if (!token) return makeFailureResult("unexpected end of input", (PositionVector){});

    if (token.type == TokenType.NUMBER) {
        NumberNode* node = mem::malloc(NumberNode::size);
        node.type = NodeType.NUMBER_NODE;
        node.value = token.value.to_double() ?? 0;
        this.next();
        return makeSuccessResult((Node)node);
    }

    if (token.type == TokenType.DELIMITER && token.value == "(") {
        this.next();
        Resulter expr = this.parseExpression();
        if (expr.isError()) return expr;
        if (this.getCurrent() && this.getCurrent().value == ")") {
            this.next();
        }
        return expr;
    }

    if (token.type == TokenType.STRING) {
        StringLiteralNode* node = mem::malloc(StringLiteralNode::size);
        node.type = NodeType.STRING_LITERAL_NODE;
        node.value = token.value[1 : token.value.len - 2];
        this.next();
        return makeSuccessResult((Node)node);
    }

    if (token.type == TokenType.IDENTIFIER) {
        IdentifierNode* node = mem::malloc(IdentifierNode::size);
        node.type = NodeType.IDENTIFIER_NODE;
        node.value = token.value;
        this.next();

        Token* next = this.getCurrent();
        if (next && next.matches("(", TokenType.DELIMITER)) {
            this.next();
            return this.parseFunctionCall((Node)node);
        }

        return makeSuccessResult((Node)node);
    }

    return makeFailureResult(string::format(mem, "unexpected token '%s'", token.value), token.position);
}

fn Resulter Parser.parseBinary(Parser* this, int min_prec) {
    Resulter left_result = this.parsePrimary();
    if (left_result.isError()) return left_result;
    Node left = left_result.value;

    while (true) {
        Token* token = this.getCurrent();
        if (!token || token.type != TokenType.OPERATOR) break;

        int prec = getPrecedence(token.value);
        if (prec < min_prec) break;

        String op = token.value;
        this.next();

        Resulter right_result = this.parseBinary(prec + 1);
        if (right_result.isError()) break;

        BinaryNode* node = mem::malloc(BinaryNode::size);
        node.type = NodeType.BINARY_NODE;
        node.left = left;
        node.op = op;
        node.right = right_result.value;
        left = (Node)node;
    }

    return makeSuccessResult(left);
}

fn Resulter Parser.parseExpression(Parser* this) {
    return this.parseBinary(0);
}

fn Resulter Parser.parseFunctionCall(Parser* this, Node callee) {
    FunctionCallNode* node = mem::malloc(FunctionCallNode::size);
    node.type = NodeType.FUNCTION_CALL_NODE;
    node.callee = callee;
    node.args.init(mem);

    while (this.getCurrent() && !this.getCurrent().matches(")", TokenType.DELIMITER)) {
        Resulter argument = this.parseExpression();
        if (argument.isError()) return argument;
        node.args.push(argument.value);

        Token* current = this.getCurrent();
        if (current && current.matches(",", TokenType.DELIMITER)) {
            this.next();
            if (this.getCurrent() && this.getCurrent().matches(")", TokenType.DELIMITER)) break;
        }
    }

    Token* current = this.getCurrent();
    if (!current || !current.matches(")", TokenType.DELIMITER)) {
        return makeFailureResult("expected ')' after function call arguments", current ? current.position : (PositionVector){});
    }

    this.next();
    return makeSuccessResult((Node)node);
}

fn Resulter Parser.parseStatement(Parser* this) {
    Token* current = this.getCurrent();
    if (current.matches("sql", TokenType.KEYWORD)) {
        Resulter sql = this.parseSql();
        if (sql.isError()) return sql;

        if (this.getCurrent() && this.getCurrent().matches(";", TokenType.DELIMITER)) this.next();
        return sql;
    } else if (current.matches("type", TokenType.KEYWORD)) {
        Resulter type = this.parseType();
        if (type.isError()) return type;

        if (this.getCurrent() && this.getCurrent().matches(";", TokenType.DELIMITER)) this.next();
        return type;
    } else if (current.matches("table", TokenType.KEYWORD)) {
        Resulter table = this.parseTable();
        if (table.isError()) return table;

        if (this.getCurrent() && this.getCurrent().matches(";", TokenType.DELIMITER)) this.next();
        return table;
    }

    Resulter expr = this.parseExpression();
    if (expr.isError()) return expr;

    if (this.getCurrent() && this.getCurrent().matches(";", TokenType.DELIMITER)) this.next();

    return expr;
}

fn Resulter Parser.parse(Parser* this) {
    List{Node} nodes;
    nodes.init(mem);

    while (this.getCurrent()) {
        Resulter statement = this.parseStatement();
        if (statement.isError()) {
            this.next();
            continue;
        }

        nodes.push(statement.value);
    }

    ProgramNode* program_node = mem::malloc(ProgramNode::size);
    program_node.statements = nodes;
    program_node.type = NodeType.PROGRAM_NODE;

    return makeSuccessResult((Node)program_node);
}