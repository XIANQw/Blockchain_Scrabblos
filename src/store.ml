open Word

type word_store = {
  check_sigs : bool;
  words_table : (Crypto.hash, word) Hashtbl.t;
}

let init_words ?(check_sigs = true) () : word_store =
  let words_table = Hashtbl.create 200 in
  Hashtbl.add words_table Constants.genesis Constants.genesis_word ;
  { check_sigs; words_table }

let add_word (st : word_store) w =
  if (not st.check_sigs) || Word.check_signature w then
    Hashtbl.add st.words_table (Crypto.hash @@ Word.to_bigstring w) w
  else
    Log.log_warn
      "Incorrect Word Signature %a, word not added to word store"
      Word.pp
      w

let add_words st ws = List.iter (add_word st) (List.map snd ws)

let get_word_opt (st : word_store) h = Hashtbl.find_opt st.words_table h

let get_word (st : word_store) h = Hashtbl.find st.words_table h

let get_words (st: word_store) = Hashtbl.to_seq_values st.words_table

let get_words_table (st: word_store) = st.words_table

let iter_words f st = Hashtbl.iter f st.words_table

type letter_store = {
  check_sigs : bool;
  letters_table : (Crypto.hash, Letter.t) Hashtbl.t;
}

let init_letters ?(check_sigs = true) () : letter_store =
  { check_sigs; letters_table = Hashtbl.create 200 }

let add_letter (st : letter_store) (l : Letter.t) =
  if (not st.check_sigs) || Letter.check_signature l then
    Hashtbl.add st.letters_table l.Letter.head l
  else
    Log.log_warn
      "Incorrect Letter Signature %a, letter not added to letter store"
      Letter.pp
      l

let add_letters (st : letter_store) (ls : Letter.t list) =
  List.iter (add_letter st) ls

let get_letters (st : letter_store) h = Hashtbl.find_all st.letters_table h

let get_letters_table (st : letter_store) = st.letters_table

let length st = Hashtbl.length st.words_table
