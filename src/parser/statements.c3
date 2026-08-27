module lublinsql::parser;

import lublinsql::lexer;

import std::io;

fn Node Parser.parse_sql(Parser* this) {
    if (!this.getCurrent() || !this.getCurrent().matches("sql", TokenType.KEYWORD)) return (Node)null;
    this.next();

    if (!this.getCurrent() || !this.getCurrent().matches("{", TokenType.DELIMITER)) return (Node)null;
    this.next();

    SQLNode* node = mem::malloc(SQLNode::size);
    node.type = NodeType.SQL_NODE;

    DString ds;
    
    while (this.getCurrent() != null && this.getCurrent().value != "}") {
        ds.appendf("%s ", this.getCurrent().value);
        this.next();
    }

    if (this.getCurrent() != null) this.next();

    node.sql = ds.copy_str(mem);

    return (Node)node;
}