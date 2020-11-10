(* open Error *)

(**  printable designation of a connection *)
type point = { addr : Unix.inet_addr; port : int }

(** conenction  *)
type conn = { point : point; fd : Lwt_unix.file_descr }

(** pool of connections  *)
type pool = {
  (* pool of all active connections  *)
  poolos : (point, conn) Pool.t;
  (* pool of connections which asked to continously receive data  *)
  broadcastpoolos : (point, conn) Pool.t;
}

(* worker linked to a connection *)
and worker_state = {
  (* pool of connections *)
  netpoolos : pool;
  (*pool of letters and words  *)
  mempoolos : Mempool.mempool;
  (* remote point *)
  point : point;
  (* communication socket *)
  fd : Lwt_unix.file_descr;
  (* callback to handle incoming messages *)
  callback : worker_state -> (Messages.message, string) result -> unit Lwt.t;
}

(** Worker that handle a connection  *)
let rec worker_loop (st : worker_state) =
  let%lwt () = Lwt_unix.yield () in
  let%lwt message =
    let () = Log.log_info "Waiting for messages.@." in
    Messages.receive_async ~verbose:true st.fd
  in
  let%lwt () = st.callback st message in
  let () = Log.log_info "Message processed.@." in
  worker_loop st

let pp_may_message ppf may_message =
  match may_message with
  | Ok msg -> Format.fprintf ppf "message :%a" Messages.pp_message msg
  | Error s -> Format.fprintf ppf "Error %s" s

(** Create the shared pool of connections  *)
let create () =
  let broadcastpoolos = Pool.create () in
  {
    broadcastpoolos;
    poolos =
      Pool.create
        ~remove_callback:(fun (point, _) _ ->
          Pool.remove broadcastpoolos point ;
          Lwt.return_unit)
        ();
  }

let pp_point ppf (addr, port) =
  Format.fprintf ppf "%s:%i" (Unix.string_of_inet_addr addr) port

(** Add a connection to the netpoolos pool and starts its dedicated worker  *)
let accept (netpoolos : pool) mempoolos ~callback fd (addr, port) =
  let point = { addr; port } in
  let%lwt () = Pool.add netpoolos.poolos point { point; fd } in
  Lwt.catch
    (fun () ->
      Log.log_info
        "STARTING: Answering loop started for %a@."
        pp_point
        (addr, port) ;
      worker_loop { netpoolos; mempoolos; point; fd; callback })
    (fun _exn ->
      let _ =
        Log.log_info "STOPPING: answerer for %a@." pp_point (addr, port)
      in
      Pool.remove netpoolos.poolos { addr; port } ;
      Lwt.return_unit)
