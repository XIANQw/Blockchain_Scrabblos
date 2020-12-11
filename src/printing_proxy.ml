let out_conn : Lwt_unix.file_descr option ref = ref None

let in_conn : Lwt_unix.file_descr option ref = ref None

let connect ?(addr = Unix.inet_addr_of_string "::1") ?(port = 12346) () =
  Log.log_info "Connecting to %s@." (Unix.string_of_inet_addr addr) ;
  let main_socket = Lwt_unix.(socket PF_INET6 SOCK_STREAM 0) in
  let remote_addr = Lwt_unix.ADDR_INET (addr, port) in
  let%lwt () = Lwt_unix.connect main_socket remote_addr in
  let%lwt listening_sock =
    Server.create_listening_socket ~backlog:10 ~addr 12345
  in
  let%lwt (fd, _inaddr) = Lwt_unix.accept listening_sock in
  out_conn := Some main_socket ;
  in_conn := Some fd ;
  Lwt.return_unit

let send ch msg = Option.map (Messages.send_async ~verbose:false msg) ch

let receive ?(verbose = true) in_ch : bytes Lwt.t =
  let%lwt () =
    if verbose then Log.log_info "receiving Message.@." ;
    Lwt.return_unit
  in
  let%lwt () =
    if verbose then Log.log_info "reading size.@." ;
    Lwt.return_unit
  in
  let%lwt len = Utils.read_int_a in_ch in
  let _ = if verbose then Log.log_info "Reading %i chars@." len in
  let buf = Bytes.create len in
  let%lwt _ = Utils.read_channel_a in_ch buf 0 len in
  let _ =
    if verbose then Log.log_info "All data read, processing %i chars@." len
  in
  Lwt.return buf

let receive ~name ch () =
  Option.map ((* Messages. *) receive ~verbose:false) ch |> function
  | None ->
      Log.log_error "No connection@" ;
      Lwt.return_none
  | Some t -> (
      let%lwt t = t in
      match
        Yojson.Safe.from_string (Bytes.to_string t)
        |> Messages.message_of_yojson
      with
      | Ok msg ->
          Log.log_color
            Log.orange
            name
            "Received %s@."
            (* Messages.pp_message msg *)
            (* (Yojson.Safe.pretty_print ?std:None) *)
            (Bytes.to_string t) ;
          Lwt.return @@ Some msg
      | Error s ->
          Log.log_error
            "@[<v 2>Decoding error %s.@ string: %s@ yojson: %a@]@."
            s
            (Bytes.to_string t)
            (fun ppf t ->
              Yojson.Safe.pretty_print
                ?std:None
                ppf
                (Yojson.Safe.from_string (Bytes.to_string t)))
            t ;
          Lwt.return_none )

let trace_send_error = function
  | Some v -> v
  | None ->
      Log.log_error "No connection@" ;
      Lwt.return_unit

let rec bounce_loop name input output =
  let%lwt () = Lwt_unix.yield () in
  let%lwt _ =
    match%lwt receive ~name input () with
    | Some msg -> send output msg |> trace_send_error
    | None -> Lwt.return_unit
  in
  flush_all () ;
  bounce_loop name input output

let _ =
  let main =
    let%lwt _ = connect () in
    Lwt.async (fun () -> bounce_loop "C -> S" !in_conn !out_conn) ;
    bounce_loop "S -> C" !out_conn !in_conn
  in
  Lwt_main.run main
