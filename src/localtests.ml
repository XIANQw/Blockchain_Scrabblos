open Letter
open Dictionary

(* interleave 1 [2;3] = [ [1;2;3]; [2;1;3]; [2;3;1] ] *)
let rec interleave x lst = 
  match lst with
  | [] -> [[x]]
  | hd::tl -> (x::lst) :: (List.map (fun y -> hd::y) (interleave x tl))
;;

(*permutations [1; 2; 3] = [[1; 2; 3]; [2; 1; 3]; [2; 3; 1]; [1; 3; 2]; [3; 1; 2]; [3; 2; 1]] *)
let rec permutations lst = 
  match lst with
  | hd::tl -> List.concat (List.map (interleave hd) (permutations tl))
  | _ -> [lst]
;;

let rec print_list = function 
[] -> print_string " ]"
| e::l -> print_int e ; print_string "," ; print_list l
;;




let generate_new_word_by_letters (letters:letter list) = 
  let allCombinations = permutations letters in
  let rec parcours (combinations :letter list list) =
    match combinations with
    | [] -> None
    | combination :: tl -> 
      if contains combination then Some combination else parcours tl
  in parcours allCombinations;;

(*
let p=permutations [1;2;3] in
List.iter print_list p;;*)

let i=interleave 1 [2;3] in
List.iter print_list i;;
(*
let pk,sk =Crypto.genkeys ();;
let l=make ~letter='c' ~head=Constants.genesis ~level=1 ~pk=pk ~sk=sk  ;;*)

