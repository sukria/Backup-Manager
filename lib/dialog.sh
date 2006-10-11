# Copyright © 2005-2006 The Backup Manager Authors
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

	_exit 0
}

# this is the callback wich is run when backup-manager
# is stopped with a signal like SIGTERM or SIGKILL
# see the trap stuff ;)
# So the only thing to do is to release the lock before.
stop_me()
{
	echo ""
	error "Warning, process interrupted, archives may be corrupted."
	release_lock
}


# Prompt the user with a question, set $BM_RET to "true" if the user agreed,
# to "false" if not.
# PLEASE use translate() for giving a question to that function!
function bm_prompt()
{
    # this must be translated here, I cannot do it here! 
    question="$1"
         
    if ! tty -s ; then
        error "Not in interactive mode, cannot continue."
    fi
    
    echo -n "$question "; echo "[y/N] "
    read ret
    
    if [ "$ret" == "y" ] || [ "$ret" == "Y" ]; then
        export BM_RET="true"
    else 
        export BM_RET="false"
    fi
}

# Prints a message and wait for the user to press enter.
function bm_pause()
{
    message="$1"

    if ! tty -s ; then
        error "Not in interactive mode, cannot continue."
    fi

    echo -n "$message "
    read pause
}

function tail_logfile
{
    logfile="$1"
    if [ "$verbosedebug" == "true" ]; then
        debug "Outping content of $logfile to stderr"
        tail -f $logfile &
    fi
}
