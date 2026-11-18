#! /usr/bin/env bash

set -e

source testlib.sh
# verbose="true"
# warnings="true"

source confs/base.conf

export BM_REPOSITORY_ROOT="$PWD/spaced repo"
source $locallib/sanitize.sh

function clean()
{
    rm -rf "$PWD/spaced repo" "$PWD/spaced" "$PWD/repo"
}

bm_init_env
bm_init_today
clean
create_directories

first="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-etc.$TODAY.txt"
second="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-usr.$TODAY.txt"
touch "$first" "$second"

listing=$($bmu --list -m=scp -h=localhost -u="$(id -un)" -r="$BM_REPOSITORY_ROOT" "$TODAY")
echo "$listing" | grep -qxF -- "- $first" || { clean; exit 10; }
echo "$listing" | grep -qxF -- "- $second" || { clean; exit 11; }

clean
exit 0
