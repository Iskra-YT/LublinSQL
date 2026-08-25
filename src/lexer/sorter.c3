module lublinsql::lexer;

String whitespaces = " \t\n\r";

fn bool is_whitespace(char c) {
    String s = string::format(mem, "%c", c);
    defer s.free(mem);

    return whitespaces.contains(s);
}