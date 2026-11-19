#! /usr/bin/env bash
# Copyright © 2005-2025 The Backup Manager Authors
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
# conffile just renders warnings but still works as before, and refuse to
# run with a retired confkey instead of silently ignoring it.

# How a configuration key is renamed:
#
# 1. Deprecation. The old name is added to BM__DEPRECATED_CONFKEYS. It keeps
#    working: its value is copied to the new key, with a warning.
#
# 2. Retirement. The entry is moved to BM__RETIRED_CONFKEYS, along with the
#    version it is retired in. From then on, a conffile setting the old name
#    makes backup-manager stop with an error naming the new key.
#
# Never just delete an entry. A key that is not read anymore is silently
# ignored, and the new key falls back to its default value: the archives
# land in another repository, or get purged with the default TTL. An entry
# in BM__RETIRED_CONFKEYS is kept forever, which also prevents a future key
# from reusing a name that used to mean something else.
#
# When retiring a key, also update contrib/upgrade-conffile.sh and the
# "Renamed configuration keys" section of doc/user-guide.sgml.

# Renamed keys that are still honoured.
# Format: "OLD_KEY NEW_KEY"
BM__DEPRECATED_CONFKEYS=(
    "BM_DIRECTORIES BM_TARBALL_DIRECTORIES"
)

# Renamed keys that are not honoured anymore, the run stops if one is set.
# Format: "OLD_KEY NEW_KEY[|OTHER_NEW_KEY] VERSION"
# A key that was split in several new keys lists all of them, separated by
# a pipe.
BM__RETIRED_CONFKEYS=(
    "BM_ARCHIVES_REPOSITORY BM_REPOSITORY_ROOT 1.1"
    "BM_ARCHIVES_PREFIX BM_ARCHIVE_PREFIX 1.1"
    "BM_BACKUP_METHOD BM_ARCHIVE_METHOD 1.1"
    "BM_MAX_TIME_TO_LIVE BM_ARCHIVE_TTL 1.1"
    "BM_PURGE_DUPLICATES BM_ARCHIVE_PURGEDUPS 1.1"
    "BM_USER BM_REPOSITORY_USER 1.1"
    "BM_GROUP BM_REPOSITORY_GROUP 1.1"
    "BM_FILETYPE BM_TARBALL_FILETYPE 1.1"
    "BM_NAME_FORMAT BM_TARBALL_NAMEFORMAT 1.1"
    "BM_DIRECTORIES_BLACKLIST BM_TARBALL_BLACKLIST 1.1"
    "BM_DUMP_SYMLINKS BM_TARBALL_DUMPSYMLINKS 1.1"
    "BM_UPLOAD_MODE BM_UPLOAD_METHOD 1.1"
    "BM_UPLOAD_DIR BM_UPLOAD_DESTINATION 1.1"
    "BM_UPLOAD_KEY BM_UPLOAD_SSH_KEY 1.1"
    "BM_UPLOAD_USER BM_UPLOAD_SSH_USER|BM_UPLOAD_FTP_USER 1.1"
    "BM_UPLOAD_PASSWD BM_UPLOAD_FTP_PASSWORD 1.1"
    "BM_FTP_PURGE BM_UPLOAD_FTP_PURGE 1.1"
    "BM_UPLOAD_FTPPURGE BM_UPLOAD_FTP_PURGE 1.1"
)

# Booleans used to accept "yes" and "no", they only accept "true" and
# "false" since this version.
BM__RETIRED_BOOLEANS_VERSION="1.1"

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

# Refuses to run when a retired key is set, naming its replacement.
# The value is not used in place of the new key: guessing could put the
# archives in the wrong place or purge them with the wrong TTL.
function confkey_refuse_retired()
{
    retired_key="$1"
    new_keys="$2"
    retired_version="$3"
    debug "confkey_refuse_retired ($retired_key, $new_keys, $retired_version)"

    eval "retired_value=\"\${$retired_key-}\"" || retired_value=""

    if [[ -n "$retired_value" ]]; then
        if [[ "$new_keys" = *"|"* ]]; then
            new_keys="${new_keys//|/, }"
            error "The configuration key \"\$retired_key\" was removed in Backup Manager \$retired_version, rename it to one of \$new_keys, depending on your configuration. See contrib/upgrade-conffile.sh."
        else
            error "The configuration key \"\$retired_key\" was removed in Backup Manager \$retired_version, rename it to \"\$new_keys\". See contrib/upgrade-conffile.sh."
        fi
    fi
}

# In version older than 0.6, it was possible to set booleans to "yes" or "no".
# That was honoured with a warning until BM__RETIRED_BOOLEANS_VERSION, it is
# now refused: we cannot tell which keys are booleans, so we cannot safely
# keep overriding the value.
function refuse_retired_booleans()
{
    debug "refuse_retired_booleans()"
    retired_version="$BM__RETIRED_BOOLEANS_VERSION"
    # Every BM_ variable, exported or not: an unexported BM_REPOSITORY_SECURE=yes
    # would otherwise silently read as false.
    for key in $(compgen -v BM_)
    do
        value="${!key}"
        # Be sure to not treat BM_ARCHIVE_PREFIX as a deprecated boolean
        if [[ "$key" != "BM_ARCHIVE_PREFIX" ]]; then
            if [[ "$value" = "yes" ]]; then
                error "The configuration key \$key is set to \"yes\", booleans only accept \"true\" or \"false\" since Backup Manager \$retired_version. Set it to \"true\". See contrib/upgrade-conffile.sh."
            fi
            if [[ "$value" = "no" ]]; then
                error "The configuration key \$key is set to \"no\", booleans only accept \"true\" or \"false\" since Backup Manager \$retired_version. Set it to \"false\". See contrib/upgrade-conffile.sh."
            fi
        fi
    done
}

##############################################################
# Sanitizer - check mandatory configuration keys, handle them
# the best possible, with default values and so on...
#############################################################

# First of all, refuse retired keys and yes/no booleans, then honour the
# deprecated keys, before any default value is applied.
for entry in "${BM__RETIRED_CONFKEYS[@]}"
do
    confkey_refuse_retired $entry
done
refuse_retired_booleans
for entry in "${BM__DEPRECATED_CONFKEYS[@]}"
do
    confkey_handle_deprecated $entry
done

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
    confkey_require "BM_REPOSITORY_USER" "root"
    confkey_require "BM_REPOSITORY_GROUP" "root"
    confkey_require "BM_REPOSITORY_CHMOD" "770"
    confkey_require "BM_ARCHIVE_CHMOD" "660"
fi

confkey_require "BM_REPOSITORY_RECURSIVEPURGE" "false" 

confkey_require "BM_ARCHIVE_TTL" "5"

confkey_require "BM_ARCHIVE_PURGEDUPS" "true"

confkey_require "BM_ARCHIVE_PREFIX" "$HOSTNAME"

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

# BM_TARBALL_BLACKLIST can be either a space-separated list or an array
# (needed for paths with spaces), it is converted to BM__TARBALL_BLACKLIST[].
# see issue #82 for details.
declare -a BM__TARBALL_BLACKLIST
if [[ "$(declare -p BM_TARBALL_BLACKLIST 2>/dev/null)" == "declare -a"* ]]; then
    BM__TARBALL_BLACKLIST=("${BM_TARBALL_BLACKLIST[@]}")
else
    BM__TARBALL_BLACKLIST=($BM_TARBALL_BLACKLIST)
fi

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

if [[ "$BM_ARCHIVE_METHOD" = "mariadb" ]]; then
    confkey_require "BM_MYSQL_ADMINLOGIN" "root"
    confkey_require "BM_MYSQL_HOST" "localhost"
    confkey_require "BM_MYSQL_PORT" ""
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
