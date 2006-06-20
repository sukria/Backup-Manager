#!/bin/sh
# $Revision: $
# $Date: $

set -e

function clean()
{
    rm -rf $BM_ARCHIVE_ROOT
    rm -rf $testdir
#    echo clean
}


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
export BM_TARBALL_FILETYPE="tar.gz"


bm_init_env
bm_init_today

# cleaning
rm -rf $BM_REPOSITORY_ROOT
rm -rf testdir

##############################################################
# first make a master backup of testdir/
#############################################################
master_day=$(date +'%w')
export BM_TARBALLINC_MASTERDATEVALUE="${master_day}"
export BM_TARBALLINC_MASTERDATETYPE="weekly"
TODAY=$(date +%Y%m%d --date '1 days ago')
info "making a master backup for $TODAY"
source $locallib/sanitize.sh

mkdir testdir
mkdir testdir/dir1
cp /etc/passwd testdir/dir1/file1
create_directories
make_archives

# Very important, or tar won't notice differnce between files 
# added before or after that point.
info "Waiting 5 seconds..."
sleep 5
cat /etc/passwd > testdir/dir1/file_new_for_incremental

##############################################################
# then make an incremental backup
#############################################################
bm_init_today
info "making an incremental backup for $TODAY"
cp /etc/group testdir/dir1
touch testdir/newfile-only-incremental

# frocing incremental backup with a false value
export BM_TARBALLINC_MASTERDATEVALUE="999"
export BM_TARBALLINC_MASTERDATETYPE="weekly"

make_archives

##############################################################
# Testing backups content
#############################################################
info "Testing content"
YESTERDAY=$(date +%Y%m%d --date '1 days ago')
name=$(get_dir_name "$PWD/testdir" long)

if [ -e "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$YESTERDAY.master.tar.gz" ]; then

    # Now make sure file2 and dir2 are not saved in last darball
    for file in file1
    do
        grep=`tar tvzf $BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz 2>/dev/null | grep $file` || true

        if [ -n "$grep" ]; then
            warning "$file is saved in last archive, shouldn't."
            if [ $verbose == true ]; then
                tar tvzf $BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz
            fi
            clean
            exit 10
        fi
    done
    clean
    exit 0
else
    clean
    exit 20
fi        
