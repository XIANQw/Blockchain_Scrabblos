open Hacl
open Error
open Utils

(** Hash  *)
type hash = Bigstring.t

let pp_hash = pp_bs

let show_hash = show_bs

let hash_to_yojson = bigstring_to_yojson

let hash_of_yojson = bigstring_of_yojson

let hash_to_bigstring s = s

let hash_of_bigstring s =
  assert (Bigstring.length s = Hash.SHA256.bytes) ;
  s

let hash bigs = Hacl.Hash.SHA256.digest bigs

let hash_list bigs =
  let state = Hacl.Hash.SHA256.init () in
  List.iter (Hacl.Hash.SHA256.update state) bigs ;
  Hacl.Hash.SHA256.finish state

(** Public/private keys  *)

type pk = public Sign.key

let pk_to_yojson pk =
  let pk_bytes = Hacl.Sign.unsafe_to_bytes pk in
  bigstring_to_yojson pk_bytes

let pk_of_yojson pkj = bigstring_of_yojson pkj >>? Hacl.Sign.unsafe_pk_of_bytes

let pk_to_bigstring pk = Hacl.Sign.unsafe_to_bytes pk

let pk_of_bigstring pkbs = Hacl.Sign.unsafe_pk_of_bytes pkbs

let pp_pk ppf pk = pk_to_bigstring pk |> pp_bs ppf

let show_pk pk = pk_to_bigstring pk |> show_bs

type sk = secret Sign.key

let sk_to_yojson sk =
  let sk_bytes = Hacl.Sign.unsafe_to_bytes sk in
  bigstring_to_yojson sk_bytes

let sk_of_yojson skj = bigstring_of_yojson skj >>? Hacl.Sign.unsafe_sk_of_bytes

let sk_to_bigstring sk = Hacl.Sign.unsafe_to_bytes sk

let sk_of_bigstring skbs = Hacl.Sign.unsafe_sk_of_bytes skbs

let pp_sk ppf sk = sk_to_bigstring sk |> pp_bs ppf

let show_sk sk = sk_to_bigstring sk |> show_bs

let genkeys () = Sign.keypair ()

(** Signature  *)
type signature = Bigstring.t

let signature_to_yojson = bigstring_to_yojson

let signature_of_yojson = bigstring_of_yojson

let pp_signature = pp_bs

let show_signature = show_bs

let signature_to_bigstring s = s

let signature_of_bigstring s = s

let sign ~sk ~msg =
  let signature = Bigstring.create Sign.bytes in
  Sign.sign ~sk ~msg ~signature ;
  signature

let verify ~pk ~msg ~signature = Sign.verify ~pk ~msg ~signature

(* let encode_pk pk =
 *   let buf = Bigstring.create Sign.pkbytes in
 *   Sign.blit_to_bytes pk buf;
 *   buf
 *
 * let encode_sk sk =
 *   let buf = Bigstring.create Sign.skbytes in
 *   Sign.blit_to_bytes sk buf;
 *   buf *)

type pkh = Bigstring.t

let pkh_to_yojson = bigstring_to_yojson

let pkh_of_yojson = bigstring_of_yojson

let pkh_to_bigstring pkh = pkh

let pkh_of_bigstring pkh = pkh

let pp_pkh = pp_hash

let show_pkh = show_hash
