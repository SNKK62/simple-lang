# Simple Language in OCaml

This compiler is written in OCaml-yacc, OCaml-lex and OCaml based on [this book](https://www.rs.tus.ac.jp/mune/ccp/).

### Frontend

- lexer
  - lexer.mll
- parser
  - parser.mly
- ast
  - ast.ml
- Semantic Analyzer
  - semant.ml
  - table.ml
  - types.ml
- code generator
  - emitter.ml
- main
  - sim.ml

#### Features

- can prit error locations (with error recovery)

#### Developing

```sh
dune build -w
```

#### Formatting
```sh
# for the first time
echo "version = `ocamlformat --version`" > .ocamlformat

# format
opam exec -- dune fmt
```

#### How to build

Run the following commands in `./bin`

```sh
make print_ast
make simc
```

#### How to run

Run the following commands in `./bin`

```sh
./print_ast <...>.spl
./simc <...>.spl

./a.out
```
