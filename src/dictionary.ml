open Letter

let dictionary =
  (** Should concat list 1_10 and 5_15 *) 
  [ Client_utils.list_of_dict "dict/dict_100000_1_10.txt" @ Client_utils.list_of_dict "dict/dict_100000_5_15.txt"]
(* @ [Client_utils.list_of_dict "dict/dict_100000_25_75.txt"]
@ [Client_utils.list_of_dict "dict/dict_100000_50_200.txt"] *)

let contains (letters: letter list) =
  let str = List.fold_left (fun str letter -> 
    let letterStr = String.make 1 letter.letter in
    letterStr ^ str
  ) "" letters in
  let length = String.length str in
  if length >= 1 && length <= 15 then
    List.mem str (List.nth dictionary 0)
  (* else if length >= 25 && length <= 75 then
    List.mem str (List.nth dictionary 1)
  else if length >= 50 && length <= 200 then
    List.mem str (List.nth dictionary 2) *)
  else false
