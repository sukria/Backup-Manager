# This is the logger library
# It can print stuff on STDIN, STDERR and send messages
# to syslog


if [ -z "$BM_LOGGER" ]; then
	BM_LOGGER="true"
fi

if [ -z "$BM_LOGGER_FACILITY" ]; then
	BM_LOGGER_FACILITY="user"
fi

if [ -x /usr/bin/logger ]; then
	logger=/usr/bin/logger

else
	BM_LOGGER="false"
fi


#########################################
# The syslog() function should be called 
# for sending messages to syslog.
#
# Note that no messages will be sent to 
# syslog if BM_LOGGER is set to "no".
#
# ex:
#      syslog "info" "message to log"
#
#########################################
syslog()
{
	if [ "$BM_LOGGER" = "true" ]; then	
		level="$1"
		message="$2"
		$logger -t "backup-manager[$$]" -p "${BM_LOGGER_FACILITY}.${level}" -- "$level * $message"	
	fi
}

# The meta function to log something to syslog, and 
# eventually print it to the appropriate STDOUT
#
# $@ should be the same args as for a echo stanza.
# 
# $bm_log_level should be "info", "warning" or "error".
#
log() 
{
	# set the default log level if none given
	if [ -z "$bm_log_level" ]; then
		bm_log_level="info"
	fi
	
	# choose the good switch to read if needed
	case "$bm_log_level" in
		"debug")
			bm_log_level=$debug
		;;
		"info")
			bm_log_switch=$verbose
		;;
		"warning")
			bm_log_switch=$warnings
		;;
		# in the default case, we print stuff
		*)
			bm_log_switch="true"
		;;
	esac
	
	# if there's the -n switch, we buffer the message 
	if [ "$1" = "-n" ]; then
		# output the message to STDOUT
		message=$(echo_translated "$@")
		if [ "$bm_log_switch" = "true" ]; then
			echo -n "${message}"
		fi
		BM_LOG_BUFFER="${BM_LOG_BUFFER}${message}"
	
	else
		# output the message to STDOUT
		message=$(echo_translated "$@")
		if [ "$bm_log_switch" == "true" ]; then
			echo "${message}"
		fi
		# log the message to syslog
		syslog $bm_log_level "${BM_LOG_BUFFER}${message}"
		# we have now to flush the buffer
		BM_LOG_BUFFER=""
	fi
}

info()
{
	bm_log_level="info"
	log "$@"
}

error()
{
	bm_log_level="error"
	log "$@"
	_exit 1
}

debug()
{
	bm_log_level="debug"
	log "$@"
}

warning()
{
	bm_log_level="warning"
	log "$@"
}


# that's the way backup-manager should exit.
# need to remove the lock before, clean the mountpoint and 
# remove the logfile
_exit()
{
	info "Releasing lock"
	release_lock

	unmount_tmp_dir

	exit $@
}
