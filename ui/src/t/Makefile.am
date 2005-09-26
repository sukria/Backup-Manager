## Process this file with automake to produce Makefile.in

INCLUDES = \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	@PACKAGE_CFLAGS@

bin_PROGRAMS = t_libmem t_bm_configuration_manager

t_bm_configuration_manager_SOURCES = \
	t_bm_configuration_manager.c

t_libmem_SOURCES = \
	t_libmem.c

t_bm_configuration_manager_LDADD = @PACKAGE_LIBS@ $(INTLLIBS) ../libmem.a ../libconffile.a ../libstring.a
t_libmem_LDADD = @PACKAGE_LIBS@ $(INTLLIBS) ../libmem.a ../libstring.a
