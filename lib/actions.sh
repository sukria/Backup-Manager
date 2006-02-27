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
#
# Major features of backup manager are here.

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

# This will get all the md5 sums of the day,
# mount the BM_BURNING_DEVICE on /tmp/device and check 
# that the files are correct with md5 tests.
check_cdrom_md5_sums()
{
    has_error=0

    if [ -z $BM_BURNING_DEVICE ]; then
        error "MD5 checkup is only performed on CD media. Please set the BM_BURNING_DEVICE in \$conffile."
    fi

    # first create the mount point
    mount_point="$(mktemp -d /tmp/bm-mnt.XXXXXX)"
    if [ ! -d $mount_point ]; then
        error "The mount point \$mount_point is not there"
    fi
    
    # mount the device in /tmp/
    info "Mounting \$BM_BURNING_DEVICE on \$mount_point."
    mount $BM_BURNING_DEVICE $mount_point >& /dev/null || error "Unable to mount \$BM_BURNING_DEVICE on \$mount_point."
    export HAS_MOUNTED=1
    
    # now we can check the md5 sums.
    for file in $mount_point/*
    do
        base_file=$(basename $file)
        date_of_file=$(get_date_from_file $file)
        prefix_of_file=$(get_prefix_from_file $file)
        str=$(echo_translated "Checking MD5 sum for \$base_file:")
        
        # Which file should contain the MD5 hashes for that file ?
        md5_file="$BM_REPOSITORY_ROOT/${prefix_of_file}-${date_of_file}.md5"

        # if it does not exists, we create it (that will take much time).
        if [ ! -f $md5_file ]; then
            save_md5_sum $file $md5_file || continue
        fi
        
        # try to read the previously saved md5 hash in the file
        md5hash_trust=$(get_md5sum_from_file ${base_file} $md5_file)

        # If the MD5 hash was not found, generate it and save it now.
        if [ -z "$md5hash_trust" ]; then
            save_md5_sum $file $md5_file || continue
            md5hash_trust=$(get_md5sum_from_file ${base_file} $md5_file)
        fi
        
        md5hash_cdrom=$(get_md5sum $file) || md5hash_cdrom="undefined"
        case "$md5hash_cdrom" in
            "$md5hash_trust")
                echo_translated "\$str ok"
            ;;
            "undefined")
                echo_translated "\$str failed (read error)"
                has_error=1
            ;;
            *)
                echo_translated "\$str failed (MD5 hash mismatch)"
                has_error=1
            ;;
        esac
    done

    if [ $has_error = 1 ]; then
        error "Errors encountered during MD5 controls."
    fi

    # remove the mount point
    umount $BM_BURNING_DEVICE || error "unable to unmount the mount point \$mount_point"
    rmdir $mount_point || error "unable to remove the mount point \$mount_point"
}

# this will try to burn the generated archives to the media
# choosed in the configuration.
# Obviously, we will use mkisofs for generating the iso and 
# cdrecord for burning CD, growisofs for the DVD.
# Note that we pipe the iso image directly to cdrecord
# in this way, we prevent the use of preicous disk place.
#
# Two cases are possible:
# - non-interactive mode: will try to burn data on a signle media
# - interactive mode : will ask for next media if needed.
burn_files()
{
    if [ "$BM_BURNING_METHOD" = "none" ] || 
       [ -z "$BM_BURNING_METHOD" ]; then
        info "No burning method used."
        return 0
    fi
    
    # Choose which mode to use (interactive or not)
    # according to the standard input
    if tty -s ; then 
#        NOT YET READY - DOES NOT WORK
#        burn_files_interactive
        burn_files_non_interactive
    else
        burn_files_non_interactive
    fi
}

function find_what_to_burn()
{
    source="$1"
    for file in "$source"
    do
        if [ ! -L $file ]; then
            what_to_burn="$what_to_burn $file"
        fi
    done    
}

# This has to do something without any interactive input.
function burn_files_non_interactive()
{
    # find what to burn according to the size...
    what_to_burn=""
    size=$(size_of_path "$BM_REPOSITORY_ROOT")

    # We can't burn the whole repository, using only today's archives
    # FIXME: should be possible to choose another date than "today"
    if [ $size -gt $BM_BURNING_MAXSIZE ]; then
        size=$(size_of_path "${BM_REPOSITORY_ROOT}/*${TODAY}*")
        
        # does not fit neither, cannot burn anything.
        if [ $size -gt $BM_BURNING_MAXSIZE ]; then
			error "Cannot burn archives of the \$TODAY, too big: \${size}M, must fit in \$BM_BURNING_MAXSIZE"
        fi
        find_what_to_burn "${BM_REPOSITORY_ROOT}/*${TODAY}*"
    else
        find_what_to_burn "${BM_REPOSITORY_ROOT}"
    fi

    burn_session "$what_to_burn"
}

# This will be used only in interactive mode, then we can burn 
# the whole repository safely: user will change media when needed (hopefully).
# (anyway, we rely on this assertion, this should be documented).
function burn_files_interactive()
{
    find_what_to_burn "$BM_REPOSITORY_ROOT"
    size=$(size_of_path "$BM_REPOSITORY_ROOT")
    info "Trying to burn \$BM_REPOSITORY_ROOT (\$size_of_path MB) in interactive mode."
    burn_multiples_media
}

# This will burn $what_to_burn on a single session 
# It must fit in a media!
function burn_session()
{
    what_to_burn="$1"
    session_number="$2"

    if [ -z "$session_number" ]; then
        title="Backups of ${TODAY}"
    else
        title="Backups of ${TODAY} - $session_number"
    fi
    
    # Let's unmount the device first
    if grep $BM_BURNING_DEVICE /etc/mtab >/dev/null 2>&1; then
        info "\$BM_BURNING_DEVICE is mounted, unmounting before the burning session."
        umount $BM_BURNING_DEVICE || warning "Unable to unmount the device \$BM_BURNING_DEVICE"
    fi
    
    # get a log file in a secure path
    logfile="$(mktemp /tmp/bm-burning.log.XXXXXX)"
    info "Redirecting burning logs into \$logfile"
    
    # set the cdrecord command 
    devforced=""
    if [ -n "$BM_BURNING_DEVFORCED" ]; then
        info "Forcing dev=\${BM_BURNING_DEVFORCED} for cdrecord commands"
        devforced="dev=${BM_BURNING_DEVFORCED}"
    fi
    
    # User must change the media before burning
    if [ "$interactive" = "true" ] ; then
        insert_media
    fi

    # burning the iso with the user choosen method
    case "$BM_BURNING_METHOD" in
        "DVD")
            if [ ! -x $growisofs ]; then
                error "DVD burning requires \$growisofs, aborting."
            fi
            if [ ! -x $dvdrwformat ]; then
                error "DVD burning requires \$dvdrwformat, aborting."
            fi
            
            info "Blanking the DVD media in \$BM_BURNING_DEVICE"
            $dvdrwformat -blank $BM_BURNING_DEVICE > $logfile 2>&1 || 
                error "Unable to blank the DVD media (check \$logfile)."
            
            info "Exporting archives to the DVD media in \$BM_BURNING_DEVICE."
            $growisofs -Z ${BM_BURNING_DEVICE} -R -J -V "${title}" ${what_to_burn} >> ${logfile} 2>&1 ||
                error "failed, check \$logfile"
        ;;
        "CDRW")
            if [ ! -x $cdrecord ]; then
                error "CDROM burning requires \$cdrecord, aborting."
            fi
                        
            info "Blanking the CDRW in \$BM_BURNING_DEVICE."
            ${cdrecord} -tao $devforced blank=fast > ${logfile} 2>&1 ||
                error "failed, check \$logfile"
            
            info "Burning data to \$BM_BURNING_DEVICE."
            ${mkisofs} -V "${title}" -q -R -J ${what_to_burn} | \
            ${cdrecord} -tao $devforced - > ${logfile} 2>&1 ||
                error "failed, check \$logfile"
        ;;
        "CDR")
            if [ ! -x $cdrecord ]; then
                error "CDROM burning requires \$cdrecord, aborting."
            fi

            info "Burning data to \$BM_BURNING_DEVICE."
            ${mkisofs} -V "${title}" -q -R -J ${what_to_burn} | \
            ${cdrecord} -tao $devforced - > ${logfile} 2>&1 ||
                error "failed, check \$logfile"
        ;;
        "none"|"NONE")
            info "Nothing to burn."
        ;;
        *)
            error "The requested burning method is not supported, check BM_BURNING_METHOD in \$conffile"
        ;;
    esac
    
    # Cleaning the logile, everything was fine at this point.
    rm -f $logfile

    # checking the files in the CDR if wanted
    if [ $BM_BURNING_CHKMD5 = true ]; then
        check_cdrom_md5_sums
    fi
}

# This will burn $what_to_burn on as many media as needed.
# Take care, this has to be called in an interactive mode!
burn_multiples_media()
{
    what_to_burn_session=""
    interactive="true"
    session_number="1"

    # Sort the list of files which have to be burned
    # and start with the little one.
    what_to_burn_total="$(ls -r -S $what_to_burn)"
    for file in $what_to_burn_total ; do
        what_to_burn_sorted="$what_to_burn_sorted $file"
    done
    what_to_burn_total="$what_to_burn_sorted"

    for file in $what_to_burn_total ; do
        file="$BM_REPOSITORY_ROOT/$file"
        size_file=$(size_of_path "$file")
        if [ $size_file -gt $BM_BURNING_MAXSIZE ] ; then
            info "The file \$file (\${size_file}M) is too big for the burning device."
        fi

        if [ -z "$what_to_burn_session" ] ; then
            # Adding $file if the last session havn't keep any file which havn't been burnt.
            what_to_burn_possible_session="$file"
            what_to_burn_session="$file"
        else
            what_to_burn_possible_session="$what_to_burn_session $file"
        fi

        size_possible_session=$(size_of_path "$what_to_burn_possible_session")

        # Test if $what_to_burn_possible_session is bigger than the $BM_BURNING_MAXSIZE.
        # If yes, we return to $what_to_burn_session.
        # If no, $file can be added to $what_to_burn_session by keeping $what_to_burn_possible_session.
        if [ $size_possible_session -gt $BM_BURNING_MAXSIZE ] ; then
            info "Burning session... (with \$what_to_burn_session)."
            burn_session "$what_to_burn_session" "$session_number"

            # Test if just one file have been burned in the last session.
            if [ "$what_to_burn_session" = "$file" -o "$what_to_burn_session" = "$old_file" ] ; then
                info "One file in this session."
                # We reset the content of the session.
                what_to_burn_session=""
                old_file=""
                if [ "$what_to_burn_session" = "$old_file" ] ; then
                    # Adding $file to $what_to_burn for the next session because
                    # in this session, $old_file was burnt.
                    what_to_burn_session="$file"
                fi 
            else
                # We add the file which havn't been burnt in this session.
                what_to_burn_session="$file"
                old_file="$file"
            fi
            
        else
            what_to_burn_session="$what_to_burn_possible_session"
        fi

        session_number=$(($session_number + 1))
    done

    # Test if there is one more file which haven't been burnt by 
    # the last loop.
    if [ ! -z "$what_to_burn_session" ] ; then
        info "Burning the last media... (with \$what_to_burn_session)." 
        burn_session "$what_to_burn_session" "$session_number"
    fi
}


# This function is used by the burning process in case of it require more than one CD/DVD.
# It's just a pause and gives some time to the user for changing the media.
insert_media()
{
#eject
while true ; do
    echo -en "Please, insert a media and answer yes when you're ready to burn [YES|no]: "
    read answer
    case "$answer" in
        yes|YES|"") break   ;;
        no)                 ;;
        *) info "Please answer yes or no to the question !" ;;
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
