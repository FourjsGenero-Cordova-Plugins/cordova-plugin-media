.SUFFIXES: .per .42f .4gl .42m .msg .img 

%.42f: %.per 
	fglform -M $<

%.42m: %.4gl 
	fglcomp -M -W all --resolve-calls $<

%.xa: %.4gl 
	fglcomp -M -W all --build-doc $<

%.iem: %.msg
	fglmkmsg $< $@

MODS=$(patsubst %.4gl,%.42m,$(wildcard *.4gl))
DOCS_XA=$(patsubst %.4gl,%.xa,$(wildcard *.4gl))

all:: $(MODS)

$(MODS): git_version.txt

git_version.txt:
	echo "CONSTANT GIT_VERSION='$(shell git describe)'" >$@

$(DOCS_XA): git_version.txt

doc: $(DOCS_XA)

clean:
	rm -f *.42?
	rm -f *.xa git_version.txt

distclean: clean
	rm -f *.html
