# Installation

This project requires opam 2.0 to be installed via opam, which is the
recommended way.

The minimal OCaml version is 4.08.0

## Install Opam 2

https://opam.ocaml.org/doc/Install.html

On Ubuntu-like system, you can simply use aptitude:

```
$ sudo apt-get install opam
```

## Initialize Opam with OCaml 4.08.0

If you never had initialized opam, do:

```
$ opam init
$ eval $(opam env)
```

## Install Scrabblos

First pin the git repository for the scrabblos project:

```
$ opam pin add scrabblos https://gitlab.com/julien.t/projet-p6.git
```

Then install the package:

```
$ opam install scrabblos
```

If your current opam switch has a too old version of the OCaml
compiler, and you don't want to create a new switch, you can use :

```
$ opam install scrabblos --unlock-base
```

Be aware that it will change the compiler version of your current
switch.
