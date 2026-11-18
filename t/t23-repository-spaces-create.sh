#! /usr/bin/env bash

set -e

# Each test script should include testlib.sh
source testlib.sh
# verbose="true"
# warnings="true"

source confs/base.conf
source confs/tarball.conf

export BM_REPOSITORY_ROOT="$PWD/spaced repo"
export BM_REPOSITORY_SECURE="true"
export BM_REPOSITORY_USER="$(id -un)"
export BM_REPOSITORY_GROUP="$(id -gn)"
export BM_REPOSITORY_CHMOD="750"
export BM_ARCHIVE_TTL="3"
export BM_ARCHIVE_STRICTPURGE="false"
export BM_REPOSITORY_RECURSIVEPURGE="false"
source $locallib/sanitize.sh

function clean()
{
    # "spaced" and "repo" are what the unquoted mkdir used to create
    rm -rf "$PWD/spaced repo" "$PWD/spaced" "$PWD/repo"
}

bm_init_env
bm_init_today
clean

create_directories
[[ -d "$BM_REPOSITORY_ROOT" ]] || { clean; exit 10; }
[[ ! -e "$PWD/repo" ]] || { clean; exit 11; }
[[ "$(stat -c %a "$BM_REPOSITORY_ROOT")" = "750" ]] || { clean; exit 12; }

old_date=$(date +%Y%m%d --date "10 days ago")
old_archive="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-etc.$old_date.tar.gz"
new_archive="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-etc.$TODAY.tar.gz"
touch "$old_archive" "$new_archive"

clean_repositories
[[ ! -e "$old_archive" ]] || { clean; exit 13; }
[[ -e "$new_archive" ]] || { clean; exit 14; }

clean
exit 0
