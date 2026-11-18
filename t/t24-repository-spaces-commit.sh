#! /usr/bin/env bash

set -e

source testlib.sh
# verbose="true"
# warnings="true"

source confs/base.conf
source confs/tarball.conf

export BM_REPOSITORY_ROOT="$PWD/spaced repo"
export BM_REPOSITORY_SECURE="true"
export BM_REPOSITORY_USER="$(id -un)"
export BM_REPOSITORY_GROUP="$(id -gn)"
export BM_ARCHIVE_PURGEDUPS="true"
source $locallib/sanitize.sh

function clean()
{
    rm -rf "$PWD/spaced repo" "$PWD/spaced" "$PWD/repo"
}

bm_init_env
bm_init_today
clean
create_directories

yesterday=$(date +%Y%m%d --date "1 days ago")
old_archive="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-etc.$yesterday.txt"
new_archive="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-etc.$TODAY.txt"
cp /etc/passwd "$old_archive"
cp /etc/passwd "$new_archive"

# two spaced paths: du rounds the total up to one 1000k block (0 if paths get split)
[[ "$(size_of_path "$old_archive" "$new_archive")" -ge 1 ]] || { clean; exit 10; }

commit_archive "$old_archive"
commit_archive "$new_archive"

grep -qxF "$(md5sum < /etc/passwd | awk '{print $1}')  $(basename "$old_archive")" "$MD5FILE" || { clean; exit 11; }
grep -qxF "$(md5sum < /etc/passwd | awk '{print $1}')  $(basename "$new_archive")" "$MD5FILE" || { clean; exit 12; }
[[ -L "$old_archive" ]] || { clean; exit 13; }
[[ "$(readlink "$old_archive")" = "$new_archive" ]] || { clean; exit 14; }
[[ "$(stat -c %a "$new_archive")" = "660" ]] || { clean; exit 15; }

clean
exit 0
