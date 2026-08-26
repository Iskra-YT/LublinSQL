module lublinsql;

import lublinsql::lexer;
import lublinsql::parser;
import std::io;

fn int main(String[] args) {
    if (args.len < 2) {
        io::printn("Usage: lublinrc <input_file>");
        return 1;
    }

    String? input = (String)file::load(mem, args[1]);
    if (catch err = input) {
        io::printfn("Error loading file: %s", err);
        return 1;
    }

    defer input.free(mem);

    lexer::Tokens tokens = lexer::lex(input);
    defer tokens.free();

    Node* ast = parser::parse(tokens);
    if (!ast) {
        io::printn("Error: failed to parse expression");
        return 1;
    }

    io::printn(ast.repr());

    return 0;
}
