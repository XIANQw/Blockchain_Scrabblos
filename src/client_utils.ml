let conn : Unix.file_descr option ref = ref None

let connect ?(addr = Unix.inet_addr_of_string "::1") ?(port = 12345) () =
  let main_socket = Unix.(socket PF_INET6 SOCK_STREAM 0) in
  let remote_addr = Unix.ADDR_INET (addr, port) in
  let () = Unix.connect main_socket remote_addr in
  conn := Some main_socket

let send msg = Option.map (Messages.send msg) !conn

let receive ?check () =
  Option.map Messages.receive !conn |> function
  | None -> failwith "No connection@"
  | Some t -> (
      match t with
      | Ok msg ->
          Log.log_info "Received %a@." Messages.pp_message msg ;
          Utils.unopt_map ~default:() (fun f -> f msg) check ;
          msg
      | Error s -> failwith (Format.sprintf "Reception error %s@." s) )

let no_some v = match v with None -> failwith "No connection" | Some v -> v

let send_some v =
  Log.log_info "Sending %a@." Messages.pp_message v ;
  no_some @@ send v

let ignore_msgs = function Messages.Next_turn _ -> true | _ -> false

exception Test_failure of (string * string)

let rec checker ~hard ?(ignore_msgs = fun _ -> false) test sent received =
  if ignore_msgs received then
    ignore (receive ~check:(checker ~hard ~ignore_msgs test sent) ())
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

let check_inject_letter ~hard =
  checker ~hard ~ignore_msgs (function
      | (Inject_letter l, Diff_letterpool { letterpool; _ })
        when List.mem l letterpool.letters ->
          true
      | _ -> false)

(* Read dictionnary  file and returns a list of all the word it contains *)
let list_of_dict (fname : string) =
  let ic = open_in fname in
  let lines = ref [] in
  try
    while true do
      lines := input_line ic :: !lines
    done ;
    !lines
  with End_of_file ->
    close_in ic ;
    !lines
