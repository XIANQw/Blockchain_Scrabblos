open Messages
open Letter
open Word
open Utils

(** Broadcasting a message to the registered connections  *)
let broadcast ?except broadcastpool msg =
  Log.log_info "Broadcasting message %a@." Messages.pp_message msg ;
  Pool.iter_p broadcastpool (fun (point, (conn : Netpool.conn)) ->
      if unopt_map ~default:true (fun p -> point != p) except then
        Messages.send_async ~verbose:false msg conn.fd
      else Lwt.return_unit)

(** Check the signature of a letter  *)
let check_letter l =
  if Letter.check_signature l then true
  else (
    Log.log_warn "Signature check failed for %a@." pp_letter l ;
    false )

(** Check the signature of a word *)
let check_word w =
  if Word.check_signature w then true
  else (
    Log.log_warn "Signature check failed for %a@." pp_word w ;
    false )

let log_unexpected_message msg =
  Log.log_warn
    "@[<v 2>Unexpected msg %a.@]@.Igonoring it.@."
    Messages.pp_message
    msg ;
  Lwt.return_unit

(** answer triggered by received messages *)
let answer (st : Netpool.worker_state) (msg : (Messages.message, string) result)
    =
  match msg with
  | Error s ->
      Log.log_error "Error decoding input message: %s" s ;
      Messages.send_async
        (Messages.Inject_raw_op (Bytes.unsafe_of_string s))
        st.fd
  | Ok msg -> (
      Log.log_info "Processing messages @[%a@]@." Messages.pp_message msg ;
      match msg with
      (* On registration, send a bag of letters *)
      | Register id ->
          let lettres = Mempool.gen_letters st.mempoolos id in
          Mempool.register st.mempoolos id ;
          Messages.send_async (Messages.Letters_bag lettres) st.fd
      (* On listen, add to the broadcast pool *)
      | Listen ->
          Pool.add
            st.netpoolos.broadcastpoolos
            st.point
            { point = st.point; fd = st.fd }
      (* On stop listen, remove from the broadcast pool *)
      | Stop_listen ->
          Pool.remove st.netpoolos.broadcastpoolos st.point ;
          Lwt.return_unit
      (* On Get_full_letterpool, send the fool letter pool currently
       * in mempool *)
      | Get_full_letterpool ->
          Messages.send_async
            (Messages.Full_letterpool (Mempool.letterpool st.mempoolos))
            st.fd
      (* On Get_full_wordpool, send the fool word pool currently
       * in mempool *)
      | Get_full_wordpool ->
          Messages.send_async
            (Messages.Full_wordpool (Mempool.wordpool st.mempoolos))
            st.fd
      (* On Get_letterpool_since, send the letters added to the
       * pool since the given period *)
      | Get_letterpool_since date ->
          Messages.send_async
            (Messages.Diff_letterpool
               {
                 since = date;
                 letterpool = Mempool.letterpool_since st.mempoolos date;
               })
            st.fd
      (* On Get_wordpool_since, send the words added to the
       * pool since the given period *)
      | Get_wordpool_since date ->
          Messages.send_async
            (Messages.Diff_wordpool
               {
                 since = date;
                 wordpool = Mempool.wordpool_since st.mempoolos date;
               })
            st.fd
      (* On Inject_letter, check letter validity, then inject in the
         mempool.
         If injection succeed, the word is broadcasted.
         Injection can trigger a change of period in which case
         [Next_Turn] message is broadcasted
      *)
      | Inject_letter l -> (
          let (next_turn, injected) = Mempool.inject_letter st.mempoolos l in
          let%lwt _bcst_msg =
            if injected then
              broadcast ~except:st.point st.netpoolos.broadcastpoolos msg
            else (
              Log.log_warn "Injection failed for letter %a" pp_letter l ;
              Lwt.return_unit )
          in
          match next_turn with
          | Some p when Mempool.turn_by_turn st.mempoolos ->
              broadcast st.netpoolos.poolos (Messages.Next_turn p)
          | _ -> Lwt.return_unit
          (* On Inject_word, check word validity, then inject in the
             mempool.
             The word is broadcasted, injection should always succeed..
             The opportunity is taken to check wether a change of period
               * occured (for example due to a timeout) in which case
             [Next_Turn] message is broadcasted
          *) )
      | Inject_word w -> (
          let (next_turn, _injected) = Mempool.inject_word st.mempoolos w in
          let%lwt _bcst_msg =
            broadcast ~except:st.point st.netpoolos.broadcastpoolos msg
          in
          match next_turn with
          | Some p when Mempool.turn_by_turn st.mempoolos ->
              broadcast st.netpoolos.poolos (Messages.Next_turn p)
          | _ -> Lwt.return_unit )
      (* Raw operations are directly broadcasted  *)
      | Inject_raw_op _ ->
          broadcast ~except:st.point st.netpoolos.broadcastpoolos msg
      (* Clients should not forge the following messages *)
      | Letters_bag _ -> log_unexpected_message msg
      | Next_turn _ -> log_unexpected_message msg
      | Full_letterpool _ -> log_unexpected_message msg
      | Diff_letterpool _ -> log_unexpected_message msg
      | Full_wordpool _ -> log_unexpected_message msg
      | Diff_wordpool _ -> log_unexpected_message msg )
