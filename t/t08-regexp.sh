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

export BM_TARBALL_DIRECTORIES="foo-*.d bar[0-9][0-9] static"
subdirs_to_create="foo-bar.d foo-foo.d bar01 bar21 static"
subdirs_to_ignore="foo.d bar-foo"

# The test actions

if [ -e $BM_ARCHIVE_ROOT ]; then
    rm -f $BM_ARCHIVE_ROOT/*
fi    


for dir in "$subdirs_to_ignore $subdirs_to_create"
do
    mkdir -p $dir        
done

bm_init_env
create_archive_root_if_not_exists
make_archives


err_code=0
for dir in $subdirs_to_create
do
    name=$(get_dir_name $dir long)
    if [ ! -e "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz" ]; then
        err_code=$(($err_code + 1))
        echo "ERR: $BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX-$name.$TODAY.tar.gz"
    fi        
done
exit $err_code

