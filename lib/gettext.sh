# This is a wrapper to the gettext API for shell scripts.

# If /usr/bin/gettext.sh is not found, we'll 
# provide a dummy function.

libdir="/usr/lib/backup-manager"
libgettext="/usr/bin/gettext.sh"

if [ ! -f $libgettext ]; then
	. $libdir/gettext-dummy.sh
else
	. $libdir/gettext-real.sh
fi
