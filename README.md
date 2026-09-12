# LublinSQL

> A statically typed data programming language compiled to SQL.

LublinSQL is a new programming language for working with data.

Instead of treating SQL as the language programmers write directly, LublinSQL treats SQL as a compilation target. The language provides its own type system, data model, abstractions, and semantics, which are then compiled into a specific SQL dialect.

## Dialect Support

LublinSQL is designed to be dialect-agnostic, allowing developers to write code that can be compiled into different SQL dialects. 
However, as of now, the language is still in its early stages of development, and support for various SQL dialects is not yet implemented.


Table of supported SQL dialects:

| Dialect | Status | Notes |
|---------|--------|-------|
| MySQL | ✅ | Basic support: `CREATE TABLE` (String/Int/Double/Bool), `SELECT` via `print()`, `sql { }` passthrough. `--backend mysql` |
| PostgreSQL | ❎ | Not yet implemented |
| SQLite | ❎ | Not yet implemented |
| Oracle | ❎ | Not yet implemented |
| MSSQL | ❎ | Not yet implemented |

The backend is selected with the `--backend <name>` (or `-b <name>`) flag, e.g. `lublinrc --backend mysql input.lublin`. Defaults to `mysql`.

## Core idea

LublinSQL is not intended to be "SQL with different keywords."

The goal is to provide a higher-level programming model for relational data while retaining the power and interoperability of SQL.

## Contributing

Contributions to LublinSQL are welcome! 
If you would like to contribute, please fork the repository and submit a pull request or open an issue to discuss your ideas.