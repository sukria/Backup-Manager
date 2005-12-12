#!/bin/sh
#
# Check that every key in the conffile is ok for a proper run.
# Also manage deprecated confkeys the best as possible, so a deprecated
# conffile just renders warnings but still works as before.


# we'll count the number of warnings, here
nb_warnings=0

# For minimizing translations and counting warnings, we globalize the warnings messages
# Please, developers, use this for handling those warnings :)
confkey_warning()
{
	key="$1"
	default="$2"
	nb_warnings=$(($nb_warnings + 1))
	warning "The configuration key \$key is not set, using \"\$default\"."	
}

confkey_warning_deprecated()
{
	deprecated_key="$1"
	deprecated_value="$2"
	new_key="$3"

	nb_warnings=$(($nb_warnings + 1))
	warning "The configuration key \"\$deprecated_key\" is deprecated, you should rename it \"\$new_key\". Using \"\$deprecated_value\"."
}

# Look if the deprecated key exists, if so, warning and use it as 
# a default value for the new key.
confkey_handle_deprecated()
{
	deprecated_key="$1"
	new_key="$2"
	eval "deprecated_value=\"\$$deprecated_key\""

	if [ -n "$deprecated_value" ]; then 
		confkey_warning_deprecated "$deprecated_key" "$deprecated_value" "$new_key"
		eval "$new_key=\"\$deprecated_value\""
		eval "export $new_key"
	fi
}

confkey_require()
{
	key="$1"
	default="$2"
	eval "value=\"\$$key\""

	if [ -z "$value" ]; then
		confkey_warning "$key" "$default"
		eval "$key=\"\$default\""
		eval "export $key"
	fi
}

confkey_error()
{
	key="$1"
	keymandatory="$2"
	error "The configuration key \$key is not set but \$keymandatory is enabled."
}

# In version older than 0.6, it was possible to 
# set booleans to "yes" or "no", that's not more
# valid.
# In order to keep old conffiles working, we automagically
# override yes/no values to true/false, but we trigger 
# a warning.
replace_deprecated_booleans()
{
        for line in $(env)
        do
            key=$(echo "$line" | awk -F '=' '{print $1}')
            value=$(echo "$line" | awk -F '=' '{print $2}')
          
            if [ $(expr match $key BM_) -gt 0 ]; then
                if [ "$value" = "yes" ]; then
                    warning "Deprecated boolean, \$key is set to \"yes\", setting \"true\" instead."
	                nb_warnings=$(($nb_warnings + 1))
                    eval "export $key=\"true\""
                fi
                if [ "$value" = "no" ]; then
                    warning "Deprecated boolean, \$key is set to \"no\", setting \"false\" instead."
	                nb_warnings=$(($nb_warnings + 1))
                    eval "export $key=\"false\""
                fi
            fi
        done    
}

##############################################################
# Sanitizer - check mandatory configuration keys, handle them
# the best possible, with default values and so on...
#############################################################

confkey_handle_deprecated "BM_ARCHIVES_REPOSITORY" "BM_REPOSITORY_ROOT"
confkey_require "BM_REPOSITORY_ROOT" "/var/archives" 

confkey_require "BM_REPOSITORY_SECURE" "true" 
if [ "$BM_REPOSITORY_SECURE" = "true" ]; then
	confkey_handle_deprecated "BM_USER" "BM_REPOSITORY_USER"
	confkey_require "BM_REPOSITORY_USER" "root"
	confkey_handle_deprecated "BM_GROUP" "BM_REPOSITORY_GROUP"
	confkey_require "BM_REPOSITORY_GROUP" "root"
fi

confkey_handle_deprecated "BM_MAX_TIME_TO_LIVE" "BM_ARCHIVE_TTL"
confkey_require "BM_ARCHIVE_TTL" "5"

confkey_handle_deprecated "BM_PURGE_DUPLICATES" "BM_ARCHIVE_PURGEDUPS"
confkey_require "BM_ARCHIVE_PURGEDUPS" "true"

confkey_handle_deprecated "BM_ARCHIVES_PREFIX" "BM_ARCHIVE_PREFIX"
confkey_require "BM_ARCHIVE_PREFIX" "$HOSTNAME"

confkey_handle_deprecated "BM_BACKUP_METHOD" "BM_ARCHIVE_METHOD"
confkey_require "BM_ARCHIVE_METHOD" "tarball"

if [ "$BM_ARCHIVE_METHOD" = "tarball-incremental" ] && 
   [ -z "$BM_TARBALLINC_MASTERDATETYPE" ]; then
        confkey_require "BM_TARBALLINC_MASTERDATETYPE" "weekly"
fi

if [ "$BM_ARCHIVE_METHOD" = "tarball" ]; then

	confkey_handle_deprecated "BM_FILETYPE" "BM_TARBALL_FILETYPE"
	confkey_require "BM_TARBALL_FILETYPE" "tar.gz"

	confkey_handle_deprecated "BM_NAME_FORMAT" "BM_TARBALL_NAMEFORMAT"
	confkey_require "BM_TARBALL_NAMEFORMAT" "long"

	confkey_handle_deprecated "BM_DUMP_SYMLINKS" "BM_TARBALL_DUMPSYMLINKS"
	confkey_require "BM_TARBALL_DUMPSYMLINKS" "false"

	confkey_handle_deprecated "BM_DIRECTORIES" "BM_TARBALL_DIRECTORIES"
	confkey_handle_deprecated "BM_DIRECTORIES_BLACKLIST" "BM_TARBALL_BLACKLIST"
fi

if [ "$BM_UPLOAD_METHOD" = "rsync" ]; then
	confkey_require "BM_UPLOAD_RSYNC_DUMPSYMLINKS" "false"
	confkey_handle_deprecated "BM_UPLOAD_KEY" "BM_UPLOAD_SSH_KEY"
	confkey_handle_deprecated "BM_UPLOAD_USER" "BM_UPLOAD_SSH_USER"
fi

if [ "$BM_ARCHIVE_METHOD" = "mysql" ]; then
	confkey_require "BM_MYSQL_ADMINLOGIN" "root"
	confkey_require "BM_MYSQL_ADMINPASS" ""
	confkey_require "BM_MYSQL_HOST" "localhost"
	confkey_require "BM_MYSQL_PORT" "3306"
	confkey_require "BM_MYSQL_FILETYPE" "tar.gz"
fi

# Burning system
if [ -n "$BM_BURNING_METHOD" ] && 
   [ "$BM_BURNING_METHOD" != "none" ] ; then
	confkey_require "BM_BURNING_DEVICE" "/dev/cdrom"
	confkey_require "BM_BURNING_MAXSIZE" "650"
	confkey_require "BM_BURNING_CHKMD5" "true"
fi

# The SSH stuff

# The FTP stuff

if [ -n "$BM_UPLOAD_MODE" ]; then
	confkey_handle_deprecated "BM_UPLOAD_MODE" "BM_UPLOAD_METHOD"
   
    confkey_handle_deprecated "BM_UPLOAD_USER" "BM_UPLOAD_SSH_USER"
    confkey_handle_deprecated "BM_UPLOAD_KEY" "BM_UPLOAD_SSH_KEY"

    confkey_handle_deprecated "BM_UPLOAD_USER" "BM_UPLOAD_FTP_USER"
    confkey_handle_deprecated "BM_UPLOAD_PASSWD" "BM_UPLOAD_FTP_PASSWORD"
	confkey_handle_deprecated "BM_FTP_PURGE" "BM_UPLOAD_FTP_PURGE"
	confkey_handle_deprecated "BM_UPLOAD_FTPPURGE" "BM_UPLOAD_FTP_PURGE"

    confkey_handle_deprecated "BM_UPLOAD_DIR" "BM_UPLOAD_DESTINATION"
fi        

replace_deprecated_booleans

if [ -z "$BM_LOGGER" ]; then
	confkey_warning "BM_LOGGER" "true"
	export BM_LOGGER="true"
fi

if [ "$BM_LOGGER" = "true" ] && [ -z "$BM_LOGGER_FACILITY" ]; then
	confkey_warning "BM_LOGGER_FACILITY" "user"
	export BM_LOGGER_FACILITY="user"
fi

if [ $nb_warnings -gt 0 ]; then
	warning "When validating the configuration file \$conffile, \$nb_warnings warnings were found."
fi
