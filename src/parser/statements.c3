module lublinsql::parser;

import lublinsql::lexer;

fn Node Parser.parse_sql(Parser* this) {
    if (!this.getCurrent().matches("sql", TokenType.KEYWORD)) return (Node)null;
    this.next();

    if (!this.getCurrent().matches("{", TokenType.DELIMITER)) return (Node)null;
    this.next();

    SQLNode* node = mem::malloc(SQLNode::size);
    node.type = NodeType.SQL_NODE;
    
    if (!(this.getCurrent().type == TokenType.STRING)) return (Node)null;

    node.sql = this.getCurrent().value;
    return (Node)node;
}