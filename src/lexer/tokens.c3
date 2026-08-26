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