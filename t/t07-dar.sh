#!/bin/sh
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

export TEST_FILES_SUBDIR=test

export BM_ARCHIVE_ROOT="repository"
export BM_ARCHIVE_METHOD="tarball-incremental"
export BM_TARBALL_DIRECTORIES="$PWD/$TEST_FILES_SUBDIR"
export BM_TARBALL_FILETYPE="dar"
export BM_TARBALLINC_MASTERDATETYPE="weekly"
export BM_TARBALLINC_MASTERDATEVALUE="1"

source $locallib/sanitize.sh

if [[ ! -x $dar ]]; then
    info "cannot run test, need $dar"
    exit 1
fi

# The test actions

rm -rf $TEST_FILES_SUBDIR
mkdir -p $TEST_FILES_SUBDIR
mkdir $TEST_FILES_SUBDIR/dir1
touch $TEST_FILES_SUBDIR/file1

if [[ -e $BM_ARCHIVE_ROOT ]]; then
    rm -f $BM_ARCHIVE_ROOT/*
fi    

bm_init_env
bm_init_today
create_directories
make_archives

name=$(get_dir_name $BM_TARBALL_DIRECTORIES long)
if [[ -e "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.master.1.dar" ]]; then
    rm -rf $BM_ARCHIVE_ROOT
    exit 0
else
    rm -rf $BM_ARCHIVE_ROOT
    exit 1
fi        
