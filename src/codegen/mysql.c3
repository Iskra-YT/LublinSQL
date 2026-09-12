module lublinsql::codegen::mysql;

import lublinsql::codegen;
import lublinsql::error;
import lublinsql::ir;
import lublinsql::position;

fn bool generate(IRProgram* program, SQLWriter* out) {
    if (!program) return false;

    bool ok = true;

    foreach (IRNode node : program.tables) {
        if (!generateTable((IRTableDecl*)node, out)) ok = false;
    }

    foreach (IRNode node : program.statements) {
        if (!generateStatement(node, out)) ok = false;
    }

    return ok;
}

fn bool generateTable(IRTableDecl* table, SQLWriter* out) {
    IRType* element = table.element_type;
    if (!element || element.kind != IRTypeKind.ARRAY || !element.element) return false;
    IRType* record = element.element;
    if (!record || record.kind != IRTypeKind.RECORD || !record.declaration) return false;

    bool ok = true;
    out.write(string::format(mem, "CREATE TABLE %s (\n", table.name));

    bool first = true;
    foreach (IRNode field_node : record.declaration.fields) {
        IRField* field = (IRField*)field_node;
        if (!first) out.write(",\n");
        first = false;

        String column_type;
        if (!mapSqlType(field.base_type, &column_type)) {
            error::createError(string::format(mem, "column '%s' of table '%s' uses unsupported type", field.name, table.name), (PositionVector){});
            ok = false;
            continue;
        }

        out.write(string::format(mem, "    %s %s", field.name, column_type));
    }

    out.write("\n);\n");
    return ok;
}

fn bool mapSqlType(IRType* type, String* result) {
    switch (type.kind) {
        case IRTypeKind.PRIMITIVE: return mapPrimitive(type.name, result);
        default: return false;
    }
}

fn bool mapPrimitive(String name, String* result) {
    if (name == "String") { *result = "VARCHAR(255)"; return true; }
    if (name == "Int") { *result = "INT"; return true; }
    if (name == "Double") { *result = "DOUBLE"; return true; }
    if (name == "Bool") { *result = "BOOLEAN"; return true; }
    return false;
}

fn bool generateStatement(IRNode node, SQLWriter* out) {
    IRHeader* header = (IRHeader*)node;
    switch (header.type) {
        case IR_SQL_STMT: {
            IRSqlStmt* stmt = (IRSqlStmt*)node;
            out.write(stmt.sql);
            out.writeln();
            return true;
        }

        case IR_EXPR_STMT: {
            return generateExprStmt((IRExprStmt*)node, out);
        }

        default: {
            return true;
        }
    }
}

fn bool generateExprStmt(IRExprStmt* stmt, SQLWriter* out) {
    IRHeader* header = (IRHeader*)stmt.expr;
    switch (header.type) {
        case IR_CALL: {
            IRCall* call = (IRCall*)stmt.expr;
            if (call.callee == "print") return generatePrint(call, out);

            error::createError(string::format(mem, "unsupported function '%s' in mysql backend", call.callee), (PositionVector){});
            return false;
        }

        default: {
            DString sql;
            sql.init(mem);
            if (!renderExpression(stmt.expr, &sql)) return false;

            String select = sql.copy_str(mem);
            defer select.free(mem);

            out.write("SELECT ");
            out.write(select);
            out.write(";\n");
            return true;
        }
    }
}

fn bool generatePrint(IRCall* call, SQLWriter* out) {
    if (call.args.size == 1) {
        IRHeader* header = (IRHeader*)call.args[0];
        if (header.type == IR_IDENTIFIER) {
            IRIdentifier* identifier = (IRIdentifier*)call.args[0];
            if (identifier.resolved && identifier.resolved.kind == IRTypeKind.ARRAY) {
                out.write(string::format(mem, "SELECT * FROM %s;\n", identifier.name));
                return true;
            }
        }
    }

    DString select;
    select.init(mem);
    DString from;
    from.init(mem);

    bool from_first = true;
    foreach (int idx, IRExpr argument : call.args) {
        IRHeader* header = (IRHeader*)argument;
        if (idx > 0) select.appendf(", ");

        IRIdentifier* identifier = null;
        if (header.type == IR_IDENTIFIER) {
            identifier = (IRIdentifier*)argument;
        }

        if (identifier && identifier.resolved && identifier.resolved.kind == IRTypeKind.ARRAY) {
            select.appendf("%s.*", identifier.name);
            if (!from_first) from.appendf(", ");
            from.appendf("%s", identifier.name);
            from_first = false;
            continue;
        }

        if (!renderExpression(argument, &select)) return false;
    }

    String select_text = select.copy_str(mem);
    defer select_text.free(mem);

    out.write("SELECT ");
    out.write(select_text);
    if (!from_first) {
        String from_text = from.copy_str(mem);
        defer from_text.free(mem);
        out.write(string::format(mem, " FROM %s", from_text));
    }
    out.write(";\n");
    return true;
}

fn bool renderExpression(IRExpr expr, DString* sql) {
    IRHeader* header = (IRHeader*)expr;
    switch (header.type) {
        case IR_LITERAL: {
            return renderLiteral((IRLiteral*)expr, sql);
        }

        case IR_IDENTIFIER: {
            IRIdentifier* identifier = (IRIdentifier*)expr;
            sql.appendf("%s", identifier.name);
            return true;
        }

        case IR_BINARY: {
            IRBinary* binary = (IRBinary*)expr;
            sql.appendf("(");
            if (!renderExpression(binary.left, sql)) return false;
            sql.appendf(" %s ", sqlOperator(binary.op));
            if (!renderExpression(binary.right, sql)) return false;
            sql.appendf(")");
            return true;
        }

        default: {
            error::createError("unsupported expression in mysql backend", (PositionVector){});
            return false;
        }
    }
}

fn String sqlOperator(String op) {
    if (op == "~=") return "<>";
    return op;
}

fn bool renderLiteral(IRLiteral* literal, DString* sql) {
    if (literal.kind == IRPrimitive.DOUBLE) {
        if (literal.number == (double)(long)literal.number) {
            sql.appendf("%d", (int)literal.number);
        } else {
            sql.appendf("%f", literal.number);
        }
        return true;
    }

    if (literal.kind == IRPrimitive.STRING) {
        String quoted = escape(literal.string);
        defer quoted.free(mem);
        sql.appendf("'%s'", quoted);
        return true;
    }

    return false;
}

fn String escape(String value) {
    DString result;
    result.init(mem);
    for (usz i = 0; i < value.len; i++) {
        char ch = value[i];
        if (ch == '\'') {
            result.appendf("''");
        } else {
            result.appendf("%c", ch);
        }
    }
    return result.copy_str(mem);
}