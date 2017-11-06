# Copyright © 2005-2016 The Backup Manager Authors
#
# See the AUTHORS file for details.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

#
# Main wrapper
#

# Loop on the backup methods
function make_archives()
{
    debug "make_archives()"

    for method in $BM_ARCHIVE_METHOD
    do      
        case $method in
        mysql)
            backup_method_mysql "$method"
        ;;
        pgsql)
            backup_method_pgsql "$method"
        ;;
        tarball|tarball-incremental)
            backup_method_tarball "$method"
        ;;
        pipe)
            backup_method_pipe "$method"
        ;;
        svn)
            backup_method_svn "$method"
        ;;
        none|disabled)
            info "No backup method used."
        ;;
        *)
            if [ $(type -t "backup_method_${method}") = "function" ]; then
                backup_method_${method} "${method}"
            else
                error "No such backup method: \$BM_ARCHIVE_METHOD"
            fi
        ;;
    esac

    # Now make sure the md5 file is okay.
    if [[ -e $MD5FILE ]] && 
       [[ "$BM_REPOSITORY_SECURE" = "true" ]]; then
        chown $BM_REPOSITORY_USER:$BM_REPOSITORY_GROUP $MD5FILE ||
            warning "Unable to change the owner of \"\$MD5FILE\"."
        chmod $BM_ARCHIVE_CHMOD $MD5FILE ||
            warning "Unable to change file permissions of \"\$MD5FILE\"."
    fi
done
}

# Loop on the upload methods
function upload_files()
{
    debug "upload_files()"

    for method in $BM_UPLOAD_METHOD
    do            
        case $method in
        ftp|FTP)
            bm_upload_ftp
        ;;
        ssh|SSH|scp|SCP)
            bm_upload_ssh       
        ;;
    ssh-gpg|SSH-GPG)
        bm_upload_ssh_gpg
    ;;
        rsync|RSYNC)
            bm_upload_rsync
        ;;
        rsync-snapshots|RSYNC-SNAPSHOTS)
            bm_upload_rsync_snapshots
        ;;
        s3|S3)
            bm_upload_s3
        ;;
        none|disabled)
            info "No upload method used."
        ;;
        *)
            warning "The upload method \"\$method\" is not supported; skipping."
        ;;
        esac
    done        
}

# This will parse all the files contained in BM_REPOSITORY_ROOT
# and will clean them up. Using clean_directory() and clean_file().
function clean_repositories()
{
    debug "clean_repositories"

    info "Cleaning \$BM_REPOSITORY_ROOT"
    clean_directory $BM_REPOSITORY_ROOT
}

# This will run the pre-command given.
# If this command exit with non-zero status,
# backup-manager will stop here.
function exec_pre_command()
{
    debug "exec_pre_command()"

    if [[ ! -z "$BM_PRE_BACKUP_COMMAND" ]]; then
        info "Running pre-command: \$BM_PRE_BACKUP_COMMAND."
        $BM_PRE_BACKUP_COMMAND
        if [ $? -eq 0 ]; then
            info "Pre-command succeeded."
        else
            warning "Pre-command failed. Stopping the process."
            _exit 15 "PRE_COMMAND"
        fi
    fi

}

function exec_post_command()
{
    debug "exec_post_command()"

    if [[ ! -z "$BM_POST_BACKUP_COMMAND" ]]; then
        info "Running post-command: \$BM_POST_BACKUP_COMMAND"
        $BM_POST_BACKUP_COMMAND
        if [ $? -eq 0 ]; then
            info "Post-command succeeded."
        else
            warning "Post-command failed."
            _exit 15 "POST_COMMAND"
        fi
    fi
}

function bm_init_env()
{
    debug "bm_init_env()"
    export TOOMUCH_TIME_AGO=`date +%d --date "$BM_ARCHIVE_TTL days ago"`

    # Use a single md5 file to store all archives. This lives here to make the
    # test suite work. It runs actions without touching the backup-manager
    # script
    export MD5FILE="${BM_REPOSITORY_ROOT}/${BM_ARCHIVE_PREFIX}-hashes.md5"

    if [[ -n "$HOME" ]]; then
        export BM__GPG_HOMEDIR="--homedir ${HOME}/.gnupg"
    else
        export BM__GPG_HOMEDIR="--homedir /root/.gnupg"
    fi
    check_logger
}

function bm_init_today()
{
    debug "bm_init_today()"
    export TODAY=`date +%Y%m%d`                  
}

# be sure that zip is supported.
function check_filetypes()
{
    debug "check_filetypes()"

    case "$BM_TARBALL_FILETYPE" in
        "zip")
            if [[ ! -x "$zip" ]]; then
                error "The BM_TARBALL_FILETYPE conf key is set to \"zip\" but zip is not installed."
            fi
        ;;
        "tar.bz2" )
            if [[ ! -x "$bzip" ]]; then
                error "The BM_TARBALL_FILETYPE conf key is set to \"tar.bz2\" but bzip2 is not installed."
            fi
        ;;
         "tar.xz" )
            if [[ ! -x "$xz" ]]; then
                error "The BM_TARBALL_FILETYPE conf key is set to \"tar.xz\" but xz is not installed."
            fi
        ;;
         "tar.lzma" )
            if [[ ! -x "$lzma" ]]; then
                error "The BM_TARBALL_FILETYPE conf key is set to \"tar.lzma\" but lzma is not installed."
            fi
        ;;
        "dar" )
            if [[ ! -x "$dar" ]]; then
                error "The BM_TARBALL_FILETYPE conf key is set to \"dar\" but dar is not installed."
            fi
        ;;
    esac
}

function create_directories()
{
    debug "create_directories()"

    if [[ ! -d $BM_REPOSITORY_ROOT ]]
    then
        info "The repository \$BM_REPOSITORY_ROOT does not exist, creating it."
        mkdir -p $BM_REPOSITORY_ROOT
    fi

    # for security reason, the repository should not be world readable
    # only BM_REPOSITORY_USER:BM_REPOSITORY_GROUP can read/write it. 
    if [[ "$BM_REPOSITORY_SECURE" = "true" ]]; then
        chown $BM_REPOSITORY_USER:$BM_REPOSITORY_GROUP $BM_REPOSITORY_ROOT
        chmod $BM_REPOSITORY_CHMOD $BM_REPOSITORY_ROOT
    fi
}


