#!/bin/sh

set -e

source testlib.sh
#verbose="true"
#warnings="true"

source confs/base.conf

# taken verbatim from file attached to bug #4
# http://bugzilla.backup-manager.org/cgi-bin/attachment.cgi?id=1&action=view
export BM_REPOSITORY_ROOT="$PWD/repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_NAMEFORMAT="long"
export BM_TARBALL_FILETYPE="dar"
export BM_TARBALL_DUMPSYMLINKS="no"
export BM_TARBALL_DIRECTORIES="$PWD/var/www/"
export BM_TARBALL_BLACKLIST="$PWD/var/www/xim $PWD/var/www/Upload/ /tmp/ titi"

# clean
if [ -e $PWD/var ]; then
    rm -rf $PWD/var
fi        
if [ -e $PWD/repository ]; then
    rm -rf $PWD/repository
fi    

# environement
mkdir $PWD/var
mkdir $PWD/var/www
mkdir $PWD/var/www/real
mkdir $PWD/var/www/xim
mkdir $PWD/var/www/Upload
touch $PWD/var/www/file1
touch $PWD/var/www/xim/file2
touch $PWD/var/www/Upload/file3
touch $PWD/var/www/real/file4

# BM actions
bm_init_env
bm_init_today
create_directories
make_archives

# test of success/failure
name=$(get_dir_name "$PWD/var/www" "long")
archive="$BM_ARCHIVE_PREFIX$name.$TODAY.master.1.dar"
archive_name="$BM_ARCHIVE_PREFIX$name.$TODAY.master"

if [ -e $BM_REPOSITORY_ROOT/$archive ]
then
        tempfile=$(mktemp)
        dar -l $BM_REPOSITORY_ROOT/$archive_name > $tempfile
        
        if grep "xim/file2" $tempfile >/dev/null
        then
           warning "Archive seems to have the blacklisted dirs:"
           if [ "$warnings" = "true" ]; then
                echo "BM_TARBALL_BLACKLIST = $BM_TARBALL_BLACKLIST"
                cat $tempfile
           fi
           rm -f $tempfile
           exit 1
        else
            rm -f $tempfile
            exit 0
        fi                
else
    warning "$archive doesn't exists"
    exit 1
fi    

