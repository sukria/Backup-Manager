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

# All functions dedicated to manage the files.

#unmount_tmp_dir()
#{
#   if [[ -n "$mount_point" ]] && 
#      [[ -d $mount_point ]] &&
#      [[ grep $mount_point /etc/mtab >/dev/null 2>&1 ]]; then
#       umount "$mount_point" > /dev/null 2>&1 || error "unable to unmount \$mount_point"
#       sleep 1
#       rmdir "$mount_point" > /dev/null 2>&1 || error "unable to remove \$mount_point"
#   fi
#}


# detect if find supports -H
find_opt=""
if find -H /tmp > /dev/null 2>&1 ; then
    find_opt="-H"
fi    

# this will send the appropriate name of archive to 
# make according to what the user choose in the conf.
function get_dir_name()
{
    base="$1"
    format="$2"
    debug "get_dir_name ($base, $format)"

    if [[ "$format" = "long" ]]
    then
        # first remove the trailing slash
        base=${base%/}

        # every space by a _ 
        dirname=$(echo "$base" | sed 's/ /_/g')
        # every / by a -
        dirname=$(echo "$dirname" | sed 's/\//-/g')
        
    elif [[ "$format" = "short" ]]
    then
        OLDIFS=$IFS
        export IFS="/"
        for directory in $base
        do
            parent=$directory
        done
        dirname=-$directory
        export IFS=$OLDIFS
    else
        echo ""
    fi
    
    echo "$dirname"
}

# This will take a path and return the size in mega bytes
# used on the disk.
# Thanks to Michel Grentzinger <mic.grentz@online.fr>
function size_of_path()
{
    path="$1"
    debug "size_of_path ($path)"

    if [[ -z "$path" ]]; then
        error "No path given."
    fi

    #echo "DEBUG: du --si --block-size=1000k -c $path | tail -n 1 | awk '{print $1}'" >&2
    total_size=$(du --si --block-size=1000k -c $path | tail -n 1 | awk '{print $1}')
    echo $total_size
}

# Thanks to Michel Grentzinger <mic.grentz@online.fr>
function size_left_of_path()
{
    path="$1"
    debug "size_left_of_path ($path)"

    if [[ -z "$path" ]]; then
        error "No path given."
    fi

    left=$(df --si --block-size=1000k "$path" | tail -n 1 | awk '{print $4}')

    echo $left

}

# Will return the prefix contained in the file name
function get_prefix_from_file()
{
    filename="$1"
    debug "get_prefix_from_file ($filename)"

    filename=$(basename $filename)
    prefix=$(echo $filename | sed -e 's/^\([^-]\+\)-.*$/\1/')
    echo $prefix
}


# Will return the date contained in the file name
function get_date_from_file()
{
    debug "get_date_from_file ($1)"
    get_date_from_archive "$1"
}

# This function is here to free each lock previously enabled.
# We have to keep in mind that lock must be done for each conffile.
# It is not global anymore, and that's the tricky thing.
function release_lock() 
{
    debug "release_lock()"

    if [[ -e $lockfile ]]; then
        # We have to remove the line which contains 
        # the conffile.
        newfile=$(mktemp ${BM_TEMP_DIR}/lock.XXXXXX)
        newcontent=""
        OLDIFS=$IFS
        IFS=$'\n'
        for line in $(cat $lockfile)
        do
            thisfile=$(echo $line | awk '{print $2}')
            if [[ ! $conffile = $thisfile ]]; then
                echo "$line" >> $newfile
            fi
        done
        IFS=$OLDIFS
        mv $newfile $lockfile
    fi
}

# This function try to get a lock, if this is not possible,
# backup-manager won't run.
# Be aware that a there will be one lock for each conffile used.
# If the PID written in the lockfile is not alive, release.
function get_lock() 
{
    debug "get_lock()"

    if [[ -e $lockfile ]]; then
        
        # look if a lock exists for that conffile (eg, we must find 
        # the path of the conffile in the lockfile)
        # lockfile format : 
        # $pid  $conffile
    
        pid=`grep " $conffile " $lockfile | awk '{print $1}'`

        # be sure that the process is running
        if [[ ! -z $pid ]]; then
	    unamestr=`uname | xargs | awk '{print tolower($0)}'`
	    # For OSX & fink :
	    if [[ "$unamestr" == 'darwin' ]]; then
		real_pid=$(ps -p $pid |tail -n +2 |awk '{print $1}')
	    else
		real_pid=$(ps --no-headers --pid $pid |awk '{print $1}')
	    fi
            
	    if [[ -z $real_pid ]]; then
                echo_translated "Removing lock for old PID, \$pid is not running."
                release_lock
                #unmount_tmp_dir
                pid=""
            fi
        fi

        if [[ -n "$pid" ]]; then
            # we really must not use error or _exit here ! 
            # this is the special point were release_lock should not be called !
            echo_translated "A backup-manager process (\$pid) is already running with the conffile \$conffile"
            exit 1
        else
            pid=$$
            info "Getting lock for backup-manager \$pid with \$conffile"
            echo "$$ $conffile " >> $lockfile
            
        fi
    else 
        pid=$$
        info "Getting lock for backup-manager \$pid with \$conffile"
        echo "$$ $conffile " > $lockfile
        if [[ ! -e $lockfile ]]; then
            error "failed (check the file permissions)."
            exit 1
        fi
    fi
}


function get_date_from_archive()
{
    file="$1"
    debug "get_date_from_archive ($file)"

    date=$(echo $file | sed -e 's/.*\(20[0-9][0-9][0-9][0-9][0-3][0-9]\).*/\1/')
    echo "$date"
}   

# Returns the name of an archive.
# eg: get_name_from_archive "ouranos-usr-bin.20060329.tar.bz2"
# usr-bin
function get_name_from_archive()
{
    archive="$1"
    debug "get_name_from_archive ($archive)"

    archive=$(basename "$archive")

    # drop the first token before a dash (the prefix)
    name="${archive#*-}"
    
    # drop the right part: everything from the first dot
    name="${name%%.*}"
    
    # done
    echo "$name"
}

function get_master_from_archive()
{
    archive="$1"
    debug "get_master_from_archive ($archive)"

    archive=$(basename "$archive")
    
    master=$(echo "$archive" | sed -e 's/.*\.\(master\)\..*/\1/')
    if [[ "$master" = "master" ]]; then
        echo "true"
    else 
        echo "false"
    fi
}

function get_prefix_from_archive()
{
    archive="$1"
    archive=$(basename "$archive")
    echo "${archive%%-*}"
}

function get_newer_master()
{
    prefix="$1"
    name="$2"
    date="$3"
    debug "get_newer_master ($prefix, $name, $date)"
    
    master=""
    
    for this_master in $BM_REPOSITORY_ROOT/$prefix-$name.*.master.*
    do
        this_date=$(get_date_from_archive "$this_master")
        
        # is this master newer than the one we are testing?
        if [[ "$this_date" -gt "$date" ]]; then
            debug "found this newer master : $this_master"
            master="$this_master"
        fi
    done

    echo "$this_master"
}

function clean_file()
{
    file="$1"
    purge_date="$2"
    debug "clean_file ($file, $purge_date)"

    if [[ ! -f "$file" ]]; then
        error "\$file is not a regular file."
    fi

    prefix=$(get_prefix_from_archive "$file")
    date=$(get_date_from_archive "$file")
    name=$(get_name_from_archive "$file")
    master=$(get_master_from_archive "$file")
    debug "parsing $file ($prefix, $date, $name, $master)"
                
    # we assume that if we find that, we have an archive
    if [[ -n "$date" ]] && [[ "$date" != "$(basename $file)" ]] &&
       [[ -n "$prefix" ]] && [[ "$prefix" != "$(basename $file)" ]] &&
       [[ -n "$name" ]] && [[ "$name" != "$(basename $file)" ]]; then
        
        # look if the archive is obsolete
        if [[ "$date" -lt "$purge_date" ]] || 
           [[ "$date" = "$purge_date" ]]; then
           
            # if it's a master, we have to find a newer master around
            if [[ "$master" = "true" ]]; then
                master_archive=$(get_newer_master "$prefix" "$name" "$date")
                
                # if the master returned is not the same as the one we have, 
                # the one we have can be deleted, because it's older.
                if [[ "$master_archive" != "$file" ]]; then
                    info "Removing obsolete master backup: \"\$file\"."
                    rm -f "$file"
                
                # else, we can only remove the master archive if we cannot find any 
                # incremental archive related.
                else
                    nb_incrementals=$(ls -l $BM_REPOSITORY_ROOT/$prefix-$name.*.* | wc -l)
                    if [[ "$nb_incrementals" = "1" ]]; then
                        info "Removing obsolete master backup (isolated): \"\$file\"."
                        rm -f $file
                    fi
                fi

            # the archive we handle isn't a master backup, we can drop it.
            else
                info "Removing archive \"\$file\"."
                rm -f "$file"
            fi
        fi
    fi
}


# clean one given repository.
# This will take each file that has 
# a date in its names and will compare 
# the file's date to the date_to_remove.
# If the file's date is older than the date_to_remove
# we drop the file.
function clean_directory()
{
    directory="$1"
    debug "clean_directory ($directory)"

    purge_date=$(date +%Y%m%d --date "$BM_ARCHIVE_TTL days ago")

    if [[ ! -d $directory ]]; then
        error "Directory given was not found."
    fi

    if [[ "$BM_REPOSITORY_RECURSIVEPURGE" = "true" ]]; then
        maxdepth=""
    else
        maxdepth="-maxdepth 1"
    fi

    # First list all the files to process
    # and ask backup-manager-purge what to remove
    list=$(mktemp ${BM_TEMP_DIR}/bm-list.XXXXXX)
    
    # files & symlinks
    find $find_opt "$directory" $maxdepth \
         \( -type f -o -type l \) -print \
         | $bmp --ttl=$BM_ARCHIVE_TTL > $list
    
    # Then actually remove the files
    for archive in `cat $list`
    do
        info "Removing archive \"\$archive\"."
        rm -f $archive
    done
    rm -f $list
}

# This takes a file and the md5sum of that file.
# It will look at every archives of the same source
# and will replace duplicates (same size) by symlinks.
# CONDITION: BM_ARCHIVE_PURGEDUPS = true
function purge_duplicate_archives()
{
    file_to_create="$1"

    if [[ -z "$2" ]]; then
        debug "purge_duplicate_archives ($file_to_create)"
        md5hash=$(get_md5sum $file_to_create)
    else
        # if the 2nd argument exists, it is the md5sum
        md5hash="$2"
        debug "purge_duplicate_archives ($file_to_create, $md5hash)"
    fi

    # Only purge if BM_ARCHIVE_PURGEDUPS = true
    if [[ -z "$BM_ARCHIVE_PURGEDUPS" ]] ||
       [[ "$BM_ARCHIVE_PURGEDUPS" != "true" ]]; then
        return 0
    fi

    if [[ ! -e $file_to_create ]]; then
        error "The given file does not exist: \$file_to_create"
        return 1
    fi    

    if [[ -z "$file_to_create" ]]; then
        error "No file given."
    fi

    # we'll parse all the files of the same source
    date_of_file=$(get_date_from_file $file_to_create) || 
        error "Unable to get date from file."
    if [[ -z "$date_of_file" ]]; then
        error "Unable to get date from file."
    fi
   
    file_pattern=$(echo $file_to_create | sed -e "s/$date_of_file/\*/") || 
        error "Unable to find the pattern of the file."
    
    # loop on each archive occurences (eg: archivename-*-filetype)
    for file in $file_pattern
    do
        # handle only regular files
        if [[ ! -L $file ]] && [[ "$file" != "$file_to_create" ]]; then
            
            # get the date of the file we parse
            date_of_file=$(get_date_from_file $file) || 
                error "Unable to get date from file."
            
            # get the md5 hash of the file we parse, in its .md5 file
            md5sum_to_check="$(get_md5sum_from_file $file $MD5FILE)"
            if [[ -z "$md5sum_to_check" ]]; then
                warning "Unable to find the md5 hash of file \"\$file\" in file \"\$MD5FILE\"."
                continue
            fi
            
            # if the md5 hashes are the same, purge the duplicate 
            if [[ "$md5hash" = "$md5sum_to_check" ]]; then
                info "\$file is a duplicate of \$file_to_create (using symlink)."
                rm -f $file
                ln -s $file_to_create $file
            fi
        fi
    done
}

function assert_file_exists() {
	file="$1"
	if [[ ! -r "$file" ]]; then
		warning "File '\$file' does not exist or is not readable."
		return 1
	fi
}

function assert_file_is_executable() {
	file="$1"
	if [[ ! -x "$file" ]]; then
		warning "File '\$file' is not executable"
		return 1
	fi
}

