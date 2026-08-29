module lublinsql::parser;

import lublinsql::lexer;
import lublinsql::position;

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

fn Resulter Parser.parseType(Parser* this) {
    Token* current = this.getCurrent();
    if (!current || !current.matches("type", TokenType.KEYWORD)) {
        return makeFailureResult("expected keyword 'type'", current ? current.position : (PositionVector){});
    }
    this.next();

    TypeNode* type_node = mem::malloc(TypeNode::size);
    type_node.type = NodeType.TYPE_NODE;
    type_node.elements.init(mem);

    current = this.getCurrent();
    if (!current || current.type != TokenType.IDENTIFIER) {
        return makeFailureResult("expected identifier after 'type'", current ? current.position : (PositionVector){});
    }

    Resulter name = this.parsePrimary();
    if (name.isError()) return name;
    type_node.name = name.value;

    current = this.getCurrent();
    if (!current.matches("{", TokenType.DELIMITER)) {
        return makeFailureResult("expected token '{", current ? current.position : (PositionVector){});
    }

    this.next();

    while (this.getCurrent() && !this.getCurrent().matches("}", TokenType.DELIMITER)) {
        Resulter result = this.parseTypeElement();
        if (result.isError()) return result;
        type_node.elements.push(result.value);
    }

    this.next();
    return makeSuccessResult((Node)type_node);
}

fn Resulter Parser.parseTypeElement(Parser* this) {
    TypeElementNode* element_node = mem::malloc(TypeElementNode::size);
    element_node.type = NodeType.TYPE_ELEMENT_NODE;

    if (this.getCurrent().type != TokenType.IDENTIFIER) {
        return makeFailureResult("expected identifier", this.getCurrent().position);
    }

    Resulter name = this.parsePrimary();
    if (name.isError()) return name;
    element_node.name = name.value;

    if (!this.getCurrent().matches(":", TokenType.DELIMITER)) {
        return makeFailureResult("expected ':'", this.getCurrent().position);
    }

    this.next();
    if (this.getCurrent().type != TokenType.IDENTIFIER) {
        return makeFailureResult("expected identifier", this.getCurrent().position);
    }

    Resulter type = this.parsePrimary();
    if (type.isError()) return type;
    element_node.element_type = type.value;

    return makeSuccessResult((Node)element_node);
}

fn Resulter Parser.parseTable(Parser* this) {
    if (!this.getCurrent().matches("table", TokenType.KEYWORD)) {
        return makeFailureResult("expected 'table' keyword", this.getCurrent().position);
    }

    TableNode* table_node = mem::malloc(TableNode::size);
    table_node.type = NodeType.TABLE_NODE;

    this.next();

    if (this.getCurrent().type != TokenType.IDENTIFIER) {
        return makeFailureResult("expected identifier", this.getCurrent().position);
    }

    Resulter name = this.parsePrimary();
    if (name.isError()) return name;
    table_node.name = name.value;

    if (!this.getCurrent().matches(":", TokenType.DELIMITER)) {
        return makeFailureResult("expected ':'", this.getCurrent().position);
    }

    this.next();

    if (this.getCurrent().type != TokenType.IDENTIFIER) {
        return makeFailureResult("expected identifier", this.getCurrent().position);
    }

    Resulter type = this.parsePrimary();
    if (type.isError()) return type;
    table_node.table_type = type.value;

    return makeSuccessResult((Node)table_node);
}