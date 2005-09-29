## Process this file with automake to produce Makefile.in

MAINTAINERCLEANFILES = Makefile.in


INCLUDES = \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	@PACKAGE_CFLAGS@

bin_PROGRAMS = backup-manager-preferences
noinst_LIBRARIES = libmem.a libstring.a libconffile.a

backup_manager_preferences_SOURCES = \
	main.c \
	customconfig.h \
	callbacks.c callbacks.h 

libmem_a_SOURCES = \
	mem_manager.c mem_manager.h

libstring_a_SOURCES = \
	strLcpy.c strLcpy.h

libconffile_a_SOURCES = \
	bm-libconf.c bm-libconf.h

backup_manager_preferences_LDADD = @PACKAGE_LIBS@ $(INTLLIBS) libmem.a libconffile.a libstring.a

