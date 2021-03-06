(** Some utility methods, and a test to make sure that we can call out to
    helpful utilities (curl, gunzip, tar) for getting and processing the
    data. *)
let protect ~f ~finally =
  let r = try f () with e -> finally (); raise e in
  finally ();
  r

let failwithf fmt = Printf.ksprintf failwith fmt
let invalid_argf fmt = Printf.ksprintf failwith fmt

(* Taken from M.Mottl's myocamlbuild.ml *)
let read_lines_from_cmd ~max_lines cmd =
  let ic = Unix.open_process_in cmd in
  let lines_ref = ref [] in
  let rec loop n =
    if n <= 0 then ()
    else begin
      lines_ref := input_line ic :: !lines_ref;
      loop (n - 1)
    end
  in
  begin
    try loop max_lines with
    | End_of_file -> ()
    | exc -> close_in_noerr ic; raise exc
  end;
  close_in ic;
  List.rev !lines_ref

(* Replace these with appropriate OCaml libraries? *)
let () =
  if read_lines_from_cmd ~max_lines:1 "which curl" = [] then
    failwith "can't curl"
  else if read_lines_from_cmd ~max_lines:1 "which gunzip" = [] then
    failwith "can't gunzip"
  else if read_lines_from_cmd ~max_lines:1 "which tar" = [] then
    failwith "can't tar"
  else
    ()

let fp ?dir fname =
  match dir with None -> fname | Some dir -> Filename.concat dir fname

