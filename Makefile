
DSFOPKGS=bau
DSVISPKGS=$(DSFOPKGS) graphics
LIB_EXTS=cma cmxa cmxs

default: dsfo dsvis

dsfo:
	ocamlbuild -use-ocamlfind $(foreach p, $(DSFOPKGS),-pkg $(p)) -I src/lib $(foreach e,$(LIB_EXTS),dsfo.$(e))

dsvis:
	ocamlbuild -use-ocamlfind $(foreach p, $(DSVISPKGS),-pkg $(p)) -I src/lib -I src/vis $(foreach e,$(LIB_EXTS),dsvis.$(e))

clean:
	ocamlbuild -clean
