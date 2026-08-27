# Contributing to LublinSQL

This file documents the coding conventions for the LublinSQL codebase. GitHub
displays it automatically and it applies to **all** new and modified code —
inconsistent code is a bug.

> [!WARNING]
> **This project does NOT follow the C3 language's default/recommended style.**

We use C3 as an *implementation vehicle* only. It is not a model for how
LublinSQL source code should look. Do not "fix" or "correct" code in this
repository so that it matches the C3 standard guide — doing so is a **regression**
and will be rejected in review.

---

## Deviation from the C3 default style

The official C3 conventions recommend `snake_case` for **all** identifiers:
functions, methods, types, variables, parameters and file names alike.

This project intentionally diverges from that part of the C3 standard in two
places:

| Identifier | LublinSQL **this project** | C3 default | Use C3 default? |
|------------|----------------------------|------------|-----------------|
| Functions / methods | `camelCase` | `snake_case` | **Never** |
| Types (structs, enums, aliases) | `PascalCase` | `snake_case` | **Never** |
| Variables / parameters / locals | `snake_case` | `snake_case` | Yes |
| Struct fields | `snake_case` | `snake_case` | Yes |
| Constants / enum members | `UPPER_SNAKE_CASE` | `UPPER_SNAKE_CASE` | Yes |
| Modules | `snake_case` | `snake_case` | Yes |
| Files | `snake_case` | `snake_case` | Yes |

This is a conscious decision:

- `camelCase` function names read naturally after the accessor prefix used in
  this codebase (`getCurrent`, `parseExpression`, `makeToken`) and keep
  functions visually distinct from variables.
- `PascalCase` types match the surrounding ecosystem style and keep type names
  visually distinct from values.

Keep the "C3 default" column empty at all times — it exists only to document
what we are **not** following.

---

## Modules & file layout

- Module names are `snake_case` and namespaced under a project prefix:
  `lublinsql::lexer`, `lublinsql::parser`, `lublinsql::position`,
  `lublinsql::tests`.
- The directory layout under `src/` mirrors the module namespace:

  | Module | File |
  |--------|------|
  | `lublinsql::lexer` | `src/lexer/lexer.c3` |
  | `lublinsql::parser` | `src/parser/parser.c3` |
  | `lublinsql::position` | `src/position.c3` |

  One module per "concern directory"; a single module should not be split
  across unrelated paths, and unrelated modules should not be squashed into a
  single file.
- **Test files** live under `tests/` and follow the pattern
  `<module>_tests.c3` — e.g. `tests/lexer_tests.c3` tests the
  `lublinsql::lexer` module. They must never be placed under `src/`.
- Imports are grouped logically and placed at the top of the module, after
  the `module` declaration. Third-party / std imports come before local
  imports in their own paragraph:

  ```c
  module lublinsql::lexer;

  import std::collections::list;
  import lublinsql::position;
  ```

- Only `c3` files. No generated files, no build artifacts inside `src/`.

---

## Naming

| Thing | Convention | Example |
|-------|-----------|---------|
| Functions (free and methods) | `camelCase` | `makeToken`, `Parser.getCurrent`, `parseExpression` |
| Variables / parameters / locals | `snake_case` | `token_value`, `start_line` |
| Struct fields | `snake_case` | `line`, `column`, `token_list` |
| Structs / types / enums / aliases | `PascalCase` | `PositionVector`, `TokenType`, `Tokens` |
| Constants | `UPPER_SNAKE_CASE` | `KEYWORDS` |
| Enum members | `UPPER_SNAKE_CASE` | `TokenType.NUMBER`, `NodeType.SQL_NODE` |
| Modules | `snake_case` | `lublinsql::lexer` |
| File names | `snake_case` | `lexer.c3`, `tokens.c3`, `lexer_tests.c3` |

### Rules

- `camelCase` for **every function** — struct methods (`Parser.getCurrent`,
  `Token.matches`) and free functions (`makeToken`, `lexNumber`,
  `parseBinary`) alike. Using `snake_case` for a function name is an error.
- The receiver parameter of every method is always named `this`.
- Variables, parameters and locals use `snake_case`. Using `camelCase` for a
  variable is an error, unless the name comes from code outside this project.
- Struct fields use `snake_case`. Constant-width values such as `sz`,
  `double` or `String` carry no type prefix — the name must be descriptive on
  its own (`index`, `column`, not `i_col` or `sz_index`).
- Single-letter names are only allowed for obvious throwaway loop indices
  (`for (int i = 0; ...)`, `for (int k = 0; ...)`) and pointer arithmetic
  cursors. Everything else gets a descriptive name.
- Avoid reserved / ambiguous words. Do not shadow the field name of a struct
  inside its own method via a parameter.

---

## Constants & enums

- Constant declarations use `UPPER_SNAKE_CASE`:

  ```c
  const String[] KEYWORDS = { "sql" };
  ```

- Enum members are `UPPER_SNAKE_CASE` and use a noun suffix where the domain
  requires disambiguation (`TokenType.NUMBER_NODE` only where needed; prefer
  `TokenType.NUMBER` when unambiguous):

  ```c
  enum TokenType : int {
      UNKNOWN,
      IDENTIFIER,
      KEYWORD,
      OPERATOR,
      DELIMITER,
      NUMBER,
      STRING
  }
  ```

---

## Structs & types

- Types are `PascalCase`: `Position`, `PositionVector`, `Token`, `Parser`,
  `ProgramNode`, `NumberNode`.
- Every struct that participates in a tagged dispatch carries the dispatch
  tag as its **first** field, named `type` (`NodeType type;`).
- Representation methods are named `repr` and return a `String`. Accessors
  for possibly-missing values return a pointer `Token*`, never a copied
  struct.
- Collection aliases use `PascalCase` too, matching the types they alias:

  ```c
  alias Tokens = List{Token};
  ```

---

## Layout & formatting

- Indentation: **4 spaces**. No tabs. No trailing whitespace. One trailing
  newline at end of file.
- Opening brace `{` goes on the **same line** as the function signature or
  control-flow keyword.
- A single trailing statement after a control keyword may be placed on the
  same line without braces:

  ```c
  if (value == KEYWORDS[i]) return makeToken(value, TokenType.KEYWORD, start, end);
  if (this.getCurrent() != null) this.next();
  ```

- Multi-statement bodies **always** use braces.
- Empty blocks are written `{}` only if required by the language; prefer an
  explicit early `return` / `continue` over an empty body.
- Break long conditions onto multiple lines with one level of indentation;
  keep the closing parenthesis and opening brace on the final line.
- Struct initializers use designated `.field = value` syntax and wrap entries
  one per line:

  ```c
  Position pos = {
      .index = -1,
      .column = 0,
      .line = 1
  };
  ```

---

## Control flow & errors

- Fail fast: validate inputs at the top of a function and return early.
- Prefer the null-coalescing form over explicit branching when the fallback
  is a plain value and the intent stays obvious:

  ```c
  node.value = token.value.to_double() ?? 0;
  ```

- Fallible calls are always handled; errors are never swallowed silently.
- Pointers and nullable values are checked against `null` before use.

---

## Comments

- Comments explain **why**, never restate the code. Code that needs a "what"
  comment should be rewritten instead.
- Single-line comments use `//`. Block comments are reserved for license
  headers.
- Do **not** leave TODO/FIXME markers in committed code — open an issue
  instead. Inline Polish comments are not allowed in committed files.
- Test code gets the same discipline as production code: no commented-out
  assertions, no dead blocks.

---

## Tests

- Tests live in `tests/` and mirror their module: `tests/lexer_tests.c3`.
- Every test function follows the `test_<scenario>` naming convention used by
  the test runner:

  ```c
  fn void test_numbers() @test { ... }
  fn void test_identifiers_and_keywords() @test { ... }
  ```

  This is the one place free functions are allowed to be `snake_case`.
  Production code never gets this exception.
- Helpers shared by several tests follow `camelCase` like any other function.
- Test functions must be self-contained: create input, run, assert via
  `test::eq` / `assert_token`.

---

## Example

```c
fn Token lexNumber(String input, int* pos, Position start) {
    int begin = *pos;
    int len = (int)input.len;

    while (*pos < len && (is_digit(input[*pos]) || input[*pos] == '_')) {
        (*pos)++;
    }

    Position end = skip(start, input, begin, *pos);
    return makeToken(input[begin : *pos - begin], TokenType.NUMBER, start, end);
}
```

---

## Quick checklist

- Functions & methods `camelCase`, types `PascalCase`, variables/fields
  `snake_case`, constants & enum members `UPPER_SNAKE_CASE`, files
  `snake_case`.
- **Nothing** was renamed to match the C3 default style.
- 4-space indentation, no tabs, braces on the same line.
- Files under `src/` mirror module namespaces; tests under `tests/`.