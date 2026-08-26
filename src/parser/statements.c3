module lublinsql::parser;

import lublinsql::lexer;

fn Node* parse_sql_statement(Parser* p) {
    p.advance();
    lexer::Token* open = p.peek();
    if (!open || open.value != "{" || open.type != lexer::TokenType.DELIMITER) return null;
    p.advance();

    String body = "";
    int depth = 1;
    while (p.peek() && depth > 0) {
        lexer::Token cur = p.advance();
        if (cur.value == "{" && cur.type == lexer::TokenType.DELIMITER) {
            depth++;
            if (body.len > 0) {
                body = string::format(mem, "%s {", body);
            } else {
                body = string::format(mem, "{");
            }
        } else if (cur.value == "}" && cur.type == lexer::TokenType.DELIMITER) {
            depth--;
            if (depth > 0) {
                body = string::format(mem, "%s }", body);
            }
        } else {
            if (body.len > 0) {
                body = string::format(mem, "%s %s", body, cur.value);
            } else {
                body = string::format(mem, "%s", cur.value);
            }
        }
    }

    if (depth != 0) {
        body.free(mem);
        return null;
    }

    return make_sql_statement_node(body);
}
