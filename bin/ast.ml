(* The definition of the abstract syntax tree *)

type id = string
type syntax_error = SyntaxError of int * int * int * int

type var = Var of id | IndexedVar of var * exp

and stmt =
  | Assign of var * exp
  | CallProc of id * exp list
  | Block of dec list * stmt list
  | If of exp * stmt * stmt option
  | While of exp * stmt
  | NilStmt
  | Break
  | Continue
  | StmtSyntaxError of syntax_error

and exp =
  | VarExp of var
  | StrExp of string
  | IntExp of int
  | CallFunc of id * exp list
  | StmtExp of stmt * exp

and dec =
  | FuncDec of id * (typ * id) list * typ * stmt
  | TypeDec of id * typ
  | VarDec of typ * id * exp option
  | DecSyntaxError of syntax_error

and typ = NameTyp of string | ArrayTyp of int * typ | IntTyp | VoidTyp
