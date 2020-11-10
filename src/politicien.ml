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

let send_new_word st level =
  let _ = st in
  let _ = level in
  (* generate a word above the blockchain head, with the adequate letters *)
  (* then send it to the server *)
  failwith ("à programmer" ^ __LOC__)

let run ?(max_iter = 0) () =
  (* ignoring unused variables - to be removed *)
  ignore max_iter ;

  (* end ignoring unused variables - to be removed *)

  (* Generate public/secret keys *)
  Log.log_warn "TODO" ;
  (* Get initial wordpool *)
  Log.log_warn "TODO" ;
  (* Generate initial blocktree *)
  Log.log_warn "TODO" ;
  (* Get initial letterpool *)
  Log.log_warn "TODO" ;
  (* Generate initial letterpool *)
  Log.log_warn "TODO" ;
  (* Create and send first word *)
  Log.log_warn "TODO" ;
  (* start listening to server messages *)
  Log.log_warn "TODO" ;
  (*  main loop *)
  failwith ("à programmer" ^ __LOC__)

let _ =
  let main =
    Random.self_init () ;
    let () = Client_utils.connect () in
    run ~max_iter:(-1) ()
  in
  main
