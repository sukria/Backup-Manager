#! /usr/bin/env bash

set -e

source testlib.sh
source confs/base.conf

# taken verbatim from file attached to bug #4 that previously lived at
# http://bugzilla.backup-manager.org/cgi-bin/attachment.cgi?id=1&action=view
export BM_REPOSITORY_ROOT="$PWD/repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_NAMEFORMAT="long"
export BM_TARBALL_FILETYPE="tar.gz"
export BM_TARBALL_DUMPSYMLINKS="false"
export BM_TARBALL_DIRECTORIES="$PWD/var/www/"
export BM_TARBALL_BLACKLIST="$PWD/var/www/xim $PWD/var/www/Upload"

# verbose="true"
# warnings="true"
source $locallib/sanitize.sh

# clean
if [[ -e $PWD/var ]]; then
    rm -rf $PWD/var
fi        
if [[ -e $PWD/repository ]]; then
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
archive="$BM_ARCHIVE_PREFIX$name.$TODAY.master.tar.gz"

if [[ -e $BM_REPOSITORY_ROOT/$archive ]]
then
        tempfile=$(mktemp)
        tar tvzf $BM_REPOSITORY_ROOT/$archive > $tempfile
        
        if grep "xim/file2" $tempfile
        then
           warning "Archive seems to have the blacklisted dirs:"
           if [[ "$warnings" = "true" ]]; then
                cat $tempfile
           fi
           rm -f $tempfile
           rm -rf $PWD/var
           rm -rf $PWD/repository
           exit 1
        else
            rm -f $tempfile
           rm -rf $PWD/var
           rm -rf $PWD/repository
            exit 0
        fi                
else
    warning "$archive doesn't exists"
    rm -rf $PWD/var
    rm -rf $PWD/repository
    exit 1
fi    

