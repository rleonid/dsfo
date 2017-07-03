
(** Download the data *)

val description : string

val download : ?extract:bool -> ?dir:string -> unit -> unit

type data_m = (float, Bigarray.float64_elt, Bigarray.fortran_layout) Bigarray.Array2.t

(** Load the appropriate data *)
val data : ?dir:string -> ?cache:bool -> [< `Test | `Train of int ] -> data_m 

type color_v = (float, Bigarray.float64_elt, Bigarray.fortran_layout) Bigarray.Array1.t 

(** Separate the data into a triple of the red, green and blue values and
    the label *)
val decode : data_m -> int -> (color_v * color_v * color_v) * string

