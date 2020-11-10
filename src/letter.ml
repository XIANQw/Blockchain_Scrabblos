open Crypto
open Utils
open Id

type period = int [@@deriving yojson, show]

type letter = {
  letter : char;
  level : period;
  head : hash;
  author : author_id;
  signature : signature;
}
[@@deriving yojson, show]

type t = letter [@@deriving yojson, show]

let sign_letter ~sk ~c ~head ~level ~author =
  sign
    ~sk
    ~msg:
      ( hash_to_bigstring
      @@ hash_list
           [
             bigstring_of_char c;
             bigstring_of_int level;
             hash_to_bigstring head;
             pk_to_bigstring author;
           ] )

let sign_letter_alt ~sk ~c ~head ~level ~author =
  let head = hash_to_bigstring head
  and author = pk_to_bigstring author
  and level = bigstring_of_int level in
  let head_length = Bigstring.length head in
  let author_length = Bigstring.length author in
  let level_length = Bigstring.length level in
  let msg = Bigstring.create (1 + level_length + head_length + author_length) in
  let c = bigstring_of_char c in
  Bigstring.blit c 0 msg 0 1 ;
  Bigstring.blit level 0 msg 1 level_length ;
  Bigstring.blit head 0 msg (1 + level_length) head_length ;
  Bigstring.blit author 0 msg (1 + level_length + head_length) author_length ;
  sign ~sk ~msg

let make_letter_on_block sk author level block c : letter =
  let head = hash block in
  let signature = sign_letter ~sk ~c ~head ~level ~author in
  let signature_alt = sign_letter_alt ~sk ~c ~head ~level ~author in
  assert (signature_alt = signature) ;
  { letter = c; level; head; author; signature }

let make_letter_on_hash sk author level head_hash c : letter =
  let head = head_hash in
  let signature = sign_letter ~sk ~c ~head ~level ~author in
  { letter = c; level; head; author; signature }

let pre_bigstring ~letter ~level ~head ~author =
  let buf =
    Bigstring.concat
      ""
      [
        bigstring_of_char letter;
        bigstring_of_int level;
        hash_to_bigstring head;
        pk_to_bigstring author;
      ]
  in
  buf

let pre_to_bigstring { letter; level; head; author; _ } =
  pre_bigstring ~letter ~level ~head ~author

let to_bigstring ({ signature; _ } as w) =
  let buf =
    Bigstring.concat "" [pre_to_bigstring w; signature_to_bigstring signature]
  in
  buf

let check_signature l =
  Crypto.verify ~pk:l.author ~msg:(pre_to_bigstring l) ~signature:l.signature

let make ~letter ~head ~level ~pk ~sk =
  let author = pk in
  let msg = pre_bigstring ~letter ~head ~level ~author in
  let signature = sign ~sk ~msg in
  { letter; head; level; author; signature }

let letter_to_bigstring = to_bigstring
