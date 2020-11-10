open Word
open Constants

(* ignoring unused variables - to be removed *)
let _ = ignore genesis

(* end ignoring unused variables - to be removed *)

let word_score { word; _ } : int =
  (* ignoring unused variables - to be removed *)
  ignore word ;
  (* end ignoring unused variables - to be removed *)
  (* TODO *)
  assert false

let fitness st word =
  (* ignoring unused variables - to be removed *)
  ignore st ;
  ignore word ;
  ignore word_score ;
  (* end ignoring unused variables - to be removed *)
  (* TODO *)
  assert false

(* TODO *)

let head ?level (st : Store.word_store) =
  (* ignoring unused variables - to be removed *)
  ignore level ;
  ignore st ;
  (* end ignoring unsed variables - to be removed *)
  (* TODO *)
  assert false
