module lublinsql::lexer;

import std::collections::list;

alias Tokens = List{Token};

fn Tokens lex(String input) {
    Tokens tokens;
    tokens.init(mem);

    int i = 0;
    int len = (int)input.len;

    for (; i < len; i++) {
        char c = input[i];

        if (is_whitespace(c)) continue;

        if (ascii::is_digit(c) || (is_dot(c) && i + 1 < len && ascii::is_digit(input[i + 1]))) {
            Token token = lex_number(input, &i);
            tokens.push(token);
            i--;
            continue;
        }

        if (ascii::is_alpha(c) || c == '_' || c == '@') {
            Token token = lex_identifier(input, &i);
            tokens.push(token);
            i--;
            continue;
        }

        if (c == '"' || c == '\'') {
            Token token = lex_string(input, &i);
            tokens.push(token);
            i--;
            continue;
        }

        Token token;
        token.value = string::format(mem, "%c", c);
        token.type = TokenType.UNKNOWN;
        tokens.push(token);
    }

    return tokens;
}

fn void read_digits(String input, int* pos) {
    int len = (int)input.len;
    while (*pos < len && ascii::is_digit(input[*pos])) {
        (*pos)++;
    }
}

fn Token lex_number(String input, int* pos) {
    int start = *pos;
    int len = (int)input.len;

    if (*pos < len && is_dot(input[*pos])) {
        (*pos)++;
        read_digits(input, pos);
        return make_token(input[start : *pos - start], TokenType.NUMBER);
    }

    read_digits(input, pos);

    if (*pos < len && is_dot(input[*pos])) {
        int dot_pos = *pos + 1;
        if (dot_pos < len && ascii::is_digit(input[dot_pos])) {
            (*pos)++;
            read_digits(input, pos);
        }
    }

    return make_token(input[start : *pos - start], TokenType.NUMBER);
}

fn Token lex_identifier(String input, int* pos) {
    int start = *pos;
    int len = (int)input.len;

    while (*pos < len && (ascii::is_digit(input[*pos]) || ascii::is_alpha(input[*pos]) || input[*pos] == '_' || input[*pos] == '@')) {
        (*pos)++;
    }

    return make_token(input[start : *pos - start], TokenType.IDENTIFIER);
}

fn Token lex_string(String input, int* pos) {
    int start = *pos;
    int len = (int)input.len;
    char quote = input[*pos];

    (*pos)++;

    while (*pos < len && input[*pos] != quote) {
        (*pos)++;
    }

    if (*pos < len) {
        (*pos)++;
    }

    return make_token(input[start : *pos - start], TokenType.STRING);
}
