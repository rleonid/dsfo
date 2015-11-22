(** Load MNIST data
   http://yann.lecun.com/exdb/mnist/
*)

(** Download the necessary files to [dir].

  @param dir Where to download files, defaults to current dir.
  @raise Invalid_argument if command doesn't succeed, check stdout
*)
val download : ?dir:string -> [< `Test | `Train ] -> unit

(**
  Organized as fortran matrix where each column is a labeled data.
  The first 28 * 28 rows of a column represent the image and
  the next 10 a dummy encoding of the label.

  @param dir Directory to look for downloaded files, defaults to current dir.
  @cache Cached the matrix in the current directory.

  @raise Invalid_argument if necessary files are not not in [dir].
*)
val data : ?dir:string -> ?cache:bool -> [< `Test | `Train ] ->
  (float, Bigarrayo.float64_elt, Bigarrayo.fortran_layout) Bigarrayo.A2.t


(** [decode dataset index] separate the training and label parts stored in a
    column vector at the specified index. *)
val decode : ('a, 'b, Bigarray.fortran_layout) Bigarrayo.A2.t -> int ->
              ('a, 'b, Bigarray.fortran_layout) Bigarrayo.Array2.t * 
              ('a, 'b, Bigarray.fortran_layout) Bigarrayo.A1.t 
