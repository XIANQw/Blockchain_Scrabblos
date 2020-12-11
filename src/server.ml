(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2019 Nomadic Labs                                           *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

(** the server handle a pool of connections and a mempool  *)
type t = {
  socket : Lwt_unix.file_descr;
  netpoolos : Netpool.pool;
  mempoolos : Mempool.mempool;
}

(** for each new connection, the server accept it in its netpool.
    The communication protocole is defined by the Answerer.
    [see Netpool.accept, Answerer.answer]
  *)
let rec worker_loop st =
  let%lwt () = Lwt_unix.yield () in
  let%lwt (fd, addr) = Lwt_unix.accept st.socket in
  match addr with
  | Lwt_unix.ADDR_UNIX _ -> assert false
  | Lwt_unix.ADDR_INET (addr, port) ->
      Lwt.async (fun () ->
          Netpool.accept
            ~callback:Answerer.answer
            st.netpoolos
            st.mempoolos
            fd
            (addr, port)) ;
      worker_loop st

(** Creating the socket on wich se server is listening   *)
let create_listening_socket ~backlog ?(addr = Unix.inet6_addr_any) port =
  let main_socket = Lwt_unix.(socket PF_INET6 SOCK_STREAM 0) in
  Lwt_unix.(setsockopt main_socket SO_REUSEADDR true) ;
  let%lwt () = Lwt_unix.bind main_socket Unix.(ADDR_INET (addr, port)) in
  Lwt_unix.listen main_socket backlog ;
  Lwt.return main_socket

(** Opening the listen socket and creating the state of the server.  *)
let create ?addr ~backlog ~netpoolos ~mempoolos port =
  Lwt.catch
    (fun () ->
      let%lwt socket = create_listening_socket ~backlog ?addr port in
      let st = { socket; netpoolos; mempoolos } in
      Lwt.return st)
    (fun exn ->
      Log.log_error
        "@[<v 2>Cannot accept incoming connections@ %s@ address %s:%a@.@]"
        (Printexc.to_string exn)
        (Unix.string_of_inet_addr
           (Option.value addr ~default:Unix.inet6_addr_any))
        Format.pp_print_int
        port ;
      Lwt.fail exn)

(** Running the server worker  *)
let activate st =
  Lwt.catch
    (fun () ->
      Log.log_info "Server's welcome loop started@." ;
      let%lwt _worker = worker_loop st in
      Log.log_info "Server's welcome loop stopped@." ;
      Lwt.return_unit)
    (fun _ ->
      Log.log_info "Server's welcome loop stopped@." ;
      Lwt_unix.close st.socket)

(** Running the full server.
 [addr]: binding address
 [turn_by_turn] : is the server in turn by turn mode ?
 [nb_rounds]: how many rounds do we play ?
 [timeout]: time before switching to next turn even if some
            participant didn't inject their operation
 [port]: listening port
*)
let serve ?addr ~check_sigs ~turn_by_turn ~nb_rounds ?timeout ~port () =
  Log.log_info
    "Creating pools and server in %s mode.@."
    (if turn_by_turn then "turn-by-turn" else "free turn") ;
  Log.log_info 
    "check_sig=%b, nb_rounds=%d, port=%d.@."
    check_sigs nb_rounds port;
  let netpoolos = Netpool.create () in
  let mempoolos =
    Mempool.create ~check_sigs ~turn_by_turn ~nb_rounds ?timeout ()
  in
  let%lwt server = create ?addr ~backlog:100 ~netpoolos ~mempoolos port in
  Log.log_info "Activating server@." ;
  let%lwt _ = activate server in
  Lwt.return_unit
