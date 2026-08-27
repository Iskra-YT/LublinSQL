module lublinsql::parser;

import lublinsql::lexer;
import lublinsql::position;

import std::io;

fn Resulter Parser.parseSql(Parser* this) {
    Token* current = this.getCurrent();
    if (!current || !current.matches("sql", TokenType.KEYWORD)) {
        return makeFailureResult("expected keyword 'sql'", current ? current.position : (PositionVector){});
    }
    this.next();

    current = this.getCurrent();
    if (!current || !current.matches("{", TokenType.DELIMITER)) {
        return makeFailureResult("expected '{' after 'sql'", current ? current.position : (PositionVector){});
    }
    this.next();

    SQLNode* node = mem::malloc(SQLNode::size);
    node.type = NodeType.SQL_NODE;

    DString sql_buffer;

    while (true) {
        current = this.getCurrent();
        if (current == null) return makeFailureResult("unterminated sql block", (PositionVector){});
        if (current.value == "}") break;

        sql_buffer.appendf("%s ", current.value);
        this.next();
    }

    this.next();

    node.sql = sql_buffer.copy_str(mem);

    return makeSuccessResult((Node)node);
}