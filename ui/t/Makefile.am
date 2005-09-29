## Process this file with automake to produce Makefile.in

MAINTAINERCLEANFILES = Makefile.in

INCLUDES = \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	@PACKAGE_CFLAGS@

bin_PROGRAMS = t_libmem t-bm-libconfig

t_bm_libconfig_SOURCES = \
	t-bm-libconfig.c

t_libmem_SOURCES = \
	t_libmem.c

t_bm_libconfig_LDADD = @PACKAGE_LIBS@ $(INTLLIBS) \
	$(top_builddir)/src/libmem.a \
	$(top_builddir)/src/libconffile.a \
	$(top_builddir)/src/libstring.a

t_libmem_LDADD = @PACKAGE_LIBS@ $(INTLLIBS) \
	$(top_builddir)/src/libmem.a \
	$(top_builddir)/src/libstring.a

