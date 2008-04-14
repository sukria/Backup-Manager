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

export BM_REPOSITORY_ROOT="repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_DIRECTORIES="$PWD"
export BM_ARCHIVE_TTL="3"
# Test the purge with BM_REPOSITORY_RECURSIVEPURGE set to false
export BM_REPOSITORY_RECURSIVEPURGE="false"
export BM_ARCHIVE_STRICTPURGE="false"
source $locallib/sanitize.sh

# The test actions

if [[ -e $BM_REPOSITORY_ROOT ]]; then
    rm -rf $BM_REPOSITORY_ROOT/*
fi    

date_today=$(date +"%Y%m%d")
date_1_days_ago=$(date +"%Y%m%d" --date "1 days ago")
date_2_days_ago=$(date +"%Y%m%d" --date "2 days ago")
date_3_days_ago=$(date +"%Y%m%d" --date "3 days ago")
date_4_days_ago=$(date +"%Y%m%d" --date "4 days ago")

bm_init_env
bm_init_today

function create_test_repository()
{
    create_directories
    
    # a md5 file
    touch $BM_REPOSITORY_ROOT/ouranos-$date_today.md5
    touch $BM_REPOSITORY_ROOT/ouranos-$date_1_days_ago.md5
    touch $BM_REPOSITORY_ROOT/ouranos-$date_2_days_ago.md5
    touch $BM_REPOSITORY_ROOT/ouranos-$date_3_days_ago.md5
    touch $BM_REPOSITORY_ROOT/ouranos-$date_4_days_ago.md5

    # some files
    touch $BM_REPOSITORY_ROOT/ouranoqsdq.md5
    touch $BM_REPOSITORY_ROOT/foo-bar.txt
    touch $BM_REPOSITORY_ROOT/passwd

    # Some archives of /usr/loca/bin
    touch $BM_REPOSITORY_ROOT/ouranos01-usr-local-bin.incremental-list.txt
    touch $BM_REPOSITORY_ROOT/ouranos01-usr-local-bin.$date_today.tar.bz2
    touch $BM_REPOSITORY_ROOT/ouranos01-usr-local-bin.$date_1_days_ago.tar.bz2
    touch $BM_REPOSITORY_ROOT/ouranos01-usr-local-bin.$date_2_days_ago.tar.bz2
    touch $BM_REPOSITORY_ROOT/ouranos01-usr-local-bin.$date_3_days_ago.tar.bz2
    # deprecated but should not be removed, as master.
    touch $BM_REPOSITORY_ROOT/ouranos01-usr-local-bin.$date_4_days_ago.master.tar.bz2 

    # some deprecated master backup isolated, should be removed
    touch $BM_REPOSITORY_ROOT/ouranos01-home-sukria.$date_4_days_ago.master.tar.bz2

    # Some master archive
    touch $BM_REPOSITORY_ROOT/ouranos-etc.$date_1_days_ago.master.txt
    touch $BM_REPOSITORY_ROOT/ouranos-etc.$date_2_days_ago.master.txt
    touch $BM_REPOSITORY_ROOT/ouranos-etc.$date_3_days_ago.master.txt
    touch $BM_REPOSITORY_ROOT/ouranos-etc.$date_4_days_ago.master.txt

    # an archive with a prefix containing 8 digits
    touch $BM_REPOSITORY_ROOT/ouranos-01020102-fdisk.incremental-list.txt
    touch $BM_REPOSITORY_ROOT/ouranos01020102-fdisk.incremental-list.txt
}

function create_test_repository_subdirs()
{
    for dir in subdir1 subdir2 subdir3 subdir4
    do
        mkdir -p $BM_REPOSITORY_ROOT/$dir
        touch "$BM_REPOSITORY_ROOT/$dir/host-path-to-dir.$date_1_days_ago.master.txt"
        touch "$BM_REPOSITORY_ROOT/$dir/host-path-to-dir.$date_2_days_ago.txt"
        touch "$BM_REPOSITORY_ROOT/$dir/host-path-to-dir.$date_3_days_ago.txt"
        touch "$BM_REPOSITORY_ROOT/$dir/host-path-to-dir.$date_4_days_ago.txt"
    done
}


# build the repository
create_test_repository
create_test_repository_subdirs

# call the purging system
clean_directory "$BM_REPOSITORY_ROOT"

# test what it did
error=0
if [[ -e $BM_REPOSITORY_ROOT/ouranos-$date_4_days_ago.md5 ]]; then
    info "$BM_REPOSITORY_ROOT/ouranos-$date_4_days_ago.md5 exists"
    error=1
fi

if [[ ! -e $BM_REPOSITORY_ROOT/ouranos01-usr-local-bin.$date_4_days_ago.master.tar.bz2 ]]; then
    info "$BM_REPOSITORY_ROOT/ouranos01-usr-local-bin.$date_4_days_ago.master.tar.bz2 has been removed"
    error=2
fi

if [[ ! -e $BM_REPOSITORY_ROOT/passwd ]]; then
    info "$BM_REPOSITORY_ROOT/passwd has been removed"
    error=3
fi
if [[ ! -e $BM_REPOSITORY_ROOT/ouranos-01020102-fdisk.incremental-list.txt ]] ||
   [[ ! -e $BM_REPOSITORY_ROOT/ouranos01020102-fdisk.incremental-list.txt ]]; then
    info "files with 8 digits in their prefix removed"
    error=4
fi

# the archive under a depth greater than 0 should not be purged
if [[ ! -e "$BM_REPOSITORY_ROOT/subdir1/host-path-to-dir.$date_4_days_ago.txt" ]]; then
    info "archive $BM_REPOSITORY_ROOT/subdir1/host-path-to-dir.$date_4_days_ago.txt does not exist."
    error=5
fi    
rm -rf $BM_REPOSITORY_ROOT

# Test the purging system in recursive mode
export BM_REPOSITORY_RECURSIVEPURGE="true"

create_test_repository
create_test_repository_subdirs
clean_directory "$BM_REPOSITORY_ROOT"

# the archive under a depth greater than 0 should be purged
if [[ -e "$BM_REPOSITORY_ROOT/subdir1/host-path-to-dir.$date_4_days_ago.txt" ]]; then
    info "archive $BM_REPOSITORY_ROOT/subdir1/host-path-to-dir.$date_4_days_ago.txt exists."
    error=5
fi

# rm -rf $BM_REPOSITORY_ROOT
exit $error

