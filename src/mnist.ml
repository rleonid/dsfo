(* Load MNIST data 
   http://yann.lecun.com/exdb/mnist/
*)
open Printf
open Common
open Bigarray

let test_images_fname = "t10k-images-idx3-ubyte"
let test_labels_fname = "t10k-labels-idx1-ubyte"
let train_images_fname = "train-images-idx3-ubyte"
let train_labels_fname = "train-labels-idx1-ubyte"

let url = "http://yann.lecun.com/exdb/mnist/"

let files =
  [ test_images_fname
  ; test_labels_fname 
  ; train_images_fname
  ; train_labels_fname
  ]

let gzipped f = f ^ ".gz"
let encoded = List.map gzipped files

let td = function
    | None -> Filename.get_temp_dir_name ()
    | Some d -> d

let download ?(extract=true) ?(dir="") fname =
  let cmd =
    if extract then
      sprintf "curl %s%s | gunzip -c > %s" url (gzipped fname)
        (Filename.concat dir fname)
    else
      sprintf "curl %s%s > %s "  url (gzipped fname)
        (Filename.concat dir (gzipped fname))
  in
  let () = printf "cmd : %s\n%!" cmd in
  read_lines_from_cmd ~max_lines:1 cmd

let map_file_labels fname =
  let fd = Unix.openfile fname [Unix.O_RDONLY] 0o644 in
  let ic = Unix.in_channel_of_descr fd in
  protect ~finally:(fun () -> close_in ic)
    ~f:(fun () ->
      let mn = input_binary_int ic in
      if mn <> 2049 then
        failwithf "Wrong magic number got %d expected 2049" mn
      else
        let size = input_binary_int ic in
        if Unix.lseek fd 0 Unix.SEEK_SET <> 0 then
          failwithf "Failed to seek back to beginning"
        else
          Array1.map_file fd ~pos:8L Int8_unsigned Fortran_layout false size)

let map_file_images fname=
  let fd = Unix.openfile fname [Unix.O_RDONLY] 0o644 in
  let ic = Unix.in_channel_of_descr fd in
  protect ~finally:(fun () -> close_in ic)
    ~f:(fun () ->
      let mn = input_binary_int ic in
      if mn <> 2051 then
        failwithf "Wrong magic number got %d expected 2049" mn
      else
        let size = input_binary_int ic in
        let rows = input_binary_int ic in
        let cols = input_binary_int ic in
        if Unix.lseek fd 0 Unix.SEEK_SET <> 0 then
          failwithf "Failed to seek back to beginning"
        else
          Array3.map_file fd ~pos:16L Int8_unsigned C_layout false
            size rows cols)
 

(*
let row_to_square_gen r s =
  reshape (genarray_of_array1 r) [| s; s |]
  |> array2_of_genarray
  |> Mat.transpose

let join images labels =
  let m  = Mat.dim1 images in
  let n  = Mat.dim2 images in
  let td = Mat.make0 (m + 10) n in
  let td = lacpy ~b:td images in
  Array.iteri (fun idx label ->
    let row = label + 785 in (* 0 at 785 *)
    Array2.set td row (idx + 1) 1.)
    labels;
  td

let test_cache_fname = "mnist_test_cache.dat"
let train_cache_fname = "mnist_train_cache.dat"

let from_cache fname (d1, d2) uncached =
  if Sys.file_exists fname then
    let fd = Unix.openfile fname [Unix.O_RDONLY] 0o600 in
    let () = Printf.printf "using %s as cache\n" fname in
    Array2.map_file fd Float64 Fortran_layout false d1 d2
  else
    let td = uncached () in
    let fd = Unix.openfile fname [Unix.O_RDWR; Unix.O_CREAT] 0o644 in
    let rd = Array2.map_file fd Float64 Fortran_layout true d1 d2 in
    lacpy ~b:rd td

let data ?(cache=true) m =
  let uncached, fname, cols =
    match m with
    | `Test ->
        (fun () -> join (parse_images test_images_fname)
                        (parse_labels test_labels_fname)),
        test_cache_fname,
        10000
    | `Train ->
        (fun () -> join (parse_images train_images_fname)
                        (parse_labels train_labels_fname)),
        train_cache_fname,
        60000
  in
  if cache then
    from_cache fname (794,cols) uncached
  else
    uncached ()
   *)
