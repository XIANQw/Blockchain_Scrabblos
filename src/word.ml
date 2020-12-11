open Crypto
open Letter
open Id

type word = {
  word : letter list;
  level : int;
  head : hash;
  politician : politician_id;
  signature : signature;
}
[@@deriving yojson, show]

type t = word [@@deriving yojson, show]

let pre_bigstring ~word ~level ~head ~politician =
  let open Crypto in
  let buf =
    Bigstring.concat
      ""
      ( List.map letter_to_bigstring word
      @ [
          hash_to_bigstring head;
          Utils.bigstring_of_int level;
          pk_to_bigstring politician;
        ] )
  in
  buf

let pre_to_bigstring { word; level; head; politician; signature = _ } =
  pre_bigstring ~word ~level ~head ~politician

let to_bigstring ({ signature; _ } as w) =
  let open Crypto in
  let buf =
    Bigstring.concat "" [pre_to_bigstring w; signature_to_bigstring signature]
  in
  buf

let word_to_bigstring = to_bigstring

let check_signature w =
  Crypto.verify
    ~pk:w.politician
    ~msg:(pre_to_bigstring w)
    ~signature:w.signature

let make ~(word : letter list) ~(head : hash) ~(level : int) ~(pk : Crypto.pk)
    ~(sk : Crypto.sk) =
  let politician = pk in
  let msg = pre_bigstring ~word ~level ~head ~politician in
  let signature = sign ~sk ~msg in
  {word; level; head; politician; signature}

let hash word = Crypto.hash (to_bigstring word)
