(* Hash *)
type hash [@@deriving yojson, show]

(** cast a hash into the bigstring type   *)
val hash_to_bigstring : hash -> Bigstring.t

(** Cast a bigstring into a hash. Unsafe.
    Will fail if the bigstring has not the size of a hash.
    current implementation has size [Hacl.Hash.256.bytes]
 *)
val hash_of_bigstring : Bigstring.t -> hash

val hash : Bigstring.t -> hash

val hash_list : Bigstring.t list -> hash

(** Public/Secret keys *)
type pk [@@deriving yojson, show]

val pk_to_bigstring : pk -> Bigstring.t

val pk_of_bigstring : Bigstring.t -> pk

type sk [@@deriving yojson, show]

val sk_to_bigstring : sk -> Bigstring.t

val sk_of_bigstring : Bigstring.t -> sk

val genkeys : unit -> pk * sk

(** Signatures  *)

type signature [@@deriving yojson, show]

val signature_to_bigstring : signature -> Bigstring.t

val signature_of_bigstring : Bigstring.t -> signature

val sign : sk:sk -> msg:Bigstring.t -> signature

val verify : pk:pk -> msg:Bigstring.t -> signature:signature -> bool

(** Public key hash  *)
type pkh [@@deriving yojson, show]

val pkh_to_bigstring : pkh -> Bigstring.t

val pkh_of_bigstring : Bigstring.t -> pkh
