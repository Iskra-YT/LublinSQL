module lublinsql::ir;

import std::io;

fn void reprProgram(IRProgram* program) {
    if (!program) return;

    io::print("{IR-PROGRAM: TYPES: ");
    foreach (IRNode node : program.types) {
        reprNode(node);
    }

    io::print(" TABLES: ");
    foreach (IRNode node : program.tables) {
        reprNode(node);
    }

    io::print(" STMTS: ");
    foreach (IRNode node : program.statements) {
        reprNode(node);
    }

    io::print("};");
}

fn void reprNode(IRNode node) {
    if (!node) return;
    IRHeader* header = (IRHeader*)node;

    switch (header.type) {
        case IR_TYPE_DECL: {
            IRTypeDecl* decl = (IRTypeDecl*)node;
            io::printf(" (IRTypeDecl: %s {", decl.name);
            foreach (IRNode field_node : decl.fields) {
                IRField* field = (IRField*)field_node;
                io::print(" ");
                io::printf("%s: ", field.name);
                reprType(field.base_type);
            }
            io::print(" })");
        }

        case IR_TABLE_DECL: {
            IRTableDecl* decl = (IRTableDecl*)node;
            io::print(" (IRTableDecl: ");
            io::printf("%s : ", decl.name);
            reprType(decl.element_type);
            io::print(" )");
        }

        case IR_SQL_STMT: {
            IRSqlStmt* stmt = (IRSqlStmt*)node;
            io::printf(" (IRSqlStmt: %s) ", stmt.sql);
        }

        case IR_EXPR_STMT: {
            IRExprStmt* stmt = (IRExprStmt*)node;
            io::print(" (IRExprStmt: ");
            reprNode((IRNode)stmt.expr);
            io::print(" )");
        }

        case IR_LITERAL: {
            IRLiteral* literal = (IRLiteral*)node;
            if (literal.kind == IRPrimitive.DOUBLE) {
                io::printf(" (IRLiteral: %f) ", literal.number);
            } else {
                io::printf(" (IRLiteral: '%s') ", literal.string);
            }
        }

        case IR_IDENTIFIER: {
            IRIdentifier* identifier = (IRIdentifier*)node;
            io::print(" (IRIdentifier: ");
            io::printf("%s : ", identifier.name);
            reprType(identifier.resolved);
            io::print(" )");
        }

        case IR_BINARY: {
            IRBinary* binary = (IRBinary*)node;
            io::print(" (IRBinary: ");
            reprNode((IRNode)binary.left);
            io::printf(" %s ", binary.op);
            reprNode((IRNode)binary.right);
            io::print(" : ");
            reprType(binary.result);
            io::print(" )");
        }

        case IR_CALL: {
            IRCall* call = (IRCall*)node;
            io::printf(" (IRCall: %s(", call.callee);
            foreach (IRExpr argument : call.args) {
                reprNode((IRNode)argument);
            }
            io::print(") : ");
            reprType(call.result);
            io::print(" )");
        }

        default: {
            io::print(" (UnknownIRNode)");
        }
    }
}

fn void reprType(IRType* type) {
    if (!type) {
        io::print("<no type>");
        return;
    }
    io::printf("%s", type.name);
}