module lublinsql::lexer;

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
}

fn String Token.repr(Token* this) {
    return string::format(mem, "[%s: %s]", this.type, this.value);
}

fn Token make_token(String value, TokenType type) {
    Token token;
    token.value = value;
    token.type = type;
    return token;
}
