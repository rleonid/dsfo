
DSFOPKGS:=bau
DSVISPKGS:=$(DSFOPKGS) graphics
LIB_EXTS:=cma cmxa cmxs
INSTALL_EXTS:=$(LIB_EXTS) a o cmi cmo cmx
GRAPHICS_INSTALLED:=$(shell [ -e $$(ocamlfind query graphics)/graphics.a ] && echo 1 || echo 0)

ifeq ($(GRAPHICS_INSTALLED), 1)
	DEFAULT := dsvis
	INSTALL := install_with_vis
else
	DEFAULT := dsfo
	INSTALL := install_wo_vis
endif

default:
	$(info $$GRAPHICS_INSTALLED is $(GRAPHICS_INSTALLED))
	$(info $$DEFAULT is $(DEFAULT))
	$(MAKE) $(DEFAULT)

install:
	$(info $$GRAPHICS_INSTALLED is $(GRAPHICS_INSTALLED))
	$(info $$INSTALL is $(INSTALL))
	$(MAKE) $(INSTALL)

dsfo:
	ocamlbuild -use-ocamlfind $(foreach p, $(DSFOPKGS),-pkg $(p)) -I src/lib $(foreach e,$(LIB_EXTS),dsfo.$(e))

dsvis:
	ocamlbuild -use-ocamlfind $(foreach p, $(DSVISPKGS),-pkg $(p)) -I src/lib $(foreach e,$(LIB_EXTS),dsfo.$(e)) -I src/vis $(foreach e,$(LIB_EXTS),dsvis.$(e))

install_wo_vis:
	ocamlfind install dsfo META $(foreach e,$(INSTALL_EXTS),_build/src/lib/*.$(e))

install_with_vis:
	ocamlfind install dsfo META $(foreach e,$(INSTALL_EXTS),_build/src/lib/*.$(e)) $(foreach e,$(INSTALL_EXTS),_build/src/vis/*.$(e))

clean:
	ocamlbuild -clean
