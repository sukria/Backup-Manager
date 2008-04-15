# Copyright � 2007 Rached Ben Mustapha
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
# The backup-manager's dbus.sh library.
#
# If the dbus utilities are installed, these functions send
# signals on the bus, (system or session one, as appropriate)
# so that other processes on the system can react to backup
# events, and thus increase the hype-level of backup-manager.
#
# These interfaces are still experimental and are subject to
# change.
# 

# Message contents:
# * int32 percentage
# * string label (human-readable string describing what is
#                 currently being done)
PROGRESS_INTERFACE="org.backupmanager.BackupManager.ProgressNotify"

# Message contents:
# * string event_name (one of "startup", "shutdown")
# * string argument (details of the event)
EVENT_INTERFACE="org.backupmanager.BackupManager.EventNotify"

# Message contents:
# * string level (one of debug, info, warning, error)
# * string message (possibly truncated to fit in a dbus message)
LOG_MESSAGE_INTERFACE="org.backupmanager.BackupManager.LogMessageNotify"

SYSTEM_BUS_OBJECT="/org/backupmanager/instance/SystemInstance"
USER_BUS_OBJECT="/org/backupmanager/instance/UserInstance/${USERNAME}"

bm_dbus_init()
{
    debug "bm_dbus_init()"
    dbus_send=$(which dbus-send) || true

    if [ -x "${dbus_send}" ]; then
        if [ "${UID}" = "0" ]; then
            bus_type="system"
            bus_object=${SYSTEM_BUS_OBJECT}
        else
            bus_type="session"
            bus_object=${USER_BUS_OBJECT}
        fi

        dbus_send_cmd="${dbus_send} --${bus_type} --type=signal ${bus_object}"
    else
        dbus_send_cmd=""
    fi
}

bm_dbus_send_progress()
{
    local percentage label
    percentage=${1}
    label=${2}

    if [ -n "${dbus_send_cmd}" ]; then
        ${dbus_send_cmd} ${PROGRESS_INTERFACE} int32:"${percentage}" string:"${label}" || true
    fi
}

bm_dbus_send_log_message()
{
    local level message
    level=${1}
    message=${2}

    if [ -n "${dbus_send_cmd}" ]; then
        ${dbus_send_cmd} ${LOG_MESSAGE_INTERFACE} string:"${level}" string:"${message}" || true
    fi
}

bm_dbus_send_event()
{
    local event_name details
    event_name=${1}
    details=${2}

    if [ -n "${dbus_send_cmd}" ]; then
        ${dbus_send_cmd} ${EVENT_INTERFACE} string:"${event_name}" string:"${details}" || true
    fi
}

