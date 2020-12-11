open Error
open Letter
open Word
open Id

type letterpool = {
  current_period : period;
  next_period : period;
  letters : letter list;
}
[@@deriving yojson, show]

type wordpool = {
  current_period : period;
  next_period : period;
  words : (Crypto.hash * word) list;
}
[@@deriving yojson, show]

type diff_letterpool_arg = { since : period; letterpool : letterpool }
[@@deriving yojson, show]

type diff_wordpool_arg = { since : period; wordpool : wordpool }
[@@deriving yojson, show]

type message =
  | Register of author_id
  | Listen
  | Stop_listen
  | Next_turn of period
  | Letters_bag of char list
  | Full_letterpool of letterpool
  | Full_wordpool of wordpool
  (* | New_letter of letter
   * | New_word of word *)
  | Diff_letterpool of diff_letterpool_arg
  | Diff_wordpool of diff_wordpool_arg
  | Get_full_letterpool
  | Get_full_wordpool
  | Get_letterpool_since of period
  | Get_wordpool_since of period
  | Inject_letter of letter
  | Inject_word of word
  | Inject_raw_op of bytes
[@@deriving show]

type register_msg = { register : author_id } [@@deriving yojson]

type next_turn_msg = { next_turn : period } [@@deriving yojson]

type letters_bag_msg = { letters_bag : char list } [@@deriving yojson]

type full_letterpool_msg = { full_letterpool : letterpool } [@@deriving yojson]

type full_wordpool_msg = { full_wordpool : wordpool } [@@deriving yojson]

(* type new_letter_msg = { new_letter : letter}[@@deriving yojson] *)
(* type new_word_msg = { new_word : word}[@@deriving yojson] *)
type diff_letterpool_msg = { diff_letterpool : diff_letterpool_arg }
[@@deriving yojson]

type diff_wordpool_msg = { diff_wordpool : diff_wordpool_arg }
[@@deriving yojson]

type get_letterpool_since_msg = { get_letterpool_since : period }
[@@deriving yojson]

type get_wordpool_since_msg = { get_wordpool_since : period }
[@@deriving yojson]

type get_full_letterpool_msg = { get_full_letterpool : unit }
[@@deriving yojson]

type listen_msg = { listen : unit } [@@deriving yojson]

type stop_listen_msg = { stop_listen : unit } [@@deriving yojson]

type get_full_wordpool_msg = { get_full_wordpool : unit } [@@deriving yojson]

type inject_letter_msg = { inject_letter : letter } [@@deriving yojson]

type inject_word_msg = { inject_word : word } [@@deriving yojson]

type inject_raw_op_msg = { inject_raw_op : bytes } [@@deriving yojson]

let register_to_message { register = x } = Register x

let next_turn_to_message { next_turn = x } = Next_turn x

let letters_bag_to_message { letters_bag = x } = Letters_bag x

let full_letterpool_to_message { full_letterpool = x } = Full_letterpool x

let full_wordpool_to_message { full_wordpool = x } = Full_wordpool x

(* let new_letter_to_message { new_letter = x } =  New_letter x *)
(* let new_word_to_message { new_word = x } =  New_word x *)
let diff_letterpool_to_message { diff_letterpool = x } = Diff_letterpool x

let diff_wordpool_to_message { diff_wordpool = x } = Diff_wordpool x

let get_letterpool_since_to_message { get_letterpool_since = x } =
  Get_letterpool_since x

let get_wordpool_since_to_message { get_wordpool_since = x } =
  Get_wordpool_since x

let get_full_letterpool_to_message { get_full_letterpool = () } =
  Get_full_letterpool

let listen_to_message { listen = () } = Listen

let stop_listen_to_message { stop_listen = () } = Stop_listen

let get_full_wordpool_to_message { get_full_wordpool = () } = Get_full_wordpool

let inject_letter_to_message { inject_letter = x } = Inject_letter x

let inject_word_to_message { inject_word = x } = Inject_word x

let inject_raw_op_to_message { inject_raw_op = x } = Inject_raw_op x

let message_to_yojson msg =
  match msg with
  | Register x -> [%to_yojson: register_msg] { register = x }
  | Next_turn x -> [%to_yojson: next_turn_msg] { next_turn = x }
  | Letters_bag x -> [%to_yojson: letters_bag_msg] { letters_bag = x }
  | Full_letterpool x ->
      [%to_yojson: full_letterpool_msg] { full_letterpool = x }
  | Full_wordpool x -> [%to_yojson: full_wordpool_msg] { full_wordpool = x }
  (*   | New_letter x -> [%to_yojson: new_letter_msg] { new_letter = x} *)
  (*   | New_word x -> [%to_yojson: new_word_msg] { new_word = x} *)
  | Diff_letterpool x ->
      let x = { diff_letterpool = x } in
      [%to_yojson: diff_letterpool_msg] x
  | Diff_wordpool x ->
      let x = { diff_wordpool = x } in
      [%to_yojson: diff_wordpool_msg] x
  | Get_full_letterpool ->
      [%to_yojson: get_full_letterpool_msg] { get_full_letterpool = () }
  | Listen -> [%to_yojson: listen_msg] { listen = () }
  | Stop_listen -> [%to_yojson: stop_listen_msg] { stop_listen = () }
  | Get_full_wordpool ->
      [%to_yojson: get_full_wordpool_msg] { get_full_wordpool = () }
  | Get_letterpool_since x ->
      [%to_yojson: get_letterpool_since_msg] { get_letterpool_since = x }
  | Get_wordpool_since x ->
      [%to_yojson: get_wordpool_since_msg] { get_wordpool_since = x }
  | Inject_letter x -> [%to_yojson: inject_letter_msg] { inject_letter = x }
  | Inject_word x -> [%to_yojson: inject_word_msg] { inject_word = x }
  | Inject_raw_op x -> [%to_yojson: inject_raw_op_msg] { inject_raw_op = x }

let message_of_yojson msg =
  (msg, Error "")
  ||? ([%of_yojson: register_msg] >|> register_to_message)
  ||? ([%of_yojson: next_turn_msg] >|> next_turn_to_message)
  ||? ([%of_yojson: letters_bag_msg] >|> letters_bag_to_message)
  ||? ([%of_yojson: full_letterpool_msg] >|> full_letterpool_to_message)
  ||? ([%of_yojson: full_wordpool_msg] >|> full_wordpool_to_message)
  (*   ||? ([%of_yojson: new_letter_msg] >|> new_letter_to_message) *)
  (*   ||? ([%of_yojson: new_word_msg] >|> new_word_to_message) *)
  ||? ([%of_yojson: diff_letterpool_msg] >|> diff_letterpool_to_message)
  ||? ([%of_yojson: diff_wordpool_msg] >|> diff_wordpool_to_message)
  ||? ([%of_yojson: get_full_letterpool_msg] >|> get_full_letterpool_to_message)
  ||? ([%of_yojson: listen_msg] >|> listen_to_message)
  ||? ([%of_yojson: stop_listen_msg] >|> stop_listen_to_message)
  ||? ([%of_yojson: get_full_wordpool_msg] >|> get_full_wordpool_to_message)
  ||? ( [%of_yojson: get_letterpool_since_msg]
      >|> get_letterpool_since_to_message )
  ||? ([%of_yojson: get_wordpool_since_msg] >|> get_wordpool_since_to_message)
  ||? ([%of_yojson: inject_letter_msg] >|> inject_letter_to_message)
  ||? ([%of_yojson: inject_word_msg] >|> inject_word_to_message)
  ||? ([%of_yojson: inject_raw_op_msg] >|> inject_raw_op_to_message)
  |> snd

let receive ?(verbose = true) in_ch : (message, string) result =
  let () = if verbose then Log.log_info "receiving Message.@." in
  let () = if verbose then Log.log_info "reading size.@." in
  let len = Utils.read_int in_ch in
  let _ = if verbose then Log.log_info "Reading %i chars@." len in
  let buf = Bytes.create len in
  let _ = Utils.read_channel in_ch buf 0 len in
  let _ =
    if verbose then Log.log_info "All data read, processing %i chars@." len
  in
  Yojson.Safe.from_string (Bytes.to_string buf) |> message_of_yojson

let receive_async ?(verbose = true) in_ch : (message, string) result Lwt.t =
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
  Yojson.Safe.from_string (Bytes.to_string buf)
  |> message_of_yojson |> Lwt.return

let send ?(verbose = true) msg out_ch =
  let () = if verbose then Log.log_info "Sending message %a@." pp_message msg in
  let str =
    message_to_yojson msg |> Yojson.Safe.to_string |> Bytes.unsafe_of_string
  in
  let len = Bytes.length str in
  let () = Utils.write_int out_ch len in
  Utils.write_channel out_ch str 0 len

let send_async ?(verbose = true) msg out_ch =
  let () = if verbose then Log.log_info "Sending message %a@." pp_message msg in
  let str =
    message_to_yojson msg |> Yojson.Safe.to_string |> Bytes.unsafe_of_string
  in
  let len = Bytes.length str in
  let%lwt () = Utils.write_int_a out_ch len in
  Utils.write_channel_a out_ch str 0 len

let print_type_message () : unit = ()

(* let m : message =  _ in
 * [ Register
 *  | Listen -> (??)
 *  | Stop_listen -> (??)
 *  | Next_turn _ -> (??)
 *  | Letters_bag _ -> (??)
 *  | Full_letterpool _ -> (??)
 *  | Full_wordpool _ -> (??)
 *  | Diff_letterpool _ -> (??)
 *  | Diff_wordpool _ -> (??)
 *  | Get_full_letterpool -> (??)
 *  | Get_full_wordpool -> (??)
 *  | Get_letterpool_since _ -> (??)
 *  | Get_wordpool_since _ -> (??)
 *  | Inject_letter _ -> (??)
 *  | Inject_word _ -> (??)
 *  | Inject_raw_op _ -> (??)) *)
