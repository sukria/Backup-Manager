# Copyright © 2005-2016 The Backup Manager Authors
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
# Real gettext library.

# Initialize the gettext stuff
. /usr/bin/gettext.sh
TEXTDOMAIN=backup-manager
export TEXTDOMAIN

# This is the wrapper to the gettext function
# We use eval_gettext in order to substitue every
# variable prensent in the string.
function translate()
{
    eval_gettext "$1"; echo
}

# This can do an echo with -n or not, and after 
# having gettextized the string.
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
