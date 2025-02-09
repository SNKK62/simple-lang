%{
  open Printf
  open Ast
  open Lexing
%}

/* File parser.mly */
%token <int> NUM
%token <string> STR ID
%token INT IF WHILE DO FOR FORRANGE SPRINT IPRINT SCAN EQ NEQ GT LT GE LE ELSE RETURN NEW BREAK CONTINUE
%token PLUS MINUS TIMES DIV MOD POW INC LB RB LS RS LP RP ASSIGN PASSIGN SEMI COMMA TYPE VOID
%type <Ast.stmt> prog


%nonassoc GT LT EQ NEQ GE LE
%left PLUS MINUS              /* lowest precedence */
%left TIMES DIV MOD           /* medium precedence */
%nonassoc UMINUS              /* highest precedence */
%right POW

%start prog              /* the entry point */

%%

prog : stmt  {  $1  }
     ;

syntax_error : error {
        let start_pos = Parsing.symbol_start_pos () in
        let end_pos = Parsing.symbol_end_pos () in

        let start_line = start_pos.Lexing.pos_lnum in
        let start_col = start_pos.Lexing.pos_cnum - start_pos.Lexing.pos_bol in
 
        let end_line = end_pos.Lexing.pos_lnum in
        let end_col = end_pos.Lexing.pos_cnum - end_pos.Lexing.pos_bol in

        SyntaxError (start_line, start_col, end_line, end_col)
     }
     ;

ty   : INT              { IntTyp }
     | INT LS NUM RS    { ArrayTyp ($3, IntTyp) }
     | ID               { NameTyp $1 }
     ;

decs : decs dec { $1@$2 }
     |          { [] }
     ;

dec  : ty ids SEMI                        { List.map (fun x -> VarDec ($1,x, None)) $2 }
     | ty ID ASSIGN expr SEMI             { [VarDec ($1, $2, Some($4))] }
     | TYPE ID ASSIGN ty SEMI             { [TypeDec ($2,$4)] }
     | ty ID LP fargs_opt RP block        { [FuncDec($2, $4, $1, $6)] }
     | VOID ID LP fargs_opt RP block      { [FuncDec($2, $4, VoidTyp, $6)] }
     | syntax_error SEMI                  { [DecSyntaxError($1)] }
     ;

ids  : ids COMMA ID    { $1@[$3] }
     | ID              { [$1]  }
     ;

fargs_opt : /* empty */ { [] }
     | fargs            { $1 }
     ;

fargs: fargs COMMA ty ID     { $1@[($3,$4)] }
     | ty ID                 { [($1,$2)] }
     ;

stmts: stmts stmt  { $1@[$2] }
     | stmt        { [$1] }
     ;

stmt : ID ASSIGN expr SEMI                      { Assign (Var $1, $3) }
     | ID LS expr RS ASSIGN expr SEMI           { Assign (IndexedVar (Var $1, $3), $6) }
     | ID PASSIGN expr SEMI                     { Assign (Var $1, CallFunc ("+", [VarExp (Var $1); $3])) }
     | ID LS expr RS PASSIGN expr SEMI          { Assign (IndexedVar (Var $1, $3), CallFunc ("+", [VarExp (IndexedVar (Var $1, $3)); $6])) }
     | IF LP cond RP stmt                       { If ($3, $5, None) }
     | IF LP cond RP stmt ELSE stmt             { If ($3, $5, Some $7) }
     | WHILE LP cond RP stmt                    { While ($3, $5) }
     | DO stmt WHILE LP cond RP SEMI            { Block ([], [$2; While ($5, $2)]) }
     | FOR LP ID ASSIGN expr FORRANGE expr RP stmt {
            Block (
                  [VarDec (IntTyp, $3, Some (CallFunc ("-", [$5; IntExp 1])))],
                  [While (
                        StmtExp (
                              Assign (Var $3, CallFunc ("+", [VarExp (Var $3); IntExp 1])),
                              CallFunc ("<", [VarExp (Var $3); $7])
                        ), $9)
                  ]
            )
     }
     | SPRINT LP STR RP SEMI                    { CallProc ("sprint", [StrExp $3]) }
     | IPRINT LP expr RP SEMI                   { CallProc ("iprint", [$3]) }
     | SCAN LP ID RP SEMI                       { CallProc ("scan", [VarExp (Var $3)]) }
     | NEW LP ID RP SEMI                        { CallProc ("new", [ VarExp (Var $3)]) }
     | ID LP aargs_opt RP SEMI                  { CallProc ($1, $3) }
     | RETURN expr SEMI                         { CallProc ("return", [$2]) }
     | block                                    { $1 }
     | BREAK SEMI                               { Break }
     | CONTINUE SEMI                            { Continue }
     | SEMI                                     { NilStmt }
     | IF LP syntax_error RP                    { StmtSyntaxError ($3) }
     | WHILE LP syntax_error RP                 { StmtSyntaxError($3) }
     | syntax_error SEMI                        { StmtSyntaxError ($1) }
     ;

aargs_opt: /* empty */     { [] }
         | aargs            { $1 }
         ;

aargs : aargs COMMA expr  { $1@[$3] }
      | expr               { [$1] }
      ;

block : LB decs stmts RB  { Block ($2, $3) }
      | LB syntax_error RB { StmtSyntaxError($2) }
      ;

expr : NUM                          { IntExp $1  }
     | ID                           { VarExp (Var $1) }
     | ID LP aargs_opt RP           { CallFunc ($1, $3) } 
     | ID LS expr RS                { VarExp (IndexedVar (Var $1, $3)) }
     | expr PLUS expr               { CallFunc ("+", [$1; $3]) }
     | ID INC                       { StmtExp (
                                          Assign (Var $1, CallFunc ("+", [VarExp (Var $1); IntExp 1])),
                                          CallFunc ("-", [VarExp (Var $1); IntExp 1])
                                    )}
     | ID LS expr RS INC            { StmtExp (
                                          Assign (IndexedVar (Var $1, $3), CallFunc ("+", [VarExp (IndexedVar (Var $1, $3)); IntExp 1])),
                                          CallFunc ("-", [VarExp (IndexedVar (Var $1, $3)); IntExp 1])
                                    )}
     | expr MINUS expr              { CallFunc ("-", [$1; $3]) }
     | expr TIMES expr              { CallFunc ("*", [$1; $3]) }
     | expr DIV expr                { CallFunc ("/", [$1; $3]) }
     | expr MOD expr                { CallFunc ("-", [
                                          $1;
                                          CallFunc ("*", [
                                                $3;
                                                CallFunc ("/", [$1; $3])
                                          ]);
                                      ]) 
                                    }
     | expr POW expr                { CallFunc ("^", [$1; $3]) }
     | MINUS expr %prec UMINUS      { CallFunc("!", [$2]) }
     | LP expr RP                   { $2 }
     ;

cond : expr EQ expr  { CallFunc ("==", [$1; $3]) }
     | expr NEQ expr { CallFunc ("!=", [$1; $3]) }
     | expr GT expr  { CallFunc (">", [$1; $3]) }
     | expr LT expr  { CallFunc ("<", [$1; $3]) }
     | expr GE expr  { CallFunc (">=", [$1; $3]) }
     | expr LE expr  { CallFunc ("<=", [$1; $3]) }
     ;
%%
