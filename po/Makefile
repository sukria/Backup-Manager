prefix=$(DESTDIR)

# List here all source files with translatable strings.
POTFILES=$(shell find ../lib -type f -name \*.sh) \
	../backup-manager

POFILES=$(wildcard *.po)
MOFILES=$(POFILES:.po=.mo)


all: backup-manager.pot $(MOFILES)

install: all
	for file in $(MOFILES); do \
		lang=`echo $$file | sed 's/\.mo//'`; \
		install -d $(prefix)/usr/share/locale/$$lang/LC_MESSAGES/; \
		install -m 0644 $$file $(prefix)/usr/share/locale/$$lang/LC_MESSAGES/backup-manager.mo; \
	done

backup-manager.pot: $(POTFILES)
	@echo "Generating ext files"
	for file in $(POTFILES); do \
		base=`basename $$file`; \
		sed -e 's/echo_translated \|error \|warning \|info /gettext /g'< $$file >$$base.ext; \
		sed -e 's/-n//g'< $$base.ext >$$base.ext.new;  \
		mv $$base.ext.new $$base.ext; \
	done
	@echo "Rebuilding the pot file from ext files"
	xgettext --language=Shell -o backup-manager.pot *.ext

clean:
	rm -f backup-manager.pot $(MOFILES) messages messages.mo *.ext messages.po tmp .ext

%.mo: %.po
	msgfmt -o $@ $<

%.po: backup-manager.pot
	@echo -n "Merging backup-manager.pot and $@"
	@msgmerge $@ backup-manager.pot -o $@.new
# Typically all that changes was a date. I'd prefer not to cvs commit such
# changes, so detect and ignore them.
	@if [ "`diff $@ $@.new | grep '[<>]' | wc -l`" -ne 2 ]; then \
		mv -f $@.new $@; \
	else \
		rm -f $@.new; \
	fi
	@msgfmt --statistics $@

check:
	@for file in $(POFILES); do \
		lang=`echo $$file | sed 's/\.po//'`; \
		printf "$$lang: "; \
		msgfmt -o /dev/null -c -v --statistics $$lang.po;\
	done
