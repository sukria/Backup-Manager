prefix=$(DESTDIR)

# List here all source files with translatable strings.
POTFILES= \
	$(shell find ../lib -type f -name \*.sh) \
	../backup-manager
POFILES_SRC=backup-manager.files

POFILES=$(wildcard *.po)
MOFILES=$(POFILES:.po=.mo)

all: backup-manager.pot $(POFILES) $(MOFILES)

install: $(MOFILES)
	@echo "Installing mo files"
	for file in $(MOFILES); do \
		lang=`echo $$file | sed 's/\.mo//'`; \
		install -d $(prefix)/usr/share/locale/$$lang/LC_MESSAGES/; \
		install -m 0644 $$file $(prefix)/usr/share/locale/$$lang/LC_MESSAGES/backup-manager.mo; \
	done


$(POFILES_SRC):
	find ../lib -type f -name \*.sh > $(POFILES_SRC)
	echo ../backup-manager >> $(POFILES_SRC)

backup-manager.pot: $(POFILES_SRC)
	xgettext --keyword=info \
	         --keyword=warning \
			 --keyword=error \
			 --keyword=echo_translated \
			 --language=Shell \
			 -o backup-manager.pot \
			 --files-from=$(POFILES_SRC)
clean:
	rm -f backup-manager.pot \
	      $(MOFILES) \
		  messages messages.mo \
		  messages.po 
		  
%.mo: %.po
	msgfmt -o $@ $<

%.po: backup-manager.pot
	@echo -n "Merging backup-manager.pot and $@"
	@msgmerge $@ backup-manager.pot -o $@.new
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
