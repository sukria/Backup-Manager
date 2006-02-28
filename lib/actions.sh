# Copyright (C) 2005 The Backup Manager Authors
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

# * * *
# Every kind of actions that are not covered by -methods.sh libraries.
# * * * 

# Loop on the backup methods
make_archives()
{
    for method in $BM_ARCHIVE_METHOD
    do      
        case $method in
        mysql)
            backup_method_mysql "$method"
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
            error "No such backup method: \$BM_ARCHIVE_METHOD"
        ;;
    esac
done
}

# Loop on the upload methods
upload_files ()
{
    for method in $BM_UPLOAD_METHOD
    do            
        case $method in
        ftp|FTP)
            bm_upload_ftp
        ;;
        ssh|SSH|scp|SCP)
            bm_upload_ssh
        ;;
        rsync|RSYNC)
            bm_upload_rsync
        ;;
        rsync-snapshots|RSYNC-SNAPSHOTS)
            bm_upload_rsync_snapshots
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
clean_repositories()
{
    info "Cleaning \$BM_REPOSITORY_ROOT"
    clean_directory $BM_REPOSITORY_ROOT
}


# This will run the pre-command given.
# If this command prints on STDOUT "false", 
# backup-manager will stop here.
exec_pre_command()
{
    if [ ! -z "$BM_PRE_BACKUP_COMMAND" ]; then
        info "Running pre-command: \$BM_PRE_BACKUP_COMMAND."
        RET=`$BM_PRE_BACKUP_COMMAND` || RET="false" 
        case "$RET" in
            "false")
                warning "Pre-command failed. Stopping the process."
                _exit 15
            ;;

            *)
                info "Pre-command returned: \"\$RET\" (success)."
            ;;
        esac
    fi

}

exec_post_command()
{
    if [ ! -z "$BM_POST_BACKUP_COMMAND" ]; then
        info "Running post-command: \$BM_POST_BACKUP_COMMAND"
        RET=`$BM_POST_BACKUP_COMMAND` || RET="false"
        case "$RET" in
            "false")
                warning "Post-command failed."
                _exit 16
            ;;

            *)
                info "Post-command returned: \"\$RET\" (success)."
            ;;
        esac
    fi
}

bm_init_env ()
{
    export TODAY=`date +%Y%m%d`                  
    export TOOMUCH_TIME_AGO=`date +%d --date "$BM_ARCHIVE_TTL days ago"`
}
