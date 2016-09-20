{ (* vim: set ts=2 sw=2 et: *)

  (* This tool:
    * - reads input from stdin line by line
    * - seperates each line into a list of words
    * - slides a window of size 2 over the words of a line
    * - emits each window of words to stdout
    *
    * usage: chopchop [-w 2]
    *
    * Typical application:
    * ./chopchop < /var/log/system.log  | sort | uniq -c | sort -rn
    *
    * ocamlbuild chopchop.native
    *
    *)

  module L = Lexing 

  let get      = L.lexeme
  let sprintf  = Printf.sprintf

  exception Error of string
  let error lexbuf fmt = Printf.kprintf (fun msg -> raise (Error msg)) fmt

}

let ws    = [' ' '\t']
let nl    = ['\n']
let alpha = ['a'-'z' 'A'-'Z']
let digit = ['0'-'9']
let word  = (alpha|digit)+

rule words ws = parse
| nl        { Some (List.rev ws) }
| word      { words (get lexbuf :: ws) lexbuf }
| _         { words ws lexbuf }
| eof       { match ws with [] -> None | ws -> Some (List.rev ws) }

{
  let take n xs =
    let rec loop acc n xs =
      match n, xs with
      | 0, _        -> List.rev acc
      | _, []       -> []
      | n, x::xs    -> loop (x::acc) (n-1) xs
    in
      loop [] n xs

  let line window words =
    let rec loop words = match take window words with
    | []  -> ()
    | ws  -> ws |> String.concat "|" |> print_endline; loop (List.tl words)
    in
      loop words

  let process window io =
    let rec lexbuf = L.from_channel io in
    let rec iter lexbuf =
      match words [] lexbuf with
      | Some ws -> line window ws; iter lexbuf
      | None    -> ()
    in
      iter lexbuf

  let main () =
    let window = 2 in
    let a2i n = try int_of_string n with _ -> window in
    let args = Array.to_list Sys.argv in
    let this = Sys.executable_name in
      match args with
      | [_]         -> process window stdin; exit 0
      | [_;"-w"; n] -> process (a2i n) stdin; exit 0
      | _           -> Printf.printf "usage: %s [-w n]\n" this; exit 1

  let () = main ()

}
