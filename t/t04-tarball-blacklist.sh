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
export BM_TARBALL_FILETYPE="tar.gz"
export BM_TARBALL_DUMPSYMLINKS="no"
export BM_TARBALL_DIRECTORIES="$PWD/var/www/"
export BM_TARBALL_BLACKLIST="$PWD/var/www/xim $PWD/var/www/Upload"

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
init_default_vars
create_archive_root_if_not_exists
make_archives

# test of success/failure
name=$(get_dir_name "$PWD/var/www" "long")
archive="$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz"

if [ -e $BM_REPOSITORY_ROOT/$archive ]
then
        tempfile=$(mktemp)
        tar tvzf $BM_REPOSITORY_ROOT/$archive > $tempfile
        
        if grep "xim/file2" $tempfile
        then
           warning "Archive seems to have the blacklisted dirs:"
           if [ "$warnings" = "true" ]; then
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

