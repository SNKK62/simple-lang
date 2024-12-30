# Simple Language in OCaml

This compiler is written in OCaml-yacc, OCaml-lex and OCaml based on [this book](https://www.rs.tus.ac.jp/mune/ccp/).

### Frontend

- lexer
  - lexer.mll
- parser
  - parser.mly
- ast
  - ast.ml

#### Features

- can prit error locations (with error recovery)

#### How to build

```sh
make print_ast
```

#### How to run

```sh
./print_ast <...>.spl
```
