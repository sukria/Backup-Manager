DESTDIR?=

# For the backup-manager package
PERL5DIR=$(DESTDIR)/usr/share/perl5
LIBDIR=$(DESTDIR)/usr/share/backup-manager
SHAREDIR=$(DESTDIR)/usr/share/backup-manager
SHFILES=lib/dialog.sh \
	lib/files.sh \
	lib/actions.sh \
	lib/gettext.sh \
	lib/gettext-real.sh \
	lib/gettext-dummy.sh \
	lib/md5sum.sh 

# For the backup-manager-doc package
DOCDIR		= $(DESTDIR)/usr/share/doc/backup-manager
DOCHTMLDIR 	= $(DOCDIR)/user-guide.html
DOCPDF		= doc/user-guide.pdf
DOCHTMLFILES	= doc/user-guide.html/*.html
DOCPDF		= doc/user-guide.pdf
DOCTXT		= doc/user-guide.txt

# The backup-manager package
install_binary: doc install_lib install_deb install_po

# The backup-manager-doc package
install_doc: 
	@echo -e "\n*** Building the User Guide ***\n"
	$(MAKE) -C doc
	install -d $(DOCDIR)
	install --owner=root --group=root --mode=0644 $(DOCPDF) $(DOCDIR)
	install --owner=root --group=root --mode=0644 $(DOCTXT) $(DOCDIR)
	install -d $(DOCHTMLDIR)
	install --owner=root --group=root --mode=0644 $(DOCHTMLFILES) $(DOCHTMLDIR)

# The translation stuff
install_po:
	@echo -e "\n*** generating po files ***\n"
	$(MAKE) -C po install

# The backup-manager libraries
install_lib:
	@echo -e "\n*** Installing libraries ***\n"
	install -d $(LIBDIR)
	install --owner=root --group=root --mode=0644 $(SHFILES) $(LIBDIR)

# The main stuff to build the backup-manager package
install_deb:
	@echo -e "\n*** Installing scripts ***\n"
	mkdir -p $(DESTDIR)/usr/sbin
	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(SHAREDIR)
	install --owner=root --group=root --mode=0755 backup-manager $(DESTDIR)/usr/sbin
	install --owner=root --group=root --mode=0755 backup-manager-upload $(DESTDIR)/usr/bin
	install --owner=root --group=root --mode=0644 backup-manager.conf.tpl $(SHAREDIR)
	
	mkdir -p $(PERL5DIR)
	mkdir -p $(PERL5DIR)/BackupManager
	install --owner=root --group=root --mode=0644 BackupManager/*.pm $(PERL5DIR)/BackupManager

# generating the manpage from the perl scripts.
doc:
	@echo -e "\n*** generating manpages ***\n"
	PERL5LIB=. pod2man --center="backup-manager-upload" backup-manager-upload > man/backup-manager-upload.3

# Installing the man pages.
install_man:
	@echo -e "\n*** Installing man pages ***\n"
	install -d /usr/share/man/man3/
	install --owner=root --group=root --mode=0644 man/*.3 /usr/share/man/man3/

# Quick :)
deb:
	fakeroot dpkg-buildpackage -us -uc

clean:
	rm -f build-stamp
	rm -rf debian/backup-manager
	$(MAKE) -C po clean

