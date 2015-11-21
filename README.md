
Download (`anyhow`) and interact (`ocaml`) with common machine learning datasets.

  - [MNIST](http://yann.lecun.com/exdb/mnist/)
  - [CIFAR10](http://www.cs.toronto.edu/~kriz/cifar.html)

  ```OCaml
  # let t3 = Cifar10.data (`Train 3) ;;
  # Graphics.open_graph "" ;;
  # let display n =
      let tr, label = Cifar10.decode t3 n in
      Vcifar10.draw_and_inspect ~zoom:3 ~label (Vcifar10.aligned_colors tr) ;;
  ```
