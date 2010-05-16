# Copyright © 2005-2010 Alexis Sukrieh
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
#
# The backup-manager's md5sum.sh library.
#
# Everything related to md5sum is here.

# This will get a filename a will search its 
# md5hash in the file given as second arg.
function get_md5sum_from_file()
{
    filename="$1"
    md5file="$2"
    debug "get_md5sum_from_file ($filename, $md5file)"

    if [[ -z "$filename" ]] || 
       [[ -z "$md5file" ]]; then
        error "Internal error: bad usage of function get_md5sum_from_file()"
    fi

    if [[ ! -f $md5file ]]; then
        error "No md5file found: \$md5file"
    fi
    
    filename="$(basename $filename)"
    md5=$(grep "$filename" $md5file 2>/dev/null | awk '{print $1}') || md5=""
    
    echo "$md5"
}

# Just return the md5 hash of a file
function get_md5sum()
{
    file="$1"
    debug "get_md5sum ($file)"

    if [[ -f $file ]]; then
        md5=`$md5sum $file 2>/dev/null` || md5=""
        if [[ -z "$md5" ]]; then
            echo "undefined"
        else
            md5=$(echo $md5 | awk '{print $1}')
            echo "$md5"
        fi
    else
        echo "undefined"
    fi
}

# Will take an archive path and the path
# to a MD5 file.
# It will put the md5sum output inside.
# Note that the base name is extracted from
# the given archive path in order to get the 
# MD5 hash from the BM_REPOSITORY_ROOT.
# 
function save_md5_sum()
{
    archive="$1"
    debug "save_md5_sum ($archive)"

    archive=$(basename $archive)
    archive="$BM_REPOSITORY_ROOT/$archive"
    md5file="$2"
    if [[ -f $archive ]]; then
        hash=$(get_md5sum $archive)
        base=$(basename $archive)
        echo "$hash  $base" >> $md5file
    else
        warning "Archive given does not exist in the repository: \$archive"
    fi
}

