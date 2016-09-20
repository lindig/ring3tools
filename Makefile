# vim: set ts=8 noet:
#
#

PREFIX 	= $(HOME)
BIN 	= $(PREFIX)/bin
OCB 	= ocamlbuild

TOOLS 	+= chopchop.native
TOOLS   += logfreq.native
TOOLS 	+= ring3fmt.native

.PHONY: all
all: 	$(TOOLS)

.PHONY: install
install: all
	install chopchop.native $(BIN)/chopchop
	install logfreq.native 	$(BIN)/logfreq
	install ring3fmt.native $(BIN)/ring3fmt

.PHONY: clean
clean:
	$(OCB) -clean

%.native:
	$(OCB) $@

logfreq.native:
	$(OCB) -pkg unix $@


