module lublinsql::typer;

import std::collections::list;
import lublinsql::error;
import lublinsql::parser;
import lublinsql::position;

const String[] BUILTIN_TYPES = {
    "String",
    "Int",
    "Double",
    "Bool",
    "None",
    "Any"
};

const String[] NUMERIC_TYPES = {
    "Int",
    "Double"
};

const Function[] BUILTIN_FUNCTIONS = {
    {
        .name = "print",
        .params = { "Any" },
        .return_type = "None",
        .variadic = true
    }
};

fn void registerBuiltins(Scope* scope) {
    foreach (String name : BUILTIN_TYPES) {
        Type type = makeType(name, TypeKind.BUILDIN);
        scope.symbols.set(name, type);
    }

    foreach (Function builtin : BUILTIN_FUNCTIONS) {
        scope.functions.set(builtin.name, builtin);
    }
}

fn Type makeType(String name, TypeKind kind) {
    Type type;
    type.init(name);
    type.kind = kind;
    return type;
}

fn Type* Scope.findType(Scope* this, String name) {
    Type*? ref = this.symbols.get_ref(name);
    if (try Type* found = ref) return found;

    if (this.parent) return this.parent.findType(name);
    return null;
}

fn Function* Scope.findFunction(Scope* this, String name) {
    Function*? ref = this.functions.get_ref(name);
    if (try Function* found = ref) return found;

    if (this.parent) return this.parent.findFunction(name);
    return null;
}

fn bool typeCheck(Node ast, Scope* scope) {
    if (!ast) return false;
    NodeHeader* header = (NodeHeader*)ast;
    if (header.type != NodeType.PROGRAM_NODE) return false;

    registerBuiltins(scope);

    ProgramNode* program = (ProgramNode*)ast;

    bool ok = true;

    registerTypes(program, scope);
    if (!checkTypes(program, scope)) ok = false;
    if (!checkTables(program, scope)) ok = false;
    if (!checkStatements(program, scope)) ok = false;

    return ok;
}

fn void registerTypes(ProgramNode* program, Scope* scope) {
    foreach (Node statement : program.statements) {
        NodeHeader* header = (NodeHeader*)statement;
        if (header.type != NodeType.TYPE_NODE) continue;

        TypeNode* type_node = (TypeNode*)statement;
        IdentifierNode* name = (IdentifierNode*)type_node.name;

        if (scope.findType(name.value)) {
            error::createError(string::format(mem, "duplicate definition of type '%s'", name.value), (PositionVector){});
            continue;
        }

        Type type = makeType(name.value, TypeKind.RECORD);
        scope.symbols.set(name.value, type);
    }
}

fn bool checkTypes(ProgramNode* program, Scope* scope) {
    bool ok = true;

    foreach (Node statement : program.statements) {
        NodeHeader* header = (NodeHeader*)statement;
        if (header.type != NodeType.TYPE_NODE) continue;

        TypeNode* type_node = (TypeNode*)statement;
        if (!checkType(type_node, scope)) ok = false;
    }

    return ok;
}

fn bool checkType(TypeNode* type_node, Scope* scope) {
    IdentifierNode* name = (IdentifierNode*)type_node.name;
    Type* self = scope.findType(name.value);
    if (!self) return false;

    List{String} seen;
    seen.init(mem);

    bool ok = true;
    foreach (Node element_node : type_node.elements) {
        TypeElementNode* element = (TypeElementNode*)element_node;
        if (!checkTypeElement(element, scope, &seen, &self.scope)) ok = false;
    }

    return ok;
}

fn bool checkTypeElement(TypeElementNode* element, Scope* scope, List{String}* seen, Scope* self_scope) {
    bool ok = true;
    IdentifierNode* element_name = (IdentifierNode*)element.name;

    foreach (String used : *seen) {
        if (used == element_name.value) {
            error::createError(string::format(mem, "duplicate element '%s' in type", element_name.value), (PositionVector){});
            ok = false;
        }
    }
    seen.push(element_name.value);

    IdentifierNode* type_name = (IdentifierNode*)element.element_type;
    Type* element_type = scope.findType(type_name.value);
    if (!element_type) {
        error::createError(string::format(mem, "unknown type '%s'", type_name.value), (PositionVector){});
        return false;
    }

    if (element_type.name == "None" || element_type.name == "Any") {
        error::createError(string::format(mem, "element '%s' cannot have type '%s'", element_name.value, element_type.name), (PositionVector){});
        ok = false;
    }

    self_scope.symbols.set(element_name.value, *element_type);

    return ok;
}

fn bool checkTables(ProgramNode* program, Scope* scope) {
    bool ok = true;

    foreach (Node statement : program.statements) {
        NodeHeader* header = (NodeHeader*)statement;
        if (header.type != NodeType.TABLE_NODE) continue;

        TableNode* table_node = (TableNode*)statement;
        if (!checkTable(table_node, scope)) ok = false;
    }

    return ok;
}

fn bool checkTable(TableNode* table_node, Scope* scope) {
    IdentifierNode* name = (IdentifierNode*)table_node.name;
    IdentifierNode* type_name = (IdentifierNode*)table_node.table_type;

    Type* table_type = scope.findType(type_name.value);
    if (!table_type) {
        error::createError(string::format(mem, "unknown type '%s' for table '%s'", type_name.value, name.value), (PositionVector){});
        return false;
    }

    bool ok = true;

    if (table_type.kind == TypeKind.BUILDIN) {
        error::createError(string::format(mem, "table '%s' must use a record type, got '%s'", name.value, table_type.name), (PositionVector){});
        ok = false;
    }

    if (scope.findType(name.value)) {
        error::createError(string::format(mem, "duplicate definition of table '%s'", name.value), (PositionVector){});
        ok = false;
    }

    scope.symbols.set(name.value, *table_type);

    return ok;
}

fn bool checkStatements(ProgramNode* program, Scope* scope) {
    bool ok = true;

    foreach (Node statement : program.statements) {
        NodeHeader* header = (NodeHeader*)statement;
        if (header.type == NodeType.TYPE_NODE) continue;
        if (header.type == NodeType.TABLE_NODE) continue;
        if (header.type == NodeType.SQL_NODE) continue;

        if (!checkExpression(statement, scope)) ok = false;
    }

    return ok;
}

fn Type* checkExpression(Node node, Scope* scope) {
    NodeHeader* header = (NodeHeader*)node;

    switch (header.type) {
        case NUMBER_NODE: {
            return scope.findType("Double");
        }

        case STRING_LITERAL_NODE: {
            return scope.findType("String");
        }

        case IDENTIFIER_NODE: {
            IdentifierNode* identifier = (IdentifierNode*)node;
            Type* resolved = scope.findType(identifier.value);
            if (!resolved) {
                error::createError(string::format(mem, "undefined identifier '%s'", identifier.value), (PositionVector){});
            }
            return resolved;
        }

        case BINARY_NODE: {
            BinaryNode* binary = (BinaryNode*)node;
            Type* left = checkExpression(binary.left, scope);
            if (!left) return null;
            Type* right = checkExpression(binary.right, scope);
            if (!right) return null;

            if (binary.op == "~=") {
                return scope.findType("Bool");
            }

            if (!isNumeric(left) || !isNumeric(right)) {
                error::createError(string::format(mem, "operator '%s' requires numeric operands, got '%s' and '%s'", binary.op, left.name, right.name), (PositionVector){});
                return null;
            }

            if (left.name == "Double" || right.name == "Double") {
                return scope.findType("Double");
            }
            return scope.findType("Int");
        }

        case FUNCTION_CALL_NODE: {
            FunctionCallNode* call = (FunctionCallNode*)node;
            NodeHeader* callee_header = (NodeHeader*)call.callee;
            if (callee_header.type != NodeType.IDENTIFIER_NODE) {
                error::createError("invalid function call", (PositionVector){});
                return null;
            }

            IdentifierNode* callee = (IdentifierNode*)call.callee;
            Function* builtin = scope.findFunction(callee.value);
            if (!builtin) {
                error::createError(string::format(mem, "undefined function '%s'", callee.value), (PositionVector){});
                return null;
            }

            if (!checkArguments(call, builtin, scope)) return null;

            return scope.findType(builtin.return_type);
        }

        default: {
            error::createError("unsupported expression", (PositionVector){});
            return null;
        }
    }
}

fn bool checkArguments(FunctionCallNode* call, Function* function, Scope* scope) {
    int arg_count = (int)call.args.size;
    int param_count = (int)function.params.len;

    if (function.variadic) {
        if (arg_count < param_count - 1) {
            error::createError(string::format(mem, "function '%s' expects at least %d argument(s), got %d", function.name, param_count - 1, arg_count), (PositionVector){});
            return false;
        }
    } else if (arg_count != param_count) {
        error::createError(string::format(mem, "function '%s' expects %d argument(s), got %d", function.name, param_count, arg_count), (PositionVector){});
        return false;
    }

    for (int i = 0; i < arg_count; i++) {
        Type* arg_type = checkExpression(call.args[i], scope);
        if (!arg_type) return false;

        int index = i < param_count ? i : param_count - 1;
        String param_type_name = function.params[index];
        Type* param_type = scope.findType(param_type_name);
        if (!isAssignable(arg_type, param_type)) {
            error::createError(string::format(mem, "argument %d of function '%s' expects '%s', got '%s'", i + 1, function.name, param_type_name, arg_type.name), (PositionVector){});
            return false;
        }
    }

    return true;
}

fn bool isNumeric(Type* type) {
    foreach (String numeric : NUMERIC_TYPES) {
        if (type.name == numeric) return true;
    }
    return false;
}

fn bool isAssignable(Type* source, Type* target) {
    if (target.name == "Any") return true;
    if (source.name == target.name) return true;
    if (source.name == "Int" && target.name == "Double") return true;
    return false;
}