type ('key, 'data) t = {
  mutable data : ('key * 'data) list;
  add_callback : 'key * 'data -> ('key, 'data) t -> unit Lwt.t;
  remove_callback : 'key * 'data -> ('key, 'data) t -> unit Lwt.t;
}

let add pool key data =
  pool.data <- (key, data) :: pool.data ;
  pool.add_callback (key, data) pool

let remove pool key =
  let data = List.assoc_opt key pool.data in
  pool.data <- List.remove_assoc key pool.data ;
  Option.iter (fun data -> ignore (pool.remove_callback (key, data) pool)) data

let map pool f = List.map f pool.data

let iter pool f = List.iter f pool.data

let iter_p pool f = Lwt_list.iter_p f pool.data

let iter_s pool f = Lwt_list.iter_s f pool.data

let create ?(add_callback = fun _ _ -> Lwt.return_unit)
    ?(remove_callback = fun _ _ -> Lwt.return_unit) () =
  { data = []; add_callback; remove_callback }
