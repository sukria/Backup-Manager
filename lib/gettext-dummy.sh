# Dummy gettext library to handle gettext call 
# on a system with no gettext at all.


# Here we have to find a way to get the \$foo occurences 
# substituted with value of $foo...
translate()
{
	out=$(echo "$1" | sed -e 's/\\\$/\$/g')
	out=$(eval "echo \"$out\"")
	echo "$out"
}

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
