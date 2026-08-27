module lublinsql::lexer;

import lublinsql::position;

enum TokenType : int {
    UNKNOWN,
    IDENTIFIER,
    KEYWORD,
    OPERATOR,
    DELIMITER,
    NUMBER,
    STRING
}

struct Token {
    String value;
    TokenType type;
    PositionVector position;
}

fn String Token.repr(Token* this) {
    return string::format(mem, "[%s: %s]", this.type, this.value);
}

fn Token makeToken(String value, TokenType type, Position start, Position end) {
    Token token;
    token.value = value;
    token.type = type;
    token.position = {
        .start = start,
        .end = end
    };
    
    return token;
}

fn bool Token.matches(Token* this, String value, TokenType type) {
    return this.type == type && this.value == value;
}
