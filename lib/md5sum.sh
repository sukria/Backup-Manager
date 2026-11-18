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


# Will take the path to a MD5 file and remove
# every entry whose archive does not exist anymore
# in the directory of that MD5 file.
# Lines that cannot be parsed are kept as is.
function clean_md5_file()
{
    md5file="$1"
    debug "clean_md5_file ($md5file)"

    if [[ -z "$md5file" ]]; then
        error "Internal error: bad usage of function clean_md5_file()"
    fi

    if [[ ! -f "$md5file" ]]; then
        return 0
    fi

    md5dir=$(dirname "$md5file")
    md5file_tmp=$(mktemp ${BM_TEMP_DIR}/bm-md5.XXXXXX)
    nb_removed=0

    while IFS= read -r line || [[ -n "$line" ]]
    do
        archive="${line#*  }"
        if [[ "$archive" != "$line" ]] && [[ -n "$archive" ]] &&
           [[ ! -e "$md5dir/$archive" ]] && [[ ! -L "$md5dir/$archive" ]]; then
            nb_removed=$(($nb_removed + 1))
        else
            echo "$line" >> "$md5file_tmp"
        fi
    done < "$md5file"

    if [[ "$nb_removed" -gt 0 ]]; then
        info "Removing \$nb_removed obsolete entries from \"\$md5file\"."
        cat "$md5file_tmp" > "$md5file"
    fi
    rm -f "$md5file_tmp"
}
