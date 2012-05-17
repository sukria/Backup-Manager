# Copyright � 2005-2010 Alexis Sukrieh
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

#
# CD/DVD discs burning features
#


function bm_safe_unmount
{
    device="$1"
    debug "bm_safe_unmount($device)"

    realdevice=$(ls -l $device | awk '{print $10}')
    if [[ -n "$realdevice" ]]; then
        device="$realdevice"
    fi

    for m in `grep $device /etc/mtab 2>/dev/null| awk '{print $2}'`
    do
        info "Device \"/dev/\$device\" is mounted on \"\$m\", unmounting it."
        umount $m 2>/dev/null
        sleep 1
    done
}


# This will get all the md5 sums of the day,
# mount the BM_BURNING_DEVICE on /tmp/device and check 
# that the files are correct with md5 tests.
function check_cdrom_md5_sums()
{
    debug "check_cdrom_md5_sums()"

    has_error=0
    if [[ -z $BM_BURNING_DEVICE ]]; then
        error "MD5 checkup is only performed on disks. Please set the BM_BURNING_DEVICE in \$conffile"
    fi

    # first create the mount point
    mount_point="$(mktemp -d ${BM_TEMP_DIR}/bm-mnt.XXXXXX)"
    if [[ ! -d $mount_point ]]; then
        error "The mount point \$mount_point is not there."
    fi

    # if MD5FILE does not exist, there are no md5 sums to compare anyway
    if [[ ! -f $MD5FILE ]]; then
        error "Missing md5 sums database ($MD5FILE); cannot check md5 sums."
    fi

    # unmount if needed
    bm_safe_unmount $BM_BURNING_DEVICE

    # mount the device in /tmp/
    info "Mounting \$BM_BURNING_DEVICE on \$mount_point."
    mount $BM_BURNING_DEVICE $mount_point >& /dev/null
    export HAS_MOUNTED=1
    
    # now we can check the md5 sums.
    for file in $mount_point/*[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*
    do
        base_file=$(basename $file)
        date_of_file=$(get_date_from_file $file)
        prefix_of_file=$(get_prefix_from_file $file)

        # Do not check the md5 sums of indexes.
        if [[ "$prefix_of_file" = "index" ]]; then
            continue
        fi

        str=$(echo_translated "Checking MD5 sum for \$base_file:")

        # try to read the previously saved md5 hash in the database
        md5hash_trust=$(get_md5sum_from_file ${base_file} $MD5FILE)

        # If the MD5 hash was not found, do not generate it; instead
        # issue a warning that the burned archive cannot be verified
        if [[ -z "$md5hash_trust" ]]; then
            warning "Cannot verify correct burning of $base_file; did not found md5 sum in database"
            continue
        fi

        # now calculate burnt archive's md5 sum and compare with database
        md5hash_cdrom=$(get_md5sum $file) || md5hash_cdrom="undefined"
        case $md5hash_cdrom in
            $md5hash_trust)
                echo_translated "\$str ok."
            ;;
            undefined)
                echo_translated "\$str failed (read error)."
                has_error=1
            ;;
            *)
                echo_translated "\$str failed (MD5 hash mismatch)."
                has_error=1
            ;;
        esac
    done

    if [[ $has_error = 1 ]]; then
        warning "Errors encountered during MD5 checks."
    fi

    # remove the mount point
    umount $BM_BURNING_DEVICE || error "Unable to unmount the mount point \$mount_point"
    rmdir $mount_point || error "Unable to remove the mount point \$mount_point"
}

# this will try to burn the generated archives to the disc
# choosed in the configuration.
# Obviously, we will use mkisofs for generating the iso and 
# cdrecord for burning CD, growisofs for the DVD.
# Note that we pipe the iso image directly to cdrecord
# in this way, we prevent the use of precious disk place.
#
# Two cases are possible:
# - non-interactive mode: will try to burn data on a single disc
# - interactive mode : will ask for next disc if needed.
function burn_files()
{
    debug "burn_files()"

    if [[ "$BM_BURNING_METHOD" = "none" ]] || 
       [[ -z "$BM_BURNING_METHOD" ]]; then
        info "No burning method used."
        return 0
    fi
    
    # Choose which mode to use (interactive or not)
    # according to the standard input
    if tty -s ; then 
        debug "tty detected, using the interactive mode"
        burn_files_interactive
    else
        debug "no tty detected, non-interactive mode"
        burn_files_non_interactive
    fi
}

function find_what_to_burn()
{
    source="$1"
    debug "find_what_to_burn($source)"
    
    what_to_burn=""

    nb_file=$(ls -l $source 2>/dev/null | wc -l)
    if [[ $nb_file -gt 0 ]]; then
        info "Number of files to burn: \$nb_file."
    else
        error "Nothing to burn for the \$BM__BURNING_DATE, try the '--burn <date>' switch."
    fi
    
    for file in $source
    do
        if [[ ! -L $file ]]; then
            what_to_burn="$what_to_burn $file"
        fi
    done    
}

# This has to do something without any interactive input.
function burn_files_non_interactive()
{
    debug "burn_files_non_interactive()"

    # find what to burn according to the size...
    what_to_burn=""
    size=$(size_of_path "$BM_REPOSITORY_ROOT")

    # We can't burn the whole repository, using only today's archives
    if [[ $size -gt $BM_BURNING_MAXSIZE ]] || 
       [[ -n "${BM__BURNING_DATE}" ]]; then
        
        if [[ -z "$BM__BURNING_DATE" ]]; then
            BM__BURNING_DATE="$TODAY"
        fi

        BM__BURNING_DATE="$TODAY"
        info "Burning archives of \$BM__BURNING_DATE."
        size=$(size_of_path "${BM_REPOSITORY_ROOT}/*${BM__BURNING_DATE}*")
        
        # does not fit neither, cannot burn anything.
        if [[ $size -gt $BM_BURNING_MAXSIZE ]]; then
            error "Cannot burn archives of the \$BM__BURNING_DATE, too big: \${size}M, must fit in \$BM_BURNING_MAXSIZE"
        fi
        find_what_to_burn "${BM_REPOSITORY_ROOT}/*${BM__BURNING_DATE}*"
    else
        BM__BURNING_DATE="$TODAY"
        find_what_to_burn "${BM_REPOSITORY_ROOT}/*"
    fi

    burn_session "$what_to_burn"
}

# This will be used only in interactive mode, then we can burn 
# the whole repository safely: user will change disc when needed (hopefully).
# (anyway, we rely on this assertion, this should be documented).
function burn_files_interactive()
{
    debug "burn_files_interactive()"

    purge_indexes
    if [[ ! -z "${BM__BURNING_DATE}" ]] ; then
        info "Burning archives of \$BM__BURNING_DATE."
        find_what_to_burn "${BM_REPOSITORY_ROOT}/*${BM__BURNING_DATE}*"
        size=$(size_of_path "${BM_REPOSITORY_ROOT}/*${BM__BURNING_DATE}*")
    else
        info "Burning the whole archives."
        BM__BURNING_DATE="$TODAY"
        find_what_to_burn "${BM_REPOSITORY_ROOT}/*"
        size=$(size_of_path "${BM_REPOSITORY_ROOT}")
    fi
    info "Trying to burn \$BM_REPOSITORY_ROOT (\$size MB) in interactive mode. You will be prompted to enter insert a disc when needed"
    burn_multiples_media "$what_to_burn"
}

# This will burn $what_to_burn on a single session 
# It must fit in a medium
function burn_session()
{
    what_to_burn="$1"
    session_number="$2"
    number_of_indexes="$3"
    debug "burn_session($what_to_burn, $session_number, $number_of_indexes)"

    # Since version 0.7.5 disc-image can be non-joliet.
    # This is handled by $BM_BURNING_ISO_FLAGS, let's default that 
    # variable for backward compat.
    if [[ -z "$BM_BURNING_ISO_FLAGS" ]]; then
        BM_BURNING_ISO_FLAGS="-R -J"
    fi

    if [[ -z "$session_number" ]] || [[ $session_number = 1 ]]; then
        title="Backups of ${BM__BURNING_DATE}"
    else
        title="Backups of ${BM__BURNING_DATE} - $session_number/$number_of_indexes"
    fi
    
    # Let's unmount the device first
    bm_safe_unmount $BM_BURNING_DEVICE
    
    # get a log file in a secure path
    logfile="$(mktemp ${BM_TEMP_DIR}/bm-burning.log.XXXXXX)"
    info "Redirecting burning logs into \$logfile"
    
    # set the cdrecord command 
    devforced=""
    if [[ -n "$BM_BURNING_DEVFORCED" ]]; then
        info "Forcing dev=\${BM_BURNING_DEVFORCED} for cdrecord commands."
        devforced="dev=${BM_BURNING_DEVFORCED}"
    fi
    
    # burning the iso with the user choosen method
    case "$BM_BURNING_METHOD" in
        "DVD")
            if [[ ! -x $growisofs ]]; then
                error "DVD+R(W) burning requires \$growisofs, aborting."
            fi
            
            info "Exporting archives to the DVD+R(W) disc in \$BM_BURNING_DEVICE."
            debug "$growisofs -use-the-force-luke=tty -Z ${BM_BURNING_DEVICE} ${BM_BURNING_ISO_FLAGS} -V \"${title}\" ${what_to_burn} >> ${logfile}"
            tail_logfile $logfile
            $growisofs -use-the-force-luke=tty -Z ${BM_BURNING_DEVICE} ${BM_BURNING_ISO_FLAGS} -V "${title}" ${what_to_burn} >> ${logfile} 2>&1 ||
                error "failed, check \$logfile"
        ;;
        
        "DVD-RW")
            if [[ ! -x $growisofs ]]; then
                error "DVD-R(W) burning requires \$growisofs, aborting."
            fi
            if [[ ! -x $dvdrwformat ]]; then
                error "DVD-R(W) burning requires \$dvdrwformat, aborting."
            fi
            
            info "Blanking the DVD-R(W) disc in \$BM_BURNING_DEVICE"
            debug "$dvdrwformat -blank $BM_BURNING_DEVICE > $logfile"
            tail_logfile $logfile
            $dvdrwformat -blank $BM_BURNING_DEVICE > $logfile 2>&1 || 
                error "Unable to blank the DVD-R(W) disc (check \$logfile)."
            
            info "Exporting archives to the DVD-R(W) disc in \$BM_BURNING_DEVICE."
            debug "$growisofs -use-the-force-luke=tty -Z ${BM_BURNING_DEVICE} ${BM_BURNING_ISO_FLAGS} -V \"${title}\" ${what_to_burn} >> ${logfile}"
            $growisofs -use-the-force-luke=tty -Z ${BM_BURNING_DEVICE} ${BM_BURNING_ISO_FLAGS} -V "${title}" ${what_to_burn} >> ${logfile} 2>&1 ||
                error "failed, check \$logfile"
        ;;
        
        "CDRW")
            if [[ ! -x $cdrecord ]]; then
                error "CD-R(W) burning requires \$cdrecord, aborting."
            fi
                        
            info "Blanking the CDRW in \$BM_BURNING_DEVICE."
            debug "${cdrecord} -tao $devforced blank=fast > ${logfile}"
            tail_logfile $logfile
            ${cdrecord} -tao $devforced blank=fast > ${logfile} 2>&1 ||
                error "failed, check \$logfile"
            
            info "Burning data to \$BM_BURNING_DEVICE."
            debug "${mkisofs} -V \"${title}\" -q ${BM_BURNING_ISO_FLAGS} ${what_to_burn} | ${cdrecord} -tao $devforced - > ${logfile}"
            ${mkisofs} -V "${title}" -q ${BM_BURNING_ISO_FLAGS} ${what_to_burn} | \
            ${cdrecord} -tao $devforced - > ${logfile} 2>&1 ||
                error "failed, check \$logfile"
        ;;
        
        "CDR")
            if [[ ! -x $cdrecord ]]; then
                error "CD-R(W) burning requires \$cdrecord, aborting."
            fi

            info "Burning data to \$BM_BURNING_DEVICE."
            debug "${mkisofs} -V \"${title}\" -q ${BM_BURNING_ISO_FLAGS} ${what_to_burn} | ${cdrecord} -tao $devforced - > ${logfile}"
            tail_logfile $logfile
            ${mkisofs} -V "${title}" -q ${BM_BURNING_ISO_FLAGS} ${what_to_burn} | \
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
    if [[ $BM_BURNING_CHKMD5 = true ]]; then
        check_cdrom_md5_sums
    fi
}

function purge_indexes()
{
    debug "purge_indexes()"

    index_prefix=$(get_index_prefix)
    rm -f ${index_prefix}*
}

function get_index_prefix()
{
    debug "get_index_prefix()"
    index_prefix="$BM_REPOSITORY_ROOT/index-${BM__BURNING_DATE}"
    echo "$index_prefix"
}

# Parse "$target" and build index files. Put as many files in index as possible
# according to BM_BURNING_MAXSIZE.
# indexes are not included here, should be added by hand after that processing.
function __build_indexes_from_target()
{
    target="$1"
    debug "__build_indexes_from_target ($target)"

    indexes=""
    medium_index=""
    index_number=1
    number_of_indexes=1
    index_prefix=$(get_index_prefix)
    index_session="$index_prefix-$index_number"

    # Sorting by filetypes
    target=$(ls -v $target)

    # Write the indexes files in order to have one index file by medium.
    # When a medium is full, we create a new one.
    for file in ${target}
    do
        if [[ ! -f $file ]]; then
            continue
        fi
        size_of_file=$(size_of_path "$file")

        if [[ $size_of_file -gt $BM_BURNING_MAXSIZE ]] ; then
            warning "Not burning \$file because it does not fit in the disk."
            continue
        fi

        # Addd file to the index file.
        medium_possible_index="$medium_index $file"
        size_of_possible_index=$(size_of_path "$medium_possible_index")

        if [[ $size_of_possible_index -gt $BM_BURNING_MAXSIZE ]] ; then
            indexes="$indexes $index_session"
            
            number_of_indexes=$(($number_of_indexes +1))
            index_number=$(($index_number + 1))
            index_session="$index_prefix-$index_number"
            echo "$file" > $index_session
            
            medium_index="$file"
            medium_possible_index=""

        else
            echo "$file" >> $index_session
            medium_index="$medium_possible_index"
        fi  
    done
    indexes="$indexes $index_session"
}

function __insert_new_medium()
{
    debug "__insert_new_medium()"
    bm_pause "$(translate "Please insert a new disk in \$BM_BURNING_DEVICE")"
}

function __burn_session_from_file()
{
    index_file="$1"
    session_number="$2"
    number_of_indexes="$3"
    debug "__burn_session_from_file ($index_file, $session_number, $number_of_indexes)"

    if [[ ! -e "$index_file" ]]; then
        error "No such index file: \"\$index_file\"."
    fi
    
    what_to_burn_session=""

    for file_to_burn in $(cat "$index_file")
      do
      what_to_burn_session="$what_to_burn_session $file_to_burn"
    done
    
    what_to_burn="$what_to_burn_session"
    burn_session "$what_to_burn_session" "$session_number" "$number_of_indexes"
}

function __append_index_paths_in_indexes()
{
    debug "__append_index_paths_in_indexes()"

    prefix=$(get_index_prefix)
    for index_file in $prefix*
    do    
        for index_path in $prefix*
        do
            echo "$index_path" >> $index_file
        done
    done
}

function burn_multiples_media()
{
    target="$1"
    debug "burn_multiples_media ($target)"
    
    # first purge existing indexs
    purge_indexes

    # put in $indexes a list of files that contain
    # archives to put on each medium.
    __build_indexes_from_target "$target"

    # Display the number of medias required by the burning systemp.
    if [[ $number_of_indexes -eq 1 ]]; then
        info "The burning process will need one disk."
    else 
        info "The burning process will need \$number_of_indexes disks."
    fi        

    # Now that all indexes are built, list them so we can find
    # them all in the media.
    __append_index_paths_in_indexes

    # foreach index, build its content on a media, interactively
    session_number=0
    for index in $indexes
    do
        session_number=$(($session_number + 1))
        info "Burning content of \$index"
        __insert_new_medium
        __burn_session_from_file "$index" "$session_number" "$number_of_indexes"
    done

    # Remove all the index files.
    rm -f $indexes
}
