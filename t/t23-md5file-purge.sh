#! /usr/bin/env bash

set -e

# Each test script should include testlib.sh
source testlib.sh
# When the test is ready, set this to false for nice outputs.
# if you want to see what happens, use those flags
# verbose="true"
# warnings="true"

# The conffile part of the test, see confs/* for details.
source confs/base.conf
source confs/tarball.conf

export BM_REPOSITORY_ROOT="repository"
export BM_ARCHIVE_TTL="3"
export BM_REPOSITORY_RECURSIVEPURGE="false"
export BM_ARCHIVE_STRICTPURGE="false"
source $locallib/sanitize.sh

bm_init_env
bm_init_today

rm -rf $BM_REPOSITORY_ROOT
create_directories

date_today=$(date +"%Y%m%d")
date_5_days_ago=$(date +"%Y%m%d" --date "5 days ago")

fresh="$BM_ARCHIVE_PREFIX-etc.$date_today.tar.gz"
obsolete="$BM_ARCHIVE_PREFIX-etc.$date_5_days_ago.tar.gz"
ancient="$BM_ARCHIVE_PREFIX-etc.20170101.tar.gz"

touch "$BM_REPOSITORY_ROOT/$fresh"
touch "$BM_REPOSITORY_ROOT/$obsolete"

echo "d41d8cd98f00b204e9800998ecf8427e  $ancient" > $MD5FILE
echo "d41d8cd98f00b204e9800998ecf8427e  $obsolete" >> $MD5FILE
echo "d41d8cd98f00b204e9800998ecf8427e  $fresh" >> $MD5FILE
echo "malformed-line-without-separator" >> $MD5FILE

# call the purging system
clean_repositories

# test what it did
error=0
if ! grep -q "  $fresh\$" $MD5FILE; then
    info "entry of $fresh has been removed"
    error=1
fi
if [[ -e "$BM_REPOSITORY_ROOT/$obsolete" ]]; then
    info "$BM_REPOSITORY_ROOT/$obsolete has been kept"
    error=2
fi
if grep -q "  $obsolete\$" $MD5FILE; then
    info "entry of $obsolete has been kept"
    error=3
fi
if grep -q "  $ancient\$" $MD5FILE; then
    info "entry of $ancient has been kept"
    error=4
fi
if ! grep -q "^malformed-line-without-separator\$" $MD5FILE; then
    info "malformed line has been removed"
    error=5
fi

rm -rf $BM_REPOSITORY_ROOT
exit $error
