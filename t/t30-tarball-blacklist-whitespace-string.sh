#! /usr/bin/env bash

set -e

source testlib.sh
source confs/base.conf

# Issue #82: a blacklisted directory with spaces, using the '?' workaround
# in the space-separated string form.
export BM_REPOSITORY_ROOT="$PWD/repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_NAMEFORMAT="long"
export BM_TARBALL_FILETYPE="tar.gz"
export BM_TARBALL_DUMPSYMLINKS="false"
export BM_TARBALL_DIRECTORIES="$PWD/var/www/"
export BM_TARBALL_BLACKLIST="$PWD/var/www/dir?with?spaces $PWD/var/www/xim"

# verbose="true"
# warnings="true"
source $locallib/sanitize.sh

rm -rf $PWD/var $PWD/repository

mkdir -p "$PWD/var/www/real" "$PWD/var/www/xim" "$PWD/var/www/dir with spaces"
touch "$PWD/var/www/real/file4"
touch "$PWD/var/www/xim/file2"
touch "$PWD/var/www/dir with spaces/file3"

bm_init_env
bm_init_today
create_directories
make_archives

name=$(get_dir_name "$PWD/var/www" "long")
archive="$BM_ARCHIVE_PREFIX$name.$TODAY.master.tar.gz"

ret=0
if [[ -e $BM_REPOSITORY_ROOT/$archive ]]; then
    tempfile=$(mktemp)
    tar tzf $BM_REPOSITORY_ROOT/$archive > $tempfile
    if grep -F "dir with spaces/file3" $tempfile >/dev/null ||
       grep -F "xim/file2" $tempfile >/dev/null; then
        warning "Archive seems to have the blacklisted dirs"
        ret=1
    fi
    if ! grep -F "real/file4" $tempfile >/dev/null; then
        warning "Archive misses real/file4"
        ret=1
    fi
    rm -f $tempfile
else
    warning "$archive doesn't exists"
    ret=1
fi

rm -rf $PWD/var $PWD/repository
exit $ret
