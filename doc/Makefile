
BASE	= user-guide
SOURCE	= $(BASE).sgml
DEST    = /usr/share/backup-manager/doc

all: pdf txt html
install: all
	install -d $(DEST)
	install $(BASE).pdf $(DEST)
	install $(BASE).html $(DEST)
	install $(BASE).txt $(DEST)

pdf:
	debiandoc2pdf $(SOURCE)
txt:
	debiandoc2text $(SOURCE)
html:
	debiandoc2html $(SOURCE)

clean:
	rm -f *.pdf *.txt *.tpt
	rm -rf $(BASE).html
