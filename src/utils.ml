open Error

(* utilities  *)
let hex_of_hexstring str : Hex.t = `Hex str

let bigstring_to_yojson (bs : Bigstring.t) : Yojson.Safe.t =
  [%to_yojson: string] @@ Format.asprintf "%a" Hex.pp @@ Hex.of_bigstring bs

let bigstring_of_yojson (bsj : Yojson.Safe.t) =
  [%of_yojson: string] bsj >>? hex_of_hexstring >>? Hex.to_bigstring

let pp_bs ppf bs = Hex.of_bigstring bs |> Hex.pp ppf

let show_bs bs = Format.asprintf "%a" pp_bs bs

let unopt_map f ~default opt = Option.value ~default (Option.map f opt)

let is_nil l = l = []

(* let rec remove_first l d =
 *   match l with
 *     [] -> []
 *   | h::t when h=d -> t
 *   | h::t -> h::(remove_first t d) *)

let remove_first l d =
  let rec aux l d res =
    match l with
    | [] -> List.rev res
    | h :: t when h = d -> List.rev_append res t
    | h :: t -> aux t d (h :: res)
  in
  aux l d []

let bigstring_of_char c = Bigstring.of_string (Format.sprintf "%c" c)

let bytes_of_int i =
  let ibuf = Bytes.create 8 in
  Bytes.set_int64_be ibuf 0 (Int64.of_int i) ;
  ibuf

let bytes_to_int ibuf = Bytes.get_int64_be ibuf 0 |> Int64.to_int

let bigstring_of_int i =
  let bs = Bigstring.create 8 in
  Bigstring.fill bs '\000' ;
  let ibuf = bytes_of_int i in
  Bigstring.blit_of_bytes ibuf 0 bs 0 8 ;
  bs

let bigstring_to_int bs =
  let ibuf = Bytes.create 8 in
  Bigstring.blit_to_bytes bs 0 ibuf 0 8 ;
  bytes_to_int ibuf

exception Reading_failure

let read_channel_a ch buf offs len =
  let%lwt read_len = Lwt_unix.read ch buf offs len in
  if read_len < len then
    let _ =
      Log.log_error
        "Reading failed:  read %i instead of %i\n\
        \                           chars : @ %a@."
        read_len
        len
        Hex.pp
        (Hex.of_bytes buf)
    in
    raise Reading_failure
  else Lwt.return buf

let read_channel ch buf offs len =
  let read_len = Unix.read ch buf offs len in
  if read_len < len then
    let _ =
      Log.log_error
        "Reading failed:  read %i instead of %i\n\
        \                           chars : @ %a@."
        read_len
        len
        Hex.pp
        (Hex.of_bytes buf)
    in
    raise Reading_failure
  else buf

let size_of_int = 8

let read_int_a in_ch =
  let ibuf = Bytes.create 8 in
  let%lwt rcv_size = read_channel_a in_ch ibuf 0 size_of_int in
  Lwt.return @@ bytes_to_int rcv_size

let read_int in_ch =
  let ibuf = Bytes.create 8 in
  let rcv_size = read_channel in_ch ibuf 0 size_of_int in
  bytes_to_int rcv_size

exception Writing_failure

let write_channel_a ch buf ofs length =
  let%lwt written = Lwt_unix.write ch buf ofs length in
  if written < length then raise Writing_failure else Lwt.return_unit

let write_channel ch buf ofs length =
  let written = Unix.write ch buf ofs length in
  if written < length then raise Writing_failure else ()

let write_int_a out_ch i =
  let ibuf = bytes_of_int i in
  write_channel_a out_ch ibuf 0 size_of_int

let write_int out_ch i =
  let ibuf = bytes_of_int i in
  write_channel out_ch ibuf 0 size_of_int

let included small large =
  List.fold_left (fun i s -> if i then List.mem s large else i) true small

let diff s1 s2 = List.fold_left (fun set v -> remove_first set v) s1 s2

(* tests *)
let test_remove_first () =
  let l = [1; 2; 3; 4; 5; 6] in
  assert (remove_first l 1 = [2; 3; 4; 5; 6]) ;
  assert (remove_first l 2 = [1; 3; 4; 5; 6]) ;
  assert (remove_first l 3 = [1; 2; 4; 5; 6]) ;
  assert (remove_first l 6 = [1; 2; 3; 4; 5]) ;
  assert (remove_first l 0 = [1; 2; 3; 4; 5; 6])

let test_diff () =
  let s1 = [1; 2; 3; 4; 5; 6] in
  let s2 = [1; 2; 3; 6] in
  let s3 = [4; 5] in
  assert (diff s1 s2 = [4; 5]) ;
  assert (diff s1 s3 = [1; 2; 3; 6])

let test_included () =
  let l = [1; 2; 3; 4; 5; 6; 4; 5; 6] in
  assert (included [1; 2] l) ;
  assert (included [2; 3; 4] l) ;
  assert (included [2; 3; 4] l) ;
  assert (included [2; 3; 4; 4] l) ;
  assert (included [2] l) ;
  assert (not @@ included [0; 2; 3; 4; 4; 9] l) ;
  assert (not @@ included [0; 2; 3; 4; 4; 0; 9] l) ;
  assert (not @@ included [0; 2; 3; 4] l) ;
  assert (not @@ included [2; 3; 4; 0] l) ;
  assert (not @@ included [0] l)
