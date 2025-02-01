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
