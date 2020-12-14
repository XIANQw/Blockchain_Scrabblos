(* open Messages *)
open Word
open Crypto

type politician = { sk : Crypto.sk; pk : Crypto.pk } [@@deriving yojson, show]

type state = {
  politician : politician;
  word_store : Store.word_store;
  letter_store : Store.letter_store;
  next_words : word list;
}

let make_word_on_hash level letters politician head_hash : word =
  let head = head_hash in
  Word.make ~word:letters ~level ~pk:politician.pk ~sk:politician.sk ~head

let make_word_on_blockletters level letters politician head : word =
  let head_hash = hash head in
  make_word_on_hash level letters politician head_hash


  (* interleave 1 [2;3] = [ [1;2;3]; [2;1;3]; [2;3;1] ] *)
let rec interleave x lst = 
  match lst with
  | [] -> [[x]]
  | hd::tl -> (x::lst) :: (List.map (fun y -> hd::y) (interleave x tl))

(*permutations [1; 2; 3] = [[1; 2; 3]; [2; 1; 3]; [2; 3; 1]; [1; 3; 2]; [3; 1; 2]; [3; 2; 1]] *)
let rec permutations lst = 
  match lst with
  | hd::tl -> List.concat (List.map (interleave hd) (permutations tl))
  | _ -> [lst]
;;

let generate_new_word_by_letters (letters:Letter.letter list) = 
  let allCombinations = permutations letters in
  let rec parcours (combinations :Letter.letter list list) =
    match combinations with
    | [] -> None
    | combination :: tl -> 
      if Dictionary.contains combination then Some combination 
      else parcours tl
  in parcours allCombinations

let generate_new_word level state = 
  let letter_store = state.letter_store in
  let word_store = state.word_store in
  let head_op = Consensus.head ~level:(level) word_store in
  match head_op with 
  |None -> None
  |head -> let word = Option.get head in
    let hash_word = Word.hash word in
    let head_letters = Store.get_letters letter_store hash_word in
    let valid_letters = generate_new_word_by_letters head_letters in
    match valid_letters with
    |None -> None
    |valid_letters -> Some (make_word_on_blockletters level 
      (Option.get valid_letters) 
      state.politician
      (Word.to_bigstring word))
  
let is_word_optimal word_store word =
  let optimal = ref word in
  let words = Store.get_words_table word_store in
  let word_list = List.of_seq (Hashtbl.to_seq words) in
  List.iter (fun (_, mot) ->
    let scoreWord = Consensus.fitness word_store word in
    let scoreMot = Consensus.fitness word_store mot in
    if((mot.level = word.level) &&  (scoreMot > scoreWord)) then optimal := mot
    else () 
  ) word_list; !optimal = word
  
let send_new_word state level =
  let word_op = generate_new_word level state in
  match word_op with
  |None -> Log.log_info "Generate word failed@."
  |word_op -> let word = Option.get word_op in
  Store.add_word state.word_store word;
  (** Inject the word if and only if word has the highest score *)
  if is_word_optimal state.word_store word then (
    Log.log_info "Best word is %a@." Word.pp_word word;
    Client_utils.send_some (Messages.Inject_word word);
  )

  let run ?(max_iter = 0) () =

  (* Generate public/secret keys *)
  Log.log_warn " Generate public/secret keys " ;
  let (pk, sk) = Crypto.genkeys () in
  let politician = {sk:sk; pk:pk} in
  
  (* Get initial wordpool *)
  Log.log_warn "Get initial wordpool" ;
  Client_utils.send_some Messages.Get_full_wordpool;
  let wordpool = match Client_utils.receive () with
    | Messages.Full_wordpool wp -> wp
    | _ -> assert false
  in

  (* Generate initial blocktree *)
  Log.log_warn "Generate initial blocktree" ;
  let storeWords = Store.init_words () in 
    Store.add_words storeWords wordpool.words;

  (* Get initial letterpool *)
  Log.log_warn "Get initial letterpool" ;
  Client_utils.send_some Messages.Get_full_letterpool;
  let letterpool = match Client_utils.receive () with
    | Messages.Full_letterpool lp -> lp
    | _ -> assert false
  in

  (* Generate initial letterpool *)
  Log.log_warn "Generate initial letterpool" ;
  let storeLetters = Store.init_letters () in
  Store.add_letters storeLetters letterpool.letters;

  (* Create and send first word *)
  Log.log_warn "Create and send first word" ;
  let state = {politician=politician ; 
              word_store = storeWords; 
              letter_store = storeLetters; 
              next_words=[]} in
  send_new_word state (wordpool.current_period - 1) ;

  (* start listening to server messages *)
  Log.log_warn "Start listening to server messages";
  Client_utils.send_some Messages.Listen;
  
  (*  main loop *)
  let level = ref wordpool.current_period in
  let finish = ref false in
  
  let rec loop max_iter =
    if (max_iter = 0) then ()
    else (
      (match Client_utils.receive () with
      | Messages.Inject_word word -> (** Recieve command of inject a word *)
        Log.log_info "******** Inject word %a *******@." Word.pp word ;  
        Store.add_word storeWords word;
      | Messages.Inject_letter letter -> (** Command server to inject a letter *)
        Log.log_info "******** Inject letter %a ******@." Letter.pp_letter letter;
        Store.add_letter storeLetters letter;
        send_new_word state letter.level
      | Messages.Next_turn p -> 
        if( p < 0) then finish := true
        else level := p; Log.log_info "Next turn %d" p;
      |_ -> ()
      );
      if (!finish) then () else loop (max_iter - 1)
    )
    in
    loop max_iter;
    
  (** Stop listening after loop *)
  Client_utils.send_some Messages.Stop_listen;
  (** Find the winner *)
  let winner = Consensus.win storeWords in
  Log.log_info "winner is %a@." Crypto.pp_pk winner


let _ =
  let main =
    Random.self_init () ;
    let () = Client_utils.connect () in
    run ~max_iter:(-1) ()
  in
  main
