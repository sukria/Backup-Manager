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

export BM_ARCHIVE_ROOT="repository"
export BM_ARCHIVE_METHOD="tarball"

export BM_TARBALL_DIRECTORIES="$PWD/foo-*.d $PWD/bar[0-9][0-9] $PWD/static $PWD/rep-[a-zA-Z\-]*test"
subdirs_to_create="$PWD/foo-bar.d $PWD/foo-foo.d $PWD/bar01 $PWD/bar21 $PWD/static $PWD/rep-sukria-test $PWD/rep-BackupManagertest"
subdirs_to_ignore="foo.d bar-foo rep-132312-test"
source $locallib/sanitize.sh

# The test actions

if [ -e $BM_ARCHIVE_ROOT ]; then
    rm -f $BM_ARCHIVE_ROOT/*
fi    

for dir in "$subdirs_to_ignore $subdirs_to_create"
do
    mkdir -p $dir        
done

bm_init_env
bm_init_today
create_directories
make_archives


err_code=0
for dir in $subdirs_to_create
do
    name=$(get_dir_name $dir long)
    if [ ! -e "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.master.tar.gz" ]; then
        err_code=$(($err_code + 1))
        echo "ERR: $BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX-$name.$TODAY.master.tar.gz"
    fi        
done

rm -rf $BM_ARCHIVE_ROOT
for dir in "$subdirs_to_ignore $subdirs_to_create"
do
    rm -rf $dir        
done

exit $err_code

