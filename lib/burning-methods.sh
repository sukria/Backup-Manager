# Copyright (C) 2005-2006 The Backup Manager Authors
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
# * * *
#
# Burning related functions. Every burning method is implemented there.
#
# * * *


function bm_safe_unmount
{
    device="$1"
    if grep $device /etc/mtab >/dev/null 2>&1; then
        info "\$device is mounted, unmounting it."
        umount $device || warning "Unable to unmount the device \$device"
    fi
}

# This will get all the md5 sums of the day,
# mount the BM_BURNING_DEVICE on /tmp/device and check 
# that the files are correct with md5 tests.
check_cdrom_md5_sums()
{
    has_error=0

    if [ -z $BM_BURNING_DEVICE ]; then
        error "MD5 checkup is only performed on CD media. Please set the BM_BURNING_DEVICE in \$conffile"
    fi

    # first create the mount point
    mount_point="$(mktemp -d /tmp/bm-mnt.XXXXXX)"
    if [ ! -d $mount_point ]; then
        error "The mount point \$mount_point is not there."
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
        warning "Errors encountered during MD5 controls."
    fi

    # remove the mount point
    umount $BM_BURNING_DEVICE || error "Unable to unmount the mount point \$mount_point"
    rmdir $mount_point || error "Unable to remove the mount point \$mount_point"
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
        burn_files_interactive
    else
        burn_files_non_interactive
    fi
}

function find_what_to_burn()
{
    source="$1"
    what_to_burn=""

    nb_file=$(ls -l $source 2>/dev/null | wc -l)
    if [ $nb_file -gt 0 ]; then
        info "Number of files to burn: \$nb_file."
    else
        error "Nothing to burn for the \$BM__BURNING_DATE, try the '--burn <date>' switch."
    fi
    
    for file in $source
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
    if [ $size -gt $BM_BURNING_MAXSIZE ] ||
       [ ! -z "${BM__BURNING_DATE}" ]; then
        info "Burning archives of \$BM__BURNING_DATE."
        size=$(size_of_path "${BM_REPOSITORY_ROOT}/*${BM__BURNING_DATE}*")
        
        # does not fit neither, cannot burn anything.
        if [ $size -gt $BM_BURNING_MAXSIZE ]; then
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
# the whole repository safely: user will change media when needed (hopefully).
# (anyway, we rely on this assertion, this should be documented).
function burn_files_interactive()
{
    purge_indexes
 	if [ ! -z "${BM__BURNING_DATE}" ] ; then
		info "Burning archives of \$BM__BURNING_DATE"
		find_what_to_burn "${BM_REPOSITORY_ROOT}/*${BM__BURNING_DATE}*"
		size=$(size_of_path "${BM_REPOSITORY_ROOT}/*${BM__BURNING_DATE}*")
    else
		info "Burning the whole archives."
		BM__BURNING_DATE="$TODAY"
		find_what_to_burn "${BM_REPOSITORY_ROOT}/*"
		size=$(size_of_path "${BM_REPOSITORY_ROOT}")
	fi
    info "Trying to burn \$BM_REPOSITORY_ROOT (\$size MB) in interactive mode."
    burn_multiples_media "$what_to_burn"
}

# This will burn $what_to_burn on a single session 
# It must fit in a media!
function burn_session()
{
    what_to_burn="$1"
    session_number="$2"
    number_of_indexes="$3"

    if [ -z "$session_number" ] || [ $session_number = 1 ]; then
        title="Backups of ${BM__BURNING_DATE}"
    else
        title="Backups of ${BM__BURNING_DATE} - $session_number/$number_of_indexes"
    fi
    
    # Let's unmount the device first
    bm_safe_unmount $BM_BURNING_DEVICE
    
    # get a log file in a secure path
    logfile="$(mktemp /tmp/bm-burning.log.XXXXXX)"
    info "Redirecting burning logs into \$logfile"
    
    # set the cdrecord command 
    devforced=""
    if [ -n "$BM_BURNING_DEVFORCED" ]; then
        info "Forcing dev=\${BM_BURNING_DEVFORCED} for cdrecord commands."
        devforced="dev=${BM_BURNING_DEVFORCED}"
    fi
    
    # burning the iso with the user choosen method
    case "$BM_BURNING_METHOD" in
        
        "DVD")
            if [ ! -x $growisofs ]; then
                error "DVD+R(W) burning requires \$growisofs, aborting."
            fi
            
            info "Exporting archives to the DVD+R(W) media in \$BM_BURNING_DEVICE."
            $growisofs -Z ${BM_BURNING_DEVICE} -R -J -V "${title}" ${what_to_burn} >> ${logfile} 2>&1 ||
                error "failed, check \$logfile"
        ;;
        
        "DVD-RW")
            if [ ! -x $growisofs ]; then
                error "DVD-R(W) burning requires \$growisofs, aborting."
            fi
            if [ ! -x $dvdrwformat ]; then
                error "DVD-R(W) burning requires \$dvdrwformat, aborting."
            fi
            
            info "Blanking the DVD-R(W) media in \$BM_BURNING_DEVICE"
            $dvdrwformat -blank $BM_BURNING_DEVICE > $logfile 2>&1 || 
                error "Unable to blank the DVD-R(W) media (check \$logfile)."
            
            info "Exporting archives to the DVD-R(W) media in \$BM_BURNING_DEVICE."
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

function purge_indexes()
{
    index_prefix=$(get_index_prefix)
	rm -f ${index_prefix}*
}

function get_index_prefix()
{
	index_prefix="$BM_REPOSITORY_ROOT/index-${BM__BURNING_DATE}"
    echo "$index_prefix"
}

# Parse "$target" and build index files. Put as many files in index as possible
# according to BM_BURNING_MAXSIZE.
# indexes are not included here, should be added by hand after that processing.
function __build_indexes_from_target()
{
	target="$1"

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
		size_of_file=$(size_of_path "$file")

		if [ $size_of_file -gt $BM_BURNING_MAXSIZE ] ; then
			warning "Not burning \$file because it does not fit in the medium."
			continue
		fi

		# Addd file to the index file.
		medium_possible_index="$medium_index $file"
		size_of_possible_index=$(size_of_path "$medium_possible_index")

		if [ $size_of_possible_index -gt $BM_BURNING_MAXSIZE ] ; then
			indexes="$indexes $index_session"
			
			number_of_indexes=$(($number_of_indexes +1))
			index_number=$(($index_number + 1))
			index_session="$index_prefix-$index_number"
            #__debug "BM_BURNING_MAXSIZE is reached : new index: $index_session"
            
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
    bm_pause "$(translate "Please insert a new media in \$BM_BURNING_DEVICE")"
}

function __burn_session_from_file()
{
    index_file="$1"
    session_number="$2"
    number_of_indexes="$3"

    if [ ! -e "$index_file" ]; then
        error "No such index file : \$index_file"
    fi
	
    what_to_burn_session=""

    for file in $(cat "$index_file")
      do
      what_to_burn_session="$what_to_burn_session $file"
    done
    
    what_to_burn="$what_to_burn_session"
    
    burn_session "$what_to_burn_session" "$session_number" "$number_of_indexes"

    # Remove the index file.
    rm -f $index_file

}

function __append_index_paths_in_indexes()
{
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
    
    # first purge existing indexs
    purge_indexes

    # put in $indexes a list of files that contain
    # archives to put on each medium.
    __build_indexes_from_target "$target"

	# Display the number of medias required by the burning systemp.
	info "The burning process will need $number_of_indexes media(s)."

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
}
