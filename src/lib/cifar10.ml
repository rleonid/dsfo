(* Load CIFAR-10 data
 * http://www.cs.toronto.edu/~kriz/cifar.html
 *)
open Common
open Printf
open Bigarrayo

let train_batch_fname n =
  match n with
  | 1 | 2 | 3 | 4 | 5 -> sprintf "cifar-10-batches-bin/data_batch_%d.bin" n
  | _ -> invalid_argf "unrecognized batch %d only in [1,5]" n

let test_batch_fname = "cifar-10-batches-bin/test_batch.bin"

let url = "http://www.cs.toronto.edu/~kriz/cifar-10-binary.tar.gz"

let download ?(extract=true) ?dir () =
  let cmd =
    if extract then
      let dc = match dir with None -> "" | Some c -> sprintf "-C %s"c in
      sprintf "curl %s | tar xvz %s" url dc
    else
      let dc = match dir with | None -> "" | Some c -> sprintf "cd %s;" c in
      sprintf "%scurl -O %s " dc url
  in
  let c = Sys.command cmd in
  if c = 0 then () else invalid_argf "failed %d" c

let items = 10000

let map_file fname =
  let fd = Unix.openfile fname [Unix.O_RDONLY] 0o600 in
  let c  = items in
  let r  = 3 * 32 * 32 + 1 in
  let a  = Array2.map_file fd Int8_unsigned C_layout false c r in
  Unix.close fd;
  a

let image_rows_ub_fortran = 3 * 32 * 32
let label_rows_ub_fortran = image_rows_ub_fortran + 10

let fortran_style_data a =
  A2.init Float64 Fortran_layout label_rows_ub_fortran items (fun r c ->
    if r <= image_rows_ub_fortran then
      float a.{c-1,r}
    else
      let label = a.{c-1,0} in
      if label = r - image_rows_ub_fortran - 1 then
        1.0
      else
        0.0)

let cache_fname = sprintf "cifar10_cache_%s.dat"

let from_cache fname uncached =
  if Sys.file_exists fname then
    let fd = Unix.openfile fname [Unix.O_RDONLY] 0o600 in
    let td =
      A2.map_file fd Float64 Fortran_layout false label_rows_ub_fortran items
    in
    Unix.close fd;
    td
  else
    let td = uncached () in
    let fd = Unix.openfile fname [Unix.O_RDWR; Unix.O_CREAT] 0o644 in
    let rd =
      A2.map_file fd Float64 Fortran_layout true label_rows_ub_fortran items
    in
    A2.blit td rd;
    Unix.close fd;
    td

let data ?dir ?(cache=true) m =
  let uncached, fname =
    match m with
    | `Test ->
      (fun () ->
         let mapped = map_file (fp ?dir test_batch_fname) in
         fortran_style_data mapped),
      (cache_fname "test")
    | `Train n ->
      (fun () ->
         let mapped = map_file (fp ?dir (train_batch_fname n)) in
         fortran_style_data mapped),
      (cache_fname (sprintf "train%d" n))
  in
  if cache then
    from_cache fname uncached
  else
    uncached ()

let label_to_string = function
  | 0 -> "airplane"
  | 1 -> "automobile"
  | 2 -> "bird"
  | 3 -> "cat"
  | 4 -> "deer"
  | 5 -> "dog"
  | 6 -> "frog"
  | 7 -> "horse"
  | 8 -> "ship"
  | 9 -> "truck"
  | x -> invalid_arg (sprintf "Only [0,9] acceptable CIFAR-10 labels: %d" x)

let decode dt i =
  let col = A2.slice_right dt i in
  let label_part = A1.sub col 3073 10 in
  let image_part = A1.sub col 1 3072 in
  let red = A1.sub image_part 1 1024 in
  let green = A1.sub image_part 1024 1024 in
  let blue = A1.sub image_part 2048 1024 in
  let label =
    let rec loop i =
      if label_part.{i} = 1.0 then
        label_to_string (i - 1)
      else
        loop (i + 1)
    in
    loop 1
  in
  (red, green, blue), label
