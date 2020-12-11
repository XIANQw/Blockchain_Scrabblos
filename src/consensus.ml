open Word
open Constants
open Letter

(* ignoring unused variables - to be removed *)
let _ = ignore genesis

(* end ignoring unused variables - to be removed *)


let letter_score l : int =
  match l.letter with
  | 'a' -> 1
  | 'b' -> 3
  | 'c' -> 3
  | 'd' -> 2
  | 'e' -> 1
  | 'f' -> 4
  | 'g' -> 2
  | 'h' -> 4
  | 'i' -> 1
  | 'j' -> 8
  | 'k' -> 5
  | 'l' -> 1
  | 'm' -> 3
  | 'n' -> 1
  | 'o' -> 1
  | 'p' -> 3
  | 'q' -> 10
  | 'r' -> 1
  | 's' -> 1
  | 't' -> 1
  | 'u' -> 1
  | 'v' -> 4
  | 'w' -> 4
  | 'x' -> 8
  | 'y' -> 4
  | 'z' -> 10
  | _ -> 0


let word_score (word : word) : int =
  let rec recur (wordContent : letter list) res : int =
    match wordContent with
    | [] -> 0
    | (e::tl) -> recur tl (res + (letter_score e))
  in recur word.word 0


let fitness st word = 
  let rec fitness hash score =
    let word  = Store.get_word st hash in
      if word.level = 0 then 
        score 
      else fitness (word.head) (score + (word_score word))
  in fitness (Word.hash word) 0


  

let head ?level (st : Store.word_store) =
  let compare word1 word2 st = 
    let word1, word2 = Option.get word1, Option.get word2 in
    let fit1, fit2 = fitness st word1, fitness st word2 in
      if fit1 > fit2 then 
        Some word1 
      else if fit1 < fit2 then
        Some word2 
      else if word1.signature < word2.signature then 
        Some word1
      else if word1.signature > word2.signature then 
        Some word2  
      else  failwith "fail head"
  in
  Hashtbl.fold
      (fun _ (word:Word.word) w ->
        if Option.get level != word.level then
          w 
        else if w = None then 
          Some(word) 
        else 
          compare (Some word) w st) 
      (Store.get_words_table st)
      None




