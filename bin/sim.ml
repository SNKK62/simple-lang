let main () =
  (* ファイルを開く *)
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

  (* 生成コード用ファイルtmp.sをオープン *)
  let file = open_out "tmp.s" in
  (* コード生成 *)
  let ast = Parser.prog Lexer.lexer lexbuf in
  let _ = Syntax.check_prog ast cin_lines in
  let code = Emitter.trans_prog ast in
  (* 生成コードの書出しとファイルのクローズ *)
  output_string file code;
  close_out file;
  (* アセンブラとリンカの呼出し *)
  let _ = Unix.system "gcc tmp.s" in
  ()

let _ =
  try main () with
  | Parsing.Parse_error -> print_string "syntax error\n"
  | Table.No_such_symbol x -> print_string ("no such symbol: \"" ^ x ^ "\"\n")
  | Syntax.SyntaxErr -> ()
  | Semant.TypeErr s -> print_string (s ^ "\n")
  | Semant.Err s -> print_string (s ^ "\n")
  | Table.SymErr s -> print_string (s ^ "\n")
