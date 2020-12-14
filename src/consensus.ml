open Word
open Letter


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
  let rec recur (wordContent : letter list) : int =
    match wordContent with
    | [] -> 0
    | (e::tl) -> recur tl + (letter_score e)
  in recur word.word


let fitness word_store word = 
  let rec recur hash =
    let word = Store.get_word word_store hash in
      if word.level = 0 then 0
      else recur (word.head) + (word_score word)
  in recur (Word.hash word) 

let rec head ?level (word_store : Store.word_store) =
  let compare word1 word2 =
    if Option.is_none word1 then word2
    else if Option.is_none word2 then word1
    else (
      let word1, word2 = Option.get word1, Option.get word2 in
      let fit1, fit2 = fitness word_store word1, fitness word_store word2 in
      if fit1 > fit2 then Some word1 else Some word2
    )
  in
  (** Compare two words note and choose higher one *)
  let res = ref None in
  let word_list = List.of_seq (Hashtbl.to_seq (Store.get_words_table word_store)) in
  List.iter (fun (_, word) -> let word = Some word in res := (compare !res word)) word_list;
  if Option.is_none !res then head ~level:((Option.get level) -1)  word_store else !res
  


let win (word_store:Store.word_store) =
  let scores = Hashtbl.create (Store.length word_store) in
  let words = List.of_seq (Hashtbl.to_seq (Store.get_words_table word_store) ) in
  List.iter (fun pair ->
    match pair with
    | (_, word) ->     
      let score = word_score word in 
      if (Hashtbl.mem scores word.politician) then (
        let refscore = Hashtbl.find scores word.politician in
        refscore := !refscore + score;
      ) else Hashtbl.add scores word.politician (ref score);
  ) words ;
  let winner = ref None in
  let max_score = ref 0 in
  let author_scores = List.of_seq (Hashtbl.to_seq scores) in
  List.iter (fun (pk, score) -> 
    if(!score > !max_score) then winner := Some pk;
  ) author_scores;
  Option.get !winner



