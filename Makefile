
PACKAGES=bau

default: dsfo.cmxa

dsfo.cmxa:
	ocamlbuild -use-ocamlfind $(foreach package, $(PACKAGES),-package $(package)) -I src/lib dsfo.cma dsfo.cmxa dsfo.cmxs

clean:
	ocamlbuild -clean
