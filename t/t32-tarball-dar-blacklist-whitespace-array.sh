#! /usr/bin/env bash

set -e

source testlib.sh
source confs/base.conf

# Issue #82: array blacklist with spaces, dar filetype (-P switch).
export BM_REPOSITORY_ROOT="$PWD/repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_NAMEFORMAT="long"
export BM_TARBALL_FILETYPE="dar"
export BM_TARBALL_DUMPSYMLINKS="false"
export BM_TARBALL_DIRECTORIES="$PWD/var/www/"

declare -a BM_TARBALL_BLACKLIST
BM_TARBALL_BLACKLIST[0]="$PWD/var/www/dir with spaces"
BM_TARBALL_BLACKLIST[1]="$PWD/var/www/xim"

source $locallib/sanitize.sh

if [[ ! -x $dar ]]; then
    info "cannot run test, need $dar"
    exit 1
fi

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
archive="$BM_ARCHIVE_PREFIX$name.$TODAY.master.1.dar"
archive_name="$BM_ARCHIVE_PREFIX$name.$TODAY.master"

ret=0
if [[ -e $BM_REPOSITORY_ROOT/$archive ]]; then
    tempfile=$(mktemp)
    dar -l $BM_REPOSITORY_ROOT/$archive_name > $tempfile
    if grep -F "file3" $tempfile >/dev/null ||
       grep -F "file2" $tempfile >/dev/null; then
        warning "Archive seems to have the blacklisted dirs"
        ret=1
    fi
    if ! grep -F "file4" $tempfile >/dev/null; then
        warning "Archive misses file4"
        ret=1
    fi
    rm -f $tempfile
else
    warning "$archive doesn't exists"
    ret=1
fi

rm -rf $PWD/var $PWD/repository
exit $ret
