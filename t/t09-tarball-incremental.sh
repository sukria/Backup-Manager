#!/bin/sh
# $Revision: $
# $Date: $

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
export BM_ARCHIVE_METHOD="tarball-incremental"
export BM_TARBALL_DIRECTORIES="$PWD/testdir"
export BM_TARBALLINC_MASTERDATETYPE="weekly"
export BM_TARBALL_FILETYPE="tar.gz"

# This test is for incremental backups, we don't want master backups!
export BM_TARBALLINC_MASTERDATEVALUE="999"

bm_init_env
bm_init_today

# The test actions
rm -rf $BM_REPOSITORY_ROOT
rm -rf testdir

mkdir testdir
mkdir testdir/dir1
cat /etc/passwd > testdir/dir1/file1

# Very important, or tar won't notice differnce between files 
# added before or after that point.
sleep 5

create_directories
make_archives


YESTERDAY=$(date +%Y%m%d --date '1 days ago')
name=$(get_dir_name "$PWD/testdir" long)
if [ -e "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz" ]; then

    mv "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz" "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$YESTERDAY.tar.gz"

    mkdir testdir/dir2
    cp /etc/group testdir/dir2/file2

    make_archives

    
    # Now make sure file2 and dir2 are not saved in last darball
    for file in file1  
    do
        grep=`tar tvzf $BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz 2>/dev/null | grep $file` || true

        if [ -n "$grep" ]; then
            warning "$file is saved in last archive, shouldn't."
            if [ $verbose == true ]; then
                tar tvzf $BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz
            fi
            exit 10
        fi
    done
    exit 0
else
    exit 20
fi        
