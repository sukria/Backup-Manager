#
# The backup-manager's dialog.sh library.
#
# This will handle every functions dedicated 
# to cummunicate with the user.
#

# print on STDOUT the usage 
usage()
{
	echo "$0 [options]"
	echo "--verbose|-v        : Print what happends on STDOUT."
	echo "--conffile|-c file  : Choose an alternate config file."
	echo "--force|-f          : Force overwrite of existing archives."
	echo "--help|-h           : Print this help message (man backup-manager for details)."
	echo "--upload|-u         : Just upload the files of the day."
	echo "--burn|-b           : Just burn the files of the day."
	echo "--md5check|-m       : Just test the md5 sums."
	exit 0
}



# this prints an error message and stops the program
# with an error code.
error()
{
	echo_translated "$@"	
	_exit 1
}

debug()
{
	echo ""
	echo_translated "$@"	
	echo ""
}

# warning is just a wrapper to echo
# it will always print the mesasge 
# unless --no-warnings is given
warning()
{
	if [ "$warnings" = "true" ]; then
		echo_translated "$@"	
	fi
}

# a useful functions to handle nicely 
# communication with user according to 
# the flag --verbose
info() 
{
	if [ "$verbose" == "true" ]; then
		echo_translated "$@"	
	fi
}

# that's the way backup-manager should exit.
# need to remove the lock before !
_exit()
{
	info -n "Releasing lock: "
	release_lock
	info "ok"

	if [ "$HAS_MOUNTED" = 1 ]; then
		info -n "Unmounting \$BM_BURNING_DEVICE: "
		sleep 2
		umount $mount_point
		rmdir $mount_point
		info "ok"
	fi

	exit $@
}


# this is the callback wich is run when backup-manager
# is stopped with a signal like SIGTERM or SIGKILL
# see the trap stuff ;)
# So the only thing to do is to release the lock before.
stop_me()
{
	echo ""
	error "Warning, I was stopped before ending my job. Archives may be corrupted."
	release_lock
}

# be sure that zip is supported.
check_filetype()
{
	if [ "$BM_FILETYPE" = "zip" ]
	then
	
		if [ ! -x $zip ]
		then
			error "the BM_FILETYPE conf key is set to \"zip\" but zip is not installed."
		fi
	fi
}

# get the list of directories to backup.
check_what_to_backup()
{
	if [ ! -n "$BM_DIRECTORIES" ] 
	then 
		error "The BM_DIRECTORIES conf key is not set in \$conffile"
	fi
}

init_default_vars()
{
	if [ ! -n "$BM_MAX_TIME_TO_LIVE" ]
	then
		export BM_MAX_TIME_TO_LIVE=5
	fi

	# set the date values 
	export TODAY=`date +%Y%m%d`                  
	export TOOMUCH_TIME_AGO=`date +%d --date "$BM_MAX_TIME_TO_LIVE days ago"`
}

create_archive_root_if_not_exists()
{
	if [ ! -d $BM_ARCHIVES_REPOSITORY ]
	then
		info "\$BM_ARCHIVES_REPOSITORY does not exist, creating it"
		mkdir $BM_ARCHIVES_REPOSITORY
	fi
}

