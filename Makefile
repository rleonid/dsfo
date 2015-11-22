
DSFOPKGS=bau
DSVISPKGS=$(DSFOPKGS) graphics
LIB_EXTS=cma cmxa cmxs
INSTALL_EXTS=$(LIB_EXTS) a o cmi cmo cmx

default: dsfo dsvis

dsfo:
	ocamlbuild -use-ocamlfind $(foreach p, $(DSFOPKGS),-pkg $(p)) -I src/lib $(foreach e,$(LIB_EXTS),dsfo.$(e))

dsvis:
	ocamlbuild -use-ocamlfind $(foreach p, $(DSVISPKGS),-pkg $(p)) -I src/lib -I src/vis $(foreach e,$(LIB_EXTS),dsvis.$(e))

install:
	ocamlfind install dsfo META $(foreach e,$(INSTALL_EXTS),_build/src/lib/*.$(e)) $(foreach e,$(INSTALL_EXTS),_build/src/vis/*.$(e))

clean:
	ocamlbuild -clean
