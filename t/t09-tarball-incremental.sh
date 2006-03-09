#!/bin/sh
# $Revision: $
# $Date: $

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

export BM_ARCHIVE_ROOT="repository"
export BM_ARCHIVE_METHOD="tarball-incremental"
export BM_TARBALL_DIRECTORIES="$PWD/test"
export BM_TARBALLINC_MASTERDATETYPE="weekly"
export BM_TARBALL_FILETYPE="tar.gz"

# The test actions

rm -rf test
mkdir -p test
mkdir test/dir1
touch test/file1
cat /etc/passwd > test/passwd

if [ -e $BM_ARCHIVE_ROOT ]; then
    rm -f $BM_ARCHIVE_ROOT/*
fi    

bm_init_env
bm_init_today
create_archive_root_if_not_exists
make_archives

YESTERDAY=$(date +%Y%m%d --date '1 days ago')

name=$(get_dir_name "$PWD/test" long)
if [ -e "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz" ]; then
    mv "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz" "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$YESTERDAY.tar.gz"
    mkdir test/dir2
    touch test/file2
    make_archives

    # Now make sure file2 and dir2 are not saved in last darball
    for file in passwd file1 dir1 
    do
        grep=$(tar zxvf $BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz | grep $file)
        if [ -n "$grep" ]; then
            warning "$file is saved in last archive, shouldn't."
            if [ $verbose == true ]; then
                tar zxvf $BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz
            fi
            exit 1
        fi
    done
    exit 0
else
    exit 1
fi        
