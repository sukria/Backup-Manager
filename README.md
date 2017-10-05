Backup Manager
==============

**A really simple to use backup tool**

https://github.com/sukria/Backup-Manager/


Description
-----------

Backup Manager is a command line backup tool for GNU/Linux, designed to help
you make daily archives of your file system, while being as easy to use as
possible. Written in Bash and Perl, it can generate archives in various formats
and compression schemes, and can be run in parallel with multiple configuration
files.

Archives are kept for a given number of days and can be uploaded automatically
to a list of remote hosts or burnt automatically to a CD or DVD. The
configuration file is very simple and easy to tune up according to your needs.
Gettext is used for internationalization.


Features
--------

### Easy and automatic operation

- 1 configuration file, 5 minutes setup.
- Manually invoke backup process or run daily unattended via CRON.

### Comprehensive Backup

- Backup files, MySQL and PostgreSQL databases, Subversion repositories.
- Specify multiple targets to backup at once (`/etc`, `/home`, etc…).
- Ability to exclude files from backup.
- Automatically purge old backups.

### Backup Methods

- Full backup only or Full + Incremental backup.
- Archives formats: tar, tar.gz, tar.bz2, tar.xz, tar.lzma, dar, zip.
- Backup to an attached disk, LAN or Internet.
- Burns backup to CD/DVD with MD5 checksum verification.
- Slice archives to 2 GB if using dar archives format.

### Secure

- Backup over SSH.
- Encrypt archives.
- Offsite remote upload of archives via FTP, SSH, RSYNC or Amazon S3.

### Advanced

- Can run with different configuration files concurrently.
- Easy external hooks.

### Restoration

- Simply uncompressed the open format backup archives with any command line or
  GUI tool.


Installation
------------

See the INSTALL.md file.


Reporting Bugs
--------------

Use the GitHub bug tracking system:
https://github.com/sukria/Backup-Manager/issues
