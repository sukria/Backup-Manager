## Process this file with automake to produce Makefile.in

INCLUDES = \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	@PACKAGE_CFLAGS@

bin_PROGRAMS = t_mem_handler t_bm_configuration_manager

t_bm_configuration_manager_SOURCES = \
	t_bm_configuration_manager.c

t_mem_handler_SOURCES = \
	t_mem_handler.c

t_bm_configuration_manager_LDADD = @PACKAGE_LIBS@ $(INTLLIBS) ../libmem.a ../libconffile.a ../libstring.a
t_mem_handler_LDADD = @PACKAGE_LIBS@ $(INTLLIBS) ../libmem.a ../libstring.a
