# レポート

## フロントエンド

### 1

- (lexer.mll) 以下のようにコメントを無視するようなルールを追加した．ただし，以降の課題で行数を取得する際に改行をカウントするために，行数をインクリメントしている．
```ocaml
  | "//" [^'\n']* '\n'      { Lexing.new_line lexbuf; lexer lexbuf }

### 2

- この課題のスコープではないが，エラー回復して複数のエラーを表示するようにした．
  - また，要件が変わってしまうが，直後の字句ではなく行全体を表示したのち次行で`^`によってエラー箇所を示すようにした．
- (parser.mly) 以下のようにsyntax errorの情報を付加する文法を追加した．
```ocaml
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
```

- (parser.mly) 以下のように`dec`にsyntax errorを発生させる文法を追加した．
```ocaml
dec:
   ...
   | syntax_error SEMI                  { [DecSyntaxError($1)] }
   ;
```

- (parser.mly) 以下のように`stmt`にsyntax errorを発生させる文法を追加した．
```ocaml
dec:
   ...
   | IF LP syntax_error RP                    { StmtSyntaxError ($3) }
   | WHILE LP syntax_error RP                 { StmtSyntaxError($3) }
   | syntax_error SEMI                        { StmtSyntaxError ($1) }
   ;
```

- (parser.mly) 以下のように`block`にsyntax errorを発生させる文法を追加した．
```ocaml
block : LB decs stmts RB  { Block ($2, $3) }
      | LB syntax_error RB { StmtSyntaxError($2) }
      ;
```

- (ast.ml) 以下のようにSyntaxError関連のコードを追加した．
```ocaml
type syntax_error = SyntaxError of int * int * int * int
...
and stmt =
  ...
  | StmtSyntaxError of syntax_error
...
and dec =
  ...
  | DecSyntaxError of syntax_error
```

- (syntax.ml) 以下のようにsyntax errorを検知するためのファイルを追加した．
  - `SyntaxError`があるかを再帰的に確認し，全て確認した後に一つでもあったなら`SyntaxErr`という例外を投げるようにした．
  - `handle_syntax_error`は`SyntaxError`があった場合にその情報を表示する関数である．
```ocaml
open Ast

exception SyntaxErr

let rec replace_tabs s = String.map (fun c -> if c = '\t' then ' ' else c) s

and handle_syntax_error e (lines : string list) =
  (match e with
  | SyntaxError (sl, sc, _, ec) ->
      Printf.printf "Syntax error at line %d, column %d-%d\n%s\n%s\n" sl sc ec
        (replace_tabs (List.nth lines (sl - 1)))
        (String.make sc ' ' ^ String.make (ec - sc + 1) '^'));
  true

and check_prog ast (lines : string list) =
  match check_stmt ast lines with true -> raise SyntaxErr | false -> ()

and check_dec ast (lines : string list) =
  match ast with
  | FuncDec (_, _, _, s) -> check_stmt s lines
  | DecSyntaxError e -> handle_syntax_error e lines
  | _ -> false

and check_stmt ast (lines : string list) =
  match ast with
  | Block (dl, st) ->
      let dec_res = List.map (fun d -> check_dec d lines) dl in
      let stmt_res = List.map (fun s -> check_stmt s lines) st in
      List.exists (( = ) true) dec_res || List.exists (( = ) true) stmt_res
  | If (_, s, es) -> (
      check_stmt s lines
      || match es with Some s -> check_stmt s lines | None -> false)
  | While (_, s) -> check_stmt s lines
  | StmtSyntaxError e -> handle_syntax_error e lines
  | _ -> false
```

- (sim.ml) 以下のように入力をstringに変換してからlexbufに変換している．
```ocaml
let cin_lines =
  let rec read_lines ic acc =
    try
      let line = input_line ic in
      read_lines ic (line :: acc)
    with End_of_file -> List.rev acc (* 入力順を維持 *)
  in
  let cin =
    if Array.length Sys.argv > 1 then open_in Sys.argv.(1) else stdin
  in
  read_lines cin []
in
(* lexbufをstringから作成 *)
let cin_str = String.concat "\n" cin_lines ^ "\n" in
(* 行を結合して1つの文字列に *)
let lexbuf = Lexing.from_string cin_str in
```

- (sim.ml) 以下のようにコード生成の前にsyntax errorを検知するようにした．
```ocaml
let ast = Parser.prog Lexer.lexer lexbuf in
let _ = Syntax.check_prog ast cin_lines in
let code = Emitter.trans_prog ast in
```

- (sim.ml) 以下のように`SyntaxErr`の例外をキャッチして正常に終了するようにした．
```ocaml
try main () with
...
| Syntax.SyntaxErr -> ()
...
```

## バックエンド

### 1

- (lexer.mll) 以下のように余りの式のルールを追加した．
```ocaml
  | '%'       { MOD }
```

- (parser.mly) 以下のように余りの式の文法を追加した．ASTを工夫して，余りの式を計算するようにした．
```ocaml
expr:
  ...
  | expr MOD expr   { CallFunc ("-", [
                        $1;
                        CallFunc ("*", [
                            $3;
                            CallFunc ("/", [$1; $3])
                        ]);
                      ]) 
                    }
  ...
```

### 2

- (ast.ml) ASTに以下のようなoptionを持たせることで代入を可能にした．
```ocaml
and dec =
  ...
  | VarDec of typ * id * (exp option)
  ...
```

- (emitter.ml) 以下では，ブロックの宣言を処理する際に代入が発生するもののみをフィルターし，それらをAssignノードに変換してからコード生成を行い，ブロック本体のコードと連結している．
```ocaml
| Block (dl, sl) ->
    (* ブロック内宣言の処理 *)
    let tenv', env', addr' = type_decs dl nest tenv env in
    List.iter (fun d -> trans_dec d nest tenv' env') dl;
    (* フレームの拡張 *)
    let ex_frame = sprintf "\tsubq $%d, %%rsp\n" ((-addr' + 16) / 16 * 16) in
    let vars =
      List.map
        (fun da -> match da with VarDec (t, v, Some e) -> Assign (Var v, e))
        (List.filter
           (fun d ->
             match d with VarDec (_, _, Some _) -> true | _ -> false)
           dl)
    in
    let dc_code =
      List.fold_left
        (fun code ast ->
          code ^ trans_stmt ast nest loop_start loop_end tenv' env')
        "" vars
    in
    (* 本体（文列）のコード生成 *)
    let code =
      List.fold_left
        (fun code ast ->
          code ^ trans_stmt ast nest loop_start loop_end tenv' env')
        dc_code sl
      (* 局所変数分のフレーム拡張の付加 *)
    in
    ex_frame ^ code
```

- (parser.mly) 以下のようにdecに代入文の文法を追加した．
```ocaml
dec:
  ...
  | ty ID ASSIGN expr SEMI             { [VarDec ($1, $2, Some($4))] 
  ...
```

- その他，ASTを処理するパターンマッチを修正した．

### 3

- (lexer.mll) 以下のように`^`比較演算子のルールを追加した．
```ocaml
| '^'                     { POW }
```
- (parser.mly) tokenに加えた上で以下のように`^`比較演算子の文法を追加した．
```ocaml
| expr POW expr                { CallFunc ("^", [$1; $3]) }
```

- (semant.ml) 以下のように`^`比較演算子の型チェックを追加した．
```ocaml
| CallFunc ("^", [left; right]) -> 
     (check_int (type_exp left env); check_int(type_exp right env); INT)
```

- (semant.ml) 累乗は右結合するようにしている．
```ocaml
%right POW
```

- (emitter.ml) 以下のように`^`比較演算子のコード生成を追加した．
  - 少し煩雑になってしまったが，指数の分だけ乗算を繰り返すことで累乗を計算している．
  - ステップは以下の通りである．
    - まずtrans_expで左辺と右辺の式を計算する．
    - その後，左辺を%r8，右辺を%r9にpopする．
      - 両辺をtrans_expしてからpopするのは，`(2 ^ 3) ^ 2`などの入れ子の計算でレジスタが上書きされるのを防ぐためであり，一回の累乗計算の中で他の翻訳が入らないようにしている．
    - %rbx(ループの終了条件の比較用変数)に0を代入し，%rax(累乗計算の結果)に1をpushする．
    - ループの開始地点を設定し，%rbxと%r9を比較してループを抜けるかどうかを判定する．
    - ループ内では，%raxに%r8を掛けて%raxに代入し，%rbxに1を加算する．
    - ループの開始地点へジャンプしてループを繰り返す．
  - 以下の擬似コードをイメージするとわかりやすい．
    ```c
    int pow(int x, int y)
    {
        int i = 0;
        int ans = 1;
        while (i < y){
            ans *= x;
            i++;
        }
        return ans
    }
    ```
  - もう少し綺麗な実装がありそうだと思って考えたが，他のコード生成部分に依存せずにこのスコープ内で多少複雑になる分には他に影響はないと考えたためこの実装にした．

```ocaml
| CallFunc ("^", [left; right]) ->
            let loop_l = incLabel() in
                  let l = incLabel() in
                         trans_exp left nest env
                         ^ trans_exp right nest env
                         ^ "\tpopq %r9\n"
                         ^ "\tpopq %r8\n"
                         ^ "\tmovq $0, %rbx\n"
                         ^ "\tpushq $1\n"
                         ^ sprintf "L%d:\n" loop_l
                         ^ "\tcmpq %r9, %rbx\n"
                         ^ sprintf "\tjge L%d\n" l
                         ^ "\tpopq %rax\n"
                         ^ "\timulq %r8, %rax\n"
                         ^ "\tpushq %rax\n"
                         ^ "\taddq $1, %rbx\n"
                         ^ sprintf "\tjmp L%d\n" loop_l
                         ^ sprintf "L%d:\n" l
```

### 4

- (lexer.mll) 以下のように`++`演算子のルールを追加した．
```ocaml
  | "++"                    { INC }
```

- (ast.ml) 以下のようにexpにStmtExpを追加した．
```ocaml
and exp =
  ...
  | StmtExp of stmt * exp
```

- (parser.mly) tokenに加えた上で以下のように`INC`のルールを追加した．
```ocaml
| ID INC  { StmtExp (
                Assign (Var $1, CallFunc ("+", [VarExp (Var $1); IntExp 1])),
                CallFunc ("-", [VarExp (Var $1); IntExp 1])
          )}
| ID LS expr RS INC { StmtExp (
                        Assign (
                            IndexedVar (Var $1, $3),
                            CallFunc ("+", [
                                VarExp (IndexedVar (Var $1, $3));
                                IntExp 1
                            ])
                        ),
                        CallFunc ("-", [
                            VarExp (IndexedVar (Var $1, $3));
                            IntExp 1
                        ])
                    )}
```

- (semant.ml) 以下のように`StmtExp`の型チェックを追加した．
```ocaml
| StmtExp (s, e) -> (type_stmt s env; type_exp e env)
```

- (emitter.ml) 以下のように`StmtExp`のコード生成を追加した．
```ocaml
| StmtExp (s, e) ->
               trans_stmt s nest initTable env
             ^ trans_exp e nest env
```

### 5

- (lexer.mll) 以下のように`+=`演算子のルールを追加した．
```ocaml
  | "+="                    { PASSIGN }
```

- (parser.mly) tokenに加えた上で以下のように`PASSIGN`のルールを追加した．
```ocaml
| ID PASSIGN expr SEMI            { Assign (Var $1, CallFunc ("+", [VarExp (Var $1); $3])) }
| ID LS expr RS PASSIGN expr SEMI { Assign (
                                        IndexedVar (Var $1, $3),
                                        CallFunc ("+", [
                                            VarExp (IndexedVar (Var $1, $3));
                                            $6
                                        ])
                                    )
                                  }
```


### 6

- (lexer.mll) 以下のように`do`を追加した．
```ocaml
  | "do"                    { DO }
```

- (parser.mly) tokenに加えた上で以下のように`do stmt while (cond)`のルールを追加した．
  - 一度stmtを実行してから，while文を実行するようにしている．
```ocaml
| DO stmt WHILE LP cond RP SEMI { Block ([], [$2; While ($5, $2)]) }
```

### 7

- (lexer.mll) 以下のように`for`と`..`を追加した．
```ocaml
  | "for"                   { FOR }
  | ".."                    { FORRANGE}
```

- (parser.mly) tokenに加えた上で以下のように`for`文のルールを追加した．
  - ASTでWhile文を使ってfor文を表現している．
  - 初めは文の実行後にインクリメントしていたが，自作機能でbreak, continueを実装するために終了条件の比較前にインクリメントするように変更した．
    - これをやらないと，for文でcontinueを実行すると変数がインクリメントされずに無限ループに陥る．
```ocaml
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
```

- (semant.ml) 以下のように`type_cond`の型チェックに`StmtExp`のパターンマッチを追加した．
```ocaml
| StmtExp (s, e) -> type_stmt s env; type_cond e env
```

- (emitter.ml) 以下のように`trans_cond`に`StmtExp`のパターンマッチを追加した．
```ocaml
| StmtExp(s, e) -> (
      let stmt_code = trans_stmt s nest initTable env in
      let (cond_code, l) = trans_cond e nest env in
      (stmt_code ^ cond_code, l)
)
```

## 独自機能

### `break`文と`continue`文の実装

- (lexer.mll) 以下のように`break`と`continue`を追加した．
```ocaml
  | "break"                 { BREAK }
  | "continue"              { CONTINUE }
```
- (parser.mly) tokenに加えた上で以下のように`break`文と`continue`文のルールを追加した．
```ocaml
| BREAK SEMI                { Break }
| CONTINUE SEMI             { Continue }
```

- (ast.ml) 以下のように`Break`と`Continue`を追加した．
```ocaml
| Break
| Continue
```

- (semant.ml) 以下のように`Break`と`Continue`のパターンマッチを追加した．
```ocaml
| Break -> ()
| Continue -> ()
```

- (emitter.ml) 以下のように`trans_stmt`の引数に`break`と`continue`用のラベルを追加した．
```ocaml
and trans_stmt ast nest loop_start loop_end tenv env =
```

- (emitter.ml) 以下のように`while`文のコード生成に`break`と`continue`のラベルを更新している．
```ocaml
  | While (e, s) ->
      let condCode, l_end = trans_cond e nest env in
      let l_start = incLabel () in
      sprintf "L%d:\n" l_start ^ condCode
      ^ trans_stmt s nest (Some l_start) (Some l_end) tenv env
      ^ sprintf "\tjmp L%d\n" l_start
      ^ sprintf "L%d:\n" l_end
```
- (emitter.ml) 以下のように`break`文と`continue`文のコード生成を追加した．
```ocaml
  | Break -> (
      match loop_end with
      | Some l -> sprintf "\tjmp L%d\n" l
      | None -> raise (Err "break out of loop"))
  | Continue -> (
      match loop_start with
      | Some l -> sprintf "\tjmp L%d\n" l
      | None -> raise (Err "continue out of loop"))
```

