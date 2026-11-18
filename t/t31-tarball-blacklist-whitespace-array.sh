#! /usr/bin/env bash

set -e

source testlib.sh
source confs/base.conf

# Issue #82: BM_TARBALL_BLACKLIST given as an array, entries may contain spaces.
export BM_REPOSITORY_ROOT="$PWD/repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_NAMEFORMAT="long"
export BM_TARBALL_FILETYPE="tar.gz"
export BM_TARBALL_DUMPSYMLINKS="false"

declare -a BM_TARBALL_TARGETS
BM_TARBALL_TARGETS[0]="$PWD/var/www/"
BM_TARBALL_TARGETS[1]="$PWD/skipped target"

declare -a BM_TARBALL_BLACKLIST
BM_TARBALL_BLACKLIST[0]="$PWD/var/www/dir with spaces"
BM_TARBALL_BLACKLIST[1]="other dir"
BM_TARBALL_BLACKLIST[2]="$PWD/var/www/xim"
BM_TARBALL_BLACKLIST[3]="$PWD/skipped target/"

# verbose="true"
# warnings="true"
source $locallib/sanitize.sh

rm -rf $PWD/var $PWD/repository "$PWD/skipped target"

mkdir -p "$PWD/var/www/real/other dir" "$PWD/var/www/xim" "$PWD/var/www/dir with spaces"
mkdir -p "$PWD/skipped target"
touch "$PWD/var/www/real/file4"
touch "$PWD/var/www/real/other dir/file5"
touch "$PWD/var/www/xim/file2"
touch "$PWD/var/www/dir with spaces/file3"
touch "$PWD/skipped target/file6"

bm_init_env
bm_init_today
create_directories
make_archives

name=$(get_dir_name "$PWD/var/www" "long")
archive="$BM_ARCHIVE_PREFIX$name.$TODAY.master.tar.gz"
skipped_name=$(get_dir_name "$PWD/skipped target" "long")
skipped_archive="$BM_ARCHIVE_PREFIX$skipped_name.$TODAY.master.tar.gz"

ret=0
if [[ -e $BM_REPOSITORY_ROOT/$archive ]]; then
    tempfile=$(mktemp)
    tar tzf $BM_REPOSITORY_ROOT/$archive > $tempfile
    for excluded in "dir with spaces/file3" "other dir/file5" "xim/file2"; do
        if grep -F "$excluded" $tempfile >/dev/null; then
            warning "Archive contains blacklisted $excluded"
            ret=1
        fi
    done
    if ! grep -F "real/file4" $tempfile >/dev/null; then
        warning "Archive misses real/file4"
        ret=1
    fi
    rm -f $tempfile
else
    warning "$archive doesn't exists"
    ret=1
fi

if [[ -e "$BM_REPOSITORY_ROOT/$skipped_archive" ]]; then
    warning "Blacklisted target was archived: $skipped_archive"
    ret=1
fi

rm -rf $PWD/var $PWD/repository "$PWD/skipped target"
exit $ret
