#!/bin/sh

set -e

if [ "$UID" != 0 ]; then
    echo "This test fails without root"
    exit 1
fi

# Each test script should include testlib.sh
source testlib.sh
# When the test is ready, set this to false for nice outputs.
# if you want to see what happens, use those flags
# verbose="true"
# warnings="true"

# The conffile part of the test, see confs/* for details.
source confs/base.conf
source confs/tarball.conf

export BM_ARCHIVE_ROOT="repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_DIRECTORIES="/etc"

# The test actions

if [ -e $BM_ARCHIVE_ROOT ]; then
    rm -f $BM_ARCHIVE_ROOT/*
fi    

init_default_vars
create_archive_root_if_not_exists
make_archives

if [ -e "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX-etc.$TODAY.tar.gz" ]; then
    exit 0
else
    exit 1
fi        
