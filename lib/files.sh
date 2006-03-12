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
#
# The backup-manager's files.sh library.
#
# All functions dedicated to manage the files.
#

#unmount_tmp_dir()
#{
#	if [ -n "$mount_point" ] && 
#	   [ -d $mount_point ] &&
#	   [ grep $mount_point /etc/mtab >/dev/null 2>&1 ]; then
#		umount "$mount_point" > /dev/null 2>&1 || error "unable to unmount \$mount_point"
#		sleep 1
#		rmdir "$mount_point" > /dev/null 2>&1 || error "unable to remove \$mount_point"
#	fi
#}

# this will send the appropriate name of archive to 
# make according to what the user choose in the conf.
get_dir_name()
{
	base="$1"
	format="$2"

	if [ "$format" = "long" ]
	then
		# first remove the trailing slash
		base=$(echo $base | sed -e 's|/$||')

		# then substitue every / by a -
		dirname=`echo "$base" | sed 's/\//-/g'`
		
	elif [ "$format" = "short" ]
	then
		OLDIFS=$IFS
		export IFS="/"
		for directory in $base
		do
			parent=$directory
		done
		dirname=$directory
		export IFS=$OLDIFS
	else
		echo ""
	fi
	
	echo "$dirname"
}

# This will take a path and return the size in mega bytes
# used on the disk.
# Thanks to Michel Grentzinger <mic.grentz@online.fr>
size_of_path()
{
	path="$1"
    if [ -z "$path" ]; then
        error "No path given."
    fi

    #echo "DEBUG: du --si --block-size=1000k -c $path | tail -1 | awk '{print $1}'" >&2
    total_size=$(du --si --block-size=1000k -c $path | tail -1 | awk '{print $1}')
	echo $total_size
}

# Thanks to Michel Grentzinger <mic.grentz@online.fr>
size_left_of_path()
{
	path="$1"
    if [ -z "$path" ]; then
        error "No path given."
    fi

	left=$(df --si --block-size=1000k "$path" | tail -1 | awk '{print $4}')

	echo $left

}

# Will return the prefix contained in the file name
get_prefix_from_file()
{
	filename="$1"
	filename=$(basename $filename)
	prefix=$(echo $filename | sed -e 's/^\([^-]\+\)-.*$/\1/')
	echo $prefix
}

# Will return the date contained in the file name
get_date_from_file()
{
	filename="$1"
	date=$(echo $filename | sed -e 's/.*\([0-9]\{8\}\).*/\1/')
	if [ $date = $filename ] ; then
		date=""
	fi
	echo $date
}

# This function is here to free each lock previously enabled.
# We have to keep in mind that lock must be done for each conffile.
# It is not global anymore, and that's the tricky thing.
release_lock() {
	if [ -e $lockfile ]; then
		# We have to remove the line which contains 
		# the conffile.
		newfile=$(mktemp)
		newcontent=""
		OLDIFS=$IFS
		IFS=$'\n'
		for line in $(cat $lockfile)
		do
			thisfile=$(echo $line | awk '{print $2}')
			if [ ! $conffile = $thisfile ]; then
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
get_lock() {
	if [ -e $lockfile ]; then
		
		# look if a lock exists for that conffile (eg, we must find 
		# the path of the conffile in the lockfile)
		# lockfile format : 
		# $pid	$conffile
	
		pid=`grep " $conffile " $lockfile | awk '{print $1}'`

		# be sure that the process is running
		if [ ! -z $pid ]; then
			real_pid=$(ps --no-headers --pid $pid |awk '{print $1}')
			if [ -z $real_pid ]; then
				echo_translated "Removing lock for old PID, \$pid is not running."
				release_lock
				#unmount_tmp_dir
				pid=""
			fi
		fi

		if [ -n "$pid" ]; then
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
		if [ ! -e $lockfile ]; then
			error "failed (check the file permissions)."
			exit 1
		fi
	fi
}


# Remove a file if its date is older than the 
# date of expiration.
clean_file()
{
	date_to_remove=`date +%Y%m%d --date "$BM_ARCHIVE_TTL days ago"`
	file="$1"
	
	if [ ! -f $file ]; then
		error "\$file is not a regular file."
	fi

	date=$(get_date_from_file $file)
	if [ $date != $file ]; then
		date=$(echo $date | sed -e 's/[^0-9]//g')
		if [ ! -z $date ]; then
			if [ $date -lt $date_to_remove ] || 
			   [ $date = $date_to_remove ]; then
				info "Removing \$file"
				rm -f $file
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
clean_directory()
{
	directory="$1"

	if [ ! -d $directory ]; then
		error "Directory given is not found."
	fi

	for file in $directory/*
	do
		if [ ! -e $file ]; then
			continue
		fi
		
		if [ -d $file ]; then
			info "Entering directory \$file"
			clean_directory "$file"
		else 
			clean_file "$file"
		fi
	done
}

# This takes a file and the md5sum of that file.
# It will look at every archives of the same source
# and will replace duplicates (same size) by symlinks.
# CONDITION: BM_ARCHIVE_PURGEDUPS = true
purge_duplicate_archives()
{
	file_to_create="$1"

	# Only purge if BM_ARCHIVE_PURGEDUPS = true
	if [ -z "$BM_ARCHIVE_PURGEDUPS" ] ||
       [ "$BM_ARCHIVE_PURGEDUPS" != "true" ]; then
		return 0
	fi

    if [ ! -e $file_to_create ]; then
        error "The given file does not exist: \$file_to_create"
        return 1
    fi    

	if [ -z "$file_to_create" ]; then
		error "No file given."
	fi

	# we'll parse all the files of the same source
	date_of_file=$(get_date_from_file $file_to_create) || 
        error "Unable to get date from file."
	file_pattern=$(echo $file_to_create | sed -e "s/$date_of_file.*$/\*/") || 
        error "Unable to find the pattern of the file."
	
	for file in $file_pattern
	do
		if [ ! -L $file ] && 
		   [ "$file" != "$file_to_create" ]; then
			md5sum_to_check=$(get_md5sum_from_file $file_to_create $BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-${TODAY}.md5)

			if [ "$md5hash" = "$md5sum_to_check" ]; then
				info "\$file is a duplicate of \$file_to_create (using symlink)."
				rm -f $file
				ln -s $file_to_create $file
			fi
		fi
	done
}

