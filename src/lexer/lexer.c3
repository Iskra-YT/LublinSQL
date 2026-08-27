module lublinsql::lexer;

import std::collections::list;
import lublinsql::position;

alias Tokens = List{Token};

const String[] KEYWORDS = { "sql" };

fn Position step(Position p, char c) {
    p.index++;
    if (c == '\n') {
        p.column = 0;
        p.line++;
    } else {
        p.column++;
    }
    return p;
}

fn Position skip(Position p, String input, int from, int to) {
    for (int k = from; k < to; k++) {
        p = step(p, input[k]);
    }
    return p;
}

fn Tokens lex(String input) {
    Tokens tokens;
    tokens.init(mem);

    int i = 0;
    int len = (int)input.len;
    Position pos = {
        .index = -1,
        .column = 0,
        .line = 1
    };

    while (i < len) {
        int from = i;
        Position start = step(pos, input[i]);
        char c = input[i];

        if (c == '\n' || ascii::is_blank(c)) {
            pos = start;
            i++;
            continue;
        }

        if (c == '/' && i + 1 < len && input[i + 1] == '/') {
            while (i < len && input[i] != '\n') {
                i++;
            }
            pos = skip(pos, input, from, i);
            continue;
        }

        if (ascii::is_digit(c) || (c == '.' && i + 1 < len && ascii::is_digit(input[i + 1]))) {
            Token token = lexNumber(input, &i, start);
            tokens.push(token);
            pos = skip(pos, input, from, i);
            continue;
        }

        if (ascii::is_alpha(c) || c == '_' || c == '@') {
            Token token = lexIdentifier(input, &i, start);
            tokens.push(token);
            pos = skip(pos, input, from, i);
            continue;
        }

        if (c == '"' || c == '\'') {
            Token token = lexString(input, &i, start);
            tokens.push(token);
            pos = skip(pos, input, from, i);
            continue;
        }

        if (c == '+' || c == '-' || c == '*' || c == '/') {
            i++;
            Position end = skip(start, input, from, i);
            Token token = makeToken(input[from : i - from], TokenType.OPERATOR, start, end);
            tokens.push(token);
            pos = skip(pos, input, from, i);
            continue;
        }

        if (c == '~' && i + 1 < len && input[i + 1] == '=') {
            i += 2;
            Position end = skip(start, input, from, i);
            Token token = makeToken("~=", TokenType.OPERATOR, start, end);
            tokens.push(token);
            pos = skip(pos, input, from, i);
            continue;
        }

        if (c == ':' || c == '(' || c == ')' || c == '{' || c == '}' || c == '[' || c == ']' || c == ',' || c == ';') {
            i++;
            Position end = skip(start, input, from, i);
            Token token = makeToken(input[from : i - from], TokenType.DELIMITER, start, end);
            tokens.push(token);
            pos = skip(pos, input, from, i);
            continue;
        }

        i++;
        Position end = skip(start, input, from, i);
        Token token = makeToken(input[from : i - from], TokenType.UNKNOWN, start, end);
        tokens.push(token);
        pos = skip(pos, input, from, i);
    }

    return tokens;
}

fn void readDigits(String input, int* pos) {
    int len = (int)input.len;
    while (*pos < len && ascii::is_digit(input[*pos])) {
        (*pos)++;
    }
}

fn Token lexNumber(String input, int* pos, Position start) {
    int begin = *pos;
    int len = (int)input.len;

    if (*pos < len && input[*pos] == '.') {
        (*pos)++;
        readDigits(input, pos);
        Position end = skip(start, input, begin, *pos);
        return makeToken(input[begin : *pos - begin], TokenType.NUMBER, start, end);
    }

    readDigits(input, pos);

    if (*pos < len && input[*pos] == '.') {
        int dot_pos = *pos + 1;
        if (dot_pos < len && ascii::is_digit(input[dot_pos])) {
            (*pos)++;
            readDigits(input, pos);
        }
    }

    Position end = skip(start, input, begin, *pos);
    return makeToken(input[begin : *pos - begin], TokenType.NUMBER, start, end);
}

fn Token lexIdentifier(String input, int* pos, Position start) {
    int begin = *pos;
    int len = (int)input.len;

    while (*pos < len && (ascii::is_digit(input[*pos]) || ascii::is_alpha(input[*pos]) || input[*pos] == '_' || input[*pos] == '@')) {
        (*pos)++;
    }

    String value = input[begin : *pos - begin];
    Position end = skip(start, input, begin, *pos);
    for (int i = 0; i < KEYWORDS.len; i++) {
        if (value == KEYWORDS[i]) {
            return makeToken(value, TokenType.KEYWORD, start, end);
        }
    }
    return makeToken(value, TokenType.IDENTIFIER, start, end);
}

fn Token lexString(String input, int* pos, Position start) {
    int begin = *pos;
    int len = (int)input.len;
    char quote = input[*pos];

    (*pos)++;

    while (*pos < len && input[*pos] != quote) {
        (*pos)++;
    }

    if (*pos < len) {
        (*pos)++;
    }

    Position end = skip(start, input, begin, *pos);
    return makeToken(input[begin : *pos - begin], TokenType.STRING, start, end);
}
