module lublinsql::lexer;

import std::collections::list;

alias Tokens = List{Token};

fn Tokens lex(String input) {
    Tokens tokens;
    tokens.init(mem);

    foreach (char c : input) {
        if (is_whitespace(c)) continue;
        
        Token token;
        token.value = string::format(mem, "%c", c);
        token.type = TokenType.UNKNOWN;
        tokens.push(token);
    }

    return tokens;
}