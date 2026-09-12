module lublinsql::typer;

import std::collections::map;

struct Scope {
    Scope* parent;
    HashMap{String, Type} symbols;
    HashMap{String, Function} functions;
}

fn void Scope.init(Scope* this, Allocator allocator = mem) {
    this.symbols.init(allocator);
    this.functions.init(allocator);
}

fn bool Scope.hasParent(Scope* this) {
    return !this.parent;
}

enum TypeKind {
    RECORD,
    BUILDIN,
    ARRAY,
}

struct Function {
    String name;
    String[] params;
    String return_type;
    bool variadic;
}

struct Type {
    TypeKind kind;
    String name;
    Scope scope;
}

fn void Type.init(Type* this, String name, Allocator allocator = mem) {
    this.scope.init(allocator);
    this.name = name;
}

macro @buildMainScope() {
    Scope temp;
    temp.init(mem);
    temp.parent = null;
    return temp;
}