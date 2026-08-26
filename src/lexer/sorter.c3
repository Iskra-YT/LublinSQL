module lublinsql::lexer;

String whitespaces = " \t\n\r";

fn bool is_whitespace(char c) {
    String s = string::format(mem, "%c", c);
    defer s.free(mem);
    return whitespaces.contains(s);
}

fn bool is_number(char c) {
    return c >= '0' && c <= '9';
}

fn bool is_dot(char c) {
    return c == '.';
}
