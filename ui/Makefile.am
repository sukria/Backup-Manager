## Process this file with automake to produce Makefile.in

MAINTAINERCLEANFILES = \
	aclocal.m4 \
	config.h.in \
	config.log \
	config.status \
	configure \
	depcomp \
	install-sh \
	Makefile \
	Makefile.in \
	missing \
	mkinstalldirs \
	po/Makefile \
	po/Makefile.in \
	stamp-h.in \
	stamp-h1

SUBDIRS = src po

EXTRA_DIST = \
	autogen.sh \
	backup-manager-ui.glade \
	backup-manager-ui.gladep

install-data-local:
	@$(NORMAL_INSTALL)
	if test -d $(srcdir)/pixmaps; then \
	  $(mkinstalldirs) $(DESTDIR)$(pkgdatadir)/pixmaps; \
	  for pixmap in $(srcdir)/pixmaps/*; do \
	    if test -f $$pixmap; then \
	      $(INSTALL_DATA) $$pixmap $(DESTDIR)$(pkgdatadir)/pixmaps; \
	    fi \
	  done \
	fi

dist-hook:
	if test -d pixmaps; then \
	  mkdir $(distdir)/pixmaps; \
	  for pixmap in pixmaps/*; do \
	    if test -f $$pixmap; then \
	      cp -p $$pixmap $(distdir)/pixmaps; \
	    fi \
	  done \
	fi

