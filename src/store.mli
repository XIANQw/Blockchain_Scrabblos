open Word
open Letter

type letter_store

type word_store

val init_words : ?check_sigs:bool -> unit -> word_store

val init_letters : ?check_sigs:bool -> unit -> letter_store

val add_word : word_store -> word -> unit

val get_word : word_store -> Crypto.hash -> word

val get_word_opt : word_store -> Crypto.hash -> word option

val add_words : word_store -> (Crypto.hash * word) list -> unit

val iter_words : (Crypto.hash -> word -> unit) -> word_store -> unit

val add_letter : letter_store -> letter -> unit

val add_letters : letter_store -> letter list -> unit

val get_letters : letter_store -> Crypto.hash -> letter list

val length : word_store -> int
