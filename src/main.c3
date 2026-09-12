module lublinsql;

import lublinsql::error;
import lublinsql::lexer;
import lublinsql::parser;
import lublinsql::typer;
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

    error::initErrors();

    lexer::Tokens tokens = lexer::lex(input);
    defer tokens.free();

    Parser parser_state = parser::makeParser(tokens);
    Resulter result = parser_state.parse();
    if (result.isError()) return 1;
    Node ast = result.value;

    Scope main_scope = typer::@buildMainScope();
    bool check_ok = typer::typeCheck(ast, &main_scope);

    foreach (err : error::errors) {
        io::printfn("ERROR (%d:%d): %s", (int)err.position.start.line, (int)err.position.start.column, err.value);
    }

    if (error::errors.size > 0) return 1;

    parser::reprNodes(ast);
    io::print("\n");

    return 0;
}