open Messages

let json_pp ppf msg_yo =
  Yojson.Safe.pretty_print ~std:false ppf (message_to_yojson msg_yo)

let test () =
  Lwt_main.run
    (let (pk, _sk) = Crypto.genkeys () in

     let _print_encodings () =
       message_to_yojson Get_full_letterpool
       |> Format.printf "json: '%a@'." (Yojson.Safe.pretty_print ~std:false) ;

       message_to_yojson Get_full_letterpool
       |> Format.printf "yojson '%a'@." Yojson.Safe.pp ;

       message_to_yojson (Register pk)
       |> Format.printf "json: '%a'@." (Yojson.Safe.pretty_print ~std:false)
     in
     let _test_decoding msg =
       let _ = Log.log_info "[Testing] %a@." Messages.pp_message msg in
       let%lwt f =
         Lwt_unix.openfile
           "test.test"
           [Lwt_unix.O_WRONLY; Lwt_unix.O_TRUNC; Lwt_unix.O_CREAT]
           0o666
       in
       (* let%lwt _ = Log.log_info "test opened@." ; Lwt.return_unit in *)
       let%lwt () = Messages.send msg f in
       let%lwt () = Lwt_unix.close f in
       (* let _ = Log.log_info "re-open test@." in *)
       let%lwt f = Lwt_unix.openfile "test.test" [Lwt_unix.O_RDONLY] 0 in
       let%lwt maybe_message = Messages.receive f in
       let%lwt () = Lwt_unix.close f in
       match maybe_message with
       | Ok message ->
           Lwt.return
           @@
           if message = msg then
             Log.log_success "Decoding %a succesful@." Messages.pp_message msg
           else
             Log.log_error
               "@[<v 2>Decoding wrong value:@ @[expected:%a @]@ @[obtained:%a \
                @]@]@."
               Messages.pp_message
               msg
               Messages.pp_message
               message
       | Error b -> Lwt.return @@ Log.log_error "Error %s@." b
     in
     (* let () =
      *   _print_encodings  ()
      * in *)
     (* let%lwt () =
      *   _test_decoding  (Register pk)
      * in
      * let%lwt () = _test_decoding  (Listen)
      * in
      * let%lwt () = _test_decoding  (Stop_listen)
      * in
      * let%lwt () = _test_decoding  (Get_full_letterpool)
      * in
      * let%lwt () = _test_decoding  (Get_full_wordpool)
      * in
      * let%lwt () = _test_decoding  (Get_letterpool_since 1)
      * in
      * let%lwt () = _test_decoding  (Get_wordpool_since 1)
      * in
      * let%lwt () = _test_decoding  (Letters_bag ['a';Char.chr @@ Random.int (255)])
      * in
      * let%lwt () = _test_decoding  (Full_letterpool {period=0;letters=[]})
      * in
      * let%lwt () = _test_decoding  (Diff_letterpool {since=0;letterpool={period=0;letters=[]}})
      * in
      * let%lwt () = _test_decoding  (Full_wordpool {period=0;words=[]})
      * in
      * let%lwt () = _test_decoding  (Diff_wordpool {since=0;wordpool={period=0;words=[]}})
      * in *)
     Lwt.return_unit
     (* test_decoding  (Get_full_mempool) *))
