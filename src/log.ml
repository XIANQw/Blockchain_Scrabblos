let green = "2"

let orange = "3"

let red = "1"

let gray = "7"

(*
  ColorNames=( Black Red Green Yellow Blue Magenta Cyan White )
  FgColors=(    30   31   32    33     34   35      36   37  )
  BgColors=(    40   41   42    43     44   45      46   47  )

  local AttrNorm=0
  local AttrBright=1
  local AttrDim=2
  local AttrUnder=4
  local AttrBlink=5
  local AttrRev=7
  local AttrHide=8

 *)
let color_text ?(attr = "1") text color =
  "\027[" ^ attr ^ ";3" ^ color ^ "m" ^ text ^ "\027[m"

let log_color col tag format =
  let print = Format.printf "[%s] %s" (color_text tag col) in
  Format.kasprintf print format

let log_color_line ?(attr = "1") col tag format =
  let print s =
    Format.printf "\027[%s;3%sm[%s]%s\027[m" attr col tag s ;
    flush_all ()
  in
  Format.kasprintf print format

let log_color_line_no_prefix ?(attr = "1") col format =
  let print s =
    Format.printf "\027[%s;3%sm%s\027[m" attr col s ;
    flush_all ()
  in
  Format.kasprintf print format

let log_success format = log_color green "OK" format

let log_error format = log_color red "Error" format

let log_warn format = log_color orange "Warning" format

let log_info format = log_color_line ~attr:"0" gray "info" format

let log_info_continue format = log_color_line_no_prefix ~attr:"0" gray format
