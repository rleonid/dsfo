(* Load MNIST data
   http://yann.lecun.com/exdb/mnist/
*)
open Printf
open Common
open BigarrayExt

let description =
  "The MNIST database of handwritten digits, available from this page, has a training set of 60,000 examples, and a test set of 10,000 examples. It is a subset of a larger set available from NIST. The digits have been size-normalized and centered in a fixed-size image."

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

let download_driver ?(extract=true) ?dir fname =
  let cmd =
    if extract then
      sprintf "curl %s%s | gunzip -c > %s" url (gzipped fname)
        (fp ?dir fname)
    else
      sprintf "curl %s%s > %s " url (gzipped fname)
        (fp ?dir (gzipped fname))
  in
  let c = Sys.command cmd in
  if c = 0 then () else invalid_argf "failed %d" c

(* Avoid writing a full IDX parser until necessary. *)
let map_file_gen expected fname ~read_header ~read_rest =
  let fd = Unix.openfile fname [Unix.O_RDONLY] 0o644 in
  let ic = Unix.in_channel_of_descr fd in
  protect ~finally:(fun () -> close_in ic)
    ~f:(fun () ->
      let mn = input_binary_int ic in
      if mn <> expected then
        failwithf "Wrong magic number got %d expected %d" mn expected
      else
        let h = read_header ic in
        if Unix.lseek fd 0 Unix.SEEK_SET <> 0 then
          failwithf "Failed to seek back to beginning"
        else
          read_rest h fd)

let map_file_labels =
  map_file_gen 2049
    ~read_header:input_binary_int
    ~read_rest:(fun size fd ->
        Array1.map_file fd ~pos:8L Int8_unsigned C_layout false size)

let map_file_images =
  map_file_gen 2051
    ~read_header:(fun ic ->
        let size = input_binary_int ic in
        let rows = input_binary_int ic in
        let cols = input_binary_int ic in
        (size, rows, cols))
    ~read_rest:(fun (size, rows, cols) fd ->
          Array3.map_file fd ~pos:16L Int8_unsigned C_layout false
            size rows cols)

let scale_by_255 c = (float_of_int c) /. 255.0

let labeled_fortran_style labels images to_float label_encoding_size encode =
  let n_l = Array1.dim labels in
  let n_i = Array3.dim1 images in
  if n_l <> n_i then
    invalid_argf "label length %d doesn't equal image length %d" n_l n_i
  else
    let r = Array3.dim2 images in
    let c = Array3.dim3 images in
    let data_width = r * c in
    let w = data_width + label_encoding_size in
    let encoded = Array.init n_l (fun col -> encode labels.{col}) in
    Array2.init Float64 Fortran_layout w n_l (fun row col ->
      let c_row = row - 1 in
      let c_col = col - 1 in
      if c_row < data_width then
        to_float (images.{c_col, c_row mod r, c_row / r})
      else
        encoded.(c_col).(c_row - data_width))

let dummy_encoding = function
  | 0 -> [| 1.; 0.; 0.; 0.; 0.; 0.; 0.; 0.; 0.; 0.|]
  | 1 -> [| 0.; 1.; 0.; 0.; 0.; 0.; 0.; 0.; 0.; 0.|]
  | 2 -> [| 0.; 0.; 1.; 0.; 0.; 0.; 0.; 0.; 0.; 0.|]
  | 3 -> [| 0.; 0.; 0.; 1.; 0.; 0.; 0.; 0.; 0.; 0.|]
  | 4 -> [| 0.; 0.; 0.; 0.; 1.; 0.; 0.; 0.; 0.; 0.|]
  | 5 -> [| 0.; 0.; 0.; 0.; 0.; 1.; 0.; 0.; 0.; 0.|]
  | 6 -> [| 0.; 0.; 0.; 0.; 0.; 0.; 1.; 0.; 0.; 0.|]
  | 7 -> [| 0.; 0.; 0.; 0.; 0.; 0.; 0.; 1.; 0.; 0.|]
  | 8 -> [| 0.; 0.; 0.; 0.; 0.; 0.; 0.; 0.; 1.; 0.|]
  | 9 -> [| 0.; 0.; 0.; 0.; 0.; 0.; 0.; 0.; 0.; 1.|]
  | x -> invalid_argf "this is not a digit in mnist %d" x

let fortran_style_data ?dir = function
  | `Test ->
    let tif = fp ?dir test_images_fname in
    let tlf = fp ?dir test_labels_fname in
    if not (Sys.file_exists tif) then
      invalid_argf "Missing file %s" tif
    else if not (Sys.file_exists tlf) then
      invalid_argf "Missing file %s" tlf
    else
      let images = map_file_images tif in
      let labels = map_file_labels tlf in
      labeled_fortran_style labels images scale_by_255 10 dummy_encoding
  | `Train ->
    let tif = fp ?dir train_images_fname in
    let tlf = fp ?dir train_labels_fname in
    if not (Sys.file_exists tif) then
      invalid_argf "Missing file %s" tif
    else if not (Sys.file_exists tlf) then
      invalid_argf "Missing file %s" tlf
    else
      let images = map_file_images tif in
      let labels = map_file_labels tlf in
      labeled_fortran_style labels images scale_by_255 10 dummy_encoding

let cache_fname = sprintf "mnist_cache_%s.dat"

let from_cache fname d1 d2 uncached =
  if Sys.file_exists fname then
    let fd = Unix.openfile fname [Unix.O_RDONLY] 0o600 in
    let td = Array2.map_file fd Float64 Fortran_layout false d1 d2 in
    Unix.close fd;
    td
  else
    let td = uncached () in
    let fd = Unix.openfile fname [Unix.O_RDWR; Unix.O_CREAT] 0o644 in
    let rd = Array2.map_file fd Float64 Fortran_layout true d1 d2 in
    Array2.blit td rd;
    Unix.close fd;
    td

let download ?dir = function
  | `Test ->
    download_driver ?dir test_images_fname;
    download_driver ?dir test_labels_fname;
  | `Train ->
    download_driver ?dir train_images_fname;
    download_driver ?dir train_labels_fname

let data ?dir ?(cache=true) m =
  let uncached, fname, cols =
    match m with
    | `Test ->
        (fun () -> fortran_style_data ?dir `Test),
        (cache_fname "test"),
        10000
    | `Train ->
        (fun () -> fortran_style_data ?dir `Train),
        (cache_fname "train"),
        60000
  in
  if cache then
    from_cache fname 794 cols uncached
  else
    uncached ()

let decode dt i =
  let w = 28 * 28 in
  let v = Array2.slice_right dt i in
  let m =
    Array1.sub v 1 w
    |> genarray_of_array1
    |> (fun g -> reshape_2 g 28 28)
  in
  m, Array1.sub v (w + 1) 10
