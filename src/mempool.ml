open Id
open Letter
open Word
open Messages

type internal_letterpool = {
  mutable current_period : period;
  mutable next_period : period;
  mutable letters : (int * letter) list;
}

(* [@@deriving yojson,show] *)

type internal_wordpool = {
  mutable current_period : period;
  mutable next_period : period;
  mutable words : (int * (Crypto.hash * word)) list;
}

(* [@@deriving yojson,show] *)

type mempool = {
  turn_by_turn : bool;
  nb_rounds : int;
  check_sigs : bool;
  timeout : float option;
  mutable registered : author_id list;
  letterpoolos : internal_letterpool;
  wordpoolos : internal_wordpool;
  mutable current_period : int;
  mutable current_period_start : float;
}

let first_period = 1

let first_next_period = 2

(* let current_period {current_period; _ } =
 *   current_period *)
(* let period_to_int p = p *)

(** {1} Letters pool *)
let add_letter pool letter =
  let injected =
    if pool.check_sigs && not (Letter.check_signature letter) then (
      Log.log_warn "Incorrect signature for letter %a" pp_letter letter ;
      false )
    else if
      pool.turn_by_turn && letter.level <> pool.letterpoolos.current_period
    then (
      Log.log_warn
        "Out of timeframe letter %a (current: %a, next: %a)"
        pp_letter
        letter
        pp_period
        pool.letterpoolos.current_period
        pp_period
        pool.letterpoolos.next_period ;
      false )
    else true
  in
  ( if injected then
    let key = pool.current_period in
    pool.letterpoolos.letters <- (key, letter) :: pool.letterpoolos.letters ) ;
  injected

(* let remove_letter pool letter =
 *   pool.letterpoolos.letters <-
 *     (List.filter (fun (_,l) -> l != letter) pool.letterpoolos.letters) *)

(* let find_by_author (pool:mempool) ?period author  =
 *   List.filter
 *     (fun (p,(l:letter)) -> Option.value ~default:(fun _ -> true) period p
 *                            && l.author = author)
 *     pool.letterpoolos.letters *)

let init_letterpool =
  {
    current_period = first_period;
    next_period = first_next_period;
    letters = [];
  }

let letterpool_since { letterpoolos; _ } since : Messages.letterpool =
  let { current_period; next_period; letters } = letterpoolos in
  {
    current_period;
    next_period;
    letters = List.map snd (List.filter (fun (p, _) -> p >= since) letters);
  }

let letterpool { letterpoolos; _ } : Messages.letterpool =
  let { current_period; next_period; letters } = letterpoolos in
  { current_period; next_period; letters = List.map snd letters }

(** {1} Words pool *)
let add_word pool word =
  if pool.check_sigs && not (Word.check_signature word) then (
    Log.log_warn "Incorrect signature for letter %a" pp_word word ;
    false )
  else (
    pool.wordpoolos.words <-
      (pool.current_period, (Word.hash word, word)) :: pool.wordpoolos.words ;
    true )

let init_wordpool =
  { current_period = first_period; next_period = first_next_period; words = [] }

let wordpool_since { wordpoolos; _ } since : Messages.wordpool =
  let { current_period; next_period; words } = wordpoolos in
  {
    current_period;
    next_period;
    words = List.map snd @@ List.filter (fun (p, _) -> p >= since) words;
  }

let wordpool { wordpoolos; _ } : Messages.wordpool =
  let { current_period; next_period; words } = wordpoolos in
  { current_period; next_period; words = List.map snd words }

let current_words { wordpoolos; _ } : word list =
  let { current_period; words; _ } = wordpoolos in
  List.filter_map
    (fun (p, (_, w)) -> if p = current_period then Some w else None)
    words

(** {1} Mempool  *)

let create ~check_sigs ~turn_by_turn ?(nb_rounds = 100) ?timeout () =
  let period = first_period and current_period_start = Unix.time () in
  {
    turn_by_turn;
    nb_rounds;
    check_sigs;
    timeout;
    registered = [];
    letterpoolos = init_letterpool;
    wordpoolos = init_wordpool;
    current_period = period;
    current_period_start;
  }

let turn_by_turn { turn_by_turn; _ } = turn_by_turn

let gen_letters mempool _id =
  let code_z = 122 in
  let code_a = 97 in
  let rec aux round res =
    if round > 0 then
      aux
        (round - 1)
        ((Char.chr @@ (Random.int (code_z - code_a) + code_a)) :: res)
    else res
  in
  aux mempool.nb_rounds []

let register pool id =
  pool.registered <- id :: Utils.remove_first pool.registered id

let next_period pool =
  if not pool.turn_by_turn then Some 0
  else
    let injecters =
      List.filter
        (fun (p, _) -> p = pool.current_period)
        pool.letterpoolos.letters
      |> List.map (fun (_, { author; _ }) -> author)
    in
    let timeout =
      Utils.unopt_map
        (fun tio -> Unix.time () > pool.current_period_start +. tio)
        ~default:false
        pool.timeout
    in
    let _non_empty_word_pool = 0 <> List.length @@ current_words pool in
    let got_all = Utils.included pool.registered injecters in
    if got_all then Log.log_info "Got all letters" ;
    if timeout then Log.log_info "Timeout" ;
    if (* _non_empty_word_pool &&  *) got_all || timeout then (
      let current_period = pool.current_period + 1 in
      let next_period = current_period + 1 in
      Log.log_info_continue ": next turn (%d) !@." current_period ;
      pool.current_period <- current_period ;
      pool.wordpoolos.current_period <- current_period ;
      pool.wordpoolos.next_period <- next_period ;
      pool.letterpoolos.current_period <- current_period ;
      pool.letterpoolos.next_period <- next_period ;
      pool.current_period_start <- Unix.time () ;
      Some current_period )
    else (
      Log.log_info
        "still missing %a@."
        (Format.pp_print_list ~pp_sep:Format.pp_print_space Id.pp_politician_id)
        (Utils.diff pool.registered injecters) ;
        None )
        
let is_onlyone_inject (pool:mempool) (l : letter) =
  let letters = pool.letterpoolos.letters in
  let rec check list = 
    match list with
    | (level, lt) :: tl -> 
      if level = l.level && lt.author = l.author then false 
      else check tl
    | [] -> true
  in check letters
        
let inject_letter (pool : mempool) (l : letter) =
  if is_onlyone_inject pool l then (
    Log.log_info "[mempool] injecting letter@." ;
    let injected = add_letter pool l in
    let period_change = next_period pool in
    (period_change, injected)
  ) else (None, false)

let inject_word (pool : mempool) (w : word) =
  let period_change = next_period pool in
  (period_change, add_word pool w)
