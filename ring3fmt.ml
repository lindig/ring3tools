(*
 * filter that expands leading whitespace to tabs and but other tabs
 * to spaces.
 *
 * ocamlbuild ring3fmt.native
 *)

(** create a string with [n] [chr] chars *)
let ( ** ) chr n = String.make n chr

let sub str start len =
  try String.sub str start len
  with Invalid_argument(x) ->
    Printf.eprintf "'%s' start:%d len:%d\n" str start len;
    raise (Invalid_argument x)

(** exapnd tabs in a string to spaces *)
let expand
  : int -> string -> string
  = fun tabwidth str ->
  let len = String.length str in
  let buf = Buffer.create (len * 2) in
  let rec scan col i =
    if i >= len then
      Buffer.contents buf
    else if str.[i] <> '\t' then
      ( Buffer.add_char buf str.[i]
      ; scan (col+1) (i+1)
      )
    else (* expand tab *)
      let n = tabwidth - (col mod tabwidth) in
      ( Buffer.add_string buf (' ' ** n)
      ; scan (col+n) (i+1)
      )
  in
    scan 0 0

(** number of leading spaces in a string *)
let leading
  : string -> int
  = fun str ->
  let len = String.length str in
  let rec loop i =
    if i >= len then len
    else if str.[i] <> ' ' then i
    else loop (i+1)
  in
    loop 0

(* number of trailing spaces in a string *)
let trailing
  : string -> int
  = fun str ->
  let len = String.length str in
  let rec loop i =
    if i < 0 then len
    else if str.[i] <> ' ' then len-1-i
    else loop (i-1)
  in
    loop (len-1)


(** replace leading spaces with tabs, cut trailing spaces *)
let compress
  : int -> string -> string
  = fun tabwidth str ->
  let len     = String.length str in
  let prefix  = leading str in
    if len = prefix then
      ""
    else
      let suffix  = trailing str in
      let tabs    = prefix / tabwidth   in
      let spcs    = prefix mod tabwidth in
      let tail    = sub str prefix (len-prefix-suffix) in
        String.concat ""
        [ String.make tabs '\t'
        ; String.make spcs ' '
        ; tail
        ]

(** process [io] *)
let process tabwidth io =
  let rec iter io =
    let line = input_line io in
      ( line |> expand tabwidth |> compress tabwidth |> print_endline
      ; iter io
      )
  in
    try iter io with End_of_file -> ()

let main () =
  let tabwidth = 2 in
  let a2i n = try int_of_string n with _ -> tabwidth in
  let args = Array.to_list Sys.argv in
  let this = Sys.executable_name in
    match args with
    | [_]         -> process tabwidth stdin; exit 0
    | [_;"-t"; n] -> process (a2i n) stdin; exit 0
    | _           -> Printf.printf "usage: %s [-t n]\n" this; exit 1

let () = Printexc.catch main ()
