open Dsfo
open Cifar10

let aligned_native (r, g, b) f =
  Array.init 32 (fun i ->
    Array.init 32 (fun j ->
      let o = 32 * i + j + 1 in
      f r.{o} g.{o} b.{o}))

let aligned_colors t =
  aligned_native t (fun rf gf bf ->
      Graphics.rgb (int_of_float rf) (int_of_float gf) (int_of_float bf))

let draw_and_inspect ?(cg=true) ?(x=100) ?(y=100) ?(zoom=1) ?label ca =
  if cg then Graphics.clear_graph ();
  let ca =
    if zoom <= 1 then ca else  
      let n = Array.length ca in
      let m = Array.length ca.(0) in
      Array.init (n * zoom) (fun i ->
        Array.init (m * zoom) (fun j ->
          ca.(i / zoom).(j / zoom)))
  in
  let im = Graphics.make_image ca in
  Graphics.draw_image im x y;
  match label with | None -> ()
  | Some l ->
    begin
      Graphics.moveto x (y - 10);
      Graphics.draw_string l
    end
