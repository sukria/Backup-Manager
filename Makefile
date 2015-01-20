# Copyright © 2005-2010 The Backup Manager Authors
# See the AUTHORS file for details.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

# Makefile for Backup Manager written by Alexis Sukrieh, 
# smart ideas for finding out perl libraries' destination come 
# from Thomas Parmelan.

# $Revision$
# $Date$
# $Author$


# Overwrite that variable if you need to prefix the destination 
# (needed for vendors).
DESTDIR?=
PREFIX?=/usr/local

# Overwrite that variable with the Perl vendorlib Config value if 
# you package Backup Manager
## PERL5DIR?="$(DESTDIR)$(shell perl -MConfig -e 'print "$$Config{sitelib}"')"
PERL5DIR?=/usr/share/perl5

# Some static paths, specific to backup-manager
BINDIR=$(PREFIX)/bin
SBINDIR=$(PREFIX)/sbin
VARDIR=$(PREFIX)/var

LIBDIR=$(DESTDIR)/$(PREFIX)/lib/backup-manager
CONTRIB=$(LIBDIR)/contrib
SHAREDIR=$(DESTDIR)/$(PREFIX)/share/backup-manager
SHFILES=\
	lib/externals.sh \
	lib/dialog.sh \
	lib/files.sh \
	lib/actions.sh \
	lib/dbus.sh \
	lib/backup-methods.sh\
	lib/upload-methods.sh\
	lib/burning-methods.sh\
	lib/logger.sh \
	lib/gettext.sh \
	lib/gettext-real.sh \
	lib/gettext-dummy.sh \
	lib/sanitize.sh \
	lib/md5sum.sh 

# For the backup-manager-doc package
DOCDIR		 = $(DESTDIR)/$(PREFIX)/share/doc/backup-manager
DOCHTMLDIR	 = $(DOCDIR)/user-guide.html
DOCPDF		 = doc/user-guide.pdf
DOCHTMLFILES = doc/user-guide.html/*.html
DOCPDF		 = doc/user-guide.pdf
DOCTXT		 = doc/user-guide.txt

# Main build rule (we don't buid the docs as we don't know if debiandocs can be
# there) so the docs target has to be called manually by vendors.
build: manpages 

# The backup-manager package
install: build install_lib install_bin install_contrib install_man install_po
install_binary: build install_lib install_bin 

install_contrib:
	@echo -e "*** Contrib files ***\n"
	install -d $(CONTRIB)
	install -m0755 contrib/*.sh $(CONTRIB)

# The backup-manager-doc package
install_doc: 
	@echo -e "\n*** Building the User Guide ***\n"
	$(MAKE) -C doc DESTDIR=$(DESTDIR)
	install -d $(DOCDIR)
	install -o root -g 0 -m 0644 $(DOCPDF) $(DOCDIR)
	install -o root -g 0 -m 0644 $(DOCTXT) $(DOCDIR)
	install -d $(DOCHTMLDIR)
	install -o root -g 0 -m 0644 $(DOCHTMLFILES) $(DOCHTMLDIR)

# The translation stuff
install_po:
	$(MAKE) -C po install

# The backup-manager libraries
install_lib:
	@echo -e "\n*** Installing libraries ***\n"
	install -d $(LIBDIR)
	install -o root -g 0 -m 0644 $(SHFILES) $(LIBDIR)

# The main stuff to build the backup-manager package
install_bin:
	@echo -e "\n*** Installing scripts ***\n"
	mkdir -p $(DESTDIR)/$(SBINDIR)
	mkdir -p $(DESTDIR)/$(BINDIR)
	mkdir -p $(SHAREDIR)
	install -o root -g 0 -m 0755 backup-manager $(DESTDIR)/$(SBINDIR)
	install -o root -g 0 -m 0755 backup-manager-purge $(DESTDIR)/$(BINDIR)
	install -o root -g 0 -m 0755 backup-manager-upload $(DESTDIR)/$(BINDIR)
	install -o root -g 0 -m 0644 backup-manager.conf.tpl $(SHAREDIR)

	# Set PREFIX to backup-manager binary
	sed "s#^BIN_PREFIX=.*#BIN_PREFIX=$(DESTDIR)/$(BINDIR)#" -i $(DESTDIR)/$(SBINDIR)/backup-manager
	sed "s#^LIB_PREFIX=.*#LIB_PREFIX=$(DESTDIR)/$(PREFIX)/lib#" -i $(DESTDIR)/$(SBINDIR)/backup-manager
	sed "s#^VAR_PREFIX=.*#VAR_PREFIX=$(VARDIR)#" -i $(DESTDIR)/$(SBINDIR)/backup-manager

	mkdir -p $(PERL5DIR)
	mkdir -p $(PERL5DIR)/BackupManager
	install -o root -g 0 -m 0644 BackupManager/*.pm $(PERL5DIR)/BackupManager

# Building manpages
man/backup-manager-upload.8:
	PERL5LIB=. pod2man --section 8 --center="backup-manager-upload" backup-manager-upload > man/backup-manager-upload.8

man/backup-manager-purge.8:
	PERL5LIB=. pod2man --section 8 --center="backup-manager-purge" backup-manager-purge > man/backup-manager-purge.8
	
# build the manpages
manpages: manpages-stamp	
manpages-stamp: man/backup-manager-upload.8 man/backup-manager-purge.8
	touch manpages-stamp

# Installing the man pages.
install_man: manpages-stamp
	@echo -e "\n*** Installing man pages ***\n"
	install -d $(DESTDIR)/$(PREFIX)/share/man/man8/
	install -o root -g 0 -m 0644 man/*.8 $(DESTDIR)/$(PREFIX)/share/man/man8/

testperldir:
	@echo "PERL5DIR: $(PERL5DIR)"

docs:
	make -C doc all

clean:
	rm -f build-stamp
	rm -rf debian/backup-manager
	rm -f man/backup-manager-upload.8
	#rm -f man/*.8
	$(MAKE) -C po clean
	$(MAKE) -C doc clean

