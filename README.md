[![Build Status](https://travis-ci.org/rleonid/dsfo.svg?branch=master)](https://travis-ci.org/rleonid/dsfo)

Download (`anyhow`) and interact (`ocaml`) with common machine learning datasets.

  - [MNIST](http://yann.lecun.com/exdb/mnist/)

    ```OCaml
    # Mnist.download `Train ;;
    - : unit = ()
    # Mnist.download `Test ;;
    - : unit = ()
    # let train = Mnist.data `Train ;;
    val train : (float, Bigarrayo.float64_elt, Bigarrayo.fortran_layout) Bigarrayo.A2.t =  ...
    # let test = Mnist.data `Test ;;
    val test : (float, Bigarrayo.float64_elt, Bigarrayo.fortran_layout) Bigarrayo.A2.t =  ...
    ```

  - [CIFAR10](http://www.cs.toronto.edu/~kriz/cifar.html)

  ```OCaml
  # let t3 = Cifar10.data (`Train 3) ;;
  # Graphics.open_graph "" ;;
  # let display n =
      let tr, label = Cifar10.decode t3 n in
      Vcifar10.draw_and_inspect ~zoom:3 ~label (Vcifar10.aligned_colors tr) ;;
  ```
