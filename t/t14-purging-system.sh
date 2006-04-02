#!/bin/sh

set -e

# Each test script should include testlib.sh
source testlib.sh
# When the test is ready, set this to false for nice outputs.
# if you want to see what happens, use those flags
verbose="true"
warnings="true"

# The conffile part of the test, see confs/* for details.
source confs/base.conf
source confs/tarball.conf

export BM_REPOSITORY_ROOT="repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_DIRECTORIES="$PWD"
export BM_ARCHIVE_TTL="3"

# The test actions

if [ -e $BM_REPOSITORY_ROOT ]; then
    rm -f $BM_REPOSITORY_ROOT/*
fi    

date_today=$(date +"%Y%m%d")
date_1_days_ago=$(date +"%Y%m%d" --date "1 days ago")
date_2_days_ago=$(date +"%Y%m%d" --date "2 days ago")
date_3_days_ago=$(date +"%Y%m%d" --date "3 days ago")
date_4_days_ago=$(date +"%Y%m%d" --date "4 days ago")

bm_init_env
bm_init_today

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

# call the purging system
clean_directory "$BM_REPOSITORY_ROOT"

# test what it did
if [ -e $BM_REPOSITORY_ROOT/ouranos-$date_4_days_ago.md5 ]; then
    info "$BM_REPOSITORY_ROOT/ouranos-$date_4_days_ago.md5 exists"
    exit 1
fi

if [ ! -e $BM_REPOSITORY_ROOT/ouranos01-usr-local-bin.$date_4_days_ago.master.tar.bz2 ]; then
    info "$BM_REPOSITORY_ROOT/ouranos01-usr-local-bin.$date_4_days_ago.master.tar.bz2 has been removed"
    exit 2
fi

if [ ! -e $BM_REPOSITORY_ROOT/passwd ]; then
    info "$BM_REPOSITORY_ROOT/passwd has been removed"
    exit 3
fi

if [ ! -e $BM_REPOSITORY_ROOT/ouranos-01020102-fdisk.incremental-list.txt ] ||
   [ ! -e $BM_REPOSITORY_ROOT/ouranos01020102-fdisk.incremental-list.txt ]; then
    info "files with 8 digits in their prefix removed"
    exit 4
fi

exit 0

