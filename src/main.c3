module lublinsql;

import lublinsql::codegen;
import lublinsql::codegen::mysql;
import lublinsql::error;
import lublinsql::ir;
import lublinsql::lexer;
import lublinsql::parser;
import lublinsql::typer;
import std::io;

fn void printErrors() {
    foreach (err : error::errors) {
        io::printfn("ERROR (%d:%d): %s", (int)err.position.start.line, (int)err.position.start.column, err.value);
    }
}

fn int usage() {
    io::printn("Usage: lublinrc [options] <input_file>");
    io::printn("Options:");
    io::printn("  -b, --backend <name>  SQL backend to generate (default: mysql)");
    return 1;
}

fn int main(String[] args) {
    String backend_name = "mysql";
    String input_path;
    bool has_input = false;

    for (usz i = 1; i < args.len; i++) {
        String arg = args[i];
        if (arg == "--backend" || arg == "-b") {
            if (i + 1 >= args.len) {
                io::printn("Missing value for --backend");
                return usage();
            }
            backend_name = args[i + 1];
            i++;
        } else if (has_input) {
            io::printfn("Unexpected argument: %s", arg);
            return usage();
        } else {
            input_path = arg;
            has_input = true;
        }
    }

    if (!has_input) return usage();

    String? input = (String)file::load(mem, input_path);
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
    printErrors();
    if (!check_ok || error::errors.size > 0) return 1;

    IRProgram ir_program;
    bool ir_ok = ir::lowerProgram((ProgramNode*)ast, &main_scope, &ir_program);
    printErrors();
    if (!ir_ok || error::errors.size > 0) return 1;

    SQLWriter writer;
    writer.init();

    bool sql_ok = false;
    if (backend_name == "mysql") {
        sql_ok = mysql::generate(&ir_program, &writer);
    } else {
        io::printfn("Unknown backend '%s' (available: mysql)", backend_name);
        return 1;
    }
    printErrors();
    if (!sql_ok || error::errors.size > 0) return 1;

    String sql = writer.finish();
    defer sql.free(mem);

    io::print(sql);

    return 0;
}