(** Load MNIST data
   http://yann.lecun.com/exdb/mnist/
*)

type fortran_float_matrix = (float, Bigarrayo.float64_elt, Bigarrayo.fortran_layout) Bigarrayo.A2.t

(**
  Organized as fortran matrix where each column is a labeled data.
  The first 28 * 28 rows of a column represent the image and
  the next 10 a dummy encoding of the label.
*)
val data : ?cache:bool -> [< `Test | `Train ] -> fortran_float_matrix 

(** [decode dataset index] separate the training and label parts stored in a
    column vector at the specified index. *)
val decode : ('a, 'b, Bigarray.fortran_layout) Bigarrayo.A2.t -> int ->
              ('a, 'b, Bigarray.fortran_layout) Bigarrayo.Array2.t * 
              ('a, 'b, Bigarray.fortran_layout) Bigarrayo.A1.t 
