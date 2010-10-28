#! /usr/bin/env bash

# This will assist you for upgrading a conffile of version prior
# to 0.5.9.
#
# Usage:
#    upgrade-conffile.sh <CONFFILE>
#
# It will replace every deprecated confiugration key with the new name
# and will show you the diff before applying it.

set -e

for file in "$1"
do
	sed \
	-e 's/BM_ARCHIVES_REPOSITORY/BM_REPOSITORY_ROOT/g' \
	-e 's/BM_USER/BM_REPOSITORY_USER/g' \
	-e 's/BM_GROUP/BM_REPOSITORY_GROUP/g' \
	-e 's/BM_MAX_TIME_TO_LIVE/BM_ARCHIVE_TTL/g' \
	-e 's/BM_PURGE_DUPLICATES/BM_ARCHIVE_PURGEDUPS/g' \
	-e 's/BM_ARCHIVES_PREFIX/BM_ARCHIVE_PREFIX/g' \
	-e 's/BM_FILETYPE/BM_TARBALL_FILETYPE/g' \
	-e 's/BM_BACKUP_METHOD/BM_ARCHIVE_METHOD/g' \
	-e 's/BM_NAME_FORMAT/BM_TARBALL_NAMEFORMAT/g' \
	-e 's/BM_DUMP_SYMLINKS/BM_TARBALL_DUMPSYMLINKS/g' \
	-e 's/BM_DIRECTORIES_BLACKLIST/BM_TARBALL_BLACKLIST/g' \
	-e 's/BM_DIRECTORIES/BM_TARBALL_DIRECTORIES/g' \
	-e 's/BM_FTP_PURGE/BM_UPLOAD_FTPPURGE/g' < $file > $file.tmp
	
	diff -ubB $file $file.tmp | less
	
	echo -n "Apply changes to $file? [y/N] "
	read ret
	if [[ -z $ret ]]; then
		ret="n"
	fi
	if [[ $ret = y ]] || [[ $ret = Y ]]; then
		mv $file.tmp $file
	fi
	rm -f $file.tmp
done
