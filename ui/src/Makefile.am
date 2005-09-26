## Process this file with automake to produce Makefile.in

INCLUDES = \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	@PACKAGE_CFLAGS@

bin_PROGRAMS = backup-manager-ui test_bm

backup_manager_ui_SOURCES = \
	main.c \
	customconfig.h \
	global_widgets.h \
	support.c support.h \
	mem_manager.c mem_manager.h \
	interface.c interface.h \
	dyn_interfaces.c dyn_interfaces.h \
	bm.c bm.h \
	strLcpy.c strLcpy.h \
	callbacks.c callbacks.h

test_bm_SOURCES = \
	test_bm.c \
	bm.c bm.h \
	mem_manager.c mem_manager.h \
	strLcpy.c strLcpy.h

backup_manager_ui_LDADD = @PACKAGE_LIBS@ $(INTLLIBS)

