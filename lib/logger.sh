# Copyright © 2005-2015 The Backup Manager Authors
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

# This is the logger library
# It can print stuff on STDIN, STDERR and send messages
# to syslog.

function check_logger()
{
    if [[ -x /usr/bin/logger ]]; then
        logger=/usr/bin/logger
    else
        BM_LOGGER="false"
    fi
}

#########################################
# The syslog() function should be called 
# for sending messages to syslog.
#
# Note that no messages will be sent to 
# syslog if BM_LOGGER is set to "false".
#
# ex:
#      syslog "info" "message to log"
#
#########################################
function syslog()
{
    if [[ "$BM_LOGGER" = "true" ]]; then  
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
function log() 
{
    # set the default log level if none given
    if [[ -z "$bm_log_level" ]]; then
        bm_log_level="info"
    fi
    
    # choose the good switch to read if needed
    case "$bm_log_level" in
        "debug")
            bm_log_switch=$verbosedebug
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
    
    log_buffer=""
    # if there's the -n switch, we buffer the message 
    if [[ "$1" == "-n" ]]; then
        # output the message to STDOUT
        message=$(echo_translated "$@")
        if [[ "$bm_log_switch" == "true" ]]; then
            echo -n "${message}"
        fi
        BM_LOG_BUFFER="${log_buffer}${message}"
    
    else
        # output the message to STDOUT
        message=$(echo_translated "$@")
        if [[ "$bm_log_switch" == "true" ]]; then
            if [[ "$bm_log_level" == "debug" ]]; then
                echo "${message}" >&2
            else
                echo "${message}"
            fi
            bm_dbus_send_log_message "${bm_log_level}" "${message}"
        fi
        # log the message to syslog
        syslog $bm_log_level "${log_buffer}${message}"
        # we have now to flush the buffer
        BM_LOG_BUFFER=""
    fi
}

# That function is deprecated, soon we'll remove it.
function __debug()
{
    message="$1"
    echo "DEPRECATED DEBUG: $message" >&2
}

function debug()
{
    if [[ "$BM_LOGGER_LEVEL" == "debug" ]]; then
        bm_log_level="debug"
        log "DEBUG: $@"
    fi
}

function info()
{
    if [[ "$BM_LOGGER_LEVEL" == "debug" ]]\
    || [[ "$BM_LOGGER_LEVEL" == "info" ]]; then
        bm_log_level="info"
        log "$@"
    fi
}

function warning()
{
    if [[ "$BM_LOGGER_LEVEL" == "debug" ]]\
    || [[ "$BM_LOGGER_LEVEL" == "info" ]]\
    || [[ "$BM_LOGGER_LEVEL" == "warning" ]]; then
        bm_log_level="warning"
        log "$@"
    fi
}

# Errors are always sent to syslog
function error()
{
    bm_log_level="error"
    log "$@"
    _exit 1
}


# that's the way backup-manager should exit.
# need to remove the lock before, clean the mountpoint and 
# remove the logfile
function _exit()
{
	exit_code="$1"
	exit_context="$2"
	exit_reason="$3"

    if [[ "$exit_context" != "POST_COMMAND" ]]; then
		exec_post_command || error "Unable to exec post-command."
	fi

    umask $BM_UMASK >/dev/null
    info "Releasing lock"
    release_lock
    bm_dbus_send_progress 100 "Finished"
    bm_dbus_send_event "shutdown" "$@"

	if [[ -n "$exit_reason" ]]; then 
		info "Exit reason: \$exit_reason"
	fi
    exit $exit_code
}
