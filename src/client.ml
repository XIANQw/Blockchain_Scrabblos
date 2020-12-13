let conn : Unix.file_descr option ref = ref None

let connect ?(addr = Unix.inet_addr_of_string "::1") ?(port = 12345) () =
  let main_socket = Unix.(socket PF_INET6 SOCK_STREAM 0) in
  let remote_addr = Unix.ADDR_INET (addr, port) in
  let () = Unix.connect main_socket remote_addr in
  conn := Some main_socket ;
  Lwt.return_unit

let send msg = Option.map (Messages.send msg) !conn

let receive ?check () =
  Option.map Messages.receive !conn |> function
  | None -> Log.log_error "No connection@"
  | Some t -> (
      match t with
      | Ok msg ->
          Log.log_info "Received %a@." Messages.pp_message msg ;
          Utils.unopt_map ~default:() (fun f -> f msg) check
      | Error s -> Log.log_error "Reception error %s@." s )

exception Test_failure of (string * string)

let rec checker ~hard ?(ignore_msgs = fun _ -> false) test sent received =
  if ignore_msgs received then
    receive ~check:(checker ~hard ~ignore_msgs test sent) ()
  else if test (sent, received) then
    Log.log_success
      "message %a after %a@."
      Messages.pp_message
      received
      Messages.pp_message
      sent
  else (
    Log.log_error
      "message %a after %a@."
      Messages.pp_message
      received
      Messages.pp_message
      sent ;
    if hard then
      raise
      @@ Test_failure
           (Messages.show_message sent, Messages.show_message received) )

let ignore_msgs = function Messages.Next_turn _ -> true | _ -> false

let check_register ~hard =
  checker ~hard ~ignore_msgs (function
      | (Register _, Letters_bag _) -> true
      | _ -> false)

let check_get_full_letterpool ~hard =
  checker ~hard ~ignore_msgs (function
      | (Get_full_letterpool, Full_letterpool _) -> true
      | _ -> false)

let check_get_letterpool_since ~hard =
  checker ~hard ~ignore_msgs (function
      | (Get_letterpool_since d, Diff_letterpool { since; _ }) when d = since ->
          true
      | _ -> false)

let check_get_full_wordpool ~hard =
  checker ~hard ~ignore_msgs (function
      | (Get_full_wordpool, Full_wordpool _) -> true
      | _ -> false)

let check_get_wordpool_since ~hard =
  checker ~hard ~ignore_msgs (function
      | (Get_wordpool_since d, Diff_wordpool { since; _ }) when d = since ->
          true
      | _ -> false)

let check_inject_letter ~hard =
  checker ~hard ~ignore_msgs (function
      | (Inject_letter l, Diff_letterpool { letterpool; _ })
        when List.mem l letterpool.letters ->
          true
      | _ -> false)

let check_inject_word ~hard =
  checker ~hard ~ignore_msgs (function
      | (Inject_word w, Diff_wordpool { wordpool; _ })
        when List.mem w (List.map snd wordpool.words) ->
          true
      | _ -> false)

let no_some v = match v with None -> failwith "No connection" | Some v -> v

let send_some v =
  Log.log_info "Sending %a@." Messages.pp_message v ;
  no_some @@ send v

let test ?(hard = false) () =
  Log.log_info "Start client's test hard=%b.@." hard;
  let (pk, sk) = Crypto.genkeys () in

  Log.log_info "Test resgistion.@.";
  let register = Messages.Register pk in
  let () = send_some register in
  let () = receive ~check:(check_register ~hard register) () in

  Log.log_info "Test get full letterpool.@.";
  let get_full_letterpool = Messages.Get_full_letterpool in
  let () = send_some get_full_letterpool in
  let () =
    receive ~check:(check_get_full_letterpool ~hard get_full_letterpool) ()
  in
  Log.log_info "Test get full wordpool.@.";
  let get_full_wordpool = Messages.Get_full_wordpool in
  let () = send_some get_full_wordpool in
  let () =
    receive ~check:(check_get_full_wordpool ~hard get_full_wordpool) ()
  in

  Log.log_info "Test inject letter.@.";

  let letter = Author.make_letter_on_hash sk pk 0 Constants.genesis 'a' in
  Log.log_info "Letter = %a@." Letter.pp_letter letter;

  let message = Messages.Inject_letter letter in
  let () = send_some message in
  let getpool = Messages.Get_letterpool_since 0 in
  let () = send_some getpool in
  let () = receive ~check:(check_inject_letter ~hard message) () in

  let politicien = Politicien.{ pk; sk } in
  let letters =
    List.map (Author.make_letter_on_hash sk pk 0 Constants.genesis) ['a'; 'b']
  in

  let word =
    Politicien.make_word_on_hash 0 letters politicien Constants.genesis
  in
  let message = Messages.Inject_word word in
  let () = send_some message in
  let getpool = Messages.Get_wordpool_since 0 in
  let () = send_some getpool in
  let () = receive ~check:(check_inject_word ~hard message) () in

  Lwt.return_unit

let _ =
  let main =
    Log.log_info "Client starting...@.";
    let _ = connect () in
    test ~hard:true ()
  in
  Lwt_main.run main
