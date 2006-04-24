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
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_DIRECTORIES="$PWD/testdir"
export BM_TARBALLINC_MASTERDATETYPE="weekly"
export BM_TARBALL_FILETYPE="tar.gz"
export BM_ARCHIVE_PURGEDUPS="true"

# This test is for incremental backups, we don't want master backups!
export BM_TARBALLINC_MASTERDATEVALUE="999"

bm_init_env
bm_init_today
YESTERDAY=$(date +%Y%m%d --date '1 days ago')
TODAY=$YESTERDAY

# The test actions
rm -rf $BM_REPOSITORY_ROOT
rm -rf testdir

mkdir testdir
mkdir testdir/dir1
cat /etc/passwd > testdir/dir1/file1

create_directories
make_archives

name=$(get_dir_name "$PWD/testdir" long)
if [ -e "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$YESTERDAY.master.tar.gz" ]; then

    bm_init_today
    make_archives
    
    if [ -L "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$YESTERDAY.master.tar.gz" ]; then
        info "Duplicate has been purged, succes."
        exit 0
    else
        warning "Duplicate has not been purged, failure."
        exit 1
    fi
else
    exit 20
fi        
