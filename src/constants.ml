open Crypto
open Word

let unerror v = match v with Ok v -> v | _ -> assert false

let god_sk =
  unerror
  @@ sk_of_yojson
       (`String
         "f644288a51b79cf539efc79d3860d4daee505d7256dac2fbfc54d0212a6281e4")

let god_pk =
  unerror
  @@ pk_of_yojson
       (`String
         "c45d9c1bb3a0ff41f4932a64a010e2e60ea0e0b8fc253a074a86e3e3f72bb908")

let sign_word ~word ~head (sk, pk) =
  let head_bs = hash_to_bigstring head
  and politician_bs = pk_to_bigstring pk
  and word_bs = List.map Letter.to_bigstring word in
  let msg =
    hash_to_bigstring @@ hash_list @@ word_bs @ [head_bs; politician_bs]
  in
  sign ~sk ~msg

let word = []

let genesis_word =
  let genesis = Crypto.hash Bigstring.empty in
  {
    word;
    level = 0;
    head = genesis;
    politician = god_pk;
    signature = sign_word ~word ~head:genesis (god_sk, god_pk);
  }

let genesis = Word.hash genesis_word
