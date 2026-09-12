module lublinsql::ir;

import std::collections::list;
import lublinsql::error;
import lublinsql::parser;
import lublinsql::position;
import lublinsql::typer;

fn bool lowerProgram(ProgramNode* program, Scope* scope, IRProgram* out) {
    if (!program) return false;

    out.type = IRNodeType.IR_PROGRAM;
    out.types.init(mem);
    out.tables.init(mem);
    out.statements.init(mem);

    bool ok = true;

    foreach (Node statement : program.statements) {
        NodeHeader* header = (NodeHeader*)statement;
        if (header.type != NodeType.TYPE_NODE) continue;
        if (!createTypeDecl((TypeNode*)statement, out)) ok = false;
    }

    foreach (Node statement : program.statements) {
        NodeHeader* header = (NodeHeader*)statement;
        if (header.type == NodeType.TYPE_NODE) {
            if (!fillTypeFields((TypeNode*)statement, scope, out)) ok = false;
            continue;
        }
        if (header.type == NodeType.TABLE_NODE) {
            if (!lowerTable((TableNode*)statement, scope, out)) ok = false;
            continue;
        }
        if (header.type == NodeType.SQL_NODE) {
            if (!lowerSql((SQLNode*)statement, out)) ok = false;
            continue;
        }
        if (!lowerExprStmt(statement, scope, out)) ok = false;
    }

    return ok;
}

fn bool createTypeDecl(TypeNode* type_node, IRProgram* out) {
    IRTypeDecl* decl = mem::malloc(IRTypeDecl::size);
    decl.type = IRNodeType.IR_TYPE_DECL;
    decl.name = ((IdentifierNode*)type_node.name).value;
    decl.fields.init(mem);

    out.types.push((IRNode)decl);
    return true;
}

fn bool fillTypeFields(TypeNode* type_node, Scope* scope, IRProgram* out) {
    IdentifierNode* type_name = (IdentifierNode*)type_node.name;
    IRTypeDecl* decl = findTypeDecl(out, type_name.value);
    if (!decl) return false;

    foreach (Node element_node : type_node.elements) {
        TypeElementNode* element = (TypeElementNode*)element_node;

        IRField* field = mem::malloc(IRField::size);
        field.type = IRNodeType.IR_FIELD;
        field.name = ((IdentifierNode*)element.name).value;
        field.base_type = resolveTypeNode((IdentifierNode*)element.element_type, scope, out);

        decl.fields.push((IRNode)field);
    }

    return true;
}

fn bool lowerTable(TableNode* table_node, Scope* scope, IRProgram* out) {
    IdentifierNode* name = (IdentifierNode*)table_node.name;
    IdentifierNode* type_name = (IdentifierNode*)table_node.table_type;

    Type* resolved = scope.findType(type_name.value);
    if (!resolved) return false;

    IRType* element_type = makeRecordType(resolved.name, findTypeDecl(out, resolved.name));
    IRType* array_type = makeArrayType(string::format(mem, "%s[]", resolved.name), element_type);

    IRTableDecl* decl = mem::malloc(IRTableDecl::size);
    decl.type = IRNodeType.IR_TABLE_DECL;
    decl.name = name.value;
    decl.element_type = array_type;

    out.tables.push((IRNode)decl);
    return true;
}

fn bool lowerSql(SQLNode* sql_node, IRProgram* out) {
    IRSqlStmt* stmt = mem::malloc(IRSqlStmt::size);
    stmt.type = IRNodeType.IR_SQL_STMT;
    stmt.sql = sql_node.sql;

    out.statements.push((IRNode)stmt);
    return true;
}

fn bool lowerExprStmt(Node node, Scope* scope, IRProgram* out) {
    IRExprStmt* stmt = mem::malloc(IRExprStmt::size);
    stmt.type = IRNodeType.IR_EXPR_STMT;
    stmt.expr = lowerExpression(node, scope, out);
    if (!stmt.expr) return false;

    out.statements.push((IRNode)stmt);
    return true;
}

fn IRExpr lowerExpression(Node node, Scope* scope, IRProgram* out) {
    Type* type = typer::checkExpression(node, scope);
    if (!type) return (IRExpr)null;
    IRType* ir_type = mapIRType(type, out);

    NodeHeader* header = (NodeHeader*)node;
    switch (header.type) {
        case NUMBER_NODE: {
            NumberNode* number_node = (NumberNode*)node;
            IRLiteral* literal = mem::malloc(IRLiteral::size);
            literal.type = IRNodeType.IR_LITERAL;
            literal.kind = IRPrimitive.DOUBLE;
            literal.number = number_node.value;
            return (IRExpr)literal;
        }

        case STRING_LITERAL_NODE: {
            StringLiteralNode* string_node = (StringLiteralNode*)node;
            IRLiteral* literal = mem::malloc(IRLiteral::size);
            literal.type = IRNodeType.IR_LITERAL;
            literal.kind = IRPrimitive.STRING;
            literal.string = string_node.value;
            return (IRExpr)literal;
        }

        case IDENTIFIER_NODE: {
            IdentifierNode* identifier = (IdentifierNode*)node;
            IRIdentifier* ir_identifier = mem::malloc(IRIdentifier::size);
            ir_identifier.type = IRNodeType.IR_IDENTIFIER;
            ir_identifier.name = identifier.value;
            ir_identifier.resolved = ir_type;
            return (IRExpr)ir_identifier;
        }

        case BINARY_NODE: {
            BinaryNode* binary = (BinaryNode*)node;
            IRBinary* ir_binary = mem::malloc(IRBinary::size);
            ir_binary.type = IRNodeType.IR_BINARY;
            ir_binary.op = binary.op;
            ir_binary.left = lowerExpression(binary.left, scope, out);
            ir_binary.right = lowerExpression(binary.right, scope, out);
            ir_binary.result = ir_type;
            if (!ir_binary.left || !ir_binary.right) return (IRExpr)null;
            return (IRExpr)ir_binary;
        }

        case FUNCTION_CALL_NODE: {
            FunctionCallNode* call = (FunctionCallNode*)node;
            IRCall* ir_call = mem::malloc(IRCall::size);
            ir_call.type = IRNodeType.IR_CALL;
            ir_call.callee = ((IdentifierNode*)call.callee).value;
            ir_call.args.init(mem);
            foreach (Node argument : call.args) {
                IRExpr arg = lowerExpression(argument, scope, out);
                if (!arg) return (IRExpr)null;
                ir_call.args.push(arg);
            }
            ir_call.result = ir_type;
            return (IRExpr)ir_call;
        }

        default: {
            error::createError("unsupported expression in lowering", (PositionVector){});
            return (IRExpr)null;
        }
    }
}

fn IRType* resolveTypeNode(IdentifierNode* type_name, Scope* scope, IRProgram* out) {
    Type* resolved = scope.findType(type_name.value);
    if (!resolved) return makePrimitiveType(type_name.value);
    return mapIRType(resolved, out);
}

fn IRType* mapIRType(Type* type, IRProgram* out) {
    switch (type.kind) {
        case TypeKind.BUILDIN: {
            return makePrimitiveType(type.name);
        }

        case TypeKind.ARRAY: {
            String element_name;
            if (type.name.len >= 2) {
                element_name = type.name[0 : type.name.len - 2];
            } else {
                element_name = type.name;
            }
            IRType* element_type = makeRecordType(element_name, findTypeDecl(out, element_name));
            return makeArrayType(type.name, element_type);
        }

        case TypeKind.RECORD: {
            return makeRecordType(type.name, findTypeDecl(out, type.name));
        }

        default: {
            return makePrimitiveType(type.name);
        }
    }
}

fn IRType* makePrimitiveType(String name) {
    IRType* type = mem::malloc(IRType::size);
    type.kind = IRTypeKind.PRIMITIVE;
    type.name = name;
    type.element = null;
    type.declaration = null;
    return type;
}

fn IRType* makeRecordType(String name, IRTypeDecl* declaration) {
    IRType* type = mem::malloc(IRType::size);
    type.kind = IRTypeKind.RECORD;
    type.name = name;
    type.element = null;
    type.declaration = declaration;
    return type;
}

fn IRType* makeArrayType(String name, IRType* element) {
    IRType* type = mem::malloc(IRType::size);
    type.kind = IRTypeKind.ARRAY;
    type.name = name;
    type.element = element;
    type.declaration = null;
    return type;
}

fn IRTypeDecl* findTypeDecl(IRProgram* out, String name) {
    foreach (IRNode node : out.types) {
        IRTypeDecl* decl = (IRTypeDecl*)node;
        if (decl.name == name) return decl;
    }
    return null;
}