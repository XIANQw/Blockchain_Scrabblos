let ( >>? ) b a = match b with Ok b -> Ok (a b) | Error _ as err -> err

let ( ||? ) (i, r) f = match r with Ok _ as v -> (i, v) | Error _ -> (i, f i)

let ( >|> ) f g x = f x >>? g

type error = ..

type error += Exn of exn

let protect f = try Ok (f ()) with exn -> Error (Exn exn)
