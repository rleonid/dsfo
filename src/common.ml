
let protect ~f ~finally =
  let r = try f () with e -> finally (); raise e in
  finally ();
  r

let failwithf fmt = Printf.ksprintf failwith fmt

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

let () =
  if read_lines_from_cmd ~max_lines:1 "which curl" = [] then
    failwith "can't curl"
  else if read_lines_from_cmd ~max_lines:1 "which gunzip" = [] then
    failwith "can't gunzip"
  else
    ()
