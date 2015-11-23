#! /usr/bin/env bash
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
#
# Check that every key in the conffile is ok for a proper run.
# Also manage deprecated confkeys the best as possible, so a deprecated
# conffile just renders warnings but still works as before.

# we'll count the number of warnings, here
nb_warnings=0

# For minimizing translations and counting warnings, we globalize the warnings messages
# Please, developers, use this for handling those warnings :)
function confkey_warning()
{
    key="$1"
    default="$2"
    debug "confkey_warning ($key, $default)"

    nb_warnings=$(($nb_warnings + 1))
    warning "The configuration key \$key is not set, using \"\$default\"."  
}

function confkey_warning_deprecated()
{
    deprecated_key="$1"
    deprecated_value="$2"
    new_key="$3"
    debug "confkey_warning_deprecated ($deprecated_key, $deprecated_value, $new_key)"

    nb_warnings=$(($nb_warnings + 1))
    warning "The configuration key \"\$deprecated_key\" is deprecated, you should rename it \"\$new_key\". Using \"\$deprecated_value\"."
}

# Look if the deprecated key exists, if so, warning and use it as 
# a default value for the new key.
function confkey_handle_deprecated()
{
    deprecated_key="$1"
    new_key="$2"
    debug "confkey_handle_deprecated ($deprecated_key, $new_key)"

    eval "deprecated_value=\"\$$deprecated_key\"" || deprecated_value=""

    if [[ -n "$deprecated_value" ]]; then 
        confkey_warning_deprecated "$deprecated_key" "$deprecated_value" "$new_key"
        eval "$new_key=\"\$deprecated_value\""
        eval "export $new_key"
    fi
}

function confkey_require()
{
    key="$1"
    default="$2"
    debug "confkey_require ($key, $default)"

    eval "value=\"\$$key\""

    if [[ -z "$value" ]]; then
        confkey_warning "$key" "$default"
        eval "$key=\"\$default\""
        eval "export $key"
    fi
}

function confkey_error()
{
    key="$1"
    keymandatory="$2"
    debug "confkey_error ($key, $keymandatory)"

    error "The configuration key \$key is not set but \$keymandatory is enabled."
}

# In version older than 0.6, it was possible to set booleans to "yes" or "no",
# that's not valid anymore. In order to be backward compatible, we override yes/no
# values to true/false, but we trigger a warning.
function replace_deprecated_booleans()
{
    debug "replace_deprecated_booleans()"
    for line in $(env)
    do
        key=$(echo "$line" | awk -F '=' '{print $1}')
        value=$(echo "$line" | awk -F '=' '{print $2}')
        # Be sure to not treat BM_ARCHIVE_PREFIX as a deprecated boolean
        if [[ "$key" != "BM_ARCHIVE_PREFIX" ]]; then
            if [[ -n "$key" ]]; then
                if [[ $(expr match "$key" BM_) -gt 0 ]]; then
                    if [[ "$value" = "yes" ]]; then
                        warning "Deprecated boolean, \$key is set to \"yes\", setting \"true\" instead."
                        nb_warnings=$(($nb_warnings + 1))
                        eval "export $key=\"true\""
                    fi
                    if [[ "$value" = "no" ]]; then
                        warning "Deprecated boolean, \$key is set to \"no\", setting \"false\" instead."
                        nb_warnings=$(($nb_warnings + 1))
                        eval "export $key=\"false\""
                    fi
                fi
            fi
        fi
    done    
}

##############################################################
# Sanitizer - check mandatory configuration keys, handle them
# the best possible, with default values and so on...
#############################################################

# First of all replace yes/no booleans with true/false ones.
replace_deprecated_booleans
confkey_handle_deprecated "BM_ARCHIVES_REPOSITORY" "BM_REPOSITORY_ROOT"
confkey_require "BM_REPOSITORY_ROOT" "/var/archives" 

# The temp dir used by BM
confkey_require "BM_TEMP_DIR" "/tmp" 
# creating the temp path if not found
if [[ ! -d "$BM_TEMP_DIR" ]]; then
    mkdir "$BM_TEMP_DIR" || error "Unable to create BM_TEMP_DIR: \"\$BM_TEMP_DIR\"."
fi

# let's drop the trailing slash, if any.
export BM_REPOSITORY_ROOT="${BM_REPOSITORY_ROOT%/}"

confkey_require "BM_REPOSITORY_SECURE" "true" 
if [[ "$BM_REPOSITORY_SECURE" = "true" ]]; then
    confkey_handle_deprecated "BM_USER" "BM_REPOSITORY_USER"
    confkey_require "BM_REPOSITORY_USER" "root"
    confkey_handle_deprecated "BM_GROUP" "BM_REPOSITORY_GROUP"
    confkey_require "BM_REPOSITORY_GROUP" "root"
    confkey_require "BM_REPOSITORY_CHMOD" "770"
    confkey_require "BM_ARCHIVE_CHMOD" "660"
fi

confkey_require "BM_REPOSITORY_RECURSIVEPURGE" "false" 

confkey_handle_deprecated "BM_MAX_TIME_TO_LIVE" "BM_ARCHIVE_TTL"
confkey_require "BM_ARCHIVE_TTL" "5"

confkey_handle_deprecated "BM_PURGE_DUPLICATES" "BM_ARCHIVE_PURGEDUPS"
confkey_require "BM_ARCHIVE_PURGEDUPS" "true"

confkey_handle_deprecated "BM_ARCHIVES_PREFIX" "BM_ARCHIVE_PREFIX"
confkey_require "BM_ARCHIVE_PREFIX" "$HOSTNAME"

confkey_handle_deprecated "BM_BACKUP_METHOD" "BM_ARCHIVE_METHOD"
confkey_require "BM_ARCHIVE_METHOD" "tarball"

confkey_require "BM_ARCHIVE_NICE_LEVEL" "10"

if [[ "$BM_ARCHIVE_METHOD" = "tarball-incremental" ]] && 
   [[ -z "$BM_TARBALLINC_MASTERDATETYPE" ]]; then
        confkey_require "BM_TARBALLINC_MASTERDATETYPE" "weekly"
fi
if [[ -n "$BM_TARBALLINC_MASTERDATEVALUE" ]]; then
    if [[ "$BM_TARBALLINC_MASTERDATEVALUE" -gt "6" ]]; then
        if [[ "$BM_TARBALLINC_MASTERDATETYPE" = "weekly" ]]; then
            warning "BM_TARBALLINC_MASTERDATEVALUE should not be greater than 6, falling back to 0"
            export BM_TARBALLINC_MASTERDATEVALUE="0"
        else
        # monthly
            if [[ "$BM_TARBALLINC_MASTERDATEVALUE" -gt "31" ]]; then
                warning "BM_TARBALLINC_MASTERDATEVALUE should not be greater than 31, falling back to 1"
                export BM_TARBALLINC_MASTERDATEVALUE="1"
            fi
        fi
    fi
fi

if [[ "$BM_ARCHIVE_METHOD" = "tarball" ]] || 
   [[ "$BM_ARCHIVE_METHOD" = "tarball-incremental" ]] ; then
    confkey_require "BM_TARBALL_FILETYPE" "tar.gz"
    confkey_require "BM_TARBALL_NAMEFORMAT" "long"
    confkey_require "BM_TARBALL_DUMPSYMLINKS" "false"
fi

confkey_handle_deprecated "BM_FILETYPE" "BM_TARBALL_FILETYPE"
confkey_handle_deprecated "BM_NAME_FORMAT" "BM_TARBALL_NAMEFORMAT"
confkey_handle_deprecated "BM_DIRECTORIES_BLACKLIST" "BM_TARBALL_BLACKLIST"
confkey_handle_deprecated "BM_DUMP_SYMLINKS" "BM_TARBALL_DUMPSYMLINKS"

# encryption stuff goes here
if [[ "$BM_ENCRYPTION_METHOD" = "gpg" ]]; then
    if [[ -z "$BM_ENCRYPTION_RECIPIENT" ]]; then
        confkey_error "BM_ENCRYPTION_RECIPIENT" "BM_ENCRYPTION_METHOD"
    fi
fi

# The TARBALL_OVER_SSH thing
if [[ "$BM_TARBALL_OVER_SSH" = "true" ]]; then
    if [[ -z "$BM_UPLOAD_SSH_HOSTS" ]]; then
        confkey_error "BM_UPLOAD_SSH_HOSTS" "BM_TARBALL_OVER_SSH"
    fi
    if [[ -z "$BM_UPLOAD_SSH_KEY" ]]; then
        confkey_error "BM_UPLOAD_SSH_KEY" "BM_TARBALL_OVER_SSH"
    fi
    if [[ -z "$BM_UPLOAD_SSH_USER" ]]; then
        confkey_error "BM_UPLOAD_SSH_USER" "BM_TARBALL_OVER_SSH"
    fi
    confkey_require "BM_UPLOAD_SSH_PORT" "22"
fi

# Converting anything in BM_TARBALL_DIRECTORIES in the array BM_TARBALL_TARGETS[].
# see bug #86 for details.
if [[ -n "$BM_DIRECTORIES" ]]; then
    BM_TARBALL_DIRECTORIES="$BM_DIRECTORIES"
fi
if [[ -n "$BM_TARBALL_DIRECTORIES" ]]; then
    declare -a BM_TARBALL_TARGETS
    index=0
    for target in $BM_TARBALL_DIRECTORIES
    do
        BM_TARBALL_TARGETS[$index]="$target"
        index=$(($index + 1))
    done
fi

if [[ "$BM_UPLOAD_METHOD" = "rsync" ]]; then
    confkey_require "BM_UPLOAD_RSYNC_DUMPSYMLINKS" "false"
    confkey_handle_deprecated "BM_UPLOAD_KEY" "BM_UPLOAD_SSH_KEY"
    confkey_handle_deprecated "BM_UPLOAD_USER" "BM_UPLOAD_SSH_USER"
fi

if [[ "$BM_UPLOAD_METHOD" = "ssh" ]]; then
    confkey_require "BM_UPLOAD_SSH_PORT" "22"
fi

if [[ "$BM_UPLOAD_METHOD" = "ftp" ]]; then
    confkey_require "BM_UPLOAD_FTP_TIMEOUT" "120"
fi

if [[ "$BM_ARCHIVE_METHOD" = "mysql" ]]; then
    confkey_require "BM_MYSQL_ADMINLOGIN" "root"
    confkey_require "BM_MYSQL_HOST" "localhost"
    confkey_require "BM_MYSQL_PORT" "3306"
    confkey_require "BM_MYSQL_FILETYPE" "tar.gz"
fi

if [[ "$BM_ARCHIVE_METHOD" = "pgsql" ]]; then
    confkey_require "BM_PGSQL_ADMINLOGIN" "root"
    confkey_require "BM_PGSQL_HOST" "localhost"
    confkey_require "BM_PGSQL_PORT" "3306"
    confkey_require "BM_PGSQL_FILETYPE" "tar.gz"
fi

# Burning system
if [[ -n "$BM_BURNING" ]]; then
        case "$BM_BURNING" in 
            ""|"no"|"false"|"none")
                BM_BURNING_METHOD="none"
            ;;
        esac
fi        

if [[ -n "$BM_BURNING_METHOD" ]] && 
   [[ "$BM_BURNING_METHOD" != "none" ]] ; then
    confkey_require "BM_BURNING_DEVICE" "/dev/cdrom"
    confkey_require "BM_BURNING_MAXSIZE" "650"
    confkey_require "BM_BURNING_CHKMD5" "true"
fi

if [[ -n "$BM_UPLOAD_MODE" ]]; then
    confkey_handle_deprecated "BM_UPLOAD_MODE" "BM_UPLOAD_METHOD"
   
    confkey_handle_deprecated "BM_UPLOAD_USER" "BM_UPLOAD_SSH_USER"
    confkey_handle_deprecated "BM_UPLOAD_KEY" "BM_UPLOAD_SSH_KEY"

    confkey_handle_deprecated "BM_UPLOAD_USER" "BM_UPLOAD_FTP_USER"
    confkey_handle_deprecated "BM_UPLOAD_PASSWD" "BM_UPLOAD_FTP_PASSWORD"
    confkey_handle_deprecated "BM_FTP_PURGE" "BM_UPLOAD_FTP_PURGE"
    confkey_handle_deprecated "BM_UPLOAD_FTPPURGE" "BM_UPLOAD_FTP_PURGE"

    confkey_handle_deprecated "BM_UPLOAD_DIR" "BM_UPLOAD_DESTINATION"
fi        

if [[ -z "$BM_ARCHIVE_STRICTPURGE" ]]; then
    confkey_require "BM_ARCHIVE_STRICTPURGE" "true"
fi

confkey_require "BM_LOGGER" "true"
if [[ "$BM_LOGGER" = "true" ]]; then 
    confkey_require "BM_LOGGER_FACILITY" "user"
    confkey_require "BM_LOGGER_LEVEL" "warning"
fi

if [[ $nb_warnings -gt 0 ]]; then
    warning "When validating the configuration file \$conffile, \$nb_warnings warnings were found."
fi
