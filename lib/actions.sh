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

    # Now make sure the md5 file is okay.
	md5file="$BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-${TODAY}.md5"
    if [ -e $md5file ]; then
        chown $BM_REPOSITORY_USER:$BM_REPOSITORY_GROUP $md5file ||
            warning "Unable to change the owner of \"\$md5file\"."
        chmod 0660 $md5file ||
            warning "Unable to change file permissions of \"\$md5file\"."
    fi
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

function bm_init_env ()
{
    export TOOMUCH_TIME_AGO=`date +%d --date "$BM_ARCHIVE_TTL days ago"`
    check_logger
}

function bm_init_today()
{
    export TODAY=`date +%Y%m%d`                  
}

# be sure that zip is supported.
check_filetypes()
{
	case "$BM_TARBALL_FILETYPE" in
		"zip")
			if [ ! -x $zip ]; then
				error "The BM_TARBALL_FILETYPE conf key is set to \"zip\" but zip is not installed."
			fi
		;;
		"tar.bz2" )
			if [ ! -x $bzip ]; then
				error "The BM_TARBALL_FILETYPE conf key is set to \"bzip2\" but bzip2 is not installed."
			fi
		;;
		"dar" )
			if [ ! -x $dar ]; then
				error "The BM_TARBALL_FILETYPE conf key is set to \"dar\" but dar is not installed."
			fi
		;;
	esac
}

# get the list of directories to backup.
check_what_to_backup()
{
	if [ ! -n "$BM_TARBALL_DIRECTORIES" ] && [ "$BM_ARCHIVE_METHOD" = "tarball" ]; then 
		error "The BM_TARBALL_DIRECTORIES conf key is not set in \$conffile"
	fi
}


function create_directories()
{
	if [ ! -d $BM_REPOSITORY_ROOT ]
	then
		info "The repository \$BM_REPOSITORY_ROOT does not exist, creating it."
		mkdir $BM_REPOSITORY_ROOT
	fi

	# for security reason, the repository should not be world readable
	# only BM_REPOSITORY_USER:BM_REPOSITORY_GROUP can read/write it. 
	if [ "$BM_REPOSITORY_SECURE" = "true" ]; then
		chown $BM_REPOSITORY_USER:$BM_REPOSITORY_GROUP $BM_REPOSITORY_ROOT
		chmod 770 $BM_REPOSITORY_ROOT
	fi
}



