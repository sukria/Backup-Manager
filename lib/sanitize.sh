#!/BIN/SH
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
confkey_hanlde_deprecated()
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

##############################################################
# Sanitizer - check mandatory configuration keys, hanlde them
# the best possible, with default values and so on...
#############################################################

confkey_hanlde_deprecated "BM_ARCHIVES_REPOSITORY" "BM_REPOSITORY_ROOT"
confkey_require "BM_REPOSITORY_ROOT" "/var/archives" 

confkey_require "BM_REPOSITORY_SECURE" "yes" 
if [ "$BM_REPOSITORY_SECURE" = "yes" ]; then
	confkey_hanlde_deprecated "BM_USER" "BM_REPOSITORY_USER"
	confkey_require "BM_REPOSITORY_USER" "root"
	confkey_hanlde_deprecated "BM_GROUP" "BM_REPOSITORY_GROUP"
	confkey_require "BM_REPOSITORY_GROUP" "root"
fi

confkey_hanlde_deprecated "BM_MAX_TIME_TO_LIVE" "BM_ARCHIVE_TTL"
confkey_require "BM_ARCHIVE_TTL" "5"

confkey_hanlde_deprecated "BM_PURGE_DUPLICATES" "BM_ARCHIVE_PURGEDUPS"
confkey_require "BM_ARCHIVE_PURGEDUPS" "yes"

confkey_hanlde_deprecated "BM_ARCHIVES_PREFIX" "BM_ARCHIVE_PREFIX"
confkey_require "BM_ARCHIVE_PREFIX" "$HOSTNAME"

confkey_hanlde_deprecated "BM_BACKUP_METHOD" "BM_ARCHIVE_METHOD"
confkey_require "BM_ARCHIVE_METHOD" "tarball"

if [ "$BM_ARCHIVE_METHOD" = "tarball-incremental" ] && 
   [ -z "$BM_TARBALLINC_MASTERDATETYPE" ]; then
        confkey_require "BM_TARBALLINC_MASTERDATETYPE" "weekly"
fi

if [ "$BM_ARCHIVE_METHOD" = "tarball" ]; then

	confkey_hanlde_deprecated "BM_FILETYPE" "BM_TARBALL_FILETYPE"
	confkey_require "BM_TARBALL_FILETYPE" "tar.gz"

	confkey_hanlde_deprecated "BM_NAME_FORMAT" "BM_TARBALL_NAMEFORMAT"
	confkey_require "BM_TARBALL_NAMEFORMAT" "long"

	confkey_hanlde_deprecated "BM_DUMP_SYMLINKS" "BM_TARBALL_DUMPSYMLINKS"
	confkey_require "BM_TARBALL_DUMPSYMLINKS" "no"

	confkey_hanlde_deprecated "BM_DIRECTORIES" "BM_TARBALL_DIRECTORIES"
	confkey_hanlde_deprecated "BM_DIRECTORIES_BLACKLIST" "BM_TARBALL_BLACKLIST"
fi

if [ "$BM_ARCHIVE_METHOD" = "rsync" ]; then
	confkey_hanlde_deprecated "BM_TARBALL_DUMPSYMLINKS" "BM_RSYNC_DUMPSYMLINKS"
	confkey_require "BM_RSYNC_DUMPSYMLINKS" "no"

	confkey_hanlde_deprecated "BM_TARBALL_DIRECTORIES" "BM_RSYNC_DIRECTORIES"
	confkey_hanlde_deprecated "BM_UPLOAD_HOSTS" "BM_RSYNC_HOSTS"
	confkey_hanlde_deprecated "BM_UPLOAD_KEY" "BM_UPLOAD_SSH_KEY"
	confkey_hanlde_deprecated "BM_UPLOAD_USER" "BM_UPLOAD_SSH_USER"
fi

if [ "$BM_ARCHIVE_METHOD" = "mysql" ]; then
	confkey_require "BM_MYSQL_ADMINLOGIN" "root"
	confkey_require "BM_MYSQL_ADMINPASS" ""
	confkey_require "BM_MYSQL_HOST" "localhost"
	confkey_require "BM_MYSQL_PORT" "3306"
	confkey_require "BM_MYSQL_FILETYPE" "tar.gz"
fi

# Burning system
if [ "$BM_BURNING" = "yes" ]; then
	confkey_require "BM_BURNING_DEVICE" "/dev/cdrom"
	confkey_require "BM_BURNING_METHOD" "CDRW"
	confkey_require "BM_BURNING_MAXSIZE" "650"
	confkey_require "BM_BURNING_CHKMD5" "yes"
fi

# The SSH stuff

# The FTP stuff

if [ -n "$BM_UPLOAD_MODE" ]; then
	confkey_hanlde_deprecated "BM_UPLOAD_MODE" "BM_UPLOAD_METHOD"
   
    confkey_hanlde_deprecated "BM_UPLOAD_USER" "BM_UPLOAD_SSH_USER"
    confkey_hanlde_deprecated "BM_UPLOAD_KEY" "BM_UPLOAD_SSH_KEY"

    confkey_hanlde_deprecated "BM_UPLOAD_USER" "BM_UPLOAD_FTP_USER"
    confkey_hanlde_deprecated "BM_UPLOAD_PASSWD" "BM_UPLOAD_FTP_PASSWORD"
	confkey_hanlde_deprecated "BM_FTP_PURGE" "BM_UPLOAD_FTP_PURGE"
	confkey_hanlde_deprecated "BM_UPLOAD_FTPPURGE" "BM_UPLOAD_FTP_PURGE"

    confkey_hanlde_deprecated "BM_UPLOAD_DIR" "BM_UPLOAD_DESTINATION"
fi        

if [ -z "$BM_LOGGER" ]; then
	confkey_warning "BM_LOGGER" "yes"
	export BM_LOGGER="yes"
fi

if [ "$BM_LOGGER" = "yes" ] && [ -z "$BM_LOGGER_FACILITY" ]; then
	confkey_warning "BM_LOGGER_FACILITY" "user"
	export BM_LOGGER_FACILITY="user"
fi

if [ $nb_warnings -gt 0 ]; then
	warning "When validating the configuration file \$conffile, \$nb_warnings warnings were found."
fi
