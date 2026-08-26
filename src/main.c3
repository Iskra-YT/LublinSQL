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

    Parser p = parser::make_parser(tokens);
    Node ast = p.parse();
    if (!ast) return 1;

    parser::repr_nodes(ast);
    io::print("\n");

    return 0;
}
