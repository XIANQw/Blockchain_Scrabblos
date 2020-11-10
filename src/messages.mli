open Id
open Letter
open Word

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
  (*   | New_letter of letter *)
  (*   | New_word of word *)
  | Diff_letterpool of diff_letterpool_arg
  | Diff_wordpool of diff_wordpool_arg
  | Get_full_letterpool
  | Get_full_wordpool
  | Get_letterpool_since of period
  | Get_wordpool_since of period
  | Inject_letter of letter
  | Inject_word of word
  | Inject_raw_op of bytes
[@@deriving yojson, show]

val receive : ?verbose:bool -> Unix.file_descr -> (message, string) result

val send : ?verbose:bool -> message -> Unix.file_descr -> unit

val receive_async :
  ?verbose:bool -> Lwt_unix.file_descr -> (message, string) result Lwt.t

val send_async : ?verbose:bool -> message -> Lwt_unix.file_descr -> unit Lwt.t

val print_type_message : unit -> unit
