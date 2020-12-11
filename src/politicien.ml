open Messages
open Word
open Crypto

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

let send_new_word st level =
  Option.iter ( fun (head:word) ->
  let lettersFromStore = Store.get_letters st.letter_store head.head in
  let word = make_word_on_blockletters level lettersFromStore st.politician (Word.to_bigstring head) in
  let message = Messages.Inject_word word in Client_utils.send_some message
  )
  (Consensus.head ~level:(level - 1) st.word_store)


let run ?(max_iter = 0) () =
  ignore max_iter;

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
  
  (*  main loop *)
  let level = ref wordpool.current_period in
  ignore level;
  failwith ("a programmer" ^ __LOC__)
  

let _ =
  let main =
    Random.self_init () ;
    let () = Client_utils.connect () in
    run ~max_iter:(-1) ()
  in
  main
