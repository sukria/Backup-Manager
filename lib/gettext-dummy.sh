# Dummy gettext library to handle gettext call 
# on a system with no gettext at all.

translate()
{
	echo "$1"
}

echo_translated()
{
	echo "$@"
}
