# Real gettext library.

# Initialize the gettext stuff
. /usr/bin/gettext.sh
TEXTDOMAIN=backup-manager
export TEXTDOMAIN

# This is the wrapper to the gettext function
# We use eval_gettext in order to substitue every
# variable prensent in the string.
translate()
{
	eval_gettext "$1"; echo
}

# This can do an echo with -n or not, and after 
# having gettextized the string.
echo_translated()
{
	if [ "$1" = "-n" ]; then
		message=$(translate "$2")
		echo -n "$message"
	else
		message=$(translate "$1")
		echo "$message"
	fi
}
