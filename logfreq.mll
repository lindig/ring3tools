
{

  let sprintf = Printf.sprintf

  let this_year = Unix.((time () |> localtime).tm_year+1900)

  type date =
    { year:     int
    ; month:    int
    ; day:      int
    ; hour:     int
    ; min:      int
    ; sec:      int
    }

  let month_from_str = function
    |  "Jan" -> 0
    |  "Feb" -> 1
    |  "Mar" -> 2
    |  "Apr" -> 3
    |  "May" -> 4
    |  "Jun" -> 5
    |  "Jul" -> 6
    |  "Aug" -> 7
    |  "Sep" -> 8
    |  "Oct" -> 9
    |  "Nov" -> 10
    |  "Dec" -> 11
    |  x     -> failwith ("not a month: "^x)

  let a2i n =
    try int_of_string n
    with _ -> failwith (sprintf "not an integer: %s" n)

  (** [is_leapyear] is true, if and only if a year is a leap year *)
  let is_leapyear year =
          year mod 4    = 0
      &&  year mod 400 != 100
      &&  year mod 400 != 200
      &&  year mod 400 != 300

  let ( ** ) x y    = Int64.mul (Int64.of_int x) y
  let sec           = 1L
  let sec_per_min   = 60 ** sec
  let sec_per_hour  = 60 ** sec_per_min
  let sec_per_day   = 24 ** sec_per_hour

  (* The following calculations are based on the following book: Nachum
  Dershowitz, Edward M. Reingold: Calendrical calculations (3. ed.).
  Cambridge University Press 2008, ISBN 978-0-521-88540-9, pp. I-XXIX,
  1-479, Chapter 2, The Gregorian Calendar *)

  let days_since_epoch yy mm dd =
    let epoch       = 1       in
    let y'          = yy - 1  in
    let correction  =
      if mm <= 2                          then 0
      else if mm > 2 && is_leapyear yy    then -1
                                          else -2
    in
      epoch - 1 + 365*y' + y'/4 - y'/100 + y'/400 +
      (367 * mm - 362)/12 + correction + dd

  let seconds_since_epoch d =
    let ( ++ )        = Int64.add in
      (days_since_epoch d.year d.month d.day ** sec_per_day)
      ++ (d.hour ** sec_per_hour)
      ++ (d.min  ** sec_per_min)
      ++ (d.sec  ** sec)

  let elapsed past now =
    let ( -- ) = Int64.sub in
      seconds_since_epoch now  -- seconds_since_epoch past

}

let digit = ['0'-'9']
let month = "Jan" | "Feb" | "Mar" | "Apr" | "May" | "Jun"
          | "Jul" | "Aug" | "Sep" | "Oct" | "Nov" | "Dec"
let weekday = "Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat" | "Sun"

let day   =     digit
          | '1' digit
          | '2' digit
          | '3' ['0'-'1']
let min   = ['0'-'5'] digit
let sec   = ['0'-'5'] digit
let hour  = ['0'-'1'] digit
          | '2' ['0'-'3']
let frac  = '.' digit+
let any   = [^'\n']

rule dateline = parse
    (weekday ' ')?
    (month as month) ' ' ' '? (day   as day)  ' '
    (hour  as hour)  ':'      (min   as min)  ':' (sec   as sec) frac?
    ' ' any * '\n'

                        { Some  { year  = this_year
                                ; month = month_from_str month
                                ; day   = a2i day
                                ; hour  = a2i hour
                                ; min   = a2i min
                                ; sec   = a2i sec
                                }
                        }
  | any * '\n'          { dateline lexbuf (* skip line *) }
  | eof                 { None }

{
  let log2 x   = log x /. log 2.0
  let max x y  = if x > y then x else y

  let freq lines past now =
    let secs    = elapsed past now |> Int64.to_int in
    let rate    = float_of_int lines /. float_of_int secs in
    let rate60s = 60.0 *. rate in
    Printf.printf "%02d-%02d-%02d %02d:%02d:%02d %5d lines %5d sec %8.2f/min %s\n"
      now.year now.month now.day now.hour now.min now.sec
      lines
      secs
      rate60s (* lines per minute *)
      (String.make (log2 rate60s |> max 0.0 |> int_of_float) '#')

  let readuntil p lexbuf =
    let rec loop past lines =
      match dateline lexbuf with
      | Some now when p past now lines ->
          ( freq lines past now
          ; loop now 0
          )
      | Some _ -> loop past (lines+1)
      | None   -> ()
    in
      match dateline lexbuf with
      | Some now -> loop now 0
      | None     -> ()

  let process n io =
    let rec lexbuf = Lexing.from_channel io in
    let enough past now lines =
      let seconds = elapsed past now in
           seconds >= 60L && lines >= n
        || seconds >= 300L
        || seconds < 0L (* reset *)
    in
      readuntil enough lexbuf

  let main () =
    let args = Array.to_list Sys.argv in
    let this = Sys.executable_name in
    let lines = 1000 in
    let a2i n = try int_of_string n with _ -> lines in
      match args with
      | [_]         -> process  lines  stdin; exit 0
      | [_;"-n"; n] -> process (a2i n) stdin; exit 0
      | _           -> Printf.printf "usage: %s [-n n]\n" this; exit 1

  let () = main ()


}


