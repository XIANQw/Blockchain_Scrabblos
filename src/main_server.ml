let _ =
  Log.log_info "Server starting...@.";
  let addr_ref = ref None in
  let port_ref = ref 12345 in
  let no_check_sigs_ref = ref false in
  let no_turn_ref = ref false in
  let nb_rounds_ref = ref 15 in
  let timeout_ref = ref None in
  let parse_list =
    [
      ( "-bind",
        Arg.String (fun s -> addr_ref := Some (Unix.inet_addr_of_string s)),
        ":Address to which the server should bind (default is any)" );
      ( "-port",
        Arg.Set_int port_ref,
        ":Port to which the server should bind (default is any)" );
      ( "-nb-turns",
        Arg.Set_int nb_rounds_ref,
        ":Number of turns until the end of the game." );
      ("-no-turn", Arg.Set no_turn_ref, ":Disable the turn-by-turn mechanism");
      ( "-no-check-sigs",
        Arg.Set no_check_sigs_ref,
        ":Disable the signature verification" );
      ( "-timeout",
        Arg.Float (fun t -> timeout_ref := Some t),
        "Turns last no longer than [t].\n\
        \    This option has no effect if the turn-by-turn mechanism is not \
         activated." );
    ]
  in
  let doc = "Usage: server [options]" in
  Arg.parse parse_list (fun _doc -> failwith "Unexpected argument") doc ;
  let serve =
    Server.serve
      ?addr:!addr_ref
      ~port:!port_ref
      ~check_sigs:(not !no_check_sigs_ref)
      ~turn_by_turn:(not !no_turn_ref)
      ~nb_rounds:!nb_rounds_ref
      ?timeout:!timeout_ref
      ()
  in
  Lwt_main.run serve
