(* File lexer.mll *)
{
  open Parser
  exception Lexing_error of string * int * int
}

let newline = '\n'
let digit = ['0'-'9']
let id = ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9']*

rule lexer = parse
  | newline                 { Lexing.new_line lexbuf; lexer lexbuf }
  | digit+ as num           { NUM (int_of_string num) }
  | "if"                    { IF }
  | "else"                  { ELSE }
  | "while"                 { WHILE }
  | "scan"                  { SCAN }
  | "sprint"                { SPRINT }
  | "iprint"                { IPRINT }
  | "int"                   { INT }
  | "return"                { RETURN }
  | "type"                  { TYPE }
  | "void"                  { VOID }
  | id as text              { ID text }
  | '\"'[^'\"']*'\"' as str { STR str }
  | '='                     { ASSIGN }
  | "+="                    { PASSIGN }
  | "=="                    { EQ }
  | "!="                    { NEQ }
  | '>'                     { GT }
  | '<'                     { LT }
  | ">="                    { GE }
  | "<="                    { LE }
  | '+'                     { PLUS }
  | "++"                    { INC }
  | '-'                     { MINUS }
  | '*'                     { TIMES }
  | '/'                     { DIV }
  | '%'                     { MOD }
  | '^'                     { POW }
  | '{'                     { LB }
  | '}'                     { RB }
  | '['                     { LS }
  | ']'                     { RS }
  | '('                     { LP }
  | ')'                     { RP }
  | ','                     { COMMA }
  | ';'                     { SEMI }
  | [' ' '\t']              { lexer lexbuf } (* eat up whitespace *)
  | "//" [^'\n']* '\n'      { Lexing.new_line lexbuf; lexer lexbuf } (* eat up line comment *)
  | eof                     { raise End_of_file }
  | _ as c                  {
      let line = lexbuf.lex_start_p.Lexing.pos_lnum in
      let col = lexbuf.lex_start_p.Lexing.pos_cnum - lexbuf.lex_start_p.Lexing.pos_bol in
      raise (Lexing_error (Printf.sprintf "Unexpected character: \"%c\"" c, line, col))
  }
