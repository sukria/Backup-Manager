#! /bin/bash

if [ -z "$1" ]; then
	echo "No file given"
	exit 1
fi

lib="/usr/share/backup-manager"

source $lib/gettext.sh
source $lib/dialog.sh
source $lib/logger.sh
source "$1"
source $lib/sanitize.sh

exit 0
