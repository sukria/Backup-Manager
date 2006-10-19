
BASE	= user-guide
SOURCE	= $(BASE).sgml
DEST    = /usr/share/backup-manager/doc

all: pdf txt html
install: all
	install -d $(DEST)
	install $(BASE).pdf $(DEST)
	install $(BASE).html $(DEST)
	install $(BASE).txt $(DEST)

pdf: user-guide.pdf
user-guide.pdf:
	debiandoc2pdf $(SOURCE)

txt: user-guide.txt
user-guide.txt:
	debiandoc2text $(SOURCE)

html: user-guide.html
user-guide.html:
	debiandoc2html $(SOURCE)

clean:
	rm -f *.pdf *.txt *.tpt
	rm -rf $(BASE).html
