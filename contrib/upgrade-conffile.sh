#! /usr/bin/env bash

# This will assist you for upgrading a conffile that still uses
# configuration keys that have been renamed, or "yes"/"no" booleans.
# Backup Manager refuses to run with those, see the "Renamed configuration
# keys" section of the user guide.
#
# Usage:
#    upgrade-conffile.sh <CONFFILE>
#
# It will replace every deprecated configuration key with the new name
# and will show you the diff before applying it.
#
# BM_UPLOAD_USER used to set both BM_UPLOAD_SSH_USER and BM_UPLOAD_FTP_USER,
# so its assignment is replaced by both of them, and the other references to
# it by BM_UPLOAD_SSH_USER, which holds the same value.

set -e

# Matches the beginning of an assignment, up to the equal sign.
assignment='^\([[:space:]]*\(export[[:space:]]\+\)\?BM_[A-Z0-9_]*=\)'

for file in "$1"
do
	sed \
	-e 's/\bBM_ARCHIVES_REPOSITORY\b/BM_REPOSITORY_ROOT/g' \
	-e 's/\bBM_USER\b/BM_REPOSITORY_USER/g' \
	-e 's/\bBM_GROUP\b/BM_REPOSITORY_GROUP/g' \
	-e 's/\bBM_MAX_TIME_TO_LIVE\b/BM_ARCHIVE_TTL/g' \
	-e 's/\bBM_PURGE_DUPLICATES\b/BM_ARCHIVE_PURGEDUPS/g' \
	-e 's/\bBM_ARCHIVES_PREFIX\b/BM_ARCHIVE_PREFIX/g' \
	-e 's/\bBM_FILETYPE\b/BM_TARBALL_FILETYPE/g' \
	-e 's/\bBM_BACKUP_METHOD\b/BM_ARCHIVE_METHOD/g' \
	-e 's/\bBM_NAME_FORMAT\b/BM_TARBALL_NAMEFORMAT/g' \
	-e 's/\bBM_DUMP_SYMLINKS\b/BM_TARBALL_DUMPSYMLINKS/g' \
	-e 's/\bBM_DIRECTORIES_BLACKLIST\b/BM_TARBALL_BLACKLIST/g' \
	-e 's/\bBM_DIRECTORIES\b/BM_TARBALL_DIRECTORIES/g' \
	-e 's/\bBM_UPLOAD_MODE\b/BM_UPLOAD_METHOD/g' \
	-e 's/\bBM_UPLOAD_DIR\b/BM_UPLOAD_DESTINATION/g' \
	-e 's/\bBM_UPLOAD_KEY\b/BM_UPLOAD_SSH_KEY/g' \
	-e 's/\bBM_UPLOAD_PASSWD\b/BM_UPLOAD_FTP_PASSWORD/g' \
	-e 's/\bBM_FTP_PURGE\b/BM_UPLOAD_FTP_PURGE/g' \
	-e 's/\bBM_UPLOAD_FTPPURGE\b/BM_UPLOAD_FTP_PURGE/g' \
	-e 's/^\([[:space:]]*\(export[[:space:]]\+\)\?\)BM_UPLOAD_USER=\(.*\)$/\1BM_UPLOAD_SSH_USER=\3\n\1BM_UPLOAD_FTP_USER=\3/' \
	-e 's/\bBM_UPLOAD_USER\b/BM_UPLOAD_SSH_USER/g' \
	-e "/\bBM_ARCHIVE_PREFIX=/!s/${assignment}\([\"']\?\)yes\3\([[:space:]]*\(#.*\)\?\)$/\1\3true\3\4/" \
	-e "/\bBM_ARCHIVE_PREFIX=/!s/${assignment}\([\"']\?\)no\3\([[:space:]]*\(#.*\)\?\)$/\1\3false\3\4/" \
	< "$file" > "$file.tmp"

	diff -ubB "$file" "$file.tmp" | ${PAGER:-less}

	echo -n "Apply changes to $file? [y/N] "
	read ret
	if [[ -z $ret ]]; then
		ret="n"
	fi
	if [[ $ret = y ]] || [[ $ret = Y ]]; then
		mv "$file.tmp" "$file"
	fi
	rm -f "$file.tmp"
done
