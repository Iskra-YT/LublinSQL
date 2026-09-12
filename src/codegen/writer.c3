module lublinsql::codegen;

struct SQLWriter {
    DString buffer;
}

fn void SQLWriter.init(SQLWriter* this) {
    this.buffer.init(mem);
}

fn void SQLWriter.write(SQLWriter* this, String text) {
    this.buffer.appendf("%s", text);
}

fn void SQLWriter.writeln(SQLWriter* this) {
    this.buffer.appendf("\n");
}

fn String SQLWriter.finish(SQLWriter* this) {
    return this.buffer.copy_str(mem);
}