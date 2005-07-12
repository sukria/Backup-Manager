#!/bin/sh
#
# Check that every key in the conffile is ok for a proper run.


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

confkey_error()
{
	key="$1"
	keymandatory="$2"
	error "The configuration key \$key is not set but \$keymandatory is enabled."
}

# Global stuff
if [ -z "$BM_ARCHIVES_REPOSITORY" ]; then
	confkey_warning "BM_ARCHIVES_REPOSITORY" "/var/archives"
	export BM_ARCHIVES_REPOSITORY="/var/archives"
fi

if [ -z "$BM_NAME_FORMAT" ]; then
	confkey_warning "BM_NAME_FORMAT" "long"
	export BM_NAME_FORMAT="long"
fi

if [ -z "$BM_FILETYPE" ]; then
	confkey_warning "BM_FILETYPE" "tar.gz"
	export BM_FILETYPE="tar.gz"
fi

if [ -z "$BM_MAX_TIME_TO_LIVE" ]; then
	confkey_warning "BM_MAX_TIME_TO_LIVE" "5"
	export BM_MAX_TIME_TO_LIVE="5"
fi

if [ -z "$BM_BACKUP_METHOD" ]; then
	confkey_warning "BM_BACKUP_METHOD" "tarball"
	export BM_BACKUP_METHOD="tarball"
fi

if [ -z "$BM_DUMP_SYMLINKS" ]; then
	confkey_warning "BM_DUMP_SYMLINKS" "no"
	export BM_DUMP_SYMLINKS="no"
fi

if [ -z "$BM_PURGE_DUPLICATES" ]; then
	confkey_warning "BM_PURGE_DUPLICATES" "yes"
	export BM_PURGE_DUPLICATES="yes"
fi

if [ -z "$BM_ARCHIVES_PREFIX" ]; then
	confkey_warning "BM_ARCHIVES_PREFIX" "$HOSTNAME"
	export BM_ARCHIVES_PREFIX="$HOSTNAME"
fi

if [ -z "$BM_REPOSITORY_SECURE" ]; then
	confkey_warning "BM_REPOSITORY_SECURE" "yes"
	export BM_REPOSITORY_SECURE="yes"
fi

# Secure repository
if [ "$BM_REPOSITORY_SECURE" = "yes" ]; then
	if [ -z "$BM_USER" ]; then
		confkey_warning "BM_USER" "root"
		export BM_USER="root"
	fi
	if [ -z "$BM_GROUP" ]; then
		confkey_warning "BM_GROUP" "root"
		export BM_GROUP="root"
	fi
fi

# Burning system
if [ "$BM_BURNING" = "yes" ]; then
	if [ -z "$BM_BURNING_DEVICE" ]; then
		confkey_warning "BM_BURNING_DEVICE" "/dev/cdrom"
		export BM_BURNING_DEVICE="/dev/cdrom"
	fi

	if [ -z "$BM_BURNING_METHOD" ]; then
		confkey_warning "BM_BURNING_METHOD" "CDRW"
		export BM_BURNING_METHOD="CDRW"
	fi

	if [ -z "$BM_BURNING_MAXSIZE" ]; then
		confkey_warning "BM_BURNING_MAXSIZE" "650"
		export BM_BURNING_MAXSIZE="650"
	fi

	if [ -z "$BM_BURNING_CHKMD5" ]; then
		confkey_warning "BM_BURNING_CHKMD5" "yes"
		export BM_BURNING_CHKMD5="yes"
	fi
fi

# the upload system
if [ -n "$BM_UPLOAD_HOSTS" ]; then
	if [ -z "$BM_FTP_PURGE" ]; then
		confkey_warning "BM_FTP_PURGE" "no"
		export BM_FTP_PURGE="no"
	fi
	
	if [ -z "$BM_UPLOAD_USER" ]; then
		confkey_error "BM_UPLOAD_USER" "BM_UPLOAD_HOSTS"
	fi

	if [ "$BM_UPLOAD_MODE" = "ftp" ] && [ -z "$BM_UPLOAD_PASSWD" ]; then
		# This one is not globalizable, the message is a real specific one.
		error "The configuration key BM_UPLOAD_PASSWD is not set but BM_UPLOAD_MODE is set to \"ftp\"."
	fi

	if [ -z "$BM_UPLOAD_MODE" ]; then
		confkey_error "BM_UPLOAD_MODE" "BM_UPLOAD_HOSTS"
	fi
	
	if [ -z "$BM_UPLOAD_DIR" ]; then
		confkey_error "BM_UPLOAD_DIR" "BM_UPLOAD_HOSTS"
	fi
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
