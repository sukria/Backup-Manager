
BASE	= user-guide
SOURCE	= $(BASE).sgml

install: pdf txt html

pdf:
	debiandoc2pdf $(SOURCE)
txt:
	debiandoc2text $(SOURCE)
html:
	debiandoc2html $(SOURCE)

clean:
	rm -f *.pdf *.txt *.tpt
	rm -rf $(BASE).html
