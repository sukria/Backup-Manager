# Copyright (C) 2010 The Backup Manager Authors
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
# This is a wrapper to the gettext API for shell scripts.

# If /usr/bin/gettext.sh is not found, we'll 
# provide a dummy function.

if [[ -z "$libdir" ]]; then
    libdir="/usr/share/backup-manager"
fi    
libgettext="/usr/bin/gettext.sh"

if [[ ! -f $libgettext ]]; then
    . $libdir/gettext-dummy.sh
else
    . $libdir/gettext-real.sh
fi
