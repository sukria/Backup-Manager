#
# The backup-manager's files.sh library.
#
# All functions dedicated to manage the files.
#

unmount_tmp_dir()
{
	if [ -d $mount_point ]; then
		umount $mount_point
		rmdir $mount_point
	fi
}

# this will send the appropriate name of archive to 
# make according to what the user choose in the conf.
get_dir_name()
{
	base=$1
	format=$2

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
size_of_path()
{
	path="$1"
	out=$(du -m -c $path)

	OLDIFS=$IFS
	IFS=$'\n'
	for line in $out
	do
		size=$(echo $line | awk '{print $1}')
		dir=$(echo $line | awk '{print $2}')
		if [ "$dir" = "total" ]; then
			total_size=$size
		fi
	done
	IFS=$OLDIFS
	echo $total_size
}

size_left_of_path()
{
	path="$1"
	out=$(df -B 1024K $path) 

	OLDIFS=$IFS
	IFS=$'\n'
	for line in $out
	do
		left=$(echo $line | awk '{print $4}')
	done
	IFS=$OLDIFS
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
				echo "Removing lock for old PID, \$pid is not running."
				release_lock
				unmount_tmp_dir
				pid=""
			fi
		fi

		if [ -n "$pid" ]; then
			# we really must not use error or _exit here ! 
			# this is the special point were release_lock should not be called !
			echo "A backup-manager process (\$pid) is already running with the conffile \$conffile."
			exit 1
		else
			pid=$$
			info -n "Getting lock for backup-manager \$pid with \$conffile: "
			echo "$$ $conffile " >> $lockfile
			info "ok"
			
		fi
	else 
		pid=$$
		info -n "Getting lock for backup-manager \$pid with \$conffile: "
		echo "$$ $conffile " > $lockfile
		if [ ! -e $lockfile ]; then
			error "failed (check the file permissions)"
			exit 1
		fi
		info "ok"
	fi
}
