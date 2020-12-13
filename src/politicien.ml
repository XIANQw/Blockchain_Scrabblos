open Messages
open Word
open Crypto
open Letter
open Dictionary


type politician = { sk : Crypto.sk; pk: Crypto.pk}  [@@deriving yojson, show]

let make_politician (sk:Crypto.sk) (pk:Crypto.pk) =
  {sk:sk; pk:pk}

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
  let head_hash = Crypto.hash head in
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

let generate_new_word_by_letters (letters:letter list) = 
  let allCombinations = permutations letters in
  let rec parcours (combinations :letter list list) =
    match combinations with
    | [] -> None
    | combination :: tl -> 
      if contains combination then Some combination else parcours tl
  in parcours allCombinations


let send_new_word state level =
  let letters = List.map snd 
  (List.of_seq (Hashtbl.to_seq (Store.get_letters_table state.letter_store))) in
  let cur_letters = List.filter (fun (letter:letter) -> letter.level = level) letters in
  let res = generate_new_word_by_letters cur_letters in
  if Option.is_some res then (
    let letterlist = Option.get res in
    Option.iter (fun (head:word) ->
      let word = make_word_on_blockletters level 
        letterlist 
        state.politician 
        (Word.to_bigstring head) in
      Client_utils.send_some (Messages.Inject_word word)
    )
    (Consensus.head ~level:(level - 1) state.word_store)
  )


let run ?(max_iter = 0) () =

  (* Generate public/secret keys *)
  Log.log_warn " Generate public/secret keys " ;
  let pk, sk = Crypto.genkeys () in
  let regist_msg = Messages.Register pk in Client_utils.send_some regist_msg;
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
  send_new_word state wordpool.current_period;

  (* start listening to server messages *)
  Log.log_warn "Start listening to server messages";
  Client_utils.send_some Messages.Listen;
  
  (*  main loop *)
  let level = ref wordpool.current_period in
  let rec loop max_iter =
    if (max_iter = 0) then ()
    else (
      match Client_utils.receive () with
      | Messages.Inject_word word -> (** Command server to inject a word *)
          Store.add_word storeWords word;
          let st = {politician=state.politician; 
                    word_store=storeWords; 
                    letter_store=state.letter_store; 
                    next_words = state.next_words} in
          Option.iter (
            fun (head:word) ->
              if head = word then (
                Log.log_info "Head updated to incoming word %a@." Word.pp word ;  
                send_new_word st !level
              ) else Log.log_info "incoming word %a not a new head@." Word.pp word;
          ) (Consensus.head ~level:(!level - 1) storeWords)
      | Messages.Inject_letter letter -> (** Command server to inject a letter *)
        Store.add_letter storeLetters letter;
        let st = {politician=state.politician; 
                  word_store=state.word_store; 
                  letter_store=storeLetters; 
                  next_words = state.next_words} in
        Option.iter 
          (fun (head : word) -> 
            Log.log_info "head is %a @." Word.pp head; 
            send_new_word st !level
          )
          (Consensus.head ~level:(!level-1) storeWords)
      | Messages.Next_turn next -> level := next; Log.log_info "Next turn";
      |_ -> ();
      loop (max_iter - 1)
    );
  in loop max_iter;

  (** Stop listening after loop *)
  Client_utils.send_some Messages.Stop_listen;
  (** Find the winner *)
  let winner = Consensus.win storeWords in
  Log.log_info "winner is %a@." Crypto.pp_pk winner

let _ =
  let main =
    Log.log_info "Start politician";
    Random.self_init () ;
    let () = Client_utils.connect () in
    run ~max_iter:(-1) ()
  in
  main
