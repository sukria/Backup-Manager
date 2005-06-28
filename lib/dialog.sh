#
# The backup-manager's dialog.sh library.
#
# This will handle every functions dedicated 
# to send feedback tothe user.
#
# print on STDOUT the usage 
usage()
{
	echo_translated "$0 [options]"

	echo ""
	echo_translated "Output:"
	echo -n "--help|-h           : "; echo_translated "Print this short help message."
	echo -n "--verbose|-v        : "; echo_translated "Print what happens on STDOUT."
	echo -n "--no-warnings       : "; echo_translated "Disable warnings."

	echo ""
	echo_translated "Single actions:"
	echo -n "--upload|-u         : "; echo_translated "Just upload the files of the day."
	echo -n "--burn|-b           : "; echo_translated "Just burn the files of the day."
	echo -n "--md5check|-m       : "; echo_translated "Just test the md5 sums."
	echo -n "--purge|-p          : "; echo_translated "Just purge old archives."

	echo ""
	echo_translated "Behaviour:"
	echo -n "--conffile|-c file  : "; echo_translated "Choose an alternate config file."
	echo -n "--force|-f          : "; echo_translated "Force overwrite of existing archives."

	echo ""
	echo_translated "Unwanted actions:"
	echo -n "--no-upload         : "; echo_translated "Disable the upload process."
	echo -n "--no-burn           : "; echo_translated "Disable the burning process."
	echo -n "--no-purge          : "; echo_translated "Disable the purge process."

	exit 0
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
	if [ -z "$BM_USER" ]; then
		BM_USER="root"
	fi
	if [ -z "$BM_GROUP" ]; then
		BM_GROUP="root"
	fi
	
	if [ ! -d $BM_ARCHIVES_REPOSITORY ]
	then
		info "\$BM_ARCHIVES_REPOSITORY does not exist, creating it"
		mkdir $BM_ARCHIVES_REPOSITORY
	fi

	# for security reason, the repository should not be world readable
	# only BM_USER:BM_GROUP can read/write it. 
	# FIXME: maybe putting the umask in the conf woul be good...
	chown $BM_USER:$BM_GROUP $BM_ARCHIVES_REPOSITORY
	chmod 770 $BM_ARCHIVES_REPOSITORY
}

