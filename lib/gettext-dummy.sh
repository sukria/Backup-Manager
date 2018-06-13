# Copyright © 2005-2018 The Backup Manager Authors
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
# Dummy gettext library to handle gettext call 
# on a system with no gettext at all.


# Here we have to find a way to get the \$foo occurences 
# substituted with value of $foo...
function translate()
{
    out=$(echo "$1" | sed -e 's/\\\$/\$/g')
    out=$(eval "echo \"$out\"")
    echo "$out"
}

function echo_translated()
{
    if [[ "$1" = "-n" ]]; then
        message=$(translate "$2")
        echo -n "$message"
    else
        message=$(translate "$1")
        echo "$message"
    fi
}
