open Messages
open Letter
open Crypto

let make_letter_on_hash sk pk level head_hash letter : letter =
  Letter.make ~letter ~head:head_hash ~level ~pk ~sk

let make_letter_on_block sk pk level block letter : letter =
  let head_hash = hash block in
  make_letter_on_hash sk pk level head_hash letter

(** Just generate lowercase latin letter*)
let random_char () = Random.int (122 - 97) + 97 |> Char.chr

let send_new_letter sk pk level store letter =
  (* Get blockchain head *)
  Option.iter
    (fun head ->
      (* Create new random letter *)
      Log.log_info "**** head word is %a@.*******" Word.pp head;
      let letter =
        make_letter_on_block
          sk
          pk
          level
          (Word.to_bigstring head)
          letter
      in
      (* Send letter *)
      let message = Messages.Inject_letter letter in
      Client_utils.send_some message)
    (Consensus.head ~level:(level - 1) store)

let run ?(max_iter = 0) () =
  (* Generate public/secret keys *)
  let (pk, sk) = Crypto.genkeys () in

  (* Register to the server *)
  let reg_msg = Messages.Register pk in
  Client_utils.send_some reg_msg ;

  (* drop provided letter_bag *)
  let letter_bag = ( match Client_utils.receive () with
  | Messages.Letters_bag letter_bag -> letter_bag
  | _ -> assert false ) in

  (* Get initial wordpool *)
  let getpool = Messages.Get_full_wordpool in
  Client_utils.send_some getpool ;
  let wordpool =
    match Client_utils.receive () with
    | Messages.Full_wordpool wordpool -> wordpool
    | _ -> assert false
  in

  (* Generate initial blocktree *)
  let store = Store.init_words () in
  Store.add_words store wordpool.words ;

  (* Create and send first letter *)
  let random_letter = List.nth letter_bag (Random.int (List.length letter_bag)) in
  send_new_letter sk pk wordpool.current_period store random_letter ;

  (* start listening to server messages *)
  Client_utils.send_some Messages.Listen ;

  (* start main loop *)
  let level = ref wordpool.current_period in
  let finish = ref false in
  let rec loop max_iter =
    if max_iter = 0 then ()
    else (
      ( match Client_utils.receive () with
      | Messages.Inject_word w ->
        Store.add_word store w ;
        Option.iter
          (fun head ->
            if head = w then (
              Log.log_info "Head updated to incoming word %a@." Word.pp w ;
              let random_letter = List.nth letter_bag (Random.int (List.length letter_bag)) in
              send_new_letter sk pk !level store random_letter)
            else Log.log_info "incoming word %a not a new head@." Word.pp w)
          (Consensus.head ~level:(!level - 1) store)
      | Messages.Next_turn p -> 
          if p>=0 then level := p else finish := true;
      | Messages.Inject_letter _ | _ -> () ) ;
      if !finish then () else loop (max_iter - 1) 
    )
  in loop max_iter ;
  (** When loop finished, stop listening *)
  Client_utils.send_some Messages.Stop_listen;
  let winner = Consensus.win store in 
  Log.log_info "WINNER: %a@." Crypto.pp_pk winner

let _ =
  let main =
    Random.self_init () ;
    let () = Client_utils.connect () in
    run ~max_iter:(-1) ()
  in
  main
