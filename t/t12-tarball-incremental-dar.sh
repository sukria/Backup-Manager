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
# This test is for incremental backups, we don't want master backups!
export BM_TARBALLINC_MASTERDATEVALUE="999"

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
    YESTERDAY=$(date +%Y%m%d --date '1 days ago')

    mv "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.master.1.dar" "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$YESTERDAY.master.1.dar"
    mkdir $TEST_FILES_SUBDIR/dir2
    touch $TEST_FILES_SUBDIR/file2
    make_archives

    # Now make sure file2 and dir2 are not saved in last darball
    for file in file1 dir1 
    do
        saved=$(dar -l $BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$YESTERDAY.master | grep $file | awk '{print $1}')
        if [[ "$saved" == "[saved]" ]]; then
            warning "$file is saved in last archive, shouldn't."
            rm -rf $BM_TARBALL_DIRECTORIES
            rm -rf repository
            exit 1
        fi
    done
    rm -rf $BM_TARBALL_DIRECTORIES
    rm -rf repository
    exit 0
else
    rm -rf $BM_TARBALL_DIRECTORIES
    rm -rf repository
    exit 1
fi        
