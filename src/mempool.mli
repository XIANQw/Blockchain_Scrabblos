open Messages
open Letter
open Word
open Id

type mempool

(** The mempool is responsible for:
    - storing received words and letters.
    - deciding to go to next turn
  *)
val create :
  check_sigs:bool ->
  turn_by_turn:bool ->
  ?nb_rounds:int ->
  ?timeout:float ->
  unit ->
  mempool

(** is the server in turn-by-turn mode ?  *)
val turn_by_turn : mempool -> bool

(** Generating the bag of letters for an author   *)
val gen_letters : mempool -> author_id -> char list

val register : mempool -> politician_id -> unit

val letterpool : mempool -> letterpool

val letterpool_since : mempool -> period -> letterpool

val wordpool_since : mempool -> period -> wordpool

val wordpool : mempool -> wordpool

(** Inject a letter in the mempool.
    The letter is only injected if the timeframe is correct (in
    turn-by-turn mode with timeout).
    It returns [(new_periode_option, injected)]
    [new_period_option] is
    - [Some period] if the injection triggered a period number
    change.
    - [Some 0] in non turn-by-turn mode)
    - [None] if the period didn't change.
    [Injected] is false if the injection fails, true otherwise.
  *)
val inject_letter : mempool -> letter -> period option * bool

(** Inject a word in the mempool.
    The word is always injected.
    It returns [(new_periode_option, injected)]
    [new_period_option] is
    - [Some period] if a timeout triggered a period number
    change.
    - [Some 0] in non turn-by-turn mode)
    - [None] if the period didn't change.
    [Injected] is always true for now.
  *)
val inject_word : mempool -> word -> period option * bool
